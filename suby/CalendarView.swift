//
//  CalendarView.swift
//  suby
//
//  Created by Daniel Ng Zheng Hui on 1/3/26.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query private var subscriptions: [Subscription]
    @Environment(CurrencyManager.self) private var currencyManager
    
    @State private var currentDate = Date()
    @State private var selectedSubscription: Subscription?
    
    private let calendar = Calendar.current
    private let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    // MARK: - Computed Properties
    
    private var currentMonth: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)) ?? currentDate
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM, yyyy"
        return formatter.string(from: currentDate)
    }
    
    private var daysInMonth: [Date?] {
        var days: [Date?] = []
        
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth)) else {
            return days
        }
        
        // Get the weekday of the first day (1 = Sunday, 2 = Monday, etc.)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        // Convert to Monday-based (0 = Monday, 6 = Sunday)
        let offset = (firstWeekday + 5) % 7
        
        // Add empty days for offset
        for _ in 0..<offset {
            days.append(nil)
        }
        
        // Add all days of the month
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        // Fill remaining cells to complete grid (6 rows × 7 days = 42 cells)
        while days.count < 42 {
            days.append(nil)
        }
        
        return days
    }
    
    private var monthlyTotal: Double {
        subscriptionsForMonth(currentMonth).reduce(0) { total, sub in
            let cost = sub.billingCycle == "Yearly" ? sub.price / 12 : sub.price
            return total + currencyManager.convert(cost, from: sub.currency, to: "USD")
        }
    }
    
    private var remainingAmount: Double {
        let today = Date()
        let upcomingSubs = subscriptionsForMonth(currentMonth).filter { sub in
            if let paymentDate = paymentDateInMonth(for: sub, in: currentMonth) {
                return paymentDate >= today
            }
            return false
        }
        
        return upcomingSubs.reduce(0) { total, sub in
            let cost = sub.billingCycle == "Yearly" ? sub.price : sub.price
            return total + currencyManager.convert(cost, from: sub.currency, to: "USD")
        }
    }
    
    private var upcomingPayments: [(Subscription, Date, Int)] {
        let today = Date()
        var results: [(Subscription, Date, Int)] = []
        
        for sub in subscriptions {
            if let paymentDate = paymentDateInMonth(for: sub, in: currentMonth),
               paymentDate >= today {
                let daysLeft = calendar.dateComponents([.day], from: today, to: paymentDate).day ?? 0
                results.append((sub, paymentDate, daysLeft))
            }
        }
        
        return results.sorted { $0.2 < $1.2 }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Month Header
                        monthHeaderView
                        
                        // Calendar Grid
                        calendarGridView
                            .padding(.horizontal)
                            .glassEffect()
                            .padding(.horizontal)
                        
                        // Upcoming Payments
                        if !upcomingPayments.isEmpty {
                            upcomingPaymentsView
                        }
                    }
                    .padding(.top)
                    .padding(.bottom, 50)
                }
            }
            .navigationTitle("Calendar")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: $selectedSubscription) { sub in
                AddSubscriptionView(subscription: sub)
                    .presentationDetents([.medium, .large])
            }
        }
    }
    
    // MARK: - Views
    
    private var monthHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(monthYearString)
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                HStack(spacing: 8) {
                    Text(formatCurrency(monthlyTotal))
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    if remainingAmount > 0 && remainingAmount < monthlyTotal {
                        Text("(\(formatCurrency(remainingAmount)) left)")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button {
                    withAnimation(.spring()) {
                        goToPreviousMonth()
                    }
                    HapticManager.selection()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                
                Button {
                    withAnimation(.spring()) {
                        goToNextMonth()
                    }
                    HapticManager.selection()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var calendarGridView: some View {
        VStack(spacing: 8) {
            // Weekday headers
            HStack {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 12)
            
            // Calendar days
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        CalendarDayCell(
                            date: date,
                            subscriptions: subscriptionsForDate(date),
                            isToday: calendar.isDateInToday(date),
                            onTap: { sub in
                                selectedSubscription = sub
                                HapticManager.selection()
                            }
                        )
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
            .padding(.bottom, 12)
        }
    }
    
    private var upcomingPaymentsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Payments")
                .font(.headline)
                .foregroundStyle(.gray)
                .padding(.horizontal)
            
            ForEach(upcomingPayments.prefix(5), id: \.0.id) { sub, date, daysLeft in
                UpcomingPaymentRow(
                    subscription: sub,
                    paymentDate: date,
                    daysLeft: daysLeft
                )
                .onTapGesture {
                    selectedSubscription = sub
                    HapticManager.selection()
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Helper Methods
    
    private func goToPreviousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentDate) {
            currentDate = newDate
        }
    }
    
    private func goToNextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentDate) {
            currentDate = newDate
        }
    }
    
    private func subscriptionsForMonth(_ month: Date) -> [Subscription] {
        subscriptions.filter { sub in
            paymentDateInMonth(for: sub, in: month) != nil
        }
    }
    
    private func subscriptionsForDate(_ date: Date) -> [Subscription] {
        subscriptions.filter { sub in
            isPaymentDate(for: sub, on: date)
        }
    }
    
    private func paymentDateInMonth(for subscription: Subscription, in month: Date) -> Date? {
        let startDay = calendar.component(.day, from: subscription.startDate)
        
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return nil }
        
        // Handle months with fewer days than the start date
        let payDay = min(startDay, range.count)
        
        var components = calendar.dateComponents([.year, .month], from: month)
        components.day = payDay
        
        guard let paymentDate = calendar.date(from: components) else { return nil }
        
        // Check if subscription was active by this date
        if subscription.startDate > paymentDate {
            return nil
        }
        
        // For yearly subscriptions, check if this is the correct month
        if subscription.billingCycle == "Yearly" {
            let startMonth = calendar.component(.month, from: subscription.startDate)
            let currentMonth = calendar.component(.month, from: month)
            if startMonth != currentMonth {
                return nil
            }
        }
        
        return paymentDate
    }
    
    private func isPaymentDate(for subscription: Subscription, on date: Date) -> Bool {
        guard let paymentDate = paymentDateInMonth(for: subscription, in: date) else {
            return false
        }
        return calendar.isDate(paymentDate, inSameDayAs: date)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let subscriptions: [Subscription]
    let isToday: Bool
    let onTap: (Subscription) -> Void
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text(dayNumber)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(isToday ? .white : .gray)
            
            if !subscriptions.isEmpty {
                HStack(spacing: 2) {
                    ForEach(subscriptions.prefix(3)) { sub in
                        Circle()
                            .fill(Color(hex: sub.colorHex))
                            .frame(width: 8, height: 8)
                            .onTapGesture {
                                onTap(sub)
                            }
                    }
                    
                    if subscriptions.count > 3 {
                        Text("+\(subscriptions.count - 3)")
                            .font(.system(size: 8))
                            .foregroundStyle(.gray)
                    }
                }
            }
        }
        .frame(height: 44)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isToday ? Color(hex: "#5E5CE6").opacity(0.3) : Color.clear)
        )
    }
}

// MARK: - Upcoming Payment Row

struct UpcomingPaymentRow: View {
    let subscription: Subscription
    let paymentDate: Date
    let daysLeft: Int
    
    @Environment(CurrencyManager.self) private var currencyManager
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: paymentDate)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Circle()
                .fill(Color(hex: subscription.colorHex))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: subscription.iconName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                )
            
            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                
                Text(subscription.billingCycle)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            
            // Date & Days Left
            VStack(alignment: .trailing, spacing: 2) {
                Text(dateString)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                
                Text(daysLeft == 0 ? "Today" : "\(daysLeft) days left")
                    .font(.caption)
                    .foregroundStyle(daysLeft <= 3 ? Color(hex: "#FF9F0A") : .gray)
            }
        }
        .padding()
        .glassEffect()
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: Subscription.self, inMemory: true)
        .environment(CurrencyManager())
}
