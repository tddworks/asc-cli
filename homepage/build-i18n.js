#!/usr/bin/env node

/**
 * i18n Build Script — asc CLI Landing Page
 * Usage: node build-i18n.js
 */

const fs = require('fs');
const path = require('path');

const HOMEPAGE_DIR = __dirname;
const OUTPUT_DIR = HOMEPAGE_DIR;
const I18N_DIR = path.join(HOMEPAGE_DIR, 'i18n');
const TEMPLATE_FILE = path.join(HOMEPAGE_DIR, 'template.html');

const config = {
  defaultLang: 'en',
  baseUrl: 'https://tddworks.github.io/asc-cli/homepage',
  languages: {
    en: {
      output: 'index.html',
      htmlLang: 'en',
      fontFamily: "'JetBrains Mono', 'Outfit', -apple-system, BlinkMacSystemFont, sans-serif"
    },
    zh: {
      output: 'zh/index.html',
      htmlLang: 'zh-Hans',
      fontFamily: "'JetBrains Mono', 'Outfit', 'Noto Sans SC', -apple-system, BlinkMacSystemFont, sans-serif",
      extraFonts: 'family=Noto+Sans+SC:wght@300;400;500;600;700&'
    }
  }
};

const langLabels = {
  en: 'EN',
  zh: '简体中文'
};

function get(obj, keyPath, defaultValue = '') {
  const result = keyPath.split('.').reduce((acc, part) => acc?.[part], obj);
  return result !== undefined ? result : defaultValue;
}

function interpolate(template, translations, lang) {
  return template.replace(/\{\{([^}]+)\}\}/g, (match, key) => {
    const value = get(translations, key.trim());
    if (value === '') console.warn(`  Warning: Missing key "${key}" for ${lang}`);
    return value;
  });
}

function generateLangDropdownItems(currentLang) {
  return Object.entries(config.languages).map(([lang, cfg]) => {
    const isActive = lang === currentLang;
    let href;
    if (currentLang === config.defaultLang) {
      href = lang === config.defaultLang ? 'index.html' : cfg.output;
    } else {
      href = lang === config.defaultLang ? '../index.html' : `../${cfg.output}`;
    }
    const label = langLabels[lang] || lang.toUpperCase();
    const activeClass = isActive ? ' active' : '';
    const check = `<svg class="lang-check" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 6L9 17l-5-5"/></svg>`;
    return `<a href="${href}" class="lang-dropdown-item${activeClass}">${check}<span>${label}</span></a>`;
  }).join('\n          ');
}

function getCanonicalUrl(lang) {
  if (lang === config.defaultLang) return `${config.baseUrl}/`;
  return `${config.baseUrl}/${config.languages[lang].output.replace('/index.html', '/')}`;
}

function generateHreflangLinks(currentLang) {
  const links = Object.entries(config.languages).map(([lang, cfg]) => {
    let href;
    if (currentLang === config.defaultLang) {
      href = lang === config.defaultLang ? 'index.html' : cfg.output;
    } else {
      href = lang === config.defaultLang ? '../index.html' : `../${cfg.output}`;
    }
    return `<link rel="alternate" hreflang="${cfg.htmlLang}" href="${href}">`;
  });
  const defaultHref = currentLang === config.defaultLang ? 'index.html' : '../index.html';
  links.push(`<link rel="alternate" hreflang="x-default" href="${defaultHref}">`);
  return links.join('\n  ');
}

function adjustAssetPaths(html, lang) {
  if (lang === config.defaultLang) return html;
  return html
    .replace(/href="static\//g, 'href="../static/')
    .replace(/src="static\//g, 'src="../static/')
    .replace(/href="styles\//g, 'href="../styles/')
    .replace(/src="components\//g, 'src="../components/');
}

function build() {
  console.log('Building asc CLI landing page...\n');

  if (!fs.existsSync(TEMPLATE_FILE)) {
    console.error(`Error: template.html not found`);
    process.exit(1);
  }

  const template = fs.readFileSync(TEMPLATE_FILE, 'utf8');

  for (const [lang, langConfig] of Object.entries(config.languages)) {
    console.log(`Processing: ${lang}`);
    const i18nFile = path.join(I18N_DIR, `${lang}.json`);
    if (!fs.existsSync(i18nFile)) { console.warn(`  Skipping: ${i18nFile} not found`); continue; }

    const translations = JSON.parse(fs.readFileSync(i18nFile, 'utf8'));
    let html = template;

    html = html.replace('{{HTML_LANG}}', langConfig.htmlLang);
    html = html.replace('{{LANG_DROPDOWN_ITEMS}}', generateLangDropdownItems(lang));
    html = html.replace('{{CURRENT_LANG_LABEL}}', langLabels[lang] || lang.toUpperCase());
    html = html.replace('{{HREFLANG_LINKS}}', generateHreflangLinks(lang));
    html = html.replace(/\{\{CANONICAL_URL\}\}/g, getCanonicalUrl(lang));
    html = html.replace('{{FONT_FAMILY}}', langConfig.fontFamily);
    html = html.replace('{{EXTRA_FONTS}}', langConfig.extraFonts || '');

    html = interpolate(html, translations, lang);
    html = adjustAssetPaths(html, lang);

    const outputPath = path.join(OUTPUT_DIR, langConfig.output);
    const outputDir = path.dirname(outputPath);
    if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir, { recursive: true });

    fs.writeFileSync(outputPath, html, 'utf8');
    console.log(`  ✓ Created: ${langConfig.output}`);
  }

  console.log('\nBuild complete!');
  console.log('  Preview: open homepage/index.html');
}

build();
