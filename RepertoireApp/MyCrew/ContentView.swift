import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query private var contacts: [Contact]
    @State private var showingFilters = false
    @State private var showingImport = false
    @State private var showingListExportOptions = false
    @State private var currentFilters = FilterSettings()
    @State private var searchText = ""
    @State private var userProfile = UserProfile.load() ?? UserProfile.example() // Ajout du profil utilisateur

    struct FilterSettings {
        var selectedJob = "Tous"
        var selectedCountry = "Tous"
        var selectedRegions: Set<String> = []
        var includeVehicle = false
        var includeHoused = false
        var includeResident = false
    }

// MARK: - FilterTag
struct FilterTag: View {
    let text: String
    let icon: String?
    let onRemove: () -> Void
    
    init(text: String, icon: String? = nil, onRemove: @escaping () -> Void) {
        self.text = text
        self.icon = icon
        self.onRemove = onRemove
    }
    
    var body: some View {
        Button {
            onRemove()
        } label: {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption2)
                        .foregroundColor(MyCrewColors.accent)
                }
                Text(text)
                    .font(.caption)
                    .foregroundColor(MyCrewColors.textPrimary)
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(MyCrewColors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(MyCrewColors.accent.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

    private var filteredAndSortedContacts: [Contact] {
        let filtered = filteredContacts
        return filtered.sorted {
            if $0.isFavorite && !$1.isFavorite { return true }
            if !$0.isFavorite && $1.isFavorite { return false }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    private var groupedContacts: [(String, [Contact])] {
        let grouped = Dictionary(grouping: filteredAndSortedContacts) {
            String($0.name.prefix(1).uppercased())
        }
        return grouped.sorted { $0.key < $1.key }
    }

    private var filteredContacts: [Contact] {
        var result = contacts
        
        // Appliquer les filtres d'abord
        if hasActiveFilters {
            result = result.filter { $0.matchesFilters(filters: currentFilters) }
        }
        
        // Appliquer la recherche ensuite
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result = result.filter { contact in
                matchesSearch(contact: contact, searchText: searchText)
            }
        }
        
        return result
    }

    private var hasActiveFilters: Bool {
        currentFilters.selectedJob != "Tous" ||
        currentFilters.selectedCountry != "Tous" ||
        !currentFilters.selectedRegions.isEmpty ||
        currentFilters.includeVehicle ||
        currentFilters.includeHoused ||
        currentFilters.includeResident
    }

    var body: some View {
        VStack(spacing: 0) {
            // Ma fiche pro (NOUVEAUTÉ - au bon endroit)
            UserProfileHeaderView(userProfile: $userProfile)
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            // Barre de filtres et actions
            HStack {
                Button {
                    showingFilters.toggle()
                } label: {
                    HStack {
                        Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundColor(hasActiveFilters ? MyCrewColors.accent : MyCrewColors.textSecondary)
                        Text("Filtres")
                            .foregroundColor(hasActiveFilters ? MyCrewColors.accent : MyCrewColors.textSecondary)
                    }
                }
                
                if hasActiveFilters {
                    Button("Effacer") {
                        currentFilters = FilterSettings()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.leading, 8)
                }
                
                Spacer()
                
                HStack(spacing: 16) {
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
                        .foregroundColor(MyCrewColors.accent)
                    }
                    
                    Button {
                        showingImport = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down.on.square")
                                .font(.caption)
                            Text("Importer")
                                .font(.caption)
                        }
                    }
                    .foregroundColor(MyCrewColors.accent)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Barre de recherche (NOUVEAUTÉ)
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                    
                    TextField("Rechercher un nom, métier, lieu...", text: $searchText)
                        .foregroundColor(MyCrewColors.textPrimary)
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 16))
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(MyCrewColors.cardBackground)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(searchText.isEmpty ? Color.clear : MyCrewColors.accent.opacity(0.3), lineWidth: 1)
                )
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Affichage des filtres actifs
            if hasActiveFilters {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Filtre métier
                        if currentFilters.selectedJob != "Tous" {
                            FilterTag(text: "Poste: \(currentFilters.selectedJob)") {
                                currentFilters.selectedJob = "Tous"
                            }
                        }
                        
                        // Filtre pays
                        if currentFilters.selectedCountry != "Tous" {
                            FilterTag(text: "Pays: \(currentFilters.selectedCountry)") {
                                currentFilters.selectedCountry = "Tous"
                                currentFilters.selectedRegions.removeAll()
                            }
                        }
                        
                        // Filtres régions
                        ForEach(Array(currentFilters.selectedRegions), id: \.self) { region in
                            FilterTag(text: region) {
                                currentFilters.selectedRegions.remove(region)
                            }
                        }
                        
                        // Filtres attributs
                        if currentFilters.includeVehicle {
                            FilterTag(text: "Véhiculé", icon: "car.fill") {
                                currentFilters.includeVehicle = false
                            }
                        }
                        
                        if currentFilters.includeHoused {
                            FilterTag(text: "Logé", icon: "house.fill") {
                                currentFilters.includeHoused = false
                            }
                        }
                        
                        if currentFilters.includeResident {
                            FilterTag(text: "Résidence fiscale", icon: "building.columns.fill") {
                                currentFilters.includeResident = false
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(MyCrewColors.background)
            }
            
            Group {
                if filteredAndSortedContacts.isEmpty && !contacts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 50))
                            .foregroundColor(MyCrewColors.textSecondary)
                        Text("Aucun résultat")
                            .font(.title2)
                            .foregroundColor(MyCrewColors.textPrimary)
                            .fontWeight(.semibold)
                        
                        if !searchText.isEmpty {
                            Text("Aucun contact trouvé pour \"\(searchText)\"")
                                .font(.subheadline)
                                .foregroundColor(MyCrewColors.textSecondary)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Essayez d'ajuster vos filtres")
                                .font(.subheadline)
                                .foregroundColor(MyCrewColors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if contacts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 60))
                            .foregroundColor(MyCrewColors.textSecondary)
                        Text("Aucun contact")
                            .font(.title2)
                            .foregroundColor(MyCrewColors.textPrimary)
                            .fontWeight(.semibold)
                        Text("Appuyez sur + pour ajouter votre premier contact")
                            .font(.subheadline)
                            .foregroundColor(MyCrewColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(groupedContacts, id: \.0) { letter, contactsInGroup in
                            Section(header: Text(letter).font(.headline).foregroundColor(MyCrewColors.accent)) {
                                ForEach(contactsInGroup) { contact in
                                    NavigationLink(destination: ContactDetailView(contact: contact)) {
                                        ContactRowView(contact: contact, searchText: searchText)
                                    }
                                    .listRowBackground(MyCrewColors.cardBackground)
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(MyCrewColors.background)
                }
            }
        }
        .navigationTitle("Mes Contacts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: AddContactView()) {
                    Label("Ajouter", systemImage: "plus")
                        .foregroundColor(MyCrewColors.accent)
                }
            }
        }
        .background(MyCrewColors.background.ignoresSafeArea())
        .preferredColorScheme(.light) // Force le mode clair
        .sheet(isPresented: $showingFilters) {
            FilterModalView(filters: $currentFilters, contacts: contacts)
        }
        .sheet(isPresented: $showingListExportOptions) {
            ExportOptionsView(contacts: filteredAndSortedContacts, filterDescription: getFilterDescription())
        }
        .sheet(isPresented: $showingImport) {
            ImportView()
        }
    }
    
    // NOUVELLE FONCTION : Logique de recherche
    private func matchesSearch(contact: Contact, searchText: String) -> Bool {
        let search = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !search.isEmpty else { return true }
        
        // Recherche dans le nom (n'importe où dans le nom)
        if contact.name.lowercased().contains(search) {
            return true
        }
        
        // Recherche dans le métier
        if contact.jobTitle.lowercased().contains(search) {
            return true
        }
        
        // Recherche dans les lieux (pays et régions)
        for location in contact.locations {
            // Recherche dans le pays
            if location.country.lowercased().contains(search) {
                return true
            }
            
            // Recherche dans la région si elle existe
            if let region = location.region, region.lowercased().contains(search) {
                return true
            }
        }
        
        return false
    }
    
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
            description.append("Critères: \(attributes.joined(separator: ", "))")
        }
        
