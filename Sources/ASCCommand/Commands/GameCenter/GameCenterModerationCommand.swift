import ArgumentParser
import Domain

// MARK: - Score moderations

struct GameCenterScoreModerationsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "score-moderations",
        abstract: "Review and block scores submitted to a leaderboard",
        subcommands: [
            GameCenterScoreModerationsList.self,
            GameCenterScoreModerationsBlock.self,
            GameCenterScoreModerationsUnblock.self,
        ]
    )
}

struct GameCenterScoreModerationsList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List scores submitted to a leaderboard"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Leaderboard ID")
    var leaderboardId: String

    @Flag(name: .long, help: "Only show blocked scores")
    var blockedOnly: Bool = false

    func run() async throws {
        let repo = try ClientProvider.makeGameCenterModerationRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any GameCenterModerationRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let items = try await repo.listScoreModerations(leaderboardId: leaderboardId, blockedOnly: blockedOnly)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items, affordanceMode: affordanceMode)
    }
}

struct GameCenterScoreModerationsBlock: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "block",
        abstract: "Hide a score from the leaderboard"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Score moderation ID")
    var moderationId: String

    func run() async throws {
        let repo = try ClientProvider.makeGameCenterModerationRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any GameCenterModerationRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let items = [try await repo.updateScoreModeration(id: moderationId, isBlocked: true)]
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items, affordanceMode: affordanceMode)
    }
}

struct GameCenterScoreModerationsUnblock: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "unblock",
        abstract: "Show a previously blocked score on the leaderboard again"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Score moderation ID")
    var moderationId: String

    func run() async throws {
        let repo = try ClientProvider.makeGameCenterModerationRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any GameCenterModerationRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let items = [try await repo.updateScoreModeration(id: moderationId, isBlocked: false)]
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items, affordanceMode: affordanceMode)
    }
}

// MARK: - Blocked players

struct GameCenterBlockedPlayersCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "blocked-players",
        abstract: "List players blocked from the game's leaderboards",
        subcommands: [GameCenterBlockedPlayersList.self]
    )
}

struct GameCenterBlockedPlayersList: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List blocked players for a Game Center detail"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Game Center detail ID")
    var detailId: String

    func run() async throws {
        let repo = try ClientProvider.makeGameCenterModerationRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any GameCenterModerationRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let items = try await repo.listBlockedPlayers(gameCenterDetailId: detailId)
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items, affordanceMode: affordanceMode)
    }
}

// MARK: - Players

struct GameCenterPlayersCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "players",
        abstract: "Block or unblock a Game Center player",
        subcommands: [GameCenterPlayersBlock.self, GameCenterPlayersUnblock.self]
    )
}

struct GameCenterPlayersBlock: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "block",
        abstract: "Hide all of a player's scores from the game's leaderboards"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Game Center player ID")
    var playerId: String

    func run() async throws {
        let repo = try ClientProvider.makeGameCenterModerationRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any GameCenterModerationRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let items = [try await repo.updatePlayer(id: playerId, isBlocked: true)]
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items, affordanceMode: affordanceMode)
    }
}

struct GameCenterPlayersUnblock: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "unblock",
        abstract: "Let a blocked player's scores appear on the game's leaderboards again"
    )

    @OptionGroup var globals: GlobalOptions

    @Option(name: .long, help: "Game Center player ID")
    var playerId: String

    func run() async throws {
        let repo = try ClientProvider.makeGameCenterModerationRepository()
        print(try await execute(repo: repo))
    }

    func execute(repo: any GameCenterModerationRepository, affordanceMode: AffordanceMode = .cli) async throws -> String {
        let items = [try await repo.updatePlayer(id: playerId, isBlocked: false)]
        let formatter = OutputFormatter(format: globals.outputFormat, pretty: globals.pretty)
        return try formatter.formatAgentItems(items, affordanceMode: affordanceMode)
    }
}
