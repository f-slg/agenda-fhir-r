// UI-only clipboard action. No Store writes or business events.
document.addEventListener("click", async (event) => {
  const button = event.target.closest("[data-copy-target]");
  if (!button) return;
  const content = document.getElementById(button.dataset.copyTarget);
  const feedback = button.parentElement.querySelector(".copy-feedback");
  try {
    await navigator.clipboard.writeText(content?.innerText || "");
    feedback.textContent = "JSON copiado";
  } catch (_) {
    feedback.textContent = "No se pudo copiar. Puede seleccionar el texto o descargar JSON.";
  }
});

// Hidden DT tables need a width measurement after their tab becomes visible.
function adjustVisibleTables() {
  if (!window.jQuery?.fn.dataTable) return;
  requestAnimationFrame(() => window.jQuery.fn.dataTable.tables({visible:true,api:true}).columns.adjust());
}
document.addEventListener("DOMContentLoaded", () => {
  window.jQuery?.(document).on("shown.bs.tab", adjustVisibleTables);
});
