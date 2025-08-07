import SwiftUI
import CoreImage.CIFilterBuiltins
import Foundation

class QRCodeGenerator {
    static let shared = QRCodeGenerator()
    
    private init() {}
    
    // Format des données pour QR Code
    struct QRContactData: Codable {
        let type: String = "MyCrew_Contact"
        let version: String = "1.0"
        let data: ContactData
        
        struct ContactData: Codable {
            let name: String
            let jobTitle: String
            let phone: String
            let email: String
            let notes: String
            let isFavorite: Bool
            let locations: [LocationData]
            
            struct LocationData: Codable {
                let country: String
                let region: String?
                let isLocalResident: Bool
                let hasVehicle: Bool
                let isHoused: Bool
                let isPrimary: Bool
            }
        }
    }
    
    // Générer QR code à partir d'un Contact
    func generateQRCode(for contact: Contact) -> UIImage? {
        // Convertir le contact en données QR
        let locationData = contact.locations.map { location in
            QRContactData.ContactData.LocationData(
                country: location.country,
                region: location.region,
                isLocalResident: location.isLocalResident,
                hasVehicle: location.hasVehicle,
                isHoused: location.isHoused,
                isPrimary: location.isPrimary
            )
        }
        
        let contactData = QRContactData.ContactData(
            name: contact.name,
            jobTitle: contact.jobTitle,
            phone: contact.phone,
            email: contact.email,
            notes: contact.notes,
            isFavorite: contact.isFavorite,
            locations: locationData
        )
        
        let qrData = QRContactData(data: contactData)
        
        // Encoder en JSON
        guard let jsonData = try? JSONEncoder().encode(qrData),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("❌ Erreur encodage JSON pour QR Code")
            return nil
        }
        
        return generateQRCodeImage(from: jsonString)
    }
    
    // Générer l'image QR code
    private func generateQRCodeImage(from string: String) -> UIImage? {
        let data = Data(string.utf8)
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel") // Niveau de correction moyen
        
        guard let ciImage = filter.outputImage else {
            print("❌ Erreur génération QR Code")
            return nil
        }
        
        // Upscaler pour meilleure qualité
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledCIImage = ciImage.transformed(by: transform)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledCIImage, from: scaledCIImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    // Parser les données QR scannées
    func parseQRCodeData(_ qrString: String) -> ContactExportData.ContactData? {
        guard let data = qrString.data(using: .utf8) else {
            print("❌ Impossible de convertir QR string en data")
            return nil
        }
        
        do {
            let qrData = try JSONDecoder().decode(QRContactData.self, from: data)
            
            // Vérifier le format
            guard qrData.type == "MyCrew_Contact" else {
                print("❌ QR Code non reconnu : type \(qrData.type)")
                return nil
            }
            
            // Convertir vers ContactExportData
            let locations = qrData.data.locations.map { loc in
                ContactExportData.ContactData.LocationData(
                    country: loc.country,
                    region: loc.region,
                    isLocalResident: loc.isLocalResident,
                    hasVehicle: loc.hasVehicle,
                    isHoused: loc.isHoused,
                    isPrimary: loc.isPrimary
                )
            }
            
            let contact = ContactExportData.ContactData(
                name: qrData.data.name,
                jobTitle: qrData.data.jobTitle,
                phone: qrData.data.phone,
                email: qrData.data.email,
                notes: qrData.data.notes,
                isFavorite: qrData.data.isFavorite,
                locations: locations
            )
            
            print("✅ QR Code parsé : \(contact.name)")
            return contact
            
        } catch {
            print("❌ Erreur parsing QR Code : \(error)")
            return nil
        }
    }
}
