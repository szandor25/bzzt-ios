import SwiftUI

struct ContentView: View {
    @State private var store = BZZTGameStore()

    var body: some View {
        ZStack {
            BZZTScreenBackground()

            activeScreen

            if let bannerText = store.connectionBannerText {
                VStack {
                    BZZTConnectionBanner(message: bannerText) {
                        store.reconnect()
                    }
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: store.connectionBannerText)
        .task {
            store.resumePreviousSessionIfPossible()
        }
    }

    @ViewBuilder
    private var activeScreen: some View {
        switch store.phase {
        case .home:
            HomeView(store: store)
        case .createRoom:
            CreateRoomView(store: store)
        case .joinRoom:
            JoinRoomView(store: store)
        case .profile:
            ProfileView(store: store)
        case .playerProfile:
            PlayerProfileSettingsView(store: store)
        case .settings:
            AppSettingsView(store: store)
        case .lobby:
            LobbyView(store: store)
        case .countdown(let value):
            CountdownView(value: value) {
                store.advanceCountdown(from: value)
            }
        case .roundIntro:
            RoundIntroView(store: store)
        case .question:
            QuestionView(store: store)
        case .trueFalse:
            TrueFalseRoundView(store: store)
        case .risk:
            RiskRoundView(store: store)
        case .leaderHunt:
            LeaderHuntRoundView(store: store)
        case .finalLadder:
            FinalLadderRoundView(store: store)
        case .buzz:
            BuzzRoundView(store: store)
        case .roundResult(let result):
            RoundResultView(result: result, store: store)
        case .scoreboard:
            ScoreboardView(store: store)
        case .podium:
            PodiumView(store: store)
        case .gameSummary:
            GameSummaryView(store: store)
        }
    }
}

#Preview {
    ContentView()
}
