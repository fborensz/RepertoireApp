import SwiftData
import Foundation

@Model
class Contact {
    var id: UUID
    var name: String
    var jobTitle: String
    var city: String
    var skills: String
    var phone: String
    var email: String
    var notes: String
    var isFavorite: Bool
    
    init(
        name: String,
        jobTitle: String,
        city: String,
        skills: String,
        phone: String,
        email: String,
        notes: String,
        isFavorite: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.jobTitle = jobTitle
        self.city = city
        self.skills = skills
        self.phone = phone
        self.email = email
        self.notes = notes
        self.isFavorite = isFavorite
    }
}
