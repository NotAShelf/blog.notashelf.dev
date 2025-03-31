function formatDate(isoDate, useRelativeDates = true) {
  const date = new Date(isoDate);
  const now = new Date();
  const diffDays = Math.floor((now - date) / (1000 * 60 * 60 * 24));
  
  // Use relative dates for recent posts if enabled
  if (useRelativeDates) {
    if (diffDays === 0) return "Today";
    if (diffDays === 1) return "Yesterday";
    if (diffDays < 7) return `${diffDays} days ago`;
  }
  
  const months = [
    "January", "February", "March", "April", "May", "June", 
    "July", "August", "September", "October", "November", "December"
  ];

  return `${months[date.getMonth()]} ${date.getDate()}, ${date.getFullYear()}`;
}

function createPostElement(post) {
  const fallbackImage = "https://avatars.githubusercontent.com/u/62766066?v=4";
  
  // Create elements
  const postItem = document.createElement("li");
  const postImage = document.createElement("img");
  const postContent = document.createElement("div");
  const postTitle = document.createElement("a");
  const postDate = document.createElement("p");
  const postDescription = document.createElement("p");
  
  // Set attributes and content
  postItem.classList.add("post-dropdown-item");
  postItem.setAttribute("tabindex", "0");
  
  postImage.src = post.imagePath || fallbackImage;
  postImage.alt = `Thumbnail for "${post.title}"`;
  postImage.classList.add("post-image");
  postImage.loading = "lazy"; // Lazy load images
  
  postContent.classList.add("post-content");
  
  postTitle.textContent = post.title;
  postTitle.href = post.path;
  postTitle.classList.add("dropdown-link");
  
  postDate.textContent = `🗓️ ${formatDate(post.date)}`;
  postDate.classList.add("post-date");
  
  postDescription.textContent = post.description;
  postDescription.classList.add("post-description");
  
  // Assemble the elements
  postContent.appendChild(postTitle);
  postContent.appendChild(postDate);
  postContent.appendChild(postDescription);
  postItem.appendChild(postImage);
  postItem.appendChild(postContent);
  
  return postItem;
}

/**
 * Renders posts to the container
 * @param {Array} posts - Array of post objects
 * @param {HTMLElement} container - Container element
 */
function renderPosts(posts, container) {
  // Show empty state if no posts
  if (!posts || posts.length === 0) {
    const emptyState = document.createElement("div");
    emptyState.classList.add("posts-empty-state");
    emptyState.textContent = "No posts available at the moment.";
    container.appendChild(emptyState);
    return;
  }

  // Use DocumentFragment for better performance
  const fragment = document.createDocumentFragment();
  
  posts.forEach(post => {
    fragment.appendChild(createPostElement(post));
  });
  
  container.appendChild(fragment);
}

/**
 * Fetches and displays posts
 * @param {Object} options - Configuration options
 */
function fetchPosts(options = {}) {
  const {
    url = "/posts/posts.json",
    containerId = "posts-content",
    limit = null,
    sort = "newest" // 'newest', 'oldest', etc.
  } = options;
  
  const postsContent = document.getElementById(containerId);
  
  if (!postsContent) {
    console.error(`Container element with ID "${containerId}" not found.`);
    return;
  }
  
  // Show loading state
  const loadingEl = document.createElement("div");
  loadingEl.classList.add("posts-loading");
  loadingEl.textContent = "Loading posts...";
  loadingEl.setAttribute("aria-live", "polite");
  postsContent.appendChild(loadingEl);

  fetch(url)
    .then(response => {
      if (!response.ok) {
        throw new Error(`Failed to fetch posts (Status ${response.status})`);
      }
      return response.json();
    })
    .then(data => {
      // Remove loading indicator
      loadingEl.remove();
      
      let posts = data.posts || [];
      
      // Sort posts
      switch(sort) {
        case "newest":
          posts.sort((a, b) => new Date(b.date) - new Date(a.date));
          break;
        case "oldest":
          posts.sort((a, b) => new Date(a.date) - new Date(b.date));
          break;
        // Add more sorting options as needed
      }
      
      // Apply limit if specified
      if (limit && typeof limit === 'number') {
        posts = posts.slice(0, limit);
      }
      
      renderPosts(posts, postsContent);
    })
    .catch(error => {
      // Show error state in the UI
      loadingEl.remove();
      
      const errorEl = document.createElement("div");
      errorEl.classList.add("posts-error");
      errorEl.textContent = `Error loading posts: ${error.message}`;
      errorEl.setAttribute("aria-live", "assertive");
      postsContent.appendChild(errorEl);
      
      console.error("Error fetching posts:", error);
    });
}

/**
 * Initialize posts functionality with optional filters
 */
function initPosts() {
  const filterLinks = document.querySelectorAll('[data-post-filter]');
  
  // Add filtering capability if filter elements exist
  if (filterLinks.length > 0) {
    filterLinks.forEach(link => {
      link.addEventListener('click', (e) => {
        e.preventDefault();
        
        // Clear active state from all filters
        filterLinks.forEach(l => l.classList.remove('active'));
        link.classList.add('active');
        
        const filter = link.getAttribute('data-post-filter');
        const container = document.getElementById('posts-content');
        
        // Clear previous posts
        container.innerHTML = '';
        
        // Fetch posts with the selected filter
        fetchPosts({
          sort: filter
        });
      });
    });
  }
  
  // Initial fetch
  fetchPosts();
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initPosts);
} else {
  initPosts();
}
