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

                VStack(spacing: 12) {
                    ForEach(store.currentQuestion.options) { option in
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
            HeaderView(title: "PRAWDA / FAŁSZ", subtitle: "Znaczenie nie zależy od koloru: decyzja jest też opisana tekstem.", backAction: { store.phase = .roundIntro })

            Spacer()

            Text(store.trueFalsePrompt.statement)
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(Color.bzztTextPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            HStack(spacing: 14) {
                TruthButton(title: "FAŁSZ", systemImage: "xmark", color: Color.bzztError) {
                    store.submitTrueFalseAnswer(false)
                }
                TruthButton(title: "PRAWDA", systemImage: "checkmark", color: Color.bzztSuccess) {
                    store.submitTrueFalseAnswer(true)
                }
            }
        }
        .padding(24)
    }
}

struct RiskRoundView: View {
    let store: BZZTGameStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HeaderView(title: "RISK ROUND", subtitle: "Postaw punkty. Dobra odpowiedź dodaje stawkę, zła ją odejmuje.", backAction: { store.phase = .roundIntro })

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
                }

                QuestionHeader(question: store.riskPrompt.question)

                Text(store.riskPrompt.question.text)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(Color.bzztTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 12) {
                    ForEach(store.riskPrompt.question.options) { option in
                        BZZTAnswerCard(option: option, state: store.state(for: option)) {
                            store.submitRiskAnswer(option)
                        }
                    }
                }
            }
            .padding(24)
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
            .background(color.opacity(0.22))
            .overlay {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(color, lineWidth: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .buttonStyle(.plain)
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
