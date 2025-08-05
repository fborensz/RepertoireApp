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
    @State private var selectedCountry = "Worldwide"
    @State private var selectedRegion: String? = nil
    @State private var isHoused = false
    @State private var isLocalResident = false
    @State private var hasVehicle = false
    
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
                    TextField("Téléphone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                }
                
                Section(header: Text("Notes")) {
                    TextField("Notes supplémentaires", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
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
                            notes: notes
                        )
                        
                        let workLocation = WorkLocation(
                            country: selectedCountry,
                            region: selectedRegion,
                            isLocalResident: isLocalResident,
                            hasVehicle: hasVehicle,
                            isHoused: isHoused
                        )
                        
                        newContact.locations = [workLocation]
                        
                        context.insert(newContact)
                        try? context.save()
                        dismiss()
                    }
                    .disabled(name.isEmpty || jobTitle.isEmpty)
                }
            }
        }
    }
}
