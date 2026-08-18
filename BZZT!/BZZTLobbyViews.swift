import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

struct HomeView: View {
    let store: BZZTGameStore

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 36)

            VStack(spacing: 10) {
                BZZTLogo(size: 58)
                Text("Mobilny teleturniej imprezowy")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.bzztTextSecondary)
            }

            Spacer()

            VStack(spacing: 14) {
                BZZTPrimaryButton(title: "GRAJ TERAZ", systemImage: "play.fill") {
                    store.quickStart()
                }

                HStack(spacing: 12) {
                    BZZTSecondaryButton(title: "UTWÓRZ", systemImage: "plus") {
                        store.showCreateRoom()
                    }
                    BZZTSecondaryButton(title: "DOŁĄCZ", systemImage: "number") {
                        store.showJoinRoom()
                    }
                }
            }

            Spacer()

            HStack {
                Button {
                    store.showPlayerProfile()
                } label: {
                    Label("Profil", systemImage: "person.crop.circle")
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    store.showSettings()
                } label: {
                    Label("Ustawienia", systemImage: "gearshape")
                }
                .buttonStyle(.plain)
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Color.bzztTextSecondary)
        }
        .padding(24)
    }
}

struct CreateRoomView: View {
    @Bindable var store: BZZTGameStore
    @State private var isShowingMoreSettings = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HeaderView(title: "UTWÓRZ GRĘ", subtitle: "Domyślnie szybki Party Mode dla 2–8 graczy.", backAction: store.goHome)

                BZZTPanel {
                    Text("TRYB GRY")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.bzztTextSecondary)

                    VStack(spacing: 10) {
                        ForEach(BZZTGameMode.allCases) { mode in
                            GameModeSelectionRow(
                                mode: mode,
                                isSelected: store.roomSettings.mode == mode
                            ) {
                                store.selectGameMode(mode)
                            }
                        }
                    }
                }

                BZZTPanel {
                    SettingsPicker(title: "Czas gry", selection: $store.roomSettings.length)
                    SettingsPicker(title: "Poziom", selection: $store.roomSettings.difficulty)
                }

                BZZTPrimaryButton(title: "UTWÓRZ POKÓJ", systemImage: "bolt.circle.fill") {
                    store.createRoom()
                }

                BZZTSecondaryButton(title: "WIĘCEJ USTAWIEŃ", systemImage: "slider.horizontal.3") {
                    isShowingMoreSettings = true
                }
            }
            .padding(24)
        }
        .sheet(isPresented: $isShowingMoreSettings) {
            RoomAdvancedSettingsView(store: store)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct RoomAdvancedSettingsView: View {
    @Bindable var store: BZZTGameStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            BZZTScreenBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("USTAWIENIA GRY")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundStyle(Color.bzztTextPrimary)
                            Text("Dostosuj parametry przed utworzeniem pokoju.")
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(Color.bzztTextSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.headline.weight(.black))
                                .foregroundStyle(Color.bzztTextPrimary)
                                .frame(width: 42, height: 42)
                                .background(Color.bzztSurfaceElevated)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Zamknij")
                    }

                    BZZTPanel {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("LICZBA RUND")
                                    .font(.caption.weight(.black))
                                    .foregroundStyle(Color.bzztTextSecondary)
                                Text("\(store.roomSettings.roundCount)")
                                    .font(.system(size: 42, weight: .black, design: .rounded))
                                    .foregroundStyle(Color.bzztElectric)
                            }

                            Spacer()

                            Stepper("", value: $store.roomSettings.roundCount, in: 3...20, step: 1)
                                .labelsHidden()
                        }

                        Slider(value: Binding(
                            get: { Double(store.roomSettings.roundCount) },
                            set: { store.roomSettings.roundCount = Int($0.rounded()) }
                        ), in: 3...20, step: 1)
                        .tint(Color.bzztElectric)
                    }

                    BZZTPanel {
                        SettingsSummaryRow(title: "Tryb", value: store.roomSettings.mode.rawValue)
                        Text(store.roomSettings.mode.details)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.bzztTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        SettingsSummaryRow(title: "Czas gry", value: store.roomSettings.length.rawValue)
                        SettingsSummaryRow(title: "Poziom", value: store.roomSettings.difficulty.rawValue)
                    }

                    BZZTPrimaryButton(title: "GOTOWE", systemImage: "checkmark") {
                        dismiss()
                    }
                }
                .padding(24)
            }
        }
        .preferredColorScheme(.dark)
    }
}

