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
        // RevenueCat public SDK key (fallback to provided key if Info.plist is empty).
        let configuredKey = (Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String) ?? ""
        let key = configuredKey.isEmpty ? "sk_TIvoGfnGpIRsjKAlVnTtAaZLitWcV" : configuredKey
        RevenueCatManager.shared.configure(apiKey: key)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
