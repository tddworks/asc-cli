import Testing
@testable import Domain

@Suite
struct UserRoleTests {

    @Test func `cliArgument accepts uppercase raw value`() {
        #expect(UserRole(cliArgument: "ADMIN") == .admin)
        #expect(UserRole(cliArgument: "DEVELOPER") == .developer)
        #expect(UserRole(cliArgument: "APP_MANAGER") == .appManager)
    }

    @Test func `cliArgument accepts lowercase value`() {
        #expect(UserRole(cliArgument: "admin") == .admin)
        #expect(UserRole(cliArgument: "developer") == .developer)
        #expect(UserRole(cliArgument: "finance") == .finance)
    }

    @Test func `cliArgument returns nil for unknown value`() {
        #expect(UserRole(cliArgument: "SUPERUSER") == nil)
        #expect(UserRole(cliArgument: "") == nil)
    }

    @Test func `displayName returns human readable string`() {
        #expect(UserRole.admin.displayName == "Admin")
        #expect(UserRole.appManager.displayName == "App Manager")
        #expect(UserRole.accessToReports.displayName == "Access to Reports")
        #expect(UserRole.cloudManagedDeveloperID.displayName == "Cloud Managed Developer ID")
    }

    @Test func `team member affordances include remove and updateRoles`() {
        let member = TeamMember(
            id: "u-1",
            username: "jdoe@example.com",
            firstName: "Jane",
            lastName: "Doe",
            roles: [.developer, .appManager],
            isAllAppsVisible: false,
            isProvisioningAllowed: false
        )

        #expect(member.affordances["remove"] == "asc users remove --user-id u-1")
        #expect(member.affordances["updateRoles"] == "asc users update --user-id u-1 --role DEVELOPER --role APP_MANAGER")
    }

    @Test func `team member affordances updateRoles reflects current roles`() {
        let admin = TeamMember(
            id: "u-2",
            username: "admin@example.com",
            firstName: "A",
            lastName: "B",
            roles: [.admin],
            isAllAppsVisible: true,
            isProvisioningAllowed: true
        )

        #expect(admin.affordances["updateRoles"] == "asc users update --user-id u-2 --role ADMIN")
    }

    @Test func `invitation affordance contains cancel command`() {
        let invitation = UserInvitationRecord(
            id: "inv-1",
            email: "new@example.com",
            firstName: "New",
            lastName: "User",
            roles: [.developer],
            isAllAppsVisible: false,
            isProvisioningAllowed: false
        )

        #expect(invitation.affordances["cancel"] == "asc user-invitations cancel --invitation-id inv-1")
    }
}
