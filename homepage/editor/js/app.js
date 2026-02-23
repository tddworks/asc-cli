// app.js — Main state machine

// ─── State ────────────────────────────────────────────────────────────────────

const state = {
  view: 'gallery',       // 'gallery' | 'editor'
  currentLocale: null,
  currentScreenshotId: null,
  locales: {}
};

// ─── Editor DOM refs (all live inside #editorView) ────────────────────────────

const localeTabs          = document.getElementById('localeTabs');
const screenshotSlots     = document.getElementById('screenshotSlots');
const addLocaleBtn        = document.getElementById('addLocaleBtn');
const addScreenshotBtn    = document.getElementById('addScreenshotBtn');
const canvasEl            = document.getElementById('mainCanvas');
const canvasWrapper       = document.getElementById('canvasWrapper');
const zoomSlider          = document.getElementById('zoomSlider');
const zoomValue           = document.getElementById('zoomValue');
const canvasInfo          = document.getElementById('canvasInfo');
const displayTypeSelect   = document.getElementById('displayTypeSelect');
const deviceSelect        = document.getElementById('deviceSelect');
const screenshotFileInput = document.getElementById('screenshotFileInput');
const bgTabs              = document.querySelectorAll('.bg-tab');
const bgSolid             = document.getElementById('bgSolid');
const bgGradient          = document.getElementById('bgGradient');
const bgSolidColor        = document.getElementById('bgSolidColor');
const bgGradColor1        = document.getElementById('bgGradColor1');
const bgGradColor2        = document.getElementById('bgGradColor2');
const bgGradAngle         = document.getElementById('bgGradAngle');
const bgGradAngleVal      = document.getElementById('bgGradAngleVal');
const textLayersList      = document.getElementById('textLayersList');
const addTextBtn          = document.getElementById('addTextBtn');
const exportBtn           = document.getElementById('exportBtn');
const bezelLayerEl        = document.getElementById('bezelLayer');

let zoom         = 75;    // bezel scale %
let displayScale = 0.33;  // CSS scale to fit canvas in viewport

// Bezel drag state
let bezelDrag  = null;
let rafPending = false;

// ─── Navigation ───────────────────────────────────────────────────────────────

function showGallery() {
  state.view = 'gallery';
  document.getElementById('editorView').classList.add('hidden');
  document.getElementById('galleryView').classList.remove('hidden');
  renderGallery();
}

function showEditor(locale, screenshotId) {
  state.view = 'editor';
  state.currentLocale = locale;
  state.currentScreenshotId = screenshotId || null;
  document.getElementById('galleryView').classList.add('hidden');
  document.getElementById('editorView').classList.remove('hidden');
  // One frame for layout before measuring viewport
  requestAnimationFrame(() => rerender());
}

// ─── Locale metadata ─────────────────────────────────────────────────────────

const LOCALE_FLAGS = {
  'en-US':'🇺🇸','en-GB':'🇬🇧','en-AU':'🇦🇺','en-CA':'🇨🇦',
  'ja':'🇯🇵','zh-Hans':'🇨🇳','zh-Hant':'🇹🇼','ko':'🇰🇷',
  'fr':'🇫🇷','de':'🇩🇪','es':'🇪🇸','es-MX':'🇲🇽','it':'🇮🇹',
  'pt-BR':'🇧🇷','pt-PT':'🇵🇹','ru':'🇷🇺','ar':'🇸🇦',
  'hi':'🇮🇳','tr':'🇹🇷','nl':'🇳🇱','sv':'🇸🇪','da':'🇩🇰',
  'fi':'🇫🇮','nb':'🇳🇴','pl':'🇵🇱','cs':'🇨🇿','hu':'🇭🇺',
  'el':'🇬🇷','th':'🇹🇭','id':'🇮🇩','ms':'🇲🇾','vi':'🇻🇳','uk':'🇺🇦',
};

