// Draggable text layer management + alignment guides (snap to center / other layers)

const SNAP_PCT = 2;   // snap zone in percentage points

let selectedTextId = null;

function createTextLayer(partial = {}) {
  return {
    id:         'txt_' + Date.now() + '_' + Math.random().toString(36).slice(2),
    content:    partial.content    || 'New Text',
    x:          partial.x          ?? 50,
    y:          partial.y          ?? 20,
    fontSize:   partial.fontSize   || 52,
    fontWeight: partial.fontWeight || 'bold',
    color:      partial.color      || '#ffffff',
    align:      partial.align      || 'center',
  };
}

function renderTextOverlay(screenshot, canvasWrapper, outSize, scale, onUpdate) {
  const overlay = canvasWrapper.querySelector('#textLayerOverlay');

  // Remove only draggable text items — preserve alignment guide elements
  overlay.querySelectorAll('.text-overlay-item').forEach(el => el.remove());

  if (!screenshot || !screenshot.texts) return;

  const texts   = screenshot.texts;
  const guideH  = overlay.querySelector('#canvasGuideH');
  const guideV  = overlay.querySelector('#canvasGuideV');

  texts.forEach(t => {
    const el = document.createElement('div');
    el.className = 'text-overlay-item' + (t.id === selectedTextId ? ' selected' : '');
    el.dataset.id = t.id;

    // Position and size in scaled (CSS-pixel) coordinates
    el.style.left       = (t.x / 100 * outSize.width  * scale) + 'px';
    el.style.top        = (t.y / 100 * outSize.height * scale) + 'px';
    el.style.fontSize   = (t.fontSize * scale) + 'px';
    el.style.fontWeight = t.fontWeight || 'normal';
    el.style.color      = t.color      || '#ffffff';
    el.style.textAlign  = t.align      || 'center';
    el.textContent      = t.content    || '';
    el.title            = 'Drag to move';

    let dragStart = null;

    el.addEventListener('pointerdown', (e) => {
      e.stopPropagation();
      selectedTextId = t.id;
      dragStart = { px: e.clientX, py: e.clientY, tx: t.x, ty: t.y };
      el.setPointerCapture(e.pointerId);
      document.dispatchEvent(new CustomEvent('textSelected', { detail: t.id }));
    });

    el.addEventListener('pointermove', (e) => {
      if (!dragStart) return;

      // Convert screen-pixel delta → percentage of full-res canvas
      const dx = (e.clientX - dragStart.px) / scale / outSize.width  * 100;
      const dy = (e.clientY - dragStart.py) / scale / outSize.height * 100;
      let newX = Math.max(0, Math.min(100, dragStart.tx + dx));
      let newY = Math.max(0, Math.min(100, dragStart.ty + dy));

      // ── Snap to center ────────────────────────────────────────────────────
      let snapH = false, snapV = false;
      if (Math.abs(newX - 50) < SNAP_PCT) { newX = 50; snapV = true; }
      if (Math.abs(newY - 50) < SNAP_PCT) { newY = 50; snapH = true; }

      // ── Snap to other text layers ─────────────────────────────────────────
      texts.forEach(other => {
        if (other.id === t.id) return;
        if (Math.abs(newX - other.x) < SNAP_PCT) { newX = other.x; snapV = true; }
        if (Math.abs(newY - other.y) < SNAP_PCT) { newY = other.y; snapH = true; }
      });

      t.x = newX;
      t.y = newY;

      // Position guide lines at the snapped coordinate
      if (guideH) {
        guideH.classList.toggle('visible', snapH);
        if (snapH) guideH.style.top = (t.y / 100 * outSize.height * scale) + 'px';
      }
      if (guideV) {
        guideV.classList.toggle('visible', snapV);
        if (snapV) guideV.style.left = (t.x / 100 * outSize.width * scale) + 'px';
      }

      // Update position in scaled coords
      el.style.left = (t.x / 100 * outSize.width  * scale) + 'px';
      el.style.top  = (t.y / 100 * outSize.height * scale) + 'px';
    });

    el.addEventListener('pointerup', () => {
      if (dragStart) {
        onUpdate();
        dragStart = null;
        guideH?.classList.remove('visible');
        guideV?.classList.remove('visible');
      }
    });

    overlay.appendChild(el);
  });
}
