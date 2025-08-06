import SwiftUI
import SwiftData

struct EditContactView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var contact: Contact
    
    @State private var locations: [LocationData] = []
    
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
            Section(header: Text("Informations principales").foregroundColor(MyCrewColors.accent)) {
                TextField("Nom complet", text: $contact.name)
                    .foregroundColor(MyCrewColors.textPrimary)

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
                    .foregroundColor(MyCrewColors.accent)
                }
            }

            ForEach(Array(locations.enumerated()), id: \.element.id) { index, _ in
                Section(header: Text(index == 0 ? "Lieu principal" : "Lieu secondaire \(index)").foregroundColor(MyCrewColors.accent)) {
                    locationSection(for: index)
                }
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
            }

            Section(header: Text("Contact").foregroundColor(MyCrewColors.accent)) {
                TextField("Téléphone", text: $contact.phone)
                    .keyboardType(.phonePad)
                    .foregroundColor(MyCrewColors.textPrimary)
                TextField("Email", text: $contact.email)
                    .keyboardType(.emailAddress)
                    .foregroundColor(MyCrewColors.textPrimary)
            }

            Section(header: Text("Notes").foregroundColor(MyCrewColors.accent)) {
                TextField("Notes supplémentaires", text: $contact.notes, axis: .vertical)
                    .lineLimit(3...6)
                    .foregroundColor(MyCrewColors.textPrimary)
            }
            
            Section(header: Text("Options").foregroundColor(MyCrewColors.accent)) {
                Toggle("Favori", isOn: $contact.isFavorite)
                    .tint(MyCrewColors.accent)
            }
        }
        .navigationTitle("Modifier Contact")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annuler") { dismiss() }
                    .foregroundColor(.red)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Enregistrer") {
                    saveLocations()
                    try? context.save()
                    dismiss()
                }
                .foregroundColor(MyCrewColors.accent)
            }
        }
        .onAppear { loadLocations() }
        .background(MyCrewColors.background.ignoresSafeArea())
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
    
    private func loadLocations() {
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
    
    private func saveLocations() {
        for oldLocation in contact.locations {
            context.delete(oldLocation)
        }
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
    }
}
