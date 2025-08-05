// ContactSharingManager.swift
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// Définir le type de fichier personnalisé
extension UTType {
    static var repertoire: UTType {
        UTType(exportedAs: "com.repertoire.contact")
    }
}

// Structure pour l'export/import des contacts
struct ContactExportData: Codable {
    let version: String = "1.0"
    let exportDate: Date = Date()
    let contact: ContactData
    
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

// Extension pour convertir Contact en ContactExportData
extension Contact {
    func toExportData() -> ContactExportData {
        let locationData = self.locations.map { location in
            ContactExportData.ContactData.LocationData(
                country: location.country,
                region: location.region,
                isLocalResident: location.isLocalResident,
                hasVehicle: location.hasVehicle,
                isHoused: location.isHoused,
                isPrimary: location.isPrimary
            )
        }
        
        let contactData = ContactExportData.ContactData(
            name: self.name,
            jobTitle: self.jobTitle,
            phone: self.phone,
            email: self.email,
            notes: self.notes,
            isFavorite: self.isFavorite,
            locations: locationData
        )
        
        return ContactExportData(contact: contactData)
    }
}

// Manager pour gérer l'export/import
class ContactSharingManager: ObservableObject {
    static let shared = ContactSharingManager()
    
    private init() {}
    
    // Export d'un contact avec format JSON standard
    func exportContact(_ contact: Contact) -> URL? {
        do {
            let exportData = contact.toExportData()
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(exportData)
            
            // Créer un nom de fichier sécurisé avec extension .json pour une meilleure compatibilité
            let safeName = contact.name.replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: "\\", with: "-")
                .replacingOccurrences(of: "[^a-zA-Z0-9_-]", with: "", options: .regularExpression)
            
            let fileName = "Contact_\(safeName).json"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            
            try jsonData.write(to: tempURL)
            return tempURL
            
        } catch {
            print("Erreur lors de l'export: \(error)")
            return nil
        }
    }
    
    // Export avec données texte pour partage facile
    func exportContactAsText(_ contact: Contact) -> String {
        var text = "📋 FICHE CONTACT - RÉPERTOIRE\n"
        text += "================================\n\n"
        text += "👤 NOM: \(contact.name)\n"
        text += "💼 POSTE: \(contact.jobTitle)\n"
        
        if !contact.phone.isEmpty {
            text += "📞 TÉLÉPHONE: \(contact.phone)\n"
        }
        
        if !contact.email.isEmpty {
            text += "📧 EMAIL: \(contact.email)\n"
        }
        
        text += "\n📍 LIEUX DE TRAVAIL:\n"
        
        // Lieu principal
        if let primaryLoc = contact.primaryLocation {
            text += "• PRINCIPAL: \(primaryLoc.country)"
            if let region = primaryLoc.region {
                text += " / \(region)"
            }
            
            var attributes: [String] = []
            if primaryLoc.hasVehicle { attributes.append("Véhiculé") }
            if primaryLoc.isHoused { attributes.append("Logé") }
            if primaryLoc.isLocalResident { attributes.append("Résidence fiscale") }
            
            if !attributes.isEmpty {
                text += " (\(attributes.joined(separator: ", ")))"
            }
            text += "\n"
        }
        
        // Lieux secondaires
        for (index, location) in contact.secondaryLocations.enumerated() {
            text += "• SECONDAIRE \(index + 1): \(location.country)"
            if let region = location.region {
                text += " / \(region)"
            }
            
            var attributes: [String] = []
            if location.hasVehicle { attributes.append("Véhiculé") }
            if location.isHoused { attributes.append("Logé") }
            if location.isLocalResident { attributes.append("Résidence fiscale") }
            
            if !attributes.isEmpty {
                text += " (\(attributes.joined(separator: ", ")))"
            }
            text += "\n"
        }
        
        if !contact.notes.isEmpty {
            text += "\n📝 NOTES:\n\(contact.notes)\n"
        }
        
        text += "\n================================\n"
        text += "Exporté depuis Répertoire App"
        
        return text
    }
    
    // Import d'un contact depuis URL
    func importContact(from url: URL, context: ModelContext) throws -> Contact {
        let data = try Data(contentsOf: url)
        let exportData = try JSONDecoder().decode(ContactExportData.self, from: data)
        
        // Créer le nouveau contact
        let newContact = Contact(
            name: exportData.contact.name,
            jobTitle: exportData.contact.jobTitle,
            phone: exportData.contact.phone,
            email: exportData.contact.email,
            notes: exportData.contact.notes,
            isFavorite: false // Importé comme non-favori par défaut
        )
        
        // Créer les lieux de travail
        var workLocations: [WorkLocation] = []
        for locationData in exportData.contact.locations {
            let workLocation = WorkLocation(
                country: locationData.country,
                region: locationData.region,
                isLocalResident: locationData.isLocalResident,
                hasVehicle: locationData.hasVehicle,
                isHoused: locationData.isHoused,
                isPrimary: locationData.isPrimary
            )
            context.insert(workLocation)
            workLocations.append(workLocation)
        }
        
        newContact.locations = workLocations
        context.insert(newContact)
        try context.save()
        
        return newContact
    }
}
