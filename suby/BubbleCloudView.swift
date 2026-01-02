//
//  BubbleCloudView.swift
//  suby
//
//  Created by Daniel Ng Zheng Hui on 1/2/26.
//

import SwiftUI

struct BubbleCloudView: View {
    let subscriptions: [Subscription]
    let onSelect: (Subscription) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let sortedSubs = subscriptions.sorted { $0.monthlyCost > $1.monthlyCost }
            
            // Calculate scale to fit
            // Max radius relative to center ~ spacing * sqrt(count) + bubbleRadius
            let spacing: CGFloat = 65 // Reduced spacing for compactness
            let maxBubbleRadius: CGFloat = 80 // Half of max bubble size (160)
            // Tuning: The spiral is tighter than the estimate usually, so we can be slightly less conservative
            let estimatedRadius = spacing * sqrt(Double(sortedSubs.count)) + (maxBubbleRadius * 0.5) 
            
            // Allow it to go slightly beyond bounds (1.1) if needed for a "full" look, or stick to 1.0
            // Using 1.0 margin to keep it safe but larger than before
            let fitScale = min(1.0, min(geometry.size.width, geometry.size.height) / (estimatedRadius * 2))
            
            ZStack {
                ForEach(Array(sortedSubs.enumerated()), id: \.element.id) { index, sub in
                    let position = calculatePosition(index: index, center: center, spacing: spacing)
                    BubbleView(subscription: sub)
                        .position(position)
                        .onTapGesture {
                            onSelect(sub)
                        }
                }
            }
            .scaleEffect(fitScale)
            .animation(.spring(), value: sortedSubs.count)
        }
        // Height estimation: proportional to number of subs to avoid clipping?
        // Or assume caller gives enough height.
        .frame(height: 400) 
    }
    
    // Phyllotaxis (Sunflower) Spiral
    func calculatePosition(index: Int, center: CGPoint, spacing: CGFloat) -> CGPoint {
        if index == 0 { return center }
        
        // Tuning parameters
        let angleIncrement = 2.4 // Golden angle in radians approx
        
        let distance = spacing * sqrt(Double(index))
        let angle = Double(index) * angleIncrement
        
        let x = center.x + CGFloat(cos(angle) * distance)
        let y = center.y + CGFloat(sin(angle) * distance)
        
        return CGPoint(x: x, y: y)
    }
}
