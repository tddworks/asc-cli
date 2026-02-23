// Locale picker modal — lets users select one or more locales to add.
// Opens as a sheet with the full list; already-added locales are dimmed.
// Calls back into the project and re-renders the active view on confirm.

let _pickerSelected = new Set();

function openLocalePicker() {
  _pickerSelected.clear();

  const list    = document.getElementById('localeModalList');
  const confirm = document.getElementById('localeModalConfirm');
  list.innerHTML = '';

  for (const loc of ALL_LOCALES) {
    const alreadyAdded = !!project.localeByCode(loc.code);
    const item = document.createElement('div');
    item.className   = 'locale-list-item' + (alreadyAdded ? ' locale-list-item-added' : '');
    item.dataset.code = loc.code;
    item.innerHTML = `
      <span class="locale-list-flag">${loc.flag}</span>
      <span class="locale-list-name">${loc.name}</span>
      <span class="locale-list-code">${loc.code.replace('-', '_')}</span>
      <span class="locale-list-check">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
          <polyline points="20 6 9 17 4 12"/>
        </svg>
      </span>
    `;

    if (!alreadyAdded) {
      item.addEventListener('click', () => {
        const isSelected = _pickerSelected.has(loc.code);
        if (isSelected) {
          _pickerSelected.delete(loc.code);
          item.classList.remove('selected');
        } else {
          _pickerSelected.add(loc.code);
          item.classList.add('selected');
        }
        confirm.disabled = _pickerSelected.size === 0;
      });
    }

    list.appendChild(item);
  }

  confirm.disabled = true;
  document.getElementById('localeModal').classList.remove('hidden');
}

function closeLocalePicker() {
  document.getElementById('localeModal').classList.add('hidden');
  _pickerSelected.clear();
}

function confirmAddLocales() {
  if (_pickerSelected.size === 0) return;
  for (const code of _pickerSelected) project.addLocale(code);
  closeLocalePicker();
  // Re-render whichever view is active
  if (ui.view === 'gallery') renderGallery();
  else renderEditor();
}
