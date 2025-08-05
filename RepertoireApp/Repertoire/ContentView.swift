import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Query private var contacts: [Contact]

    var body: some View {
        NavigationView {
            List {
                ForEach(contacts) { contact in
                    NavigationLink(destination: ContactDetailView(contact: contact)) {
                        VStack(alignment: .leading) {
                            Text(contact.name)
                                .font(.headline)
                            Text("\(contact.jobTitle) • \(contact.city)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Mes Contacts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: AddContactView()) {
                        Label("Ajouter", systemImage: "plus")
                    }
                }
            }
        }
    }
}
