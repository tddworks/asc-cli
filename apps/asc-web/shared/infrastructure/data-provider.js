// Infrastructure: REST API data provider with mock fallback
// Uses HATEOAS — navigates resources by following _links from server responses
import { MockDataProvider } from './mock-data.js';
import {
  enrichApp, enrichVersion, enrichBuild, enrichBetaGroup,
  enrichReview, enrichIAP, enrichSubGroup, enrichSubscription,
  enrichBundleId, enrichCert, enrichProfile, enrichTeamMember,
  enrichInvitation, enrichXCProduct, enrichXCWorkflow, enrichXCBuildRun,
} from '../domain/enrichers.js';
import { authStatusAffordances } from '../domain/affordances.js';

export const DataProvider = {
  _mode: 'mock', // 'mock' | 'rest'
  _serverUrl: '',
  _onModeChange: null,   // callback: () => void
  _onCommand: null,       // callback: (cmd) => void
  _onOutput: null,        // callback: (text) => void
  _onError: null,         // callback: (text) => void
  _onNotify: null,        // callback: (message, type) => void

  async init() {
    const isSecure = window.location.protocol === 'https:';
    const isLocalServer = window.location.port === '8420' || window.location.port === '8421';
    const bases = isSecure
      ? ['https://localhost:8421', 'https://127.0.0.1:8421']
      : isLocalServer
        ? ['']
        : ['http://localhost:8420', 'http://127.0.0.1:8420'];

    for (const base of bases) {
      try {
        const controller = new AbortController();
        setTimeout(() => controller.abort(), 2000);
        const resp = await fetch(`${base}/api/v1`, { signal: controller.signal });
        if (resp.ok) {
          this._mode = 'rest';
          this._serverUrl = base;
          return;
        }
      } catch {}
    }
    this._mode = 'mock';
  },

  setMode(mode) {
    this._mode = mode;
    if (this._onNotify) this._onNotify(`Switched to ${mode === 'rest' ? 'REST API' : 'Mock Data'} mode`, 'info');
    if (this._onModeChange) this._onModeChange();
  },

  /// Legacy: execute a CLI command via /api/run (for pages not yet migrated to REST).
  async fetch(command) {
    if (this._onCommand) this._onCommand(`asc ${command}`);
    if (this._mode === 'mock') return this._fetchMock(command);
    try {
      const fullCmd = command.startsWith('asc ') ? command : `asc ${command}`;
      const resp = await fetch(`${this._serverUrl}/api/run`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ command: fullCmd }),
      });
      if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
      const data = await resp.json();
      if (data.exit_code !== 0) {
        if (this._onError) this._onError(data.stderr || `Exit code ${data.exit_code}`);
        return null;
      }
      let result;
      try { result = JSON.parse(data.stdout); } catch { result = data.stdout; }
      if (this._onOutput) this._onOutput(JSON.stringify(result, null, 2).substring(0, 500));
      return result;
    } catch (e) {
      if (this._onError) this._onError(e.message);
      return null;
    }
  },

  // MARK: - REST API (HATEOAS)

  /// Primary data method. Fetches a REST API path.
  /// Usage: `const result = await DataProvider.get('/api/v1/apps')`
  async get(path) {
    if (this._onCommand) this._onCommand(`GET ${path}`);
    if (this._mode === 'mock') return this._followMock(path);

    try {
      const resp = await fetch(`${this._serverUrl}${path}`);
      if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
      const result = await resp.json();
      if (this._onOutput) this._onOutput(JSON.stringify(result, null, 2).substring(0, 500));
      return result;
    } catch (e) {
      if (this._onError) this._onError(e.message);
      return null;
    }
  },

  /// Follow a HATEOAS link from a server response.
  /// Usage: `await DataProvider.follow(app.affordances.listVersions)`
  async follow(link) {
    if (!link) return null;
    if (typeof link === 'object' && link.href) return this.get(link.href);
    return null;
  },

  // MARK: - Mock data

  _fetchMock(command) {
    const args = command.split(/\s+/);
    const flag = (name) => { const i = args.indexOf(name); return i >= 0 ? args[i + 1] : null; };
    let result = null;

    if (command === 'apps list') {
      result = { data: MockDataProvider.apps.data.map(enrichApp) };
    }
    else if (args[0] === 'versions' && args[1] === 'list') {
      const appId = flag('--app-id');
      const raw = MockDataProvider.versions[appId];
      result = raw ? { data: raw.data.map(enrichVersion) } : { data: [] };
    }
    else if (args[0] === 'builds' && args[1] === 'list') {
      const appId = flag('--app-id');
      const raw = MockDataProvider.builds[appId];
      result = raw ? { data: raw.data.map(enrichBuild) } : { data: [] };
    }
    else if (args[0] === 'testflight' && args[1] === 'groups' && args[2] === 'list') {
      const appId = flag('--app-id');
      const raw = MockDataProvider.betaGroups[appId];
      result = raw ? { data: raw.data.map(enrichBetaGroup) } : { data: [] };
    }
    else if (args[0] === 'testflight' && args[1] === 'testers' && args[2] === 'list') {
      const gid = flag('--beta-group-id');
      const raw = MockDataProvider.betaTesters[gid];
      result = raw ? { data: raw.data } : { data: [] };
    }
    else if (args[0] === 'reviews' && args[1] === 'list') {
      const appId = flag('--app-id');
      const raw = MockDataProvider.reviews[appId];
      result = raw ? { data: raw.data.map(enrichReview) } : { data: [] };
    }
    else if (args[0] === 'iap' && args[1] === 'list') {
      const appId = flag('--app-id');
      const raw = MockDataProvider.iaps[appId];
      result = raw ? { data: raw.data.map(enrichIAP) } : { data: [] };
    }
    else if (args[0] === 'subscription-groups' && args[1] === 'list') {
      const appId = flag('--app-id');
      const raw = MockDataProvider.subscriptionGroups[appId];
      result = raw ? { data: raw.data.map(enrichSubGroup) } : { data: [] };
    }
    else if (args[0] === 'subscriptions' && args[1] === 'list') {
      const gid = flag('--group-id');
      const raw = MockDataProvider.subscriptions[gid];
      result = raw ? { data: raw.data.map(enrichSubscription) } : { data: [] };
    }
    else if (args[0] === 'users' && args[1] === 'list') {
      result = { data: MockDataProvider.users.data.map(enrichTeamMember) };
    }
    else if (args[0] === 'user-invitations' && args[1] === 'list') {
      result = { data: MockDataProvider.invitations.data.map(enrichInvitation) };
    }
    else if (args[0] === 'bundle-ids' && args[1] === 'list') {
      result = { data: MockDataProvider.bundleIds.data.map(enrichBundleId) };
    }
    else if (args[0] === 'certificates' && args[1] === 'list') {
      result = { data: MockDataProvider.certificates.data.map(enrichCert) };
    }
    else if (args[0] === 'devices' && args[1] === 'list') {
      result = { data: MockDataProvider.devices.data };
    }
    else if (args[0] === 'profiles' && args[1] === 'list') {
      result = { data: MockDataProvider.profiles.data.map(enrichProfile) };
    }
    else if (args[0] === 'xcode-cloud' && args[1] === 'products' && args[2] === 'list') {
      result = { data: MockDataProvider.xcProducts.data.map(enrichXCProduct) };
    }
    else if (args[0] === 'xcode-cloud' && args[1] === 'workflows' && args[2] === 'list') {
      const pid = flag('--product-id');
      const raw = MockDataProvider.xcWorkflows[pid];
      result = raw ? { data: raw.data.map(enrichXCWorkflow) } : { data: [] };
    }
    else if (args[0] === 'xcode-cloud' && args[1] === 'builds' && args[2] === 'list') {
      const wid = flag('--workflow-id');
      const raw = MockDataProvider.xcBuildRuns[wid];
      result = raw ? { data: raw.data.map(enrichXCBuildRun) } : { data: [] };
    }
    else if (args[0] === 'app-infos' && args[1] === 'list') {
      const appId = flag('--app-id');
      const raw = MockDataProvider.appInfos[appId];
      result = raw ? { data: raw.data } : { data: [] };
    }
    else if (args[0] === 'app-info-localizations' && args[1] === 'list') {
      const aiId = flag('--app-info-id');
      const raw = MockDataProvider.appInfoLocalizations[aiId];
      result = raw ? { data: raw.data } : { data: [] };
    }
    else if (args[0] === 'version-localizations' && args[1] === 'list') {
      const vid = flag('--version-id');
      const raw = MockDataProvider.versionLocalizations[vid];
      result = raw ? { data: raw.data } : { data: [] };
    }
    else if (args[0] === 'screenshot-sets' && args[1] === 'list') {
      const lid = flag('--localization-id');
      const raw = MockDataProvider.screenshotSets[lid];
      result = raw ? { data: raw.data } : { data: [] };
    }
    else if (args[0] === 'screenshots' && args[1] === 'list') {
      const sid = flag('--set-id');
      const raw = MockDataProvider.screenshots[sid];
      result = raw ? { data: raw.data } : { data: [] };
    }
    else if (args[0] === 'plugins' && args[1] === 'list') {
      result = { data: MockDataProvider.plugins.data };
    }
    else if (args[0] === 'plugins' && args[1] === 'market' && args[2] === 'list') {
      result = { data: MockDataProvider.marketPlugins.data };
    }
    else if (args[0] === 'plugins' && args[1] === 'market' && args[2] === 'search') {
      const q = (flag('--query') || '').toLowerCase();
      result = { data: MockDataProvider.marketPlugins.data.filter(p =>
        p.name.toLowerCase().includes(q) || p.description.toLowerCase().includes(q) ||
        (p.categories || []).some(c => c.toLowerCase().includes(q))
      )};
    }
    else if (args[0] === 'auth' && args[1] === 'check') {
      result = { data: [{ ...MockDataProvider.authStatus, affordances: authStatusAffordances() }] };
    }
    else {
      result = { data: [] };
    }

    if (this._onOutput) this._onOutput(JSON.stringify(result, null, 2).substring(0, 600));
    return result;
  },

  /// Mock handler for REST path-based requests.
  _followMock(path) {
    if (path === '/api/v1/apps') return this._fetchMock('apps list');
    if (path.match(/^\/api\/v1\/apps\/[^/]+\/versions$/)) {
      const appId = path.split('/')[4];
      return this._fetchMock(`versions list --app-id ${appId}`);
    }
    if (path.match(/^\/api\/v1\/apps\/[^/]+\/builds$/)) {
      const appId = path.split('/')[4];
      return this._fetchMock(`builds list --app-id ${appId}`);
    }
    if (path.match(/^\/api\/v1\/apps\/[^/]+\/testflight$/)) {
      const appId = path.split('/')[4];
      return this._fetchMock(`testflight groups list --app-id ${appId}`);
    }
    if (path.match(/^\/api\/v1\/apps\/[^/]+\/reviews$/)) {
      const appId = path.split('/')[4];
      return this._fetchMock(`reviews list --app-id ${appId}`);
    }
    if (path === '/api/v1/certificates') return this._fetchMock('certificates list');
    if (path === '/api/v1/bundle-ids') return this._fetchMock('bundle-ids list');
    if (path === '/api/v1/devices') return this._fetchMock('devices list');
    if (path === '/api/v1/profiles') return this._fetchMock('profiles list');
    if (path === '/api/v1/plugins') return this._fetchMock('plugins list');
    return { data: [] };
  },
};
