// script.js
Shiny.addCustomMessageHandler('nav_switch', function(page) {
  // This JS function handles the UI switching if you want to move away from shinyjs
  console.log("Switching to page: " + page);
});