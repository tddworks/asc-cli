// Presentation: Auth status check
import { DataProvider } from '../../../shared/infrastructure/data-provider.js';
import { escapeHTML } from './helpers.js';

export async function checkAuth() {
  const result = await DataProvider.fetch('auth check');
  const dot = document.getElementById('authDot');
  const info = document.getElementById('authInfo');
  const auth = result?.data?.[0] || (result?.keyID ? result : null);
  if (auth?.keyID) {
    dot.classList.remove('disconnected');
    info.innerHTML = `<span>${escapeHTML(auth.name || 'default')}</span>Key: ${auth.keyID.substring(0, 6)}... (${auth.source})`;
    document.querySelector('.auth-status').style.background = 'var(--success-bg)';
    info.style.color = 'var(--success-text)';
  } else {
    dot.classList.add('disconnected');
    info.innerHTML = '<span>Not Connected</span>Run: asc auth login';
    document.querySelector('.auth-status').style.background = 'var(--danger-bg)';
    info.style.color = 'var(--danger-text)';
  }
}
