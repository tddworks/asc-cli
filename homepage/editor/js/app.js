// ═══════════════════════════════════════════════════════════════════════════════
// DOMAIN MODEL
// The project owns the data. All mutations go through domain operations.
// This matches the user's mental model: a Screenshot Set with Locales,
// each Locale has ordered Screenshot Slots.
// ═══════════════════════════════════════════════════════════════════════════════

const project = {
  locales: {}  // Map<localeCode, { displayType: string, screenshots: Shot[] }>
};

// ── Domain reads ──────────────────────────────────────────────────────────────

function primaryLocaleCode() {
  return Object.keys(project.locales)[0] || null;
}

function isPrimary(code) {
  return primaryLocaleCode() === code;
}

function localeFor(code) {
  return project.locales[code] || null;
}

function shotFor(localeCode, shotId) {
  const loc = localeFor(localeCode);
  if (!loc) return null;
  return loc.screenshots.find(s => s.id === shotId) || null;
}

function projectStats() {
  const entries = Object.entries(project.locales);
  return {
    localeCount: entries.length,
    totalShots:  entries.reduce((n, [, l]) => n + l.screenshots.length, 0),
  };
}

// ── Domain mutations ──────────────────────────────────────────────────────────

function createLocale(code) {
  if (project.locales[code]) return false;
  const primary = localeFor(primaryLocaleCode());
  project.locales[code] = {
    displayType: primary?.displayType || 'APP_IPHONE_67',
    screenshots: Array.from({ length: primary?.screenshots.length || 1 },
                            (_, i) => makeShot(i + 1)),
  };
  return true;
}

function deleteLocale(code) {
  delete project.locales[code];
}

function addShotToLocale(code) {
  const loc = localeFor(code);
  if (!loc || loc.screenshots.length >= 10) return null;
  const shot = makeShot(loc.screenshots.length + 1);
  loc.screenshots.push(shot);
  return shot;
}

function removeShotFromLocale(code, shotId) {
  const loc = localeFor(code);
  if (!loc) return;
  loc.screenshots = loc.screenshots.filter(s => s.id !== shotId);
  loc.screenshots.forEach((s, i) => s.order = i + 1);
}

function makeShot(order) {
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

// ── Shot status (semantic state) ──────────────────────────────────────────────

function shotIsEmpty(shot) {
  return !shot.sourceImage;
}

// ═══════════════════════════════════════════════════════════════════════════════
// UI STATE  (view selections — separate from domain data)
// ═══════════════════════════════════════════════════════════════════════════════

const ui = {
  view:         'gallery',  // 'gallery' | 'editor'
  activeLocale: null,       // locale code currently open in editor
  activeShotId: null,       // screenshot id currently selected in editor
};

function activeLocaleData()  { return ui.activeLocale ? localeFor(ui.activeLocale) : null; }
function activeShot()        { return shotFor(ui.activeLocale, ui.activeShotId); }
function activeOutSize() {
  const loc = activeLocaleData();
  if (!loc) return { width: 1290, height: 2796 };
  return DISPLAY_TYPE_SIZES[loc.displayType] || { width: 1290, height: 2796 };
}

// ═══════════════════════════════════════════════════════════════════════════════
// LOCALE METADATA
// ═══════════════════════════════════════════════════════════════════════════════

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
  'APP_IPHONE_55':'iPhone 5.5"','APP_IPHONE_47':'iPhone 4.7"',
  'APP_IPAD_PRO_3GEN_129':'iPad Pro 12.9"','APP_IPAD_PRO_3GEN_11':'iPad Pro 11"',
  'APP_IPAD_PRO_129':'iPad Pro 12.9" (Gen 1-2)','APP_IPAD_105':'iPad 10.5"','APP_IPAD_97':'iPad 9.7"',
  'APP_WATCH_ULTRA':'Apple Watch Ultra','APP_DESKTOP':'Mac',
  'IMESSAGE_APP_IPHONE_67':'iMessage 6.7"',
};

function localeName(code) { return LOCALE_NAMES[code]  || code; }
function localeFlag(code) { return LOCALE_FLAGS[code]  || '🌐'; }

// ═══════════════════════════════════════════════════════════════════════════════
// NAVIGATION
// ═══════════════════════════════════════════════════════════════════════════════

function showGallery() {
  ui.view = 'gallery';
  document.getElementById('editorView').classList.add('hidden');
  document.getElementById('galleryView').classList.remove('hidden');
  renderGallery();
}