const LOCALE_NAMES = {
  'en-US':'English (US)','en-GB':'English (UK)','en-AU':'English (Australia)','en-CA':'English (Canada)',
  'ja':'Japanese','zh-Hans':'Chinese (Simplified)','zh-Hant':'Chinese (Traditional)','ko':'Korean',
  'fr':'French','de':'German','es':'Spanish','es-MX':'Spanish (Mexico)','it':'Italian',
  'pt-BR':'Portuguese (Brazil)','pt-PT':'Portuguese (Portugal)','ru':'Russian','ar':'Arabic',
  'hi':'Hindi','tr':'Turkish','nl':'Dutch','sv':'Swedish','da':'Danish',
  'fi':'Finnish','nb':'Norwegian','pl':'Polish','cs':'Czech','hu':'Hungarian',
  'el':'Greek','th':'Thai','id':'Indonesian','ms':'Malay','vi':'Vietnamese','uk':'Ukrainian',
};

const DISPLAY_TYPE_SHORT = {
  'APP_IPHONE_67':'iPhone 6.7"','APP_IPHONE_65':'iPhone 6.5"','APP_IPHONE_61':'iPhone 6.1"',
  'APP_IPHONE_58':'iPhone 5.8"','APP_IPHONE_55':'iPhone 5.5"','APP_IPHONE_47':'iPhone 4.7"',
  'APP_IPHONE_40':'iPhone 4"',
  'APP_IPAD_PRO_3GEN_129':'iPad Pro 12.9"','APP_IPAD_PRO_3GEN_11':'iPad Pro 11"',
  'APP_IPAD_PRO_129':'iPad Pro 12.9" (Gen 1-2)','APP_IPAD_105':'iPad 10.5"','APP_IPAD_97':'iPad 9.7"',
  'APP_WATCH_ULTRA':'Apple Watch Ultra','APP_WATCH_SERIES_10':'Apple Watch Series 10',
  'APP_DESKTOP':'Mac','IMESSAGE_APP_IPHONE_67':'iMessage 6.7"',
};

function localeName(code)  { return LOCALE_NAMES[code]  || code; }
function localeFlag(code)  { return LOCALE_FLAGS[code]  || '🌐'; }
function displayShort(dt)  { return DISPLAY_TYPE_SHORT[dt] || dt; }

// ─── Gallery rendering ────────────────────────────────────────────────────────

