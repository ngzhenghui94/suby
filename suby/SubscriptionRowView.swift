//
//  SubscriptionRowView.swift
//  suby
//
//  Created by Daniel Ng Zheng Hui on 1/2/26.
//

import SwiftUI

struct SubscriptionRowView: View {
    let subscription: Subscription
    
    var body: some View {
        HStack(spacing: 15) {
            Circle()
                .fill(Color(hex: subscription.colorHex).gradient(to: Color(hex: subscription.colorHex).opacity(0.7)))
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: subscription.iconName).font(.caption).foregroundColor(.white))
                .shadow(color: Color(hex: subscription.colorHex).opacity(0.5), radius: 5)
            
            VStack(alignment: .leading) {
                Text(subscription.name)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text(subscription.billingCycle)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(subscription.currency) \(subscription.price, specifier: "%.2f")")
                    .font(.callout)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
        }
        .padding()
        .glassEffect()
    }
}
