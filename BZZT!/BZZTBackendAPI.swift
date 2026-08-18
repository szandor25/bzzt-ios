import Foundation

struct BZZTBackendConfiguration: Equatable {
    var baseURL: URL

    init(baseURL: URL = URL(string: "https://bzzt.e-aw.pl")!) {
        self.baseURL = baseURL
    }

    func webSocketURL(roomCode: String, sessionID: String) -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.scheme = components.scheme == "https" ? "wss" : "ws"
        components.path = "/ws/\(roomCode)"
        components.queryItems = [URLQueryItem(name: "session_id", value: sessionID)]
        return components.url!
    }
}

struct BZZTCreateRoomRequest: Encodable, Equatable {
    let nickname: String
    let avatar: String
    let roundCount: Int
    let gameMode: String

    enum CodingKeys: String, CodingKey {
        case nickname
        case avatar
        case roundCount = "round_count"
        case gameMode = "game_mode"
    }
}

struct BZZTJoinRoomRequest: Encodable, Equatable {
    let nickname: String
    let avatar: String
}

struct BZZTRoomSessionResponse: Decodable, Equatable {
    let roomCode: String
    let playerSessionID: String
    let isHost: Bool

    enum CodingKeys: String, CodingKey {
        case roomCode = "room_code"
        case playerSessionID = "player_session_id"
        case isHost = "is_host"
    }
}

struct BZZTSessionLookupResponse: Decodable, Equatable {
    let roomCode: String

    enum CodingKeys: String, CodingKey {
        case roomCode = "room_code"
    }
}

struct BZZTBackendPublicState: Decodable, Equatable {
    let roomCode: String
    let phase: String
    let roundCount: Int
    let gameMode: String?
    let hostSessionID: String
    let players: [BZZTBackendPlayer]

    enum CodingKeys: String, CodingKey {
        case roomCode = "room_code"
        case phase
        case roundCount = "round_count"
        case gameMode = "game_mode"
        case hostSessionID = "host_session_id"
        case players
    }
}

struct BZZTBackendPlayer: Decodable, Equatable {
    let sessionID: String
    let nickname: String
    let avatar: String
    let isHost: Bool
    let ready: Bool
    let connected: Bool
    let score: Int

    enum CodingKeys: String, CodingKey {
        case sessionID = "session_id"
        case nickname
        case avatar
        case isHost = "is_host"
        case ready
        case connected
        case score
    }
}

struct BZZTBackendQuestion: Decodable, Equatable {
    let id: String
    let text: String
    let audioURLPath: String?
    let answers: [BZZTBackendAnswer]
    let timeLimit: Int
    let basePoints: Int

    enum CodingKeys: String, CodingKey {
        case id
        case text
        case audioURLPath = "audio_url"
        case answers
        case timeLimit = "time_limit"
        case basePoints = "base_points"
    }
}

struct BZZTBackendAnswer: Decodable, Equatable {
    let id: String
    let label: String
    let text: String
}

struct BZZTBackendRoundStartPayload: Decodable, Equatable {
    let roundID: String
    let roundIndex: Int
    let questionType: String
    let question: BZZTBackendQuestion
    let serverStartMS: Int
    let duration: Double

    enum CodingKeys: String, CodingKey {
        case roundID = "round_id"
        case roundIndex = "round_index"
        case questionType = "question_type"
        case question
        case serverStartMS = "server_start_ms"
        case duration
    }
}

struct BZZTBackendRoundPreparePayload: Decodable, Equatable {
    let roundID: String
    let roundIndex: Int
    let questionType: String
    let startsInMS: Int

    enum CodingKeys: String, CodingKey {
        case roundID = "round_id"
        case roundIndex = "round_index"
        case questionType = "question_type"
        case startsInMS = "starts_in_ms"
    }
}

struct BZZTBackendRoundEndPayload: Decodable, Equatable {
    let roundID: String
    let correctAnswerID: String
    let explanation: String?
    let explanationAudioURLPath: String?
    let results: [String: BZZTBackendSubmissionResult]