function renderGallery() {
  const container = document.getElementById('galleryLocalesContainer');
  container.innerHTML = '';

  const localeEntries = Object.entries(state.locales);
  if (localeEntries.length === 0) return;

  // Empty / populated state
  const emptyEl   = document.getElementById('galleryEmpty');
  const footerEl  = document.getElementById('galleryFooter');
  const isEmpty   = localeEntries.length === 0;
  emptyEl.classList.toggle('hidden', !isEmpty);
  footerEl.classList.toggle('hidden', isEmpty);
  if (isEmpty) return;

  // Topbar stats
  const totalShots   = localeEntries.reduce((n, [, d]) => n + d.screenshots.length, 0);
  const statsEl      = document.getElementById('galleryStats');
  if (statsEl) statsEl.textContent = `${localeEntries.length} locale${localeEntries.length > 1 ? 's' : ''} · ${totalShots} capture${totalShots !== 1 ? 's' : ''}`;

  const primaryLocale = localeEntries[0][0];

  for (const [locale, locData] of localeEntries) {
    const isPrimary = locale === primaryLocale;
    const outSize   = DISPLAY_TYPE_SIZES[locData.displayType] || { width: 1290, height: 2796 };
    const ar        = outSize.width / outSize.height;
    const shotCount = locData.screenshots.length;

    const section = document.createElement('div');
    section.className = 'locale-section';

    // ── Header ──
    const header = document.createElement('div');
    header.className = 'locale-section-header';
    header.innerHTML = `
      <div class="locale-section-title">
        <span class="locale-flag">${localeFlag(locale)}</span>
        <span class="locale-name">${localeName(locale)}</span>
        ${isPrimary ? '<span class="locale-primary-badge">Primary</span>' : ''}
        <span class="locale-shot-badge">${shotCount} shot${shotCount !== 1 ? 's' : ''}</span>
      </div>
      <div class="locale-section-actions">
        ${!isPrimary ? `<button class="btn-locale-delete" data-locale="${locale}" title="Delete locale">Delete</button>` : ''}
      </div>
    `;

    // ── Screenshot grid ──
    const grid = document.createElement('div');
    grid.className = 'screenshot-gallery-grid';

    for (const ss of locData.screenshots) {
      const card = document.createElement('div');
      card.className = 'screenshot-gallery-card';
      card.dataset.locale = locale;
      card.dataset.id     = ss.id;
      card.style.setProperty('--ar', ar.toString());

      const bg    = ss.background || { type: 'gradient', colors: ['#1a1a2e', '#0f3460'], angle: 135 };
      const bgCSS = bg.type === 'solid'
        ? `background:${bg.color || '#1a1a2e'};`
        : `background:linear-gradient(${bg.angle || 135}deg,${(bg.colors||['#1a1a2e','#0f3460'])[0]},${(bg.colors||['#1a1a2e','#0f3460'])[1]});`;

      const hasImage  = !!ss.sourceImage;
      const imgHTML   = hasImage ? `<img class="gallery-card-img" src="${ss.sourceImage.src}" alt="">` : '';
      const emptyHTML = hasImage ? '' : `
        <div class="gallery-card-empty">
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/>
            <circle cx="12" cy="13" r="4"/>
          </svg>
          <span>Add image</span>
        </div>`;

      card.innerHTML = `
        <div class="gallery-card-thumb" style="${bgCSS}">
          ${imgHTML}${emptyHTML}
        </div>
        <div class="gallery-card-meta">
          <span class="gallery-card-title">Screenshot ${ss.order}</span>
          <span class="gallery-card-dims">${outSize.width} × ${outSize.height}</span>
        </div>
      `;
      grid.appendChild(card);
    }

    // Add-screenshot card
    if (locData.screenshots.length < 10) {
      const addCard = document.createElement('div');
      addCard.className = 'screenshot-gallery-card screenshot-gallery-card-add';
      addCard.dataset.locale = locale;
      addCard.style.setProperty('--ar', ar.toString());
      addCard.innerHTML = `
        <div class="gallery-card-thumb gallery-card-thumb-add">
          <span class="add-thumb-icon">+</span>
        </div>
        <div class="gallery-card-meta">
          <span class="gallery-card-title">Add</span>
        </div>
      `;
      grid.appendChild(addCard);
    }

    section.appendChild(header);
    section.appendChild(grid);
    container.appendChild(section);
  }

  // ── Bind events ──
  container.querySelectorAll('.screenshot-gallery-card:not(.screenshot-gallery-card-add)').forEach(card => {
    card.addEventListener('click', () => showEditor(card.dataset.locale, card.dataset.id));
  });

  container.querySelectorAll('.screenshot-gallery-card-add').forEach(card => {
    card.addEventListener('click', () => addScreenshotToLocale(card.dataset.locale));
  });

  container.querySelectorAll('.btn-locale-delete').forEach(btn => {
    btn.addEventListener('click', e => {
      e.stopPropagation();
      deleteLocale(btn.dataset.locale);
    });
  });
}

// ─── Editor render helpers ────────────────────────────────────────────────────

function calcDisplayScale() {
  const viewport = document.getElementById('canvasViewport');
  const outSize  = getOutSize();
  if (!viewport || !viewport.clientWidth) return 0.33;
  const availW = viewport.clientWidth  - 48;
  const availH = viewport.clientHeight - 48;
  return Math.min(availW / outSize.width, availH / outSize.height, 1.0);
}

function getLocale() {
  return state.currentLocale ? state.locales[state.currentLocale] : null;
}

function getCurrentScreenshot() {
  const loc = getLocale();
  if (!loc || !state.currentScreenshotId) return null;
  return loc.screenshots.find(s => s.id === state.currentScreenshotId) || null;
}

