import Foundation

/// Minimal user model for follower and mutual connections
struct UserMinimal: Identifiable, Decodable {
    let id: Int
    let email: String?
    let full_name: String?

    /// Display name preference: full_name if available, else email
    var displayName: String {
        full_name ?? email ?? "Unknown"
    }
}