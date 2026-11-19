import Mockable
import Testing
@testable import ASCCommand
@testable import ASCKit

@Suite
struct DevicesRegisterTests {

    @Test func `execute registers device and returns it`() async throws {
        let mockRepo = MockDevices()
        given(mockRepo).registerDevice(name: .any, udid: .any, platform: .any)
            .willReturn(Device(id: "dev-new", name: "My iPhone", udid: "UDID-001", deviceClass: .iPhone, platform: .iOS, status: .enabled))

        let cmd = try DevicesRegister.parse(["--name", "My iPhone", "--udid", "UDID-001", "--platform", "ios", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("dev-new"))
        #expect(output.contains("UDID-001"))
        #expect(output.contains("ENABLED"))
    }

    @Test func `execute throws for invalid platform`() async throws {
        let mockRepo = MockDevices()
        let cmd = try DevicesRegister.parse(["--name", "My Device", "--udid", "UDID-001", "--platform", "tvos"])
        await #expect(throws: (any Error).self) {
            try await cmd.execute(repo: mockRepo)
        }
    }

    @Test func `table output includes all row fields`() async throws {
        let mockRepo = MockDevices()
        given(mockRepo).registerDevice(name: .any, udid: .any, platform: .any)
            .willReturn(Device(id: "dev-1", name: "iPad Pro", udid: "UDID-002", deviceClass: .iPad, platform: .iOS, status: .enabled))

        let cmd = try DevicesRegister.parse(["--name", "iPad Pro", "--udid", "UDID-002", "--platform", "ios", "--output", "table"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("dev-1"))
        #expect(output.contains("UDID-002"))
        #expect(output.contains("IPAD"))
    }
}
