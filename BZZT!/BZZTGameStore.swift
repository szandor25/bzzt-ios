import AVFoundation
import Foundation
import Observation

@Observable
@MainActor
final class BZZTGameStore {
    var phase: BZZTGamePhase = .home
    var roomSettings = BZZTRoomSettings()
    var room: BZZTRoom?
    var players: [BZZTPlayer] = []
    var localPlayerName = "AREK"
    var localAvatar = "😎"
    var joinCode = ""
    var currentQuestion = BZZTQuestion.sample
    var trueFalsePrompt = BZZTTrueFalsePrompt.sample
    var riskPrompt = BZZTRiskPrompt.sample
    var selectedAnswerID: BZZTAnswerOption.ID?
    var selectedTruthAnswer: Bool?
    var selectedWager = 250
    var buzzerState: BZZTBuzzerState = .waiting
    var connectionState: BZZTConnectionState = .offline
    var connectionMessage: String?
    var backendRoundCount = 6
    var backendBaseURLString = "https://bzzt.e-aw.pl"
    var hostVoiceEnabled = true
    var hapticsEnabled = true
    var musicVolume = 0.65
    var effectsVolume = 0.80
    var isOnlineMode = true
    var resultAdvanceDeadline: Date?
    var didRequestNextRound = false
    var nextRoundReadySessionIDs: Set<String> = []
    var nextRoundWaitingSessionIDs: Set<String> = []
    var isWaitingForRematch = false

    let avatars = ["😎", "🤖", "🦊", "👽", "🐯", "🧠"]

    private let localClient: BZZTGameClient
    private var backendAPI: BZZTBackendAPI
    private var backendWebSocket: BZZTBackendWebSocket?
    private var listenTask: Task<Void, Never>?
    private var localSessionID: String?
    private var backendSessionIDsByPlayerID: [BZZTPlayer.ID: String] = [:]
    private var currentRoundID: String?
    private var currentQuestionType: String?
    private var pendingBuzzAnswerID: String?
    private var isHost = false
    private var audioPlayer: AVPlayer?
    private var resultVisibleUntil: Date?
    private var deferredRoundTransitionTask: Task<Void, Never>?
    private var pendingRoundTransition: (@MainActor () -> Void)?
    private let resultDisplayDuration: TimeInterval = 60

    init() {
        let defaults = UserDefaults.standard
        let savedBackendURL = defaults.string(forKey: DefaultsKey.backendBaseURL) ?? "https://bzzt.e-aw.pl"

        self.localClient = BZZTLocalGameClient()
        self.backendBaseURLString = savedBackendURL
        self.localPlayerName = defaults.string(forKey: DefaultsKey.playerName) ?? "AREK"
        self.localAvatar = defaults.string(forKey: DefaultsKey.playerAvatar) ?? "😎"
        self.hostVoiceEnabled = defaults.object(forKey: DefaultsKey.hostVoiceEnabled) as? Bool ?? true
        self.hapticsEnabled = defaults.object(forKey: DefaultsKey.hapticsEnabled) as? Bool ?? true
        self.musicVolume = defaults.object(forKey: DefaultsKey.musicVolume) as? Double ?? 0.65
        self.effectsVolume = defaults.object(forKey: DefaultsKey.effectsVolume) as? Double ?? 0.80
        self.backendAPI = BZZTGameStore.makeBackendAPI(from: savedBackendURL)
    }

    var sortedPlayers: [BZZTPlayer] {
        players.sorted { lhs, rhs in
            if lhs.score == rhs.score {
                lhs.name < rhs.name
            } else {
                lhs.score > rhs.score
            }
        }
    }

    var canStartGame: Bool {
        players.count >= 2 && players.filter { !$0.isHost }.allSatisfy(\.isReady)
    }

    var localPlayerScore: Int {
        players.first(where: { $0.isHost })?.score ?? 0
    }

    var connectionBannerText: String? {
        connectionMessage ?? connectionState.bannerText
    }

