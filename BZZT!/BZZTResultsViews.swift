import SwiftUI

struct RoundResultView: View {
    let result: BZZTRoundResult
    let store: BZZTGameStore

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Spacer(minLength: 18)

            Image(systemName: result.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 76, weight: .bold))
                .foregroundStyle(result.isCorrect ? Color.bzztSuccess : Color.bzztError)

            Text(result.isCorrect ? "DOBRZE!" : "NIE TYM RAZEM")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(Color.bzztTextPrimary)
                .multilineTextAlignment(.center)

            Text(pointsText)
                .font(.system(size: 48, weight: .heavy, design: .rounded))
                .foregroundStyle(result.points >= 0 ? Color.bzztElectric : Color.bzztError)

                BZZTPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("POPRAWNA ODPOWIEDŹ")
                            .font(.caption.weight(.black))
                            .foregroundStyle(Color.bzztTextSecondary)

                        Text(result.correctAnswer)
                            .font(.title3.weight(.black))
                            .foregroundStyle(Color.bzztTextPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Divider()
                            .overlay(Color.bzztDivider)

                        Text("WYJAŚNIENIE")
                            .font(.caption.weight(.black))
                            .foregroundStyle(Color.bzztTextSecondary)

                        Text(result.explanation)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.bzztTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
            }

                if store.isOnlineMode {
                    VStack(spacing: 12) {
                        BZZTPrimaryButton(title: store.didRequestNextRound ? "CZEKAMY NA RESZTĘ" : "GOTOWY NA KOLEJNE", systemImage: store.didRequestNextRound ? "checkmark.circle.fill" : "forward.fill") {
                            store.advanceAfterResultNow()
                        }
                        .disabled(store.didRequestNextRound)
                        .opacity(store.didRequestNextRound ? 0.72 : 1)

                        ResultAutoAdvanceView(
                            deadline: store.resultAdvanceDeadline,
                            didRequestNextRound: store.didRequestNextRound,
                            readyCount: store.nextRoundReadyCount,
                            waitingNames: store.nextRoundWaitingNames
                        )
                    }
                } else {
                    HStack(spacing: 12) {
                        BZZTSecondaryButton(title: "RUNDA", systemImage: "square.grid.2x2") {
                            store.phase = .roundIntro
                        }
                        BZZTPrimaryButton(title: "RANKING", systemImage: "list.number") {
                            store.showScoreboard()
                        }
                    }
                }

                Spacer(minLength: 18)
            }
            .padding(24)
        }
    }

    private var pointsText: String {
        if result.points > 0 {
            return "+\(result.points) pkt"
        }
        if result.points < 0 {
            return "\(result.points) pkt"
        }
        return "+0 pkt"
    }
}

private struct ResultAutoAdvanceView: View {
    let deadline: Date?
    let didRequestNextRound: Bool
    let readyCount: Int
    let waitingNames: [String]

    var body: some View {
        BZZTPanel {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                HStack(spacing: 14) {
                    ProgressView()
                        .tint(Color.bzztElectric)

                    Text(text(at: context.date))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.bzztTextPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)

                    Spacer()
                }
            }
        }
    }

    private func text(at date: Date) -> String {
        guard let deadline else {
            return "Czekamy na następną rundę..."
        }

        let remaining = max(0, Int(ceil(deadline.timeIntervalSince(date))))
        if didRequestNextRound {
            if waitingNames.isEmpty {
                return readyCount > 0 ? "Wszyscy gotowi. Start za chwilę." : "Twoja gotowość wysłana. Automatycznie najpóźniej za \(remaining) s"
            }
            return "Gotowi: \(readyCount). Czekamy na: \(waitingNames.joined(separator: ", ")). Limit: \(remaining) s"
        }
        return "Automatycznie za \(remaining) s"
    }
}

struct ScoreboardView: View {
    let store: BZZTGameStore

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HeaderView(title: "RANKING", subtitle: "Ranking pokazujemy po rundzie, nie po każdym dotknięciu.", backAction: { store.phase = .roundIntro })

            BZZTPanel {
                ForEach(Array(store.sortedPlayers.enumerated()), id: \.element.id) { index, player in
                    HStack(spacing: 14) {
                        Text("\(index + 1).")
                            .font(.system(.title3, design: .rounded, weight: .black))
                            .foregroundStyle(index == 0 ? Color.bzztElectric : Color.bzztTextSecondary)
                            .frame(width: 34, alignment: .leading)
                        BZZTPlayerChip(player: player)
                    }
                }
            }

