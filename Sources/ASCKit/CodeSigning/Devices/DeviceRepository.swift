import Mockable

@Mockable
public protocol DeviceRepository: Sendable {
    func listDevices(platform: BundleIDPlatform?) async throws -> [Device]
    func registerDevice(name: String, udid: String, platform: BundleIDPlatform) async throws -> Device
}
