// ════════════════════════════════════════════════════════════════════════════
// App shell — global state, navigation, and event wiring.
//
// This file loads last and owns the two shared globals: `project` (domain
// data) and `ui` (view-selection state).  All component files access these
// by reference at event/render time so forward references are safe.
// ════════════════════════════════════════════════════════════════════════════

// ── Global state ──────────────────────────────────────────────────────────────

const project = new ScreenshotProject();

const ui = {
  view:         'gallery',  // 'gallery' | 'editor'
  activeLocale: null,       // locale code open in editor
  activeShotId: null,       // screenshot id selected in editor
};

// ── Active-state helpers (used by inspector, editor, and event handlers) ──────

function activeLocale()  { return project.localeByCode(ui.activeLocale); }
function activeShot()    { return activeLocale()?.screenshotById(ui.activeShotId) ?? null; }
function activeOutSize() {
  const loc = activeLocale();
  return loc ? (DISPLAY_TYPE_SIZES[loc.displayType] ?? { width: 1290, height: 2796 })
             : { width: 1290, height: 2796 };
}

// ── Navigation ────────────────────────────────────────────────────────────────

function showGallery() {
  ui.view = 'gallery';
  document.getElementById('editorView').classList.add('hidden');
  document.getElementById('galleryView').classList.remove('hidden');
  renderGallery();
}

function showEditor(localeCode, shotId) {
  ui.view         = 'editor';
  ui.activeLocale = localeCode;
  ui.activeShotId = shotId ?? null;
  document.getElementById('galleryView').classList.add('hidden');
  document.getElementById('editorView').classList.remove('hidden');
  requestAnimationFrame(() => renderEditor());
}

// ── Gallery buttons ───────────────────────────────────────────────────────────

document.getElementById('backToGalleryBtn').addEventListener('click', showGallery);
document.getElementById('galleryExportBtn').addEventListener('click', () => exportProject(project));
document.getElementById('addLocaleTopbarBtn').addEventListener('click', openLocalePicker);
document.getElementById('addLocaleGalleryBtn').addEventListener('click', openLocalePicker);
document.getElementById('galleryEmptyAddBtn').addEventListener('click', openLocalePicker);

// ── Locale picker modal buttons ───────────────────────────────────────────────

document.getElementById('localeModalClose').addEventListener('click', closeLocalePicker);
document.getElementById('localeModalCancel').addEventListener('click', closeLocalePicker);
document.getElementById('localeModalConfirm').addEventListener('click', confirmAddLocales);
document.getElementById('localeModal').addEventListener('click', e => {
  if (e.target === document.getElementById('localeModal')) closeLocalePicker();
});

// ── Editor sidebar buttons ────────────────────────────────────────────────────

document.getElementById('addLocaleBtn').addEventListener('click', openLocalePicker);
document.getElementById('addScreenshotBtn').addEventListener('click', () => {
  const shot = activeLocale()?.addScreenshot();
  if (shot) { ui.activeShotId = shot.id; renderEditor(); }
});
document.getElementById('exportBtn').addEventListener('click', () => exportProject(project));

// ── Canvas toolbar ────────────────────────────────────────────────────────────

document.getElementById('zoomSlider').addEventListener('input', e => {
  zoom = parseInt(e.target.value);
  document.getElementById('zoomValue').textContent = zoom + '%';
  applyBezelZoom(document.getElementById('bezelLayer'), zoom);
});

window.addEventListener('resize', () => {
  if (ui.view === 'editor') renderCanvas();
});

// ── Inspector: canvas size ────────────────────────────────────────────────────

document.getElementById('displayTypeSelect').addEventListener('change', e => {
  const loc = activeLocale();
  if (loc) { loc.displayType = e.target.value; renderCanvas(); }
});

// ── Inspector: device frame ───────────────────────────────────────────────────

document.getElementById('deviceSelect').addEventListener('change', e => {
  const shot = activeShot();
  if (shot) { shot.setDevice(e.target.value); renderCanvas(); }
});

// ── Inspector: screenshot image ───────────────────────────────────────────────

document.getElementById('screenshotFileInput').addEventListener('change', e => {
  const file = e.target.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = ev => {
    const img  = new Image();
    img.onload = () => {
      const shot = activeShot();
      if (shot) { shot.setSourceImage(img); renderEditor(); }
    };
    img.src = ev.target.result;
  };
  reader.readAsDataURL(file);
  e.target.value = '';
});

// ── Inspector: background ─────────────────────────────────────────────────────

document.querySelectorAll('.bg-tab').forEach(tab => {
  tab.addEventListener('click', () => {
    const shot = activeShot();
    if (!shot) return;
    shot.setBackground({ ...shot.background, type: tab.dataset.type });
    renderEditor();
  });
});

document.getElementById('bgSolidColor').addEventListener('change', e => {
  const shot = activeShot();
  if (shot) { shot.setBackground({ type: 'solid', color: e.target.value }); renderCanvas(); }
});

document.getElementById('bgGradColor1').addEventListener('change', applyGradient);
document.getElementById('bgGradColor2').addEventListener('change', applyGradient);
document.getElementById('bgGradAngle').addEventListener('input',   applyGradient);

function applyGradient() {
  const shot = activeShot();
  if (!shot) return;
  const angle = parseInt(document.getElementById('bgGradAngle').value);
  document.getElementById('bgGradAngleVal').textContent = angle + '°';
  shot.setBackground({
    type:   'gradient',
    colors: [document.getElementById('bgGradColor1').value,
             document.getElementById('bgGradColor2').value],
    angle,
  });
  renderCanvas();
}

document.querySelectorAll('.preset-swatch').forEach(swatch => {
  swatch.addEventListener('click', () => {
    const shot = activeShot();
    if (shot) {
      shot.setBackground({ type: 'gradient', ...JSON.parse(swatch.dataset.gradient) });
      renderCanvas();
    }
  });
});

// ── Inspector: text layers ────────────────────────────────────────────────────

document.getElementById('addTextBtn').addEventListener('click', () => {
  const shot = activeShot();
  if (shot) { shot.addTextLayer(); renderEditor(); }
});

document.addEventListener('textSelected', () => {
  renderTextLayersList(activeShot());
});

// ── Init ──────────────────────────────────────────────────────────────────────

initCanvasDrag();   // wire bezel drag once on the persistent canvasWrapper

initDevices().then(() => {
  populateDeviceDropdown(document.getElementById('deviceSelect'));
  showGallery();    // starts empty — user adds locales via picker
});
