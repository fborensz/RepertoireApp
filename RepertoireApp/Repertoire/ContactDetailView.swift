// ContactDetailView.swift - Version mise à jour avec export
import SwiftUI
import SwiftData

struct ContactDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var showDeleteAlert = false
    @Bindable var contact: Contact

    var body: some View {
        Form {
            Section(header: Text("Informations principales")) {
                HStack {
                    Text("Nom")
                    Spacer()
                    Text(contact.name)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Poste")
                    Spacer()
                    Text(contact.jobTitle)
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("Lieu de travail")) {
                // Lieu principal
                if let primaryLoc = contact.primaryLocation {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Principal")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                            Spacer()
                        }
                        
                        Text(primaryLoc.country + (primaryLoc.region != nil ? " / \(primaryLoc.region!)" : ""))
                        
                        // Icônes subtiles pour les options actives
                        HStack(spacing: 16) {
                            if primaryLoc.hasVehicle {
                                Image(systemName: "car.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            if primaryLoc.isHoused {
                                Image(systemName: "house.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            if primaryLoc.isLocalResident {
                                Image(systemName: "building.columns.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(.bottom, 8)
                }
                
                // Lieux secondaires
                ForEach(Array(contact.secondaryLocations.enumerated()), id: \.element.id) { index, secondaryLoc in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Secondaire \(index + 1)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(Capsule())
                            Spacer()
                        }
                        
                        Text(secondaryLoc.country + (secondaryLoc.region != nil ? " / \(secondaryLoc.region!)" : ""))
                        
                        // Icônes subtiles pour les options actives
                        HStack(spacing: 16) {
                            if secondaryLoc.hasVehicle {
                                Image(systemName: "car.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            if secondaryLoc.isHoused {
                                Image(systemName: "house.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            if secondaryLoc.isLocalResident {
                                Image(systemName: "building.columns.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(.bottom, 4)
                }
                
                // Si aucun lieu principal n'est défini, afficher le premier comme fallback
                if contact.primaryLocation == nil && !contact.locations.isEmpty {
                    let firstLoc = contact.locations[0]
                    VStack(alignment: .leading, spacing: 8) {
                        Text(firstLoc.country + (firstLoc.region != nil ? " / \(firstLoc.region!)" : ""))
                        
                        HStack(spacing: 16) {
                            if firstLoc.hasVehicle {
                                Image(systemName: "car.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            if firstLoc.isHoused {
                                Image(systemName: "house.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            if firstLoc.isLocalResident {
                                Image(systemName: "building.columns.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            }

            Section(header: Text("Contact")) {
                if !contact.phone.isEmpty {
                    HStack {
                        Text("Téléphone")
                        Spacer()
                        Text(contact.phone)
                            .foregroundColor(.blue)
                    }
                }
                if !contact.email.isEmpty {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(contact.email)
                            .foregroundColor(.blue)
                    }
                }
            }

            if !contact.notes.isEmpty {
                Section(header: Text("Notes")) {
                    Text(contact.notes)
                }
            }

            Section {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Supprimer ce contact", systemImage: "trash")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle(contact.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    contact.toggleFavorite()
                    try? context.save()
                } label: {
                    Image(systemName: contact.isFavorite ? "star.fill" : "star")
                        .foregroundColor(contact.isFavorite ? .yellow : .gray)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button {
                        shareContact(contact)
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    
                    Button("Modifier") {
                        isEditing = true
                    }
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditContactView(contact: contact)
        }
        .alert("Supprimer ce contact ?", isPresented: $showDeleteAlert, actions: {
            Button("Annuler", role: .cancel) { }
            Button("Supprimer", role: .destructive) {
                context.delete(contact)
                try? context.save()
                dismiss()
            }
        }, message: {
            Text("Cette action est irréversible.")
        })
    }
    
    private func shareContact(_ contact: Contact) {
        // Créer les deux formats de partage
        let textToShare = ContactSharingManager.shared.exportContactAsText(contact)
        
        var itemsToShare: [Any] = [textToShare]
        
        // Ajouter le fichier JSON si disponible
        if let fileURL = ContactSharingManager.shared.exportContact(contact) {
            itemsToShare.append(fileURL)
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: itemsToShare,
            applicationActivities: nil
        )
        
        // Exclure certaines activités non pertinentes
        activityViewController.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .openInIBooks
        ]
        
        // Pour iPad
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            if let popover = activityViewController.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootViewController.present(activityViewController, animated: true)
        }
    }
}
