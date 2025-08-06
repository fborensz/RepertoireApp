import SwiftUI
import SwiftData

struct EditContactView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let contact: Contact // Pas @Bindable !
    
    // Variables d'état locales pour éviter la sauvegarde automatique
    @State private var name: String = ""
    @State private var jobTitle: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var notes: String = ""
    @State private var isFavorite: Bool = false
    @State private var locations: [LocationData] = []
    @State private var showingDeleteAlert = false
    
    struct LocationData: Identifiable {
        let id = UUID()
        var country: String = "Worldwide"
        var region: String? = nil
        var isHoused = false
        var isLocalResident = false
        var hasVehicle = false
        var isPrimary = false
    }

    var body: some View {
        Form {
            // Section Favori en premier
            Section {
                HStack {
                    Button {
                        isFavorite.toggle()
                    } label: {
                        HStack {
                            Image(systemName: isFavorite ? "star.fill" : "star")
                                .foregroundColor(isFavorite ? MyCrewColors.favoriteStar : MyCrewColors.textSecondary)
                                .font(.title2)
                            Text("Favori")
                                .foregroundColor(MyCrewColors.textPrimary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
                .listRowBackground(MyCrewColors.cardBackground)
            }
            
            Section(header: Text("Informations principales").foregroundColor(MyCrewColors.accent)) {
                TextField("Nom complet", text: $name)
                    .foregroundColor(MyCrewColors.textPrimary)

                Menu {
                    ForEach(JobTitles.departments.keys.sorted(), id: \.self) { department in
                        Section(header: Text(department)) {
                            ForEach(JobTitles.departments[department]!, id: \.self) { job in
                                Button(job) { jobTitle = job }
                            }
                        }
                    }
                } label: {
                    Label(jobTitle.isEmpty ? "Choisir un poste" : jobTitle,
                          systemImage: "briefcase")
                    .foregroundColor(MyCrewColors.accent)
                }
            }
            .listRowBackground(MyCrewColors.cardBackground)

            ForEach(Array(locations.enumerated()), id: \.element.id) { index, _ in
                Section(header: Text(index == 0 ? "Lieu principal" : "Lieu secondaire \(index)").foregroundColor(MyCrewColors.accent)) {
                    locationSection(for: index)
                }
                .listRowBackground(MyCrewColors.cardBackground)
            }
            
            if locations.count < 5 {
                Section {
                    Button {
                        locations.append(LocationData())
                    } label: {
                        Label("Ajouter un lieu", systemImage: "plus.circle")
                            .foregroundColor(MyCrewColors.accent)
                    }
                }
                .listRowBackground(MyCrewColors.cardBackground)
            }

            Section(header: Text("Contact").foregroundColor(MyCrewColors.accent)) {
                TextField("Téléphone", text: $phone)
                    .keyboardType(.phonePad)
                    .foregroundColor(MyCrewColors.textPrimary)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .foregroundColor(MyCrewColors.textPrimary)
            }
            .listRowBackground(MyCrewColors.cardBackground)

            Section(header: Text("Notes").foregroundColor(MyCrewColors.accent)) {
                TextField("Notes supplémentaires", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
                    .foregroundColor(MyCrewColors.textPrimary)
            }
            .listRowBackground(MyCrewColors.cardBackground)
            
            // Section Suppression
            Section {
                Button {
                    showingDeleteAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Supprimer ce contact")
                    }
                    .foregroundColor(.red)
                }
            }
            .listRowBackground(MyCrewColors.cardBackground)
        }
        .scrollContentBackground(.hidden)
        .background(MyCrewColors.background)
        .navigationTitle("Modifier Contact")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annuler") { dismiss() }
                    .foregroundColor(.red)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Enregistrer") {
                    saveChanges()
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || jobTitle.isEmpty)
                .foregroundColor(MyCrewColors.accent)
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Mes Contacts")
                    }
                    .foregroundColor(MyCrewColors.accent)
                }
            }
        }
        .onAppear { loadContactData() }
        .alert("Supprimer le contact", isPresented: $showingDeleteAlert) {
            Button("Annuler", role: .cancel) { }
            Button("Supprimer", role: .destructive) {
                // Supprimer les lieux associés
                for location in contact.locations {
                    context.delete(location)
                }
                // Supprimer le contact
                context.delete(contact)
                try? context.save()
                dismiss()
            }
        } message: {
            Text("Êtes-vous sûr de vouloir supprimer \(contact.name) ? Cette action est irréversible.")
        }
    }
    
    @ViewBuilder
    private func locationSection(for index: Int) -> some View {
        Picker("Pays", selection: $locations[index].country) {
            ForEach(Locations.countries, id: \.self) { country in
                Text(country).tag(country)
            }
        }
        
        if locations[index].country == "France" {
            Picker("Région", selection: Binding(
                get: { locations[index].region ?? Locations.frenchRegions.first! },
                set: { locations[index].region = $0 }
            )) {
                ForEach(Locations.frenchRegions, id: \.self) { region in
                    Text(region).tag(region as String?)
                }
            }
        }
        
        Toggle("Véhiculé", isOn: $locations[index].hasVehicle).tint(MyCrewColors.accent)
        Toggle("Logé", isOn: $locations[index].isHoused).tint(MyCrewColors.accent)
        Toggle("Résidence fiscale", isOn: $locations[index].isLocalResident).tint(MyCrewColors.accent)
    }
    
    // Charger les données du contact dans les variables d'état locales
    private func loadContactData() {
        name = contact.name
        jobTitle = contact.jobTitle
        phone = contact.phone
        email = contact.email
        notes = contact.notes
        isFavorite = contact.isFavorite
        
        locations = []
        if let primaryLoc = contact.primaryLocation {
            locations.append(LocationData(
                country: primaryLoc.country,
                region: primaryLoc.region,
                isHoused: primaryLoc.isHoused,
                isLocalResident: primaryLoc.isLocalResident,
                hasVehicle: primaryLoc.hasVehicle,
                isPrimary: true
            ))
        }
        for secondaryLoc in contact.secondaryLocations {
            locations.append(LocationData(
                country: secondaryLoc.country,
                region: secondaryLoc.region,
                isHoused: secondaryLoc.isHoused,
                isLocalResident: secondaryLoc.isLocalResident,
                hasVehicle: secondaryLoc.hasVehicle,
                isPrimary: false
            ))
        }
        if locations.isEmpty { locations.append(LocationData(isPrimary: true)) }
    }
    
    // Sauvegarder uniquement quand on appuie sur "Enregistrer"
    private func saveChanges() {
        // Mettre à jour les propriétés du contact
        contact.name = name
        contact.jobTitle = jobTitle
        contact.phone = phone
        contact.email = email
        contact.notes = notes
        contact.isFavorite = isFavorite
        
        // Supprimer les anciens lieux
        for oldLocation in contact.locations {
            context.delete(oldLocation)
        }
        
        // Créer les nouveaux lieux
        var newLocations: [WorkLocation] = []
        for (index, loc) in locations.enumerated() {
            let newLocation = WorkLocation(
                country: loc.country,
                region: loc.region,
                isLocalResident: loc.isLocalResident,
                hasVehicle: loc.hasVehicle,
                isHoused: loc.isHoused,
                isPrimary: index == 0
            )
            context.insert(newLocation)
            newLocations.append(newLocation)
        }
        contact.locations = newLocations
        
        // Sauvegarder en base
        try? context.save()
    }
}
