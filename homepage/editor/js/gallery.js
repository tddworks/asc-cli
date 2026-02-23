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

  // After the sync DOM render, generate composited thumbnails asynchronously.
  // Each thumbnail replaces the CSS-background placeholder with the full
  // composited view (background + bezel + screenshot + frame).
  generateComposedThumbnails();

  // ── Wire card clicks (delegated would survive re-renders but innerHTML
  //    is rebuilt anyway, so direct wiring is fine here) ──────────────────────
  container.querySelectorAll('.screenshot-gallery-card:not(.screenshot-gallery-card-add)')
    .forEach(card => {
      card.addEventListener('click', () => showEditor(card.dataset.locale, card.dataset.id));

      // Drag-and-drop image onto card
      card.addEventListener('dragover', e => {
        e.preventDefault();
        card.classList.add('drag-over');
      });
      card.addEventListener('dragleave', () => card.classList.remove('drag-over'));
      card.addEventListener('drop', e => {
        e.preventDefault();
        card.classList.remove('drag-over');
        const file = e.dataTransfer.files[0];
        if (!file || !file.type.startsWith('image/')) return;
        const reader = new FileReader();
        reader.onload = ev => {
          const img = new Image();
          img.onload = () => {
            const locale = project.localeByCode(card.dataset.locale);
            const shot   = locale?.screenshotById(card.dataset.id);
            if (shot) { shot.setSourceImage(img); renderGallery(); }
          };
          img.src = ev.target.result;
        };
        reader.readAsDataURL(file);
      });
    });

  container.querySelectorAll('.screenshot-gallery-card-add').forEach(card => {
    card.addEventListener('click', () => {
      const locale = project.localeByCode(card.dataset.locale);
      const shot   = locale?.addScreenshot();
      if (shot) showEditor(card.dataset.locale, shot.id);
    });

    // Drag-and-drop onto Add card: create shot + set image immediately
    card.addEventListener('dragover', e => {
      e.preventDefault();
      card.classList.add('drag-over');
    });
    card.addEventListener('dragleave', () => card.classList.remove('drag-over'));
    card.addEventListener('drop', e => {
      e.preventDefault();
      card.classList.remove('drag-over');
      const file = e.dataTransfer.files[0];
      if (!file || !file.type.startsWith('image/')) return;
      const reader = new FileReader();
      reader.onload = ev => {
        const img = new Image();
        img.onload = () => {
          const locale = project.localeByCode(card.dataset.locale);
          const shot   = locale?.addScreenshot();
          if (shot) { shot.setSourceImage(img); renderGallery(); }
        };
        img.src = ev.target.result;
      };
      reader.readAsDataURL(file);
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

// ── Composited thumbnails (async, non-blocking) ───────────────────────────────
// Renders each shot at card-width resolution and updates the card in-place.
// Uses the same compositor path as ZIP export so thumbnails reflect background,
// device frame, and image exactly as they appear on the full-res canvas.

async function generateComposedThumbnails() {
  const CARD_W    = 200;
  const bezelZoom = typeof zoom !== 'undefined' ? zoom : 75;

  for (const locale of project.locales) {
    const outSize   = DISPLAY_TYPE_SIZES[locale.displayType] ?? { width: 1290, height: 2796 };
    const ar        = outSize.width / outSize.height;
    const thumbSize = { width: CARD_W, height: Math.round(CARD_W / ar) };

    for (const shot of locale.screenshots) {
      // Don't generate (or inject) a thumbnail for empty shots — the camera-icon
      // placeholder must remain visible so the user knows to add an image.
      if (shot.isEmpty) continue;

      const canvas = await composeShotThumbnail(shot, outSize, thumbSize, bezelZoom);
      const url    = canvas.toDataURL('image/jpeg', 0.88);
      shot._thumbnailUrl = url;

      const thumb = document.querySelector(
        `.screenshot-gallery-card[data-locale="${locale.code}"][data-id="${shot.id}"] .gallery-card-thumb`
      );
      if (thumb) {
        thumb.style.background    = 'none';
        thumb.style.backgroundImage = '';
        thumb.innerHTML = `<img class="gallery-card-img" src="${url}" alt="">`;
      }
    }
  }
}

// Renders a shot as a thumbnail by compositing at FULL App Store resolution and
// then scaling down.  This guarantees the thumbnail matches the editor exactly:
//
//   - frameOffsetX/Y is in full-res coordinates → correct at full-res, wrong if
//     applied unchanged to a small canvas
//   - text baseline: CSS overlay uses translate(-50%,-50%) so the anchor is the
//     CENTER of the text box → textBaseline:'middle' matches that
//   - font rendering at tiny px sizes can look bad → scale-down produces better AA
//
async function composeShotThumbnail(shot, outSize, thumbSize, bezelZoom) {
  // 1. Composite at full App Store resolution
  const full = document.createElement('canvas');
  await compositeScreenshot(full, shot, outSize, bezelZoom);

  // 2. Bake text layers at full resolution with correct vertical centering
  if (shot.texts?.length) {
    const ctx = full.getContext('2d');
    ctx.textBaseline = 'middle';   // matches CSS: transform translate(-50%,-50%)
    for (const t of shot.texts) {
      const fontStyle = t.fontWeight === 'bold' ? 'bold ' : '';
      ctx.font      = `${fontStyle}${t.fontSize || 48}px -apple-system, "SF Pro Display", sans-serif`;
      ctx.fillStyle = t.color || '#ffffff';
      ctx.textAlign = t.align || 'center';
      ctx.fillText(
        t.content || '',
        (t.x / 100) * outSize.width,
        (t.y / 100) * outSize.height,
      );
    }
  }

  // 3. Scale down to thumbnail size with high-quality interpolation
  const thumb = document.createElement('canvas');
  thumb.width  = thumbSize.width;
  thumb.height = thumbSize.height;
  const tCtx  = thumb.getContext('2d');
  tCtx.imageSmoothingEnabled  = true;
  tCtx.imageSmoothingQuality  = 'high';
  tCtx.drawImage(full, 0, 0, thumbSize.width, thumbSize.height);
  return thumb;
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
        <div class="gallery-card-empty">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/>
            <circle cx="12" cy="13" r="4"/>
          </svg>
          <span>Add</span>
        </div>
      </div>
      <div class="gallery-card-meta">
        <span class="gallery-card-title">Add screenshot</span>
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

  // If a composited thumbnail has been generated (after editor visit), use it —
  // but only when the shot actually has a source image.  Empty shots always show
  // the camera-icon placeholder so the drag target is obvious.
  let thumbContent;
  if (shot._thumbnailUrl && !shot.isEmpty) {
    thumbContent = `<div class="gallery-card-thumb"><img class="gallery-card-img" src="${shot._thumbnailUrl}" alt=""></div>`;
  } else {
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
    thumbContent = `<div class="gallery-card-thumb" style="${bgCSS}">${imgHTML}${emptyHTML}</div>`;
  }

  card.innerHTML = `
    ${thumbContent}
    <div class="gallery-card-meta">
      <span class="gallery-card-title">Screenshot ${shot.order}</span>
      <span class="gallery-card-dims">${outSize.width} × ${outSize.height}</span>
    </div>
  `;
  return card;
}
