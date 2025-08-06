import SwiftUI
import SwiftData

@main
struct RepertoireApp: App {
    var body: some Scene {
        WindowGroup {
            SplashView() // Splash → Root → Content
        }
        .modelContainer(for: [Contact.self, WorkLocation.self])
    }
}