    enum CodingKeys: String, CodingKey {
        case roundID = "round_id"
        case correctAnswerID = "correct_answer_id"
        case explanation
        case explanationAudioURLPath = "explanation_audio_url"
        case results
    }
}

struct BZZTBackendSubmissionResult: Decodable, Equatable {
    let answerID: String?
    let responseMS: Int?
    let isCorrect: Bool
    let points: Int

    enum CodingKeys: String, CodingKey {
        case answerID = "answer_id"
        case responseMS = "response_ms"
        case isCorrect = "is_correct"
        case points
    }
}

struct BZZTBackendNextRoundStatusPayload: Decodable, Equatable {
    let roundID: String
    let ready: [String]
    let waitingFor: [String]

    enum CodingKeys: String, CodingKey {
        case roundID = "round_id"
        case ready
        case waitingFor = "waiting_for"
    }
}

struct BZZTBackendGameEndPayload: Decodable, Equatable {
    let ranking: [BZZTBackendRankingPlayer]
}

struct BZZTBackendRankingPlayer: Decodable, Equatable {
    let sessionID: String
    let nickname: String
    let avatar: String
    let score: Int
    let rank: Int

    enum CodingKeys: String, CodingKey {
        case sessionID = "session_id"
        case nickname
        case avatar
        case score
        case rank
    }
}

enum BZZTBackendError: LocalizedError, Equatable {
    case invalidResponse
    case server(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "Nieprawidłowa odpowiedź backendu."
        case .server(_, let message):
            message
        }
    }
}

struct BZZTBackendAPI {
    let configuration: BZZTBackendConfiguration
    var session: URLSession = .shared

    init(configuration: BZZTBackendConfiguration = BZZTBackendConfiguration(), session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    func createRoom(nickname: String, avatar: String, roundCount: Int = 6, gameMode: BZZTGameMode = .party) async throws -> BZZTRoomSessionResponse {
        let payload = BZZTCreateRoomRequest(nickname: nickname, avatar: avatar, roundCount: roundCount, gameMode: gameMode.backendValue)
        return try await send(path: "/rooms", method: "POST", body: payload)
    }

    func joinRoom(code: String, nickname: String, avatar: String) async throws -> BZZTRoomSessionResponse {
        let payload = BZZTJoinRoomRequest(nickname: nickname, avatar: avatar)
        return try await send(path: "/rooms/\(code)/join", method: "POST", body: payload)
    }

    func getRoom(code: String) async throws -> BZZTBackendPublicState {
        try await send(path: "/rooms/\(code)", method: "GET", body: Optional<String>.none)
    }

    func lookupSession(_ sessionID: String) async throws -> BZZTSessionLookupResponse {
        try await send(path: "/sessions/\(sessionID)", method: "GET", body: Optional<String>.none)
    }

    private func send<Response: Decodable, Body: Encodable>(path: String, method: String, body: Body?) async throws -> Response {
        guard var components = URLComponents(url: configuration.baseURL, resolvingAgainstBaseURL: false) else {
            throw BZZTBackendError.invalidResponse
        }
        components.path = path
        guard let url = components.url else {
            throw BZZTBackendError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder.bzztBackend.encode(body)
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BZZTBackendError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw BZZTBackendError.server(statusCode: httpResponse.statusCode, message: decodeErrorMessage(from: data))
        }

        return try JSONDecoder.bzztBackend.decode(Response.self, from: data)
    }

    private func decodeErrorMessage(from data: Data) -> String {
        struct ErrorPayload: Decodable {
            let detail: String?
        }

        return (try? JSONDecoder.bzztBackend.decode(ErrorPayload.self, from: data).detail) ?? "Backend zwrócił błąd."
    }
}

extension JSONEncoder {
    static var bzztBackend: JSONEncoder {
        JSONEncoder()
    }
}

extension JSONDecoder {
    static var bzztBackend: JSONDecoder {
        JSONDecoder()
    }
}
