/* =========================================================
   SHARED UI BEHAVIOR
   Sidebar toggle, toasts, password visibility, small helpers.
   Included on every page.
   ========================================================= */

document.addEventListener("DOMContentLoaded", () => {
  // Mobile sidebar toggle
  const toggleBtn = document.querySelector("[data-sidebar-toggle]");
  const sidebar = document.querySelector(".sidebar");
  if (toggleBtn && sidebar) {
    toggleBtn.addEventListener("click", () => sidebar.classList.toggle("open"));
    document.addEventListener("click", (e) => {
      if (window.innerWidth <= 991 && sidebar.classList.contains("open")) {
        if (!sidebar.contains(e.target) && !toggleBtn.contains(e.target)) {
          sidebar.classList.remove("open");
        }
      }
    });
  }

  // Highlight current page link in sidebar
  const current = window.location.pathname.split("/").pop() || "index.html";
  document.querySelectorAll(".sidebar-nav a").forEach((link) => {
    if (link.getAttribute("href") === current) link.classList.add("active");
  });

  // Password show/hide toggles: <button data-toggle-password="#fieldId">
  document.querySelectorAll("[data-toggle-password]").forEach((btn) => {
    btn.addEventListener("click", () => {
      const field = document.querySelector(btn.getAttribute("data-toggle-password"));
      if (!field) return;
      const showing = field.type === "text";
      field.type = showing ? "password" : "text";
      btn.innerHTML = showing
        ? '<i class="bi bi-eye"></i>'
        : '<i class="bi bi-eye-slash"></i>';
    });
  });
});

/** Show a small toast in the top-right corner. type: 'success' | 'danger' | 'default' */
function showToast(message, type = "default") {
  let stack = document.querySelector(".toast-stack");
  if (!stack) {
    stack = document.createElement("div");
    stack.className = "toast-stack";
    document.body.appendChild(stack);
  }
  const el = document.createElement("div");
  el.className = `mini-toast ${type}`;
  const icon = type === "success" ? "bi-check-circle" : type === "danger" ? "bi-exclamation-circle" : "bi-info-circle";
  el.innerHTML = `<i class="bi ${icon}"></i><span>${message}</span>`;
  stack.appendChild(el);
  setTimeout(() => {
    el.style.opacity = "0";
    el.style.transition = "opacity .2s ease";
    setTimeout(() => el.remove(), 200);
  }, 2800);
}

/** Maps an appointment/bill/doctor status string to a badge CSS class. */
function statusBadgeClass(status) {
  const map = {
    Scheduled: "badge-scheduled",
    Confirmed: "badge-confirmed",
    Completed: "badge-completed",
    Cancelled: "badge-cancelled",
    "No-show": "badge-noshow",
    Pending: "badge-pending",
    Paid: "badge-paid",
    Active: "badge-active",
    "On Leave": "badge-inactive",
    Inactive: "badge-inactive",
  };
  return map[status] || "badge-scheduled";
}

/** Very small live-filter helper for tables. Call on keyup of a search input. */
function filterTableRows(inputEl, tableBodySelector, columnIndexes) {
  const q = inputEl.value.trim().toLowerCase();
  const rows = document.querySelectorAll(`${tableBodySelector} tr`);
  let visibleCount = 0;
  rows.forEach((row) => {
    const cells = row.querySelectorAll("td");
    const haystack = columnIndexes
      .map((i) => (cells[i] ? cells[i].textContent.toLowerCase() : ""))
      .join(" ");
    const match = haystack.includes(q);
    row.style.display = match ? "" : "none";
    if (match) visibleCount++;
  });
  const emptyRow = document.querySelector(`${tableBodySelector} .no-results-row`);
  if (emptyRow) emptyRow.style.display = visibleCount === 0 ? "" : "none";
}

/** Simple required-field + pattern validation for a form, using .was-validated-field wrappers. */
function validateForm(formEl) {
  let valid = true;
  formEl.querySelectorAll(".was-validated-field").forEach((wrap) => {
    const field = wrap.querySelector("input, select, textarea");
    if (!field) return;
    const isEmpty = !field.value || !field.value.trim();
    const patternFails = field.pattern && field.value && !new RegExp(field.pattern).test(field.value);
    if ((field.required && isEmpty) || patternFails) {
      wrap.classList.add("is-invalid");
      valid = false;
    } else {
      wrap.classList.remove("is-invalid");
    }
  });
  return valid;
}

/** Formats a number as INR currency for the billing pages. */
function formatCurrency(n) {
  return "₹" + Number(n).toLocaleString("en-IN");
}
