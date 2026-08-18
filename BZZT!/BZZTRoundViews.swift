import SwiftUI

struct CountdownView: View {
    let value: Int
    let advance: () -> Void

    var body: some View {
        VStack(spacing: 34) {
            Spacer()
            Text("\(value)")
                .font(.system(size: 118, weight: .black, design: .rounded))
                .foregroundStyle(Color.bzztElectric)
                .contentTransition(.numericText())
            Text("START ZA CHWILĘ")
                .font(.headline.weight(.black))
                .foregroundStyle(Color.bzztTextSecondary)
            Spacer()
            BZZTPrimaryButton(title: value == 1 ? "BZZT!" : "DALEJ", systemImage: "bolt.fill", action: advance)
        }
        .padding(24)
    }
}

struct RoundIntroView: View {
    let store: BZZTGameStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HeaderView(title: "PRZYGOTOWANIE RUNDY", subtitle: "Czekamy na kolejne pytanie.", backAction: store.goHome)

                BZZTPanel {
                    HStack(spacing: 14) {
                        ProgressView()
                            .tint(Color.bzztElectric)
                        Text("Czekamy na serwer...")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.bzztTextPrimary)
                    }
                }
            }
            .padding(24)
        }
    }
}

struct QuestionView: View {
    let store: BZZTGameStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                QuestionHeader(question: store.currentQuestion)

