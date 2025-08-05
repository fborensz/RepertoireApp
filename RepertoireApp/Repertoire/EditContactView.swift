import SwiftUI
import SwiftData

struct EditContactView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var contact: Contact
    
    @State private var locations: [LocationData] = []
    
    // Structure pour gérer les données des lieux
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
        NavigationView {
            Form {
                Section(header: Text("Informations principales")) {
                    TextField("Nom complet", text: $contact.name)

                    Menu {
                        ForEach(JobTitles.departments.keys.sorted(), id: \.self) { department in
                            Section(header: Text(department)) {
                                ForEach(JobTitles.departments[department]!, id: \.self) { job in
                                    Button(job) { contact.jobTitle = job }
                                }
                            }
                        }
                    } label: {
                        Label(contact.jobTitle.isEmpty ? "Choisir un poste" : contact.jobTitle,
                              systemImage: "briefcase")
                    }
                }

                // Lieux de travail
                ForEach(Array(locations.enumerated()), id: \.element.id) { index, _ in
                    Section(header: HStack {
                        Text(index == 0 ? "Lieu principal" : "Lieu secondaire \(index)")
                        Spacer()
                        if locations.count > 1 {
                            Button("Supprimer") {
                                locations.remove(at: index)
                            }
                            .foregroundColor(.red)
                            .font(.caption)
                        }
                    }) {
                        locationSection(for: index)
                    }
                }
                
                // Bouton ajouter lieu (max 3)
                if locations.count < 3 {
                    Section {
                        Button {
                            locations.append(LocationData())
                        } label: {
                            Label("Ajouter un lieu", systemImage: "plus.circle")
                        }
                    }
                }

                Section(header: Text("Contact")) {
                    TextField("Téléphone", text: $contact.phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $contact.email)
                        .keyboardType(.emailAddress)
                }

                Section(header: Text("Notes")) {
                    TextField("Notes supplémentaires", text: $contact.notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Options")) {
                    Toggle("Favori", isOn: $contact.isFavorite)
                }
            }
            .navigationTitle("Modifier contact")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        saveLocations()
                        try? context.save()
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadLocations()
            }
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
        
        Toggle("Véhiculé", isOn: $locations[index].hasVehicle)
        Toggle("Logé", isOn: $locations[index].isHoused)
        Toggle("Résidence fiscale", isOn: $locations[index].isLocalResident)
    }
    
    private func loadLocations() {
        locations = []
        
        // Charger le lieu principal
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
        
        // Charger les lieux secondaires
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
        
        // S'assurer d'avoir au moins un lieu
        if locations.isEmpty {
            locations.append(LocationData(isPrimary: true))
        }
    }
    
    private func saveLocations() {
        // Supprimer toutes les anciennes locations
        for oldLocation in contact.locations {
            context.delete(oldLocation)
        }
        
        // Créer les nouvelles locations
        var newLocations: [WorkLocation] = []
        
        for (index, locationData) in locations.enumerated() {
            let workLocation = WorkLocation(
                country: locationData.country,
                region: locationData.region,
                isLocalResident: locationData.isLocalResident,
                hasVehicle: locationData.hasVehicle,
                isHoused: locationData.isHoused,
                isPrimary: index == 0 // Le premier est toujours principal
            )
            context.insert(workLocation)
            newLocations.append(workLocation)
        }
        
        contact.locations = newLocations
    }
}
