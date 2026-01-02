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
    var id: UUID
    var name: String
    var price: Double
    var currency: String // "USD", "SGD"
    var billingCycle: String // "Monthly", "Yearly"
    var startDate: Date
    var colorHex: String
    var iconName: String
    
    init(id: UUID = UUID(),
         name: String,
         price: Double,
         currency: String = "USD",
         billingCycle: String = "Monthly",
         startDate: Date = Date(),
         colorHex: String = "#5E5CE6",
         iconName: String = "creditcard.fill") {
        self.id = id
        self.name = name
        self.price = price
        self.currency = currency
        self.billingCycle = billingCycle
        self.startDate = startDate
        self.colorHex = colorHex
        self.iconName = iconName
    }
    
    var monthlyCost: Double {
        if billingCycle == "Yearly" {
            return price / 12.0
        }
        return price
    }
}
