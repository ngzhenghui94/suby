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
    
    // Simple currency converter (fixed for now as per plan)
    // let usdToSgd = 1.35
    
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
                            Text("Subscriptions")
                                .font(.system(.largeTitle, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            Spacer()
                            
                            // Analytics Button
                            NavigationLink {
                                AnalyticsView()
                                    .environment(currencyManager)
                            } label: {
                                Image(systemName: "chart.pie.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .padding(10)
                                    .background(Material.ultraThin)
                                    .clipShape(Circle())
                            }
                            
                            Button {
                                showingAddSheet = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundStyle(.white)
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
                                .frame(height: 400) // Give it substantial space
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
                                    HStack(spacing: 15) {
                                        Circle()
                                            .fill(Color(hex: sub.colorHex).gradient(to: Color(hex: sub.colorHex).opacity(0.7)))
                                            .frame(width: 40, height: 40)
                                            .overlay(Image(systemName: sub.iconName).font(.caption).foregroundColor(.white))
                                            .shadow(color: Color(hex: sub.colorHex).opacity(0.5), radius: 5)
                                        
                                        VStack(alignment: .leading) {
                                            Text(sub.name)
                                                .font(.body)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.white)
                                            Text(sub.billingCycle)
                                                .font(.caption)
                                                .foregroundStyle(.gray)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing) {
                                            Text("\(sub.currency) \(sub.price, specifier: "%.2f")")
                                                .font(.callout)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .padding()
                                    .glassEffect()
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

struct GlassStatsCard: View {
    let title: String
    let mainValue: String
    let subValue: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .textCase(.uppercase)
                .foregroundStyle(.gray)
            
            Text(mainValue)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            
            if let sub = subValue {
                Text(sub)
                    .font(.caption)
                    .foregroundStyle(.gray.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect()
    }
}
