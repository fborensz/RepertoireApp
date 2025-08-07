import Foundation
import SwiftUI

struct UserProfile: Codable, Equatable {
    var firstName: String = ""
    var lastName: String = ""
    var jobTitle: String = ""
    var phoneNumber: String = ""
    var email: String = ""
    var locations: [Location] = []
    var isFavorite: Bool = false

    static let storageKey = "UserProfile"

    static func load() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(UserProfile.self, from: data)
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    static func example() -> UserProfile {
        UserProfile(
            firstName: "Jean",
            lastName: "Dupont",
            jobTitle: "Cadreur",
            phoneNumber: "+33 6 12 34 56 78",
            email: "jean.dupont@example.com",
            locations: [],
            isFavorite: true
        )
    }
}
