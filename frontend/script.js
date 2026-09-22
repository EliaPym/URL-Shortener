// Change this to match `short_url` in infrastructure/variables.tf
const API_URL = "https://i-l.ink";

const form = document.getElementById("shorten-form");
const submitButton = form.querySelector("button[type=submit]");
const result = document.getElementById("result");
const shortLink = document.getElementById("short-url");
const copyButton = document.getElementById("copy-button");
const error = document.getElementById("error");

form.addEventListener("submit", async (event) => {
  event.preventDefault();
  result.hidden = true;
  error.hidden = true;
  submitButton.disabled = true;

  try {
    const response = await fetch(`${API_URL}/Shorten`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        long_url: form.long_url.value.trim(),
        custom_url: form.custom_url.value.trim() || null,
      }),
    });
    const data = await response.json().catch(() => ({}));

    if (!response.ok) {
      throw new Error(typeof data.detail === "string" ? data.detail : "Something went wrong, please try again.");
    }

    shortLink.href = data.short_url;
    shortLink.textContent = data.short_url;
    result.hidden = false;
  } catch (err) {
    error.textContent = err.message;
    error.hidden = false;
  } finally {
    submitButton.disabled = false;
  }
});

copyButton.addEventListener("click", async () => {
  await navigator.clipboard.writeText(shortLink.textContent);
  copyButton.textContent = "Copied!";
  setTimeout(() => (copyButton.textContent = "Copy"), 2000);
});