    var nextRoundReadyCount: Int {
        nextRoundReadySessionIDs.count
    }

    var nextRoundWaitingNames: [String] {
        nextRoundWaitingSessionIDs.compactMap { sessionID in
            players.first { player in
                backendSessionIDsByPlayerID[player.id] == sessionID
            }?.name
        }
    }

    func showCreateRoom() {
        phase = .createRoom
    }

    func showJoinRoom() {
        phase = .joinRoom
    }

    func showPlayerProfile() {
        phase = .playerProfile
    }

    func showSettings() {
        phase = .settings
    }

    func selectGameMode(_ mode: BZZTGameMode) {
        roomSettings.mode = mode
        roomSettings.roundCount = mode.recommendedRoundCount
    }

    func quickStart() {
        createRoom()
    }

    func createRoom() {
        guard isOnlineMode else {
            connectionState = .connecting
            sendLocal(.createRoom(settings: roomSettings, playerName: localPlayerName, avatar: localAvatar))
            return
        }

        Task {
            await createOnlineRoom()
        }
    }

    func joinRoom() {
        guard isOnlineMode else {
            connectionState = .connecting
            sendLocal(.joinRoom(code: joinCode, playerName: localPlayerName, avatar: localAvatar))
            return
        }

        Task {
            await joinOnlineRoom()
        }
    }

    func saveProfile() {
        saveProfileDefaults()
        guard !isOnlineMode else {
            connectionMessage = nil
            phase = .lobby
            return
        }
        sendLocal(.updateProfile(name: localPlayerName, avatar: localAvatar))
    }

