**Caption Buddy**
An iOS application built to explore accessibility in video communication through automated captioning and sign language animation. 
This project is the first part of a planned suite of applications focused on improving workflows and accessibility for people with disabilities.

**Core Concept**
The primary goal of Caption Buddy is to provide a more accessible video communication tool. 
The app leverages native iOS frameworks to create a seamless pipeline from video recording to captioned playback.

**Features**
The app is currently in active development. 
The existing feature set provides a complete core loop for recording and playback:
Video & Audio Recording: Built with AVFoundation to capture video and audio.
Timed Transcription: Uses the native Speech framework to generate a timed transcript (word-by-word) from recorded audio.
Data Persistence: All recordings and their caption data are saved locally using Core Data.
Video Library: A SwiftUI interface for browsing and playing back saved recordings, featuring asynchronously generated video thumbnails for a responsive UI.
Synchronized Playback: A custom video player that displays captions in real-time as the video plays.
Animation: Demonstrates the ability to trigger a corresponding Lottie animation when a specific keyword from the transcript is spoken.
Live Stream Simulation: A complete UI/UX simulation for a live streaming feature, including a participant list and a real-time chat, designed to be powered by a real-time communication SDK.

**Technology Stack**
UI: SwiftUI
Media Pipeline: AVFoundation, AVKit
Transcription: Speech Framework
Data Persistence: Core Data
Animation: Lottie API
Live Streaming Feature: Agora SDK
Concurrency: Swift Concurrency & Combine
Testing: XCTest for Unit & UI Tests

**Architecture**
The app is built using a modern MVVM architecture, enhanced with a Use Case/Interactor layer for more complex features like live streaming. 
This separation of concerns was chosen to keep the ViewModels lean and focused on state management, while isolating business logic for better testability.
Dependency Injection is used for core services like the DataManager and RecordingService, allowing for robust unit testing with mock objects.

**Project Status**
This project is currently in development. The core features are functional, and the next phase of work is focused on refinement, testing, and expanding the feature set.

**Roadmap & Future Work**
The following features are planned for future development:
Video Import: Add the ability for users to import videos directly from their device's photo library.
macOS Version: Build a native macOS version of the app to expand the suite of tools.

**Getting Started**
The project is a standard Xcode project. To build and run:

Clone the repository:

git clone https://github.com/jonatas-araujo-silva/CaptionBuddy.git

Open CaptionBuddy.xcodeproj in Xcode.

The app is configured to run on the iOS Simulator, which uses pre-loaded video and caption files for a complete demo experience.

**CI/CD**
A Continuous Integration and Deployment pipeline is planned using Fastlane(using Fastlane Match to centralize certifications) and GitHub Actions.
