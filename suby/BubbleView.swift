//
//  BubbleView.swift
//  suby
//
//  Created by Daniel Ng Zheng Hui on 1/2/26.
//

import SwiftUI

struct BubbleView: View {
    let subscription: Subscription
    
    // Scale factor to determine bubble size relative to cost
    // This might need tuning or a more complex layout engine for a true "cloud" packing
    var size: CGFloat {
        // Base size + cost factor.
        // E.g. $10 -> 80 + 10 = 90
        // $30 -> 80 + 30 = 110
        // Cap at some reasonable max if needed, or use log scale
        let baseSize: CGFloat = 80
        let costFactor: CGFloat = CGFloat(subscription.monthlyCost) * 1.5
        return min(max(baseSize + costFactor, 80), 160)
    }
    
    @State private var animate = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: subscription.colorHex).opacity(1.0), Color(hex: subscription.colorHex).opacity(0.6)],
                        center: .topLeading,
                        startRadius: 5,
                        endRadius: size
                    )
                )
                .shadow(color: Color(hex: subscription.colorHex).opacity(0.6), radius: 12, x: 0, y: 8)
                .overlay(
                    Circle()
                        .stroke(LinearGradient(colors: [.white.opacity(0.4), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                )
            
            VStack(spacing: 4) {
                Text(subscription.name)
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 8)
                
                Text(formatPrice(subscription.price))
                    .font(.system(.headline, design: .rounded))
                    .bold()
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.2), radius: 2)
                
                Text("/\(subscription.billingCycle == "Monthly" ? "mo" : "yr")")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding()
        }
        .frame(width: size, height: size)
        .scaleEffect(animate ? 1.05 : 1.0)
        .offset(y: animate ? -5 : 5)
        .onAppear {
            let delay = Double.random(in: 0...2)
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true).delay(delay)) {
                animate.toggle()
            }
        }
    }
    
    func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = subscription.currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: price)) ?? "$\(price)"
    }
}

// Helper for Hex Colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
