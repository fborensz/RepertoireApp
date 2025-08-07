import SwiftUI
import SwiftData

struct ContactDetailView: View {
    @Bindable var contact: Contact
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // En-tête avec nom et QR Code
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(contact.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(MyCrewColors.textPrimary)
                        
                        Text(contact.jobTitle)
                            .font(.headline)
                            .foregroundColor(MyCrewColors.accent)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        if contact.isFavorite {
                            Image(systemName: "star.fill")
                                .foregroundColor(MyCrewColors.favoriteStar)
                        }
                        
                        // QR Code miniature (NOUVEAUTÉ)
                        QRCodeMiniature(contact: contact)
                    }
                }
                
                Divider()
                
                if let primaryLoc = contact.primaryLocation {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Lieu principal")
                            .font(.subheadline)
                            .foregroundColor(MyCrewColors.accent)
                        Text("\(primaryLoc.country) \(primaryLoc.region ?? "")")
                            .foregroundColor(MyCrewColors.textPrimary)
                        locationAttributesView(for: primaryLoc)
                    }
                }
                
                if !contact.secondaryLocations.isEmpty {
                    ForEach(contact.secondaryLocations, id: \.id) { loc in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Lieu secondaire")
                                .font(.subheadline)
                                .foregroundColor(MyCrewColors.accent)
                            Text("\(loc.country) \(loc.region ?? "")")
                                .foregroundColor(MyCrewColors.textPrimary)
                            locationAttributesView(for: loc)
                        }
                        Divider()
                    }
                }
                
                if !contact.phone.isEmpty {
                    Label(contact.phone, systemImage: "phone.fill")
                        .foregroundColor(MyCrewColors.textPrimary)
                }
                
                if !contact.email.isEmpty {
                    Label(contact.email, systemImage: "envelope.fill")
                        .foregroundColor(MyCrewColors.textPrimary)
                }
                
                if !contact.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Notes")
                            .font(.subheadline)
                            .foregroundColor(MyCrewColors.accent)
                        Text(contact.notes)
                            .foregroundColor(MyCrewColors.textPrimary)
                    }
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        exportContact()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(MyCrewColors.accent)
                    }
                    
                    NavigationLink(destination: EditContactView(contact: contact)) {
                        Text("Modifier")
                            .foregroundColor(MyCrewColors.accent)
                    }
                }
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
        .background(MyCrewColors.background.ignoresSafeArea())
    }
    
    private func exportContact() {
        let sharingManager = ContactSharingManager.shared
        let result = sharingManager.exportContact(contact, format: .json)
        
        if let url = result.content as? URL {
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.present(activityVC, animated: true)
            }
        }
    }
    
    private func locationAttributesView(for location: WorkLocation) -> some View {
        HStack(spacing: 12) {
            if location.hasVehicle {
                Image(systemName: "car.fill")
                    .foregroundColor(MyCrewColors.iconMuted)
            }
            if location.isHoused {
                Image(systemName: "house.fill")
                    .foregroundColor(MyCrewColors.iconMuted)
            }
            if location.isLocalResident {
                Image(systemName: "building.columns.fill")
                    .foregroundColor(MyCrewColors.iconMuted)
            }
        }
    }
}
