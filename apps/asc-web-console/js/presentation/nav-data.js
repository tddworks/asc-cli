// Presentation: Navigation structure — maps features to CLI commands
export const NAV = [
  { group: 'Overview', items: [
    { id: 'dashboard', label: 'Dashboard', icon: 'grid' },
  ]},
  { group: 'App Management', items: [
    { id: 'apps', label: 'Apps', icon: 'box', cmds: ['apps list'] },
    { id: 'versions', label: 'Versions', icon: 'layers', cmds: ['versions list','versions create','versions submit','versions set-build','versions check-readiness'] },
    { id: 'localizations', label: 'Localizations', icon: 'globe', cmds: ['version-localizations list','version-localizations create','version-localizations update'] },
    { id: 'screenshots', label: 'Screenshots', icon: 'image', cmds: ['screenshot-sets list','screenshot-sets create','screenshots list','screenshots upload','screenshots import'] },
    { id: 'previews', label: 'App Previews', icon: 'play', cmds: ['app-preview-sets list','app-preview-sets create','app-previews list','app-previews upload'] },
    { id: 'appinfo', label: 'App Info', icon: 'info', cmds: ['app-infos list','app-infos update','app-info-localizations list','app-info-localizations create','app-info-localizations update','app-info-localizations delete','age-rating get','age-rating update','app-categories list'] },
    { id: 'appclips', label: 'App Clips', icon: 'scissors', cmds: ['app-clips list','app-clip-experiences list','app-clip-experiences create','app-clip-experiences delete','app-clip-experience-localizations list','app-clip-experience-localizations create','app-clip-experience-localizations delete'] },
  ]},
  { group: 'Distribution', items: [
    { id: 'builds', label: 'Builds', icon: 'package', cmds: ['builds list','builds upload','builds archive','builds uploads','builds add-beta-group','builds remove-beta-group','builds update-beta-notes'] },
    { id: 'testflight', label: 'TestFlight', icon: 'send', cmds: ['testflight groups list','testflight testers list','testflight testers add','testflight testers remove','testflight testers import','testflight testers export'] },
    { id: 'reviews', label: 'Reviews', icon: 'star', cmds: ['reviews list','reviews get','review-responses get','review-responses create','review-responses delete','version-review-detail get','version-review-detail update'] },
    { id: 'betareview', label: 'Beta Review', icon: 'check-circle', cmds: ['beta-review submissions list','beta-review submissions create','beta-review submissions get','beta-review detail get','beta-review detail update'] },
  ]},
  { group: 'Monetization', items: [
    { id: 'iap', label: 'In-App Purchases', icon: 'shopping-cart', cmds: ['iap list','iap create','iap submit','iap-localizations list','iap-localizations create','iap-price-points list','iap-prices set'] },
    { id: 'subscriptions', label: 'Subscriptions', icon: 'repeat', cmds: ['subscription-groups list','subscription-groups create','subscriptions list','subscriptions create','subscriptions submit','subscription-localizations list','subscription-localizations create','subscription-offers list','subscription-offers create'] },
    { id: 'offercodes', label: 'Offer Codes', icon: 'tag', cmds: ['subscription-offer-codes list','subscription-offer-codes create','iap-offer-codes list','iap-offer-codes create'] },
    { id: 'reports', label: 'Reports', icon: 'bar-chart', cmds: ['sales-reports download','finance-reports download','analytics-reports request','analytics-reports list'] },
  ]},
  { group: 'Development', items: [
    { id: 'codesigning', label: 'Code Signing', icon: 'shield', cmds: ['bundle-ids list','bundle-ids create','certificates list','certificates create','devices list','devices register','profiles list','profiles create'] },
    { id: 'xcodecloud', label: 'Xcode Cloud', icon: 'cloud', cmds: ['xcode-cloud products list','xcode-cloud workflows list','xcode-cloud builds list','xcode-cloud builds get','xcode-cloud builds start'] },
    { id: 'gamecenter', label: 'Game Center', icon: 'trophy', cmds: ['game-center detail get','game-center achievements list','game-center achievements create','game-center leaderboards list','game-center leaderboards create'] },
    { id: 'performance', label: 'Performance', icon: 'activity', cmds: ['perf-metrics list','diagnostics list','diagnostic-logs list'] },
  ]},
  { group: 'Tools', items: [
    { id: 'appshots', label: 'App Shots', icon: 'camera', cmds: ['app-shots generate','app-shots translate','app-shots html','app-shots config'] },
    { id: 'availability', label: 'Availability', icon: 'map', cmds: ['app-availability get','iap-availability get','subscription-availability get','territories list'] },
  ]},
  { group: 'Settings', items: [
    { id: 'auth', label: 'Authentication', icon: 'key', cmds: ['auth login','auth logout','auth check','auth list','auth use','auth update'] },
    { id: 'users', label: 'Users & Teams', icon: 'users', cmds: ['users list','users update','users remove','user-invitations list','user-invitations invite','user-invitations cancel'] },
    { id: 'plugins', label: 'Plugins', icon: 'puzzle', cmds: ['plugins list','plugins install','plugins uninstall','plugins enable','plugins disable','plugins run'] },
    { id: 'skills', label: 'Skills', icon: 'zap', cmds: ['skills list','skills install','skills uninstall','skills installed','skills check','skills update'] },
  ]},
];

export function getPageData(id) {
  for (const section of NAV) {
    for (const item of section.items) {
      if (item.id === id) return item;
    }
  }
  return null;
}

export function getAllCommands() {
  const cmds = [];
  NAV.forEach(g => g.items.forEach(item => {
    if (item.cmds) item.cmds.forEach(c => cmds.push({ cmd: `asc ${c}`, label: item.label, icon: item.icon }));
  }));
  return cmds;
}
