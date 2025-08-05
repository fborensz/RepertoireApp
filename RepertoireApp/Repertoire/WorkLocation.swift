import Foundation
import SwiftData

@Model
class WorkLocation {
    var id: UUID
    var country: String
    var region: String?
    var isLocalResident: Bool
    var hasVehicle: Bool
    var isHoused: Bool
    var isPrimary: Bool = false // Valeur par défaut pour éviter les erreurs de migration
    
    init(
        country: String,
        region: String? = nil,
        isLocalResident: Bool = false,
        hasVehicle: Bool = false,
        isHoused: Bool = false,
        isPrimary: Bool = false
    ) {
        self.id = UUID()
        self.country = country
        self.region = region
        self.isLocalResident = isLocalResident
        self.hasVehicle = hasVehicle
        self.isHoused = isHoused
        self.isPrimary = isPrimary
    }
}
