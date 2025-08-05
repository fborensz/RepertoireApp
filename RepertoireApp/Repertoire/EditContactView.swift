import SwiftUI
import SwiftData

struct EditContactView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var contact: Contact

    @State private var selectedCountry: String = "Worldwide"
    @State private var selectedRegion: String? = nil
    @State private var isHoused = false
    @State private var isLocalResident = false
    @State private var hasVehicle = false

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

                Section(header: Text("Lieu de travail")) {
                    Picker("Pays", selection: $selectedCountry) {
                        ForEach(Locations.countries, id: \.self) { country in
                            Text(country).tag(country)
                        }
                    }

                    if selectedCountry == "France" {
                        Picker("Région", selection: Binding(
                            get: { selectedRegion ?? Locations.frenchRegions.first! },
                            set: { selectedRegion = $0 }
                        )) {
                            ForEach(Locations.frenchRegions, id: \.self) { region in
                                Text(region).tag(region as String?)
                            }
                        }
                    }

                    Toggle("Véhiculé", isOn: $hasVehicle)
                    Toggle("Logé", isOn: $isHoused)
                    Toggle("Résidence fiscale", isOn: $isLocalResident)
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
            }
            .navigationTitle("Modifier contact")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        // Mettre à jour ou créer la location
                        if let existingLocation = contact.locations.first {
                            existingLocation.country = selectedCountry
                            existingLocation.region = selectedRegion
                            existingLocation.isLocalResident = isLocalResident
                            existingLocation.hasVehicle = hasVehicle
                            existingLocation.isHoused = isHoused
                        } else {
                            let newLocation = WorkLocation(
                                country: selectedCountry,
                                region: selectedRegion,
                                isLocalResident: isLocalResident,
                                hasVehicle: hasVehicle,
                                isHoused: isHoused
                            )
                            contact.locations = [newLocation]
                        }
                        
                        try? context.save()
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let loc = contact.locations.first {
                    selectedCountry = loc.country
                    selectedRegion = loc.region
                    isLocalResident = loc.isLocalResident
                    hasVehicle = loc.hasVehicle
                    isHoused = loc.isHoused
                }
            }
        }
    }
}
