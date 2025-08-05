import SwiftUI
import SwiftData

struct ContactDetailView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var showDeleteAlert = false

    var contact: Contact

    var body: some View {
        Form {
            Section(header: Text("Informations")) {
                HStack {
                    Text("Nom")
                    Spacer()
                    Text(contact.name)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Poste")
                    Spacer()
                    Text(contact.jobTitle)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Ville")
                    Spacer()
                    Text(contact.city)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Compétences")
                    Spacer()
                    Text(contact.skills)
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("Contact")) {
                if !contact.phone.isEmpty {
                    HStack {
                        Text("Téléphone")
                        Spacer()
                        Text(contact.phone)
                            .foregroundColor(.blue)
                    }
                }
                if !contact.email.isEmpty {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(contact.email)
                            .foregroundColor(.blue)
                    }
                }
            }

            if !contact.notes.isEmpty {
                Section(header: Text("Notes")) {
                    Text(contact.notes)
                }
            }

            Section {
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Supprimer ce contact", systemImage: "trash")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .navigationTitle(contact.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Modifier") {
                    isEditing = true
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditContactView(contact: contact)
        }
        .alert("Supprimer ce contact ?", isPresented: $showDeleteAlert, actions: {
            Button("Annuler", role: .cancel) { }
            Button("Supprimer", role: .destructive) {
                context.delete(contact)
                try? context.save()
                dismiss()
            }
        }, message: {
            Text("Cette action est irréversible.")
        })
    }
}
