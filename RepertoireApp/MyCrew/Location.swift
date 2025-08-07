import Foundation

struct Location: Codable, Identifiable, Equatable {
    var id = UUID()
    var country: String
    var region: String? = nil // Changé de String = "" à String? = nil
    var isLocalResident: Bool
    var hasVehicle: Bool
    var isHoused: Bool
    var isPrimary: Bool

    static let example = Location(
        country: "France",
        region: "Île-de-France",
        isLocalResident: true,
        hasVehicle: false,
        isHoused: false,
        isPrimary: true
    )
}