        if !searchText.isEmpty {
            description.append("Recherche: \"\(searchText)\"")
        }
        
        return description.isEmpty ? "Tous les contacts" : description.joined(separator: " • ")
    }
}

// MARK: - FilterModalView
struct FilterModalView: View {
    @Binding var filters: ContentView.FilterSettings
    @Environment(\.dismiss) private var dismiss
    let contacts: [Contact]
    
    private var availableJobs: [String] {
        let allJobsInDatabase = Set(contacts.map { $0.jobTitle })
        let standardJobs = Set(JobTitles.allAvailableJobs)
        
        // Inclure "À définir" seulement s'il existe dans la base
        var jobs = standardJobs
        if allJobsInDatabase.contains(JobTitles.defaultJob) {
            jobs.insert(JobTitles.defaultJob)
        }
        
        return ["Tous"] + jobs.sorted()
    }
    
    private var availableCountries: [String] {
        let countries = Set(contacts.flatMap { contact in
            contact.locations.map { $0.country }
        })
        return ["Tous"] + countries.sorted()
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Métier").foregroundColor(MyCrewColors.accent)) {
                    Picker("Poste", selection: $filters.selectedJob) {
                        ForEach(availableJobs, id: \.self) { job in
                            Text(job).tag(job)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .listRowBackground(MyCrewColors.cardBackground)
                
                Section(header: Text("Localisation").foregroundColor(MyCrewColors.accent)) {
                    Picker("Pays", selection: $filters.selectedCountry) {
                        ForEach(availableCountries, id: \.self) { country in
                            Text(country).tag(country)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    if filters.selectedCountry == "France" {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Régions")
                                .font(.subheadline)
                                .foregroundColor(MyCrewColors.accent)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach(Locations.frenchRegions, id: \.self) { region in
                                    Button {
                                        if filters.selectedRegions.contains(region) {
                                            filters.selectedRegions.remove(region)
                                        } else {
                                            filters.selectedRegions.insert(region)
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: filters.selectedRegions.contains(region) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(filters.selectedRegions.contains(region) ? MyCrewColors.accent : .secondary)
                                            Text(region)
                                                .font(.caption)
                                                .foregroundColor(MyCrewColors.textPrimary)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listRowBackground(MyCrewColors.cardBackground)
                
                Section(header: Text("Critères").foregroundColor(MyCrewColors.accent)) {
                    Toggle("Véhiculé", isOn: $filters.includeVehicle)
                        .tint(MyCrewColors.accent)
                    Toggle("Logé", isOn: $filters.includeHoused)
                        .tint(MyCrewColors.accent)
                    Toggle("Résidence fiscale", isOn: $filters.includeResident)
                        .tint(MyCrewColors.accent)
                }
                .listRowBackground(MyCrewColors.cardBackground)
                
                Section {
                    Button("Effacer tous les filtres") {
                        filters = ContentView.FilterSettings()
                    }
                    .foregroundColor(.red)
                }
                .listRowBackground(MyCrewColors.cardBackground)
            }
            .scrollContentBackground(.hidden)
            .background(MyCrewColors.background)
            .navigationTitle("Filtres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Appliquer") {
                        dismiss()
                    }
                    .foregroundColor(MyCrewColors.accent)
                }
            }
        }
    }
}

// MARK: - ContactRowView (modifiée pour highlight la recherche)

struct ContactRowView: View {
    let contact: Contact
    let searchText: String
    
    // Initializer avec valeur par défaut pour la compatibilité
    init(contact: Contact, searchText: String = "") {
        self.contact = contact
        self.searchText = searchText
    }
    
    private func getDepartmentIcon(for jobTitle: String) -> String? {
        for (department, jobs) in JobTitles.departments {
            if jobs.contains(jobTitle) {
                switch department {
                case "Réalisation": return "megaphone.fill"
                case "Image": return "camera.fill"
                case "Son": return "music.note"
                case "Lumière": return "lightbulb.fill"
                case "Régie": return "exclamationmark.triangle.fill"
                case "Décors": return "hammer.fill"
                case "Costumes": return "tshirt.fill"
                case "Maquillage et Coiffure": return "paintbrush.fill"
                case "Production": return "dollarsign.circle.fill"
                case "Post-Production": return "tv.fill"
                default: return nil
                }
            }
        }
        return nil
    }
    
    // Fonction pour surligner les termes de recherche
    private func highlightedText(_ text: String, searchTerm: String) -> Text {
        guard !searchTerm.isEmpty else {
            return Text(text).foregroundColor(MyCrewColors.textSecondary)
        }
        
        let lowercasedText = text.lowercased()
        let lowercasedSearch = searchTerm.lowercased()
        
        if lowercasedText.contains(lowercasedSearch) {
            var result = Text("")
            let ranges = lowercasedText.ranges(of: lowercasedSearch)
            
            var lastEnd = text.startIndex
            for range in ranges {
                // Partie avant le match
                if lastEnd < range.lowerBound {
                    let beforeMatch = String(text[lastEnd..<range.lowerBound])
                    result = result + Text(beforeMatch).foregroundColor(MyCrewColors.textSecondary)
                }
                
                // Partie matchée (surlignée)
                let matchedPart = String(text[range])
                result = result + Text(matchedPart)
                    .foregroundColor(MyCrewColors.accent)
                    .fontWeight(.semibold)
                
                lastEnd = range.upperBound
            }
            
            // Partie après le dernier match
            if lastEnd < text.endIndex {
                let afterMatch = String(text[lastEnd...])
                result = result + Text(afterMatch).foregroundColor(MyCrewColors.textSecondary)
            }
            
            return result
        } else {
            return Text(text).foregroundColor(MyCrewColors.textSecondary)
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                // Nom avec surlignage
                if !searchText.isEmpty && contact.name.lowercased().contains(searchText.lowercased()) {
                    highlightedText(contact.name, searchTerm: searchText)
                        .font(.headline)
                } else {
                    Text(contact.name)
                        .font(.headline)
                        .foregroundColor(MyCrewColors.textPrimary)
                }
                
                HStack(spacing: 8) {
                    if let icon = getDepartmentIcon(for: contact.jobTitle) {
                        Image(systemName: icon)
                            .font(.caption)
                            .foregroundColor(MyCrewColors.accent)
                    }
                    
                    // Métier et lieu avec surlignage
                    HStack(spacing: 0) {
                        if !searchText.isEmpty && contact.jobTitle.lowercased().contains(searchText.lowercased()) {
                            highlightedText(contact.jobTitle, searchTerm: searchText)
                        } else {
                            Text(contact.jobTitle)
                                .foregroundColor(MyCrewColors.textSecondary)
                        }
                        
                        Text(" • ")
                            .foregroundColor(MyCrewColors.textSecondary)
                        
                        if !searchText.isEmpty && contact.city.lowercased().contains(searchText.lowercased()) {
                            highlightedText(contact.city, searchTerm: searchText)
                        } else {
                            Text(contact.city)
                                .foregroundColor(MyCrewColors.textSecondary)
                        }
                    }
                }
                .font(.subheadline)
            }
            Spacer()
            
            if contact.isFavorite {
                Image(systemName: "star.fill")
                    .foregroundColor(MyCrewColors.favoriteStar)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
    }
}

// Extension pour trouver les ranges d'une substring
extension String {
    func ranges(of substring: String, options: CompareOptions = []) -> [Range<Index>] {
        var ranges: [Range<Index>] = []
        var searchStartIndex = self.startIndex
        
        while searchStartIndex < self.endIndex,
              let range = self.range(of: substring, options: options, range: searchStartIndex..<self.endIndex) {
            ranges.append(range)
            searchStartIndex = range.upperBound
        }
        
        return ranges
    }
}
