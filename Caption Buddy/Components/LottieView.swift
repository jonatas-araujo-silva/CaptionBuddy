import SwiftUI
import Lottie

// Acts as a wrapper around UIKit's LottieAnimationView. Use Coordinator pattern
 
struct LottieView: UIViewRepresentable {
    // The name of the Lottie animation file
    var name: String
    // The loop behavior of the animation
    var loopMode: LottieLoopMode = .playOnce
    // The playback speed of the animation
    var animationSpeed: CGFloat = 1

    // Creates the Coordinator instance that will manage the LottieAnimationView.
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // Creates the initial UIView. This is called only once.
    func makeUIView(context: UIViewRepresentableContext<LottieView>) -> UIView {
        let view = UIView(frame: .zero)
        context.coordinator.animationView.contentMode = .scaleAspectFit
        view.addSubview(context.coordinator.animationView)
        
        context.coordinator.animationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            context.coordinator.animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            context.coordinator.animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])

        return view
    }

    // This function is now responsible for telling the Coordinator to update the animation.
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<LottieView>) {
        context.coordinator.parent = self
        context.coordinator.updateAnimation()
    }
    
    /*Makes the LottieView works.
     * persists for the entire lifecycle of the view, holding onto the LottieAnimationView
     * instance and preventing it from being recreated unnecessarily.
     */
    
    class Coordinator: NSObject {
        var parent: LottieView
        var animationView = LottieAnimationView()

        init(_ parent: LottieView) {
            self.parent = parent
        }
        
        // Called by updateUIView to apply the new animation properties.
        func updateAnimation() {
            animationView.animation = LottieAnimation.named(parent.name)
            animationView.loopMode = parent.loopMode
            animationView.animationSpeed = parent.animationSpeed
            
            // Ensure the animation plays from the beginning.
            animationView.currentProgress = 0
            animationView.play()
        }
    }
}
