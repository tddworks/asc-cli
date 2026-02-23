// Draggable text layer management

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
  overlay.innerHTML = '';
  if (!screenshot || !screenshot.texts) return;

  // scale = displayScale (e.g. 0.33).
  // canvasWrapper is sized at outSize × scale CSS pixels,
  // so all positions and font sizes must be multiplied by scale.
  const texts = screenshot.texts;

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
      t.x = Math.max(0, Math.min(100, dragStart.tx + dx));
      t.y = Math.max(0, Math.min(100, dragStart.ty + dy));
      // Update position in scaled coords
      el.style.left = (t.x / 100 * outSize.width  * scale) + 'px';
      el.style.top  = (t.y / 100 * outSize.height * scale) + 'px';
    });

    el.addEventListener('pointerup', () => {
      if (dragStart) { onUpdate(); dragStart = null; }
    });

    overlay.appendChild(el);
  });
}
