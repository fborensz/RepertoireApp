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
    
    struct LocationData: Identifiable {
        let id = UUID()
        var country: String = "Worldwide"
        var region: String? = nil
        var isHoused = false
        var isLocalResident = false
        var hasVehicle = false
        var isPrimary = false
    }
    
    // Fonction séparée pour éviter les problèmes de compilation SwiftUI
    @ViewBuilder
    private func locationSectionView(for index: Int) -> some View {
        Section(header: locationHeader(for: index)) {
            locationSection(for: index)
        }
        .listRowBackground(MyCrewColors.cardBackground)
    }
    
    @ViewBuilder
    private func locationHeader(for index: Int) -> some View {
        HStack {
            Text(index == 0 ? "Lieu principal" : "Lieu secondaire \(index)")
                .foregroundColor(MyCrewColors.accent)
            Spacer()
            if locations.count > 1 && index > 0 {
                Button {
                    withAnimation {
                        let _ = locations.remove(at: index)
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
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
                locationSectionView(for: index)
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
        }
        .scrollContentBackground(.hidden)
        .background(MyCrewColors.background)
        .navigationTitle("Nouveau Contact")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annuler") { dismiss() }
                    .foregroundColor(.red)
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
                    
                    var workLocations: [WorkLocation] = []
                    for (index, locationData) in locations.enumerated() {
                        let workLocation = WorkLocation(
                            country: locationData.country,
                            region: locationData.region,
                            isLocalResident: locationData.isLocalResident,
                            hasVehicle: locationData.hasVehicle,
                            isHoused: locationData.isHoused,
                            isPrimary: index == 0
                        )
                        context.insert(workLocation)
                        workLocations.append(workLocation)
                    }
                    newContact.locations = workLocations
                    context.insert(newContact)
                    try? context.save()
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
                        Text("Retour")
                    }
                    .foregroundColor(MyCrewColors.accent)
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
        
        Toggle("Véhiculé", isOn: $locations[index].hasVehicle).tint(MyCrewColors.accent)
        Toggle("Logé", isOn: $locations[index].isHoused).tint(MyCrewColors.accent)
        Toggle("Résidence fiscale", isOn: $locations[index].isLocalResident).tint(MyCrewColors.accent)
    }
}
