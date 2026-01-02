//
//  AnalyticsView.swift
//  suby
//
//  Created by Daniel Ng Zheng Hui on 1/2/26.
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Query private var subscriptions: [Subscription]
    @Environment(CurrencyManager.self) private var currencyManager
    
    var data: [CategoryData] {
        var dict: [String: Double] = [:]
        for sub in subscriptions {
            let cost = currencyManager.convert(sub.monthlyCost, from: sub.currency, to: "USD")
            dict[sub.category, default: 0] += cost
        }
        return dict.map { CategoryData(category: $0.key, amount: $0.value) }.sorted { $0.amount > $1.amount }
    }
    
    var totalCost: Double {
        data.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        if totalCost > 0 {
                            // Chart
                            VStack {
                                Text("Spending by Category")
                                    .font(.headline)
                                    .foregroundStyle(.gray)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Chart(data) { item in
                                    SectorMark(
                                        angle: .value("Cost", item.amount),
                                        innerRadius: .ratio(0.6),
                                        angularInset: 2
                                    )
                                    .cornerRadius(5)
                                    .foregroundStyle(by: .value("Category", item.category))
                                }
                                .frame(height: 250)
                                .padding(.vertical)
                                
                                Text("Total: \(currencyManager.convert(totalCost, from: "USD", to: "USD"), format: .currency(code: "USD")) / mo")
                                    .font(.title3)
                                    .bold()
                                    .foregroundStyle(.white)
                            }
                            .padding()
                            .glassEffect()
                            .padding(.horizontal)
                            
                            // Listing
                            VStack(spacing: 12) {
                                ForEach(data) { item in
                                    HStack {
                                        if let cat = SubscriptionCategory(rawValue: item.category) {
                                            Image(systemName: cat.icon)
                                                .foregroundStyle(Color(hex: cat.color))
                                        }
                                        Text(item.category)
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Text(item.amount, format: .currency(code: "USD"))
                                            .bold()
                                            .foregroundStyle(.white)
                                    }
                                    .padding()
                                    .glassEffect()
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            ContentUnavailableView("No Data", systemImage: "chart.pie.fill")
                        }
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Analytics")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

struct CategoryData: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
}
