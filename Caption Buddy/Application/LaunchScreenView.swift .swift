import SwiftUI

/* Displays the app icon with a subtle pulsing animation and then
 * transitions to the main view.
 */
struct LaunchScreenView: View {
    
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    
    var body: some View {
        if isActive {
            MainView()
        } else {
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
                    
                    // After delay, set isActive to true to trigger transition
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            self.isActive = true
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
