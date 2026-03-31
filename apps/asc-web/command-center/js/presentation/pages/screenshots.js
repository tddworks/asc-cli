// Page: Screenshots — Version → Locale → Device → Screenshots
import { DataProvider } from '../../../../shared/infrastructure/data-provider.js';
import { state } from '../state.js';
import { showToast } from '../toast.js';
import { escapeHTML } from '../helpers.js';

// Page-local state
let versions = [];
let selectedVersionId = null;
let localizations = [];
let activeLocaleIdx = 0;
let screenshotSets = {}; // localizationId → [sets]
let screenshots = {};    // setId → [screenshots]
let expandedSetId = null;

export function renderScreenshots() {
  const appName = state.selectedApp?.name || 'PhotoSync Pro';
  return `
    <div class="card mb-24">
      <div class="toolbar">
        <div class="toolbar-left">
          <span style="font-size:13px;color:var(--text-muted)">App:</span>
          <span style="font-size:13px;font-weight:600">${escapeHTML(appName)}</span>
        </div>
        <div class="toolbar-right">
          <label style="font-size:12px;color:var(--text-muted);margin-right:6px">Version:</label>
          <select id="ssVersionPicker" onchange="ssPickVersion(this.value)" style="font-size:13px;padding:4px 8px;border:1px solid var(--border);border-radius:6px;background:var(--bg);color:var(--text-primary)">
            <option value="">Loading...</option>
          </select>
        </div>
      </div>
    </div>

    <div id="ssLocaleBar" style="display:none" class="mb-24">
      <div class="filter-group" id="ssLocaleTabs"></div>
    </div>

    <div id="ssContent">
      <div class="card"><div class="empty-state"><div class="spinner" style="margin:24px auto"></div></div></div>
    </div>

    <div class="card mt-24">
      <div class="card-header">
        <span class="card-title">AI Screenshot Generation</span>
      </div>
      <div class="card-body padded">
        <p style="font-size:13px;color:var(--text-secondary);margin-bottom:12px">Generate marketing screenshots with AI using <code>asc app-shots</code></p>
        <div style="display:flex;gap:8px">
          <button class="btn btn-secondary" onclick="showToast('asc app-shots generate --plan plan.json','info')">Generate</button>
          <button class="btn btn-secondary" onclick="showToast('asc app-shots translate --to zh --to ja','info')">Translate</button>
          <button class="btn btn-secondary" onclick="showToast('asc app-shots html --plan plan.json','info')">HTML Export</button>
        </div>
      </div>
    </div>`;
}

export async function loadScreenshots() {
  const appId = state.selectedApp?.id || '6449071230';
  const result = await DataProvider.fetch(`versions list --app-id ${appId}`);
  versions = result?.data || [];

  const picker = document.getElementById('ssVersionPicker');
  if (!picker) return;

  if (versions.length === 0) {
    picker.innerHTML = '<option value="">No versions</option>';
    document.getElementById('ssContent').innerHTML = '<div class="card"><div class="empty-state"><p style="color:var(--text-muted)">No versions found for this app.</p></div></div>';
    return;
  }

  // Default to latest editable version, or first
  const editable = versions.find(v => v.isEditable);
  const defaultV = editable || versions[0];
  selectedVersionId = defaultV.id;

  picker.innerHTML = versions.map(v =>
    `<option value="${v.id}" ${v.id === selectedVersionId ? 'selected' : ''}>${escapeHTML(v.versionString)} (${formatState(v.state)})</option>`
  ).join('');

  await loadLocalizationsForVersion(selectedVersionId);
}

async function loadLocalizationsForVersion(versionId) {
  activeLocaleIdx = 0;
  screenshotSets = {};
  screenshots = {};
  expandedSetId = null;

  document.getElementById('ssContent').innerHTML = '<div class="card"><div class="empty-state"><div class="spinner" style="margin:24px auto"></div></div></div>';

  const result = await DataProvider.fetch(`version-localizations list --version-id ${versionId}`);
  localizations = result?.data || [];

  if (localizations.length === 0) {
    document.getElementById('ssLocaleBar').style.display = 'none';
    document.getElementById('ssContent').innerHTML = '<div class="card"><div class="empty-state"><p style="color:var(--text-muted)">No localizations found. Create one first.</p><button class="btn btn-primary btn-sm" style="margin-top:12px" onclick="showToast(\'asc version-localizations create --version-id ' + versionId + ' --locale en-US\',\'info\')">+ Add Localization</button></div></div>';
    return;
  }

  // Render locale tabs
  const tabsEl = document.getElementById('ssLocaleTabs');
  const barEl = document.getElementById('ssLocaleBar');
  barEl.style.display = '';
  tabsEl.innerHTML = localizations.map((loc, i) =>
    `<button class="filter-btn ${i === 0 ? 'active' : ''}" onclick="ssPickLocale(${i}, this)">${escapeHTML(loc.locale)}</button>`
  ).join('');

  await loadSetsForLocale(0);
}

