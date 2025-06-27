import SwiftUI
import Lottie

/*
 * reusable SwiftUI component that acts as a wrapper around UIKit's LottieAnimationView
 * It allows us to embed Lottie animations within our SwiftUI views
 *
 * How to use:
 * LottieView(name: "my_animation_name", loopMode: .loop)
 *
 * Parameters:
 * - name: The filename of the .lottie (or .json) animation file in your asset bundle.
 * - loopMode: How the animation should play (e.g., play once, loop, autoplay).
 * - animationSpeed: The speed at which the animation should play.
 */
struct LottieView: UIViewRepresentable {
    // The name of the Lottie animation file
    var name: String
    // The loop behavior of the animation
    var loopMode: LottieLoopMode = .playOnce
    // The playback speed of the animation
    var animationSpeed: CGFloat = 1

    // This view will host our Lottie animation
    private let animationView = LottieAnimationView()

    // Creates the initial UIView.
    func makeUIView(context: UIViewRepresentableContext<LottieView>) -> UIView {
        let view = UIView(frame: .zero)

        // 1. Load the animation by name
        animationView.animation = LottieAnimation.named(name)
        // 2. Set the content mode to scale aspect fit
        animationView.contentMode = .scaleAspectFit
        // 3. Set the loop mode
        animationView.loopMode = loopMode
        // 4. Set the animation speed
        animationView.animationSpeed = animationSpeed
        // 5. Play the animation
        animationView.play()

        // Add the animationView as a subview and set up constraints
        view.addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])

        return view
    }

    // This function is called when SwiftUI state changes, but we don't need it for this simple view.
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<LottieView>) {
        // You could add logic here to update the animation if the name or loopMode changes.
        // For now, we will just have it play again on updates.
        animationView.play()
    }
}


#Preview {
    LottieView(name: "Lottie View")
}
