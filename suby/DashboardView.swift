//
//  DashboardView.swift
//  suby
//
//  Created by Daniel Ng Zheng Hui on 1/2/26.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var subscriptions: [Subscription]
    @State private var showingAddSheet = false
    @State private var selectedSubscription: Subscription?
    @State private var currencyManager = CurrencyManager()
    @AppStorage("accentColor") private var accentColorHex: String = "#5E5CE6"
    
    var totalMonthlyUSD: Double {
        subscriptions.reduce(0) { total, sub in
            let monthlyCost = sub.monthlyCost
            // Convert to USD using manager
            let costInUSD = currencyManager.convert(monthlyCost, from: sub.currency, to: "USD")
            return total + costInUSD
        }
    }
    
    var totalAnnuallyUSD: Double {
        totalMonthlyUSD * 12
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackgroundView()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Custom Header
                        HStack {
                            Text("Subly")
                                .font(.system(.largeTitle, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            Spacer()
                            
                            Button {
                                HapticManager.impact(.medium)
                                showingAddSheet = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundStyle(Color(hex: accentColorHex))
                                    .padding(10)
                                    .background(Material.ultraThin)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal)
                        
                        // Stats Row
                        HStack(spacing: 12) {
                            GlassStatsCard(title: "Monthly", mainValue: formatCurrency(totalMonthlyUSD, "USD"), subValue: formatCurrency(currencyManager.convert(totalMonthlyUSD, from: "USD", to: "SGD"), "SGD"))
                            GlassStatsCard(title: "Annually", mainValue: formatCurrency(totalAnnuallyUSD, "USD"), subValue: formatCurrency(currencyManager.convert(totalAnnuallyUSD, from: "USD", to: "SGD"), "SGD"))
                            GlassStatsCard(title: "Active", mainValue: "\(subscriptions.count)", subValue: "Subs")
                        }
                        .padding(.horizontal)
                        
                        // Bubbles Cloud
                        // Bubbles Cloud (Organic Spiral)
                        Group {
                            if !subscriptions.isEmpty {
                                BubbleCloudView(subscriptions: subscriptions) { sub in
                                    selectedSubscription = sub
                                }
                                .aspectRatio(1.0, contentMode: .fit) // Responsive square layout
                            } else {
                                ContentUnavailableView("No Subscriptions", systemImage: "bubble.left.and.bubble.right")
                            }
                        }
                        .padding(.horizontal)
                        
                        // List View
                        if !subscriptions.isEmpty {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("All Subscriptions")
                                    .font(.headline)
                                    .foregroundStyle(.gray)
                                    .padding(.horizontal)
                                
                                ForEach(subscriptions) { sub in
                                    SubscriptionRowView(subscription: sub)
                                        .onTapGesture {
                                            selectedSubscription = sub
                                        }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.top)
                    .padding(.bottom, 50)
                }
            }
            .toolbar(.hidden) // Hide default toolbar to use our custom header
            .sheet(isPresented: $showingAddSheet) {
                AddSubscriptionView()
                    .presentationDetents([.medium, .large])
            }
            .sheet(item: $selectedSubscription) { sub in
                AddSubscriptionView(subscription: sub)
                    .presentationDetents([.medium, .large])
            }
        }
        .preferredColorScheme(.dark)
    }
    
    func formatCurrency(_ value: Double, _ code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? ""
    }
}
