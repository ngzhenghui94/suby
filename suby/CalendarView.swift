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
    @State private var selectedDate: Date? = nil // New: Track selected date
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
        
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let offset = (firstWeekday + 5) % 7
        
        for _ in 0..<offset {
            days.append(nil)
        }
        
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(date)
            }
        }
        
        while days.count < 42 {
            days.append(nil)
        }
        
        return days
    }
    
    // Total cost for the ENTRIE month displayed
    private var monthlyTotal: Double {
        subscriptionsForMonth(currentMonth).reduce(0) { total, sub in
            let cost = sub.billingCycle == "Yearly" ? sub.price / 12 : sub.price
            return total + currencyManager.convert(cost, from: sub.currency, to: "USD")
        }
    }
    
    private var remainingAmount: Double {
        let today = Date()
        // Determine "remaining" based on real time today, not the calendar view time
        // Only makes sense if we are viewing the CURRENT month
        if !calendar.isDate(currentMonth, equalTo: today, toGranularity: .month) {
            return 0 // For past/future months, concept of "remaining" is less relevant or simply full amount
        }
        
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
    
    // New Logic: Show payments based on selection state
    private var displayedPayments: [(Subscription, Date, Int)] {
        let today = Date()
        var results: [(Subscription, Date, Int)] = []
        
        // If a specific date is selected, filter for that. Otherwise, show whole month.
        let targetDates = selectedDate != nil ? [selectedDate!] : daysInMonth.compactMap { $0 }
        
        for date in targetDates {
            // Optimization: Skip if date is not in the currently viewed month (unless we allowed cross-month selection, but here we scope to view)
            if !calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) { continue }
            
            let subsOnDate = subscriptionsForDate(date)
            for sub in subsOnDate {
                let daysDiff = calendar.dateComponents([.day], from: today, to: date).day ?? 0
                results.append((sub, date, daysDiff))
            }
        }
        
        // Sort by date, then by name
        return results.sorted {
            if $0.1 != $1.1 { return $0.1 < $1.1 }
            return $0.0.name < $1.0.name
        }
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
                        
                        // Dynamic Payments List
                        paymentsListView
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
            .onAppear {
                 // Reset selection when appearing if needed, or keep state
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
                    
                    // Show "left" only if viewing current month
                    if calendar.isDate(currentMonth, equalTo: Date(), toGranularity: .month) && remainingAmount > 0 {
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
                            isSelected: isSelected(date),
                            onTap: {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    if selectedDate == date {
                                        selectedDate = nil // Deselect if tapping same date
                                    } else {
                                        selectedDate = date
                                    }
                                }
                                HapticManager.selection()
                            }
                        )
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }
            .padding(.bottom, 12)
        }
    }
    
    private var paymentsListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Dynamic Header
            HStack {
                if let selected = selectedDate {
                    Text("Due on \(formatDateHeader(selected))")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Button("Show All") {
                        withAnimation {
                            selectedDate = nil
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(Color(hex: "#5E5CE6"))
                } else {
                    Text("Payments in \(monthYearString)")
                        .font(.headline)
                        .foregroundStyle(.gray)
                }
            }
            .padding(.horizontal)
            
            if displayedPayments.isEmpty {
                ContentUnavailableView(
                    selectedDate == nil ? "No payments this month" : "No payments due",
                    systemImage: "calendar.badge.checkmark"
                )
                .padding(.top, 20)
            } else {
                ForEach(displayedPayments, id: \.0.id) { sub, date, daysDiff in
                    PaymentListRow(
                        subscription: sub,
                        paymentDate: date,
                        daysDiff: daysDiff
                    )
                    .onTapGesture {
                        selectedSubscription = sub
                        HapticManager.selection()
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func goToPreviousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentDate) {
            currentDate = newDate
            selectedDate = nil // Reset selection on change
        }
    }
    
    private func goToNextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentDate) {
            currentDate = newDate
            selectedDate = nil // Reset selection on change
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
        
        let payDay = min(startDay, range.count)
        var components = calendar.dateComponents([.year, .month], from: month)
        components.day = payDay
        
        guard let paymentDate = calendar.date(from: components) else { return nil }
        
        if subscription.startDate > paymentDate { return nil }
        
        if subscription.billingCycle == "Yearly" {
            let startMonth = calendar.component(.month, from: subscription.startDate)
            let currentMonth = calendar.component(.month, from: month)
            if startMonth != currentMonth { return nil }
        }
        
        return paymentDate
    }
    
    private func isPaymentDate(for subscription: Subscription, on date: Date) -> Bool {
        guard let paymentDate = paymentDateInMonth(for: subscription, in: date) else { return false }
        return calendar.isDate(paymentDate, inSameDayAs: date)
    }
    
    private func isSelected(_ date: Date) -> Bool {
        guard let selected = selectedDate else { return false }
        return calendar.isDate(selected, inSameDayAs: date)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
    
    private func formatDateHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Calendar Day Cell

struct CalendarDayCell: View {
    let date: Date
    let subscriptions: [Subscription]
    let isToday: Bool
    let isSelected: Bool
    let onTap: () -> Void
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(dayNumber)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight((isToday || isSelected) ? .bold : .regular)
                    .foregroundStyle(isSelected ? .white : (isToday ? Color(hex: "#5E5CE6") : .gray))
                
                if !subscriptions.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(subscriptions.prefix(3)) { sub in
                            Circle()
                                .fill(Color(hex: sub.colorHex))
                                .frame(width: 6, height: 6)
                        }
                    }
                } else {
                    Spacer().frame(height: 6) // Keep alignment consistent
                }
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "#5E5CE6") : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isToday && !isSelected ? Color(hex: "#5E5CE6").opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Payment List Row (Renamed)

struct PaymentListRow: View {
    let subscription: Subscription
    let paymentDate: Date
    let daysDiff: Int // <0: Past, 0: Today, >0: Future
    
    @Environment(CurrencyManager.self) private var currencyManager
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter.string(from: paymentDate)
    }
    
    private var statusText: String {
        if daysDiff < 0 {
            return "Paid"
        } else if daysDiff == 0 {
            return "Today"
        } else if daysDiff == 1 {
            return "Tomorrow"
        } else {
            return "\(daysDiff) days"
        }
    }
    
    private var statusColor: Color {
        if daysDiff < 0 {
            return .gray.opacity(0.6)
        } else if daysDiff <= 3 {
            return Color(hex: "#FF9F0A") // Warning
        } else {
            return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Circle()
                .fill(Color(hex: subscription.colorHex))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: subscription.iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                )
            
            // Name & Status
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
            
            // Cost & Date Info
            VStack(alignment: .trailing, spacing: 2) {
                Text(currencyManager.convert(subscription.price, from: subscription.currency, to: "USD"), format: .currency(code: "USD"))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                
                HStack(spacing: 4) {
                    Text(dateString)
                    Text("•")
                    Text(statusText)
                        .foregroundStyle(statusColor)
                }
                .font(.caption2)
                .foregroundStyle(.gray)
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
