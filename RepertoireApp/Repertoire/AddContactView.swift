import SwiftUI
import SwiftData

struct AddContactView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var name = ""
    @State private var jobTitle = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var notes = ""
    @State private var isFavorite = false
    
    @State private var locations: [LocationData] = [LocationData(isPrimary: true)]
    
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
                    TextField("Nom complet", text: $name)
                    
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
                    TextField("Téléphone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                }
                
                Section(header: Text("Notes")) {
                    TextField("Notes supplémentaires", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Options")) {
                    Toggle("Ajouter aux favoris", isOn: $isFavorite)
                }
            }
            .navigationTitle("Nouveau contact")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        let newContact = Contact(
                            name: name,
                            jobTitle: jobTitle,
                            phone: phone,
                            email: email,
                            notes: notes,
                            isFavorite: isFavorite
                        )
                        
                        // Créer les lieux de travail
                        var workLocations: [WorkLocation] = []
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
                            workLocations.append(workLocation)
                        }
                        
                        newContact.locations = workLocations
                        context.insert(newContact)
                        try? context.save()
                        dismiss()
                    }
                    .disabled(name.isEmpty || jobTitle.isEmpty)
                }
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
}
