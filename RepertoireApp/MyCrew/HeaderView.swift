import SwiftUI

struct HeaderView: View {
    var body: some View {
        HStack {
            Image("MyCrewLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .padding(.leading, 12)
            Spacer()
        }
        .padding(.vertical, 8)
        .background(MyCrewColors.background)
    }
}
