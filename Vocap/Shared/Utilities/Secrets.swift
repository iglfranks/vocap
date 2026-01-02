import Foundation

/// ⚠️ SECRETS - DO NOT COMMIT THIS FILE
/// This file contains sensitive configuration values.
/// Copy from Secrets.example.swift and fill in your actual values.

enum Secrets {
    /// Your Supabase project URL (from Settings > API)
    /// Example: "https://abcdefghijklmnop.supabase.co"
    static let supabaseURL = "https://oticnekxludxjumjjfee.supabase.co"

    /// Your Supabase anon/public key (from Settings > API)
    /// This key is safe to use in client apps (protected by RLS)
    static let supabaseAnonKey =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im90aWNuZWt4bHVkeGp1bWpqZmVlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjczNDY4NjgsImV4cCI6MjA4MjkyMjg2OH0.sd1xRTtDin4lnqT0pwaNzM51jh3A9UfM_kND6iIlX1s"
}
