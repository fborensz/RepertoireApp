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

// Structure pour l'export/import de listes de contacts
struct ContactListExport: Codable {
    let version: String
    let exportDate: Date
    let totalContacts: Int
    let filterDescription: String
    let contacts: [ContactExportData.ContactData]
    
    init(contacts: [ContactExportData.ContactData], filterDescription: String = "Tous les contacts") {
        self.version = "1.0"
        self.exportDate = Date()
        self.totalContacts = contacts.count
        self.filterDescription = filterDescription
        self.contacts = contacts
    }
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
    
    // Export d'une liste de contacts
    func exportContactList(_ contacts: [Contact], format: ExportFormat, filterDescription: String = "Contacts sélectionnés") -> (content: Any?, isFile: Bool) {
        switch format {
        case .text:
            return (exportContactListAsText(contacts, filterDescription: filterDescription), false)
        case .csv:
            return (exportContactListAsCSV(contacts, filterDescription: filterDescription), true)
        case .json:
            return (exportContactListAsJSON(contacts, filterDescription: filterDescription), true)
        }
    }
    
    // Export selon le format choisi (contact unique - conservé pour compatibilité)
    func exportContact(_ contact: Contact, format: ExportFormat) -> (content: Any?, isFile: Bool) {
        return exportContactList([contact], format: format, filterDescription: "Contact individuel")
    }
    
    // Export de liste en texte lisible
    private func exportContactListAsText(_ contacts: [Contact], filterDescription: String) -> String {
        var text = "📋 LISTE CONTACTS - RÉPERTOIRE\n"
        text += "===============================\n\n"
        text += "📊 FILTRE: \(filterDescription)\n"
        text += "👥 NOMBRE: \(contacts.count) contact(s)\n"
        text += "📅 EXPORTÉ LE: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))\n\n"
        
        for (index, contact) in contacts.enumerated() {
            text += "▼ CONTACT \(index + 1)/\(contacts.count)\n"
            text += "================================\n"
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
            for (locIndex, location) in contact.secondaryLocations.enumerated() {
                text += "• SECONDAIRE \(locIndex + 1): \(location.country)"
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
            
            if index < contacts.count - 1 {
                text += "\n" + String(repeating: "=", count: 32) + "\n\n"
            }
        }
        
        text += "\n================================\n"
        text += "Exporté depuis Répertoire App"
        
        return text
    }
    
    // Export de liste en CSV
    private func exportContactListAsCSV(_ contacts: [Contact], filterDescription: String) -> URL? {
        var csvContent = "# Filtre: \(filterDescription)\n"
        csvContent += "# Nombre de contacts: \(contacts.count)\n"
        csvContent += "# Exporté le: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))\n\n"
        csvContent += "Nom,Poste,Telephone,Email,Pays,Region,Vehicule,Loge,Residence_Fiscale,Type_Lieu,Notes\n"
        
        for contact in contacts {
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
        }
        
        // Créer un nom de fichier intelligent
        let fileName = generateIntelligentFileName(for: contacts, format: "csv", filterDescription: filterDescription)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Erreur lors de l'export CSV: \(error)")
            return nil
        }
    }
    
    // Export de liste en JSON
    private func exportContactListAsJSON(_ contacts: [Contact], filterDescription: String) -> URL? {
        do {
            let contactsData = contacts.map { contact in
                contact.toExportData().contact
            }
            
            let listExport = ContactListExport(
                contacts: contactsData,
                filterDescription: filterDescription
            )
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(listExport)
            
            let fileName = generateIntelligentFileName(for: contacts, format: "json", filterDescription: filterDescription)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            
            try jsonData.write(to: tempURL)
            return tempURL
            
        } catch {
            print("Erreur lors de l'export JSON: \(error)")
            return nil
        }
    }
    
