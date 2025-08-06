import SwiftUI

extension Contact {
    func matchesFilters(filters: ContentView.FilterSettings) -> Bool {
        // Vérif job
        if filters.selectedJob != "Tous" && self.jobTitle != filters.selectedJob {
            return false
        }

        // Vérif pays
        if filters.selectedCountry != "Tous" {
            let matchingLocations = self.locations.filter { $0.country == filters.selectedCountry }
            if matchingLocations.isEmpty { return false }

            // Vérif régions (si France)
            if filters.selectedCountry == "France" && !filters.selectedRegions.isEmpty {
                let hasMatchingRegion = matchingLocations.contains {
                    $0.region.map { filters.selectedRegions.contains($0) } ?? false
                }
                if !hasMatchingRegion { return false }
            }

            // Vérif attributs
            if filters.includeVehicle && !matchingLocations.contains(where: { $0.hasVehicle }) {
                return false
            }
            if filters.includeHoused && !matchingLocations.contains(where: { $0.isHoused }) {
                return false
            }
            if filters.includeResident && !matchingLocations.contains(where: { $0.isLocalResident }) {
                return false
            }
        } else {
            // Pas de filtre pays : check global
            if filters.includeVehicle && !self.locations.contains(where: { $0.hasVehicle }) {
                return false
            }
            if filters.includeHoused && !self.locations.contains(where: { $0.isHoused }) {
                return false
            }
            if filters.includeResident && !self.locations.contains(where: { $0.isLocalResident }) {
                return false
            }
        }

        return true
    }
}
