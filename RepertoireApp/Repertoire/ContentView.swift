import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query private var contacts: [Contact]
    @State private var showingFilters = false
    @State private var showingImport = false
    @State private var showingListExportOptions = false
    @State private var currentFilters = FilterSettings()

    struct FilterSettings {
        var selectedJob = "Tous"
        var selectedCountry = "Tous"
        var selectedRegions: Set<String> = []
        var includeVehicle = false
        var includeHoused = false
        var includeResident = false
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
        if !hasActiveFilters { return contacts }
        return contacts.filter { $0.matchesFilters(filters: currentFilters) }
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
                // Logo est déjà dans RootView

                
                HStack {
                    Button {
                        showingFilters.toggle()
                    } label: {
                        HStack {
                            Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                .foregroundColor(hasActiveFilters ? MyCrewColors.accent : .secondary)
                            Text("Filtres")
                                .foregroundColor(hasActiveFilters ? MyCrewColors.accent : .secondary)
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
                        .foregroundColor(MyCrewColors.accent)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                Group {
                    if filteredAndSortedContacts.isEmpty && !contacts.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "person.crop.circle.badge.questionmark")
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
                            Image(systemName: "person.3.fill")
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
                            ForEach(groupedContacts, id: \.0) { letter, contactsInGroup in
                                Section(header: Text(letter).font(.headline).foregroundColor(MyCrewColors.accent)) {
                                    ForEach(contactsInGroup) { contact in
                                        NavigationLink(destination: ContactDetailView(contact: contact)) {
                                            ContactRowView(contact: contact)
                                        }
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
        }
    }

// MARK: - ContactRowView

struct ContactRowView: View {
    let contact: Contact
    
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
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.headline)
                    .foregroundColor(MyCrewColors.textPrimary)
                
                HStack(spacing: 8) {
                    if let icon = getDepartmentIcon(for: contact.jobTitle) {
                        Image(systemName: icon)
                            .font(.caption)
                            .foregroundColor(MyCrewColors.accent)
                    }
                    Text("\(contact.jobTitle) • \(contact.city)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
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