async function loadSetsForLocale(idx) {
  activeLocaleIdx = idx;
  expandedSetId = null;
  const loc = localizations[idx];
  if (!loc) return;

  document.getElementById('ssContent').innerHTML = '<div class="card"><div class="empty-state"><div class="spinner" style="margin:24px auto"></div></div></div>';

  // Fetch screenshot sets for this localization
  if (!screenshotSets[loc.id]) {
    const result = await DataProvider.fetch(`screenshot-sets list --localization-id ${loc.id}`);
    screenshotSets[loc.id] = result?.data || [];
  }

  renderDeviceCards(loc);
}

function renderDeviceCards(loc) {
  const sets = screenshotSets[loc.id] || [];

  if (sets.length === 0) {
    document.getElementById('ssContent').innerHTML = `
      <div class="card">
        <div class="empty-state">
          <p style="color:var(--text-muted)">No screenshot sets for <strong>${escapeHTML(loc.locale)}</strong>.</p>
          <button class="btn btn-primary btn-sm" style="margin-top:12px" onclick="showToast('asc screenshot-sets create --localization-id ${loc.id} --display-type APP_IPHONE_67','info')">+ New Screenshot Set</button>
        </div>
      </div>`;
    return;
  }

  document.getElementById('ssContent').innerHTML = sets.map(set => {
    const deviceName = formatDisplayType(set.screenshotDisplayType);
    const isExpanded = expandedSetId === set.id;
    const shotsList = screenshots[set.id];

    return `
      <div class="card mb-16">
        <div class="card-header" style="cursor:pointer" onclick="ssToggleSet('${set.id}', '${loc.id}')">
          <div style="display:flex;align-items:center;gap:12px">
            <span style="font-size:18px">${deviceIcon(set.screenshotDisplayType)}</span>
            <div>
              <span class="card-title" style="font-size:14px">${escapeHTML(deviceName)}</span>
              <span style="font-size:12px;color:var(--text-muted);margin-left:8px">${set.screenshotsCount} screenshot${set.screenshotsCount !== 1 ? 's' : ''}</span>
            </div>
          </div>
          <div style="display:flex;align-items:center;gap:8px">
            <button class="btn btn-sm btn-secondary" onclick="event.stopPropagation();showToast('asc screenshots upload --set-id ${set.id} --file screenshot.png','info')">Upload</button>
            <button class="btn btn-sm btn-primary" onclick="event.stopPropagation();showToast('asc screenshot-sets create --localization-id ${loc.id} --display-type APP_IPHONE_67','info')">+ New Set</button>
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="16" height="16" style="transition:transform 0.2s;transform:rotate(${isExpanded ? '180' : '0'}deg)"><path d="M6 9l6 6 6-6"/></svg>
          </div>
        </div>
        ${isExpanded ? renderScreenshotGrid(set.id, shotsList) : ''}
      </div>`;
  }).join('') + `
    <div style="text-align:center;padding:8px 0">
      <button class="btn btn-sm btn-secondary" onclick="showToast('asc screenshot-sets create --localization-id ${loc.id} --display-type APP_IPHONE_67','info')">+ Add Device Type</button>
    </div>`;
}

