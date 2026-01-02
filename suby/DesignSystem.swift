//
//  DesignSystem.swift
//  suby
//
//  Created by Daniel Ng Zheng Hui on 1/2/26.
//

import SwiftUI

struct AppTheme {
    static let background = Color(hex: "#050511") // Very dark blue/black
    static let primaryText = Color.white
    static let secondaryText = Color.gray
    
    // Glassmorphism background for cards
    static let glassMaterial = Material.ultraThin
}

extension View {
    func glassEffect() -> some View {
        self
            .background(AppTheme.glassMaterial)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(LinearGradient(colors: [.white.opacity(0.2), .white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            )
    }
    
    func appBackground() -> some View {
        self
            .background(AppTheme.background)
            .preferredColorScheme(.dark) // Force dark mode for now
    }
}

// Helper to get a gradient from a single hex color
extension Color {
    func gradient(to color: Color? = nil) -> LinearGradient {
        let endColor = color ?? self.opacity(0.6)
        return LinearGradient(colors: [self, endColor], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
