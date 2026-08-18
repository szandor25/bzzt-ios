import SwiftUI

enum BZZTGamePhase {
    case home
    case createRoom
    case joinRoom
    case profile
    case playerProfile
    case settings
    case lobby
    case countdown(Int)
    case roundIntro
    case question
    case trueFalse
    case risk
    case buzz
    case roundResult(BZZTRoundResult)
    case scoreboard
    case podium
    case gameSummary
}

enum BZZTGameMode: String, CaseIterable, Identifiable {
    case party = "Party"
    case classic = "Klasyczny"
    case quick = "Szybki"

    var id: String { rawValue }

    var backendValue: String {
        switch self {
        case .party:
            "party"
        case .classic:
            "classic"
        case .quick:
            "quick"
        }
    }

    var subtitle: String {
        switch self {
        case .party:
            "Flagowy tryb BZZT! z mieszanką rund, power-upów i finałem."
        case .classic:
            "Spokojniejszy quiz z większym naciskiem na wiedzę i uczciwą punktację."
        case .quick:
            "Krótka, intensywna partia z małą liczbą przerw i szybkim tempem."
        }
    }

    var details: String {
        switch self {
        case .party:
            "Gra miesza różne rundy: ABCD, prawda/fałsz, audio, obrazki, ryzyko, power-upy, polowanie na lidera i finał. Najlepszy wybór dla kilku osób przy wspólnej zabawie."
        case .classic:
            "Głównie pytania wiedzy, mniej losowych mechanik i mniej power-upów. Dobry wybór do rodzinnego grania albo bardziej poważnego quizu."
        case .quick:
            "Mało przerw, krótkie timery i dużo pytań pod rząd. Idealny wybór, gdy chcecie zagrać jedną szybką partię."
        }
    }

    var recommendedRoundCount: Int {
        switch self {
        case .party:
            10
        case .classic:
            8
        case .quick:
            5
        }
    }

    var systemImage: String {
        switch self {
        case .party:
            "sparkles"
        case .classic:
            "graduationcap.fill"
        case .quick:
            "timer"
        }
    }
}

enum BZZTGameLength: String, CaseIterable, Identifiable {
    case twenty = "20 min"
    case thirty = "30 min"
    case unlimited = "Bez limitu"

    var id: String { rawValue }
}

enum BZZTDifficulty: String, CaseIterable, Identifiable {
    case family = "Rodzinny"
    case normal = "Normalny"
    case hard = "Trudny"

    var id: String { rawValue }
}

struct BZZTRoomSettings {
    var mode: BZZTGameMode = .party
    var length: BZZTGameLength = .twenty
    var difficulty: BZZTDifficulty = .family
    var roundCount: Int = 6
}

struct BZZTRoom {
    let code: String
    let title: String
    var settings: BZZTRoomSettings
    var maxPlayers: Int = 8
}

struct BZZTPlayer: Identifiable, Equatable {
    let id: UUID
    var name: String
    var avatar: String
    var score: Int
    var isHost: Bool
    var isReady: Bool

    init(id: UUID = UUID(), name: String, avatar: String, score: Int = 0, isHost: Bool = false, isReady: Bool = false) {
        self.id = id
        self.name = name
        self.avatar = avatar
        self.score = score
        self.isHost = isHost
        self.isReady = isReady
    }
}

struct BZZTQuestion {
    let id: String
    let index: Int
    let total: Int
    let category: String
    let text: String
    let options: [BZZTAnswerOption]
    let correctAnswerID: BZZTAnswerOption.ID?
    let timeLimit: Int
    let explanation: String
    let audioURL: URL?
    let explanationAudioURL: URL?

    init(
        id: String,
        index: Int,
        total: Int,
        category: String,
        text: String,
        options: [BZZTAnswerOption],
        correctAnswerID: BZZTAnswerOption.ID?,
        timeLimit: Int,
        explanation: String,
        audioURL: URL? = nil,
        explanationAudioURL: URL? = nil
    ) {
        self.id = id
        self.index = index
        self.total = total
        self.category = category
        self.text = text
        self.options = options
        self.correctAnswerID = correctAnswerID
        self.timeLimit = timeLimit
        self.explanation = explanation
        self.audioURL = audioURL
        self.explanationAudioURL = explanationAudioURL
    }
}

