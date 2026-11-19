/// REST route registrations for Game Center (`asc game-center …` subcommands).
///
/// Command keys carry the literal space of the nested CLI subcommand so
/// `Affordance.cliCommand` and `RESTPathResolver` share one key.
extension RESTPathResolver {
    static let _gameCenterRoutes: Void = {
        registerRoute(command: "game-center detail", parentParam: "app-id", parentSegment: "apps", segment: "game-center")
        registerRoute(command: "game-center achievements", parentParam: "detail-id", parentSegment: "game-center/details", segment: "achievements")
        registerRoute(command: "game-center leaderboards", parentParam: "detail-id", parentSegment: "game-center/details", segment: "leaderboards")
        registerRoute(command: "game-center blocked-players", parentParam: "detail-id", parentSegment: "game-center/details", segment: "blocked-players")
        registerRoute(command: "game-center score-moderations", parentParam: "leaderboard-id", parentSegment: "game-center/leaderboards", segment: "score-moderations")
    }()
}
