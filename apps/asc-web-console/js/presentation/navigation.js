// Presentation: Navigation + page rendering
import { state } from './state.js';
import { icon } from './icons.js';
import { NAV, getPageData } from './nav-data.js';
import { renderDashboard } from './pages/dashboard.js';
import { renderFeaturePage } from './pages/feature.js';

export function renderNav() {
  const nav = document.getElementById('nav');
  let html = '';
  NAV.forEach(section => {
    html += `<div class="nav-group-title">${section.group}</div>`;
    section.items.forEach(item => {
      const active = item.id === state.currentPage ? 'active' : '';
      html += `<button data-page="${item.id}" class="nav-item ${active}">
        ${icon(item.icon)}
        <span>${item.label}</span>
      </button>`;
    });
  });
  nav.innerHTML = html;
  nav.querySelectorAll('[data-page]').forEach(btn => {
    btn.addEventListener('click', () => navigate(btn.dataset.page));
  });
}

export function navigate(pageId) {
  state.currentPage = pageId;
  renderNav();
  renderPage();
}

export function renderPage() {
  const container = document.getElementById('page-content');
  const title = document.getElementById('page-title');
  const badge = document.getElementById('page-badge');
  const data = getPageData(state.currentPage);

  container.classList.remove('fade-in');
  void container.offsetWidth;
  container.classList.add('fade-in');

  if (state.currentPage === 'dashboard') {
    title.textContent = 'Dashboard';
    badge.style.display = 'none';
    container.innerHTML = renderDashboard();
    return;
  }

  if (!data) return;
  title.textContent = data.label;
  if (data.cmds) {
    badge.textContent = `${data.cmds.length} commands`;
    badge.style.display = '';
  } else {
    badge.style.display = 'none';
  }
  container.innerHTML = renderFeaturePage(data);
}

// Expose navigate globally for event delegation
window.navigate = navigate;