function getOutSize() {
  const loc = getLocale();
  if (!loc) return { width: 1290, height: 2796 };
  return DISPLAY_TYPE_SIZES[loc.displayType] || { width: 1290, height: 2796 };
}

// ─── Editor renderers ─────────────────────────────────────────────────────────

function renderLocaleTabs() {
  localeTabs.innerHTML = '';
  for (const locale of Object.keys(state.locales)) {
    const el = document.createElement('div');
    el.className = 'locale-tab' + (locale === state.currentLocale ? ' active' : '');
    el.innerHTML = `<span>${locale}</span><span class="delete-locale" data-locale="${locale}" title="Remove">&#x2715;</span>`;
    el.addEventListener('click', e => {
      if (e.target.classList.contains('delete-locale')) return;
      selectLocale(locale);
    });
    el.querySelector('.delete-locale').addEventListener('click', () => deleteLocale(locale));
    localeTabs.appendChild(el);
  }
}

function renderScreenshotSlots() {
  screenshotSlots.innerHTML = '';
  const loc = getLocale();
  if (!loc) return;
  loc.screenshots.forEach(ss => {
    const el = document.createElement('div');
    el.className = 'screenshot-slot' + (ss.id === state.currentScreenshotId ? ' active' : '');
    const thumbSrc = ss.sourceImage ? ss.sourceImage.src : '';
    el.innerHTML = `
      <div class="slot-thumb">${thumbSrc ? `<img src="${thumbSrc}">` : ''}</div>
      <div class="slot-label"><span class="slot-num">#${ss.order}</span></div>
      <span class="delete-slot" title="Remove">&#x2715;</span>
    `;
    el.addEventListener('click', e => {
      if (e.target.classList.contains('delete-slot')) return;
      selectScreenshot(ss.id);
    });
    el.querySelector('.delete-slot').addEventListener('click', () => deleteScreenshot(ss.id));
    screenshotSlots.appendChild(el);
  });
}

function renderInspector() {
  const loc = getLocale();
  const ss  = getCurrentScreenshot();

  if (loc) displayTypeSelect.value = loc.displayType;

  if (ss) {
    deviceSelect.value = ss.device || '';
    const bg = ss.background || { type: 'gradient', colors: ['#1a1a2e', '#0f3460'], angle: 135 };
    bgTabs.forEach(t => t.classList.toggle('active', t.dataset.type === bg.type));
    bgSolid.classList.toggle('hidden',    bg.type !== 'solid');
    bgGradient.classList.toggle('hidden', bg.type !== 'gradient');
    if (bg.type === 'solid')    bgSolidColor.value = bg.color || '#1a1a2e';
    if (bg.type === 'gradient') {
      bgGradColor1.value = (bg.colors || [])[0] || '#1a1a2e';
      bgGradColor2.value = (bg.colors || [])[1] || '#0f3460';
      bgGradAngle.value  = bg.angle || 135;
      bgGradAngleVal.textContent = (bg.angle || 135) + '\u00B0';
    }
  }

  renderTextLayersList();
}

