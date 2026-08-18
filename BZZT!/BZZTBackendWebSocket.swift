import Foundation

enum BZZTBackendIncomingMessage: Equatable {
    case reconnect(BZZTBackendPublicState)
    case roomUpdated(BZZTBackendPublicState)
    case gameStart(BZZTBackendPublicState)
    case roundPrepare(BZZTBackendRoundPreparePayload)
    case roundStart(BZZTBackendRoundStartPayload)
    case answerLocked(roundID: String)
    case roundEnd(BZZTBackendRoundEndPayload)
    case scoreUpdate([String: Int])
    case leaderChanged(sessionID: String)
    case buzzAccepted(roundID: String, sessionID: String)
    case buzzRejected(roundID: String, reason: String)
    case nextRoundStatus(BZZTBackendNextRoundStatusPayload)
    case rematchStarted(BZZTBackendPublicState)
    case gameEnd(BZZTBackendGameEndPayload)
    case error(String)
    case unknown(type: String)
}

struct BZZTBackendOutgoingMessage: Encodable, Equatable {
    let type: String
    var payload: [String: BZZTJSONValue] = [:]

    static func ready() -> BZZTBackendOutgoingMessage {
        BZZTBackendOutgoingMessage(type: "READY")
    }

    static func startGame() -> BZZTBackendOutgoingMessage {
        BZZTBackendOutgoingMessage(type: "START_GAME")
    }

    static func nextRound(roundID: String?) -> BZZTBackendOutgoingMessage {
        var payload: [String: BZZTJSONValue] = [:]
        if let roundID {
            payload["round_id"] = .string(roundID)
        }
        return BZZTBackendOutgoingMessage(type: "NEXT_ROUND", payload: payload)
    }

    static func rematch() -> BZZTBackendOutgoingMessage {
        BZZTBackendOutgoingMessage(type: "REMATCH")
    }

    static func submitAnswer(roundID: String, answerID: String) -> BZZTBackendOutgoingMessage {
        BZZTBackendOutgoingMessage(type: "SUBMIT_ANSWER", payload: [
            "round_id": .string(roundID),
            "answer_id": .string(answerID)
        ])
    }

    static func buzz(roundID: String) -> BZZTBackendOutgoingMessage {
        BZZTBackendOutgoingMessage(type: "BUZZ", payload: [
            "round_id": .string(roundID)
        ])
    }
}

enum BZZTJSONValue: Encodable, Equatable {
    case string(String)
    case int(Int)
    case bool(Bool)

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        }
    }
}

final class BZZTBackendWebSocket {
    private let url: URL
    private let session: URLSession
    private var task: URLSessionWebSocketTask?

    init(url: URL, session: URLSession = .shared) {
        self.url = url
        self.session = session
    }

    func connect() {
        task = session.webSocketTask(with: url)
        task?.resume()
    }

    func disconnect() {
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
    }

    func send(_ message: BZZTBackendOutgoingMessage) async throws {
        let data = try JSONEncoder.bzztBackend.encode(message)
        guard let text = String(data: data, encoding: .utf8) else {
            throw BZZTBackendError.invalidResponse
        }
        try await task?.send(.string(text))
    }

    func receive() async throws -> BZZTBackendIncomingMessage {
        guard let task else {
            throw BZZTBackendError.invalidResponse
        }

        let message = try await task.receive()
        switch message {
        case .string(let text):
            guard let data = text.data(using: .utf8) else {
                throw BZZTBackendError.invalidResponse
            }
            return try BZZTBackendMessageDecoder.decode(data)
        case .data(let data):
            return try BZZTBackendMessageDecoder.decode(data)
        @unknown default:
            throw BZZTBackendError.invalidResponse
        }
    }
}

