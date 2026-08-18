import SwiftUI

struct HeaderView: View {
    let title: String
    let subtitle: String
    let backAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: backAction) {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.bzztTextPrimary)
                    .frame(width: 42, height: 42)
                    .background(Color.bzztSurfaceElevated)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Wstecz")

            Text(title)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(Color.bzztTextPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.78)

            Text(subtitle)
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.bzztTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct SettingsPicker<Value: Hashable & Identifiable & RawRepresentable & CaseIterable>: View where Value.RawValue == String, Value.AllCases: RandomAccessCollection, Value.AllCases.Element == Value {
    let title: String
    @Binding var selection: Value

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption.weight(.black))
                .foregroundStyle(Color.bzztTextSecondary)

            Picker(title, selection: $selection) {
                ForEach(Value.allCases) { value in
                    Text(value.rawValue).tag(value)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

struct BZZTConnectionBanner: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(Color.bzztElectric)
                .controlSize(.small)

            Text(message)
                .font(.callout.weight(.bold))
                .foregroundStyle(Color.bzztTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Spacer()

            Button(action: retryAction) {
                Image(systemName: "arrow.clockwise")
                    .font(.headline.weight(.black))
                    .foregroundStyle(Color.bzztElectric)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Połącz ponownie")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.bzztSurfaceElevated.opacity(0.96))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.bzztDivider, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.24), radius: 16, y: 8)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

struct RoundModeButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(Color.bzztElectric)
                    .frame(width: 44, height: 44)
                    .background(Color.bzztElectric.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline.weight(.black))
                        .foregroundStyle(Color.bzztTextPrimary)
                    Text(subtitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.bzztTextSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.black))
                    .foregroundStyle(Color.bzztTextSecondary)
            }
            .padding(16)
            .background(Color.bzztSurfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
