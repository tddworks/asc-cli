// Infrastructure: Static mock data — mirrors actual `asc` JSON output with {data:[...]}
export const MockDataProvider = {
  // ===== Apps =====
  apps: {
    data: [
      { id: '6449071230', name: 'PhotoSync Pro', bundleId: 'com.example.photosync', sku: 'PHOTOSYNC2024', primaryLocale: 'en-US' },
      { id: '6449071231', name: 'TaskFlow', bundleId: 'com.example.taskflow', sku: 'TASKFLOW2024', primaryLocale: 'en-US' },
      { id: '6449071232', name: 'WeatherLens', bundleId: 'com.example.weatherlens', primaryLocale: 'en-US' },
      { id: '6449071233', name: 'CodePad', bundleId: 'com.example.codepad', primaryLocale: 'en-US' },
      { id: '6449071234', name: 'FitTrack', bundleId: 'com.example.fittrack', primaryLocale: 'en-US' },
      { id: '6449071235', name: 'MindMap Studio', bundleId: 'com.example.mindmap', primaryLocale: 'en-US' },
    ],
  },

  // ===== Versions — with appId parent =====
  versions: {
    '6449071230': {
      data: [
        { id: 'v-ps-001', appId: '6449071230', versionString: '2.1.0', platform: 'IOS', state: 'READY_FOR_SALE', createdDate: '2026-03-10T10:00:00Z', buildId: 'b-ps-003' },
        { id: 'v-ps-002', appId: '6449071230', versionString: '2.2.0', platform: 'IOS', state: 'PREPARE_FOR_SUBMISSION', createdDate: '2026-03-15T14:00:00Z' },
        { id: 'v-ps-003', appId: '6449071230', versionString: '2.0.1', platform: 'IOS', state: 'READY_FOR_SALE', createdDate: '2026-02-28T09:00:00Z', buildId: 'b-ps-005' },
      ],
    },
    '6449071231': {
      data: [
        { id: 'v-tf-001', appId: '6449071231', versionString: '1.0.0', platform: 'IOS', state: 'PREPARE_FOR_SUBMISSION', createdDate: '2026-03-12T08:00:00Z' },
      ],
    },
    '6449071234': {
      data: [
        { id: 'v-ft-001', appId: '6449071234', versionString: '3.5.0', platform: 'IOS', state: 'IN_REVIEW', createdDate: '2026-03-14T16:00:00Z', buildId: 'b-ft-001' },
      ],
    },
    '6449071235': {
      data: [
        { id: 'v-mm-001', appId: '6449071235', versionString: '1.2.0', platform: 'IOS', state: 'WAITING_FOR_REVIEW', createdDate: '2026-03-13T11:00:00Z', buildId: 'b-mm-001' },
      ],
    },
  },

  // ===== Builds — with appId parent =====
  builds: {
    '6449071230': {
      data: [
        { id: 'b-ps-001', version: '2.2.0', buildNumber: '142', uploadedDate: '2026-03-16T08:30:00Z', expired: false, processingState: 'VALID' },
        { id: 'b-ps-002', version: '2.2.0', buildNumber: '141', uploadedDate: '2026-03-14T11:00:00Z', expired: false, processingState: 'VALID' },
        { id: 'b-ps-003', version: '2.1.0', buildNumber: '138', uploadedDate: '2026-03-09T15:00:00Z', expired: false, processingState: 'VALID' },
        { id: 'b-ps-004', version: '2.2.0', buildNumber: '140', uploadedDate: '2026-03-13T09:00:00Z', expired: false, processingState: 'INVALID' },
        { id: 'b-ps-005', version: '2.0.1', buildNumber: '135', uploadedDate: '2026-02-27T14:00:00Z', expired: true,  processingState: 'VALID' },
      ],
    },
    '6449071234': {
      data: [
        { id: 'b-ft-001', version: '3.5.0', buildNumber: '89', uploadedDate: '2026-03-14T15:00:00Z', expired: false, processingState: 'VALID' },
      ],
    },
  },

  // ===== TestFlight Beta Groups — with appId parent =====
  betaGroups: {
    '6449071230': {
      data: [
        { id: 'bg-001', appId: '6449071230', name: 'Internal Testers', isInternalGroup: true, publicLinkEnabled: false, createdDate: '2025-06-01T10:00:00Z' },
        { id: 'bg-002', appId: '6449071230', name: 'External Beta', isInternalGroup: false, publicLinkEnabled: true, createdDate: '2025-09-15T10:00:00Z' },
        { id: 'bg-003', appId: '6449071230', name: 'VIP Testers', isInternalGroup: false, publicLinkEnabled: false, createdDate: '2026-01-10T10:00:00Z' },
      ],
    },
  },

  // ===== Beta Testers — with groupId parent =====
  betaTesters: {
    'bg-001': {
      data: [
        { id: 'bt-001', groupId: 'bg-001', firstName: 'Alice', lastName: 'Wang', email: 'alice@example.com', inviteType: 'EMAIL' },
        { id: 'bt-002', groupId: 'bg-001', firstName: 'Bob', lastName: 'Li', email: 'bob@example.com', inviteType: 'EMAIL' },
      ],
    },
    'bg-002': {
      data: [
        { id: 'bt-003', groupId: 'bg-002', firstName: 'Carol', lastName: 'Zhang', email: 'carol@test.com', inviteType: 'PUBLIC_LINK' },
        { id: 'bt-004', groupId: 'bg-002', email: 'david@test.com', inviteType: 'EMAIL' },
      ],
    },
  },

  // ===== Customer Reviews — with appId parent =====
  reviews: {
    '6449071230': {
      data: [
        { id: 'r-001', appId: '6449071230', rating: 5, title: 'Amazing app!', body: 'Love the new photo sync feature. Works flawlessly across all my devices.', reviewerNickname: 'PhotoFan42', createdDate: '2026-03-15T12:00:00Z', territory: 'USA' },
        { id: 'r-002', appId: '6449071230', rating: 2, title: 'Crashes on iPad', body: 'App crashes when I try to open large albums with 500+ photos. Please fix this.', reviewerNickname: 'iPadUser99', createdDate: '2026-03-14T08:00:00Z', territory: 'USA' },
        { id: 'r-003', appId: '6449071230', rating: 4, title: 'Good but needs dark mode', body: 'Great app overall. The sync is fast and reliable. Only missing dark mode.', reviewerNickname: 'NightOwl', createdDate: '2026-03-12T18:00:00Z', territory: 'GBR' },
        { id: 'r-004', appId: '6449071230', rating: 5, title: 'Best photo app', body: 'Switched from Google Photos. Much better privacy and speed.', reviewerNickname: 'PrivacyFirst', createdDate: '2026-03-11T09:00:00Z', territory: 'DEU' },
        { id: 'r-005', appId: '6449071230', rating: 1, title: 'Lost my photos!', body: 'After the last update, half my library disappeared. PLEASE HELP.', reviewerNickname: 'Frustrated123', createdDate: '2026-03-10T22:00:00Z', territory: 'USA' },
      ],
    },
  },

  // ===== In-App Purchases — with appId parent =====
  iaps: {
    '6449071230': {
      data: [
        { id: 'iap-001', appId: '6449071230', referenceName: 'Premium Unlock', productId: 'com.example.photosync.premium', type: 'NON_CONSUMABLE', state: 'APPROVED' },
        { id: 'iap-002', appId: '6449071230', referenceName: '100 Cloud Credits', productId: 'com.example.photosync.credits100', type: 'CONSUMABLE', state: 'APPROVED' },
        { id: 'iap-003', appId: '6449071230', referenceName: '500 Cloud Credits', productId: 'com.example.photosync.credits500', type: 'CONSUMABLE', state: 'READY_TO_SUBMIT' },
      ],
    },
  },

  // ===== Subscription Groups — with appId parent =====
  subscriptionGroups: {
    '6449071230': {
      data: [
        { id: 'sg-001', appId: '6449071230', referenceName: 'Pro Plans' },
        { id: 'sg-002', appId: '6449071230', referenceName: 'Storage Add-ons' },
      ],
    },
  },

  // ===== Subscriptions — with groupId parent =====
  subscriptions: {
    'sg-001': {
      data: [
        { id: 'sub-001', groupId: 'sg-001', name: 'Pro Monthly', productId: 'com.example.photosync.pro.monthly', subscriptionPeriod: 'ONE_MONTH', isFamilySharable: false, state: 'APPROVED', groupLevel: 1 },
        { id: 'sub-002', groupId: 'sg-001', name: 'Pro Yearly', productId: 'com.example.photosync.pro.yearly', subscriptionPeriod: 'ONE_YEAR', isFamilySharable: true, state: 'APPROVED', groupLevel: 2 },
        { id: 'sub-003', groupId: 'sg-001', name: 'Pro Lifetime', productId: 'com.example.photosync.pro.lifetime', subscriptionPeriod: 'ONE_YEAR', isFamilySharable: false, state: 'READY_TO_SUBMIT', groupLevel: 3 },
      ],
    },
  },

  // ===== Team Members =====
  users: {
    data: [
      { id: 'u-001', username: 'alex@example.com', firstName: 'Alex', lastName: 'Chen', roles: ['ADMIN'], isAllAppsVisible: true, isProvisioningAllowed: true },
      { id: 'u-002', username: 'sarah@example.com', firstName: 'Sarah', lastName: 'Kim', roles: ['DEVELOPER'], isAllAppsVisible: true, isProvisioningAllowed: true },
      { id: 'u-003', username: 'james@example.com', firstName: 'James', lastName: 'Wu', roles: ['MARKETING'], isAllAppsVisible: false, isProvisioningAllowed: false },
      { id: 'u-004', username: 'ming@example.com', firstName: 'Ming', lastName: 'Liu', roles: ['APP_MANAGER','DEVELOPER'], isAllAppsVisible: true, isProvisioningAllowed: true },
    ],
  },

  // ===== User Invitations =====
  invitations: {
    data: [
      { id: 'inv-001', email: 'new-dev@example.com', firstName: 'Pat', lastName: 'Taylor', roles: ['DEVELOPER'], expirationDate: '2026-03-24T00:00:00Z', isAllAppsVisible: true, isProvisioningAllowed: false },
    ],
  },

  // ===== Code Signing: Bundle IDs =====
  bundleIds: {
    data: [
      { id: 'bid-001', name: 'PhotoSync Pro', identifier: 'com.example.photosync', platform: 'IOS', seedID: 'A1B2C3D4E5' },
      { id: 'bid-002', name: 'PhotoSync Pro Mac', identifier: 'com.example.photosync', platform: 'MAC_OS', seedID: 'A1B2C3D4E5' },
      { id: 'bid-003', name: 'CodePad', identifier: 'com.example.codepad', platform: 'MAC_OS', seedID: 'A1B2C3D4E5' },
      { id: 'bid-004', name: 'FitTrack', identifier: 'com.example.fittrack', platform: 'IOS' },
    ],
  },

  // ===== Code Signing: Certificates =====
  certificates: {
    data: [
      { id: 'cert-001', name: 'Apple Distribution: Example Inc', certificateType: 'DISTRIBUTION', displayName: 'Apple Distribution', serialNumber: '3A4B5C6D', expirationDate: '2027-03-15T00:00:00Z' },
      { id: 'cert-002', name: 'Apple Development: Alex Chen', certificateType: 'DEVELOPMENT', displayName: 'Apple Development', serialNumber: '7E8F9A0B', expirationDate: '2027-01-20T00:00:00Z' },
      { id: 'cert-003', name: 'Mac App Distribution', certificateType: 'MAC_APP_DISTRIBUTION', displayName: 'Mac App Distribution', serialNumber: '1C2D3E4F', expirationDate: '2026-04-01T00:00:00Z' },
    ],
  },

  // ===== Code Signing: Devices =====
  devices: {
    data: [
      { id: 'dev-001', name: "Alex's iPhone 15 Pro", udid: '00008110-001234567890ABCD', deviceClass: 'IPHONE', platform: 'IOS', status: 'ENABLED', model: 'iPhone 15 Pro' },
      { id: 'dev-002', name: "Alex's iPad Pro", udid: '00008110-001234567890EFGH', deviceClass: 'IPAD', platform: 'IOS', status: 'ENABLED', model: 'iPad Pro 12.9"' },
      { id: 'dev-003', name: "Test iPhone SE", udid: '00008110-001234567890IJKL', deviceClass: 'IPHONE', platform: 'IOS', status: 'DISABLED', model: 'iPhone SE 3rd' },
    ],
  },

  // ===== Code Signing: Profiles =====
  profiles: {
    data: [
      { id: 'prof-001', name: 'PhotoSync AppStore', profileType: 'IOS_APP_STORE', profileState: 'ACTIVE', bundleIdId: 'bid-001', expirationDate: '2027-03-15T00:00:00Z', uuid: 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890' },
      { id: 'prof-002', name: 'PhotoSync Dev', profileType: 'IOS_APP_DEVELOPMENT', profileState: 'ACTIVE', bundleIdId: 'bid-001', expirationDate: '2027-03-15T00:00:00Z', uuid: 'B2C3D4E5-F6A7-8901-BCDE-F12345678901' },
      { id: 'prof-003', name: 'CodePad AppStore', profileType: 'MAC_APP_STORE', profileState: 'INVALID', bundleIdId: 'bid-003', expirationDate: '2026-01-01T00:00:00Z', uuid: 'C3D4E5F6-A7B8-9012-CDEF-123456789012' },
    ],
  },

  // ===== Xcode Cloud Products — with appId parent =====
  xcProducts: {
    data: [
      { id: 'xcp-001', appId: '6449071230', name: 'PhotoSync Pro', productType: 'APP', createdDate: '2025-08-01T10:00:00Z' },
      { id: 'xcp-002', appId: '6449071233', name: 'CodePad', productType: 'APP', createdDate: '2025-10-15T10:00:00Z' },
    ],
  },

  // ===== Xcode Cloud Workflows — with productId parent =====
  xcWorkflows: {
    'xcp-001': {
      data: [
        { id: 'xcw-001', productId: 'xcp-001', name: 'Release Build', isEnabled: true, isLockedForEditing: false, containerFilePath: 'PhotoSync.xcodeproj' },
        { id: 'xcw-002', productId: 'xcp-001', name: 'PR Check', isEnabled: true, isLockedForEditing: false, containerFilePath: 'PhotoSync.xcodeproj' },
        { id: 'xcw-003', productId: 'xcp-001', name: 'Nightly Test', isEnabled: false, isLockedForEditing: false },
      ],
    },
  },

  // ===== Xcode Cloud Build Runs — with workflowId parent =====
  xcBuildRuns: {
    'xcw-001': {
      data: [
        { id: 'xcbr-001', workflowId: 'xcw-001', number: 42, executionProgress: 'COMPLETE', completionStatus: 'SUCCEEDED', startReason: 'MANUAL', createdDate: '2026-03-16T07:00:00Z', startedDate: '2026-03-16T07:01:00Z', finishedDate: '2026-03-16T07:18:00Z' },
        { id: 'xcbr-002', workflowId: 'xcw-001', number: 41, executionProgress: 'COMPLETE', completionStatus: 'FAILED', startReason: 'GIT_REF_CHANGE', createdDate: '2026-03-15T14:00:00Z', startedDate: '2026-03-15T14:01:00Z', finishedDate: '2026-03-15T14:22:00Z' },
        { id: 'xcbr-003', workflowId: 'xcw-001', number: 43, executionProgress: 'RUNNING', startReason: 'MANUAL', createdDate: '2026-03-17T09:00:00Z', startedDate: '2026-03-17T09:01:00Z' },
      ],
    },
  },

  // ===== App Info — with appId parent =====
  appInfos: {
    '6449071230': {
      data: [
        { id: 'ai-001', appId: '6449071230', primaryCategoryId: '6008', secondaryCategoryId: '6007' },
      ],
    },
  },

  // ===== App Info Localizations — with appInfoId parent =====
  appInfoLocalizations: {
    'ai-001': {
      data: [
        { id: 'ail-001', appInfoId: 'ai-001', locale: 'en-US', name: 'PhotoSync Pro', subtitle: 'Sync photos everywhere', privacyPolicyUrl: 'https://example.com/privacy' },
        { id: 'ail-002', appInfoId: 'ai-001', locale: 'zh-Hans', name: 'PhotoSync Pro', subtitle: '随处同步照片', privacyPolicyUrl: 'https://example.com/privacy' },
        { id: 'ail-003', appInfoId: 'ai-001', locale: 'ja', name: 'PhotoSync Pro' },
      ],
    },
  },

  // ===== Version Localizations — with versionId parent =====
  versionLocalizations: {
    'v-ps-002': {
      data: [
        { id: 'vl-001', versionId: 'v-ps-002', locale: 'en-US', description: 'PhotoSync Pro keeps your photos in sync across all devices.', keywords: 'photo,sync,backup,cloud', whatsNew: 'Bug fixes and performance improvements.', supportUrl: 'https://example.com/support' },
        { id: 'vl-002', versionId: 'v-ps-002', locale: 'zh-Hans', description: 'PhotoSync Pro 让您的照片在所有设备间保持同步。', keywords: '照片,同步,备份,云', whatsNew: '修复了一些问题并提升了性能。' },
      ],
    },
  },

  // ===== Screenshot Sets — with localizationId parent =====
  screenshotSets: {
    'vl-001': {
      data: [
        { id: 'ss-001', localizationId: 'vl-001', screenshotDisplayType: 'APP_IPHONE_67', screenshotsCount: 6 },
        { id: 'ss-002', localizationId: 'vl-001', screenshotDisplayType: 'APP_IPHONE_65', screenshotsCount: 6 },
        { id: 'ss-003', localizationId: 'vl-001', screenshotDisplayType: 'APP_IPAD_PRO_129', screenshotsCount: 4 },
        { id: 'ss-006', localizationId: 'vl-001', screenshotDisplayType: 'APP_DESKTOP', screenshotsCount: 3 },
      ],
    },
    'vl-002': {
      data: [
        { id: 'ss-004', localizationId: 'vl-002', screenshotDisplayType: 'APP_IPHONE_67', screenshotsCount: 6 },
        { id: 'ss-005', localizationId: 'vl-002', screenshotDisplayType: 'APP_IPHONE_65', screenshotsCount: 3 },
      ],
    },
  },

  // ===== Screenshots — with setId parent =====
  // imageUrl: in live mode, resolved from sourceUrl template with {w}/{h}/{f} placeholders
  // In mock mode, we use picsum.photos for visual placeholder images
  screenshots: {
    'ss-001': {
      data: [
        { id: 'sc-001', setId: 'ss-001', fileName: 'home-screen.png', fileSize: 1245678, assetState: 'COMPLETE', imageWidth: 1290, imageHeight: 2796, imageUrl: 'https://picsum.photos/seed/sc001/258/559' },
        { id: 'sc-002', setId: 'ss-001', fileName: 'search-view.png', fileSize: 987654, assetState: 'COMPLETE', imageWidth: 1290, imageHeight: 2796, imageUrl: 'https://picsum.photos/seed/sc002/258/559' },
        { id: 'sc-003', setId: 'ss-001', fileName: 'detail-view.png', fileSize: 1123456, assetState: 'COMPLETE', imageWidth: 1290, imageHeight: 2796, imageUrl: 'https://picsum.photos/seed/sc003/258/559' },
        { id: 'sc-004', setId: 'ss-001', fileName: 'settings.png', fileSize: 654321, assetState: 'COMPLETE', imageWidth: 1290, imageHeight: 2796, imageUrl: 'https://picsum.photos/seed/sc004/258/559' },
        { id: 'sc-005', setId: 'ss-001', fileName: 'sync-progress.png', fileSize: 876543, assetState: 'COMPLETE', imageWidth: 1290, imageHeight: 2796, imageUrl: 'https://picsum.photos/seed/sc005/258/559' },
        { id: 'sc-006', setId: 'ss-001', fileName: 'share-sheet.png', fileSize: 998877, assetState: 'COMPLETE', imageWidth: 1290, imageHeight: 2796, imageUrl: 'https://picsum.photos/seed/sc006/258/559' },
      ],
    },
    'ss-002': {
      data: [
        { id: 'sc-007', setId: 'ss-002', fileName: 'home-screen.png', fileSize: 1100234, assetState: 'COMPLETE', imageWidth: 1284, imageHeight: 2778, imageUrl: 'https://picsum.photos/seed/sc007/257/556' },
        { id: 'sc-008', setId: 'ss-002', fileName: 'search-view.png', fileSize: 934567, assetState: 'COMPLETE', imageWidth: 1284, imageHeight: 2778, imageUrl: 'https://picsum.photos/seed/sc008/257/556' },
        { id: 'sc-009', setId: 'ss-002', fileName: 'detail-view.png', fileSize: 1056789, assetState: 'COMPLETE', imageWidth: 1284, imageHeight: 2778, imageUrl: 'https://picsum.photos/seed/sc009/257/556' },
        { id: 'sc-010', setId: 'ss-002', fileName: 'settings.png', fileSize: 612345, assetState: 'UPLOAD_COMPLETE', imageWidth: 1284, imageHeight: 2778, imageUrl: 'https://picsum.photos/seed/sc010/257/556' },
        { id: 'sc-011', setId: 'ss-002', fileName: 'sync-progress.png', fileSize: 845678, assetState: 'COMPLETE', imageWidth: 1284, imageHeight: 2778, imageUrl: 'https://picsum.photos/seed/sc011/257/556' },
        { id: 'sc-012', setId: 'ss-002', fileName: 'share-sheet.png', fileSize: 967890, assetState: 'COMPLETE', imageWidth: 1284, imageHeight: 2778, imageUrl: 'https://picsum.photos/seed/sc012/257/556' },
      ],
    },
    'ss-003': {
      data: [
        { id: 'sc-013', setId: 'ss-003', fileName: 'home-ipad.png', fileSize: 2345678, assetState: 'COMPLETE', imageWidth: 2048, imageHeight: 2732, imageUrl: 'https://picsum.photos/seed/sc013/300/400' },
        { id: 'sc-014', setId: 'ss-003', fileName: 'search-ipad.png', fileSize: 2123456, assetState: 'COMPLETE', imageWidth: 2048, imageHeight: 2732, imageUrl: 'https://picsum.photos/seed/sc014/300/400' },
        { id: 'sc-015', setId: 'ss-003', fileName: 'detail-ipad.png', fileSize: 2567890, assetState: 'COMPLETE', imageWidth: 2048, imageHeight: 2732, imageUrl: 'https://picsum.photos/seed/sc015/300/400' },
        { id: 'sc-016', setId: 'ss-003', fileName: 'settings-ipad.png', fileSize: 1987654, assetState: 'COMPLETE', imageWidth: 2048, imageHeight: 2732, imageUrl: 'https://picsum.photos/seed/sc016/300/400' },
      ],
    },
    'ss-006': {
      data: [
        { id: 'sc-026', setId: 'ss-006', fileName: 'screenshot_main.png', fileSize: 2945678, assetState: 'COMPLETE', imageWidth: 2880, imageHeight: 1800, imageUrl: 'https://picsum.photos/seed/sc026/480/300' },
        { id: 'sc-027', setId: 'ss-006', fileName: 'screenshot_editor.png', fileSize: 3123456, assetState: 'COMPLETE', imageWidth: 2880, imageHeight: 1800, imageUrl: 'https://picsum.photos/seed/sc027/480/300' },
        { id: 'sc-028', setId: 'ss-006', fileName: 'screenshot_prefs.png', fileSize: 2567890, assetState: 'COMPLETE', imageWidth: 2880, imageHeight: 1800, imageUrl: 'https://picsum.photos/seed/sc028/480/300' },
      ],
    },
    'ss-004': {
      data: [
        { id: 'sc-017', setId: 'ss-004', fileName: '\u9996\u9875.png', fileSize: 1245678, assetState: 'COMPLETE', imageWidth: 1290, imageHeight: 2796, imageUrl: 'https://picsum.photos/seed/sc017/258/559' },
        { id: 'sc-018', setId: 'ss-004', fileName: '\u641c\u7d22.png', fileSize: 987654, assetState: 'COMPLETE', imageWidth: 1290, imageHeight: 2796, imageUrl: 'https://picsum.photos/seed/sc018/258/559' },
        { id: 'sc-019', setId: 'ss-004', fileName: '\u8be6\u60c5.png', fileSize: 1123456, assetState: 'COMPLETE', imageWidth: 1290, imageHeight: 2796, imageUrl: 'https://picsum.photos/seed/sc019/258/559' },
        { id: 'sc-020', setId: 'ss-004', fileName: '\u8bbe\u7f6e.png', fileSize: 654321, assetState: 'COMPLETE', imageWidth: 1290, imageHeight: 2796, imageUrl: 'https://picsum.photos/seed/sc020/258/559' },
        { id: 'sc-021', setId: 'ss-004', fileName: '\u540c\u6b65.png', fileSize: 876543, assetState: 'COMPLETE', imageWidth: 1290, imageHeight: 2796, imageUrl: 'https://picsum.photos/seed/sc021/258/559' },
        { id: 'sc-022', setId: 'ss-004', fileName: '\u5206\u4eab.png', fileSize: 998877, assetState: 'COMPLETE', imageWidth: 1290, imageHeight: 2796, imageUrl: 'https://picsum.photos/seed/sc022/258/559' },
      ],
    },
    'ss-005': {
      data: [
        { id: 'sc-023', setId: 'ss-005', fileName: '\u9996\u9875-65.png', fileSize: 1100234, assetState: 'COMPLETE', imageWidth: 1284, imageHeight: 2778, imageUrl: 'https://picsum.photos/seed/sc023/257/556' },
        { id: 'sc-024', setId: 'ss-005', fileName: '\u641c\u7d22-65.png', fileSize: 934567, assetState: 'COMPLETE', imageWidth: 1284, imageHeight: 2778, imageUrl: 'https://picsum.photos/seed/sc024/257/556' },
        { id: 'sc-025', setId: 'ss-005', fileName: '\u8be6\u60c5-65.png', fileSize: 1056789, assetState: 'AWAITING_UPLOAD', imageWidth: null, imageHeight: null },
      ],
    },
  },

  // ===== Iris Status =====
  irisStatus: {
    data: [
      { source: 'browser', cookieCount: 7 },
    ],
  },

  // ===== Iris App Bundles =====
  irisApps: {
    data: [
      { id: '6449071230', name: 'PhotoSync Pro', bundleId: 'com.example.photosync', sku: 'PHOTOSYNC2024', primaryLocale: 'en-US', platforms: ['IOS'] },
      { id: '6449071231', name: 'TaskFlow', bundleId: 'com.example.taskflow', sku: 'TASKFLOW2024', primaryLocale: 'en-US', platforms: ['IOS', 'MAC_OS'] },
    ],
  },

  // ===== Installed Plugins =====
  plugins: {
    data: [
      {
        id: 'asc-pro', name: 'ASC Pro', version: '1.0', slug: 'ASCPro',
        uiScripts: ['ui/sim-stream.js'],
        affordances: { uninstall: 'asc plugins uninstall --name ASCPro', browseMarket: 'asc plugins market list' },
      },
    ],
  },

  // ===== Plugin Marketplace =====
  marketPlugins: {
    data: [
      {
        id: 'asc-pro', name: 'ASC Pro', version: '1.0',
        description: 'Simulator streaming, interaction & tunnel sharing',
        author: 'slamhan', repositoryURL: 'https://github.com/tddworks/asc-pro',
        downloadURL: 'https://github.com/tddworks/asc-pro/releases/latest/download/ASCPro.plugin.zip',
        categories: ['simulators', 'streaming'], isInstalled: true,
        affordances: { uninstall: 'asc plugins uninstall --name asc-pro', listMarket: 'asc plugins market list', viewRepository: 'https://github.com/tddworks/asc-pro' },
      },
      {
        id: 'asc-analytics', name: 'ASC Analytics', version: '0.5',
        description: 'Advanced App Store analytics dashboard with charts',
        author: 'community', repositoryURL: 'https://github.com/example/asc-analytics',
        downloadURL: 'https://github.com/example/asc-analytics/releases/latest/download/ASCAnalytics.plugin.zip',
        categories: ['analytics', 'reports'], isInstalled: false,
        affordances: { install: 'asc plugins install --name asc-analytics', listMarket: 'asc plugins market list', viewRepository: 'https://github.com/example/asc-analytics' },
      },
      {
        id: 'asc-notify', name: 'ASC Notify', version: '1.2',
        description: 'Slack and Telegram notifications for review status changes',
        author: 'community',
        downloadURL: 'https://github.com/example/asc-notify/releases/latest/download/ASCNotify.plugin.zip',
        categories: ['notifications'], isInstalled: false,
        affordances: { install: 'asc plugins install --name asc-notify', listMarket: 'asc plugins market list' },
      },
    ],
  },

  // ===== Auth Status =====
  authStatus: {
    name: 'default',
    keyID: 'ABC123XYZ',
    issuerID: '69a6de75-4321-47e3-e053-5b8c7c11a4d1',
    source: 'file',
    vendorNumber: '85012345',
  },
};
