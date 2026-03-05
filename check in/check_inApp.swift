//
//  check_inApp.swift
//  check in
//
//  Created by cameron Dorsey  on 2/25/26.
//

import SwiftUI

@main
struct check_inApp: App {
    init() {
        // Add REVENUECAT_API_KEY to Info.plist to enable live entitlements.
        if let key = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String,
           !key.isEmpty {
            RevenueCatManager.shared.configure(apiKey: key)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
