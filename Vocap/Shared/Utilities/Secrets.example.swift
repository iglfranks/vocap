import Foundation

/// Template for Secrets.swift
///
/// Setup Instructions:
/// 1. Copy this file to `Secrets.swift` in the same directory
/// 2. Fill in your actual Supabase credentials
/// 3. Secrets.swift is gitignored and will not be committed
///
/// To get your Supabase credentials:
/// 1. Go to https://supabase.com and open your project
/// 2. Navigate to Settings > API
/// 3. Copy the "Project URL" and "anon public" key

enum Secrets {
    /// Your Supabase project URL (from Settings > API)
    /// Example: "https://abcdefghijklmnop.supabase.co"
    static let supabaseURL = "https://oticnekxludxjumjjfee.supabase.co"

    /// Your Supabase anon/public key (from Settings > API)
    /// This key is safe to use in client apps (protected by RLS)
    static let supabaseAnonKey =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im90aWNuZWt4bHVkeGp1bWpqZmVlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjczNDY4NjgsImV4cCI6MjA4MjkyMjg2OH0.sd1xRTtDin4lnqT0pwaNzM51jh3A9UfM_kND6iIlX1s"
}
