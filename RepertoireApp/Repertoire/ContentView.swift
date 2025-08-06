// ContentView.swift - Version complète avec génération de données de test
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query private var contacts: [Contact]
    @State private var hasPerformedCleanup = false
    @State private var showingFilters = false
    @State private var showingImport = false
    @State private var showingListExportOptions = false
    @State private var currentFilters = FilterSettings()
    
    // Structure pour les filtres
    struct FilterSettings {
        var selectedJob = "Tous"
        var selectedCountry = "Tous"
        var selectedRegions: Set<String> = []
        var includeVehicle = false
        var includeHoused = false
        var includeResident = false
    }

    // Contacts filtrés et triés par ordre alphabétique
    private var filteredAndSortedContacts: [Contact] {
        let filtered = filteredContacts
        return filtered.sorted { contact1, contact2 in
            // Favoris en premier, puis alphabétique
            if contact1.isFavorite && !contact2.isFavorite {
                return true
            } else if !contact1.isFavorite && contact2.isFavorite {
                return false
            } else {
                return contact1.name.localizedCaseInsensitiveCompare(contact2.name) == .orderedAscending
            }
        }
    }
    
    // Contacts groupés par lettre pour l'index alphabétique
    private var groupedContacts: [(String, [Contact])] {
        let grouped = Dictionary(grouping: filteredAndSortedContacts) { contact in
            String(contact.name.prefix(1).uppercased())
        }
        return grouped.sorted { $0.key < $1.key }
    }
    
    // Lettres disponibles pour l'index
    private var availableLetters: [String] {
        return groupedContacts.map { $0.0 }
    }
    
    // Logique de filtrage
    private var filteredContacts: [Contact] {
        if !hasActiveFilters {
            return contacts
        }
        
        return contacts.filter { contact in
            return matchesFilters(contact: contact)
        }
    }
    
    private var hasActiveFilters: Bool {
        currentFilters.selectedJob != "Tous" ||
        currentFilters.selectedCountry != "Tous" ||
        !currentFilters.selectedRegions.isEmpty ||
        currentFilters.includeVehicle ||
        currentFilters.includeHoused ||
        currentFilters.includeResident
    }
    
    private func matchesFilters(contact: Contact) -> Bool {
        // Métier
        if currentFilters.selectedJob != "Tous" {
            if contact.jobTitle != currentFilters.selectedJob {
                return false
            }
        }
        
        // Pays et régions
        if currentFilters.selectedCountry != "Tous" {
            // Trouver les lieux qui correspondent au pays sélectionné
            let matchingLocations = contact.locations.filter { $0.country == currentFilters.selectedCountry }
            
            if matchingLocations.isEmpty {
                return false // Pas de lieu dans ce pays
            }
            
            // Si des régions sont sélectionnées (et que c'est la France), vérifier qu'AU MOINS une région correspond
            if currentFilters.selectedCountry == "France" && !currentFilters.selectedRegions.isEmpty {
                let hasMatchingRegion = matchingLocations.contains { location in
                    if let region = location.region {
                        return currentFilters.selectedRegions.contains(region)
                    }
                    return false
                }
                if !hasMatchingRegion { return false }
            }
            
            // Si des attributs sont sélectionnés, vérifier qu'ils existent dans ce pays/région
            if currentFilters.includeVehicle {
                let hasVehicleInLocation = matchingLocations.contains { $0.hasVehicle }
                if !hasVehicleInLocation { return false }
            }
            
            if currentFilters.includeHoused {
                let isHousedInLocation = matchingLocations.contains { $0.isHoused }
                if !isHousedInLocation { return false }
            }
            
            if currentFilters.includeResident {
                let isResidentInLocation = matchingLocations.contains { $0.isLocalResident }
                if !isResidentInLocation { return false }
            }
        } else {
            // Pas de filtre pays, mais des attributs sélectionnés
            if currentFilters.includeVehicle {
                let hasVehicle = contact.locations.contains { $0.hasVehicle }
                if !hasVehicle { return false }
            }
            
            if currentFilters.includeHoused {
                let isHoused = contact.locations.contains { $0.isHoused }
                if !isHoused { return false }
            }
            
            if currentFilters.includeResident {
                let isResident = contact.locations.contains { $0.isLocalResident }
                if !isResident { return false }
            }
        }
        
        return true
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Barre de filtres
                HStack {
                    Button {
                        showingFilters.toggle()
                    } label: {
                        HStack {
                            Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .foregroundColor(hasActiveFilters ? .blue : .secondary)
                            Text("Filtres")
                                .foregroundColor(hasActiveFilters ? .blue : .secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if hasActiveFilters {
                        Button("Tout effacer") {
                            currentFilters = FilterSettings()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                    
                    if !contacts.isEmpty {
                        Button {
                            showingListExportOptions = true
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up.on.square")
                                    .font(.caption)
                                Text("Exporter")
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Filtres actifs
                if hasActiveFilters {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            if currentFilters.selectedJob != "Tous" {
                                FilterChip(title: currentFilters.selectedJob, icon: "briefcase.fill") {
                                    currentFilters.selectedJob = "Tous"
                                }
                            }
                            if currentFilters.selectedCountry != "Tous" {
                                FilterChip(title: currentFilters.selectedCountry, icon: "location.fill") {
                                    currentFilters.selectedCountry = "Tous"
                                    currentFilters.selectedRegions.removeAll()
                                }
                            }
                            ForEach(Array(currentFilters.selectedRegions), id: \.self) { region in
                                FilterChip(title: region, icon: "map.fill") {
                                    currentFilters.selectedRegions.remove(region)
                                }
                            }
                            if currentFilters.includeVehicle {
                                FilterChip(title: "Véhiculé", icon: "car.fill") {
                                    currentFilters.includeVehicle = false
                                }
                            }
                            if currentFilters.includeHoused {
                                FilterChip(title: "Logé", icon: "house.fill") {
                                    currentFilters.includeHoused = false
                                }
                            }
                            if currentFilters.includeResident {
                                FilterChip(title: "Résidence fiscale", icon: "building.columns.fill") {
                                    currentFilters.includeResident = false
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }
                
                // Liste des contacts
                Group {
                    if filteredAndSortedContacts.isEmpty && !contacts.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("Aucun résultat")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("Essayez d'ajuster vos filtres")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if contacts.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "person.3")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("Aucun contact")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("Appuyez sur + pour ajouter votre premier contact")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        HStack(spacing: 0) {
                            // Liste principale avec sections alphabétiques
                            List {
                                ForEach(groupedContacts, id: \.0) { letter, contactsInGroup in
                                    Section(header: Text(letter).font(.headline).foregroundColor(.blue)) {
                                        ForEach(contactsInGroup) { contact in
                                            NavigationLink(destination: ContactDetailView(contact: contact)) {
                                                ContactRowView(contact: contact)
                                            }
                                        }
                                    }
                                }
                            }
                            .listStyle(PlainListStyle())
                            
                            // Index alphabétique sur le côté droit
                            if !availableLetters.isEmpty && availableLetters.count > 1 {
                                VStack(spacing: 2) {
                                    ForEach(availableLetters, id: \.self) { letter in
                                        Button(letter) {
                                            // Scroll vers la section de cette lettre
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                // Note: Le scroll programmatique nécessiterait ScrollViewReader
                                                // Pour l'instant, on affiche juste l'index visuel
                                            }
                                        }
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                        .frame(width: 20, height: 16)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.trailing, 8)
                                .padding(.vertical)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Mes Contacts")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack {
                        if !contacts.isEmpty {
                            Text("\(filteredAndSortedContacts.count)/\(contacts.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Button {
                            showingImport = true
                        } label: {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.blue)
                        }
                        
                        // Bouton temporaire pour les tests
                        Button("🧪") {
                            generateTestData()
                        }
                        .font(.caption)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: AddContactView()) {
                        Label("Ajouter", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                ContentFiltersView(filters: $currentFilters)
            }
            .sheet(isPresented: $showingImport) {
                ContactImportView()
            }
            .actionSheet(isPresented: $showingListExportOptions) {
                ActionSheet(
                    title: Text("Exporter la liste"),
                    message: Text("Exporter \(filteredAndSortedContacts.count) contact(s)"),
                    buttons: [
                        .default(Text("📱 Texte (Messages/WhatsApp)")) {
                            shareContactList(format: .text)
                        },
                        .default(Text("📊 CSV (Excel/Numbers)")) {
                            shareContactList(format: .csv)
                        },
                        .default(Text("💾 JSON (Sauvegarde complète)")) {
                            shareContactList(format: .json)
                        },
                        .cancel(Text("Annuler"))
                    ]
                )
            }
            .onAppear {
                if !hasPerformedCleanup {
                    cleanupData()
                    hasPerformedCleanup = true
                }
            }
        }
    }
    
    private func cleanupData() {
        print("🔧 Début du nettoyage des données...")
        
        for contact in contacts {
            // 1. Supprimer les doublons
            let uniqueLocations = removeDuplicateLocations(contact.locations)
            if uniqueLocations.count != contact.locations.count {
                print("🗑️ Suppression de doublons pour \(contact.name)")
                for location in contact.locations {
                    context.delete(location)
                }
                contact.locations = uniqueLocations
            }
            
            // 2. Vérifier les lieux principaux
            let primaryCount = contact.locations.filter { $0.isPrimary }.count
            
            if primaryCount == 0 && !contact.locations.isEmpty {
                print("✅ Définition du lieu principal pour \(contact.name)")
                contact.locations[0].isPrimary = true
            } else if primaryCount > 1 {
                print("🔄 Correction des lieux principaux multiples pour \(contact.name)")
                for (index, location) in contact.locations.enumerated() {
                    location.isPrimary = (index == 0)
                }
            }
            
            // 3. Créer un lieu par défaut si aucun
            if contact.locations.isEmpty {
                print("📍 Création d'un lieu par défaut pour \(contact.name)")
                let defaultLocation = WorkLocation(
                    country: "Worldwide",
                    isPrimary: true
                )
                context.insert(defaultLocation)
                contact.locations = [defaultLocation]
            }
        }
        
        do {
            try context.save()
            print("✅ Nettoyage terminé avec succès")
        } catch {
            print("❌ Erreur lors de la sauvegarde: \(error)")
        }
    }
    
    private func removeDuplicateLocations(_ locations: [WorkLocation]) -> [WorkLocation] {
        var seen = Set<String>()
        var uniqueLocations: [WorkLocation] = []
        
        for location in locations {
            let key = "\(location.country)-\(location.region ?? "")-\(location.isHoused)-\(location.hasVehicle)-\(location.isLocalResident)"
            if !seen.contains(key) {
                seen.insert(key)
                uniqueLocations.append(location)
            }
        }
        
        return uniqueLocations
    }
    
    // Fonction pour générer une description des filtres actifs
    private func getFilterDescription() -> String {
        var description: [String] = []
        
        if currentFilters.selectedJob != "Tous" {
            description.append("Poste: \(currentFilters.selectedJob)")
        }
        
        if currentFilters.selectedCountry != "Tous" {
            description.append("Pays: \(currentFilters.selectedCountry)")
        }
        
        if !currentFilters.selectedRegions.isEmpty {
            let regions = Array(currentFilters.selectedRegions).sorted().joined(separator: ", ")
            description.append("Régions: \(regions)")
        }
        
        var attributes: [String] = []
        if currentFilters.includeVehicle { attributes.append("Véhiculé") }
        if currentFilters.includeHoused { attributes.append("Logé") }
        if currentFilters.includeResident { attributes.append("Résidence fiscale") }
        
        if !attributes.isEmpty {
            description.append("Attributs: \(attributes.joined(separator: ", "))")
        }
        
        return description.isEmpty ? "Tous les contacts" : description.joined(separator: " • ")
    }
    
    // Fonction pour partager une liste de contacts
    private func shareContactList(format: ExportFormat) {
        let filterDescription = getFilterDescription()
        let exportResult = ContactSharingManager.shared.exportContactList(
            filteredAndSortedContacts,
            format: format,
            filterDescription: filterDescription
        )
        
        var itemsToShare: [Any] = []
        
        if exportResult.isFile {
            // C'est un fichier (CSV ou JSON)
            if let fileURL = exportResult.content as? URL {
                itemsToShare.append(fileURL)
            } else {
                print("Erreur: Impossible de créer le fichier")
                return
            }
        } else {
            // C'est du texte
            if let text = exportResult.content as? String {
                itemsToShare.append(text)
            } else {
                print("Erreur: Impossible de créer le texte")
                return
            }
        }
        
        guard !itemsToShare.isEmpty else {
            print("Erreur lors de l'export")
            return
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: itemsToShare,
            applicationActivities: nil
        )
        
        // Adapter les activités selon le format
        switch format {
        case .text:
            activityViewController.excludedActivityTypes = [
                .assignToContact,
                .addToReadingList,
                .openInIBooks,
                .saveToCameraRoll
            ]
        case .csv, .json:
            activityViewController.excludedActivityTypes = [
                .assignToContact,
                .addToReadingList,
                .openInIBooks,
                .postToFacebook,
                .postToTwitter,
                .postToWeibo
            ]
        }
        
        // Pour iPad
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            if let popover = activityViewController.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootViewController.present(activityViewController, animated: true)
        }
    }
    
    // MARK: - Fonctions de génération de données de test
    
    private func generateTestData() {
        // Supprimer tous les contacts existants
        for contact in contacts {
            context.delete(contact)
        }
        
        let testContacts: [(String, String, String, String, String, Bool, String, String?, Bool, Bool, Bool)] = [
            ("Jean Dupont", "Réalisateur", "06 12 34 56 01", "j.dupont@cinema.fr", "Spécialiste films d'auteur, disponible septembre", false, "France", "Île-de-France", true, true, true),
            ("Marie Martin", "Chef opérateur", "06 23 45 67 02", "m.martin@image.fr", "Experte éclairage naturel, tournages extérieurs", true, "France", "Provence-Alpes-Côte d'Azur", true, true, false),
            ("Pierre Bernard", "Cadreur", "06 34 56 78 03", "p.bernard@image.pro", "Steadicam, drone, 15 ans d'expérience", false, "France", "Île-de-France", true, true, true),
            ("Sophie Dubois", "1er Assistant Caméra", "06 45 67 89 04", "s.dubois@focus.fr", "Précise, rapide, bonne entente équipe", true, "France", "Occitanie", true, true, true),
            ("Thomas Moreau", "Ingénieur du Son", "06 56 78 90 05", "t.moreau@sound.fr", "Matériel haut de gamme, mixage live", false, "France", "Bretagne", true, true, false),
            ("Camille Rousseau", "Perchman", "06 67 89 01 06", "c.rousseau@audio.fr", "Discrète, bonne condition physique", false, "France", "Île-de-France", true, false, true),
            ("Antoine Lefevre", "Chef Électro", "06 78 90 12 07", "a.lefevre@light.pro", "Équipe de 5 personnes, gros plateaux", true, "France", "Île-de-France", true, true, true),
            ("Julie Lambert", "Électro", "06 89 01 23 08", "j.lambert@electric.fr", "Spécialiste LED, éco-responsable", false, "France", "Auvergne-Rhône-Alpes", true, true, false),
            ("Nicolas Petit", "Chef Machiniste", "06 90 12 34 09", "n.petit@grip.fr", "Travelling, dolly, grues légères", false, "France", "Nouvelle-Aquitaine", true, true, true),
            ("Laura Garnier", "Machiniste", "06 01 23 45 10", "l.garnier@grip.pro", "Force, précision, bonne humeur", false, "France", "Grand Est", true, false, false),
            ("David Simon", "Régisseur Général", "06 12 34 56 11", "d.simon@regie.fr", "Organisé, relationnel, résout tout", true, "France", "Île-de-France", true, true, true),
            ("Emma Faure", "Assistant Régie", "06 23 45 67 12", "e.faure@assistant.fr", "Première expérience, motivée", false, "France", "Occitanie", true, false, false),
            ("Maxime Vincent", "Chef Décorateur", "06 34 56 78 13", "m.vincent@decor.fr", "Style vintage, attention aux détails", false, "France", "Pays de la Loire", true, true, true),
            ("Chloe Mercier", "Ensemblière", "06 45 67 89 14", "c.mercier@ensemble.fr", "Créative, budget serré OK", false, "France", "Normandie", true, true, false),
            ("Julien Blanc", "Chef Costumier", "06 56 78 90 15", "j.blanc@costume.fr", "Période, contemporain, retouches", true, "France", "Île-de-France", true, false, true),
            ("Alice Bonnet", "Habilleur", "06 67 89 01 16", "a.bonnet@wardrobe.fr", "Rapide, discrète, couture express", false, "France", "Centre-Val de Loire", true, false, false),
            ("Hugo Roux", "Chef Maquilleur", "06 78 90 12 17", "h.roux@makeup.fr", "Effets spéciaux, prothèses, beauté", false, "France", "Provence-Alpes-Côte d'Azur", true, true, true),
            ("Léa Girard", "Maquilleur", "06 89 01 23 18", "l.girard@beauty.fr", "Maquillage de jour, naturel", false, "France", "Bourgogne-Franche-Comté", true, true, false),
            ("Paul Morel", "Chef Coiffeur", "06 90 12 34 19", "p.morel@hair.fr", "Perruques, coiffures d'époque", false, "France", "Hauts-de-France", true, false, true),
            ("Manon Durand", "Producteur", "06 01 23 45 20", "m.durand@prod.fr", "Courts métrages, budgets créatifs", true, "France", "Île-de-France", true, true, true),
            ("Lucas Fontaine", "Directeur de Production", "06 12 34 56 21", "l.fontaine@direction.fr", "Expérience internationale, efficace", false, "France", "Île-de-France", true, true, true),
            ("Sarah Chevalier", "Monteur Image", "06 23 45 67 22", "s.chevalier@edit.fr", "Avid, Premiere, rythme dynamique", false, "France", "Île-de-France", true, false, true),
            ("Romain Gauthier", "Assistant Monteur", "06 34 56 78 23", "r.gauthier@assist.fr", "Organisation parfaite, backup sécurisé", false, "France", "Auvergne-Rhône-Alpes", true, true, false),
            ("Clara Leroux", "Étalonneur", "06 45 67 89 24", "c.leroux@color.fr", "DaVinci expert, look cinéma", true, "France", "Île-de-France", true, false, true),
            ("Benjamin Fournier", "Cascadeur", "06 56 78 90 25", "b.fournier@stunt.fr", "Combat, chute, conduite, assurance OK", false, "France", "Provence-Alpes-Côte d'Azur", true, true, false),
            ("Océane Michel", "Scripte", "06 67 89 01 26", "o.michel@script.fr", "Mémoire parfaite, rapports précis", false, "France", "Bretagne", true, true, true),
            ("Alexandre Roy", "1er Assistant Réalisateur", "06 78 90 12 27", "a.roy@assist.fr", "Leadership naturel, planning au top", true, "France", "Île-de-France", true, true, true),
            ("Inès André", "2e Assistant Réalisateur", "06 89 01 23 28", "i.andre@2nd.fr", "Casting figurants, coordination", false, "France", "Occitanie", true, false, false),
            ("Théo Masson", "Cadreur", "06 90 12 34 29", "t.masson@camera.be", "Spécialiste drone et underwater", false, "Belgique", nil, true, true, true),
            ("Zoé Sanchez", "Chef opérateur", "06 01 23 45 30", "z.sanchez@dop.es", "Style documentaire, lumière naturelle", false, "Espagne", nil, true, true, false),
            ("Amélie Lefebvre", "Cadreur", "06 12 34 56 34", "a.lefebvre@cam.fr", "Caméra épaule, reportage style", false, "France", "Île-de-France", true, true, false),
            ("Gabriel Moreau", "Cadreur", "06 23 45 67 35", "g.moreau@steadicam.fr", "Steadicam expert, mouvements fluides", true, "France", "Provence-Alpes-Côte d'Azur", true, true, true),
            ("Valentine Dubois", "Cadreur", "06 34 56 78 36", "v.dubois@focus.fr", "Jeune, dynamique, formations récentes", false, "France", "Auvergne-Rhône-Alpes", true, false, false),
            ("Martin Petit", "Cadreur", "06 45 67 89 37", "m.petit@drone.fr", "Pilote drone certifié, prises aériennes", false, "France", "Occitanie", true, true, true),
            ("Chloé Simon", "Cadreur", "06 56 78 90 38", "c.simon@camera.fr", "Polyvalente, adaptable, bonne humeur", false, "France", "Bretagne", true, true, false),
            ("Étienne Garcia", "Cadreur", "06 67 89 01 39", "e.garcia@image.fr", "Sport, action, caméra embarquée", false, "France", "Nouvelle-Aquitaine", true, true, true),
            ("Margot Laurent", "Ingénieur du Son", "06 78 90 12 40", "m.laurent@audio.fr", "Post-production, mixage, mastering", false, "France", "Île-de-France", true, false, true),
            ("Noah Bertrand", "Ingénieur du Son", "06 89 01 23 41", "n.bertrand@sound.fr", "Prise de son direct, ambiances", false, "France", "Grand Est", true, true, false),
            ("Lola Fabre", "Ingénieur du Son", "06 90 12 34 42", "l.fabre@mix.fr", "Studio mobile, tournages extérieurs", true, "France", "Occitanie", true, true, true),
            ("Jules Mercier", "Cadreur", "06 44 55 66 91", "j.mercier@handheld.fr", "Caméra portée, style documentaire", false, "France", "Bretagne", true, false, false),
            ("Rose Leclerc", "Cadreur", "06 55 66 77 92", "r.leclerc@camera.fr", "Portraits, gros plans, sensibilité", true, "France", "Île-de-France", true, true, true),
            ("Camille Dufresne", "Cadreur", "06 66 77 88 95", "c.dufresne@motion.fr", "Mouvements fluides, chorégraphie caméra", false, "France", "Occitanie", true, true, false),
            ("Antoine Leclercq", "Cadreur", "06 77 88 99 96", "a.leclercq@steadiness.fr", "Main sûre, cadres stables, précis", false, "France", "Grand Est", true, false, true),
            ("Margaux Robin", "Cadreur", "06 88 99 00 97", "m.robin@creative.fr", "Angles créatifs, compositions originales", false, "France", "Pays de la Loire", true, true, true),
            ("Dylan Martinez", "Cadreur", "06 99 00 11 98", "d.martinez@action.fr", "Tournages action, sport, adrénaline", false, "France", "Normandie", true, true, false),
            ("Jade Blanchard", "Cadreur", "06 00 11 22 99", "j.blanchard@beauty.fr", "Beauté, mode, éclairage flatteur", false, "France", "Centre-Val de Loire", true, false, false),
            ("Loïc Bertrand", "Cadreur", "06 11 22 33 00", "l.bertrand@veteran.fr", "30 ans d'expérience, mentor jeunes", true, "France", "Bourgogne-Franche-Comté", true, true, true)
        ]
        
        // Créer les contacts principaux
        for contactData in testContacts {
            let contact = Contact(
                name: contactData.0,
                jobTitle: contactData.1,
                phone: contactData.2,
                email: contactData.3,
                notes: contactData.4,
                isFavorite: contactData.5
            )
            
            let location = WorkLocation(
                country: contactData.6,
                region: contactData.7,
                isLocalResident: contactData.8,
                hasVehicle: contactData.9,
                isHoused: contactData.10,
                isPrimary: true
            )
            
            context.insert(location)
            contact.locations = [location]
            context.insert(contact)
        }
        
        // Générer des contacts supplémentaires pour atteindre 100
        generateAdditionalRandomContacts()
        
        do {
            try context.save()
            print("✅ 100 contacts de test générés avec succès!")
        } catch {
            print("❌ Erreur lors de la génération: \(error)")
        }
    }
    
    private func generateAdditionalRandomContacts() {
        let firstNames = ["Alex", "Sam", "Jordan", "Casey", "Riley", "Taylor", "Morgan", "Avery", "Quinn", "Blake", "Cameron", "Drew", "Hayden", "Jamie", "Kendall", "Logan", "Micah", "Noel", "Parker", "Reese", "Sage", "Skyler", "Tanner", "Val", "Wesley"]
        
        let lastNames = ["Martin", "Bernard", "Dubois", "Thomas", "Robert", "Richard", "Petit", "Durand", "Leroy", "Moreau", "Simon", "Laurent", "Lefebvre", "Michel", "Garcia", "David", "Bertrand", "Roux", "Vincent", "Fournier", "Morel", "Girard", "André", "Lefevre", "Mercier", "Dupont", "Lambert", "Bonnet", "François", "Martinez"]
        
        let jobs = ["Cadreur", "Ingénieur du Son", "Électro", "Machiniste", "Assistant Régie", "Habilleur", "Maquilleur", "Coiffeur", "Assistant Monteur", "Perchman", "Assistant Son", "Rigger", "Accessoiriste", "Constructeur Décor", "Peintre Décor"]
        
        let regions = ["Île-de-France", "Provence-Alpes-Côte d'Azur", "Occitanie", "Bretagne", "Auvergne-Rhône-Alpes", "Grand Est", "Nouvelle-Aquitaine", "Pays de la Loire", "Normandie", "Centre-Val de Loire", "Bourgogne-Franche-Comté", "Hauts-de-France"]
        
        let countries = ["France", "Belgique", "Suisse", "Espagne", "Italie"]
        
        let remainingCount = 100 - 46 // 46 contacts déjà créés ci-dessus
        
        for i in 0..<remainingCount {
            let firstName = firstNames.randomElement()!
            let lastName = lastNames.randomElement()!
            let job = jobs.randomElement()!
            let country = countries.randomElement()!
            let region = country == "France" ? regions.randomElement()! : nil
            
            let contact = Contact(
                name: "\(firstName) \(lastName)",
                jobTitle: job,
                phone: "06 \(String(format: "%02d", Int.random(in: 10...99))) \(String(format: "%02d", Int.random(in: 10...99))) \(String(format: "%02d", Int.random(in: 10...99))) \(String(format: "%02d", i % 100))",
                email: "\(firstName.lowercased()).\(lastName.lowercased())@\(job.lowercased().replacingOccurrences(of: " ", with: "")).fr",
                notes: "Contact généré automatiquement pour les tests",
                isFavorite: Int.random(in: 1...10) == 1 // 10% de chance d'être favori
            )
            
            let location = WorkLocation(
                country: country,
                region: region,
                isLocalResident: true,
                hasVehicle: Bool.random(),
                isHoused: Bool.random(),
                isPrimary: true
            )
            
            context.insert(location)
            contact.locations = [location]
            context.insert(contact)
        }
    }
}

// Vue pour afficher chaque contact
struct ContactRowView: View {
    let contact: Contact
    
    // Fonction pour obtenir l'icône du département
    private func getDepartmentIcon(for jobTitle: String) -> String? {
        for (department, jobs) in JobTitles.departments {
            if jobs.contains(jobTitle) {
                switch department {
                case "Réalisation":
                    return "megaphone.fill"
                case "Image":
                    return "camera.fill"
                case "Son":
                    return "music.note"
                case "Lumière":
                    return "lightbulb.fill"
                case "Régie":
                    return "exclamationmark.triangle.fill"
                case "Décors":
                    return "hammer.fill"
                case "Costumes":
                    return "tshirt.fill"
                case "Maquillage et Coiffure":
                    return "paintbrush.fill"
                case "Production":
                    return "dollarsign.circle.fill"
                case "Post-Production":
                    return "tv.fill"
                default:
                    return nil
                }
            }
        }
        return nil
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                // Nom
                Text(contact.name)
                    .font(.headline)
                
                // Poste et lieu
                HStack(spacing: 8) {
                    if let icon = getDepartmentIcon(for: contact.jobTitle) {
                        Image(systemName: icon)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Text("\(contact.jobTitle) • \(contact.city)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Étoile de favori
            if contact.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }
        }
        .padding(.vertical, 2)
    }
}

// Vue pour les filtres actifs
struct FilterChip: View {
    let title: String
    let icon: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(title)
                .font(.caption)
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(12)
    }
}

// Vue modale pour les filtres avec sélection de régions
struct ContentFiltersView: View {
    @Binding var filters: ContentView.FilterSettings
    @Environment(\.dismiss) private var dismiss
    @State private var jobSearchText = ""
    @State private var showingJobPicker = false
    
    // Liste de tous les métiers
    private var allJobs: [String] {
        JobTitles.departments.values.flatMap { $0 }.sorted()
    }
    
    // Métiers filtrés par la recherche
    private var filteredJobs: [String] {
        if jobSearchText.isEmpty {
            return allJobs
        }
        return allJobs.filter { job in
            job.localizedCaseInsensitiveContains(jobSearchText)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Métier")) {
                    Button {
                        showingJobPicker = true
                    } label: {
                        HStack {
                            Text("Poste")
                                .foregroundColor(.primary)
                            Spacer()
                            Text(filters.selectedJob == "Tous" ? "Tous les métiers" : filters.selectedJob)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
                
                Section(header: Text("Localisation")) {
                    Picker("Pays", selection: $filters.selectedCountry) {
                        Text("Tous les pays").tag("Tous")
                        ForEach(Locations.countries.filter { $0 != "Worldwide" }, id: \.self) { country in
                            Text(country).tag(country)
                        }
                    }
                    .onChange(of: filters.selectedCountry) { _, newValue in
                        if newValue != "France" {
                            filters.selectedRegions.removeAll()
                        }
                    }
                    
                    // Sélection des régions françaises
                    if filters.selectedCountry == "France" {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Régions")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                                if !filters.selectedRegions.isEmpty {
                                    Button("Tout effacer") {
                                        filters.selectedRegions.removeAll()
                                    }
                                    .font(.caption)
                                    .foregroundColor(.red)
                                }
                            }
                            
                            Button {
                                if filters.selectedRegions.count == Locations.frenchRegions.count {
                                    filters.selectedRegions.removeAll()
                                } else {
                                    filters.selectedRegions = Set(Locations.frenchRegions)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: filters.selectedRegions.count == Locations.frenchRegions.count ? "checkmark.square.fill" : "square")
                                        .foregroundColor(.blue)
                                    Text("Tout le pays")
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.vertical, 4)
                            
                            ForEach(Locations.frenchRegions, id: \.self) { region in
                                Button {
                                    if filters.selectedRegions.contains(region) {
                                        filters.selectedRegions.remove(region)
                                    } else {
                                        filters.selectedRegions.insert(region)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: filters.selectedRegions.contains(region) ? "checkmark.square.fill" : "square")
                                            .foregroundColor(.blue)
                                        Text(region)
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.vertical, 2)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section(header: Text("Attributs")) {
                    Toggle(isOn: $filters.includeVehicle) {
                        HStack {
                            Image(systemName: "car.fill")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            Text("Véhiculé")
                        }
                    }
                    
                    Toggle(isOn: $filters.includeHoused) {
                        HStack {
                            Image(systemName: "house.fill")
                                .foregroundColor(.green)
                                .frame(width: 20)
                            Text("Logé")
                        }
                    }
                    
                    Toggle(isOn: $filters.includeResident) {
                        HStack {
                            Image(systemName: "building.columns.fill")
                                .foregroundColor(.orange)
                                .frame(width: 20)
                            Text("Résidence fiscale")
                        }
                    }
                }
                
                Section {
                    Button("Réinitialiser tous les filtres") {
                        filters = ContentView.FilterSettings()
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("Filtres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingJobPicker) {
                ContentJobPickerView(
                    selectedJob: $filters.selectedJob,
                    searchText: $jobSearchText,
                    filteredJobs: filteredJobs
                )
            }
        }
    }
}

// Vue séparée pour le picker des métiers (nom changé pour éviter les conflits)
struct ContentJobPickerView: View {
    @Binding var selectedJob: String
    @Binding var searchText: String
    @Environment(\.dismiss) private var dismiss
    let filteredJobs: [String]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Barre de recherche
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Rechercher un métier...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    if !searchText.isEmpty {
                        Button("Effacer") {
                            searchText = ""
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                
                // Liste des métiers
                List {
                    // Option "Tous"
                    Button {
                        selectedJob = "Tous"
                        dismiss()
                    } label: {
                        HStack {
                            Text("Tous les métiers")
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedJob == "Tous" {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    // Métiers filtrés
                    if searchText.isEmpty {
                        // Affichage par département quand pas de recherche
                        ForEach(JobTitles.departments.keys.sorted(), id: \.self) { department in
                            Section(header: Text(department)) {
                                ForEach(JobTitles.departments[department]!, id: \.self) { job in
                                    Button {
                                        selectedJob = job
                                        dismiss()
                                    } label: {
                                        HStack {
                                            Text(job)
                                                .foregroundColor(.primary)
                                            Spacer()
                                            if selectedJob == job {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        // Affichage simple lors de la recherche
                        ForEach(filteredJobs, id: \.self) { job in
                            Button {
                                selectedJob = job
                                dismiss()
                            } label: {
                                HStack {
                                    Text(job)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if selectedJob == job {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Choisir un métier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Vue pour l'import de fichiers (nom changé pour éviter les conflits)
struct ContactImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var showingDocumentPicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "square.and.arrow.down.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                VStack(spacing: 16) {
                    Text("Importer des contacts")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Sélectionnez un fichier .json ou .csv reçu d'un collègue pour importer un ou plusieurs contacts")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button {
                    showingDocumentPicker = true
                } label: {
                    HStack {
                        Image(systemName: "folder.fill")
                        Text("Choisir un fichier")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showingDocumentPicker,
                allowedContentTypes: [.json, .commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result: result)
            }
            .alert("Import", isPresented: $showingAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let importedContacts = try ContactSharingManager.shared.importContacts(from: url, context: context)
                if importedContacts.count == 1 {
                    alertMessage = "Contact \"\(importedContacts.first?.name ?? "")\" importé avec succès !"
                } else {
                    alertMessage = "\(importedContacts.count) contacts importés avec succès !"
                }
                showingAlert = true
            } catch {
                alertMessage = "Erreur lors de l'import: \(error.localizedDescription)"
                showingAlert = true
            }
            
        case .failure(let error):
            alertMessage = "Erreur lors de la sélection: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}
