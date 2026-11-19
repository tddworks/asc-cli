import Testing
@testable import ASCKit

@Suite
struct DeviceTests {

    @Test func `device carries all fields`() {
        let device = MockRepositoryFactory.makeDevice(
            id: "dev-1",
            name: "My iPhone",
            udid: "ABC-123",
            deviceClass: .iPhone,
            platform: .iOS,
            status: .enabled,
            model: "iPhone 16 Pro"
        )
        #expect(device.id == "dev-1")
        #expect(device.name == "My iPhone")
        #expect(device.udid == "ABC-123")
        #expect(device.deviceClass == .iPhone)
        #expect(device.platform == .iOS)
        #expect(device.model == "iPhone 16 Pro")
    }

    @Test func `enabled device isEnabled is true`() {
        let device = MockRepositoryFactory.makeDevice(status: .enabled)
        #expect(device.isEnabled == true)
    }

    @Test func `disabled device isEnabled is false`() {
        let device = MockRepositoryFactory.makeDevice(status: .disabled)
        #expect(device.isEnabled == false)
    }

    @Test func `device class raw values match asc api`() {
        #expect(DeviceClass.iPhone.rawValue == "IPHONE")
        #expect(DeviceClass.iPad.rawValue == "IPAD")
        #expect(DeviceClass.mac.rawValue == "MAC")
        #expect(DeviceClass.appleVisionPro.rawValue == "APPLE_VISION_PRO")
    }

    @Test func `device status raw values match asc api`() {
        #expect(DeviceStatus.enabled.rawValue == "ENABLED")
        #expect(DeviceStatus.disabled.rawValue == "DISABLED")
    }
}
