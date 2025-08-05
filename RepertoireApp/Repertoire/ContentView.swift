// ContentView.swift - Version nettoyée sans redéclarations
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query private var contacts: [Contact]
    @State private var hasPerformedCleanup = false
    @State private var showingFilters = false
    @State private var showingImport = false
    @State private var currentFilters = FilterSettings()
    
    // Structure pour les filtres
    struct FilterSettings {
        var selectedJob = "Tous"
        var selectedCountry = "Tous"
        var includeVehicle = false
        var includeHoused = false
        var includeResident = false
    }

    // Contacts filtrés et triés
    private var filteredAndSortedContacts: [Contact] {
        let filtered = filteredContacts
        return filtered.sorted { contact1, contact2 in
            // Favoris en premier
            if contact1.isFavorite && !contact2.isFavorite {
                return true
            } else if !contact1.isFavorite && contact2.isFavorite {
                return false
            } else {
                return contact1.name.localizedCaseInsensitiveCompare(contact2.name) == .orderedAscending
            }
        }
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
        
        // Logique combinée Pays + Attributs
        if currentFilters.selectedCountry != "Tous" {
            // Trouver les lieux qui correspondent au pays sélectionné
            let matchingLocations = contact.locations.filter { $0.country == currentFilters.selectedCountry }
            
            if matchingLocations.isEmpty {
                return false // Pas de lieu dans ce pays
            }
            
            // Si des attributs sont sélectionnés, vérifier qu'ils existent dans ce pays
            if currentFilters.includeVehicle {
                let hasVehicleInCountry = matchingLocations.contains { $0.hasVehicle }
                if !hasVehicleInCountry { return false }
            }
            
            if currentFilters.includeHoused {
                let isHousedInCountry = matchingLocations.contains { $0.isHoused }
                if !isHousedInCountry { return false }
            }
            
            if currentFilters.includeResident {
                let isResidentInCountry = matchingLocations.contains { $0.isLocalResident }
                if !isResidentInCountry { return false }
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
                        List {
                            ForEach(filteredAndSortedContacts) { contact in
                                NavigationLink(destination: ContactDetailView(contact: contact)) {
                                    ContactRowView(contact: contact)
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
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

// Vue modale pour les filtres (nom changé pour éviter les conflits)
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
    @State private var importedContact: Contact?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "square.and.arrow.down.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                VStack(spacing: 16) {
                    Text("Importer un contact")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Sélectionnez un fichier .repertoire reçu d'un collègue pour l'ajouter à vos contacts")
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
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result: result)
            }
            .alert("Import", isPresented: $showingAlert) {
                Button("OK") {
                    if importedContact != nil {
                        dismiss()
                    }
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
                importedContact = try ContactSharingManager.shared.importContact(from: url, context: context)
                alertMessage = "Contact \"\(importedContact?.name ?? "")\" importé avec succès !"
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
