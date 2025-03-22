function formatDate(isoDate) {
  const date = new Date(isoDate);

  const months = [
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
  ];

  const year = date.getFullYear();
  const month = months[date.getMonth()];
  const day = date.getDate();

  return `${month} ${day}, ${year}`;
}

function fetchPosts() {
  fetch("/posts/posts.json")
    .then((response) => {
      console.log("Fetch response received:", response);
      if (!response.ok) {
        throw new Error("Failed to fetch posts");
      }
      return response.json();
    })
    .then((data) => {
      const postsContent = document.getElementById("posts-content");
      if (!postsContent) {
        throw new Error("Unable to process posts!");
      }

      const sortedPosts = data.posts.sort(
        (a, b) => new Date(b.date) - new Date(a.date),
      );

      sortedPosts.forEach((post) => {
        const fallback = "https://avatars.githubusercontent.com/u/62766066?v=4";
        const postItem = document.createElement("li");
        postItem.classList.add("post-dropdown-item");

        const postImage = document.createElement("img");
        postImage.src = post.imagePath || fallback;
        postImage.alt = post.title;
        postImage.classList.add("post-image");

        const postContent = document.createElement("div");
        postContent.classList.add("post-content");

        const postTitle = document.createElement("a");
        postTitle.textContent = post.title;
        postTitle.href = post.path;
        postTitle.classList.add("dropdown-link");

        const postDate = document.createElement("p");
        postDate.textContent = `🗓️ ${formatDate(post.date)}`;
        postDate.classList.add("post-date");

        const postDescription = document.createElement("p");
        postDescription.textContent = post.description;
        postDescription.classList.add("post-description");

        postContent.appendChild(postTitle);
        postContent.appendChild(postDate);
        postContent.appendChild(postDescription);
        postItem.appendChild(postImage);
        postItem.appendChild(postContent);
        postsContent.appendChild(postItem);
      });
    })
    .catch((error) => console.error("Error fetching posts:", error));
}

document.addEventListener("DOMContentLoaded", () => {
  fetchPosts();
});
