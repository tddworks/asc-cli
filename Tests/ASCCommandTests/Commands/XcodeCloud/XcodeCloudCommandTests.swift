import Mockable
import Testing
@testable import ASCCommand
@testable import Domain

@Suite
struct XcodeCloudProductsListTests {

    @Test func `listed products include app id and affordances`() async throws {
        let mockRepo = MockXcodeCloudProductRepository()
        given(mockRepo).listProducts(appId: .any).willReturn([
            XcodeCloudProduct(id: "prod-1", appId: "app-42", name: "My App CI", productType: .app),
        ])

        let cmd = try XcodeCloudProductsList.parse(["--app-id", "app-42", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listProducts" : "asc xcode-cloud products list --app-id app-42",
                "listWorkflows" : "asc xcode-cloud workflows list --product-id prod-1"
              },
              "appId" : "app-42",
              "id" : "prod-1",
              "name" : "My App CI",
              "productType" : "APP"
            }
          ]
        }
        """)
    }
}

@Suite
struct XcodeCloudWorkflowsListTests {

    @Test func `listed workflows include product id and affordances`() async throws {
        let mockRepo = MockXcodeCloudWorkflowRepository()
        given(mockRepo).listWorkflows(productId: .value("prod-1")).willReturn([
            XcodeCloudWorkflow(id: "wf-1", productId: "prod-1", name: "CI Build", isEnabled: true, isLockedForEditing: false),
        ])

        let cmd = try XcodeCloudWorkflowsList.parse(["--product-id", "prod-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listBuildRuns" : "asc xcode-cloud builds list --workflow-id wf-1",
                "listWorkflows" : "asc xcode-cloud workflows list --product-id prod-1",
                "startBuild" : "asc xcode-cloud builds start --workflow-id wf-1"
              },
              "id" : "wf-1",
              "isEnabled" : true,
              "isLockedForEditing" : false,
              "name" : "CI Build",
              "productId" : "prod-1"
            }
          ]
        }
        """)
    }

    @Test func `disabled workflow omits startBuild affordance`() async throws {
        let mockRepo = MockXcodeCloudWorkflowRepository()
        given(mockRepo).listWorkflows(productId: .value("prod-1")).willReturn([
            XcodeCloudWorkflow(id: "wf-2", productId: "prod-1", name: "Disabled CI", isEnabled: false, isLockedForEditing: false),
        ])

        let cmd = try XcodeCloudWorkflowsList.parse(["--product-id", "prod-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "listBuildRuns" : "asc xcode-cloud builds list --workflow-id wf-2",
                "listWorkflows" : "asc xcode-cloud workflows list --product-id prod-1"
              },
              "id" : "wf-2",
              "isEnabled" : false,
              "isLockedForEditing" : false,
              "name" : "Disabled CI",
              "productId" : "prod-1"
            }
          ]
        }
        """)
    }
}

@Suite
struct XcodeCloudBuildsListTests {

    @Test func `listed build runs include workflow id and affordances`() async throws {
        let mockRepo = MockXcodeCloudBuildRunRepository()
        given(mockRepo).listBuildRuns(workflowId: .value("wf-1")).willReturn([
            XcodeCloudBuildRun(
                id: "run-1", workflowId: "wf-1", number: 5,
                executionProgress: .complete,
                completionStatus: .succeeded,
                startReason: .manual
            ),
        ])

        let cmd = try XcodeCloudBuildsList.parse(["--workflow-id", "wf-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getBuildRun" : "asc xcode-cloud builds get --build-run-id run-1",
                "listBuildRuns" : "asc xcode-cloud builds list --workflow-id wf-1"
              },
              "completionStatus" : "SUCCEEDED",
              "executionProgress" : "COMPLETE",
              "id" : "run-1",
              "number" : 5,
              "startReason" : "MANUAL",
              "workflowId" : "wf-1"
            }
          ]
        }
        """)
    }
}

@Suite
struct XcodeCloudBuildsGetTests {

    @Test func `get build run returns single build run with affordances`() async throws {
        let mockRepo = MockXcodeCloudBuildRunRepository()
        given(mockRepo).getBuildRun(id: .value("run-99")).willReturn(
            XcodeCloudBuildRun(
                id: "run-99", workflowId: "wf-1", number: 12,
                executionProgress: .running,
                completionStatus: nil,
                startReason: .gitRefChange
            )
        )

        let cmd = try XcodeCloudBuildsGet.parse(["--build-run-id", "run-99", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getBuildRun" : "asc xcode-cloud builds get --build-run-id run-99",
                "listBuildRuns" : "asc xcode-cloud builds list --workflow-id wf-1"
              },
              "executionProgress" : "RUNNING",
              "id" : "run-99",
              "number" : 12,
              "startReason" : "GIT_REF_CHANGE",
              "workflowId" : "wf-1"
            }
          ]
        }
        """)
    }
}

@Suite
struct XcodeCloudBuildsStartTests {

    @Test func `start build returns new build run with affordances`() async throws {
        let mockRepo = MockXcodeCloudBuildRunRepository()
        given(mockRepo).startBuildRun(workflowId: .value("wf-1"), clean: .value(false)).willReturn(
            XcodeCloudBuildRun(
                id: "run-100", workflowId: "wf-1", number: nil,
                executionProgress: .pending,
                completionStatus: nil,
                startReason: .manual
            )
        )

        let cmd = try XcodeCloudBuildsStart.parse(["--workflow-id", "wf-1", "--pretty"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output == """
        {
          "data" : [
            {
              "affordances" : {
                "getBuildRun" : "asc xcode-cloud builds get --build-run-id run-100",
                "listBuildRuns" : "asc xcode-cloud builds list --workflow-id wf-1"
              },
              "executionProgress" : "PENDING",
              "id" : "run-100",
              "startReason" : "MANUAL",
              "workflowId" : "wf-1"
            }
          ]
        }
        """)
    }

    @Test func `start build with clean flag calls repo with clean true`() async throws {
        let mockRepo = MockXcodeCloudBuildRunRepository()
        given(mockRepo).startBuildRun(workflowId: .value("wf-1"), clean: .value(true)).willReturn(
            XcodeCloudBuildRun(id: "run-101", workflowId: "wf-1", executionProgress: .pending)
        )

        let cmd = try XcodeCloudBuildsStart.parse(["--workflow-id", "wf-1", "--clean"])
        let output = try await cmd.execute(repo: mockRepo)

        #expect(output.contains("run-101"))
    }
}
