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
    static let glassMaterial = Material.ultraThinMaterial // Or .thinMaterial if ultraThin is too light
}

struct AnimatedBackgroundView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            // Random floating blobs
            Circle()
                .fill(Color(hex: "#5E5CE6").opacity(0.4))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: animate ? -100 : 100, y: animate ? -50 : 50)
            
            Circle()
                .fill(Color(hex: "#30B0C7").opacity(0.3))
                .frame(width: 250, height: 250)
                .blur(radius: 50)
                .offset(x: animate ? 150 : -150, y: animate ? 100 : -100)
            
            Circle()
                .fill(Color(hex: "#AF52DE").opacity(0.3))
                .frame(width: 350, height: 350)
                .blur(radius: 70)
                .offset(x: animate ? -50 : 50, y: animate ? 200 : -200)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

extension View {
    func glassEffect() -> some View {
        self
            .background(Material.thinMaterial) // Slightly stronger blur
            .cornerRadius(24) // Rounded pop
            .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 10) // Soft shadow
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(LinearGradient(colors: [.white.opacity(0.3), .white.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            )
    }
    
    func appBackground() -> some View { // No longer used if we use AnimatedBackgroundView directly, but good to keep
        self
            .background(AppTheme.background)
            .preferredColorScheme(.dark)
    }
}

// Helper to get a gradient from a single hex color
extension Color {
    func gradient(to color: Color? = nil) -> LinearGradient {
        let endColor = color ?? self.opacity(0.6)
        return LinearGradient(colors: [self, endColor], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
