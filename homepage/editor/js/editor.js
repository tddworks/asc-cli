// Editor view — sidebar (locale tabs + shot slots) + canvas with bezel/overlay.
// Canvas rendering is separated from DOM rendering so zoom stays GPU-only.

// ── Canvas-specific state (owned by this module) ──────────────────────────────
let zoom         = 75;
let displayScale = 0.33;
let bezelDrag    = null;
let rafPending   = false;

// ── Entry point ───────────────────────────────────────────────────────────────

function renderEditor() {
  renderLocaleTabs();
  renderShotSlots();
  renderInspector();   // defined in inspector.js
  renderCanvas();
}

// ── Sidebar: locale tabs ──────────────────────────────────────────────────────

function renderLocaleTabs() {
  const container = document.getElementById('localeTabs');
  container.innerHTML = '';

  for (const locale of project.locales) {
    const tab = document.createElement('div');
    tab.className = 'locale-tab' + (locale.code === ui.activeLocale ? ' active' : '');
    tab.innerHTML = `
      <span>${locale.code}</span>
      <span class="delete-locale" data-locale="${locale.code}" title="Remove">&#x2715;</span>
    `;

    tab.addEventListener('click', e => {
      if (e.target.classList.contains('delete-locale')) return;
      selectLocale(locale.code);
    });

    tab.querySelector('.delete-locale').addEventListener('click', () => {
      project.removeLocale(locale.code);
      if (ui.activeLocale === locale.code) {
        const next = project.locales[0];
        if (next) selectLocale(next.code);
        else      showGallery();
      } else {
        renderEditor();
      }
    });

    container.appendChild(tab);
  }
}

// ── Sidebar: screenshot slots ─────────────────────────────────────────────────

function renderShotSlots() {
  const container = document.getElementById('screenshotSlots');
  container.innerHTML = '';

  const locale = project.localeByCode(ui.activeLocale);
  if (!locale) return;

  for (const shot of locale.screenshots) {
    const el = document.createElement('div');
    el.className = 'screenshot-slot' + (shot.id === ui.activeShotId ? ' active' : '');
    el.innerHTML = `
      <div class="slot-thumb">
        ${shot.sourceImage ? `<img src="${shot.sourceImage.src}">` : ''}
      </div>
      <div class="slot-label"><span class="slot-num">#${shot.order}</span></div>
      <span class="delete-slot" title="Remove">&#x2715;</span>
    `;

    el.addEventListener('click', e => {
      if (e.target.classList.contains('delete-slot')) return;
      ui.activeShotId = shot.id;
      renderEditor();
    });

    el.querySelector('.delete-slot').addEventListener('click', () => {
      locale.removeScreenshot(shot.id);
      if (ui.activeShotId === shot.id) {
        ui.activeShotId = locale.screenshots[0]?.id ?? null;
      }
      renderEditor();
    });

    container.appendChild(el);
  }
}

// ── Canvas ────────────────────────────────────────────────────────────────────

async function renderCanvas() {
  const locale  = project.localeByCode(ui.activeLocale);
  const shot    = locale?.screenshotById(ui.activeShotId) ?? null;
  const outSize = locale
    ? (DISPLAY_TYPE_SIZES[locale.displayType] ?? { width: 1290, height: 2796 })
    : { width: 1290, height: 2796 };

  const canvasEl      = document.getElementById('mainCanvas');
  const canvasWrapper = document.getElementById('canvasWrapper');
  const bezelLayerEl  = document.getElementById('bezelLayer');
  const canvasInfo    = document.getElementById('canvasInfo');

  displayScale = calcDisplayScale(outSize);
  const cssW   = Math.round(outSize.width  * displayScale);
  const cssH   = Math.round(outSize.height * displayScale);

  if (canvasEl.width !== cssW || canvasEl.height !== cssH) {
    canvasEl.width  = cssW;
    canvasEl.height = cssH;
  }
  canvasWrapper.style.width  = cssW + 'px';
  canvasWrapper.style.height = cssH + 'px';

  if (!shot) {
    const ctx = canvasEl.getContext('2d');
    ctx.fillStyle = '#0e0e18';
    ctx.fillRect(0, 0, cssW, cssH);
    canvasInfo.textContent     = 'No screenshot selected';
    bezelLayerEl.style.display = 'none';
    return;
  }

  drawBg(canvasEl, shot.background);

  if (!shot.device || !shot.sourceImage) {
    bezelLayerEl.style.display = 'none';
    if (shot.sourceImage) {
      const ctx = canvasEl.getContext('2d');
      const sw = shot.sourceImage.width, sh = shot.sourceImage.height;
      const s  = Math.max(cssW / sw, cssH / sh);
      ctx.drawImage(shot.sourceImage,
                    (cssW - sw * s) / 2, (cssH - sh * s) / 2,
                    sw * s, sh * s);
    }
  } else {
    await updateBezelLayer(bezelLayerEl, shot, cssW, cssH);
    applyBezelZoom(bezelLayerEl, zoom);
  }

  canvasInfo.textContent = `${outSize.width} × ${outSize.height}`;
  renderTextOverlay(shot, canvasWrapper, outSize, displayScale, renderCanvas);
}

function calcDisplayScale(outSize) {
  const viewport = document.getElementById('canvasViewport');
  if (!viewport?.clientWidth) return 0.33;
  return Math.min(
    (viewport.clientWidth  - 48) / outSize.width,
    (viewport.clientHeight - 48) / outSize.height,
    1.0,
  );
}

// ── Locale selection ──────────────────────────────────────────────────────────

function selectLocale(code) {
  ui.activeLocale = code;
  const locale    = project.localeByCode(code);
  ui.activeShotId = locale?.screenshots[0]?.id ?? null;
  renderEditor();
}

// ── Bezel drag — wired once on the persistent canvasWrapper element ───────────

function initCanvasDrag() {
  const canvasWrapper = document.getElementById('canvasWrapper');

  canvasWrapper.addEventListener('pointerdown', e => {
    const locale = project.localeByCode(ui.activeLocale);
    const shot   = locale?.screenshotById(ui.activeShotId);
    if (!shot) return;
    bezelDrag = {
      px: e.clientX, py: e.clientY,
      ox: shot.frameOffsetX ?? 0, oy: shot.frameOffsetY ?? 0,
    };
    canvasWrapper.setPointerCapture(e.pointerId);
    canvasWrapper.classList.add('dragging');
    e.preventDefault();
  });

  canvasWrapper.addEventListener('pointermove', e => {
    if (!bezelDrag) return;
    const locale = project.localeByCode(ui.activeLocale);
    const shot   = locale?.screenshotById(ui.activeShotId);
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
}
