import SwiftUI
import SwiftData

struct AddContactView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var jobTitle = ""
    @State private var selectedCountry = "Worldwide"
    @State private var selectedRegion: String? = nil
    @State private var phone = ""
    @State private var email = ""
    @State private var notes = ""

    var body: some View {
        NavigationView {
            Form {
                // SECTION - Informations principales
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
                    TextField("Téléphone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                }

                // SECTION - Notes
                Section(header: Text("Notes")) {
                    TextField("Notes supplémentaires", text: $notes)
                }
            }
            .navigationTitle("Ajouter un contact")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        let cityString = selectedCountry +
                            (selectedCountry == "France" && selectedRegion != nil ? " / \(selectedRegion!)" : "")

                        let newContact = Contact(
                            name: name,
                            jobTitle: jobTitle,
                            city: cityString,
                            phone: phone,
                            email: email,
                            notes: notes
                        )
                        context.insert(newContact)
                        dismiss()
                    }
                    .disabled(name.isEmpty || jobTitle.isEmpty)
                }
            }
        }
    }
}
