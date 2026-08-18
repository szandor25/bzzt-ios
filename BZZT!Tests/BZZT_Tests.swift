import Testing
@testable import BZZT_

struct BZZT_Tests {
    @Test @MainActor func createRoomBuildsLobbyState() throws {
        let store = makeLocalStore()

        store.createRoom()

        #expect(store.room?.code == "482731")
        #expect(store.players.count == 3)
        #expect(store.players.contains { $0.isHost })
        #expect(store.connectionState == .connected)
    }

    @Test @MainActor func correctAnswerScoresOnlyOnce() throws {
        let store = makeLocalStore()
        store.createRoom()
        store.beginQuestion()

        let correct = store.currentQuestion.options[1]
        let wrong = store.currentQuestion.options[0]
        store.submitAnswer(correct)
        store.submitAnswer(wrong)

        #expect(store.selectedAnswerID == correct.id)
        #expect(store.players.first(where: { $0.isHost })?.score == 820)
    }

    @Test @MainActor func trueFalseAnswerScoresOnlyOnce() throws {
        let store = makeLocalStore()
        store.createRoom()
        store.showTrueFalseRound()

        store.submitTrueFalseAnswer(true)
        store.submitTrueFalseAnswer(false)

        #expect(store.selectedTruthAnswer == true)
        #expect(store.players.first(where: { $0.isHost })?.score == 640)
    }

    @Test @MainActor func incorrectRiskAnswerSubtractsWager() throws {
        let store = makeLocalStore()
        store.createRoom()
        store.showRiskRound()
        store.selectWager(500)

        let wrong = store.riskPrompt.question.options[0]
        store.submitRiskAnswer(wrong)

        #expect(store.selectedAnswerID == wrong.id)
        #expect(store.players.first(where: { $0.isHost })?.score == -500)
    }

    @Test @MainActor func armedBuzzerAwardsHost() throws {
        let store = makeLocalStore()
        store.createRoom()
        store.showBuzzRound()

        store.pressBuzzer()
        #expect(store.players.first(where: { $0.isHost })?.score == 0)

        store.armBuzzer()
        store.pressBuzzer()

        #expect(store.buzzerState == .won)
        #expect(store.players.first(where: { $0.isHost })?.score == 500)
    }

    @Test @MainActor func reconnectRestoresConnectionState() throws {
        let store = makeLocalStore()
        store.createRoom()

        store.simulateConnectionDrop()
        #expect(store.connectionState == .reconnecting)
        #expect(store.connectionBannerText == "Ponowne łączenie...")

        store.reconnect()
        #expect(store.connectionState == .connected)
        #expect(store.connectionBannerText == nil)
    }

    @Test func localClientRejectsShortRoomCode() throws {
        let client = BZZTLocalGameClient()
        let snapshot = BZZTGameSnapshot(
            roomSettings: BZZTRoomSettings(),
            room: nil,
            players: [],
            currentQuestion: .sample,
            trueFalsePrompt: .sample,
            riskPrompt: .sample
        )

        let events = client.send(.joinRoom(code: "12", playerName: "AREK", avatar: "😎"), state: snapshot)

        guard case .error(let message) = events.first else {
            Issue.record("Expected an error event")
            return
        }
        #expect(message == "Wpisz kod pokoju.")
    }

    @MainActor private func makeLocalStore() -> BZZTGameStore {
        let store = BZZTGameStore()
        store.isOnlineMode = false
        return store
    }
}
