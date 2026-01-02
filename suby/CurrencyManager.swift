//
//  CurrencyManager.swift
//  suby
//
//  Created by Daniel Ng Zheng Hui on 1/2/26.
//

import Foundation
import SwiftUI

@Observable
class CurrencyManager {
    var rates: [String: Double] = ["USD": 1.0, "SGD": 1.35] // Default fallback
    var lastUpdated: Date?
    
    init() {
        loadRates()
        fetchRates()
    }
    
    func fetchRates() {
        guard let url = URL(string: "https://open.er-api.com/v6/latest/USD") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching rates: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
                DispatchQueue.main.async {
                    self.rates = decoded.rates
                    self.lastUpdated = Date()
                    self.saveRates()
                }
            } catch {
                print("Error decoding rates: \(error)")
            }
        }.resume()
    }
    
    func convert(_ amount: Double, from sourceCurrency: String, to targetCurrency: String) -> Double {
        let sourceRate = rates[sourceCurrency] ?? 1.0
        let targetRate = rates[targetCurrency] ?? 1.0
        
        // Convert to USD first (since base is likely USD from this API), then to target
        // If API base is USD:
        // Amount in USD = Amount / SourceRate
        // Amount in Target = Amount in USD * TargetRate
        return (amount / sourceRate) * targetRate
    }
    
    private func saveRates() {
        if let encoded = try? JSONEncoder().encode(rates) {
            UserDefaults.standard.set(encoded, forKey: "cached_rates")
        }
    }
    
    private func loadRates() {
        if let data = UserDefaults.standard.data(forKey: "cached_rates"),
           let decoded = try? JSONDecoder().decode([String: Double].self, from: data) {
            self.rates = decoded
        }
    }
}

struct ExchangeRateResponse: Codable {
    let result: String
    let rates: [String: Double]
}
