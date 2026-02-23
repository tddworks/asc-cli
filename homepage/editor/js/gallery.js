// Gallery view — renders all locales and their screenshot thumbnail grids.
// Each locale section shows a flag + name + badge header, and a row of
// clickable portrait cards.  Clicking a card opens the editor for that shot.

function renderGallery() {
  const container = document.getElementById('galleryLocalesContainer');
  const emptyEl   = document.getElementById('galleryEmpty');
  const footerEl  = document.getElementById('galleryFooter');
  const statsEl   = document.getElementById('galleryStats');
  container.innerHTML = '';

  // Always toggle empty/footer before any return
  emptyEl.classList.toggle('hidden', !project.isEmpty);
  footerEl.classList.toggle('hidden', project.isEmpty);
  if (project.isEmpty) return;

  const { localeCount, totalShots } = project.stats;
  statsEl.textContent =
    `${localeCount} locale${localeCount !== 1 ? 's' : ''} · ` +
    `${totalShots} capture${totalShots !== 1 ? 's' : ''}`;

  for (const locale of project.locales) {
    container.appendChild(buildLocaleSection(locale));
  }

  // ── Wire card clicks (delegated would survive re-renders but innerHTML
  //    is rebuilt anyway, so direct wiring is fine here) ──────────────────────
  container.querySelectorAll('.screenshot-gallery-card:not(.screenshot-gallery-card-add)')
    .forEach(card => {
      card.addEventListener('click', () => showEditor(card.dataset.locale, card.dataset.id));
    });

  container.querySelectorAll('.screenshot-gallery-card-add').forEach(card => {
    card.addEventListener('click', () => {
      const locale = project.localeByCode(card.dataset.locale);
      const shot   = locale?.addScreenshot();
      if (shot) showEditor(card.dataset.locale, shot.id);
    });
  });

  container.querySelectorAll('.btn-locale-delete').forEach(btn => {
    btn.addEventListener('click', e => {
      e.stopPropagation();
      project.removeLocale(btn.dataset.locale);
      renderGallery();
    });
  });
}

// ── Section builder ───────────────────────────────────────────────────────────

function buildLocaleSection(locale) {
  const outSize   = DISPLAY_TYPE_SIZES[locale.displayType] ?? { width: 1290, height: 2796 };
  const ar        = outSize.width / outSize.height;
  const shotCount = locale.screenshots.length;

  const section = document.createElement('div');
  section.className = 'locale-section';

  const header = document.createElement('div');
  header.className = 'locale-section-header';
  header.innerHTML = `
    <div class="locale-section-title">
      <span class="locale-flag">${localeFlag(locale.code)}</span>
      <span class="locale-name">${localeName(locale.code)}</span>
      ${project.isPrimary(locale.code)
        ? '<span class="locale-primary-badge">Primary</span>'
        : ''}
      <span class="locale-shot-badge">${shotCount} shot${shotCount !== 1 ? 's' : ''}</span>
    </div>
    <div class="locale-section-actions">
      ${!project.isPrimary(locale.code)
        ? `<button class="btn-locale-delete" data-locale="${locale.code}">Delete</button>`
        : ''}
    </div>
  `;

  const grid = document.createElement('div');
  grid.className = 'screenshot-gallery-grid';

  for (const shot of locale.screenshots) {
    grid.appendChild(buildShotCard(locale, shot, outSize, ar));
  }

  if (locale.canAddMore) {
    const addCard = document.createElement('div');
    addCard.className = 'screenshot-gallery-card screenshot-gallery-card-add';
    addCard.dataset.locale = locale.code;
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

// ── Card builder ──────────────────────────────────────────────────────────────

function buildShotCard(locale, shot, outSize, ar) {
  const card = document.createElement('div');
  card.className      = 'screenshot-gallery-card';
  card.dataset.locale = locale.code;
  card.dataset.id     = shot.id;
  card.style.setProperty('--ar', ar.toString());

  const bg    = shot.background ?? { type: 'gradient', colors: ['#1a1a2e', '#0f3460'], angle: 135 };
  const bgCSS = bg.type === 'solid'
    ? `background:${bg.color ?? '#1a1a2e'};`
    : `background:linear-gradient(${bg.angle ?? 135}deg,${(bg.colors ?? ['#1a1a2e','#0f3460'])[0]},${(bg.colors ?? ['#1a1a2e','#0f3460'])[1]});`;

  const imgHTML   = shot.sourceImage
    ? `<img class="gallery-card-img" src="${shot.sourceImage.src}" alt="">`
    : '';
  const emptyHTML = shot.isEmpty ? `
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
