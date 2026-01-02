//
//  AddSubscriptionView.swift
//  suby
//
//  Created by Daniel Ng Zheng Hui on 1/2/26.
//

import SwiftUI
import SwiftData

struct AddSubscriptionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var subscription: Subscription?
    
    @State private var name: String = ""
    @State private var price: Double = 9.99
    @State private var currency: String = "USD"
    @State private var billingCycle: String = "Monthly"
    @State private var startDate: Date = Date()
    @State private var colorHex: String = "#5E5CE6"
    
    let currencies = ["USD", "SGD", "EUR", "GBP"]
    let cycles = ["Monthly", "Yearly"]
    let colors = ["#5E5CE6", "#FF2D55", "#30B0C7", "#FF9F0A", "#32D74B", "#AF52DE", "#FF375F", "#007AFF"]
    
    init(subscription: Subscription? = nil) {
        self.subscription = subscription
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name (e.g. Netflix)", text: $name)
                    
                    HStack {
                        TextField("Price", value: $price, format: .number)
                            .keyboardType(.decimalPad)
                        
                        Picker("Currency", selection: $currency) {
                            ForEach(currencies, id: \.self) { curr in
                                Text(curr).tag(curr)
                            }
                        }
                        .labelsHidden()
                    }
                    
                    Picker("Billing Cycle", selection: $billingCycle) {
                        ForEach(cycles, id: \.self) { cycle in
                            Text(cycle).tag(cycle)
                        }
                    }
                }
                
                Section("Appearance") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(colors, id: \.self) { color in
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: colorHex == color ? 4 : 0)
                                    )
                                    .onTapGesture {
                                        colorHex = color
                                    }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
            }
            .navigationTitle(subscription == nil ? "Add Subscription" : "Edit Subscription")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(subscription == nil ? "Add" : "Save") {
                        saveSubscription()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let sub = subscription {
                    name = sub.name
                    price = sub.price
                    currency = sub.currency
                    billingCycle = sub.billingCycle
                    startDate = sub.startDate
                    colorHex = sub.colorHex
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func saveSubscription() {
        if let sub = subscription {
            // Edit existing
            sub.name = name
            sub.price = price
            sub.currency = currency
            sub.billingCycle = billingCycle
            sub.startDate = startDate
            sub.colorHex = colorHex
        } else {
            // Create new
            let newSub = Subscription(
                name: name,
                price: price,
                currency: currency,
                billingCycle: billingCycle,
                startDate: startDate,
                colorHex: colorHex
            )
            modelContext.insert(newSub)
        }
        dismiss()
    }
}
