// Presentation: Navigation structure — maps features to CLI commands
// - entry: commands that work without any parent context (true entry points)
// - workflow: commands reached via affordances in CLI output (need parent IDs)
// - flow: the resource hierarchy path showing how to reach workflow commands

export const NAV = [
  { group: 'Overview', items: [
    { id: 'dashboard', label: 'Dashboard', icon: 'grid' },
  ]},
  { group: 'App Management', items: [
    { id: 'apps', label: 'Apps', icon: 'box',
      entry: ['apps list'],
      workflow: [],
    },
    { id: 'versions', label: 'Versions', icon: 'layers',
      entry: [],
      workflow: ['versions list', 'versions create', 'versions submit', 'versions set-build', 'versions check-readiness'],
      flow: ['apps list', 'versions list --app-id', 'versions submit --version-id'],
    },
    { id: 'localizations', label: 'Localizations', icon: 'globe',
      entry: [],
      workflow: ['version-localizations list', 'version-localizations create', 'version-localizations update'],
      flow: ['apps list', 'versions list --app-id', 'version-localizations list --version-id'],
    },
    { id: 'screenshots', label: 'Screenshots', icon: 'image',
      entry: [],
      workflow: ['screenshot-sets list', 'screenshot-sets create', 'screenshots list', 'screenshots upload', 'screenshots import'],
      flow: ['apps list', 'versions list --app-id', 'version-localizations list --version-id', 'screenshot-sets list --localization-id', 'screenshots upload --set-id --file'],
    },
    { id: 'previews', label: 'App Previews', icon: 'play',
      entry: [],
      workflow: ['app-preview-sets list', 'app-preview-sets create', 'app-previews list', 'app-previews upload'],
      flow: ['apps list', 'versions list --app-id', 'version-localizations list --version-id', 'app-preview-sets list --localization-id', 'app-previews upload --set-id --file'],
    },
    { id: 'appinfo', label: 'App Info', icon: 'info',
      entry: ['app-categories list'],
      workflow: ['app-infos list', 'app-infos update', 'app-info-localizations list', 'app-info-localizations create', 'app-info-localizations update', 'app-info-localizations delete', 'age-rating get', 'age-rating update'],
      flow: ['apps list', 'app-infos list --app-id', 'app-info-localizations list --app-info-id'],
    },
    { id: 'appclips', label: 'App Clips', icon: 'scissors',
      entry: [],
      workflow: ['app-clips list', 'app-clip-experiences list', 'app-clip-experiences create', 'app-clip-experiences delete', 'app-clip-experience-localizations list', 'app-clip-experience-localizations create', 'app-clip-experience-localizations delete'],
      flow: ['apps list', 'app-clips list --app-id', 'app-clip-experiences list --app-clip-id'],
    },
  ]},
  { group: 'Distribution', items: [
    { id: 'builds', label: 'Builds', icon: 'package',
      entry: [],
      workflow: ['builds list', 'builds upload', 'builds archive', 'builds uploads', 'builds add-beta-group', 'builds remove-beta-group', 'builds update-beta-notes'],
      flow: ['apps list', 'builds list --app-id', 'builds add-beta-group --build-id --beta-group-id'],
    },
    { id: 'testflight', label: 'TestFlight', icon: 'send',
      entry: [],
      workflow: ['testflight groups list', 'testflight testers list', 'testflight testers add', 'testflight testers remove', 'testflight testers import', 'testflight testers export'],
      flow: ['apps list', 'testflight groups list --app-id', 'testflight testers list --beta-group-id'],
    },
    { id: 'reviews', label: 'Reviews', icon: 'star',
      entry: [],
      workflow: ['reviews list', 'reviews get', 'review-responses get', 'review-responses create', 'review-responses delete', 'version-review-detail get', 'version-review-detail update'],
      flow: ['apps list', 'reviews list --app-id', 'review-responses create --review-id'],
    },
    { id: 'betareview', label: 'Beta Review', icon: 'check-circle',
      entry: [],
      workflow: ['beta-review submissions list', 'beta-review submissions create', 'beta-review submissions get', 'beta-review detail get', 'beta-review detail update'],
      flow: ['apps list', 'builds list --app-id', 'beta-review submissions create --build-id'],
    },
  ]},
  { group: 'Monetization', items: [
    { id: 'iap', label: 'In-App Purchases', icon: 'shopping-cart',
      entry: [],
      workflow: ['iap list', 'iap create', 'iap submit', 'iap-localizations list', 'iap-localizations create', 'iap-price-points list', 'iap-prices set'],
      flow: ['apps list', 'iap list --app-id', 'iap submit --iap-id'],
    },
    { id: 'subscriptions', label: 'Subscriptions', icon: 'repeat',
      entry: [],
      workflow: ['subscription-groups list', 'subscription-groups create', 'subscriptions list', 'subscriptions create', 'subscriptions submit', 'subscription-localizations list', 'subscription-localizations create', 'subscription-offers list', 'subscription-offers create'],
      flow: ['apps list', 'subscription-groups list --app-id', 'subscriptions list --group-id'],
    },
    { id: 'offercodes', label: 'Offer Codes', icon: 'tag',
      entry: [],
      workflow: ['subscription-offer-codes list', 'subscription-offer-codes create', 'iap-offer-codes list', 'iap-offer-codes create'],
      flow: ['subscriptions list --group-id', 'subscription-offer-codes list --subscription-id'],
    },
    { id: 'reports', label: 'Reports', icon: 'bar-chart',
      entry: [],
      workflow: ['sales-reports download', 'finance-reports download', 'analytics-reports request', 'analytics-reports list'],
      flow: ['auth check', 'sales-reports download --vendor-number --report-type --frequency --report-date'],
    },
  ]},
  { group: 'Development', items: [
    { id: 'codesigning', label: 'Code Signing', icon: 'shield',
      entry: ['bundle-ids list', 'certificates list', 'devices list', 'profiles list'],
      workflow: ['bundle-ids create', 'certificates create', 'devices register', 'profiles create'],
    },
    { id: 'xcodecloud', label: 'Xcode Cloud', icon: 'cloud',
      entry: [],
      workflow: ['xcode-cloud products list', 'xcode-cloud workflows list', 'xcode-cloud builds list', 'xcode-cloud builds get', 'xcode-cloud builds start'],
      flow: ['apps list', 'xcode-cloud products list --app-id', 'xcode-cloud workflows list --product-id', 'xcode-cloud builds start --workflow-id'],
    },
    { id: 'gamecenter', label: 'Game Center', icon: 'trophy',
      entry: [],
      workflow: ['game-center detail get', 'game-center achievements list', 'game-center achievements create', 'game-center leaderboards list', 'game-center leaderboards create'],
      flow: ['apps list', 'game-center detail get --app-id', 'game-center achievements list --detail-id'],
    },
    { id: 'performance', label: 'Performance', icon: 'activity',
      entry: [],
      workflow: ['perf-metrics list', 'diagnostics list', 'diagnostic-logs list'],
      flow: ['apps list', 'builds list --app-id', 'diagnostics list --build-id', 'diagnostic-logs list --signature-id'],
    },
  ]},
  { group: 'Tools', items: [
    { id: 'appshots', label: 'App Shots', icon: 'camera',
      entry: ['app-shots config'],
      workflow: ['app-shots generate', 'app-shots translate', 'app-shots html'],
    },
    { id: 'availability', label: 'Availability', icon: 'map',
      entry: ['territories list'],
      workflow: ['app-availability get', 'iap-availability get', 'subscription-availability get'],
    },
  ]},
  { group: 'Settings', items: [
    { id: 'auth', label: 'Authentication', icon: 'key',
      entry: ['auth check', 'auth list'],
      workflow: ['auth login', 'auth logout', 'auth use', 'auth update'],
    },
    { id: 'users', label: 'Users & Teams', icon: 'users',
      entry: ['users list', 'user-invitations list'],
      workflow: ['users update', 'users remove', 'user-invitations invite', 'user-invitations cancel'],
    },
    { id: 'plugins', label: 'Plugins', icon: 'puzzle',
      entry: ['plugins list'],
      workflow: ['plugins install', 'plugins uninstall', 'plugins enable', 'plugins disable', 'plugins run'],
    },
    { id: 'skills', label: 'Skills', icon: 'zap',
      entry: ['skills list', 'skills installed', 'skills check'],
      workflow: ['skills install', 'skills uninstall', 'skills update'],
    },
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
    if (item.entry) item.entry.forEach(c => cmds.push({ cmd: `asc ${c}`, label: item.label, icon: item.icon }));
    if (item.workflow) item.workflow.forEach(c => cmds.push({ cmd: `asc ${c}`, label: item.label, icon: item.icon }));
  }));
  return cmds;
}