function showEditor(localeCode, shotId) {
  ui.view         = 'editor';
  ui.activeLocale = localeCode;
  ui.activeShotId = shotId || null;
  document.getElementById('galleryView').classList.add('hidden');
  document.getElementById('editorView').classList.remove('hidden');
  requestAnimationFrame(() => renderEditor());
}

// ═══════════════════════════════════════════════════════════════════════════════
// GALLERY VIEW
// ═══════════════════════════════════════════════════════════════════════════════

function renderGallery() {
  const container  = document.getElementById('galleryLocalesContainer');
  const emptyEl    = document.getElementById('galleryEmpty');
  const footerEl   = document.getElementById('galleryFooter');
  const statsEl    = document.getElementById('galleryStats');
  container.innerHTML = '';

  const entries = Object.entries(project.locales);
  const isEmpty = entries.length === 0;

  // Always toggle these first — before any early return
  emptyEl.classList.toggle('hidden', !isEmpty);
  footerEl.classList.toggle('hidden', isEmpty);

  if (isEmpty) return;

  // Update topbar stats
  const { localeCount, totalShots } = projectStats();
  statsEl.textContent = `${localeCount} locale${localeCount !== 1 ? 's' : ''} · ${totalShots} capture${totalShots !== 1 ? 's' : ''}`;

  // Render each locale section
  for (const [code, locData] of entries) {
    container.appendChild(buildLocaleSection(code, locData));
  }

  // Wire events after all sections are in the DOM
  container.querySelectorAll('.screenshot-gallery-card:not(.screenshot-gallery-card-add)').forEach(card => {
    card.addEventListener('click', () => showEditor(card.dataset.locale, card.dataset.id));
  });

  container.querySelectorAll('.screenshot-gallery-card-add').forEach(card => {
    card.addEventListener('click', () => {
      const shot = addShotToLocale(card.dataset.locale);
      if (shot) showEditor(card.dataset.locale, shot.id);
    });
  });

  container.querySelectorAll('.btn-locale-delete').forEach(btn => {
    btn.addEventListener('click', e => {
      e.stopPropagation();
      deleteLocale(btn.dataset.locale);
      renderGallery();
    });
  });
}

