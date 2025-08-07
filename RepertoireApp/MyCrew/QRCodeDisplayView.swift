import SwiftUI

struct QRCodeDisplayView: View {
    let contact: Contact
    @Environment(\.dismiss) private var dismiss
    @State private var qrImage: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Infos du contact
                VStack(spacing: 8) {
                    Text(contact.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(MyCrewColors.textPrimary)
                    
                    Text(contact.jobTitle)
                        .font(.subheadline)
                        .foregroundColor(MyCrewColors.accent)
                }
                .padding(.top)
                
                // QR Code
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Génération du QR Code...")
                            .font(.subheadline)
                            .foregroundColor(MyCrewColors.textSecondary)
                    }
                    .frame(width: 280, height: 280)
                    .background(MyCrewColors.cardBackground)
                    .cornerRadius(16)
                } else if let qrImage = qrImage {
                    VStack(spacing: 16) {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 240, height: 240)
                        
                        Text("QR Code MyCrew")
                            .font(.caption)
                            .foregroundColor(MyCrewColors.textSecondary)
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 60))
                            .foregroundColor(MyCrewColors.textSecondary)
                        
                        Text("Erreur de génération")
                            .font(.subheadline)
                            .foregroundColor(.red)
                        
                        Button("Réessayer") {
                            generateQRCode()
                        }
                        .foregroundColor(MyCrewColors.accent)
                    }
                    .frame(width: 280, height: 280)
                    .background(MyCrewColors.cardBackground)
                    .cornerRadius(16)
                }
                
                // Instructions
                VStack(spacing: 8) {
                    Text("📱 Partage instantané")
                        .font(.headline)
                        .foregroundColor(MyCrewColors.textPrimary)
                    
                    Text("Les autres utilisateurs MyCrew peuvent scanner ce code pour importer ce contact directement")
                        .font(.subheadline)
                        .foregroundColor(MyCrewColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Bouton de partage
                if let qrImage = qrImage {
                    Button {
                        shareQRCode(qrImage)
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Partager le QR Code")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(MyCrewColors.accent)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .background(MyCrewColors.background)
            .navigationTitle("QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundColor(MyCrewColors.accent)
                }
            }
        }
        .onAppear {
            generateQRCode()
        }
    }
    
    private func generateQRCode() {
        isLoading = true
        qrImage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            let generatedImage = QRCodeGenerator.shared.generateQRCode(for: contact)
            
            DispatchQueue.main.async {
                isLoading = false
                qrImage = generatedImage
            }
        }
    }
    
    private func shareQRCode(_ image: UIImage) {
        let activityController = UIActivityViewController(
            activityItems: [
                "QR Code de \(contact.name) - \(contact.jobTitle)",
                image
            ],
            applicationActivities: nil
        )
        
        // Configuration pour iPad
        if let popoverController = activityController.popoverPresentationController {
            popoverController.sourceView = UIApplication.shared.windows.first?.rootViewController?.view
            popoverController.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        UIApplication.shared.windows.first?.rootViewController?.present(activityController, animated: true)
    }
}

// Miniature QR Code pour ContactDetailView
struct QRCodeMiniature: View {
    let contact: Contact
    @State private var qrImage: UIImage?
    @State private var showingFullQR = false
    
    var body: some View {
        Button {
            showingFullQR = true
        } label: {
            Group {
                if let qrImage = qrImage {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .frame(width: 60, height: 60)
            .background(Color.white)
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .onAppear {
            generateMiniQRCode()
        }
        .sheet(isPresented: $showingFullQR) {
            QRCodeDisplayView(contact: contact)
        }
    }
    
    private func generateMiniQRCode() {
        DispatchQueue.global(qos: .utility).async {
            let generatedImage = QRCodeGenerator.shared.generateQRCode(for: contact)
            
            DispatchQueue.main.async {
                qrImage = generatedImage
            }
        }
    }
}