function renderTextLayersList() {
  textLayersList.innerHTML = '';
  const ss = getCurrentScreenshot();
  if (!ss || !ss.texts) return;
  ss.texts.forEach(t => {
    const item = document.createElement('div');
    item.className = 'text-layer-item';
    item.innerHTML = `
      <div class="text-layer-header">
        <span class="text-layer-preview">${t.content || '(empty)'}</span>
        <span class="text-layer-delete" data-id="${t.id}">&#x2715;</span>
      </div>
      <div class="text-props">
        <div class="text-prop text-prop-full">
          <label>Text</label>
          <input type="text" class="txt-content" data-id="${t.id}" value="${t.content || ''}">
        </div>
        <div class="text-prop">
          <label>Size</label>
          <input type="number" class="txt-size" data-id="${t.id}" value="${t.fontSize || 52}" min="8" max="200">
        </div>
        <div class="text-prop">
          <label>Color</label>
          <input type="color" class="txt-color" data-id="${t.id}" value="${t.color || '#ffffff'}">
        </div>
        <div class="text-prop">
          <label>Weight</label>
          <select class="txt-weight" data-id="${t.id}">
            <option value="normal" ${t.fontWeight === 'normal' ? 'selected' : ''}>Normal</option>
            <option value="bold"   ${t.fontWeight === 'bold'   ? 'selected' : ''}>Bold</option>
          </select>
        </div>
        <div class="text-prop">
          <label>Align</label>
          <select class="txt-align" data-id="${t.id}">
            <option value="left"   ${t.align === 'left'   ? 'selected' : ''}>Left</option>
            <option value="center" ${t.align === 'center' ? 'selected' : ''}>Center</option>
            <option value="right"  ${t.align === 'right'  ? 'selected' : ''}>Right</option>
          </select>
        </div>
      </div>
    `;

    item.querySelector('.text-layer-delete').addEventListener('click', () => {
      ss.texts = ss.texts.filter(x => x.id !== t.id);
      rerender();
    });
    item.querySelector('.txt-content').addEventListener('input',  e => { t.content    = e.target.value;               rerender(); });
    item.querySelector('.txt-size').addEventListener('change',    e => { t.fontSize   = parseInt(e.target.value) || 52; rerender(); });
    item.querySelector('.txt-color').addEventListener('change',   e => { t.color      = e.target.value;               rerender(); });
    item.querySelector('.txt-weight').addEventListener('change',  e => { t.fontWeight = e.target.value;               rerender(); });
    item.querySelector('.txt-align').addEventListener('change',   e => { t.align      = e.target.value;               rerender(); });

    textLayersList.appendChild(item);
  });
}

async function rerender() {
  renderLocaleTabs();
  renderScreenshotSlots();
  renderInspector();
  if (state.view === 'editor') await renderCanvas();
}

async function renderCanvas() {
  const ss      = getCurrentScreenshot();
  const outSize = getOutSize();

  displayScale = calcDisplayScale();
  const cssW = Math.round(outSize.width  * displayScale);
  const cssH = Math.round(outSize.height * displayScale);
  if (canvasEl.width !== cssW || canvasEl.height !== cssH) {
    canvasEl.width  = cssW;
    canvasEl.height = cssH;
  }
  canvasWrapper.style.width  = cssW + 'px';
  canvasWrapper.style.height = cssH + 'px';

  if (!ss) {
    const ctx = canvasEl.getContext('2d');
    ctx.fillStyle = '#0e0e18';
    ctx.fillRect(0, 0, cssW, cssH);
    canvasInfo.textContent = 'No screenshot selected';
    bezelLayerEl.style.display = 'none';
  } else {
    drawBg(canvasEl, ss.background);

    if (!ss.device || !ss.sourceImage) {
      bezelLayerEl.style.display = 'none';
      if (ss.sourceImage) {
        const ctx = canvasEl.getContext('2d');
        const sw = ss.sourceImage.width, sh = ss.sourceImage.height;
        const s  = Math.max(cssW / sw, cssH / sh);
        ctx.drawImage(ss.sourceImage, (cssW - sw*s)/2, (cssH - sh*s)/2, sw*s, sh*s);
      }
    } else {
      await updateBezelLayer(bezelLayerEl, ss, cssW, cssH);
      applyBezelZoom(bezelLayerEl, zoom);
    }
    canvasInfo.textContent = `${outSize.width} \u00D7 ${outSize.height}`;
  }

  renderTextOverlay(ss, canvasWrapper, outSize, displayScale, rerender);
}

// ─── State mutations ──────────────────────────────────────────────────────────

function selectLocale(locale) {
  state.currentLocale = locale;
  const loc = state.locales[locale];
  state.currentScreenshotId = loc.screenshots.length > 0 ? loc.screenshots[0].id : null;
  rerender();
}

