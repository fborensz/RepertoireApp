import SwiftUI

struct MyCrewColors {
    static let background = Color(hex: "#F1F6F3")
    static let accent = Color(hex: "#7BAE7F")
    static let accentSecondary = Color(hex: "#A3C8A8")
    static let textPrimary = Color(hex: "#2F3E34")
    static let textSecondary = Color(hex: "#4A4A4A") // Plus foncé pour meilleure lisibilité
    static let iconMuted = Color(hex: "#6F8F7B")
    static let favoriteStar = Color(hex: "#D9B66F")
    static let cardBackground = Color.white // Pour les cartes de contacts
    static let navigationText = Color.primary // Force le noir pour la navigation
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        
        self.init(red: r, green: g, blue: b)
    }
}