function buildLocaleSection(code, locData) {
  const outSize   = DISPLAY_TYPE_SIZES[locData.displayType] || { width: 1290, height: 2796 };
  const ar        = outSize.width / outSize.height;
  const shotCount = locData.screenshots.length;

  const section = document.createElement('div');
  section.className = 'locale-section';

  // Header
  const header = document.createElement('div');
  header.className = 'locale-section-header';
  header.innerHTML = `
    <div class="locale-section-title">
      <span class="locale-flag">${localeFlag(code)}</span>
      <span class="locale-name">${localeName(code)}</span>
      ${isPrimary(code) ? '<span class="locale-primary-badge">Primary</span>' : ''}
      <span class="locale-shot-badge">${shotCount} shot${shotCount !== 1 ? 's' : ''}</span>
    </div>
    <div class="locale-section-actions">
      ${!isPrimary(code) ? `<button class="btn-locale-delete" data-locale="${code}">Delete</button>` : ''}
    </div>
  `;

  // Screenshot grid
  const grid = document.createElement('div');
  grid.className = 'screenshot-gallery-grid';

  for (const shot of locData.screenshots) {
    grid.appendChild(buildShotCard(code, shot, outSize, ar));
  }

  // Add slot card
  if (locData.screenshots.length < 10) {
    const addCard = document.createElement('div');
    addCard.className = 'screenshot-gallery-card screenshot-gallery-card-add';
    addCard.dataset.locale = code;
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
  return section;
}

function buildShotCard(localeCode, shot, outSize, ar) {
  const card = document.createElement('div');
  card.className = 'screenshot-gallery-card';
  card.dataset.locale = localeCode;
  card.dataset.id     = shot.id;
  card.style.setProperty('--ar', ar.toString());

  const bg    = shot.background || { type: 'gradient', colors: ['#1a1a2e', '#0f3460'], angle: 135 };
  const bgCSS = bg.type === 'solid'
    ? `background:${bg.color || '#1a1a2e'};`
    : `background:linear-gradient(${bg.angle || 135}deg,${(bg.colors||['#1a1a2e','#0f3460'])[0]},${(bg.colors||['#1a1a2e','#0f3460'])[1]});`;

  const imgHTML   = shot.sourceImage ? `<img class="gallery-card-img" src="${shot.sourceImage.src}" alt="">` : '';
  const emptyHTML = shotIsEmpty(shot) ? `
    <div class="gallery-card-empty">
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
        <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/>
        <circle cx="12" cy="13" r="4"/>
      </svg>
      <span>Add image</span>
    </div>` : '';

  card.innerHTML = `
    <div class="gallery-card-thumb" style="${bgCSS}">
      ${imgHTML}${emptyHTML}
    </div>
    <div class="gallery-card-meta">
      <span class="gallery-card-title">Screenshot ${shot.order}</span>
      <span class="gallery-card-dims">${outSize.width} × ${outSize.height}</span>
    </div>
  `;
  return card;
}

// ═══════════════════════════════════════════════════════════════════════════════
// EDITOR VIEW
// ═══════════════════════════════════════════════════════════════════════════════

// ── Editor DOM refs ────────────────────────────────────────────────────────────
const localeTabs          = document.getElementById('localeTabs');
const screenshotSlots     = document.getElementById('screenshotSlots');
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
const bezelLayerEl        = document.getElementById('bezelLayer');

let zoom         = 75;
let displayScale = 0.33;
let bezelDrag    = null;
let rafPending   = false;

// ── Editor rendering ──────────────────────────────────────────────────────────

function renderEditor() {
  renderLocaleTabs();
  renderShotSlots();
  renderInspector();
  renderCanvas();
}

function renderLocaleTabs() {
  localeTabs.innerHTML = '';
  for (const code of Object.keys(project.locales)) {
    const tab = document.createElement('div');
    tab.className = 'locale-tab' + (code === ui.activeLocale ? ' active' : '');
    tab.innerHTML = `<span>${code}</span><span class="delete-locale" data-locale="${code}" title="Remove">&#x2715;</span>`;
    tab.addEventListener('click', e => {
      if (e.target.classList.contains('delete-locale')) return;
      selectLocale(code);
    });
    tab.querySelector('.delete-locale').addEventListener('click', () => {
      deleteLocale(code);
      if (ui.activeLocale === code) {
        const remaining = Object.keys(project.locales)[0];
        if (remaining) selectLocale(remaining); else showGallery();
      } else {
        renderEditor();
      }
    });
    localeTabs.appendChild(tab);
  }
}

function renderShotSlots() {
  screenshotSlots.innerHTML = '';
  const loc = activeLocaleData();
  if (!loc) return;
  for (const shot of loc.screenshots) {
    const el = document.createElement('div');
    el.className = 'screenshot-slot' + (shot.id === ui.activeShotId ? ' active' : '');
    const thumbSrc = shot.sourceImage ? shot.sourceImage.src : '';
    el.innerHTML = `
      <div class="slot-thumb">${thumbSrc ? `<img src="${thumbSrc}">` : ''}</div>
      <div class="slot-label"><span class="slot-num">#${shot.order}</span></div>
      <span class="delete-slot" title="Remove">&#x2715;</span>
    `;
    el.addEventListener('click', e => {
      if (e.target.classList.contains('delete-slot')) return;
      ui.activeShotId = shot.id;
      renderEditor();
    });
    el.querySelector('.delete-slot').addEventListener('click', () => {
      removeShotFromLocale(ui.activeLocale, shot.id);
      if (ui.activeShotId === shot.id) {
        const loc2 = activeLocaleData();
        ui.activeShotId = loc2?.screenshots[0]?.id || null;
      }
      renderEditor();
    });
    screenshotSlots.appendChild(el);
  }
}

function renderInspector() {
  const loc  = activeLocaleData();
  const shot = activeShot();
  if (loc) displayTypeSelect.value = loc.displayType;
  if (!shot) return;

  deviceSelect.value = shot.device || '';
  const bg = shot.background || { type: 'gradient', colors: ['#1a1a2e', '#0f3460'], angle: 135 };
  bgTabs.forEach(t => t.classList.toggle('active', t.dataset.type === bg.type));
  bgSolid.classList.toggle('hidden',    bg.type !== 'solid');
  bgGradient.classList.toggle('hidden', bg.type !== 'gradient');
  if (bg.type === 'solid')    bgSolidColor.value = bg.color || '#1a1a2e';
  if (bg.type === 'gradient') {
    bgGradColor1.value             = (bg.colors || [])[0] || '#1a1a2e';
    bgGradColor2.value             = (bg.colors || [])[1] || '#0f3460';
    bgGradAngle.value              = bg.angle || 135;
    bgGradAngleVal.textContent     = (bg.angle || 135) + '°';
  }
  renderTextLayersList();
}

function renderTextLayersList() {
  textLayersList.innerHTML = '';
  const shot = activeShot();
  if (!shot || !shot.texts) return;
  shot.texts.forEach(t => {
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
          <input type="text"    class="txt-content" data-id="${t.id}" value="${t.content || ''}">
        </div>
        <div class="text-prop">
          <label>Size</label>
          <input type="number"  class="txt-size"    data-id="${t.id}" value="${t.fontSize || 52}" min="8" max="200">
        </div>
        <div class="text-prop">
          <label>Color</label>
          <input type="color"   class="txt-color"   data-id="${t.id}" value="${t.color || '#ffffff'}">
        </div>
        <div class="text-prop">
          <label>Weight</label>
          <select class="txt-weight" data-id="${t.id}">
            <option value="normal" ${t.fontWeight==='normal'?'selected':''}>Normal</option>
            <option value="bold"   ${t.fontWeight==='bold'  ?'selected':''}>Bold</option>
          </select>
        </div>
        <div class="text-prop">
          <label>Align</label>
          <select class="txt-align" data-id="${t.id}">
            <option value="left"   ${t.align==='left'  ?'selected':''}>Left</option>
            <option value="center" ${t.align==='center'?'selected':''}>Center</option>
            <option value="right"  ${t.align==='right' ?'selected':''}>Right</option>
          </select>
        </div>
      </div>
    `;
    item.querySelector('.text-layer-delete').addEventListener('click', () => {
      shot.texts = shot.texts.filter(x => x.id !== t.id);
      renderEditor();
    });
    item.querySelector('.txt-content').addEventListener('input',  e => { t.content    = e.target.value;                renderEditor(); });
    item.querySelector('.txt-size').addEventListener('change',    e => { t.fontSize   = parseInt(e.target.value) || 52; renderEditor(); });
    item.querySelector('.txt-color').addEventListener('change',   e => { t.color      = e.target.value;                renderEditor(); });
    item.querySelector('.txt-weight').addEventListener('change',  e => { t.fontWeight = e.target.value;                renderEditor(); });
    item.querySelector('.txt-align').addEventListener('change',   e => { t.align      = e.target.value;                renderEditor(); });
    textLayersList.appendChild(item);
  });
}

async function renderCanvas() {
  const shot    = activeShot();
  const outSize = activeOutSize();

  displayScale = calcDisplayScale();
  const cssW = Math.round(outSize.width  * displayScale);
  const cssH = Math.round(outSize.height * displayScale);
  if (canvasEl.width !== cssW || canvasEl.height !== cssH) {
    canvasEl.width = cssW; canvasEl.height = cssH;
  }
  canvasWrapper.style.width  = cssW + 'px';
  canvasWrapper.style.height = cssH + 'px';

  if (!shot) {
    const ctx = canvasEl.getContext('2d');
    ctx.fillStyle = '#0e0e18';
    ctx.fillRect(0, 0, cssW, cssH);
    canvasInfo.textContent = 'No screenshot selected';
    bezelLayerEl.style.display = 'none';
  } else {
    drawBg(canvasEl, shot.background);
    if (!shot.device || !shot.sourceImage) {
      bezelLayerEl.style.display = 'none';
      if (shot.sourceImage) {
        const ctx = canvasEl.getContext('2d');
        const sw = shot.sourceImage.width, sh = shot.sourceImage.height;
        const s  = Math.max(cssW / sw, cssH / sh);
        ctx.drawImage(shot.sourceImage, (cssW - sw*s)/2, (cssH - sh*s)/2, sw*s, sh*s);
      }
    } else {
      await updateBezelLayer(bezelLayerEl, shot, cssW, cssH);
      applyBezelZoom(bezelLayerEl, zoom);
    }
    canvasInfo.textContent = `${outSize.width} × ${outSize.height}`;
  }
  renderTextOverlay(shot, canvasWrapper, outSize, displayScale, renderCanvas);
}

function calcDisplayScale() {
  const viewport = document.getElementById('canvasViewport');
  const outSize  = activeOutSize();
  if (!viewport || !viewport.clientWidth) return 0.33;
  return Math.min(
    (viewport.clientWidth  - 48) / outSize.width,
    (viewport.clientHeight - 48) / outSize.height,
    1.0
  );
}

// ── Editor state mutations ────────────────────────────────────────────────────

function selectLocale(code) {
  ui.activeLocale = code;
  const loc = localeFor(code);
  ui.activeShotId = loc?.screenshots[0]?.id || null;
  renderEditor();
}

// ═══════════════════════════════════════════════════════════════════════════════
// LOCALE PICKER MODAL
// ═══════════════════════════════════════════════════════════════════════════════

const ALL_LOCALES = [
  { code:'en-US', name:'English (US)',           flag:'🇺🇸' },
  { code:'en-GB', name:'English (UK)',           flag:'🇬🇧' },
  { code:'ja',    name:'Japanese',               flag:'🇯🇵' },
  { code:'zh-Hans',name:'Chinese (Simplified)',  flag:'🇨🇳' },
  { code:'zh-Hant',name:'Chinese (Traditional)', flag:'🇹🇼' },
  { code:'ko',    name:'Korean',                 flag:'🇰🇷' },
  { code:'fr',    name:'French',                 flag:'🇫🇷' },
  { code:'de',    name:'German',                 flag:'🇩🇪' },
  { code:'es',    name:'Spanish',                flag:'🇪🇸' },
  { code:'es-MX', name:'Spanish (Mexico)',       flag:'🇲🇽' },
  { code:'it',    name:'Italian',                flag:'🇮🇹' },
  { code:'pt-BR', name:'Portuguese (Brazil)',    flag:'🇧🇷' },
  { code:'pt-PT', name:'Portuguese (Portugal)',  flag:'🇵🇹' },
  { code:'ru',    name:'Russian',                flag:'🇷🇺' },
  { code:'ar',    name:'Arabic',                 flag:'🇸🇦' },
  { code:'hi',    name:'Hindi',                  flag:'🇮🇳' },
  { code:'tr',    name:'Turkish',                flag:'🇹🇷' },
  { code:'nl',    name:'Dutch',                  flag:'🇳🇱' },
  { code:'sv',    name:'Swedish',                flag:'🇸🇪' },
  { code:'da',    name:'Danish',                 flag:'🇩🇰' },
  { code:'fi',    name:'Finnish',                flag:'🇫🇮' },
  { code:'nb',    name:'Norwegian',              flag:'🇳🇴' },
  { code:'pl',    name:'Polish',                 flag:'🇵🇱' },
  { code:'cs',    name:'Czech',                  flag:'🇨🇿' },
  { code:'hu',    name:'Hungarian',              flag:'🇭🇺' },
  { code:'el',    name:'Greek',                  flag:'🇬🇷' },
  { code:'th',    name:'Thai',                   flag:'🇹🇭' },
  { code:'id',    name:'Indonesian',             flag:'🇮🇩' },
  { code:'uk',    name:'Ukrainian',              flag:'🇺🇦' },
  { code:'vi',    name:'Vietnamese',             flag:'🇻🇳' },
];

let pickerSelected = new Set();

function openLocalePicker() {
  pickerSelected.clear();
  const list    = document.getElementById('localeModalList');
  const confirm = document.getElementById('localeModalConfirm');
  list.innerHTML = '';

  for (const loc of ALL_LOCALES) {
    const alreadyAdded = !!project.locales[loc.code];
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
          : '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polyline points="20 6 9 17 4 12"/></svg>'}
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
  for (const code of pickerSelected) createLocale(code);
  closeLocalePicker();
  if (ui.view === 'gallery') renderGallery();
  else renderEditor();
}

// ═══════════════════════════════════════════════════════════════════════════════
// EVENT LISTENERS
// ═══════════════════════════════════════════════════════════════════════════════

// Gallery
document.getElementById('backToGalleryBtn').addEventListener('click', showGallery);
document.getElementById('galleryExportBtn').addEventListener('click', () => exportToZip(project));
document.getElementById('addLocaleGalleryBtn').addEventListener('click', openLocalePicker);
document.getElementById('addLocaleTopbarBtn').addEventListener('click', openLocalePicker);
document.getElementById('galleryEmptyAddBtn').addEventListener('click', openLocalePicker);

// Modal
document.getElementById('localeModalClose').addEventListener('click', closeLocalePicker);
document.getElementById('localeModalCancel').addEventListener('click', closeLocalePicker);
document.getElementById('localeModalConfirm').addEventListener('click', confirmAddLocales);
document.getElementById('localeModal').addEventListener('click', e => {
  if (e.target === document.getElementById('localeModal')) closeLocalePicker();
});

// Editor sidebar
document.getElementById('addLocaleBtn').addEventListener('click', openLocalePicker);
document.getElementById('addScreenshotBtn').addEventListener('click', () => {
  const shot = addShotToLocale(ui.activeLocale);
  if (shot) { ui.activeShotId = shot.id; renderEditor(); }
});
document.getElementById('exportBtn').addEventListener('click', () => exportToZip(project));

// Canvas toolbar
zoomSlider.addEventListener('input', () => {
  zoom = parseInt(zoomSlider.value);
  zoomValue.textContent = zoom + '%';
  applyBezelZoom(bezelLayerEl, zoom);
});

window.addEventListener('resize', () => { if (ui.view === 'editor') renderCanvas(); });

// Inspector — Canvas Size
displayTypeSelect.addEventListener('change', () => {
  const loc = activeLocaleData();
  if (loc) { loc.displayType = displayTypeSelect.value; renderCanvas(); }
});

// Inspector — Device
deviceSelect.addEventListener('change', () => {
  const shot = activeShot();
  if (shot) { shot.device = deviceSelect.value; renderCanvas(); }
});

// Inspector — Screenshot image
screenshotFileInput.addEventListener('change', e => {
  const file = e.target.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = ev => {
    const img = new Image();
    img.onload = () => {
      const shot = activeShot();
      if (shot) { shot.sourceImage = img; renderEditor(); }
    };
    img.src = ev.target.result;
  };
  reader.readAsDataURL(file);
  e.target.value = '';
});

// Inspector — Background
bgTabs.forEach(tab => {
  tab.addEventListener('click', () => {
    const shot = activeShot();
    if (!shot) return;
    shot.background = { ...(shot.background || {}), type: tab.dataset.type };
    renderEditor();
  });
});

bgSolidColor.addEventListener('change', () => {
  const shot = activeShot();
  if (shot) { shot.background = { type: 'solid', color: bgSolidColor.value }; renderCanvas(); }
});

bgGradColor1.addEventListener('change', applyGradient);
bgGradColor2.addEventListener('change', applyGradient);
bgGradAngle.addEventListener('input',   applyGradient);

function applyGradient() {
  const shot = activeShot();
  if (!shot) return;
  bgGradAngleVal.textContent = bgGradAngle.value + '°';
  shot.background = {
    type:   'gradient',
    colors: [bgGradColor1.value, bgGradColor2.value],
    angle:  parseInt(bgGradAngle.value),
  };
  renderCanvas();
}

document.querySelectorAll('.preset-swatch').forEach(swatch => {
  swatch.addEventListener('click', () => {
    const shot = activeShot();
    if (!shot) return;
    shot.background = { type: 'gradient', ...JSON.parse(swatch.dataset.gradient) };
    renderCanvas();
  });
});

// Inspector — Text layers
document.getElementById('addTextBtn').addEventListener('click', () => {
  const shot = activeShot();
  if (!shot) return;
  shot.texts = shot.texts || [];
  shot.texts.push(createTextLayer());
  renderEditor();
});

document.addEventListener('textSelected', () => renderTextLayersList());

// ── Bezel drag ────────────────────────────────────────────────────────────────

canvasWrapper.addEventListener('pointerdown', e => {
  const shot = activeShot();
  if (!shot) return;
  bezelDrag = { px: e.clientX, py: e.clientY, ox: shot.frameOffsetX || 0, oy: shot.frameOffsetY || 0 };
  canvasWrapper.setPointerCapture(e.pointerId);
  canvasWrapper.classList.add('dragging');
  e.preventDefault();
});

canvasWrapper.addEventListener('pointermove', e => {
  if (!bezelDrag) return;
  const shot = activeShot();
  if (!shot) return;
  shot.frameOffsetX = bezelDrag.ox + (e.clientX - bezelDrag.px) / displayScale;
  shot.frameOffsetY = bezelDrag.oy + (e.clientY - bezelDrag.py) / displayScale;
  if (!rafPending) {
    rafPending = true;
    requestAnimationFrame(async () => { rafPending = false; await renderCanvas(); });
  }
});

canvasWrapper.addEventListener('pointerup', () => {
  if (!bezelDrag) return;
  bezelDrag = null;
  canvasWrapper.classList.remove('dragging');
  renderCanvas();
});

// ═══════════════════════════════════════════════════════════════════════════════
// INIT
// ═══════════════════════════════════════════════════════════════════════════════

initDevices().then(() => {
  populateDeviceDropdown(deviceSelect);
  showGallery(); // starts empty — user adds locales via picker
});
