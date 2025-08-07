import SwiftUI

struct UserProfileEditorView: View {
    @Binding var userProfile: UserProfile
    @Environment(\.dismiss) var dismiss
    
    // État local pour éviter la sauvegarde automatique
    @State private var editedProfile: UserProfile
    @State private var showingResidenceAlert = false // Pour l'alerte résidence fiscale
    
    // Initializer pour copier le profil
    init(userProfile: Binding<UserProfile>) {
        self._userProfile = userProfile
        self._editedProfile = State(initialValue: userProfile.wrappedValue)
    } // Correction: \.dismiss au lieu de .dismiss

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Prénom", text: $editedProfile.firstName)
                    TextField("Nom", text: $editedProfile.lastName)
                    
                    // Menu pour le métier (comme dans AddContactView)
                    Menu {
                        ForEach(JobTitles.departments.keys.sorted(), id: \.self) { department in
                            Section(header: Text(department)) {
                                ForEach(JobTitles.departments[department]!, id: \.self) { job in
                                    Button(job) { editedProfile.jobTitle = job }
                                }
                            }
                        }
                    } label: {
                        Label(editedProfile.jobTitle.isEmpty ? "Choisir un poste" : editedProfile.jobTitle,
                              systemImage: "briefcase")
                        .foregroundColor(MyCrewColors.accent)
                    }
                } header: {
                    Text("Identité")
                }

                Section {
                    TextField("Téléphone", text: $editedProfile.phoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $editedProfile.email)
                        .keyboardType(.emailAddress)
                } header: {
                    Text("Contact")
                }

                Section {
                    ForEach(editedProfile.locations.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(index == 0 ? "Lieu principal" : "Lieu secondaire \(index)")
                                    .font(.subheadline)
                                    .foregroundColor(MyCrewColors.accent)
                                Spacer()
                                
                                // Bouton supprimer (sauf pour le premier lieu qui est toujours principal)
                                if index > 0 {
                                    Button {
                                        editedProfile.locations.remove(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.title3)
                                    }
                                    .buttonStyle(BorderlessButtonStyle()) // IMPORTANT : évite les conflits de tap
                                }
                            }
                            
                            Picker("Pays", selection: $editedProfile.locations[index].country) {
                                ForEach(Locations.countries, id: \.self) { country in
                                    Text(country).tag(country)
                                }
                            }
                            
                            if editedProfile.locations[index].country == "France" {
                                Picker("Région", selection: Binding(
                                    get: { editedProfile.locations[index].region ?? Locations.frenchRegions.first! },
                                    set: { editedProfile.locations[index].region = $0 }
                                )) {
                                    ForEach(Locations.frenchRegions, id: \.self) { region in
                                        Text(region).tag(region as String?)
                                    }
                                }
                            }
                            
                            Toggle("Résidence fiscale", isOn: Binding(
                                get: { editedProfile.locations[index].isLocalResident },
                                set: { newValue in
                                    if newValue {
                                        // Vérifier s'il y a déjà une résidence fiscale
                                        let hasExistingResident = editedProfile.locations.enumerated().contains { (idx, loc) in
                                            idx != index && loc.isLocalResident
                                        }
                                        
                                        if hasExistingResident {
                                            showingResidenceAlert = true
                                        } else {
                                            editedProfile.locations[index].isLocalResident = true
                                        }
                                    } else {
                                        editedProfile.locations[index].isLocalResident = false
                                    }
                                }
                            ))
                                .tint(MyCrewColors.accent)
                            Toggle("Véhiculé", isOn: $editedProfile.locations[index].hasVehicle)
                                .tint(MyCrewColors.accent)
                            Toggle("Logé", isOn: $editedProfile.locations[index].isHoused)
                                .tint(MyCrewColors.accent)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Button(action: {
                        editedProfile.locations.append(Location(
                            country: "Worldwide",
                            region: nil,
                            isLocalResident: false,
                            hasVehicle: false,
                            isHoused: false,
                            isPrimary: false // Toujours faux pour les lieux ajoutés
                        ))
                    }) {
                        Label("Ajouter un lieu", systemImage: "plus")
                            .foregroundColor(MyCrewColors.accent)
                    }
                } header: {
                    Text("Lieux de travail")
                }
            }
            .navigationTitle("Ma fiche pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss() // Ne sauvegarde PAS les modifications
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer") {
                        // S'assurer que le premier lieu est marqué comme principal
                        for (index, _) in editedProfile.locations.enumerated() {
                            editedProfile.locations[index].isPrimary = (index == 0)
                        }
                        
                        userProfile = editedProfile // Applique les modifications
                        userProfile.save() // Sauvegarde
                        dismiss()
                    }
                    .foregroundColor(MyCrewColors.accent)
                }
            }
        }
        .alert("Résidence fiscale unique", isPresented: $showingResidenceAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Vous ne pouvez avoir qu'une seule résidence fiscale")
        }
    }
}
