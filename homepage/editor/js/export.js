// ZIP export using JSZip.
// Iterates project.locales (an array of Locale instances) and renders
// each screenshot to PNG at full App Store resolution.

async function exportProject(proj) {
  const zip = new JSZip();
  const manifest = {
    version:       '1.0',
    exportedAt:    new Date().toISOString(),
    localizations: {},
  };

  for (const locale of proj.locales) {
    const outSize = DISPLAY_TYPE_SIZES[locale.displayType] ?? { width: 1290, height: 2796 };
    manifest.localizations[locale.code] = {
      displayType: locale.displayType,
      screenshots: [],
    };
    const folder = zip.folder(locale.code);

    for (const shot of locale.screenshots) {
      const filename = `${shot.order}.png`;
      const blob     = await exportScreenshotToPNG(shot, outSize);
      if (blob) folder.file(filename, blob);
      manifest.localizations[locale.code].screenshots.push({
        order:      shot.order,
        file:       `${locale.code}/${filename}`,
        device:     shot.device     || null,
        background: shot.background || null,
        texts:      shot.texts      || [],
      });
    }
  }

  zip.file('manifest.json', JSON.stringify(manifest, null, 2));
  const content = await zip.generateAsync({ type: 'blob' });
  const url = URL.createObjectURL(content);
  const a   = document.createElement('a');
  a.href    = url;
  a.download = 'screenshots.zip';
  a.click();
  setTimeout(() => URL.revokeObjectURL(url), 5000);
}
