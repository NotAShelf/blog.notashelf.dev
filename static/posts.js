function fetchPosts() {
  fetch("/posts/posts.json")
    .then((response) => {
      console.log("Fetch response received:", response);
      if (!response.ok) {
        throw new Error("Failed to fetch posts.json");
      }
      return response.json();
    })
    .then((data) => {
      console.log("Fetched data:", data);
      const dropdownContent = document.getElementById("posts-content");
      console.log("Dropdown content element:", dropdownContent);
      if (!dropdownContent) {
        throw new Error("#posts-content element not found");
      }
      data.posts.forEach((post) => {
        console.log("Processing post:", post);
        const postItem = document.createElement("li");
        postItem.classList.add("post-dropdown-item");

        const postImage = document.createElement("img");
        postImage.src =
          post.imagePath ||
          "https://avatars.githubusercontent.com/u/62766066?v=4";
        postImage.alt = post.title;
        postImage.classList.add("post-image");

        const postContent = document.createElement("div");
        postContent.classList.add("post-content");

        const postLink = document.createElement("a");
        postLink.textContent = post.title;
        postLink.href = post.path;
        postLink.classList.add("dropdown-link");

        const postDescription = document.createElement("p");
        postDescription.textContent = post.description;
        postDescription.classList.add("post-description");

        const postDate = document.createElement("p");
        postDate.textContent = post.date;
        postDate.classList.add("post-date");

        postContent.appendChild(postLink);
        postContent.appendChild(postDescription);
        postItem.appendChild(postImage);
        postItem.appendChild(postContent);
        dropdownContent.appendChild(postItem);
      });
    })
    .catch((error) => console.error("Error fetching posts:", error));
}

document.addEventListener("DOMContentLoaded", () => {
  console.log("DOMContentLoaded fired");
  fetchPosts();
});