private struct GameModeSelectionRow: View {
    let mode: BZZTGameMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: mode.systemImage)
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(isSelected ? Color.bzztBackgroundPrimary : Color.bzztElectric)
                    .frame(width: 42, height: 42)
                    .background(isSelected ? Color.bzztElectric : Color.bzztElectric.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(mode.rawValue.uppercased())
                            .font(.headline.weight(.black))
                            .foregroundStyle(Color.bzztTextPrimary)

                        if mode == .party {
                            Text("DOMYŚLNY")
                                .font(.caption2.weight(.black))
                                .foregroundStyle(Color.bzztBackgroundPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.bzztElectric)
                                .clipShape(Capsule())
                        }
                    }

                    Text(mode.subtitle)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color.bzztTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(mode.details)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.bzztTextSecondary.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.headline.weight(.black))
                    .foregroundStyle(isSelected ? Color.bzztElectric : Color.bzztTextSecondary)
            }
            .padding(14)
            .background(isSelected ? Color.bzztElectric.opacity(0.10) : Color.bzztSurfaceElevated)
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? Color.bzztElectric : Color.bzztDivider, lineWidth: isSelected ? 2 : 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsSummaryRow: View {
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

struct JoinRoomView: View {
    @Bindable var store: BZZTGameStore
    @State private var isShowingQRScanner = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HeaderView(title: "KOD POKOJU", subtitle: "Wpisz kod od hosta, a potem wybierz nick i avatar.", backAction: store.goHome)

            BZZTPanel {
                TextField("_ _ _ _ _ _", text: $store.joinCode)
                    .keyboardType(.numberPad)
                    .textInputAutocapitalization(.characters)
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(Color.bzztTextPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 8)
                    .background(Color.bzztSurfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                BZZTSecondaryButton(title: "SKANUJ QR", systemImage: "qrcode.viewfinder") {
                    isShowingQRScanner = true
                }
            }

            if let message = store.connectionMessage {
                Text(message)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Color.bzztWarning)
            }

            BZZTPrimaryButton(title: "DALEJ", systemImage: "arrow.right") {
                store.joinRoom()
            }

            Spacer()
        }
        .padding(24)
        .fullScreenCover(isPresented: $isShowingQRScanner) {
            BZZTQRScannerView(
                onCodeScanned: { code in
                    store.joinCode = code
                    isShowingQRScanner = false
                    store.joinRoom()
                },
                onCancel: {
                    isShowingQRScanner = false
                }
            )
        }
    }
}

struct ProfileView: View {
    @Bindable var store: BZZTGameStore

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HeaderView(title: "TWÓJ NICK", subtitle: "Profil zostanie później zapisany lokalnie.", backAction: store.goHome)

            BZZTPanel {
                TextField("AREK", text: $store.localPlayerName)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(Color.bzztTextPrimary)
                    .textInputAutocapitalization(.characters)
                    .padding(16)
                    .background(Color.bzztSurfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Text("WYBIERZ AVATAR")
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color.bzztTextSecondary)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(store.avatars, id: \.self) { avatar in
                        Button {
                            store.localAvatar = avatar
                        } label: {
                            Text(avatar)
                                .font(.system(size: 36))
                                .frame(maxWidth: .infinity)
                                .frame(height: 68)
                                .background(store.localAvatar == avatar ? Color.bzztElectric.opacity(0.22) : Color.bzztSurfaceElevated)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if let message = store.connectionMessage {
                Text(message)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Color.bzztWarning)
            }

            BZZTPrimaryButton(title: "GOTOWE", systemImage: "checkmark") {
                store.saveProfile()
            }

            Spacer()
        }
        .padding(24)
    }
}

struct LobbyView: View {
    let store: BZZTGameStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HeaderView(title: store.room?.title ?? "BZZT! PARTY", subtitle: "Kod: \(store.room?.code ?? "------")", backAction: store.goHome)

                if let code = store.room?.code {
                    RoomQRCodeView(code: code)
                }

                BZZTPanel {
                    HStack {
                        Text("GRACZE \(store.players.count)/\(store.room?.maxPlayers ?? 8)")
                            .font(.caption.weight(.black))
                            .foregroundStyle(Color.bzztTextSecondary)
                        Spacer()
                        Text(store.canStartGame ? "GOTOWI" : "LOBBY")
                            .font(.caption.weight(.black))
                            .foregroundStyle(store.canStartGame ? Color.bzztElectric : Color.bzztTextSecondary)
                    }

                    ForEach(store.players) { player in
                        BZZTPlayerChip(player: player)
                            .onTapGesture {
                                store.toggleReady(for: player.id)
                            }
                    }
                }

                HStack(spacing: 12) {
                    BZZTSecondaryButton(title: "GOTOWY", systemImage: "checkmark.circle") {
                        store.markLocalReady()
                    }
                    BZZTPrimaryButton(title: "START", systemImage: "play.fill") {
                        store.startGame()
                    }
                    .disabled(!store.canStartGame)
                    .opacity(store.canStartGame ? 1 : 0.48)
                }

                if store.connectionState != .connected {
                    BZZTSecondaryButton(title: "POŁĄCZ PONOWNIE", systemImage: "arrow.clockwise") {
                        store.reconnect()
                    }
                    .opacity(0.72)
                }
            }
            .padding(24)
        }
    }
}

private struct RoomQRCodeView: View {
    let code: String

    var body: some View {
        BZZTPanel {
            HStack(alignment: .center, spacing: 16) {
                QRCodeImage(value: code)
                    .frame(width: 132, height: 132)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    Text("KOD DOŁĄCZENIA")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.bzztTextSecondary)

                    Text(code)
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(Color.bzztElectric)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text("Zeskanuj QR drugim telefonem albo wpisz kod ręcznie.")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Color.bzztTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct QRCodeImage: View {
    let value: String

    var body: some View {
        if let image = makeImage(from: value) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .padding(10)
                .accessibilityLabel("Kod QR pokoju \(value)")
        } else {
            Image(systemName: "qrcode")
                .font(.system(size: 72, weight: .bold))
                .foregroundStyle(Color.bzztTextSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel("Nie udało się wygenerować kodu QR")
        }
    }

    private func makeImage(from value: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.correctionLevel = "M"
        filter.message = Data(value.utf8)

        guard let outputImage = filter.outputImage else { return nil }
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 12, y: 12))
        guard let cgImage = QRCodeRenderer.context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

private enum QRCodeRenderer {
    static let context = CIContext()
}
