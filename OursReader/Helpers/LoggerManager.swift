import Foundation

class LoggerManager {
    static let shared = LoggerManager()
    
    private init() {}
    
    private func logEvent(_ category: String, _ event: String, _ details: String? = nil) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
        var logMessage = "[\(timestamp)] [\(category)] \(event)"
        if let details = details {
            logMessage += " - \(details)"
        }
        print(logMessage)
    }
    
    // MARK: - Haptic Feedback Events
    func logHaptic(type: String) {
        logEvent("HAPTIC", "Haptic feedback triggered", type)
    }
    
    // MARK: - Camera Events
    func logCameraAccess() {
        logEvent("CAMERA", "Camera accessed")
    }
    
    func logPhotoCapture() {
        logEvent("CAMERA", "Photo captured")
    }
    
    // MARK: - Photo Library Events
    func logAlbumOpen() {
        logEvent("PHOTOS", "Album opened")
    }
    
    func logPhotoSelection(success: Bool, error: String? = nil) {
        if success {
            logEvent("PHOTOS", "Photo selected successfully")
        } else {
            logEvent("PHOTOS", "Photo selection failed", error)
        }
    }
    
    // MARK: - CloudKit Events
    func logCloudKitOperation(operation: String, success: Bool, error: String? = nil) {
        let status = success ? "succeeded" : "failed"
        logEvent("CLOUDKIT", "Operation: \(operation) \(status)", error)
    }
    
    // MARK: - General App Events
    func logAppEvent(event: String, details: String? = nil) {
        logEvent("APP", event, details)
    }
}
