// Back to top functionality
document.addEventListener("DOMContentLoaded", () => {
    // Create back to top button
    const backToTopButton = document.createElement("a");
    backToTopButton.href = "#";
    backToTopButton.className = "back-to-top";
    backToTopButton.innerHTML = "↑";
    backToTopButton.setAttribute("aria-label", "Back to top");
    document.body.appendChild(backToTopButton);

    // Show/hide back to top button based on scroll position
    window.addEventListener("scroll", () => {
        if (window.pageYOffset > 300) {
            backToTopButton.classList.add("visible");
        } else {
            backToTopButton.classList.remove("visible");
        }
    });

    // Smooth scroll to top when button is clicked
    backToTopButton.addEventListener("click", (e) => {
        e.preventDefault();
        window.scrollTo({
            top: 0,
            behavior: "smooth",
        });
    });
});
