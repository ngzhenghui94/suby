//
//  ProfileView.swift
//  suby
//
//  Created by Daniel Ng Zheng Hui on 1/2/26.
//

import SwiftUI
import CloudKit
import SwiftData

struct ProfileView: View {
    @State private var iCloudStatus: String = "Checking..."
    @AppStorage("accentColor") private var accentColorHex: String = "#5E5CE6"
    @State private var showingResetAlert = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) var openURL
    
    let colors = ["#5E5CE6", "#FF2D55", "#30B0C7", "#FF9F0A", "#32D74B", "#AF52DE", "#FF375F", "#007AFF", "#FFD60A"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackgroundView()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Header
                        HStack {
                            Text("Profile")
                                .font(.system(.largeTitle, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        // iCloud Status Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Sync Status")
                                .font(.headline)
                                .foregroundStyle(.gray)
                            
                            HStack {
                                Image(systemName: iCloudStatus == "Active" ? "checkmark.icloud.fill" : "exclamationmark.icloud.fill")
                                    .font(.title2)
                                    .foregroundStyle(iCloudStatus == "Active" ? .green : .orange)
                                
                                VStack(alignment: .leading) {
                                    Text("iCloud Sync")
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    Text(iCloudStatus)
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                }
                                Spacer()
                            }
                            .padding()
                            .glassEffect()
                        }
                        .padding(.horizontal)
                        
                        // Theme Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Appearance")
                                .font(.headline)
                                .foregroundStyle(.gray)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Accent Color")
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(colors, id: \.self) { color in
                                            Circle()
                                                .fill(Color(hex: color))
                                                .frame(width: 40, height: 40)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white, lineWidth: accentColorHex == color ? 3 : 0)
                                                )
                                                .shadow(color: Color(hex: color).opacity(0.5), radius: 5)
                                                .onTapGesture {
                                                    accentColorHex = color
                                                }
                                        }
                                    }
                                    .padding(.vertical, 5)
                                }
                            }
                            .padding()
                            .glassEffect()
                        }
                        .padding(.horizontal)
                        
                        // Data Management Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Data Management")
                                .font(.headline)
                                .foregroundStyle(.gray)
                            
                            Button(action: {
                                showingResetAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                        .foregroundStyle(.red)
                                    Text("Delete All Data")
                                        .foregroundStyle(.red)
                                        .fontWeight(.medium)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.gray)
                                        .font(.caption)
                                }
                                .padding()
                                .glassEffect()
                            }
                        }
                        .padding(.horizontal)
                        
                        // About Section / Branding
                        VStack(spacing: 8) {
                            Text("Questfully - Subly v1.0")
                                .font(.caption)
                                .bold()
                                .foregroundStyle(.white.opacity(0.8))
                            
                            Text("Part of the Questfully Family")
                                .font(.caption2)
                                .foregroundStyle(.gray)
                            
                            Button {
                                if let url = URL(string: "https://questfully.dev") {
                                    openURL(url)
                                }
                            } label: {
                                Text("Check out our other apps at questfully.dev")
                                    .font(.caption2)
                                    .foregroundStyle(Color(hex: accentColorHex))
                                    .underline()
                            }
                            
                            Text("Made with ❤️ by Daniel")
                                .font(.caption2)
                                .foregroundStyle(.gray.opacity(0.6))
                                .padding(.top, 5)
                        }
                        .padding(.top, 20)
                    }
                    .padding(.top)
                }
            }
            .onAppear(perform: checkiCloudStatus)
            .alert("Reset All Data?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("This action cannot be undone. All subscriptions will be permanently deleted.")
            }
        }
    }
    
    private func checkiCloudStatus() {
        CKContainer.default().accountStatus { status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    iCloudStatus = "Active"
                case .noAccount:
                    iCloudStatus = "No iCloud Account"
                case .restricted:
                    iCloudStatus = "Restricted"
                case .couldNotDetermine:
                    iCloudStatus = "Could Not Determine"
                case .temporarilyUnavailable:
                    iCloudStatus = "Temporarily Unavailable"
                @unknown default:
                    iCloudStatus = "Unknown"
                }
            }
        }
    }
    
    private func deleteAllData() {
        do {
            let descriptor = FetchDescriptor<Subscription>()
            let allItems = try modelContext.fetch(descriptor)
            for item in allItems {
                modelContext.delete(item)
            }
        } catch {
            print("Failed to delete data: \(error)")
        }
    }
}
