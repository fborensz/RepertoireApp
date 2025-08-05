import SwiftUI
import SwiftData

@main
struct RepertoireApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Contact.self, WorkLocation.self])
    }
}
