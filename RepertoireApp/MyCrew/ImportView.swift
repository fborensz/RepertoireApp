import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var showingFilePicker = false
    @State private var importResult: ImportResult?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    struct ImportResult {
        let success: Bool
        let contactsImported: Int
        let message: String
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    Image(systemName: "square.and.arrow.down.on.square")
                        .font(.system(size: 50))
                        .foregroundColor(MyCrewColors.accent)
                    
                    Text("Importer des contacts")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(MyCrewColors.textPrimary)
                    
                    Text("Sélectionnez un fichier JSON ou CSV exporté depuis MyCrew")
                        .font(.body)
                        .foregroundColor(MyCrewColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 12) {
                    Text("Formats supportés :")
                        .font(.headline)
                        .foregroundColor(MyCrewColors.textPrimary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Fichiers JSON (.json)", systemImage: "doc.text")
                            .foregroundColor(MyCrewColors.textSecondary)
                        Label("Fichiers CSV (.csv)", systemImage: "tablecells")
                            .foregroundColor(MyCrewColors.textSecondary)
                    }
                }
                .padding()
                .background(MyCrewColors.cardBackground)
                .cornerRadius(10)
                
                Button {
                    showingFilePicker = true
                } label: {
                    HStack {
                        Image(systemName: "folder")
                        Text("Choisir un fichier")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(MyCrewColors.accent)
                    .cornerRadius(10)
                }
                
                if let result = importResult {
                    VStack(spacing: 8) {
                        Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(result.success ? .green : .red)
                        
                        Text(result.success ? "Import réussi !" : "Erreur d'import")
                            .font(.headline)
                            .foregroundColor(result.success ? .green : .red)
                        
                        if result.success {
                            Text("\(result.contactsImported) contact(s) importé(s)")
                                .foregroundColor(MyCrewColors.textSecondary)
                        }
                        
                        Text(result.message)
                            .font(.caption)
                            .foregroundColor(MyCrewColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(MyCrewColors.cardBackground)
                    .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
            .background(MyCrewColors.background)
            .navigationTitle("Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundColor(MyCrewColors.accent)
                }
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [UTType.json, UTType.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .alert("Import", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Démarrer l'accès sécurisé au fichier
            guard url.startAccessingSecurityScopedResource() else {
                importResult = ImportResult(
                    success: false,
                    contactsImported: 0,
                    message: "Impossible d'accéder au fichier sélectionné"
                )
                return
            }
            
            // S'assurer d'arrêter l'accès même en cas d'erreur
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            do {
                let importedContacts = try ContactSharingManager.shared.importContacts(from: url, context: context)
                importResult = ImportResult(
                    success: true,
                    contactsImported: importedContacts.count,
                    message: "Les contacts ont été ajoutés avec succès"
                )
            } catch {
                importResult = ImportResult(
                    success: false,
                    contactsImported: 0,
                    message: "Erreur lors de l'import : \(error.localizedDescription)"
                )
            }
            
        case .failure(let error):
            alertMessage = "Erreur lors de la sélection du fichier : \(error.localizedDescription)"
            showingAlert = true
        }
    }
}
