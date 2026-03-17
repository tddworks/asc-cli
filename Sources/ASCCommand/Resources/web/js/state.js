// Global app state + routing

export const state = {
  page: 'releases',
  appId: null,
  appName: '',
  bundleId: '',
  platform: 'IOS',
};

const listeners = new Set();

export function onNavigate(fn) { listeners.add(fn); }

export function navigate(page) {
  state.page = page;
  listeners.forEach(fn => fn(page));
}