function deleteLocale(locale) {
  delete state.locales[locale];
  if (state.currentLocale === locale) {
    state.currentLocale = Object.keys(state.locales)[0];
    const loc = state.locales[state.currentLocale];
    state.currentScreenshotId = loc.screenshots.length > 0 ? loc.screenshots[0].id : null;
  }
  if (state.view === 'gallery') renderGallery();
  else rerender();
}

function selectScreenshot(id) {
  state.currentScreenshotId = id;
  rerender();
}

function deleteScreenshot(id) {
  const loc = getLocale();
  if (!loc) return;
  loc.screenshots = loc.screenshots.filter(s => s.id !== id);
  if (state.currentScreenshotId === id) {
    state.currentScreenshotId = loc.screenshots.length > 0 ? loc.screenshots[0].id : null;
  }
  loc.screenshots.forEach((s, i) => s.order = i + 1);
  rerender();
}

// Add a screenshot from the editor sidebar
function addScreenshot() {
  const loc = getLocale();
  if (!loc) return;
  if (loc.screenshots.length >= 10) { alert('Max 10 screenshots per locale'); return; }
  const ss = makeScreenshot(loc.screenshots.length + 1);
  loc.screenshots.push(ss);
  selectScreenshot(ss.id);
}

// Add a screenshot from the gallery (opens editor on the new slot)
function addScreenshotToLocale(locale) {
  const loc = state.locales[locale];
  if (!loc) return;
  if (loc.screenshots.length >= 10) { alert('Max 10 screenshots per locale'); return; }
  const ss = makeScreenshot(loc.screenshots.length + 1);
  loc.screenshots.push(ss);
  showEditor(locale, ss.id);
}

// ─── Locale picker modal ──────────────────────────────────────────────────────

const ALL_LOCALES = [
  { code:'en-US', name:'English (US)',            flag:'🇺🇸' },
  { code:'en-GB', name:'English (UK)',            flag:'🇬🇧' },
  { code:'ja',    name:'Japanese',                flag:'🇯🇵' },
  { code:'zh-Hans',name:'Chinese (Simplified)',   flag:'🇨🇳' },
  { code:'zh-Hant',name:'Chinese (Traditional)',  flag:'🇹🇼' },
  { code:'ko',    name:'Korean',                  flag:'🇰🇷' },
  { code:'fr',    name:'French',                  flag:'🇫🇷' },
  { code:'de',    name:'German',                  flag:'🇩🇪' },
  { code:'es',    name:'Spanish',                 flag:'🇪🇸' },
  { code:'es-MX', name:'Spanish (Mexico)',        flag:'🇲🇽' },
  { code:'it',    name:'Italian',                 flag:'🇮🇹' },
  { code:'pt-BR', name:'Portuguese (Brazil)',     flag:'🇧🇷' },
  { code:'pt-PT', name:'Portuguese (Portugal)',   flag:'🇵🇹' },
  { code:'ru',    name:'Russian',                 flag:'🇷🇺' },
  { code:'ar',    name:'Arabic',                  flag:'🇸🇦' },
  { code:'hi',    name:'Hindi',                   flag:'🇮🇳' },
  { code:'tr',    name:'Turkish',                 flag:'🇹🇷' },
  { code:'nl',    name:'Dutch',                   flag:'🇳🇱' },
  { code:'sv',    name:'Swedish',                 flag:'🇸🇪' },
  { code:'da',    name:'Danish',                  flag:'🇩🇰' },
  { code:'fi',    name:'Finnish',                 flag:'🇫🇮' },
  { code:'nb',    name:'Norwegian',               flag:'🇳🇴' },
  { code:'pl',    name:'Polish',                  flag:'🇵🇱' },
  { code:'cs',    name:'Czech',                   flag:'🇨🇿' },
  { code:'hu',    name:'Hungarian',               flag:'🇭🇺' },
  { code:'el',    name:'Greek',                   flag:'🇬🇷' },
  { code:'th',    name:'Thai',                    flag:'🇹🇭' },
  { code:'id',    name:'Indonesian',              flag:'🇮🇩' },
  { code:'uk',    name:'Ukrainian',               flag:'🇺🇦' },
  { code:'vi',    name:'Vietnamese',              flag:'🇻🇳' },
];

