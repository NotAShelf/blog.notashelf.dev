// Update the copyright text
const currentYear = new Date().getFullYear();
const copyrightYear = currentYear !== 2024 ? "2024 - " + currentYear : "2024";

document.getElementById("copyright").textContent = copyrightYear;