function renderScreenshotGrid(setId, shotsList) {
  if (!shotsList) {
    return `<div class="card-body padded"><div class="spinner" style="margin:12px auto"></div></div>`;
  }

  if (shotsList.length === 0) {
    return `<div class="card-body padded"><p style="color:var(--text-muted);font-size:13px">No screenshots yet. Upload one to get started.</p></div>`;
  }

  return `
    <div class="card-body padded" style="padding-top:0">
      <div style="display:grid;grid-template-columns:repeat(auto-fill,minmax(140px,1fr));gap:12px;margin-top:12px">
        ${shotsList.map((sc, i) => {
          const sizeKB = Math.round(sc.fileSize / 1024);
          const dims = sc.imageWidth && sc.imageHeight ? `${sc.imageWidth}\u00d7${sc.imageHeight}` : '';
          const stateClass = sc.assetState === 'COMPLETE' ? 'live' : sc.assetState === 'AWAITING_UPLOAD' ? 'pending' : 'processing';
          const stateLabel = sc.assetState === 'COMPLETE' ? 'Ready' : sc.assetState === 'AWAITING_UPLOAD' ? 'Awaiting' : 'Processing';
          return `
            <div style="border:1px solid var(--border);border-radius:8px;overflow:hidden;background:var(--bg)">
              <div style="aspect-ratio:9/19.5;background:var(--border);display:flex;align-items:center;justify-content:center;font-size:11px;color:var(--text-muted)">
                ${dims || 'No preview'}
              </div>
              <div style="padding:8px">
                <div style="font-size:11px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis" title="${escapeHTML(sc.fileName)}">${escapeHTML(sc.fileName)}</div>
                <div style="font-size:10px;color:var(--text-muted);margin-top:2px">${sizeKB} KB${dims ? ' \u00b7 ' + dims : ''}</div>
                <div style="margin-top:4px"><span class="status ${stateClass}" style="font-size:10px">${stateLabel}</span></div>
              </div>
            </div>`;
        }).join('')}
      </div>
    </div>`;
}

// --- Helpers ---

function formatState(s) {
  const map = {
    'READY_FOR_SALE': 'Live',
    'PREPARE_FOR_SUBMISSION': 'Preparing',
    'WAITING_FOR_REVIEW': 'Waiting',
    'IN_REVIEW': 'In Review',
    'REJECTED': 'Rejected',
  };
  return map[s] || s?.replace(/_/g, ' ') || 'Unknown';
}

function formatDisplayType(dt) {
  const map = {
    'APP_IPHONE_67': 'iPhone 6.7"',
    'APP_IPHONE_65': 'iPhone 6.5"',
    'APP_IPHONE_61': 'iPhone 6.1"',
    'APP_IPHONE_58': 'iPhone 5.8"',
    'APP_IPHONE_55': 'iPhone 5.5"',
    'APP_IPHONE_47': 'iPhone 4.7"',
    'APP_IPHONE_40': 'iPhone 4"',
    'APP_IPHONE_35': 'iPhone 3.5"',
    'APP_IPAD_PRO_129': 'iPad Pro 12.9"',
    'APP_IPAD_PRO_3GEN_129': 'iPad Pro 12.9" (3rd gen)',
    'APP_IPAD_105': 'iPad 10.5"',
    'APP_IPAD_97': 'iPad 9.7"',
    'APP_APPLE_TV': 'Apple TV',
    'APP_APPLE_VISION_PRO': 'Apple Vision Pro',
    'APP_WATCH_SERIES_10': 'Apple Watch Series 10',
    'APP_DESKTOP': 'Mac Desktop',
  };
  return map[dt] || dt?.replace(/^APP_/, '').replace(/_/g, ' ') || dt;
}

function deviceIcon(dt) {
  if (dt?.includes('IPHONE')) return '\u{1F4F1}';
  if (dt?.includes('IPAD')) return '\u{1F4F1}';
  if (dt?.includes('WATCH')) return '\u231A';
  if (dt?.includes('TV')) return '\u{1F4FA}';
  if (dt?.includes('VISION')) return '\u{1F453}';
  if (dt?.includes('DESKTOP') || dt?.includes('MAC')) return '\u{1F5A5}';
  return '\u{1F4F7}';
}

// --- Global handlers ---

window.ssPickVersion = async function(versionId) {
  selectedVersionId = versionId;
  await loadLocalizationsForVersion(versionId);
};

window.ssPickLocale = async function(idx, btn) {
  btn.parentElement.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  await loadSetsForLocale(idx);
};

window.ssToggleSet = async function(setId, locId) {
  if (expandedSetId === setId) {
    expandedSetId = null;
  } else {
    expandedSetId = setId;
    // Fetch screenshots if not cached
    if (!screenshots[setId]) {
      const loc = localizations[activeLocaleIdx];
      renderDeviceCards(loc); // re-render with spinner
      const result = await DataProvider.fetch(`screenshots list --set-id ${setId}`);
      screenshots[setId] = result?.data || [];
    }
  }
  const loc = localizations[activeLocaleIdx];
  renderDeviceCards(loc);
};
