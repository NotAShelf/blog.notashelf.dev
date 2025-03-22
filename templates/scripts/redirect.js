let countdown = 5;
const countdownElement = document.getElementById("countdown");
const countdownInterval = setInterval(updateCountdown, 1000);
updateCountdown();

function updateCountdown() {
  countdown--;
  if (countdown <= 0) {
    clearInterval(countdownInterval);
    window.location.href = "/";
  } else {
    countdownElement.textContent =
      "Redirecting in " +
      countdown +
      " second" +
      (countdown !== 1 ? "s." : ".");
  }
}
