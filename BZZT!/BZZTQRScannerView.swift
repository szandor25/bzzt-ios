import AVFoundation
import SwiftUI
import UIKit

struct BZZTQRScannerView: View {
    let onCodeScanned: (String) -> Void
    let onCancel: () -> Void

    @State private var scannerMessage = "Skieruj aparat na kod QR hosta."

    var body: some View {
        ZStack {
            BZZTQRScannerCameraView(
                message: $scannerMessage,
                onCodeScanned: { rawValue in
                    guard let code = BZZTJoinCodeParser.code(from: rawValue) else {
                        scannerMessage = "Ten QR nie wygląda jak kod pokoju BZZT."
                        return
                    }
                    onCodeScanned(code)
                }
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.headline.weight(.black))
                            .foregroundStyle(Color.bzztTextPrimary)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.56))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Zamknij skaner")

                    Spacer()
                }
                .padding(20)

                Spacer()

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.bzztElectric, lineWidth: 4)
                    .frame(width: 248, height: 248)
                    .shadow(color: Color.bzztElectric.opacity(0.45), radius: 18)

                Spacer()

                Text(scannerMessage)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.bzztTextPrimary)
                    .multilineTextAlignment(.center)
                    .padding(18)
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.62))
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(20)
            }
        }
        .background(Color.black)
    }
}

private struct BZZTQRScannerCameraView: UIViewControllerRepresentable {
    @Binding var message: String
    let onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> BZZTQRScannerViewController {
        let controller = BZZTQRScannerViewController()
        controller.onCodeScanned = onCodeScanned
        controller.onMessageChanged = { message = $0 }
        return controller
    }

    func updateUIViewController(_ uiViewController: BZZTQRScannerViewController, context: Context) {}
}

private final class BZZTQRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeScanned: ((String) -> Void)?
    var onMessageChanged: ((String) -> Void)?

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "bzzt.qr.scanner.session")
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var didScanCode = false
    private var isSessionConfigured = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        self.previewLayer = previewLayer
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        prepareCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    private func prepareCamera() {
        guard Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") != nil else {
            onMessageChanged?("Brakuje NSCameraUsageDescription w ustawieniach targetu. iOS blokuje kamerę.")
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] isGranted in
                DispatchQueue.main.async {
                    if isGranted {
                        self?.configureSession()
                    } else {
                        self?.showCameraAccessDenied()
                    }
                }
            }
        case .denied, .restricted:
            showCameraAccessDenied()
        @unknown default:
            showCameraAccessDenied()
        }
    }

    private func configureSession() {
        guard !isSessionConfigured else {
            startSession()
            return
        }

        onMessageChanged?("Uruchamiam aparat...")

        sessionQueue.async { [weak self] in
            guard let self else { return }

            let discovery = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera],
                mediaType: .video,
                position: .back
            )
            guard let device = discovery.devices.first ?? AVCaptureDevice.default(for: .video) else {
                self.updateMessage("Ten telefon albo symulator nie udostępnia aparatu.")
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: device)
                let output = AVCaptureMetadataOutput()

                self.session.beginConfiguration()
                self.session.sessionPreset = .high

                guard self.session.canAddInput(input) else {
                    self.session.commitConfiguration()
                    self.updateMessage("Nie można dodać wejścia aparatu.")
                    return
                }
                self.session.addInput(input)

                guard self.session.canAddOutput(output) else {
                    self.session.commitConfiguration()
                    self.updateMessage("Nie można uruchomić skanowania QR.")
                    return
                }
                self.session.addOutput(output)
                self.session.commitConfiguration()

                DispatchQueue.main.async {
                    output.setMetadataObjectsDelegate(self, queue: .main)
                    output.metadataObjectTypes = [.qr]
                    self.isSessionConfigured = true
                    self.onMessageChanged?("Skieruj aparat na kod QR hosta.")
                }

                guard !self.session.isRunning else { return }
                self.session.startRunning()
            } catch {
                self.updateMessage("Nie można uruchomić aparatu: \(error.localizedDescription)")
            }
        }
    }

    private func updateMessage(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.onMessageChanged?(message)
        }
    }

    private func startSession() {
        sessionQueue.async { [session] in
            guard !session.isRunning else { return }
            session.startRunning()
        }
    }

    private func stopSession() {
        sessionQueue.async { [session] in
            guard session.isRunning else { return }
            session.stopRunning()
        }
    }

    private func showCameraAccessDenied() {
        onMessageChanged?("Włącz dostęp do aparatu w Ustawieniach iOS, żeby skanować QR.")
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !didScanCode else { return }
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue else {
            return
        }

        didScanCode = true
        stopSession()
        onCodeScanned?(value)
    }
}

enum BZZTJoinCodeParser {
    static func code(from rawValue: String) -> String? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let directCode = normalizedCode(trimmed)
        if !directCode.isEmpty {
            return directCode
        }

        guard let components = URLComponents(string: trimmed) else {
            return nil
        }

        let queryItems = components.queryItems ?? []
        let possibleValues = [
            queryItems.first(where: { $0.name == "code" })?.value,
            queryItems.first(where: { $0.name == "room" })?.value,
            components.path.split(separator: "/").last.map(String.init)
        ]

        for value in possibleValues {
            let code = normalizedCode(value ?? "")
            if !code.isEmpty {
                return code
            }
        }

        return nil
    }

    private static func normalizedCode(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics
        let scalars = value.uppercased().unicodeScalars.filter { allowed.contains($0) }
        let code = String(String.UnicodeScalarView(scalars))
        return (4...8).contains(code.count) ? code : ""
    }
}
