// WorkLocation.swift
import Foundation

struct WorkLocation: Identifiable {
    let id = UUID()
    var country: String
    var region: String? // uniquement pour France
    var isLocalResident: Bool
    var hasVehicle: Bool
    var isHoused: Bool
}
