// Locale reference data — flags, human-readable names, display type labels.
// ALL_LOCALES is the single source of truth; LOCALE_FLAGS and LOCALE_NAMES
// are derived from it so there is no duplication.

const ALL_LOCALES = [
  { code: 'en-US',   name: 'English (US)',           flag: '🇺🇸' },
  { code: 'en-GB',   name: 'English (UK)',           flag: '🇬🇧' },
  { code: 'en-AU',   name: 'English (Australia)',    flag: '🇦🇺' },
  { code: 'en-CA',   name: 'English (Canada)',       flag: '🇨🇦' },
  { code: 'ja',      name: 'Japanese',               flag: '🇯🇵' },
  { code: 'zh-Hans', name: 'Chinese (Simplified)',   flag: '🇨🇳' },
  { code: 'zh-Hant', name: 'Chinese (Traditional)', flag: '🇹🇼' },
  { code: 'ko',      name: 'Korean',                 flag: '🇰🇷' },
  { code: 'fr',      name: 'French',                 flag: '🇫🇷' },
  { code: 'de',      name: 'German',                 flag: '🇩🇪' },
  { code: 'es',      name: 'Spanish',                flag: '🇪🇸' },
  { code: 'es-MX',   name: 'Spanish (Mexico)',       flag: '🇲🇽' },
  { code: 'it',      name: 'Italian',                flag: '🇮🇹' },
  { code: 'pt-BR',   name: 'Portuguese (Brazil)',    flag: '🇧🇷' },
  { code: 'pt-PT',   name: 'Portuguese (Portugal)', flag: '🇵🇹' },
  { code: 'ru',      name: 'Russian',                flag: '🇷🇺' },
  { code: 'ar',      name: 'Arabic',                 flag: '🇸🇦' },
  { code: 'hi',      name: 'Hindi',                  flag: '🇮🇳' },
  { code: 'tr',      name: 'Turkish',                flag: '🇹🇷' },
  { code: 'nl',      name: 'Dutch',                  flag: '🇳🇱' },
  { code: 'sv',      name: 'Swedish',                flag: '🇸🇪' },
  { code: 'da',      name: 'Danish',                 flag: '🇩🇰' },
  { code: 'fi',      name: 'Finnish',                flag: '🇫🇮' },
  { code: 'nb',      name: 'Norwegian',              flag: '🇳🇴' },
  { code: 'pl',      name: 'Polish',                 flag: '🇵🇱' },
  { code: 'cs',      name: 'Czech',                  flag: '🇨🇿' },
  { code: 'hu',      name: 'Hungarian',              flag: '🇭🇺' },
  { code: 'el',      name: 'Greek',                  flag: '🇬🇷' },
  { code: 'th',      name: 'Thai',                   flag: '🇹🇭' },
  { code: 'id',      name: 'Indonesian',             flag: '🇮🇩' },
  { code: 'uk',      name: 'Ukrainian',              flag: '🇺🇦' },
  { code: 'vi',      name: 'Vietnamese',             flag: '🇻🇳' },
];

// Derived lookups — built once from ALL_LOCALES
const LOCALE_FLAGS = Object.fromEntries(ALL_LOCALES.map(l => [l.code, l.flag]));
const LOCALE_NAMES = Object.fromEntries(ALL_LOCALES.map(l => [l.code, l.name]));

// Short labels shown in the UI (canvas size select, gallery cards)
const DISPLAY_TYPE_SHORT = {
  APP_IPHONE_67:          'iPhone 6.7"',
  APP_IPHONE_65:          'iPhone 6.5"',
  APP_IPHONE_61:          'iPhone 6.1"',
  APP_IPHONE_55:          'iPhone 5.5"',
  APP_IPHONE_47:          'iPhone 4.7"',
  APP_IPAD_PRO_3GEN_129:  'iPad Pro 12.9"',
  APP_IPAD_PRO_3GEN_11:   'iPad Pro 11"',
  APP_IPAD_PRO_129:       'iPad Pro 12.9" (Gen 1-2)',
  APP_IPAD_105:           'iPad 10.5"',
  APP_IPAD_97:            'iPad 9.7"',
  APP_WATCH_ULTRA:        'Apple Watch Ultra',
  APP_DESKTOP:            'Mac',
  IMESSAGE_APP_IPHONE_67: 'iMessage 6.7"',
};

function localeName(code) { return LOCALE_NAMES[code] ?? code; }
function localeFlag(code)  { return LOCALE_FLAGS[code] ?? '🌐'; }
