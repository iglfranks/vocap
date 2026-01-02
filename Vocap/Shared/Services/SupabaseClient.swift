import Foundation
import Supabase

/// Global Supabase client instance
/// Configured with credentials from Secrets.swift
let supabase: SupabaseClient = {
    let url = URL(string: Secrets.supabaseURL)!
    let key = Secrets.supabaseAnonKey

    return SupabaseClient(
        supabaseURL: url,
        supabaseKey: key
    )
}()
