import SwiftUI
import SwiftData

struct EditContactView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var contact: Contact

    @State private var selectedCountry: String = "Worldwide"
    @State private var selectedRegion: String? = nil

    var body: some View {
        NavigationView {
            Form {
                // SECTION - Informations principales
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

                // SECTION - Lieu de travail
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
                }

                // SECTION - Contact
                Section(header: Text("Contact")) {
                    TextField("Téléphone", text: $contact.phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $contact.email)
                        .keyboardType(.emailAddress)
                }

                // SECTION - Notes
                Section(header: Text("Notes")) {
                    TextField("Notes supplémentaires", text: $contact.notes)
                }
            }
            .navigationTitle("Modifier contact")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        // On reconstruit city en fonction du pays et de la région
                        contact.city = selectedCountry +
                            (selectedCountry == "France" && selectedRegion != nil ? " / \(selectedRegion!)" : "")
                        try? context.save()
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Préremplissage du pays et de la région
                if contact.city.contains("/") {
                    let parts = contact.city.split(separator: "/").map { $0.trimmingCharacters(in: .whitespaces) }
                    if let country = parts.first {
                        selectedCountry = String(country)
                    }
                    if parts.count > 1 {
                        selectedRegion = String(parts[1])
                    }
                } else if !contact.city.isEmpty {
                    selectedCountry = contact.city
                }
            }
        }
    }
}
