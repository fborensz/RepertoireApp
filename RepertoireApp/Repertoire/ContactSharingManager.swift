// ContactSharingManager.swift
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// Types d'export disponibles
enum ExportFormat {
    case text
    case csv
    case json
}

// Structure pour l'export/import des contacts
struct ContactExportData: Codable {
    let version: String
    let exportDate: Date
    let contact: ContactData
    
    init(contact: ContactData) {
        self.version = "1.0"
        self.exportDate = Date()
        self.contact = contact
    }
    
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
    
    // Export selon le format choisi
    func exportContact(_ contact: Contact, format: ExportFormat) -> (content: Any?, isFile: Bool) {
        switch format {
        case .text:
            return (exportContactAsText(contact), false)
        case .csv:
            return (exportContactAsCSV(contact), true)
        case .json:
            return (exportContactAsJSON(contact), true)
        }
    }
    
    // Export en texte lisible
    private func exportContactAsText(_ contact: Contact) -> String {
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
    
    // Export en CSV
    private func exportContactAsCSV(_ contact: Contact) -> URL? {
        var csvContent = "Nom,Poste,Telephone,Email,Pays,Region,Vehicule,Loge,Residence_Fiscale,Type_Lieu,Notes\n"
        
        if contact.locations.isEmpty {
            // Contact sans lieu
            let notes = contact.notes.replacingOccurrences(of: "\"", with: "\"\"")
            csvContent += "\"\(contact.name)\",\"\(contact.jobTitle)\",\"\(contact.phone)\",\"\(contact.email)\",,,,,,\"\(notes)\"\n"
        } else {
            // Une ligne par lieu
            for location in contact.locations {
                let notes = contact.notes.replacingOccurrences(of: "\"", with: "\"\"")
                let lieuType = location.isPrimary ? "Principal" : "Secondaire"
                let region = location.region ?? ""
                
                csvContent += "\"\(contact.name)\",\"\(contact.jobTitle)\",\"\(contact.phone)\",\"\(contact.email)\",\"\(location.country)\",\"\(region)\",\(location.hasVehicle ? "Oui" : "Non"),\(location.isHoused ? "Oui" : "Non"),\(location.isLocalResident ? "Oui" : "Non"),\"\(lieuType)\",\"\(notes)\"\n"
            }
        }
        
        // Créer le fichier
        let safeName = contact.name.replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "[^a-zA-Z0-9_-]", with: "", options: .regularExpression)
        
        let fileName = "Contact_\(safeName).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Erreur lors de l'export CSV: \(error)")
            return nil
        }
    }
    
    // Export en JSON
    private func exportContactAsJSON(_ contact: Contact) -> URL? {
        do {
            let exportData = contact.toExportData()
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(exportData)
            
            let safeName = contact.name.replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "[^a-zA-Z0-9_-]", with: "", options: .regularExpression)
            
            let fileName = "Contact_\(safeName).json"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            
            try jsonData.write(to: tempURL)
            return tempURL
            
        } catch {
            print("Erreur lors de l'export JSON: \(error)")
            return nil
        }
    }
    
    // Import d'un contact depuis URL (JSON ou CSV)
    func importContact(from url: URL, context: ModelContext) throws -> Contact {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "json":
            return try importFromJSON(url: url, context: context)
        case "csv":
            return try importFromCSV(url: url, context: context)
        default:
            throw ImportError.unsupportedFormat
        }
    }
    
    private func importFromJSON(url: URL, context: ModelContext) throws -> Contact {
        let data = try Data(contentsOf: url)
        let exportData = try JSONDecoder().decode(ContactExportData.self, from: data)
        
        return try createContact(from: exportData, context: context)
    }
    
    private func importFromCSV(url: URL, context: ModelContext) throws -> Contact {
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        guard lines.count > 1 else {
            throw ImportError.invalidFormat
        }
        
        // Parser la première ligne de données (ignorer l'en-tête)
        let firstDataLine = lines[1]
        let columns = parseCSVLine(firstDataLine)
        
        guard columns.count >= 10 else {
            throw ImportError.invalidFormat
        }
        
        // Créer le contact de base
        let contact = Contact(
            name: columns[0],
            jobTitle: columns[1],
            phone: columns[2],
            email: columns[3],
            notes: columns[10],
            isFavorite: false
        )
        
        // Traiter tous les lieux
        var locations: [WorkLocation] = []
        var seenCountries = Set<String>()
        
        for i in 1..<lines.count {
            let line = lines[i]
            let cols = parseCSVLine(line)
            if cols.count >= 10 {
                let country = cols[4]
                let region = cols[5].isEmpty ? nil : cols[5]
                let hasVehicle = cols[6].lowercased() == "oui"
                let isHoused = cols[7].lowercased() == "oui"
                let isResident = cols[8].lowercased() == "oui"
                let isPrimary = cols[9].lowercased().contains("principal")
                
                if !country.isEmpty && !seenCountries.contains(country) {
                    let location = WorkLocation(
                        country: country,
                        region: region,
                        isLocalResident: isResident,
                        hasVehicle: hasVehicle,
                        isHoused: isHoused,
                        isPrimary: isPrimary
                    )
                    context.insert(location)
                    locations.append(location)
                    seenCountries.insert(country)
                }
            }
        }
        
        contact.locations = locations
        context.insert(contact)
        try context.save()
        
        return contact
    }
    
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        var i = line.startIndex
        
        while i < line.endIndex {
            let char = line[i]
            
            if char == "\"" {
                if inQuotes && line.index(after: i) < line.endIndex && line[line.index(after: i)] == "\"" {
                    current += "\""
                    i = line.index(after: i)
                } else {
                    inQuotes.toggle()
                }
            } else if char == "," && !inQuotes {
                result.append(current)
                current = ""
            } else {
                current += String(char)
            }
            
            i = line.index(after: i)
        }
        
        result.append(current)
        return result
    }
    
    private func createContact(from exportData: ContactExportData, context: ModelContext) throws -> Contact {
        let newContact = Contact(
            name: exportData.contact.name,
            jobTitle: exportData.contact.jobTitle,
            phone: exportData.contact.phone,
            email: exportData.contact.email,
            notes: exportData.contact.notes,
            isFavorite: false
        )
        
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

enum ImportError: Error {
    case unsupportedFormat
    case invalidFormat
    
    var localizedDescription: String {
        switch self {
        case .unsupportedFormat:
            return "Format de fichier non supporté"
        case .invalidFormat:
            return "Format de fichier invalide"
        }
    }
}
