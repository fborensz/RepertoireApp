import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import Foundation
import AVFoundation

struct ImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var showingFilePicker = false
    @State private var importResult: ImportResult?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingDuplicateAlert = false
    @State private var duplicateContacts: [String] = []
    @State private var pendingImportData: (url: URL, contacts: [ContactExportData.ContactData])? = nil
    @State private var showingQRScanner = false
    
    struct ImportResult {
        let success: Bool
        let contactsImported: Int
        let message: String
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    Image(systemName: "square.and.arrow.down.on.square")
                        .font(.system(size: 50))
                        .foregroundColor(MyCrewColors.accent)
                    
                    Text("Importer des contacts")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(MyCrewColors.textPrimary)
                    
                    Text("Scannez un QR Code MyCrew ou sélectionnez un fichier")
                        .font(.body)
                        .foregroundColor(MyCrewColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                // Bouton Scanner QR Code
                Button {
                    showingQRScanner = true
                } label: {
                    HStack {
                        Image(systemName: "qrcode.viewfinder")
                        Text("Scanner un QR Code MyCrew")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(MyCrewColors.accent)
                    .cornerRadius(10)
                }
                
                // Séparateur
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(MyCrewColors.textSecondary.opacity(0.3))
                    Text("ou")
                        .font(.subheadline)
                        .foregroundColor(MyCrewColors.textSecondary)
                        .padding(.horizontal)
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(MyCrewColors.textSecondary.opacity(0.3))
                }
                
                VStack(spacing: 12) {
                    Text("Importer un fichier :")
                        .font(.headline)
                        .foregroundColor(MyCrewColors.textPrimary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Fichiers JSON (.json)", systemImage: "doc.text")
                            .foregroundColor(MyCrewColors.textSecondary)
                        Label("Fichiers CSV (.csv)", systemImage: "tablecells")
                            .foregroundColor(MyCrewColors.textSecondary)
                        Label("Contacts iOS (.vcf)", systemImage: "person.crop.circle")
                            .foregroundColor(MyCrewColors.textSecondary)
                    }
                }
                .padding()
                .background(MyCrewColors.cardBackground)
                .cornerRadius(10)
                
                Button {
                    showingFilePicker = true
                } label: {
                    HStack {
                        Image(systemName: "folder")
                        Text("Choisir un fichier")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(MyCrewColors.accent)
                    .cornerRadius(10)
                }
                
                if let result = importResult {
                    VStack(spacing: 8) {
                        Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(result.success ? .green : .red)
                        
                        Text(result.success ? "Import réussi !" : "Erreur d'import")
                            .font(.headline)
                            .foregroundColor(result.success ? .green : .red)
                        
                        if result.success {
                            Text("\(result.contactsImported) contact(s) importé(s)")
                                .foregroundColor(MyCrewColors.textSecondary)
                        }
                        
                        Text(result.message)
                            .font(.caption)
                            .foregroundColor(MyCrewColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(MyCrewColors.cardBackground)
                    .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
            .background(MyCrewColors.background)
            .navigationTitle("Import")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundColor(MyCrewColors.accent)
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [
                UTType.json,
                UTType.commaSeparatedText,
                UTType(filenameExtension: "vcf")!,
                UTType(filenameExtension: "vcard")!
            ],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .fullScreenCover(isPresented: $showingQRScanner) {
            QRCodeScannerView(
                onQRCodeScanned: { qrString in
                    showingQRScanner = false
                    handleQRCodeScanned(qrString)
                },
                onDismiss: {
                    showingQRScanner = false
                }
            )
        }
        .alert("Import", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .alert("Contacts en doublon détectés", isPresented: $showingDuplicateAlert) {
            Button("Annuler", role: .cancel) {
                pendingImportData = nil
            }
            Button("Continuer", role: .destructive) {
                if let pendingData = pendingImportData {
                    proceedWithImport(url: pendingData.url, contacts: pendingData.contacts, replaceDuplicates: true)
                }
            }
        } message: {
            Text("Ces contacts existent déjà dans votre liste :\n\(duplicateContacts.joined(separator: "\n"))\n\nÊtes-vous sûr de vouloir continuer l'import ? Cela écrasera les anciens contacts et des informations risquent d'être perdues.")
        }
    }
    
    // NOUVELLE FONCTION : Gestion du QR Code scanné
    private func handleQRCodeScanned(_ qrString: String) {
        guard let contactData = QRCodeGenerator.shared.parseQRCodeData(qrString) else {
            importResult = ImportResult(
                success: false,
                contactsImported: 0,
                message: "QR Code non reconnu ou invalide"
            )
            return
        }
        
        // Vérifier les doublons
        do {
            let fetchDescriptor = FetchDescriptor<Contact>()
            let existingContacts = try context.fetch(fetchDescriptor)
            let existingNames = Set(existingContacts.map { $0.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) })
            
            let contactKey = contactData.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            
            if existingNames.contains(contactKey) {
                duplicateContacts = [contactData.name]
                pendingImportData = (URL(fileURLWithPath: "qr_code"), [contactData])
                showingDuplicateAlert = true
            } else {
                importQRContact(contactData)
            }
        } catch {
            importResult = ImportResult(
                success: false,
                contactsImported: 0,
                message: "Erreur lors de la vérification des doublons"
            )
        }
    }
    
    private func importQRContact(_ contactData: ContactExportData.ContactData) {
        do {
            // Créer le nouveau contact
            let newContact = Contact(
                name: contactData.name,
                jobTitle: contactData.jobTitle,
                phone: contactData.phone,
                email: contactData.email,
                notes: contactData.notes,
                isFavorite: false
            )
            
            var workLocations: [WorkLocation] = []
            for locationData in contactData.locations {
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
            
            importResult = ImportResult(
                success: true,
                contactsImported: 1,
                message: "Contact importé depuis QR Code !"
            )
            
        } catch {
            importResult = ImportResult(
                success: false,
                contactsImported: 0,
                message: "Erreur lors de l'import : \(error.localizedDescription)"
            )
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Démarrer l'accès sécurisé au fichier
            guard url.startAccessingSecurityScopedResource() else {
                importResult = ImportResult(
                    success: false,
                    contactsImported: 0,
                    message: "Impossible d'accéder au fichier sélectionné"
                )
                return
            }
            
            // S'assurer d'arrêter l'accès même en cas d'erreur
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            do {
                // Lire et parser le fichier d'abord
                let contacts = try parseImportFile(from: url)
                
                // Vérifier les doublons
                let fetchDescriptor = FetchDescriptor<Contact>()
                let existingContacts = try context.fetch(fetchDescriptor)
                let existingNames = Set(existingContacts.map { $0.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) })
                
                let duplicates = contacts.filter { contact in
                    existingNames.contains(contact.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))
                }
                
                if !duplicates.isEmpty {
                    duplicateContacts = duplicates.map { $0.name }
                    pendingImportData = (url: url, contacts: contacts)
                    showingDuplicateAlert = true
                } else {
                    proceedWithImport(url: url, contacts: contacts, replaceDuplicates: false)
                }
                
            } catch let error as ImportError {
                importResult = ImportResult(
                    success: false,
                    contactsImported: 0,
                    message: error.localizedDescription
                )
            } catch {
                importResult = ImportResult(
                    success: false,
                    contactsImported: 0,
                    message: "Erreur lors de l'import : \(error.localizedDescription)"
                )
            }
            
        case .failure(let error):
            alertMessage = "Erreur lors de la sélection du fichier : \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    // Parser principal avec support vCard
    private func parseImportFile(from url: URL) throws -> [ContactExportData.ContactData] {
        print("🔍 Début parsing du fichier : \(url.lastPathComponent)")
        
        let data = try Data(contentsOf: url)
        print("📊 Taille des données : \(data.count) bytes")
        
        let fileExtension = url.pathExtension.lowercased()
        print("📁 Extension détectée : \(fileExtension)")
        
        switch fileExtension {
        case "vcf", "vcard":
            print("📱 Tentative de parsing vCard (contact iOS)...")
            return try parseVCardData(data)
            
        case "json":
            print("🔄 Tentative de parsing JSON...")
            
            // Debug : afficher le début du JSON
            if let preview = String(data: data.prefix(300), encoding: .utf8) {
                print("📄 Aperçu JSON : \(preview)")
            }
            
            // Test si c'est du JSON valide
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                print("✅ JSON syntaxiquement valide")
                
                if let dict = jsonObject as? [String: Any] {
                    print("📋 Clés disponibles: \(Array(dict.keys))")
                    
                    // Vérifier le format attendu
                    if dict["contacts"] != nil {
                        print("🎯 Format ContactListExport détecté")
                    } else if dict["contact"] != nil {
                        print("🎯 Format ContactExportData détecté")
                    } else {
                        print("❓ Format non reconnu")
                    }
                }
            } catch {
                print("❌ JSON invalide : \(error)")
                throw ImportError.invalidFormat
            }
            
            // Essayer d'abord comme liste de contacts
            do {
                let listData = try JSONDecoder().decode(ContactListExport.self, from: data)
                print("✅ Réussi : Liste de \(listData.contacts.count) contacts")
                return listData.contacts
            } catch let error1 {
                print("❌ Échec liste contacts : \(error1)")
                
                // Sinon essayer comme contact unique
                do {
                    let singleContactData = try JSONDecoder().decode(ContactExportData.self, from: data)
                    print("✅ Réussi : Contact unique")
                    return [singleContactData.contact]
                } catch let error2 {
                    print("❌ Échec contact unique : \(error2)")
                    
                    // Essayer un parsing manuel plus tolérant
                    if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let contactsArray = dict["contacts"] as? [[String: Any]] {
                        print("🔧 Tentative de parsing manuel...")
                        return try parseContactsManually(contactsArray)
                    }
                    
                    throw ImportError.invalidFormat
                }
            }
            
        case "csv":
            print("🔄 Tentative de parsing CSV...")
            return try parseCSVData(data)
            
        default:
            print("❌ Extension non supportée : \(fileExtension)")
            throw ImportError.unsupportedFormat
        }
    }
    
    // Parser pour fichiers vCard
    private func parseVCardData(_ data: Data) throws -> [ContactExportData.ContactData] {
        guard let content = String(data: data, encoding: .utf8) else {
            throw ImportError.invalidFormat
        }
        
        print("📱 Contenu vCard détecté")
        
        // Séparer les contacts multiples si nécessaire
        let vCards = content.components(separatedBy: "BEGIN:VCARD")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        var contacts: [ContactExportData.ContactData] = []
        
        for vCardContent in vCards {
            let fullVCard = "BEGIN:VCARD" + vCardContent
            if let contact = parseIndividualVCard(fullVCard) {
                contacts.append(contact)
            }
        }
        
        print("✅ Parsed \(contacts.count) contact(s) depuis vCard")
        return contacts
    }
    
    // Parser pour un vCard individuel
    private func parseIndividualVCard(_ vCardContent: String) -> ContactExportData.ContactData? {
        let lines = vCardContent.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var name = ""
        var phone = ""
        var email = ""
        var organization = ""
        var notes = ""
        
        for line in lines {
            // Nom complet
            if line.hasPrefix("FN:") {
                name = String(line.dropFirst(3))
            }
            // Nom structuré (backup si pas de FN)
            else if line.hasPrefix("N:") && name.isEmpty {
                let nameComponents = String(line.dropFirst(2)).components(separatedBy: ";")
                let lastName = nameComponents.first ?? ""
                let firstName = nameComponents.count > 1 ? nameComponents[1] : ""
                name = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
            }
            // Téléphone
            else if line.hasPrefix("TEL:") || line.contains("TEL;") {
                phone = extractVCardValue(from: line, prefix: "TEL")
            }
            // Email
            else if line.hasPrefix("EMAIL:") || line.contains("EMAIL;") {
                email = extractVCardValue(from: line, prefix: "EMAIL")
            }
            // Organisation
            else if line.hasPrefix("ORG:") {
                organization = String(line.dropFirst(4))
            }
            // Notes
            else if line.hasPrefix("NOTE:") {
                notes = String(line.dropFirst(5))
            }
        }
        
        // Validation minimale
        guard !name.isEmpty else {
            print("⚠️ vCard ignoré : nom manquant")
            return nil
        }
        
        // Créer une note enrichie avec l'organisation
        var enrichedNotes = notes
        if !organization.isEmpty {
            enrichedNotes = enrichedNotes.isEmpty ?
                "Organisation: \(organization)" :
                "\(notes)\nOrganisation: \(organization)"
        }
        enrichedNotes += enrichedNotes.isEmpty ?
            "Importé depuis Contacts iOS" :
            "\nImporté depuis Contacts iOS"
        
        // Lieu par défaut
        let defaultLocation = ContactExportData.ContactData.LocationData(
            country: "Worldwide",
            region: nil,
            isLocalResident: false,
            hasVehicle: false,
            isHoused: false,
            isPrimary: true
        )
        
        let contact = ContactExportData.ContactData(
            name: name,
            jobTitle: JobTitles.defaultJob, // "À définir"
            phone: phone,
            email: email,
            notes: enrichedNotes,
            isFavorite: false,
            locations: [defaultLocation]
        )
        
        print("📱 Contact vCard parsé: \(name)")
        return contact
    }
    
    // Utilitaire pour extraire les valeurs vCard
    private func extractVCardValue(from line: String, prefix: String) -> String {
        if line.hasPrefix("\(prefix):") {
            return String(line.dropFirst(prefix.count + 1))
        } else if line.contains("\(prefix);") {
            // Format avec paramètres: TEL;TYPE=HOME:+33123456789
            if let colonIndex = line.firstIndex(of: ":") {
                return String(line[line.index(after: colonIndex)...])
            }
        }
        return ""
    }
    
    // Parsing manuel pour plus de tolérance
    private func parseContactsManually(_ contactsArray: [[String: Any]]) throws -> [ContactExportData.ContactData] {
        var contacts: [ContactExportData.ContactData] = []
        
        for contactDict in contactsArray {
            guard let name = contactDict["name"] as? String,
                  let jobTitle = contactDict["jobTitle"] as? String else {
                continue
            }
            
            let phone = contactDict["phone"] as? String ?? ""
            let email = contactDict["email"] as? String ?? ""
            let notes = contactDict["notes"] as? String ?? ""
            let isFavorite = contactDict["isFavorite"] as? Bool ?? false
            
            var locations: [ContactExportData.ContactData.LocationData] = []
            
            if let locationsArray = contactDict["locations"] as? [[String: Any]] {
                for locationDict in locationsArray {
                    let country = locationDict["country"] as? String ?? "Worldwide"
                    let region = locationDict["region"] as? String
                    let isLocalResident = locationDict["isLocalResident"] as? Bool ?? false
                    let hasVehicle = locationDict["hasVehicle"] as? Bool ?? false
                    let isHoused = locationDict["isHoused"] as? Bool ?? false
                    let isPrimary = locationDict["isPrimary"] as? Bool ?? false
                    
                    let location = ContactExportData.ContactData.LocationData(
                        country: country,
                        region: region,
                        isLocalResident: isLocalResident,
                        hasVehicle: hasVehicle,
                        isHoused: isHoused,
                        isPrimary: isPrimary
                    )
                    locations.append(location)
                }
            }
            
            let contact = ContactExportData.ContactData(
                name: name,
                jobTitle: jobTitle,
                phone: phone,
                email: email,
                notes: notes,
                isFavorite: isFavorite,
                locations: locations
            )
            contacts.append(contact)
        }
        
        return contacts
    }
    
    private func parseCSVData(_ data: Data) throws -> [ContactExportData.ContactData] {
        guard let content = String(data: data, encoding: .utf8) else {
            throw ImportError.invalidFormat
        }
        
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty && !$0.hasPrefix("#") }
        
        guard lines.count > 1 else {
            throw ImportError.invalidFormat
        }
        
        var contactsDict: [String: (name: String, jobTitle: String, phone: String, email: String, notes: String, locations: [ContactExportData.ContactData.LocationData])] = [:]
        
        // Traiter chaque ligne de données (ignorer l'en-tête)
        for i in 1..<lines.count {
            let line = lines[i]
            let columns = parseCSVLine(line)
            
            guard columns.count >= 10 else { continue }
            
            let contactName = columns[0]
            
            // Si le contact n'existe pas encore, le créer
            if contactsDict[contactName] == nil {
                contactsDict[contactName] = (
                    name: columns[0],
                    jobTitle: columns[1],
                    phone: columns[2],
                    email: columns[3],
                    notes: columns[10],
                    locations: []
                )
            }
            
            // Ajouter le lieu s'il n'est pas vide
            let country = columns[4]
            if !country.isEmpty {
                let region = columns[5].isEmpty ? nil : columns[5]
                let hasVehicle = columns[6].lowercased() == "oui"
                let isHoused = columns[7].lowercased() == "oui"
                let isResident = columns[8].lowercased() == "oui"
                let isPrimary = columns[9].lowercased().contains("principal")
                
                let locationData = ContactExportData.ContactData.LocationData(
                    country: country,
                    region: region,
                    isLocalResident: isResident,
                    hasVehicle: hasVehicle,
                    isHoused: isHoused,
                    isPrimary: isPrimary
                )
                
                contactsDict[contactName]!.locations.append(locationData)
            }
        }
        
        // Convertir en ContactData
        return contactsDict.values.map { contactInfo in
            ContactExportData.ContactData(
                name: contactInfo.name,
                jobTitle: contactInfo.jobTitle,
                phone: contactInfo.phone,
                email: contactInfo.email,
                notes: contactInfo.notes,
                isFavorite: false,
                locations: contactInfo.locations
            )
        }
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
    
    private func proceedWithImport(url: URL, contacts: [ContactExportData.ContactData], replaceDuplicates: Bool) {
        do {
            var importedCount = 0
            
            // Récupérer les contacts existants si on doit remplacer
            let fetchDescriptor = FetchDescriptor<Contact>()
            let existingContacts = try context.fetch(fetchDescriptor)
            let existingContactsMap = Dictionary(uniqueKeysWithValues: existingContacts.map {
                ($0.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines), $0)
            })
            
            for contactData in contacts {
                let contactKey = contactData.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                
                if replaceDuplicates, let existingContact = existingContactsMap[contactKey] {
                    // Supprimer l'ancien contact et ses lieux
                    for location in existingContact.locations {
                        context.delete(location)
                    }
                    context.delete(existingContact)
                }
                
                // Créer le nouveau contact
                let newContact = Contact(
                    name: contactData.name,
                    jobTitle: contactData.jobTitle,
                    phone: contactData.phone,
                    email: contactData.email,
                    notes: contactData.notes,
                    isFavorite: false
                )
                
                var workLocations: [WorkLocation] = []
                for locationData in contactData.locations {
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
                importedCount += 1
            }
            
            try context.save()
            
            importResult = ImportResult(
                success: true,
                contactsImported: importedCount,
                message: replaceDuplicates ?
                    "Les contacts ont été importés et les doublons remplacés" :
                    "Les contacts ont été ajoutés avec succès"
            )
            
            pendingImportData = nil
            
        } catch {
            importResult = ImportResult(
                success: false,
                contactsImported: 0,
                message: "Erreur lors de l'import : \(error.localizedDescription)"
            )
        }
    }
}