            Spacer()

            VStack(spacing: 12) {
                BZZTPrimaryButton(title: "KOLEJNA RUNDA", systemImage: "forward.fill") {
                    store.phase = .roundIntro
                }

                HStack(spacing: 12) {
                    BZZTSecondaryButton(title: "PODIUM", systemImage: "trophy.fill") {
                        store.showPodium()
                    }
                    BZZTSecondaryButton(title: "SUMMARY", systemImage: "chart.bar") {
                        store.showGameSummary()
                    }
                }
            }
        }
        .padding(24)
    }
}

struct PodiumView: View {
    let store: BZZTGameStore

    var body: some View {
        VStack(spacing: 22) {
            HeaderView(title: "PODIUM", subtitle: "Końcówka partii: zwycięzca, rewanż albo podsumowanie.", backAction: store.showScoreboard)

            Spacer(minLength: 8)

            let winners = store.sortedPlayers.prefix(3)
            ForEach(Array(winners.enumerated()), id: \.element.id) { index, player in
                VStack(spacing: 8) {
                    Text(["🥇", "🥈", "🥉"][index])
                        .font(.system(size: index == 0 ? 62 : 46))
                    Text(player.name.uppercased())
                        .font(.system(size: index == 0 ? 34 : 25, weight: .black, design: .rounded))
                        .foregroundStyle(index == 0 ? Color.bzztElectric : Color.bzztTextPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("\(player.score) pkt")
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(Color.bzztTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(18)
                .background(Color.bzztBackgroundSecondary.opacity(index == 0 ? 0.95 : 0.65))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }

            Spacer(minLength: 8)

            HStack(spacing: 12) {
                BZZTSecondaryButton(title: "HOME", systemImage: "house") {
                    store.goHome()
                }
                BZZTPrimaryButton(title: "REWANŻ", systemImage: "arrow.clockwise") {
                    store.rematch()
                }
                .disabled(store.isWaitingForRematch)
                .opacity(store.isWaitingForRematch ? 0.72 : 1)
            }
        }
        .padding(24)
    }
}

struct GameSummaryView: View {
    let store: BZZTGameStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HeaderView(title: "WYNIKI", subtitle: "Pierwsze lokalne podsumowanie. Statystyki będą później liczone z historii rund.", backAction: store.showScoreboard)

                BZZTPanel {
                    ForEach(Array(store.sortedPlayers.enumerated()), id: \.element.id) { index, player in
                        HStack(spacing: 12) {
                            Text(medal(for: index))
                                .font(.system(size: 28))
                                .frame(width: 38)
                            Text(player.name)
                                .font(.headline.weight(.black))
                                .foregroundStyle(Color.bzztTextPrimary)
                            Spacer()
                            Text("\(player.score)")
                                .font(.system(.title3, design: .rounded, weight: .heavy))
                                .foregroundStyle(index == 0 ? Color.bzztElectric : Color.bzztTextPrimary)
                        }
                        .padding(.vertical, 6)
                    }
                }

                BZZTPanel {
                    Text("TWOJE STATYSTYKI")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.bzztTextSecondary)
                    SummaryMetric(title: "Poprawne", value: "2/3")
                    SummaryMetric(title: "Najszybsza akcja", value: "BUZZ")
                    SummaryMetric(title: "Najlepsza runda", value: "Risk")
                    SummaryMetric(title: "Wynik", value: "\(store.localPlayerScore) pkt")
                }

                HStack(spacing: 12) {
                    BZZTSecondaryButton(title: "HOME", systemImage: "house") {
                        store.goHome()
                    }
                    BZZTPrimaryButton(title: "REWANŻ", systemImage: "arrow.clockwise") {
                        store.rematch()
                    }
                }
            }
            .padding(24)
        }
    }

    private func medal(for index: Int) -> String {
        switch index {
        case 0: "🥇"
        case 1: "🥈"
        case 2: "🥉"
        default: "\(index + 1)."
        }
    }
}

private struct SummaryMetric: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.bzztTextSecondary)
            Spacer()
            Text(value)
                .font(.body.weight(.black))
                .foregroundStyle(Color.bzztTextPrimary)
        }
    }
}
