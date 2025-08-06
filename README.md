**Caption Buddy**

<p align="center">
<img src="https://raw.githubusercontent.com/jonatas-araujo-silva/CaptionBuddy/main/Caption%20Buddy/Resources/AppIcon-Launch.png" width="200">
</p>

<p align="center">
<strong>An iOS application built to explore accessibility in video communication through automated captioning and sign language animation.</strong>
</p>

<p align="center">
<a href="https://github.com/jonatas-araujo-silva/CaptionBuddy">
<img src="https://img.shields.io/badge/status-in_development-yellow" alt="Status">
</a>
<img src="https://img.shields.io/badge/platform-iOS-lightgrey.svg" alt="Platform">
</p>


🎬 **Demo**
This demo showcases the app's core features, including the live stream with synchronized captions, Lottie animations, and the reactive video library with generated thumbnails.

****Note**: This GIF is optimized for web viewing and has a reduced frame rate. The actual application runs at a native 60 FPS.**

<p align="center">
<img src="Caption%20Buddy/Resources/DemoResources/CaptionBuddy-First-Demo-ezgif.com-optimize.gif">
</p>

This project is the first part of a planned suite of applications focused on improving workflows and accessibility for people with disabilities.


**Problem & Solution**
In an increasingly video-first world, a significant amount of content remains inaccessible to the deaf and hard-of-hearing community. 
Caption Buddy is an exploration of how native iOS technologies can be used to bridge this.

The app is designed to handle two main accessibility scenarios:
For Pre-Recorded Content: It provides a complete pipeline to take a recorded video, automatically generate a timed transcript using the Speech framework, 
and then display those captions synchronized with the video playback.
For Live Communication: It includes a fully built-out UI and architecture for a live meeting feature, 
designed to transcribe spoken audio into both text and sign language animations in real-time.


**✨ Core Features**
Video Recording: A custom recorder built with AVFoundation.
Timed Transcription: Uses Apple's native Speech framework to generate word-by-word timed captions from recorded audio.
Reactive Video Library: A SwiftUI List built with @FetchRequest that displays all saved recordings with asynchronously generated video thumbnails. 
The view is directly connected to the Core Data store and updates instantly.
Synchronized Playback: A custom AVPlayer-based view that displays the currently spoken word and trigger a corresponding Lottie animation for real-time sign language interpretation.
Live Stream: A complete UI/UX for a live streaming feature, including a participant list and a real-time chat, designed to be powered by a real-time communication SDK like Agora.


**🛠️ Technology & Architecture**
The app is built using a modern, professional technology stack, with a focus on performance, testability, and clean architecture.

UI: SwiftUI, including "liquid glass" .ultraThinMaterial effects and UIViewRepresentable to wrap UIKit components (AVCaptureVideoPreviewLayer, Agora's UIView) for use in SwiftUI.
Media Pipeline: AVFoundation & AVKit.
Live Streaming: Agora SDK for real-time video and data channels.
Transcription: Speech Framework.
Animation: Lottie API for iOS.
Concurrency: A hybrid approach using both Swift Concurrency (async/await, @MainActor) for background tasks and the Combine framework for reactive state management with @Published.
Data Persistence: Core Data, with a reactive UI built using @FetchRequest.
Testing: XCTest for Unit & UI Tests.


**🚀 Project Status & Roadmap**
This project is in active development. The core features are functional, and the next phase of work is focused on refinement and expanding the feature set.

[ ] Video Import: Add the ability for users to import videos directly from their device's photo library.
[ ] macOS Version: Build a native macOS version of the app to expand the suite of tools.
[ ] Expanded Animation Library.


**⚙️ Getting Started**
The project is a standard Xcode project. To build and run:

Clone the repository:
git clone https://github.com/jonatas-araujo-silva/CaptionBuddy.git
Open CaptionBuddy.xcodeproj in Xcode.
The app is configured to run on the iOS Simulator, which uses pre-loaded video and caption files for a complete demo experience.


**🔄 CI/CD Pipeline**
The project includes a complete Continuous Integration and Continuous Deployment (CI/CD) pipeline using Fastlane and GitHub Actions.

Automation: The Fastfile is configured with lanes to automatically run all unit and UI tests (tests) and to build and deploy a new version to TestFlight (beta).
Continuous Integration: The GitHub Actions workflow (main.yml) is triggered on every push to the main branch. It automatically checks out the code on a virtual macOS runner, runs all the tests, and prepares a build.
Secret Management: Sensitive information, such as the App Store Connect API Key and the Agora App ID, is managed securely using GitHub Secrets.
