import SwiftUI

struct ExportOptionsView: View {
    let contacts: [Contact]
    let filterDescription: String
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat: ExportFormat = .json
    @State private var showingShareSheet = false
    @State private var shareItem: Any?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Exporter \(contacts.count) contact(s)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(MyCrewColors.textPrimary)
                
                Text(filterDescription)
                    .font(.caption)
                    .foregroundColor(MyCrewColors.textSecondary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 12) {
                    ForEach([ExportFormat.json, .csv, .text], id: \.self) { format in
                        Button {
                            selectedFormat = format
                        } label: {
                            HStack {
                                Image(systemName: selectedFormat == format ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedFormat == format ? MyCrewColors.accent : .secondary)
                                VStack(alignment: .leading) {
                                    Text(format.displayName)
                                        .foregroundColor(MyCrewColors.textPrimary)
                                        .fontWeight(.medium)
                                    Text(format.description)
                                        .font(.caption)
                                        .foregroundColor(MyCrewColors.textSecondary)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(MyCrewColors.cardBackground)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Button {
                    exportContacts()
                } label: {
                    Text("Exporter")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(MyCrewColors.accent)
                        .cornerRadius(10)
                }
                .padding(.top)
                
                Spacer()
            }
            .padding()
            .background(MyCrewColors.background)
            .navigationTitle("Export")
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
        .sheet(isPresented: $showingShareSheet) {
            if let shareItem = shareItem {
                ShareSheet(activityItems: [shareItem])
            }
        }
    }
    
    private func exportContacts() {
        let sharingManager = ContactSharingManager.shared
        let result = sharingManager.exportContactList(contacts, format: selectedFormat, filterDescription: filterDescription)
        
        if result.isFile, let url = result.content as? URL {
            shareItem = url
        } else if let text = result.content as? String {
            shareItem = text
        }
        
        showingShareSheet = true
    }
}

// MARK: - ShareSheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - ExportFormat Extension
extension ExportFormat {
    var displayName: String {
        switch self {
        case .json: return "JSON"
        case .csv: return "CSV"
        case .text: return "Texte"
        }
    }
    
    var description: String {
        switch self {
        case .json: return "Format structuré, réimportable"
        case .csv: return "Tableur, Excel compatible"
        case .text: return "Texte lisible, partage facile"
        }
    }
}
