// Inspector panel — renders property editors for the active screenshot:
// canvas size, device frame, background (solid/gradient), and text layers.

function renderInspector() {
  const locale = project.localeByCode(ui.activeLocale);
  const shot   = locale?.screenshotById(ui.activeShotId) ?? null;

  if (locale) document.getElementById('displayTypeSelect').value = locale.displayType;
  if (!shot)  return;

  document.getElementById('deviceSelect').value = shot.device ?? '';

  const bg     = shot.background ?? { type: 'gradient', colors: ['#1a1a2e', '#0f3460'], angle: 135 };
  const bgType = bg.type ?? 'gradient';

  document.querySelectorAll('.bg-tab')
    .forEach(t => t.classList.toggle('active', t.dataset.type === bgType));
  document.getElementById('bgSolid').classList.toggle('hidden',    bgType !== 'solid');
  document.getElementById('bgGradient').classList.toggle('hidden', bgType !== 'gradient');

  if (bgType === 'solid') {
    document.getElementById('bgSolidColor').value = bg.color ?? '#1a1a2e';
  } else {
    document.getElementById('bgGradColor1').value       = (bg.colors ?? [])[0] ?? '#1a1a2e';
    document.getElementById('bgGradColor2').value       = (bg.colors ?? [])[1] ?? '#0f3460';
    document.getElementById('bgGradAngle').value        = bg.angle ?? 135;
    document.getElementById('bgGradAngleVal').textContent = (bg.angle ?? 135) + '°';
  }

  renderTextLayersList(shot);
}

// ── Text layers list ──────────────────────────────────────────────────────────

function renderTextLayersList(shot) {
  const list = document.getElementById('textLayersList');
  list.innerHTML = '';
  if (!shot?.texts?.length) return;

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
          <input type="text"   class="txt-content" data-id="${t.id}" value="${t.content || ''}">
        </div>
        <div class="text-prop">
          <label>Size</label>
          <input type="number" class="txt-size"    data-id="${t.id}" value="${t.fontSize || 52}" min="8" max="200">
        </div>
        <div class="text-prop">
          <label>Color</label>
          <input type="color"  class="txt-color"   data-id="${t.id}" value="${t.color || '#ffffff'}">
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
      shot.removeTextLayer(t.id);
      renderEditor();   // full rebuild — layer removed from the list
    });

    // For live edits: update data + redraw canvas only.
    // Do NOT call renderEditor() here — that would rebuild the DOM and lose focus.
    item.querySelector('.txt-content').addEventListener('input', e => {
      t.content = e.target.value;
      item.querySelector('.text-layer-preview').textContent = t.content || '(empty)';
      renderCanvas();
    });
    item.querySelector('.txt-size').addEventListener('change',   e => { t.fontSize   = parseInt(e.target.value) || 52; renderCanvas(); });
    item.querySelector('.txt-color').addEventListener('change',  e => { t.color      = e.target.value;                 renderCanvas(); });
    item.querySelector('.txt-weight').addEventListener('change', e => { t.fontWeight = e.target.value;                 renderCanvas(); });
    item.querySelector('.txt-align').addEventListener('change',  e => { t.align      = e.target.value;                 renderCanvas(); });

    list.appendChild(item);
  });
}
