import SwiftUI

extension Color {
    static let bzztBackgroundPrimary = Color(red: 0.035, green: 0.039, blue: 0.071)
    static let bzztBackgroundSecondary = Color(red: 0.067, green: 0.075, blue: 0.122)
    static let bzztSurfaceElevated = Color(red: 0.094, green: 0.106, blue: 0.165)
    static let bzztTextPrimary = Color(red: 0.973, green: 0.976, blue: 1.0)
    static let bzztTextSecondary = Color(red: 0.655, green: 0.671, blue: 0.741)
    static let bzztDivider = Color(red: 0.153, green: 0.169, blue: 0.231)
    static let bzztElectric = Color(red: 0.843, green: 1.0, blue: 0.196)
    static let bzztSuccess = Color(red: 0.224, green: 0.898, blue: 0.549)
    static let bzztError = Color(red: 1.0, green: 0.302, blue: 0.369)
    static let bzztWarning = Color(red: 1.0, green: 0.710, blue: 0.278)
    static let bzztInfo = Color(red: 0.400, green: 0.639, blue: 1.0)
}

struct BZZTScreenBackground: View {
    var body: some View {
        ZStack {
            Color.bzztBackgroundPrimary

            RadialGradient(
                colors: [Color.bzztElectric.opacity(0.22), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 360
            )

            RadialGradient(
                colors: [Color.bzztInfo.opacity(0.20), .clear],
                center: .bottomLeading,
                startRadius: 20,
                endRadius: 420
            )
        }
        .ignoresSafeArea()
    }
}

struct BZZTPrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage ?? "bolt.fill")
                .labelStyle(.titleAndIcon)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(Color.bzztBackgroundPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(Color.bzztElectric)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.bzztElectric.opacity(0.34), radius: 18, y: 8)
        }
        .buttonStyle(.plain)
    }
}

struct BZZTSecondaryButton: View {
    let title: String
    var systemImage: String? = nil
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage ?? "circle")
                .labelStyle(.titleAndIcon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.bzztTextPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.bzztSurfaceElevated)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.bzztDivider, lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct BZZTPanel<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.bzztBackgroundSecondary.opacity(0.92))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.bzztDivider, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct BZZTLogo: View {
    var size: CGFloat = 56

    var body: some View {
        Text("BZZT!")
            .font(.system(size: size, weight: .black, design: .rounded))
            .foregroundStyle(Color.bzztTextPrimary)
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: size * 0.26, weight: .black))
                    .foregroundStyle(Color.bzztElectric)
                    .offset(x: size * 0.15, y: -size * 0.08)
            }
            .accessibilityLabel("BZZT")
    }
}

struct BZZTPlayerChip: View {
    let player: BZZTPlayer

    var body: some View {
        HStack(spacing: 12) {
            Text(player.avatar)
                .font(.system(size: 30))
                .frame(width: 46, height: 46)
                .background(Color.bzztSurfaceElevated)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(.headline)
                    .foregroundStyle(Color.bzztTextPrimary)

                Text(player.isHost ? "HOST" : player.isReady ? "GOTOWY" : "CZEKA")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(player.isReady || player.isHost ? Color.bzztElectric : Color.bzztTextSecondary)
            }

            Spacer()

            Text("\(player.score)")
                .font(.system(.title3, design: .rounded, weight: .heavy))
                .foregroundStyle(Color.bzztTextPrimary)
        }
        .padding(14)
        .background(Color.bzztSurfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct BZZTAnswerCard: View {
    let option: BZZTAnswerOption
    let state: BZZTAnswerState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(option.letter)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(Color.bzztBackgroundPrimary)
                    .frame(width: 38, height: 38)
                    .background(option.color)
                    .clipShape(Circle())

                Text(option.text)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(foregroundColor)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Spacer()
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 74, alignment: .leading)
            .background(backgroundColor)
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(borderColor, lineWidth: state == .idle ? 1 : 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .scaleEffect(state == .submitted ? 0.98 : 1)
        }
        .buttonStyle(.plain)
        .disabled(state == .disabled || state == .submitted || state == .correct || state == .incorrect)
    }

    private var backgroundColor: Color {
        switch state {
        case .correct:
            Color.bzztSuccess.opacity(0.22)
        case .incorrect:
            Color.bzztError.opacity(0.22)
        case .submitted:
            Color.bzztElectric.opacity(0.18)
        case .disabled:
            Color.bzztSurfaceElevated.opacity(0.45)
        case .idle:
            Color.bzztSurfaceElevated
        }
    }

    private var borderColor: Color {
        switch state {
        case .correct:
            Color.bzztSuccess
        case .incorrect:
            Color.bzztError
        case .submitted:
            Color.bzztElectric
        default:
            Color.bzztDivider
        }
    }

    private var foregroundColor: Color {
        state == .disabled ? Color.bzztTextSecondary : Color.bzztTextPrimary
    }
}

struct BZZTBuzzerButton: View {
    let state: BZZTBuzzerState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 42, weight: .black))
                Text(state.title)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 168)
            .background(backgroundColor)
            .overlay {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .stroke(borderColor, lineWidth: 3)
            }
            .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
            .shadow(color: shadowColor, radius: 28, y: 14)
            .scaleEffect(state == .pressed ? 0.96 : 1)
        }
        .buttonStyle(.plain)
        .disabled(state != .armed)
    }

    private var backgroundColor: Color {
        switch state {
        case .armed, .won:
            Color.bzztElectric
        case .lost:
            Color.bzztError.opacity(0.18)
        case .pressed:
            Color.bzztElectric.opacity(0.55)
        case .waiting, .disabled:
            Color.bzztSurfaceElevated
        }
    }

    private var foregroundColor: Color {
        switch state {
        case .armed, .won, .pressed:
            Color.bzztBackgroundPrimary
        default:
            Color.bzztTextPrimary
        }
    }

    private var borderColor: Color {
        state == .armed || state == .won ? Color.bzztElectric : Color.bzztDivider
    }

    private var shadowColor: Color {
        state == .armed || state == .won ? Color.bzztElectric.opacity(0.45) : Color.clear
    }
}
