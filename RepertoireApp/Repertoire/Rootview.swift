import SwiftUI

struct RootView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header customisé
            HStack {
                
                Image("MyCrewLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                
                
                Text("Trouvez, contactez, tournez")
                    .font(.headline)
                    .foregroundColor(MyCrewColors.accent)
                    .padding(.leading, 12)

         
            }
            .padding(.vertical, 6) // réduit l’espace vertical (~70% de moins)
            .background(MyCrewColors.background)
            
            // Contenu de l’app
            NavigationView {
                ContentView()
                    .navigationBarHidden(false) // cache le titre système
            }
            .background(MyCrewColors.background.ignoresSafeArea())
        }
        .background(MyCrewColors.background.ignoresSafeArea())
    }
}
