@preconcurrency import AppStoreConnect_Swift_SDK

public struct SDKDevices: Devices, @unchecked Sendable {
    private let client: any APIClient

    public init(client: any APIClient) {
        self.client = client
    }

    public func listDevices(platform: ASCKit.BundleIDPlatform?) async throws -> [ASCKit.Device] {
        let filterPlatform = platform.flatMap {
            APIEndpoint.V1.Devices.GetParameters.FilterPlatform(rawValue: $0.rawValue)
        }
        let pages = try await client.requestAllPages(
            APIEndpoint.v1.devices.get(parameters: .init(
                filterPlatform: filterPlatform.map { [$0] },
                limit: 200
            )),
            nextCursor: { $0.meta?.paging.nextCursor }
        )
        return pages.flatMap(\.data).map(mapDevice)
    }

    public func registerDevice(name: String, udid: String, platform: ASCKit.BundleIDPlatform) async throws -> ASCKit.Device {
        guard let sdkPlatform = AppStoreConnect_Swift_SDK.BundleIDPlatform(rawValue: platform.rawValue) else {
            throw APIError.unknown("Unsupported platform: \(platform.rawValue)")
        }
        let body = DeviceCreateRequest(data: .init(
            type: .devices,
            attributes: .init(name: name, platform: sdkPlatform, udid: udid)
        ))
        let response = try await client.request(APIEndpoint.v1.devices.post(body))
        return mapDevice(response.data)
    }

    // MARK: - Mapper

    private func mapDevice(_ sdkDevice: AppStoreConnect_Swift_SDK.Device) -> ASCKit.Device {
        let deviceClass = sdkDevice.attributes?.deviceClass.flatMap {
            ASCKit.DeviceClass(rawValue: $0.rawValue)
        } ?? .iPhone
        let platform = sdkDevice.attributes?.platform.flatMap {
            ASCKit.BundleIDPlatform(rawValue: $0.rawValue)
        } ?? .iOS
        let status = sdkDevice.attributes?.status.flatMap {
            ASCKit.DeviceStatus(rawValue: $0.rawValue)
        } ?? .enabled
        return ASCKit.Device(
            id: sdkDevice.id,
            name: sdkDevice.attributes?.name ?? "",
            udid: sdkDevice.attributes?.udid ?? "",
            deviceClass: deviceClass,
            platform: platform,
            status: status,
            model: sdkDevice.attributes?.model,
            addedDate: sdkDevice.attributes?.addedDate
        )
    }
}
