import ArgumentParser
import Domain

// MARK: - Parent Command

struct GameCenterCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "game-center",
        abstract: "Manage Game Center achievements and leaderboards",
        subcommands: [
            GameCenterDetailCommand.self,
            GameCenterAchievementsCommand.self,
            GameCenterLeaderboardsCommand.self,
        ]
    )
}

// MARK: - Detail

struct GameCenterDetailCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "detail",
        abstract: "Get Game Center details for an app",
        subcommands: [GameCenterDetailGet.self]
    )
}

struct GameCenterDetailGet: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get Game Center configuration for an app"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "App ID")
    var appId: String

    func run() async throws {
        let repo = try ClientProvider.makeGameCenterRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any GameCenterRepository) async throws -> String {
        let detail = try await repo.getDetail(appId: appId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [detail],
            headers: ["ID", "App ID", "Arcade Enabled"],
            rowMapper: { [$0.id, $0.appId, $0.isArcadeEnabled ? "yes" : "no"] }
        )
    }
}

// MARK: - Achievements

struct GameCenterAchievementsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "achievements",
        abstract: "Manage Game Center achievements",
        subcommands: [
            GameCenterAchievementsList.self,
            GameCenterAchievementsCreate.self,
            GameCenterAchievementsDelete.self,
        ]
    )
}

struct GameCenterAchievementsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List achievements for a Game Center detail"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Game Center detail ID")
    var detailId: String

    func run() async throws {
        let repo = try ClientProvider.makeGameCenterRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any GameCenterRepository) async throws -> String {
        let items = try await repo.listAchievements(gameCenterDetailId: detailId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            items,
            headers: ["ID", "Reference Name", "Vendor ID", "Points", "Archived"],
            rowMapper: { [$0.id, $0.referenceName, $0.vendorIdentifier, "\($0.points)", $0.isArchived ? "yes" : "no"] }
        )
    }
}

struct GameCenterAchievementsCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new Game Center achievement"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Game Center detail ID")
    var detailId: String

    @Option(name: .long, help: "Internal reference name")
    var referenceName: String

    @Option(name: .long, help: "Unique vendor identifier")
    var vendorIdentifier: String

    @Option(name: .long, help: "Point value for the achievement")
    var points: Int

    @Flag(name: .long, help: "Show achievement in UI before it is earned")
    var showBeforeEarned: Bool = false

    @Flag(name: .long, help: "Allow players to earn this achievement multiple times")
    var repeatable: Bool = false

    func run() async throws {
        let repo = try ClientProvider.makeGameCenterRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any GameCenterRepository) async throws -> String {
        let item = try await repo.createAchievement(
            gameCenterDetailId: detailId,
            referenceName: referenceName,
            vendorIdentifier: vendorIdentifier,
            points: points,
            isShowBeforeEarned: showBeforeEarned,
            isRepeatable: repeatable
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [item],
            headers: ["ID", "Reference Name", "Vendor ID", "Points"],
            rowMapper: { [$0.id, $0.referenceName, $0.vendorIdentifier, "\($0.points)"] }
        )
    }
}

struct GameCenterAchievementsDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a Game Center achievement"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Achievement ID")
    var achievementId: String

    func run() async throws {
        let repo = try ClientProvider.makeGameCenterRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any GameCenterRepository) async throws {
        try await repo.deleteAchievement(id: achievementId)
    }
}

// MARK: - Leaderboards

struct GameCenterLeaderboardsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "leaderboards",
        abstract: "Manage Game Center leaderboards",
        subcommands: [
            GameCenterLeaderboardsList.self,
            GameCenterLeaderboardsCreate.self,
            GameCenterLeaderboardsDelete.self,
        ]
    )
}

struct GameCenterLeaderboardsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List leaderboards for a Game Center detail"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Game Center detail ID")
    var detailId: String

    func run() async throws {
        let repo = try ClientProvider.makeGameCenterRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any GameCenterRepository) async throws -> String {
        let items = try await repo.listLeaderboards(gameCenterDetailId: detailId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            items,
            headers: ["ID", "Reference Name", "Vendor ID", "Sort", "Submission"],
            rowMapper: { [$0.id, $0.referenceName, $0.vendorIdentifier, $0.scoreSortType.rawValue, $0.submissionType.rawValue] }
        )
    }
}

struct GameCenterLeaderboardsCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new Game Center leaderboard"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Game Center detail ID")
    var detailId: String

    @Option(name: .long, help: "Internal reference name")
    var referenceName: String

    @Option(name: .long, help: "Unique vendor identifier")
    var vendorIdentifier: String

    @Option(name: .long, help: "Score sort order: ASC or DESC")
    var scoreSortType: String

    @Option(name: .long, help: "Submission type: BEST_SCORE or MOST_RECENT_SCORE (default: BEST_SCORE)")
    var submissionType: String = "BEST_SCORE"

    func run() async throws {
        let repo = try ClientProvider.makeGameCenterRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any GameCenterRepository) async throws -> String {
        guard let sortType = ScoreSortType(rawValue: scoreSortType.uppercased()) else {
            throw ValidationError("Invalid --score-sort-type '\(scoreSortType)'. Use: ASC or DESC")
        }
        guard let subType = LeaderboardSubmissionType(rawValue: submissionType.uppercased()) else {
            throw ValidationError("Invalid --submission-type '\(submissionType)'. Use: BEST_SCORE or MOST_RECENT_SCORE")
        }
        let item = try await repo.createLeaderboard(
            gameCenterDetailId: detailId,
            referenceName: referenceName,
            vendorIdentifier: vendorIdentifier,
            scoreSortType: sortType,
            submissionType: subType
        )
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(
            [item],
            headers: ["ID", "Reference Name", "Vendor ID", "Sort", "Submission"],
            rowMapper: { [$0.id, $0.referenceName, $0.vendorIdentifier, $0.scoreSortType.rawValue, $0.submissionType.rawValue] }
        )
    }
}

struct GameCenterLeaderboardsDelete: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a Game Center leaderboard"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Leaderboard ID")
    var leaderboardId: String

    func run() async throws {
        let repo = try ClientProvider.makeGameCenterRepository()
        try await execute(repo: repo)
    }

    func execute(repo: any GameCenterRepository) async throws {
        try await repo.deleteLeaderboard(id: leaderboardId)
    }
}