struct BZZTAnswerOption: Identifiable, Equatable {
    let id: String
    let letter: String
    let text: String
    let color: Color
}

struct BZZTTrueFalsePrompt {
    let statement: String
    let correctAnswer: Bool
    let explanation: String
}

struct BZZTRiskPrompt {
    let question: BZZTQuestion
    let wagers: [Int]
}

enum BZZTAnswerState: Equatable {
    case idle
    case submitted
    case correct
    case incorrect
    case disabled
}

enum BZZTBuzzerState: Equatable {
    case disabled
    case waiting
    case armed
    case pressed
    case won
    case lost

    var title: String {
        switch self {
        case .disabled:
            "NIEAKTYWNY"
        case .waiting:
            "CZEKAJ..."
        case .armed:
            "BZZT!"
        case .pressed:
            "WYSŁANO"
        case .won:
            "PIERWSZY!"
        case .lost:
            "OLA BYŁA SZYBSZA"
        }
    }
}

struct BZZTRoundResult: Equatable {
    let isCorrect: Bool
    let points: Int
    let correctAnswer: String
    let explanation: String
}

extension BZZTQuestion {
    static let sample = BZZTQuestion(
        id: "local_jupiter",
        index: 3,
        total: 10,
        category: "Nauka",
        text: "Która planeta jest największa w Układzie Słonecznym?",
        options: [
            BZZTAnswerOption(id: "local_jupiter_a", letter: "A", text: "Mars", color: Color(red: 1.0, green: 0.302, blue: 0.369)),
            BZZTAnswerOption(id: "local_jupiter_b", letter: "B", text: "Jowisz", color: Color(red: 0.239, green: 0.482, blue: 1.0)),
            BZZTAnswerOption(id: "local_jupiter_c", letter: "C", text: "Wenus", color: Color(red: 1.0, green: 0.788, blue: 0.239)),
            BZZTAnswerOption(id: "local_jupiter_d", letter: "D", text: "Saturn", color: Color(red: 0.196, green: 0.835, blue: 0.514))
        ],
        correctAnswerID: "local_jupiter_b",
        timeLimit: 8,
        explanation: "Jowisz jest największą planetą Układu Słonecznego."
    )

    static let riskSample = BZZTQuestion(
        id: "local_canberra",
        index: 7,
        total: 10,
        category: "Geografia",
        text: "Jaka jest stolica Australii?",
        options: [
            BZZTAnswerOption(id: "local_canberra_a", letter: "A", text: "Sydney", color: Color(red: 1.0, green: 0.302, blue: 0.369)),
            BZZTAnswerOption(id: "local_canberra_b", letter: "B", text: "Melbourne", color: Color(red: 0.239, green: 0.482, blue: 1.0)),
            BZZTAnswerOption(id: "local_canberra_c", letter: "C", text: "Canberra", color: Color(red: 1.0, green: 0.788, blue: 0.239)),
            BZZTAnswerOption(id: "local_canberra_d", letter: "D", text: "Perth", color: Color(red: 0.196, green: 0.835, blue: 0.514))
        ],
        correctAnswerID: "local_canberra_c",
        timeLimit: 10,
        explanation: "Canberra jest stolicą Australii, choć Sydney jest większym miastem."
    )
}

extension BZZTTrueFalsePrompt {
    static let sample = BZZTTrueFalsePrompt(
        statement: "Wenus obraca się wokół własnej osi w przeciwnym kierunku niż większość planet Układu Słonecznego.",
        correctAnswer: true,
        explanation: "Wenus ma rotację wsteczną, dlatego słońce wschodziłoby tam na zachodzie."
    )
}

extension BZZTRiskPrompt {
    static let sample = BZZTRiskPrompt(
        question: .riskSample,
        wagers: [100, 250, 500, 1000]
    )
}
