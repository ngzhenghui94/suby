//
//  Subscription.swift
//  suby
//
//  Created by Daniel Ng Zheng Hui on 1/2/26.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class Subscription {
    var id: UUID = UUID()
    var name: String = ""
    var price: Double = 0.0
    var currency: String = "USD"
    var billingCycle: String = "Monthly"
    var startDate: Date = Date()
    var colorHex: String = "#5E5CE6"
    var iconName: String = "creditcard.fill"
    var category: String = "Other"
    
    init(id: UUID = UUID(),
         name: String,
         price: Double,
         currency: String = "USD",
         billingCycle: String = "Monthly",
         startDate: Date = Date(),
         colorHex: String = "#5E5CE6",
         iconName: String = "creditcard.fill",
         category: String = "Other") {
        self.id = id
        self.name = name
        self.price = price
        self.currency = currency
        self.billingCycle = billingCycle
        self.startDate = startDate
        self.colorHex = colorHex
        self.iconName = iconName
        self.category = category
    }
    
    var monthlyCost: Double {
        if billingCycle == "Yearly" {
            return price / 12.0
        }
        return price
    }
}

enum SubscriptionCategory: String, CaseIterable, Identifiable {
    case entertainment = "Entertainment"
    case utilities = "Utilities"
    case productivity = "Productivity"
    case social = "Social"
    case shopping = "Shopping"
    case health = "Health"
    case finance = "Finance"
    case premiums = "Premiums"
    case other = "Other"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .entertainment: return "tv.fill"
        case .utilities: return "bolt.fill"
        case .productivity: return "briefcase.fill"
        case .social: return "message.fill"
        case .shopping: return "cart.fill"
        case .health: return "heart.fill"
        case .finance: return "banknote.fill"
        case .premiums: return "crown.fill"
        case .other: return "square.grid.2x2.fill"
        }
    }
    
    var color: String {
        switch self {
        case .entertainment: return "#FF2D55" // Pink
        case .utilities: return "#FF9F0A" // Orange
        case .productivity: return "#007AFF" // Blue
        case .social: return "#32D74B" // Green
        case .shopping: return "#AF52DE" // Purple
        case .health: return "#FF375F" // Red
        case .finance: return "#30B0C7" // Teal
        case .premiums: return "#FFD60A" // Gold
        case .other: return "#8E8E93" // Gray
        }
    }
}
