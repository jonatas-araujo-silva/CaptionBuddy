import SwiftUI

// View that acts as the app's launch screen.
struct LaunchScreenView: View {
    
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                Image("AppIcon-Launch")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                
                Text("Caption Buddy")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .scaleEffect(size)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.8)) {
                    self.size = 0.9
                    self.opacity = 1.0
                }
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
