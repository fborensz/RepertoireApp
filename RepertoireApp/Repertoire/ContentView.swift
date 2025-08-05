// ContentView.swift - Version avec recherche avancée
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query private var contacts: [Contact]
    @State private var hasPerformedCleanup = false
    @State private var showingFilters = false
    @State private var filters = Filters()
    
    // Structure pour les filtres
    struct Filters {
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
        filters.selectedJob != "Tous" ||
        filters.selectedCountry != "Tous" ||
        filters.includeVehicle ||
        filters.includeHoused ||
        filters.includeResident
    }
    
    private func matchesFilters(contact: Contact) -> Bool {
        // Métier
        if filters.selectedJob != "Tous" {
            if contact.jobTitle != filters.selectedJob {
                return false
            }
        }
        
        // Pays
        if filters.selectedCountry != "Tous" {
            let hasCountry = contact.locations.contains { $0.country == filters.selectedCountry }
            if !hasCountry { return false }
        }
        
        // Véhiculé
        if filters.includeVehicle {
            let hasVehicle = contact.locations.contains { $0.hasVehicle }
            if !hasVehicle { return false }
        }
        
        // Logé
        if filters.includeHoused {
            let isHoused = contact.locations.contains { $0.isHoused }
            if !isHoused { return false }
        }
        
        // Résidence fiscale
        if filters.includeResident {
            let isResident = contact.locations.contains { $0.isLocalResident }
            if !isResident { return false }
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
                            filters = Filters()
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
                            if filters.selectedJob != "Tous" {
                                FilterChip(title: filters.selectedJob, icon: "briefcase.fill") {
                                    filters.selectedJob = "Tous"
                                }
                            }
                            if filters.selectedCountry != "Tous" {
                                FilterChip(title: filters.selectedCountry, icon: "location.fill") {
                                    filters.selectedCountry = "Tous"
                                }
                            }
                            if filters.includeVehicle {
                                FilterChip(title: "Véhiculé", icon: "car.fill") {
                                    filters.includeVehicle = false
                                }
                            }
                            if filters.includeHoused {
                                FilterChip(title: "Logé", icon: "house.fill") {
                                    filters.includeHoused = false
                                }
                            }
                            if filters.includeResident {
                                FilterChip(title: "Résidence fiscale", icon: "building.columns.fill") {
                                    filters.includeResident = false
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
                    if !contacts.isEmpty {
                        Text("\(filteredAndSortedContacts.count)/\(contacts.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: AddContactView()) {
                        Label("Ajouter", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                FiltersView(filters: $filters)
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
            var hasChanges = false
            
            // 1. Supprimer les doublons
            let uniqueLocations = removeDuplicateLocations(contact.locations)
            if uniqueLocations.count != contact.locations.count {
                print("🗑️ Suppression de doublons pour \(contact.name)")
                for location in contact.locations {
                    context.delete(location)
                }
                contact.locations = uniqueLocations
                hasChanges = true
            }
            
            // 2. Vérifier les lieux principaux
            let primaryCount = contact.locations.filter { $0.isPrimary }.count
            
            if primaryCount == 0 && !contact.locations.isEmpty {
                print("✅ Définition du lieu principal pour \(contact.name)")
                contact.locations[0].isPrimary = true
                hasChanges = true
            } else if primaryCount > 1 {
                print("🔄 Correction des lieux principaux multiples pour \(contact.name)")
                for (index, location) in contact.locations.enumerated() {
                    location.isPrimary = (index == 0)
                }
                hasChanges = true
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
                hasChanges = true
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
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                // Nom
                Text(contact.name)
                    .font(.headline)
                
                // Poste et lieu
                Text("\(contact.jobTitle) • \(contact.city)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Icônes des attributs
                HStack(spacing: 12) {
                    ForEach(contact.locations, id: \.id) { location in
                        HStack(spacing: 6) {
                            if location.hasVehicle {
                                Image(systemName: "car.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            if location.isHoused {
                                Image(systemName: "house.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            if location.isLocalResident {
                                Image(systemName: "building.columns.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                .padding(.top, 2)
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

// Vue modale pour les filtres
struct FiltersView: View {
    @Binding var filters: ContentView.Filters
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
                        filters = ContentView.Filters()
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
                JobPickerView(
                    selectedJob: $filters.selectedJob,
                    searchText: $jobSearchText,
                    filteredJobs: filteredJobs
                )
            }
        }
    }
}

// Vue séparée pour le picker des métiers avec recherche
struct JobPickerView: View {
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
                                    // Highlight du terme recherché
                                    Text(highlightedJobText(job, searchText: searchText))
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
    
    private func highlightedJobText(_ job: String, searchText: String) -> AttributedString {
        var attributedString = AttributedString(job)
        
        if !searchText.isEmpty {
            let range = job.range(of: searchText, options: .caseInsensitive)
            if let range = range {
                let nsRange = NSRange(range, in: job)
                if let attributedRange = Range(nsRange, in: attributedString) {
                    attributedString[attributedRange].backgroundColor = .yellow.opacity(0.3)
                    attributedString[attributedRange].foregroundColor = .primary
                }
            }
        }
        
        return attributedString
    }
}