let pickerSelected = new Set();

function openLocalePicker() {
  pickerSelected.clear();
  const list    = document.getElementById('localeModalList');
  const confirm = document.getElementById('localeModalConfirm');
  list.innerHTML = '';

  for (const loc of ALL_LOCALES) {
    const alreadyAdded = !!state.locales[loc.code];
    const item = document.createElement('div');
    item.className = 'locale-list-item' + (alreadyAdded ? ' locale-list-item-added' : '');
    item.dataset.code = loc.code;
    item.innerHTML = `
      <span class="locale-list-flag">${loc.flag}</span>
      <span class="locale-list-name">${loc.name}</span>
      <span class="locale-list-code">${loc.code.replace('-', '_')}</span>
      <span class="locale-list-check">
        ${alreadyAdded
          ? '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>'
          : ''}
      </span>
    `;
    if (!alreadyAdded) {
      item.addEventListener('click', () => {
        const sel = pickerSelected.has(loc.code);
        if (sel) { pickerSelected.delete(loc.code); item.classList.remove('selected'); }
        else     { pickerSelected.add(loc.code);    item.classList.add('selected'); }
        confirm.disabled = pickerSelected.size === 0;
      });
    }
    list.appendChild(item);
  }

  confirm.disabled = true;
  document.getElementById('localeModal').classList.remove('hidden');
}

function closeLocalePicker() {
  document.getElementById('localeModal').classList.add('hidden');
  pickerSelected.clear();
}

function confirmAddLocales() {
  if (pickerSelected.size === 0) return;

  const primaryKey  = Object.keys(state.locales)[0];
  const primaryData = state.locales[primaryKey];
  const displayType = primaryData ? primaryData.displayType : 'APP_IPHONE_67';
  const count       = primaryData ? primaryData.screenshots.length : 1;

  for (const code of pickerSelected) {
    if (state.locales[code]) continue;
    const screenshots = Array.from({ length: count }, (_, i) => makeScreenshot(i + 1));
    state.locales[code] = { displayType, screenshots };
  }

  closeLocalePicker();
  if (state.view === 'gallery') renderGallery();
  else rerender();
}

function addLocale() { openLocalePicker(); }

function makeScreenshot(order) {
  return {
    id:           'ss_' + Date.now() + '_' + Math.random().toString(36).slice(2),
    order,
    sourceImage:  null,
    device:       '',
    background:   { type: 'gradient', colors: ['#1a1a2e', '#0f3460'], angle: 135 },
    texts:        [],
    frameOffsetX: 0,
    frameOffsetY: 0,
  };
}

// ─── Event listeners ──────────────────────────────────────────────────────────

document.getElementById('backToGalleryBtn').addEventListener('click', showGallery);
document.getElementById('galleryExportBtn').addEventListener('click', () => exportToZip(state));
document.getElementById('addLocaleGalleryBtn').addEventListener('click', addLocale);
document.getElementById('addLocaleTopbarBtn').addEventListener('click', addLocale);
document.getElementById('galleryEmptyAddBtn').addEventListener('click', addLocale);

// Modal
document.getElementById('localeModalClose').addEventListener('click', closeLocalePicker);
document.getElementById('localeModalCancel').addEventListener('click', closeLocalePicker);
document.getElementById('localeModalConfirm').addEventListener('click', confirmAddLocales);
document.getElementById('localeModal').addEventListener('click', e => {
  if (e.target === document.getElementById('localeModal')) closeLocalePicker();
});

addLocaleBtn.addEventListener('click', addLocale);
addScreenshotBtn.addEventListener('click', addScreenshot);

