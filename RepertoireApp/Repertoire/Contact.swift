import SwiftData
import Foundation

@Model
class Contact {
    var id: UUID
    var name: String
    var jobTitle: String
    var phone: String
    var email: String
    var notes: String
    var isFavorite: Bool
    var locations: [WorkLocation]
    
    init(
        name: String,
        jobTitle: String,
        phone: String,
        email: String,
        notes: String,
        isFavorite: Bool = false,
        locations: [WorkLocation] = []
    ) {
        self.id = UUID()
        self.name = name
        self.jobTitle = jobTitle
        self.phone = phone
        self.email = email
        self.notes = notes
        self.isFavorite = isFavorite
        self.locations = locations
    }
    
    // Propriété computed pour la compatibilité avec l'ancien code
    var city: String {
        if let firstLocation = locations.first {
            return firstLocation.country + (firstLocation.region != nil ? " / \(firstLocation.region!)" : "")
        }
        return "Non spécifié"
    }
}
