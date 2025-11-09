import UIKit

/// Helper to manage haptic feedback and suppress errors in simulator
struct HapticFeedbackHelper {
    /// Check if running on a real device (not simulator)
    static var isRealDevice: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return true
        #endif
    }
    
    /// Safely trigger impact feedback (only on real devices)
    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard isRealDevice else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    /// Safely trigger notification feedback (only on real devices)
    static func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isRealDevice else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    /// Safely trigger selection feedback (only on real devices)
    static func selection() {
        guard isRealDevice else { return }
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

