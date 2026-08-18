import Foundation
import Testing
@testable import BZZT_

struct BZZT_BackendTests {
    @Test @MainActor func webSocketURLUsesBackendContract() throws {
        let configuration = BZZTBackendConfiguration(baseURL: URL(string: "https://api.example.com")!)

        let url = configuration.webSocketURL(roomCode: "482731", sessionID: "session-1")

        #expect(url.absoluteString == "wss://api.example.com/ws/482731?session_id=session-1")
    }

    @Test @MainActor func defaultBackendPointsToProductionAPI() throws {
        #expect(BZZTBackendConfiguration().baseURL.absoluteString == "https://bzzt.e-aw.pl")
    }

    @Test @MainActor func createRoomResponseDecodesSnakeCase() throws {
        let data = Data(#"{"room_code":"482731","player_session_id":"abc","is_host":true}"#.utf8)

        let response = try JSONDecoder.bzztBackend.decode(BZZTRoomSessionResponse.self, from: data)

        #expect(response.roomCode == "482731")
        #expect(response.playerSessionID == "abc")
        #expect(response.isHost)
    }

    @Test @MainActor func roundStartMessageDecodesTypedPayload() throws {
        let json = #"""
        {
          "type": "ROUND_START",
          "payload": {
            "round_id": "r1",
            "round_index": 0,
            "question_type": "multiple_choice",
            "question": {
              "id": "geo_000010",
              "text": "Jaka jest stolica Australii?",
              "audio_url": "/media/audio/questions/geo_000010-question.mp3",
              "answers": [
                {"id": "a1", "label": "A", "text": "Sydney"},
                {"id": "a2", "label": "B", "text": "Melbourne"},
                {"id": "a3", "label": "C", "text": "Canberra"},
                {"id": "a4", "label": "D", "text": "Perth"}
              ],
              "time_limit": 10,
              "base_points": 500
            },
            "server_start_ms": 12345,
            "duration": 10.0
          }
        }
        """#.data(using: .utf8)!

        let message = try BZZTBackendMessageDecoder.decode(json)

        guard case .roundStart(let payload) = message else {
            Issue.record("Expected ROUND_START payload")
            return
        }
        #expect(payload.roundID == "r1")
        #expect(payload.question.id == "geo_000010")
        #expect(payload.question.audioURLPath == "/media/audio/questions/geo_000010-question.mp3")
        #expect(payload.question.answers[2].id == "a3")
        #expect(payload.question.answers[2].text == "Canberra")
        #expect(payload.questionType == "multiple_choice")
    }

    @Test @MainActor func roundEndMessageDecodesSubmissionResults() throws {
        let json = #"""
        {
          "type": "ROUND_END",
          "payload": {
            "round_id": "r1",
            "correct_answer_id": "a2",
            "explanation": "Mario to poprawna odpowiedź.",
            "explanation_audio_url": "/media/audio/questions/gra_000001-explanation.mp3",
            "results": {
              "session-a": {"answer_id": "a2", "response_ms": 420, "is_correct": true, "points": 880},
              "session-b": {"answer_id": null, "response_ms": null, "is_correct": false, "points": 0}
            }
          }
        }
        """#.data(using: .utf8)!

        let message = try BZZTBackendMessageDecoder.decode(json)

        guard case .roundEnd(let payload) = message else {
            Issue.record("Expected ROUND_END payload")
            return
        }
        #expect(payload.correctAnswerID == "a2")
        #expect(payload.explanationAudioURLPath == "/media/audio/questions/gra_000001-explanation.mp3")
        #expect(payload.results["session-a"]?.points == 880)
        #expect(payload.results["session-b"]?.answerID == nil)
    }

    @Test @MainActor func gameEndMessageMapsRankingToPlayers() throws {
        let json = #"""
        {
          "type": "GAME_END",
          "payload": {
            "ranking": [
              {"session_id":"s1","nickname":"Arek","avatar":"😎","score":1200,"rank":1},
              {"session_id":"s2","nickname":"Ola","avatar":"🦊","score":900,"rank":2}
            ]
          }
        }
        """#.data(using: .utf8)!

        let message = try BZZTBackendMessageDecoder.decode(json)

        guard case .gameEnd(let payload) = message else {
            Issue.record("Expected GAME_END payload")
            return
        }
        let players = payload.ranking.map(\.bzztPlayer)
        #expect(players.first?.name == "Arek")
        #expect(players.first?.score == 1200)
    }

    @Test @MainActor func nextRoundStatusMessageDecodesReadyAndWaitingLists() throws {
        let json = #"""
        {
          "type": "NEXT_ROUND_STATUS",
          "payload": {
            "round_id": "r1",
            "ready": ["session-a"],
            "waiting_for": ["session-b", "session-c"]
          }
        }
        """#.data(using: .utf8)!

        let message = try BZZTBackendMessageDecoder.decode(json)

        guard case .nextRoundStatus(let payload) = message else {
            Issue.record("Expected NEXT_ROUND_STATUS payload")
            return
        }
        #expect(payload.roundID == "r1")
        #expect(payload.ready == ["session-a"])
        #expect(payload.waitingFor == ["session-b", "session-c"])
    }

    @Test @MainActor func rematchStartedMessageDecodesPublicState() throws {
        let json = #"""
        {
          "type": "REMATCH_STARTED",
          "payload": {
            "room_code": "482731",
            "phase": "lobby",
            "round_count": 6,
            "game_mode": "party",
            "host_session_id": "session-a",
            "players": [
              {"session_id":"session-a","nickname":"Arek","avatar":"😎","is_host":true,"ready":false,"connected":true,"score":0},
              {"session_id":"session-b","nickname":"Ola","avatar":"🦊","is_host":false,"ready":false,"connected":true,"score":0}
            ]
          }
        }
        """#.data(using: .utf8)!

        let message = try BZZTBackendMessageDecoder.decode(json)

        guard case .rematchStarted(let state) = message else {
            Issue.record("Expected REMATCH_STARTED payload")
            return
        }
        #expect(state.roomCode == "482731")
        #expect(state.phase == "lobby")
        #expect(state.gameMode == "party")
        #expect(state.players.allSatisfy { $0.score == 0 })
    }
}