enum BZZTBackendMessageDecoder {
    static func decode(_ data: Data) throws -> BZZTBackendIncomingMessage {
        let object = try JSONSerialization.jsonObject(with: data)
        guard let dictionary = object as? [String: Any], let type = dictionary["type"] as? String else {
            throw BZZTBackendError.invalidResponse
        }
        let payloadData = try payloadData(from: dictionary["payload"] ?? [:])

        switch type {
        case "RECONNECT":
            return .reconnect(try decodePayload(BZZTBackendPublicState.self, from: payloadData))
        case "ROOM_UPDATED", "PLAYER_JOINED":
            return .roomUpdated(try decodePayload(BZZTBackendPublicState.self, from: payloadData))
        case "GAME_START":
            return .gameStart(try decodePayload(BZZTBackendPublicState.self, from: payloadData))
        case "ROUND_PREPARE":
            return .roundPrepare(try decodePayload(BZZTBackendRoundPreparePayload.self, from: payloadData))
        case "ROUND_START":
            return .roundStart(try decodePayload(BZZTBackendRoundStartPayload.self, from: payloadData))
        case "ANSWER_LOCKED":
            let payload = try decodePayload(RoundIDPayload.self, from: payloadData)
            return .answerLocked(roundID: payload.roundID)
        case "ROUND_END":
            return .roundEnd(try decodePayload(BZZTBackendRoundEndPayload.self, from: payloadData))
        case "SCORE_UPDATE":
            return .scoreUpdate(try decodePayload([String: Int].self, from: payloadData))
        case "LEADER_CHANGED":
            let payload = try decodePayload(SessionIDPayload.self, from: payloadData)
            return .leaderChanged(sessionID: payload.sessionID)
        case "BUZZ_ACCEPTED":
            let payload = try decodePayload(BuzzPayload.self, from: payloadData)
            return .buzzAccepted(roundID: payload.roundID, sessionID: payload.sessionID)
        case "BUZZ_REJECTED":
            let payload = try decodePayload(BuzzRejectedPayload.self, from: payloadData)
            return .buzzRejected(roundID: payload.roundID, reason: payload.reason)
        case "NEXT_ROUND_STATUS":
            return .nextRoundStatus(try decodePayload(BZZTBackendNextRoundStatusPayload.self, from: payloadData))
        case "REMATCH_STARTED":
            return .rematchStarted(try decodePayload(BZZTBackendPublicState.self, from: payloadData))
        case "GAME_END":
            return .gameEnd(try decodePayload(BZZTBackendGameEndPayload.self, from: payloadData))
        case "ERROR":
            let payload = try? decodePayload(ErrorPayload.self, from: payloadData)
            return .error(payload?.message ?? "Backend zwrócił błąd.")
        default:
            return .unknown(type: type)
        }
    }

    private static func payloadData(from payload: Any) throws -> Data {
        guard JSONSerialization.isValidJSONObject(payload) else {
            throw BZZTBackendError.invalidResponse
        }
        return try JSONSerialization.data(withJSONObject: payload)
    }

    private static func decodePayload<T: Decodable>(_ type: T.Type, from payload: Data) throws -> T {
        try JSONDecoder.bzztBackend.decode(type, from: payload)
    }

    private struct RoundIDPayload: Decodable {
        let roundID: String

        enum CodingKeys: String, CodingKey {
            case roundID = "round_id"
        }
    }

    private struct SessionIDPayload: Decodable {
        let sessionID: String

        enum CodingKeys: String, CodingKey {
            case sessionID = "session_id"
        }
    }

    private struct BuzzPayload: Decodable {
        let roundID: String
        let sessionID: String

        enum CodingKeys: String, CodingKey {
            case roundID = "round_id"
            case sessionID = "session_id"
        }
    }

    private struct BuzzRejectedPayload: Decodable {
        let roundID: String
        let reason: String

        enum CodingKeys: String, CodingKey {
            case roundID = "round_id"
            case reason
        }
    }

    private struct ErrorPayload: Decodable {
        let message: String
    }
}
