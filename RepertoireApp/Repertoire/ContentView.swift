// ContentView.swift - Version avec nettoyage
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query private var contacts: [Contact]
    @State private var hasPerformedCleanup = false

    // Contacts triés : favoris en premier, puis par nom
    private var sortedContacts: [Contact] {
        contacts.sorted { contact1, contact2 in
            if contact1.isFavorite && !contact2.isFavorite {
                return true
            } else if !contact1.isFavorite && contact2.isFavorite {
                return false
            } else {
                return contact1.name < contact2.name
            }
        }
    }

    var body: some View {
        NavigationView {
            Group {
                if contacts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.3")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Aucun contact")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Appuyez sur + pour ajouter votre premier contact")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(sortedContacts) { contact in
                            NavigationLink(destination: ContactDetailView(contact: contact)) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(contact.name)
                                            .font(.headline)
                                        Text("\(contact.jobTitle) • \(contact.city)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Étoile de favori
                                    if contact.isFavorite {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Mes Contacts")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("🔧 Nettoyer") {
                        cleanupData()
                    }
                    .font(.caption)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: AddContactView()) {
                        Label("Ajouter", systemImage: "plus")
                    }
                }
            }
            .onAppear {
                if !hasPerformedCleanup {
                    cleanupData()
                    hasPerformedCleanup = true
                }
            }
        }
    }
    
    private func cleanupData() {
        print("🔧 Début du nettoyage des données...")
        
        for contact in contacts {
            var hasChanges = false
            
            // 1. Supprimer les doublons
            let uniqueLocations = removeDuplicateLocations(contact.locations)
            if uniqueLocations.count != contact.locations.count {
                print("🗑️ Suppression de doublons pour \(contact.name)")
                // Supprimer les anciens
                for location in contact.locations {
                    context.delete(location)
                }
                contact.locations = uniqueLocations
                hasChanges = true
            }
            
            // 2. Vérifier les lieux principaux
            let primaryCount = contact.locations.filter { $0.isPrimary }.count
            
            if primaryCount == 0 && !contact.locations.isEmpty {
                print("✅ Définition du lieu principal pour \(contact.name)")
                contact.locations[0].isPrimary = true
                hasChanges = true
            } else if primaryCount > 1 {
                print("🔄 Correction des lieux principaux multiples pour \(contact.name)")
                for (index, location) in contact.locations.enumerated() {
                    location.isPrimary = (index == 0)
                }
                hasChanges = true
            }
            
            // 3. Créer un lieu par défaut si aucun
            if contact.locations.isEmpty {
                print("📍 Création d'un lieu par défaut pour \(contact.name)")
                let defaultLocation = WorkLocation(
                    country: "Worldwide",
                    isPrimary: true
                )
                context.insert(defaultLocation)
                contact.locations = [defaultLocation]
                hasChanges = true
            }
            
            if hasChanges {
                print("💾 Sauvegarde des modifications pour \(contact.name)")
            }
        }
        
        do {
            try context.save()
            print("✅ Nettoyage terminé avec succès")
        } catch {
            print("❌ Erreur lors de la sauvegarde: \(error)")
        }
    }
    
    private func removeDuplicateLocations(_ locations: [WorkLocation]) -> [WorkLocation] {
        var seen = Set<String>()
        var uniqueLocations: [WorkLocation] = []
        
        for location in locations {
            let key = "\(location.country)-\(location.region ?? "")-\(location.isHoused)-\(location.hasVehicle)-\(location.isLocalResident)"
            if !seen.contains(key) {
                seen.insert(key)
                uniqueLocations.append(location)
            }
        }
        
        return uniqueLocations
    }
}
