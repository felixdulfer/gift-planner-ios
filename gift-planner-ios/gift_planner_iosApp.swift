import SwiftUI
import FirebaseCore

@main
struct gift_planner_iosApp: App {
    @StateObject private var authService = AuthService()
    
    init() {
        FirebaseApp.configure()
        
        // Suppress keyboard haptic feedback errors in simulator
        // This is a known iOS Simulator limitation - haptic hardware is not available
        // The error is harmless and doesn't affect app functionality
        #if targetEnvironment(simulator)
        // Keyboard haptic feedback will fail in simulator, but this is expected
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
        }
    }
}

