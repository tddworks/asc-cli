// ════════════════════════════════════════════════════════════════════════════
// Domain Model
//
// Mental model:  ScreenshotProject → Locale → Screenshot
//
// A user manages a Screenshot Project for their app.  The project holds
// Localizations; each Localization has ordered Screenshots with backgrounds,
// device frames, uploaded images, and text labels.
// The first locale added becomes the Primary — new locales inherit its
// display type and screenshot count.
// ════════════════════════════════════════════════════════════════════════════

class Screenshot {
  constructor(order) {
    this.id           = 'ss_' + Date.now() + '_' + Math.random().toString(36).slice(2);
    this.order        = order;
    this.sourceImage  = null;   // HTMLImageElement | null
    this.device       = '';     // device frame name (key into DEVICES_MAP)
    this.background   = { type: 'gradient', colors: ['#1a1a2e', '#0f3460'], angle: 135 };
    this.texts        = [];     // TextLayer[]
    this.frameOffsetX = 0;
    this.frameOffsetY = 0;
  }

  // ── Semantic state ─────────────────────────────────────────────────────────

  get isEmpty() { return !this.sourceImage; }

  // ── Mutations ──────────────────────────────────────────────────────────────

  setSourceImage(img) { this.sourceImage = img; }
  setDevice(name)     { this.device = name; }
  setBackground(bg)   { this.background = { ...bg }; }

  addTextLayer() {
    const layer = createTextLayer();   // createTextLayer is defined in texts.js
    this.texts.push(layer);
    return layer;
  }

  removeTextLayer(id) {
    this.texts = this.texts.filter(t => t.id !== id);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class Locale {
  constructor(code, displayType, screenshotCount = 1) {
    this.code        = code;
    this.displayType = displayType;
    this.screenshots = Array.from({ length: screenshotCount },
                                  (_, i) => new Screenshot(i + 1));
  }

  // ── Reads ──────────────────────────────────────────────────────────────────

  get canAddMore() { return this.screenshots.length < 10; }

  screenshotById(id) {
    return this.screenshots.find(s => s.id === id) ?? null;
  }

  // ── Mutations ──────────────────────────────────────────────────────────────

  addScreenshot() {
    if (!this.canAddMore) return null;
    const shot = new Screenshot(this.screenshots.length + 1);
    this.screenshots.push(shot);
    return shot;
  }

  removeScreenshot(id) {
    this.screenshots = this.screenshots.filter(s => s.id !== id);
    this.screenshots.forEach((s, i) => { s.order = i + 1; });
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class ScreenshotProject {
  constructor() {
    this._locales = [];   // Locale[] — ordered; first entry is the Primary locale
  }

  // ── Reads ──────────────────────────────────────────────────────────────────

  get locales()       { return this._locales; }
  get primaryLocale() { return this._locales[0] ?? null; }
  get isEmpty()       { return this._locales.length === 0; }

  get stats() {
    return {
      localeCount: this._locales.length,
      totalShots:  this._locales.reduce((n, l) => n + l.screenshots.length, 0),
    };
  }

  isPrimary(code)    { return this.primaryLocale?.code === code; }
  localeByCode(code) { return this._locales.find(l => l.code === code) ?? null; }

  // ── Mutations ──────────────────────────────────────────────────────────────

  addLocale(code) {
    if (this.localeByCode(code)) return null;   // already exists
    const primary = this.primaryLocale;
    const locale  = new Locale(
      code,
      primary?.displayType       ?? 'APP_IPHONE_67',
      primary?.screenshots.length ?? 1,
    );
    this._locales.push(locale);
    return locale;
  }

  removeLocale(code) {
    this._locales = this._locales.filter(l => l.code !== code);
  }
}
