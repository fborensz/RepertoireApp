import SwiftUI
import AVFoundation

struct QRCodeScannerView: UIViewControllerRepresentable {
    let onQRCodeScanned: (String) -> Void
    let onDismiss: () -> Void
    
    func makeUIViewController(context: Context) -> QRCodeScannerViewController {
        let controller = QRCodeScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QRCodeScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, QRCodeScannerDelegate {
        let parent: QRCodeScannerView
        
        init(_ parent: QRCodeScannerView) {
            self.parent = parent
        }
        
        func qrCodeScanned(_ code: String) {
            parent.onQRCodeScanned(code)
        }
        
        func scanningFailed() {
            parent.onDismiss()
        }
    }
}

protocol QRCodeScannerDelegate: AnyObject {
    func qrCodeScanned(_ code: String)
    func scanningFailed()
}

class QRCodeScannerViewController: UIViewController {
    weak var delegate: QRCodeScannerDelegate?
    
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var hasScanned = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hasScanned = false
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            delegate?.scanningFailed()
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            delegate?.scanningFailed()
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            delegate?.scanningFailed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            delegate?.scanningFailed()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Overlay avec trou au centre pour le scan
        let overlayView = UIView(frame: view.bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        let scanArea = CGRect(
            x: (view.bounds.width - 200) / 2,
            y: (view.bounds.height - 200) / 2,
            width: 200,
            height: 200
        )
        
        let path = UIBezierPath(rect: overlayView.bounds)
        let scanPath = UIBezierPath(rect: scanArea)
        path.append(scanPath)
        path.usesEvenOddFillRule = true
        
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        maskLayer.fillRule = .evenOdd
        overlayView.layer.mask = maskLayer
        
        view.addSubview(overlayView)
        
        // Bordure de scan
        let borderView = UIView(frame: scanArea)
        borderView.layer.borderColor = UIColor.white.cgColor
        borderView.layer.borderWidth = 2
        borderView.layer.cornerRadius = 8
        borderView.backgroundColor = .clear
        view.addSubview(borderView)
        
        // Label d'instructions
        let instructionLabel = UILabel()
        instructionLabel.text = "Scannez un QR Code MyCrew"
        instructionLabel.textColor = .white
        instructionLabel.font = .systemFont(ofSize: 18, weight: .medium)
        instructionLabel.textAlignment = .center
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionLabel)
        
        NSLayoutConstraint.activate([
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.topAnchor.constraint(equalTo: borderView.bottomAnchor, constant: 32)
        ])
        
        // Bouton fermer
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("✕", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 24, weight: .bold)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        closeButton.layer.cornerRadius = 20
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc private func closeButtonTapped() {
        delegate?.scanningFailed()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.layer.bounds
    }
}

extension QRCodeScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        guard !hasScanned else { return }
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            hasScanned = true
            
            // Haptic feedback
            let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
            impactGenerator.impactOccurred()
            
            // Son de scan
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            delegate?.qrCodeScanned(stringValue)
        }
    }
}
