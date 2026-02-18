public enum ScreenshotDisplayType: String, Sendable, Equatable, Hashable, CaseIterable, Codable {
    // iPhone
    case iphone67 = "APP_IPHONE_67"
    case iphone65 = "APP_IPHONE_65"
    case iphone61 = "APP_IPHONE_61"
    case iphone58 = "APP_IPHONE_58"
    case iphone55 = "APP_IPHONE_55"
    case iphone47 = "APP_IPHONE_47"
    case iphone40 = "APP_IPHONE_40"
    case iphone35 = "APP_IPHONE_35"
    // iPad
    case ipadPro3gen129 = "APP_IPAD_PRO_3GEN_129"
    case ipadPro3gen11 = "APP_IPAD_PRO_3GEN_11"
    case ipadPro129 = "APP_IPAD_PRO_129"
    case iPad105 = "APP_IPAD_105"
    case iPad97 = "APP_IPAD_97"
    // Other platforms
    case desktop = "APP_DESKTOP"
    case watchUltra = "APP_WATCH_ULTRA"
    case watchSeries10 = "APP_WATCH_SERIES_10"
    case watchSeries7 = "APP_WATCH_SERIES_7"
    case watchSeries4 = "APP_WATCH_SERIES_4"
    case watchSeries3 = "APP_WATCH_SERIES_3"
    case appleTV = "APP_APPLE_TV"
    case appleVisionPro = "APP_APPLE_VISION_PRO"
    // iMessage
    case imessageIphone67 = "IMESSAGE_APP_IPHONE_67"
    case imessageIphone65 = "IMESSAGE_APP_IPHONE_65"
    case imessageIphone61 = "IMESSAGE_APP_IPHONE_61"
    case imessageIphone58 = "IMESSAGE_APP_IPHONE_58"
    case imessageIphone55 = "IMESSAGE_APP_IPHONE_55"
    case imessageIphone47 = "IMESSAGE_APP_IPHONE_47"
    case imessageIphone40 = "IMESSAGE_APP_IPHONE_40"
    case imessageIpadPro3gen129 = "IMESSAGE_APP_IPAD_PRO_3GEN_129"
    case imessageIpadPro3gen11 = "IMESSAGE_APP_IPAD_PRO_3GEN_11"
    case imessageIpadPro129 = "IMESSAGE_APP_IPAD_PRO_129"
    case imessageIPad105 = "IMESSAGE_APP_IPAD_105"
    case imessageIPad97 = "IMESSAGE_APP_IPAD_97"

    public enum DeviceCategory: String, Sendable, Equatable {
        case iPhone, iPad, mac, watch, appleTV, appleVisionPro, iMessage

        public var displayName: String {
            switch self {
            case .iPhone: return "iPhone"
            case .iPad: return "iPad"
            case .mac: return "Mac"
            case .watch: return "Apple Watch"
            case .appleTV: return "Apple TV"
            case .appleVisionPro: return "Apple Vision Pro"
            case .iMessage: return "iMessage"
            }
        }
    }

    public var deviceCategory: DeviceCategory {
        if rawValue.hasPrefix("IMESSAGE_") { return .iMessage }
        if rawValue.contains("IPHONE") { return .iPhone }
        if rawValue.contains("IPAD") { return .iPad }
        if rawValue.contains("WATCH") { return .watch }
        if rawValue == "APP_APPLE_TV" { return .appleTV }
        if rawValue == "APP_APPLE_VISION_PRO" { return .appleVisionPro }
        if rawValue == "APP_DESKTOP" { return .mac }
        return .iPhone
    }

    public var displayName: String {
        switch self {
        case .iphone67: return "iPhone 6.7\""
        case .iphone65: return "iPhone 6.5\""
        case .iphone61: return "iPhone 6.1\""
        case .iphone58: return "iPhone 5.8\""
        case .iphone55: return "iPhone 5.5\""
        case .iphone47: return "iPhone 4.7\""
        case .iphone40: return "iPhone 4.0\""
        case .iphone35: return "iPhone 3.5\""
        case .ipadPro3gen129: return "iPad Pro 12.9\" (3rd gen)"
        case .ipadPro3gen11: return "iPad Pro 11\" (3rd gen)"
        case .ipadPro129: return "iPad Pro 12.9\""
        case .iPad105: return "iPad 10.5\""
        case .iPad97: return "iPad 9.7\""
        case .desktop: return "Mac"
        case .watchUltra: return "Apple Watch Ultra"
        case .watchSeries10: return "Apple Watch Series 10"
        case .watchSeries7: return "Apple Watch Series 7"
        case .watchSeries4: return "Apple Watch Series 4"
        case .watchSeries3: return "Apple Watch Series 3"
        case .appleTV: return "Apple TV"
        case .appleVisionPro: return "Apple Vision Pro"
        case .imessageIphone67: return "iMessage iPhone 6.7\""
        case .imessageIphone65: return "iMessage iPhone 6.5\""
        case .imessageIphone61: return "iMessage iPhone 6.1\""
        case .imessageIphone58: return "iMessage iPhone 5.8\""
        case .imessageIphone55: return "iMessage iPhone 5.5\""
        case .imessageIphone47: return "iMessage iPhone 4.7\""
        case .imessageIphone40: return "iMessage iPhone 4.0\""
        case .imessageIpadPro3gen129: return "iMessage iPad Pro 12.9\" (3rd gen)"
        case .imessageIpadPro3gen11: return "iMessage iPad Pro 11\" (3rd gen)"
        case .imessageIpadPro129: return "iMessage iPad Pro 12.9\""
        case .imessageIPad105: return "iMessage iPad 10.5\""
        case .imessageIPad97: return "iMessage iPad 9.7\""
        }
    }
}
