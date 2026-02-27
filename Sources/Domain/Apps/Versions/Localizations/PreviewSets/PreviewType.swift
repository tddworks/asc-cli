public enum PreviewType: String, Sendable, Equatable, Hashable, CaseIterable, Codable {
    // iPhone
    case iphone67 = "IPHONE_67"
    case iphone61 = "IPHONE_61"
    case iphone65 = "IPHONE_65"
    case iphone58 = "IPHONE_58"
    case iphone55 = "IPHONE_55"
    case iphone47 = "IPHONE_47"
    case iphone40 = "IPHONE_40"
    case iphone35 = "IPHONE_35"
    // iPad
    case ipadPro3gen129 = "IPAD_PRO_3GEN_129"
    case ipadPro3gen11 = "IPAD_PRO_3GEN_11"
    case ipadPro129 = "IPAD_PRO_129"
    case ipad105 = "IPAD_105"
    case ipad97 = "IPAD_97"
    // Other
    case desktop = "DESKTOP"
    case appleTV = "APPLE_TV"
    case appleVisionPro = "APPLE_VISION_PRO"

    public enum DeviceCategory: String, Sendable, Equatable {
        case iPhone
        case iPad
        case mac
        case appleTV
        case appleVisionPro

        public var displayName: String {
            switch self {
            case .iPhone: return "iPhone"
            case .iPad: return "iPad"
            case .mac: return "Mac"
            case .appleTV: return "Apple TV"
            case .appleVisionPro: return "Apple Vision Pro"
            }
        }
    }

    public var deviceCategory: DeviceCategory {
        switch self {
        case .iphone67, .iphone61, .iphone65, .iphone58, .iphone55, .iphone47, .iphone40, .iphone35:
            return .iPhone
        case .ipadPro3gen129, .ipadPro3gen11, .ipadPro129, .ipad105, .ipad97:
            return .iPad
        case .desktop:
            return .mac
        case .appleTV:
            return .appleTV
        case .appleVisionPro:
            return .appleVisionPro
        }
    }

    public var displayName: String {
        switch self {
        case .iphone67: return "iPhone 6.7\""
        case .iphone61: return "iPhone 6.1\""
        case .iphone65: return "iPhone 6.5\""
        case .iphone58: return "iPhone 5.8\""
        case .iphone55: return "iPhone 5.5\""
        case .iphone47: return "iPhone 4.7\""
        case .iphone40: return "iPhone 4.0\""
        case .iphone35: return "iPhone 3.5\""
        case .ipadPro3gen129: return "iPad Pro 12.9\" (3rd gen)"
        case .ipadPro3gen11: return "iPad Pro 11\" (3rd gen)"
        case .ipadPro129: return "iPad Pro 12.9\""
        case .ipad105: return "iPad 10.5\""
        case .ipad97: return "iPad 9.7\""
        case .desktop: return "Mac"
        case .appleTV: return "Apple TV"
        case .appleVisionPro: return "Apple Vision Pro"
        }
    }
}
