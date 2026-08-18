import SwiftUI

struct PlayerProfileSettingsView: View {
    @Bindable var store: BZZTGameStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HeaderView(title: "PROFIL", subtitle: "Nick i avatar zapisują się lokalnie, żeby nie wybierać ich przy każdej grze.", backAction: store.goHome)

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

                BZZTPrimaryButton(title: "ZAPISZ", systemImage: "checkmark") {
                    store.savePlayerProfile()
                }
            }
            .padding(24)
        }
    }
}

struct AppSettingsView: View {
    @Bindable var store: BZZTGameStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HeaderView(title: "USTAWIENIA", subtitle: "Dźwięk, haptics i adres backendu dla testów online.", backAction: store.goHome)

                BZZTPanel {
                    Toggle("Głos prowadzącego", isOn: $store.hostVoiceEnabled)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.bzztTextPrimary)

                    Toggle("Haptics", isOn: $store.hapticsEnabled)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color.bzztTextPrimary)

                    VStack(alignment: .leading, spacing: 10) {
                        SettingsValueLabel(title: "Muzyka", value: Int(store.musicVolume * 100))
                        Slider(value: $store.musicVolume, in: 0...1)
                            .tint(Color.bzztElectric)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SettingsValueLabel(title: "Efekty", value: Int(store.effectsVolume * 100))
                        Slider(value: $store.effectsVolume, in: 0...1)
                            .tint(Color.bzztElectric)
                    }
                }

                BZZTPanel {
                    Text("BACKEND")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color.bzztTextSecondary)

                    TextField("https://bzzt.e-aw.pl", text: $store.backendBaseURLString)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.bzztTextPrimary)
                        .padding(14)
                        .background(Color.bzztSurfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                BZZTPrimaryButton(title: "ZAPISZ", systemImage: "checkmark") {
                    store.saveSettings()
                }
            }
            .padding(24)
        }
    }
}

private struct SettingsValueLabel: View {
    let title: String
    let value: Int

    var body: some View {
        HStack {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.bzztTextPrimary)
            Spacer()
            Text("\(value)%")
                .font(.headline.weight(.black))
                .foregroundStyle(Color.bzztElectric)
        }
    }
}