zoomSlider.addEventListener('input', () => {
  zoom = parseInt(zoomSlider.value);
  zoomValue.textContent = zoom + '%';
  applyBezelZoom(bezelLayerEl, zoom);
});

window.addEventListener('resize', () => { if (state.view === 'editor') renderCanvas(); });

displayTypeSelect.addEventListener('change', () => {
  const loc = getLocale();
  if (loc) { loc.displayType = displayTypeSelect.value; rerender(); }
});

deviceSelect.addEventListener('change', () => {
  const ss = getCurrentScreenshot();
  if (ss) { ss.device = deviceSelect.value; rerender(); }
});

screenshotFileInput.addEventListener('change', e => {
  const file = e.target.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = ev => {
    const img = new Image();
    img.onload = () => {
      const ss = getCurrentScreenshot();
      if (ss) { ss.sourceImage = img; rerender(); }
    };
    img.src = ev.target.result;
  };
  reader.readAsDataURL(file);
  e.target.value = '';
});

bgTabs.forEach(tab => {
  tab.addEventListener('click', () => {
    const ss = getCurrentScreenshot();
    if (!ss) return;
    ss.background = ss.background || {};
    ss.background.type = tab.dataset.type;
    rerender();
  });
});

bgSolidColor.addEventListener('change', () => {
  const ss = getCurrentScreenshot();
  if (ss) { ss.background = { type: 'solid', color: bgSolidColor.value }; rerender(); }
});

bgGradColor1.addEventListener('change', updateGradient);
bgGradColor2.addEventListener('change', updateGradient);
bgGradAngle.addEventListener('input',   updateGradient);

function updateGradient() {
  const ss = getCurrentScreenshot();
  if (!ss) return;
  bgGradAngleVal.textContent = bgGradAngle.value + '\u00B0';
  ss.background = {
    type:   'gradient',
    colors: [bgGradColor1.value, bgGradColor2.value],
    angle:  parseInt(bgGradAngle.value)
  };
  rerender();
}

document.querySelectorAll('.preset-swatch').forEach(swatch => {
  swatch.addEventListener('click', () => {
    const ss = getCurrentScreenshot();
    if (!ss) return;
    ss.background = { type: 'gradient', ...JSON.parse(swatch.dataset.gradient) };
    rerender();
  });
});

addTextBtn.addEventListener('click', () => {
  const ss = getCurrentScreenshot();
  if (!ss) return;
  ss.texts = ss.texts || [];
  ss.texts.push(createTextLayer());
  rerender();
});

exportBtn.addEventListener('click', () => exportToZip(state));

document.addEventListener('textSelected', () => renderTextLayersList());

// ─── Bezel drag ───────────────────────────────────────────────────────────────

canvasWrapper.addEventListener('pointerdown', e => {
  const ss = getCurrentScreenshot();
  if (!ss) return;
  bezelDrag = { px: e.clientX, py: e.clientY, ox: ss.frameOffsetX || 0, oy: ss.frameOffsetY || 0 };
  canvasWrapper.setPointerCapture(e.pointerId);
  canvasWrapper.classList.add('dragging');
  e.preventDefault();
});

canvasWrapper.addEventListener('pointermove', e => {
  if (!bezelDrag) return;
  const ss = getCurrentScreenshot();
  if (!ss) return;
  ss.frameOffsetX = bezelDrag.ox + (e.clientX - bezelDrag.px) / displayScale;
  ss.frameOffsetY = bezelDrag.oy + (e.clientY - bezelDrag.py) / displayScale;
  if (!rafPending) {
    rafPending = true;
    requestAnimationFrame(async () => { rafPending = false; await renderCanvas(); });
  }
});

canvasWrapper.addEventListener('pointerup', () => {
  if (!bezelDrag) return;
  bezelDrag = null;
  canvasWrapper.classList.remove('dragging');
  rerender();
});

// ─── Init ─────────────────────────────────────────────────────────────────────

initDevices().then(() => {
  populateDeviceDropdown(deviceSelect);
  showGallery(); // starts empty — user picks locales via modal
});
