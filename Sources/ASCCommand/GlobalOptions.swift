import ArgumentParser
import Domain

struct GlobalOptions: ParsableArguments {
    @Option(name: .long, help: "Output format: json, table, markdown")
    var output: String = "json"

    @Flag(name: .long, help: "Pretty-print JSON output")
    var pretty: Bool = false

    @Option(name: .long, help: "Request timeout (e.g., 30s, 2m)")
    var timeout: String?

    var outputFormat: OutputFormat {
        OutputFormat(rawValue: output) ?? .json
    }
}
