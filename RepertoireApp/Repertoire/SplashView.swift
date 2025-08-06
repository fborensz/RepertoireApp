import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 1.0
    
    var body: some View {
        ZStack {
            if isActive {
                RootView()
                    .transition(.opacity)
            } else {
                VStack(spacing: 20) {
                    Image("MyCrewLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 140, height: 140)
                        .scaleEffect(scale)
                        .opacity(opacity)
                        .onAppear {
                            // Animation bump
                            withAnimation(.easeOut(duration: 0.6)) {
                                scale = 1.1
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    scale = 1.0
                                }
                            }
                            
                            // Pause de 2 secondes avant fondu
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation(.easeInOut(duration: 1.0)) {
                                    opacity = 0.0
                                }
                            }
                            
                            // Transition vers RootView après fondu
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                withAnimation {
                                    isActive = true
                                }
                            }
                        }
                    
                    Text("Trouvez, contactez, tournez")
                        .font(.headline)
                        .foregroundColor(MyCrewColors.accent)
                        .opacity(opacity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(MyCrewColors.background.ignoresSafeArea())
            }
        }
    }
}
