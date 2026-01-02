import Foundation
import Supabase

/// Singleton Supabase client instance
final class SupabaseManager: @unchecked Sendable {
    static let shared = SupabaseManager()
    
    /// The Supabase client
    let client: SupabaseClient
    
    private init() {
        client = SupabaseClient(
            supabaseURL: Constants.Supabase.url,
            supabaseKey: Constants.Supabase.anonKey
        )
    }
}

/// Convenience accessor for the Supabase client
var supabase: SupabaseClient {
    SupabaseManager.shared.client
}

