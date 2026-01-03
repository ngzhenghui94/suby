//
//  ContentView.swift
//  suby
//
//  Created by Daniel Ng Zheng Hui on 1/2/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("accentColor") private var accentColorHex: String = "#5E5CE6"
    
    init() {
        // Custom Tab Bar Appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor(Color(hex: "#050511").opacity(0.8)) // Match app background semi-transparent
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2.fill")
                }
            
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            
            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.pie.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
        .accentColor(Color(hex: accentColorHex)) // Active tab color
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Subscription.self, inMemory: true)
}
