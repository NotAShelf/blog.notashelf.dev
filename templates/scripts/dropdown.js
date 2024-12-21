// Dropdown post listing
function fetchPosts() {
  fetch("/posts/posts.json")
    .then((response) => response.json())
    .then((data) => {
      const dropdownContent = document.getElementById("dropdown-content");
      data.posts.forEach((post) => {
        const postLink = document.createElement("a");
        postLink.textContent = post.title;
        // we could use posts.url here, instead of posts.path
        // but it messes with local serving, which prefers `/`
        // to the actual URL, as it would point to the live site
        // by path
        postLink.href = post.path;
        dropdownContent.appendChild(postLink);
      });
    })
    .catch((error) => console.error("Error fetching posts:", error));
}

document.addEventListener("DOMContentLoaded", () => {
  fetchPosts();
});