    func savePlayerProfile() {
        saveProfileDefaults()
        connectionMessage = "Profil zapisany."
        phase = .home
    }

    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(backendBaseURLString, forKey: DefaultsKey.backendBaseURL)
        defaults.set(hostVoiceEnabled, forKey: DefaultsKey.hostVoiceEnabled)
        defaults.set(hapticsEnabled, forKey: DefaultsKey.hapticsEnabled)
        defaults.set(musicVolume, forKey: DefaultsKey.musicVolume)
        defaults.set(effectsVolume, forKey: DefaultsKey.effectsVolume)
        backendAPI = BZZTGameStore.makeBackendAPI(from: backendBaseURLString)
        connectionMessage = "Ustawienia zapisane."
        phase = .home
    }

    func toggleReady(for playerID: BZZTPlayer.ID) {
        guard !isOnlineMode else { return }
        sendLocal(.setReady(playerID: playerID))
    }

    func markLocalReady() {
        guard isOnlineMode else {
            markLocalReadyInMock()
            return
        }

        Task {
            await sendWebSocket(.ready())
        }
    }

    func startGame() {
        guard canStartGame else {
            connectionMessage = "Gra może ruszyć dopiero, gdy wszyscy gracze są gotowi."
            return
        }

        guard isOnlineMode else {
            sendLocal(.startGame)
            return
        }

        Task {
            await sendWebSocket(.startGame())
        }
    }

    func advanceCountdown(from value: Int) {
        if value > 1 {
            phase = .countdown(value - 1)
        } else {
            phase = .roundIntro
        }
    }

    func beginQuestion() {
        guard !isOnlineMode else { return }
        sendLocal(.roundPrepare(.question))
    }

    func submitAnswer(_ option: BZZTAnswerOption) {
        guard selectedAnswerID == nil else { return }

        guard isOnlineMode else {
            sendLocal(.submitAnswer(option.id))
            return
        }

        selectedAnswerID = option.id
        guard let currentRoundID else { return }

        if currentQuestionType == "buzz" {
            pendingBuzzAnswerID = option.id
            buzzerState = .pressed
            Task {
                await sendWebSocket(.buzz(roundID: currentRoundID))
            }
            return
        }

        Task {
            await sendWebSocket(.submitAnswer(roundID: currentRoundID, answerID: option.id))
        }
    }

    func state(for option: BZZTAnswerOption) -> BZZTAnswerState {
        guard let selectedAnswerID else { return .idle }

        guard let correctAnswerID = currentQuestion.correctAnswerID else {
            return option.id == selectedAnswerID ? .submitted : .disabled
        }

        if option.id == correctAnswerID {
            return .correct
        }

        if option.id == selectedAnswerID {
            return .incorrect
        }

        return .disabled
    }

    func showTrueFalseRound() {
        sendLocal(.roundPrepare(.trueFalse))
    }

    func submitTrueFalseAnswer(_ answer: Bool) {
        guard selectedTruthAnswer == nil else { return }
        sendLocal(.submitTrueFalse(answer))
    }

    func showRiskRound() {
        sendLocal(.roundPrepare(.risk))
    }

    func selectWager(_ wager: Int) {
        selectedWager = wager
    }

    func submitRiskAnswer(_ option: BZZTAnswerOption) {
        guard selectedAnswerID == nil else { return }
        sendLocal(.submitRisk(answerID: option.id, wager: selectedWager))
    }

    func showBuzzRound() {
        guard !isOnlineMode else { return }
        sendLocal(.roundPrepare(.buzz))
    }

    func armBuzzer() {
        guard !isOnlineMode else { return }
        sendLocal(.armBuzz)
    }

    func pressBuzzer() {
        guard buzzerState == .armed else { return }

        guard isOnlineMode else {
            buzzerState = .pressed
            sendLocal(.pressBuzz)
            return
        }

        buzzerState = .pressed
        guard let currentRoundID else { return }
        Task {
            await sendWebSocket(.buzz(roundID: currentRoundID))
        }
    }

    func simulateConnectionDrop() {
        guard isOnlineMode else {
            sendLocal(.disconnect)
            return
        }

        backendWebSocket?.disconnect()
        listenTask?.cancel()
        connectionState = .reconnecting
    }

    func reconnect() {
        guard isOnlineMode else {
            sendLocal(.reconnect)
            return
        }

        Task {
            await reconnectOnline()
        }
    }

    func resumePreviousSessionIfPossible() {
        guard isOnlineMode, localSessionID == nil else { return }
        guard case .home = phase else { return }
        guard let sessionID = UserDefaults.standard.string(forKey: DefaultsKey.playerSessionID) else { return }
        localSessionID = sessionID
        Task {
            await reconnectOnline()
        }
    }

    func showScoreboard() {
        phase = .scoreboard
    }

    func showPodium() {
        phase = .podium
    }

    func showGameSummary() {
        phase = .gameSummary
    }

    func advanceAfterResultNow() {
        guard !didRequestNextRound else { return }
        didRequestNextRound = true

        Task {
            await sendWebSocket(.nextRound(roundID: currentRoundID))
        }
    }

    func rematch() {
        if isOnlineMode {
            isWaitingForRematch = true
            connectionMessage = "Czekamy na reset pokoju..."
            Task {
                await sendWebSocket(.rematch())
            }
            return
        }

        players = players.map { player in
            var updated = player
            updated.score = 0
            updated.isReady = player.isHost
            return updated
        }
        selectedAnswerID = nil
        selectedTruthAnswer = nil
        selectedWager = 250
        buzzerState = .waiting
        phase = .lobby
    }

    private func applyOnlineRematch(_ state: BZZTBackendPublicState) {
        applyPublicState(state)
        deferredRoundTransitionTask?.cancel()
        deferredRoundTransitionTask = nil
        audioPlayer?.pause()
        audioPlayer = nil
        selectedAnswerID = nil
        selectedTruthAnswer = nil
        selectedWager = 250
        buzzerState = .waiting
        currentRoundID = nil
        currentQuestionType = nil
        pendingBuzzAnswerID = nil
        resultVisibleUntil = nil
        resultAdvanceDeadline = nil
        didRequestNextRound = false
        nextRoundReadySessionIDs = []
        nextRoundWaitingSessionIDs = []
        pendingRoundTransition = nil
        isWaitingForRematch = false
        connectionMessage = "Rewanż gotowy. Ten sam pokój i kod."
        phase = .lobby
    }

    func goHome() {
        listenTask?.cancel()
        deferredRoundTransitionTask?.cancel()
        backendWebSocket?.disconnect()
        backendWebSocket = nil
        audioPlayer?.pause()
        audioPlayer = nil
        phase = .home
        room = nil
        players = []
        selectedAnswerID = nil
        selectedTruthAnswer = nil
        selectedWager = 250
        joinCode = ""
        connectionMessage = nil
        connectionState = .offline
        localSessionID = nil
        UserDefaults.standard.removeObject(forKey: DefaultsKey.playerSessionID)
        backendSessionIDsByPlayerID = [:]
        currentRoundID = nil
        currentQuestionType = nil
        resultVisibleUntil = nil
        resultAdvanceDeadline = nil
        didRequestNextRound = false
        nextRoundReadySessionIDs = []
        nextRoundWaitingSessionIDs = []
        pendingRoundTransition = nil
        isWaitingForRematch = false
        backendRoundCount = 6
        isHost = false
    }

    private func createOnlineRoom() async {
        connectionState = .connecting
        connectionMessage = nil

        do {
            let response = try await backendAPI.createRoom(
                nickname: localPlayerName,
                avatar: localAvatar,
                roundCount: roomSettings.roundCount,
                gameMode: roomSettings.mode
            )
            applySession(response)
            try await connectWebSocket(roomCode: response.roomCode, sessionID: response.playerSessionID)
            phase = .lobby
        } catch {
            handleOnlineError(error)
        }
    }

    private func joinOnlineRoom() async {
        connectionState = .connecting
        connectionMessage = nil

        do {
            let response = try await backendAPI.joinRoom(code: joinCode, nickname: localPlayerName, avatar: localAvatar)
            applySession(response)
            try await connectWebSocket(roomCode: response.roomCode, sessionID: response.playerSessionID)
            phase = .lobby
        } catch {
            handleOnlineError(error)
        }
    }

    private func reconnectOnline() async {
        guard let sessionID = localSessionID else {
            connectionMessage = "Brak zapisanej sesji gracza."
            return
        }

        connectionState = .reconnecting
        connectionMessage = nil

        do {
            let session = try await backendAPI.lookupSession(sessionID)
            try await connectWebSocket(roomCode: session.roomCode, sessionID: sessionID)
        } catch {
            handleOnlineError(error)
        }
    }

    private func applySession(_ response: BZZTRoomSessionResponse) {
        localSessionID = response.playerSessionID
        isHost = response.isHost
        room = BZZTRoom(code: response.roomCode, title: "BZZT! PARTY", settings: roomSettings)
        saveProfileDefaults()
        UserDefaults.standard.set(response.playerSessionID, forKey: DefaultsKey.playerSessionID)
    }

    private func connectWebSocket(roomCode: String, sessionID: String) async throws {
        listenTask?.cancel()
        backendWebSocket?.disconnect()

        let url = backendAPI.configuration.webSocketURL(roomCode: roomCode, sessionID: sessionID)
        let socket = BZZTBackendWebSocket(url: url)
        backendWebSocket = socket
        socket.connect()
        connectionState = .connected
        connectionMessage = nil

        listenTask = Task { [weak self, socket] in
            while !Task.isCancelled {
                do {
                    let message = try await socket.receive()
                    self?.applyBackendMessage(message)
                } catch {
                    self?.handleWebSocketDisconnect(error)
                    break
                }
            }
        }
    }

    private func sendWebSocket(_ message: BZZTBackendOutgoingMessage) async {
        do {
            try await backendWebSocket?.send(message)
        } catch {
            handleWebSocketDisconnect(error)
        }
    }

    private func applyBackendMessage(_ message: BZZTBackendIncomingMessage) {
        switch message {
        case .reconnect(let state), .roomUpdated(let state), .gameStart(let state):
            applyPublicState(state)
            if case .gameStart = message {
                phase = .countdown(3)
            }

        case .roundPrepare:
            showAfterResultMinimum {
                self.phase = .roundIntro
            }

        case .roundStart(let payload):
            showAfterResultMinimum {
                self.applyRoundStart(payload)
            }

        case .answerLocked:
            break

        case .roundEnd(let payload):
            let result = resultFromRoundEnd(payload)
            let deadline = Date().addingTimeInterval(resultDisplayDuration)
            resultVisibleUntil = deadline
            resultAdvanceDeadline = deadline
            didRequestNextRound = false
            nextRoundReadySessionIDs = []
            nextRoundWaitingSessionIDs = []
            playAudio(from: currentQuestion.explanationAudioURL)
            phase = .roundResult(result)

        case .scoreUpdate(let scores):
            applyScores(scores)

        case .leaderChanged:
            break

        case .buzzAccepted(_, let sessionID):
            buzzerState = sessionID == localSessionID ? .won : .lost
            if sessionID == localSessionID {
                submitPendingBuzzAnswer()
            } else {
                pendingBuzzAnswerID = nil
            }

        case .buzzRejected:
            buzzerState = .lost
            pendingBuzzAnswerID = nil

        case .nextRoundStatus(let payload):
            applyNextRoundStatus(payload)

        case .rematchStarted(let state):
            applyOnlineRematch(state)

        case .gameEnd(let payload):
            showAfterResultMinimum {
                self.players = payload.ranking.map(\.bzztPlayer)
                self.phase = .podium
            }

        case .error(let message):
            connectionMessage = message

        case .unknown:
            break
        }
    }

    private func applyPublicState(_ state: BZZTBackendPublicState) {
        room = state.room
        backendRoundCount = state.roundCount
        players = state.bzztPlayers
        backendSessionIDsByPlayerID = Dictionary(uniqueKeysWithValues: zip(players.map(\.id), state.players.map(\.sessionID)))
        connectionState = .connected
        connectionMessage = nil

        switch state.phase {
        case "lobby":
            phase = .lobby
        case "scoreboard":
            phase = .scoreboard
        case "podium":
            phase = .podium
        case "gameSummary":
            phase = .gameSummary
        default:
            break
        }
    }

    private func applyRoundStart(_ payload: BZZTBackendRoundStartPayload) {
        currentRoundID = payload.roundID
        currentQuestionType = payload.questionType
        pendingBuzzAnswerID = nil
        selectedAnswerID = nil
        buzzerState = .disabled
        resultVisibleUntil = nil
        resultAdvanceDeadline = nil
        didRequestNextRound = false
        nextRoundReadySessionIDs = []
        nextRoundWaitingSessionIDs = []
        pendingRoundTransition = nil
        currentQuestion = payload.question.bzztQuestion(index: payload.roundIndex + 1, total: backendRoundCount, baseURL: backendAPI.configuration.baseURL)
        phase = .question
        playAudio(from: currentQuestion.audioURL)
    }

    private func showAfterResultMinimum(_ action: @escaping @MainActor () -> Void) {
        deferredRoundTransitionTask?.cancel()

        guard let resultVisibleUntil else {
            pendingRoundTransition = nil
            action()
            return
        }

        pendingRoundTransition = action
        let delay = resultVisibleUntil.timeIntervalSinceNow
        guard delay > 0 else {
            self.resultVisibleUntil = nil
            resultAdvanceDeadline = nil
            pendingRoundTransition = nil
            action()
            return
        }

        deferredRoundTransitionTask = Task { @MainActor [weak self] in
            let nanoseconds = UInt64(delay * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled else { return }
            self?.resultVisibleUntil = nil
            self?.resultAdvanceDeadline = nil
            let transition = self?.pendingRoundTransition
            self?.pendingRoundTransition = nil
            transition?()
        }
    }

    private func applyNextRoundStatus(_ payload: BZZTBackendNextRoundStatusPayload) {
        guard payload.roundID == currentRoundID else { return }
        nextRoundReadySessionIDs = Set(payload.ready)
        nextRoundWaitingSessionIDs = Set(payload.waitingFor)
        didRequestNextRound = localSessionID.map { nextRoundReadySessionIDs.contains($0) } ?? didRequestNextRound

        guard payload.ready.isEmpty == false, payload.waitingFor.isEmpty else { return }

        resultVisibleUntil = nil
        resultAdvanceDeadline = nil
        deferredRoundTransitionTask?.cancel()
        deferredRoundTransitionTask = nil

        guard let pendingRoundTransition else { return }
        self.pendingRoundTransition = nil
        pendingRoundTransition()
    }

    private func submitPendingBuzzAnswer() {
        guard let currentRoundID, let pendingBuzzAnswerID else { return }
        self.pendingBuzzAnswerID = nil
        Task {
            await sendWebSocket(.submitAnswer(roundID: currentRoundID, answerID: pendingBuzzAnswerID))
        }
    }

    private func playAudio(from url: URL?) {
        guard let url else { return }
        audioPlayer?.pause()
        let player = AVPlayer(url: url)
        player.volume = Float(effectsVolume)
        audioPlayer = player
        player.play()
    }

    private func applyScores(_ scores: [String: Int]) {
        players = players.map { player in
            var updated = player
            if let sessionID = backendSessionIDsByPlayerID[player.id], let score = scores[sessionID] {
                updated.score = score
            }
            return updated
        }
    }

    private func resultFromRoundEnd(_ payload: BZZTBackendRoundEndPayload) -> BZZTRoundResult {
        let correctText: String
        if let option = currentQuestion.options.first(where: { $0.id == payload.correctAnswerID }) {
            correctText = "\(option.letter) — \(option.text)"
        } else {
            correctText = "-"
        }

        let localSubmission = localSessionID.flatMap { payload.results[$0] }
        if selectedAnswerID == nil {
            selectedAnswerID = localSubmission?.answerID
        }
        let wasCorrect = selectedAnswerID == payload.correctAnswerID || (localSubmission?.isCorrect ?? false)
        let points = localSubmission?.points ?? 0

        currentQuestion = BZZTQuestion(
            id: currentQuestion.id,
            index: currentQuestion.index,
            total: currentQuestion.total,
            category: currentQuestion.category,
            text: currentQuestion.text,
            options: currentQuestion.options,
            correctAnswerID: payload.correctAnswerID,
            timeLimit: currentQuestion.timeLimit,
            explanation: payload.explanation ?? "",
            audioURL: currentQuestion.audioURL,
            explanationAudioURL: absoluteURL(from: payload.explanationAudioURLPath, baseURL: backendAPI.configuration.baseURL)
        )

        return BZZTRoundResult(
            isCorrect: wasCorrect,
            points: points,
            correctAnswer: correctText,
            explanation: payload.explanation ?? "Wynik i punkty liczy backend."
        )
    }

    private func handleOnlineError(_ error: Error) {
        connectionState = .failed(error.localizedDescription)
        connectionMessage = error.localizedDescription
    }

    private func handleWebSocketDisconnect(_ error: Error) {
        guard connectionState != .offline else { return }
        connectionState = .reconnecting
        connectionMessage = "WebSocket: \(error.localizedDescription)"
    }

    private func markLocalReadyInMock() {
        guard let index = players.firstIndex(where: { !$0.isHost && $0.name.caseInsensitiveCompare(localPlayerName) == .orderedSame }) else {
            if let firstNonHost = players.firstIndex(where: { !$0.isHost }) {
                sendLocal(.setReady(playerID: players[firstNonHost].id))
            }
            return
        }
        sendLocal(.setReady(playerID: players[index].id))
    }

    private func sendLocal(_ command: BZZTClientCommand) {
        let events = localClient.send(command, state: snapshot)
        events.forEach(applyLocal)
    }

    private var snapshot: BZZTGameSnapshot {
        BZZTGameSnapshot(
            roomSettings: roomSettings,
            room: room,
            players: players,
            currentQuestion: currentQuestion,
            trueFalsePrompt: trueFalsePrompt,
            riskPrompt: riskPrompt
        )
    }

    private func applyLocal(_ event: BZZTGameEvent) {
        switch event {
        case .connectionChanged(let state):
            connectionState = state
            if state == .connected {
                connectionMessage = nil
            }

        case .roomCreated(let room, let players):
            self.room = room
            self.players = players
            connectionMessage = nil
            phase = .lobby

        case .roomJoined(let room, let players):
            self.room = room
            self.players = players
            connectionMessage = nil
            phase = .profile

        case .profileUpdated(let name, let avatar):
            localPlayerName = name
            localAvatar = avatar
            if let index = players.firstIndex(where: { !$0.isHost && $0.avatar == avatar }) {
                players[index].name = name
            }
            connectionMessage = nil
            phase = .lobby

        case .playerReadyChanged(let playerID):
            guard let index = players.firstIndex(where: { $0.id == playerID }), !players[index].isHost else { return }
            players[index].isReady.toggle()

        case .gameStarted:
            phase = .countdown(3)

        case .roundPrepared(let nextPhase):
            prepareLocalRound(for: nextPhase)
            phase = nextPhase

        case .answerLocked(let answerID, let result):
            selectedAnswerID = answerID
            applyScoreDelta(result.points)
            phase = .roundResult(result)

        case .trueFalseLocked(let answer, let result):
            selectedTruthAnswer = answer
            applyScoreDelta(result.points)
            phase = .roundResult(result)

        case .riskLocked(let answerID, let result):
            selectedAnswerID = answerID
            applyScoreDelta(result.points)
            phase = .roundResult(result)

        case .buzzArmed:
            buzzerState = .armed

        case .buzzAccepted(let points):
            buzzerState = .won
            applyScoreDelta(points)

        case .reconnectRestored:
            connectionMessage = "Połączono ponownie."

        case .error(let message):
            connectionState = .failed(message)
            connectionMessage = message
        }
    }

    private func prepareLocalRound(for phase: BZZTGamePhase) {
        switch phase {
        case .question:
            selectedAnswerID = nil
            currentQuestion = .sample
        case .trueFalse:
            selectedTruthAnswer = nil
        case .risk:
            selectedAnswerID = nil
            selectedWager = 250
            currentQuestion = riskPrompt.question
        case .buzz:
            buzzerState = .waiting
        default:
            break
        }
    }

    private func applyScoreDelta(_ points: Int) {
        guard let hostIndex = players.firstIndex(where: { $0.isHost }) else { return }
        players[hostIndex].score += points
    }

    private func saveProfileDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(localPlayerName, forKey: DefaultsKey.playerName)
        defaults.set(localAvatar, forKey: DefaultsKey.playerAvatar)
    }

    private static func makeBackendAPI(from string: String) -> BZZTBackendAPI {
        let fallbackURL = URL(string: "https://bzzt.e-aw.pl")!
        let url = URL(string: string.trimmingCharacters(in: .whitespacesAndNewlines)) ?? fallbackURL
        return BZZTBackendAPI(configuration: BZZTBackendConfiguration(baseURL: url))
    }

    private enum DefaultsKey {
        static let playerName = "bzzt.player.name"
        static let playerAvatar = "bzzt.player.avatar"
        static let playerSessionID = "bzzt.player.sessionID"
        static let backendBaseURL = "bzzt.backend.baseURL"
        static let hostVoiceEnabled = "bzzt.settings.hostVoiceEnabled"
        static let hapticsEnabled = "bzzt.settings.hapticsEnabled"
        static let musicVolume = "bzzt.settings.musicVolume"
        static let effectsVolume = "bzzt.settings.effectsVolume"
    }
}