                Text(store.currentQuestion.text)
                    .font(.system(size: 31, weight: .black, design: .rounded))
                    .foregroundStyle(Color.bzztTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                PowerUpStrip(store: store)

                VStack(spacing: 12) {
                    ForEach(store.visibleOptions(for: store.currentQuestion)) { option in
                        BZZTAnswerCard(option: option, state: store.state(for: option)) {
                            store.submitAnswer(option)
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}

struct TrueFalseRoundView: View {
    let store: BZZTGameStore

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HeaderView(title: "PRAWDA / FAŁSZ", subtitle: "Szybka seria krótkich stwierdzeń.", backAction: { store.phase = .roundIntro })

            Spacer()

            Text(store.isOnlineMode ? store.currentQuestion.text : store.trueFalsePrompt.statement)
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(Color.bzztTextPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            if store.isOnlineMode, store.currentQuestion.options.count >= 2 {
                HStack(spacing: 14) {
                    ForEach(store.currentQuestion.options.prefix(2)) { option in
                        TruthButton(
                            title: truthTitle(for: option),
                            systemImage: truthIcon(for: option),
                            color: truthColor(for: option),
                            isSelected: store.selectedAnswerID == option.id,
                            isDisabled: store.selectedAnswerID != nil && store.selectedAnswerID != option.id
                        ) {
                            store.submitTrueFalseOption(option)
                        }
                    }
                }
            } else {
                HStack(spacing: 14) {
                    TruthButton(
                        title: "FAŁSZ",
                        systemImage: "xmark",
                        color: Color.bzztError,
                        isSelected: store.selectedTruthAnswer == false,
                        isDisabled: store.selectedTruthAnswer != nil && store.selectedTruthAnswer != false
                    ) {
                        store.submitTrueFalseAnswer(false)
                    }
                    TruthButton(
                        title: "PRAWDA",
                        systemImage: "checkmark",
                        color: Color.bzztSuccess,
                        isSelected: store.selectedTruthAnswer == true,
                        isDisabled: store.selectedTruthAnswer != nil && store.selectedTruthAnswer != true
                    ) {
                        store.submitTrueFalseAnswer(true)
                    }
                }
            }
        }
        .padding(24)
    }

    private func truthTitle(for option: BZZTAnswerOption) -> String {
        let text = option.text.lowercased()
        if text.contains("false") || text.contains("fałsz") || text.contains("falsz") {
            return "FAŁSZ"
        }
        if text.contains("true") || text.contains("prawda") {
            return "PRAWDA"
        }
        return option.text.uppercased()
    }

    private func truthIcon(for option: BZZTAnswerOption) -> String {
        truthTitle(for: option) == "FAŁSZ" ? "xmark" : "checkmark"
    }

    private func truthColor(for option: BZZTAnswerOption) -> Color {
        truthTitle(for: option) == "FAŁSZ" ? Color.bzztError : Color.bzztSuccess
    }
}

struct RiskRoundView: View {
    let store: BZZTGameStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                if store.isRiskQuestionVisible {
                    HeaderView(title: "RYZYKO", subtitle: "Stawka: \(store.selectedWager) pkt", backAction: { store.phase = .roundIntro })

                    QuestionHeader(question: store.riskPrompt.question)

                    Text(store.riskPrompt.question.text)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(Color.bzztTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    PowerUpStrip(store: store)

                    VStack(spacing: 12) {
                        ForEach(store.visibleOptions(for: store.riskPrompt.question)) { option in
                            BZZTAnswerCard(option: option, state: store.state(for: option)) {
                                store.submitRiskAnswer(option)
                            }
                        }
                    }
                } else {
                    HeaderView(title: "RYZYKO", subtitle: "Najpierw zatwierdź stawkę. Pytanie pokaże się wszystkim naraz.", backAction: { store.phase = .roundIntro })

                    BZZTPanel {
                        Text("ILE STAWIASZ?")
                            .font(.caption.weight(.black))
                            .foregroundStyle(Color.bzztTextSecondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                            ForEach(store.riskPrompt.wagers, id: \.self) { wager in
                                WagerButton(amount: wager, isSelected: store.selectedWager == wager) {
                                    store.selectWager(wager)
                                }
                            }
                            WagerButton(amount: max(100, store.localPlayerScore), label: "ALL IN", isSelected: store.selectedWager == max(100, store.localPlayerScore)) {
                                store.selectWager(max(100, store.localPlayerScore))
                            }
                        }

                        BZZTPrimaryButton(title: store.isRiskWagerLocked ? "STAWKA ZATWIERDZONA" : "ZATWIERDŹ STAWKĘ", systemImage: store.isRiskWagerLocked ? "lock.fill" : "checkmark") {
                            store.confirmRiskWager()
                        }
                        .disabled(store.isRiskWagerLocked)
                        .opacity(store.isRiskWagerLocked ? 0.72 : 1)
                    }

                    BZZTPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            Label(
                                store.isRiskWagerLocked ? "Stawka zapisana. Czekamy na resztę graczy." : "Pytanie jest ukryte do momentu obstawienia wszystkich.",
                                systemImage: store.isRiskWagerLocked ? "lock.fill" : "eye.slash.fill"
                            )
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.bzztTextPrimary)

                            if store.isRiskWagerLocked {
                                Text(riskWaitingText)
                                    .font(.callout.weight(.semibold))
                                    .foregroundStyle(Color.bzztTextSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    private var riskWaitingText: String {
        if store.riskWagerWaitingNames.isEmpty {
            return store.riskWagerReadyCount > 0 ? "Wszyscy obstawili. Pytanie startuje za chwilę." : "Czekamy na status backendu."
        }
        return "Obstawili: \(store.riskWagerReadyCount). Czekamy na: \(store.riskWagerWaitingNames.joined(separator: ", "))."
    }
}

struct LeaderHuntRoundView: View {
    let store: BZZTGameStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HeaderView(title: "POLOWANIE NA LIDERA", subtitle: "\(store.leaderName) jest celem tej rundy.", backAction: { store.phase = .roundIntro })

                BZZTPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Pozostali gracze gonią lidera bonusami za poprawne odpowiedzi.", systemImage: "scope")
                        Label("Lider może obronić przewagę poprawną i szybką odpowiedzią.", systemImage: "shield.fill")
                    }
                    .font(.callout.weight(.bold))
                    .foregroundStyle(Color.bzztTextSecondary)
                }

                QuestionHeader(question: store.currentQuestion)

                Text(store.currentQuestion.text)
                    .font(.system(size: 29, weight: .black, design: .rounded))
                    .foregroundStyle(Color.bzztTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                PowerUpStrip(store: store)

                VStack(spacing: 12) {
                    ForEach(store.visibleOptions(for: store.currentQuestion)) { option in
                        BZZTAnswerCard(option: option, state: store.state(for: option)) {
                            store.submitAnswer(option)
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}

struct FinalLadderRoundView: View {
    let store: BZZTGameStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HeaderView(title: "FINAŁ DRABINA", subtitle: "Poprawna odpowiedź przesuwa po torze, najszybsza może dać większy skok.", backAction: { store.phase = .roundIntro })

                BZZTPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(store.sortedPlayers.enumerated()), id: \.element.id) { index, player in
                            FinalLadderRow(player: player, position: min(5, index + 1))
                        }
                    }
                }

                QuestionHeader(question: store.currentQuestion)

                Text(store.currentQuestion.text)
                    .font(.system(size: 29, weight: .black, design: .rounded))
                    .foregroundStyle(Color.bzztTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 12) {
                    ForEach(store.visibleOptions(for: store.currentQuestion)) { option in
                        BZZTAnswerCard(option: option, state: store.state(for: option)) {
                            store.submitAnswer(option)
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}

private struct PowerUpStrip: View {
    let store: BZZTGameStore

    var body: some View {
        if store.canUsePowerUps {
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        ForEach(BZZTPowerUp.allCases) { powerUp in
                            Button {
                                store.usePowerUp(powerUp)
                            } label: {
                                Label(powerUp.rawValue, systemImage: powerUp.systemImage)
                                    .font(.caption.weight(.black))
                                    .foregroundStyle(store.selectedPowerUp == powerUp ? Color.bzztBackgroundPrimary : Color.bzztTextPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(store.selectedPowerUp == powerUp ? Color.bzztElectric : Color.bzztSurfaceElevated)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .disabled(store.usedPowerUps.contains(powerUp))
                            .opacity(store.usedPowerUps.contains(powerUp) && store.selectedPowerUp != powerUp ? 0.45 : 1)
                        }
                    }

                    if let message = store.powerUpMessage {
                        Text(message)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.bzztElectric)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

private struct FinalLadderRow: View {
    let player: BZZTPlayer
    let position: Int

    var body: some View {
        HStack(spacing: 10) {
            Text(player.avatar)
                .font(.title2)
            Text(player.name)
                .font(.headline.weight(.black))
                .foregroundStyle(Color.bzztTextPrimary)
            Spacer()
            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { index in
                    Capsule()
                        .fill(index < position ? Color.bzztElectric : Color.bzztSurfaceElevated)
                        .frame(width: 18, height: 8)
                }
            }
        }
    }
}

struct BuzzRoundView: View {
    let store: BZZTGameStore

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HeaderView(title: "RUNDA BUZZ", subtitle: "Najpierw kliknij jako pierwszy. Jeśli backend zaakceptuje BUZZ, odpowiadasz na pytanie.", backAction: { store.phase = .roundIntro })

            if store.buzzerState == .won {
                QuestionHeader(question: store.currentQuestion)

                Text(store.currentQuestion.text)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(Color.bzztTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 12) {
                    ForEach(store.currentQuestion.options) { option in
                        BZZTAnswerCard(option: option, state: store.state(for: option)) {
                            store.submitAnswer(option)
                        }
                    }
                }

                Spacer()
            } else {
                Spacer()

                BZZTBuzzerButton(state: store.buzzerState) {
                    store.pressBuzzer()
                }

                Spacer()

                if store.buzzerState == .waiting && !store.isOnlineMode {
                    BZZTPrimaryButton(title: "UZBRÓJ BUZZER", systemImage: "bolt.fill") {
                        store.armBuzzer()
                    }
                }
            }
        }
        .padding(24)
    }
}

private struct QuestionHeader: View {
    let question: BZZTQuestion

    var body: some View {
        HStack {
            Text("Pytanie \(question.index)/\(question.total)")
            Spacer()
            Label("\(question.timeLimit)", systemImage: "timer")
        }
        .font(.headline.weight(.bold))
        .foregroundStyle(Color.bzztElectric)
    }
}

private struct TruthButton: View {
    let title: String
    let systemImage: String
    let color: Color
    var isSelected = false
    var isDisabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 30, weight: .black))
                Text(title)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .foregroundStyle(Color.bzztTextPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 144)
            .background(isSelected ? color.opacity(0.42) : color.opacity(0.18))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(isSelected ? Color.bzztElectric : color, lineWidth: isSelected ? 4 : 2)
            }
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2.weight(.black))
                        .foregroundStyle(Color.bzztElectric)
                        .padding(12)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isSelected)
        .opacity(isDisabled ? 0.46 : 1)
    }
}

private struct WagerButton: View {
    let amount: Int
    var label: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label ?? "\(amount)")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(isSelected ? Color.bzztBackgroundPrimary : Color.bzztTextPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(isSelected ? Color.bzztElectric : Color.bzztSurfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