    // Générer un nom de fichier intelligent basé sur les filtres
    private func generateIntelligentFileName(for contacts: [Contact], format: String, filterDescription: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        var components: [String] = []
        
        // Analyser la description des filtres pour extraire les éléments clés
        if filterDescription.contains("Poste:") {
            if let jobRange = filterDescription.range(of: "Poste: ([^•]+)", options: .regularExpression) {
                let job = String(filterDescription[jobRange]).replacingOccurrences(of: "Poste: ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                let cleanJob = job.replacingOccurrences(of: " ", with: "_")
                    .replacingOccurrences(of: "[^a-zA-Z0-9_-]", with: "", options: .regularExpression)
                if !cleanJob.isEmpty {
                    components.append(cleanJob)
                }
            }
        }
        
        if filterDescription.contains("Pays:") {
            if let countryRange = filterDescription.range(of: "Pays: ([^•]+)", options: .regularExpression) {
                let country = String(filterDescription[countryRange]).replacingOccurrences(of: "Pays: ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                let cleanCountry = country.replacingOccurrences(of: " ", with: "_")
                if !cleanCountry.isEmpty {
                    components.append(cleanCountry)
                }
            }
        }
        
        if filterDescription.contains("Régions:") {
            if let regionsRange = filterDescription.range(of: "Régions: ([^•]+)", options: .regularExpression) {
                let regions = String(filterDescription[regionsRange]).replacingOccurrences(of: "Régions: ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                let regionCount = regions.split(separator: ",").count
                if regionCount == 1 {
                    let cleanRegion = regions.replacingOccurrences(of: " ", with: "_")
                        .replacingOccurrences(of: "[^a-zA-Z0-9_-]", with: "", options: .regularExpression)
                    components.append(cleanRegion)
                } else if regionCount > 1 {
                    components.append("\(regionCount)_regions")
                }
            }
        }
        
        // Si aucun filtre spécifique, utiliser un nom générique
        if components.isEmpty {
            components.append("Contacts")
        }
        
        // Ajouter le nombre de contacts et la date
        components.append("\(contacts.count)_contacts")
        components.append(dateString)
        
        let fileName = components.joined(separator: "_") + ".\(format)"
        
        // Nettoyer le nom de fichier final
        return fileName.replacingOccurrences(of: "__", with: "_")
    }
    
    // Import d'un contact ou d'une liste depuis URL (JSON ou CSV)
    func importContacts(from url: URL, context: ModelContext) throws -> [Contact] {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "json":
            return try importFromJSONFile(url: url, context: context)
        case "csv":
            return try importFromCSVFile(url: url, context: context)
        default:
            throw ImportError.unsupportedFormat
        }
    }
    
    private func importFromJSONFile(url: URL, context: ModelContext) throws -> [Contact] {
        let data = try Data(contentsOf: url)
        
        // Essayer d'abord comme liste de contacts
        if let listData = try? JSONDecoder().decode(ContactListExport.self, from: data) {
            var importedContacts: [Contact] = []
            
            for contactData in listData.contacts {
                let exportData = ContactExportData(contact: contactData)
                let contact = try createContact(from: exportData, context: context)
                importedContacts.append(contact)
            }
            
            return importedContacts
        }
        
        // Sinon essayer comme contact unique
        if let singleContactData = try? JSONDecoder().decode(ContactExportData.self, from: data) {
            let contact = try createContact(from: singleContactData, context: context)
            return [contact]
        }
        
        throw ImportError.invalidFormat
    }
    
    private func importFromCSVFile(url: URL, context: ModelContext) throws -> [Contact] {
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty && !$0.hasPrefix("#") }
        
        guard lines.count > 1 else {
            throw ImportError.invalidFormat
        }
        
        var contactsDict: [String: (contact: Contact, locations: [WorkLocation])] = [:]
        
        // Traiter chaque ligne de données (ignorer l'en-tête)
        for i in 1..<lines.count {
            let line = lines[i]
            let columns = parseCSVLine(line)
            
            guard columns.count >= 10 else { continue }
            
            let contactName = columns[0]
            
            // Si le contact n'existe pas encore, le créer
            if contactsDict[contactName] == nil {
                let contact = Contact(
                    name: columns[0],
                    jobTitle: columns[1],
                    phone: columns[2],
                    email: columns[3],
                    notes: columns[10],
                    isFavorite: false
                )
                context.insert(contact)
                contactsDict[contactName] = (contact: contact, locations: [])
            }
            
            // Ajouter le lieu s'il n'est pas vide
            let country = columns[4]
            if !country.isEmpty {
                let region = columns[5].isEmpty ? nil : columns[5]
                let hasVehicle = columns[6].lowercased() == "oui"
                let isHoused = columns[7].lowercased() == "oui"
                let isResident = columns[8].lowercased() == "oui"
                let isPrimary = columns[9].lowercased().contains("principal")
                
                // Vérifier si ce lieu existe déjà pour ce contact
                let existingLocations = contactsDict[contactName]!.locations
                let locationExists = existingLocations.contains { location in
                    location.country == country && location.region == region
                }
                
                if !locationExists {
                    let location = WorkLocation(
                        country: country,
                        region: region,
                        isLocalResident: isResident,
                        hasVehicle: hasVehicle,
                        isHoused: isHoused,
                        isPrimary: isPrimary
                    )
                    context.insert(location)
                    contactsDict[contactName]!.locations.append(location)
                }
            }
        }
        
        // Assigner les lieux aux contacts
        var importedContacts: [Contact] = []
        for (_, contactInfo) in contactsDict {
            contactInfo.contact.locations = contactInfo.locations
            importedContacts.append(contactInfo.contact)
        }
        
        try context.save()
        return importedContacts
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
