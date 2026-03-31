import Domain
import Foundation
import Network

/// HTTP server for interactive simulator streaming.
/// Serves the web UI at `/` and handles API routes for screenshots and AXe interactions.
public final class DeviceStreamServer: @unchecked Sendable {
    private let listener: NWListener
    private let queue = DispatchQueue(label: "device-stream-server")

    public let port: UInt16
    private let simulatorRepo: any SimulatorRepository
    private let interactionRepo: any SimulatorInteractionRepository
    private let htmlContent: String
    private let deviceConfigJSON: String

    public init(
        port: UInt16 = 8425,
        simulatorRepo: any SimulatorRepository,
        interactionRepo: any SimulatorInteractionRepository,
        htmlContent: String,
        deviceConfigJSON: String = "{}"
    ) throws {
        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            throw DeviceStreamServerError.invalidPort
        }
        self.port = port
        self.simulatorRepo = simulatorRepo
        self.interactionRepo = interactionRepo
        self.htmlContent = htmlContent
        self.deviceConfigJSON = deviceConfigJSON
        self.listener = try NWListener(using: .tcp, on: nwPort)
    }

    public func start() {
        listener.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }
        listener.stateUpdateHandler = { state in
            if case .failed(let error) = state {
                print("Server failed: \(error)")
            }
        }
        listener.start(queue: queue)
    }

    public func stop() {
        listener.cancel()
    }

    // MARK: - Connection Handling

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: queue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, error in
            guard error == nil, let self, let data else {
                connection.cancel()
                return
            }

            let request = String(data: data, encoding: .utf8) ?? ""
            self.route(request: request, connection: connection)
        }
    }

    private func route(request: String, connection: NWConnection) {
        let lines = request.split(separator: "\r\n", maxSplits: 1)
        let requestLine = String(lines.first ?? "")
        let parts = requestLine.split(separator: " ")
        let method = String(parts.first ?? "")
        let rawPath = parts.count > 1 ? String(parts[1]) : "/"

        // Parse path and query string
        let urlComponents = rawPath.split(separator: "?", maxSplits: 1)
        let path = String(urlComponents[0])
        let queryString = urlComponents.count > 1 ? String(urlComponents[1]) : ""
        let query = parseQuery(queryString)

        // Parse body for POST requests
        let body: [String: Any]
        if method == "POST", let bodyStart = request.range(of: "\r\n\r\n") {
            let bodyStr = String(request[bodyStart.upperBound...])
            body = parseJSON(bodyStr)
        } else {
            body = [:]
        }

        // CORS preflight
        if method == "OPTIONS" {
            return sendCORS(connection: connection)
        }

        switch (method, path) {
        case ("GET", "/"), ("GET", "/index.html"):
            sendHTML(connection: connection)

        case ("GET", "/api/device-config"):
            sendRawJSON(deviceConfigJSON, connection: connection)

        case ("GET", "/api/devices"):
            handleDevices(connection: connection)

        case ("GET", "/api/screenshot"):
            handleScreenshot(udid: query["udid"] ?? "", connection: connection)

        case ("POST", "/api/boot"):
            handleBoot(udid: body["udid"] as? String ?? "", connection: connection)

        case ("POST", "/api/tap"):
            handleTap(body: body, connection: connection)

        case ("POST", "/api/swipe"):
            handleSwipe(body: body, connection: connection)

        case ("POST", "/api/gesture"):
            handleGesture(body: body, connection: connection)

        case ("POST", "/api/type"):
            handleType(body: body, connection: connection)

        case ("POST", "/api/button"):
            handleButton(body: body, connection: connection)

        case ("POST", "/api/key"):
            handleKey(body: body, connection: connection)

        case ("POST", "/api/key-combo"):
            handleKeyCombo(body: body, connection: connection)

        case ("GET", "/api/describe"):
            handleDescribe(udid: query["udid"] ?? "", point: query["point"], connection: connection)

        case ("POST", "/api/batch"):
            handleBatch(body: body, connection: connection)

        default:
            sendJSON(["error": "not found"], status: 404, connection: connection)
        }
    }

    // MARK: - API Handlers

    private func handleDevices(connection: NWConnection) {
        nonisolated(unsafe) let conn = connection
        Task { let connection = conn
            do {
                let simulators = try await simulatorRepo.listSimulators(filter: .available)
                let devices = simulators.map { sim -> [String: Any] in
                    [
                        "udid": sim.id,
                        "name": sim.name,
                        "state": sim.state.rawValue,
                        "runtime": sim.displayRuntime,
                        "isAvailable": true,
                    ]
                }
                sendJSON(["devices": devices, "axeAvailable": interactionRepo.isAvailable()], connection: connection)
            } catch {
                sendJSON(["devices": [] as [Any], "axeAvailable": false], connection: connection)
            }
        }
    }

    private func handleScreenshot(udid: String, connection: NWConnection) {
        guard !udid.isEmpty else {
            return sendJSON(["error": "missing udid"], status: 400, connection: connection)
        }
        nonisolated(unsafe) let conn = connection
        Task { let connection = conn
            do {
                let tmpFile = FileManager.default.temporaryDirectory
                    .appendingPathComponent("sim-\(udid)-\(Int(Date().timeIntervalSince1970 * 1000)).png")
                try await simulatorRepo.captureScreenshot(udid: udid, destination: tmpFile)
                let imageData = try Data(contentsOf: tmpFile)
                try? FileManager.default.removeItem(at: tmpFile)
                sendPNG(imageData, connection: connection)
            } catch {
                sendJSON(["error": "capture failed"], status: 500, connection: connection)
            }
        }
    }

    private func handleBoot(udid: String, connection: NWConnection) {
        guard !udid.isEmpty else {
            return sendJSON(["error": "missing udid"], status: 400, connection: connection)
        }
        nonisolated(unsafe) let conn = connection
        Task { let connection = conn
            do {
                try await simulatorRepo.bootSimulator(udid: udid)
                sendJSON(["success": true], connection: connection)
            } catch {
                if error.localizedDescription.contains("Booted") {
                    sendJSON(["success": true, "message": "Already booted"], connection: connection)
                } else {
                    sendJSON(["success": false, "error": error.localizedDescription], status: 500, connection: connection)
                }
            }
        }
    }

    private func handleTap(body: [String: Any], connection: NWConnection) {
        let udid = body["udid"] as? String ?? ""
        let id = body["id"] as? String
        let label = body["label"] as? String
        let x = asInt(body["x"])
        let y = asInt(body["y"])
        nonisolated(unsafe) let conn = connection
        Task { let connection = conn
            do {
                if let id {
                    try await interactionRepo.tapById(udid: udid, identifier: id)
                    sendJSON(["success": true, "action": "tap", "id": id], connection: connection)
                } else if let label {
                    try await interactionRepo.tapByLabel(udid: udid, label: label)
                    sendJSON(["success": true, "action": "tap", "label": label], connection: connection)
                } else {
                    try await interactionRepo.tap(udid: udid, x: x, y: y)
                    sendJSON(["success": true, "action": "tap", "x": x, "y": y], connection: connection)
                }
            } catch {
                sendJSON(["error": error.localizedDescription], status: 500, connection: connection)
            }
        }
    }

    private func handleSwipe(body: [String: Any], connection: NWConnection) {
        let udid = body["udid"] as? String ?? ""
        let startX = asInt(body["fromX"])
        let startY = asInt(body["fromY"])
        let endX = asInt(body["toX"])
        let endY = asInt(body["toY"])
        let duration = body["duration"] as? Double
        let delta = body["delta"] as? Int
        nonisolated(unsafe) let conn = connection
        Task { let connection = conn
            do {
                try await interactionRepo.swipe(
                    udid: udid, startX: startX, startY: startY,
                    endX: endX, endY: endY, duration: duration, delta: delta
                )
                sendJSON(["success": true, "action": "swipe"], connection: connection)
            } catch {
                sendJSON(["error": error.localizedDescription], status: 500, connection: connection)
            }
        }
    }

    private func handleGesture(body: [String: Any], connection: NWConnection) {
        let udid = body["udid"] as? String ?? ""
        let gestureStr = body["gesture"] as? String ?? ""
        nonisolated(unsafe) let conn = connection
        Task { let connection = conn
            do {
                guard let gesture = SimulatorGesture(rawValue: gestureStr) else {
                    return sendJSON(["error": "unknown gesture: \(gestureStr)"], status: 400, connection: connection)
                }
                try await interactionRepo.gesture(udid: udid, gesture: gesture)
                sendJSON(["success": true, "action": "gesture", "gesture": gestureStr], connection: connection)
            } catch {
                sendJSON(["error": error.localizedDescription], status: 500, connection: connection)
            }
        }
    }

    private func handleType(body: [String: Any], connection: NWConnection) {
        let udid = body["udid"] as? String ?? ""
        let text = body["text"] as? String ?? ""
        nonisolated(unsafe) let conn = connection
        Task { let connection = conn
            do {
                try await interactionRepo.type(udid: udid, text: text)
                sendJSON(["success": true, "action": "type"], connection: connection)
            } catch {
                sendJSON(["error": error.localizedDescription], status: 500, connection: connection)
            }
        }
    }

    private func handleButton(body: [String: Any], connection: NWConnection) {
        let udid = body["udid"] as? String ?? ""
        let buttonStr = body["button"] as? String ?? ""
        nonisolated(unsafe) let conn = connection
        Task { let connection = conn
            do {
                guard let button = SimulatorButton(rawValue: buttonStr.lowercased()) else {
                    return sendJSON(["error": "unknown button: \(buttonStr)"], status: 400, connection: connection)
                }
                try await interactionRepo.button(udid: udid, button: button)
                sendJSON(["success": true, "action": "button", "button": buttonStr], connection: connection)
            } catch {
                sendJSON(["error": error.localizedDescription], status: 500, connection: connection)
            }
        }
    }

    private func handleKey(body: [String: Any], connection: NWConnection) {
        let udid = body["udid"] as? String ?? ""
        let keycode = asInt(body["keycode"])
        let duration = body["duration"] as? Double
        nonisolated(unsafe) let conn = connection
        Task { let connection = conn
            do {
                try await interactionRepo.key(udid: udid, keyCode: keycode, duration: duration)
                sendJSON(["success": true, "action": "key", "keycode": keycode], connection: connection)
            } catch {
                sendJSON(["error": error.localizedDescription], status: 500, connection: connection)
            }
        }
    }

    private func handleKeyCombo(body: [String: Any], connection: NWConnection) {
        let udid = body["udid"] as? String ?? ""
        let key = asInt(body["key"])
        let modifiers: [Int]
        if let arr = body["modifiers"] as? [Any] {
            modifiers = arr.compactMap { asIntOptional($0) }
        } else {
            modifiers = []
        }
        nonisolated(unsafe) let conn = connection
        Task { let connection = conn
            do {
                try await interactionRepo.keyCombo(udid: udid, modifiers: modifiers, key: key)
                sendJSON(["success": true, "action": "key-combo"], connection: connection)
            } catch {
                sendJSON(["error": error.localizedDescription], status: 500, connection: connection)
            }
        }
    }

    private func handleDescribe(udid: String, point: String?, connection: NWConnection) {
        guard !udid.isEmpty else {
            return sendJSON(["error": "missing udid"], status: 400, connection: connection)
        }
        nonisolated(unsafe) let conn = connection
        Task { let connection = conn
            do {
                let tree = try await interactionRepo.describeUI(udid: udid, point: point)
                sendJSON(["success": true, "tree": tree], connection: connection)
            } catch {
                sendJSON(["error": error.localizedDescription], status: 500, connection: connection)
            }
        }
    }

    private func handleBatch(body: [String: Any], connection: NWConnection) {
        let udid = body["udid"] as? String ?? ""
        let steps = (body["steps"] as? [Any])?.compactMap { $0 as? String } ?? []
        nonisolated(unsafe) let conn = connection
        Task { let connection = conn
            do {
                try await interactionRepo.batch(udid: udid, steps: steps)
                sendJSON(["success": true, "action": "batch", "steps": steps.count], connection: connection)
            } catch {
                sendJSON(["error": error.localizedDescription], status: 500, connection: connection)
            }
        }
    }

    // MARK: - Response Helpers

    private func sendRawJSON(_ jsonString: String, connection: NWConnection) {
        let body = Data(jsonString.utf8)
        let headers = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: \(body.count)\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\n\r\n"
        var payload = Data(headers.utf8)
        payload.append(body)
        connection.send(content: payload, isComplete: true, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    private func sendHTML(connection: NWConnection) {
        let body = Data(htmlContent.utf8)
        let headers = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: \(body.count)\r\nConnection: close\r\n\r\n"
        var payload = Data(headers.utf8)
        payload.append(body)
        connection.send(content: payload, isComplete: true, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    private func sendJSON(_ dict: [String: Any], status: Int = 200, connection: NWConnection) {
        let body: Data
        if let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []) {
            body = jsonData
        } else {
            body = Data("{}".utf8)
        }
        let statusText = status == 200 ? "OK" : status == 400 ? "Bad Request" : status == 404 ? "Not Found" : status == 500 ? "Internal Server Error" : "Error"
        let headers = "HTTP/1.1 \(status) \(statusText)\r\nContent-Type: application/json\r\nContent-Length: \(body.count)\r\nAccess-Control-Allow-Origin: *\r\nConnection: close\r\n\r\n"
        var payload = Data(headers.utf8)
        payload.append(body)
        connection.send(content: payload, isComplete: true, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    private func sendPNG(_ imageData: Data, connection: NWConnection) {
        let headers = "HTTP/1.1 200 OK\r\nContent-Type: image/png\r\nContent-Length: \(imageData.count)\r\nCache-Control: no-cache\r\nConnection: close\r\n\r\n"
        var payload = Data(headers.utf8)
        payload.append(imageData)
        connection.send(content: payload, isComplete: true, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    private func sendCORS(connection: NWConnection) {
        let headers = "HTTP/1.1 204 No Content\r\nAccess-Control-Allow-Origin: *\r\nAccess-Control-Allow-Methods: GET, POST, OPTIONS\r\nAccess-Control-Allow-Headers: Content-Type\r\nConnection: close\r\n\r\n"
        connection.send(content: Data(headers.utf8), isComplete: true, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    // MARK: - Parsing Helpers

    private func parseQuery(_ queryString: String) -> [String: String] {
        var result: [String: String] = [:]
        for pair in queryString.split(separator: "&") {
            let kv = pair.split(separator: "=", maxSplits: 1)
            if kv.count == 2 {
                result[String(kv[0])] = String(kv[1]).removingPercentEncoding ?? String(kv[1])
            }
        }
        return result
    }

    private func parseJSON(_ string: String) -> [String: Any] {
        guard let data = string.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return json
    }

    private func asInt(_ value: Any?) -> Int {
        if let i = value as? Int { return i }
        if let d = value as? Double { return Int(d) }
        if let s = value as? String, let i = Int(s) { return i }
        return 0
    }

    private func asIntOptional(_ value: Any?) -> Int? {
        if let i = value as? Int { return i }
        if let d = value as? Double { return Int(d) }
        if let s = value as? String { return Int(s) }
        return nil
    }
}

public enum DeviceStreamServerError: Error, LocalizedError {
    case invalidPort

    public var errorDescription: String? {
        switch self {
        case .invalidPort:
            return "Invalid port number"
        }
    }
}
