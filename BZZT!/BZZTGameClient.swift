import Foundation

enum BZZTConnectionState: Equatable {
    case offline
    case connecting
    case connected
    case reconnecting
    case failed(String)

    var bannerText: String? {
        switch self {
        case .offline, .connected:
            nil
        case .connecting:
            "Łączenie..."
        case .reconnecting:
            "Ponowne łączenie..."
        case .failed(let message):
            message
        }
    }
}

enum BZZTClientCommand {
    case createRoom(settings: BZZTRoomSettings, playerName: String, avatar: String)
    case joinRoom(code: String, playerName: String, avatar: String)
    case updateProfile(name: String, avatar: String)
    case setReady(playerID: BZZTPlayer.ID)
    case startGame
    case roundPrepare(BZZTGamePhase)
    case submitAnswer(BZZTAnswerOption.ID)
    case submitTrueFalse(Bool)
    case submitRisk(answerID: BZZTAnswerOption.ID, wager: Int)
    case armBuzz
    case pressBuzz
    case reconnect
    case disconnect
}

enum BZZTGameEvent {
    case connectionChanged(BZZTConnectionState)
    case roomCreated(BZZTRoom, [BZZTPlayer])
    case roomJoined(BZZTRoom, [BZZTPlayer])
    case profileUpdated(String, String)
    case playerReadyChanged(BZZTPlayer.ID)
    case gameStarted
    case roundPrepared(BZZTGamePhase)
    case answerLocked(BZZTAnswerOption.ID, BZZTRoundResult)
    case trueFalseLocked(Bool, BZZTRoundResult)
    case riskLocked(BZZTAnswerOption.ID, BZZTRoundResult)
    case buzzArmed
    case buzzAccepted(points: Int)
    case reconnectRestored
    case error(String)
}

protocol BZZTGameClient {
    func send(_ command: BZZTClientCommand, state: BZZTGameSnapshot) -> [BZZTGameEvent]
}

struct BZZTGameSnapshot {
    var roomSettings: BZZTRoomSettings
    var room: BZZTRoom?
    var players: [BZZTPlayer]
    var currentQuestion: BZZTQuestion
    var trueFalsePrompt: BZZTTrueFalsePrompt
    var riskPrompt: BZZTRiskPrompt
}

struct BZZTLocalGameClient: BZZTGameClient {
    func send(_ command: BZZTClientCommand, state: BZZTGameSnapshot) -> [BZZTGameEvent] {
        switch command {
        case .createRoom(let settings, let playerName, let avatar):
            let room = BZZTRoom(code: "482731", title: "BZZT! PARTY", settings: settings)
            let players = [
                BZZTPlayer(name: playerName, avatar: avatar, score: 0, isHost: true, isReady: true),
                BZZTPlayer(name: "Ola", avatar: "🦊", score: 0, isReady: true),
                BZZTPlayer(name: "Kasia", avatar: "🤖", score: 0, isReady: false)
            ]
            return [.connectionChanged(.connected), .roomCreated(room, players)]

        case .joinRoom(let code, let playerName, let avatar):
            guard code.count >= 4 else {
                return [.error("Wpisz kod pokoju.")]
            }

            let room = BZZTRoom(code: code, title: "BZZT! PARTY", settings: state.roomSettings)
            let players = [
                BZZTPlayer(name: "Arek", avatar: "😎", score: 0, isHost: true, isReady: true),
                BZZTPlayer(name: playerName, avatar: avatar, score: 0, isReady: false),
                BZZTPlayer(name: "Ola", avatar: "🦊", score: 0, isReady: true)
            ]
            return [.connectionChanged(.connected), .roomJoined(room, players)]

        case .updateProfile(let name, let avatar):
            guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return [.error("Podaj nick gracza.")]
            }
            return [.profileUpdated(name.uppercased(), avatar)]

        case .setReady(let playerID):
            return [.playerReadyChanged(playerID)]

        case .startGame:
            return [.gameStarted]

        case .roundPrepare(let phase):
            return [.roundPrepared(phase)]

        case .submitAnswer(let answerID):
            let isCorrect = answerID == state.currentQuestion.correctAnswerID
            let result = BZZTRoundResult(
                isCorrect: isCorrect,
                points: isCorrect ? 820 : 0,
                correctAnswer: correctAnswerText(for: state.currentQuestion),
                explanation: state.currentQuestion.explanation
            )
            return [.answerLocked(answerID, result)]

        case .submitTrueFalse(let answer):
            let isCorrect = answer == state.trueFalsePrompt.correctAnswer
            let result = BZZTRoundResult(
                isCorrect: isCorrect,
                points: isCorrect ? 640 : 0,
                correctAnswer: state.trueFalsePrompt.correctAnswer ? "PRAWDA" : "FAŁSZ",
                explanation: state.trueFalsePrompt.explanation
            )
            return [.trueFalseLocked(answer, result)]

        case .submitRisk(let answerID, let wager):
            let isCorrect = answerID == state.riskPrompt.question.correctAnswerID
            let result = BZZTRoundResult(
                isCorrect: isCorrect,
                points: isCorrect ? wager : -wager,
                correctAnswer: correctAnswerText(for: state.riskPrompt.question),
                explanation: state.riskPrompt.question.explanation
            )
            return [.riskLocked(answerID, result)]

        case .armBuzz:
            return [.buzzArmed]

        case .pressBuzz:
            return [.buzzAccepted(points: 500)]

        case .reconnect:
            return [.connectionChanged(.reconnecting), .reconnectRestored, .connectionChanged(.connected)]

        case .disconnect:
            return [.connectionChanged(.reconnecting)]
        }
    }

    private func correctAnswerText(for question: BZZTQuestion) -> String {
        guard let option = question.options.first(where: { $0.id == question.correctAnswerID }) else {
            return "-"
        }
        return "\(option.letter) — \(option.text)"
    }
}
