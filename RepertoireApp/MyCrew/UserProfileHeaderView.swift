import SwiftUI
import CoreImage.CIFilterBuiltins // Import manquant

struct UserProfileHeaderView: View {
    @Binding var userProfile: UserProfile
    @State private var showEditor = false
    @State private var showQRCode = false

    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 40, height: 40) // Taille augmentée
                .foregroundColor(MyCrewColors.accent) // Couleur inversée

            VStack(alignment: .leading, spacing: 2) {
                Text("MA FICHE PRO")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.white) // Couleur inversée
                    
                Text("\(userProfile.firstName) \(userProfile.lastName) • \(userProfile.jobTitle)")
                    .font(.body.weight(.medium)) // Taille augmentée de ~30%
                    .foregroundColor(.white.opacity(0.9)) // Couleur inversée avec opacité
            }
            Spacer()
            
            // QR Code miniature
            Image(uiImage: generateQRCode())
                .interpolation(.none)
                .resizable()
                .frame(width: 40, height: 40)
                .cornerRadius(4)
                .onTapGesture {
                    showQRCode = true
                }
        }
        .padding()
        .background(MyCrewColors.accentSecondary)
        .cornerRadius(12)
        .onTapGesture {
            showEditor = true
        }
        .sheet(isPresented: $showQRCode) {
            NavigationView {
                VStack(spacing: 24) {
                    Text("\(userProfile.firstName) \(userProfile.lastName)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(MyCrewColors.textPrimary)
                    
                    Text(userProfile.jobTitle)
                        .font(.subheadline)
                        .foregroundColor(MyCrewColors.accent)
                    
                    Image(uiImage: generateQRCode())
                        .interpolation(.none)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 240, height: 240)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    Text("Votre QR Code MyCrew")
                        .font(.caption)
                        .foregroundColor(MyCrewColors.textSecondary)
                    
                    Spacer()
                }
                .padding()
                .background(MyCrewColors.accentSecondary) // Même couleur que la fiche pro
                .navigationTitle("Mon QR Code")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Fermer") {
                            showQRCode = false
                        }
                        .foregroundColor(MyCrewColors.accent)
                    }
                }
            }
        }
        .sheet(isPresented: $showEditor) {
            UserProfileEditorView(userProfile: $userProfile)
        }
    }

    private func generateQRCode() -> UIImage {
        let data: [String: Any] = [
            "type": "MyCrew_Contact",
            "version": "1.0",
            "data": [
                "name": "\(userProfile.firstName) \(userProfile.lastName)",
                "jobTitle": userProfile.jobTitle,
                "phone": userProfile.phoneNumber,
                "email": userProfile.email,
                "notes": "Ma fiche personnelle",
                "isFavorite": false,
                "locations": userProfile.locations.map { location in
                    [
                        "country": location.country,
                        "region": location.region ?? "",
                        "isLocalResident": location.isLocalResident,
                        "hasVehicle": location.hasVehicle,
                        "isHoused": location.isHoused,
                        "isPrimary": location.isPrimary
                    ] as [String: Any]
                }
            ] as [String: Any]
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: data),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return UIImage()
        }

        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(Data(jsonString.utf8), forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        
        return UIImage()
    }
}
