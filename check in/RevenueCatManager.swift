import Foundation
import Combine

#if canImport(RevenueCat)
import RevenueCat
#endif

@MainActor
final class RevenueCatManager: ObservableObject {
    @Published var isPro = false
    @Published var statusText = "Free"

    // RevenueCat config provided by user
    let monthlyProductId = "camwambam1234"
    let entitlementId = "openclaw_entitlements"

    static let shared = RevenueCatManager()

    private init() {}

    func configure(apiKey: String, appUserID: String? = nil) {
        #if canImport(RevenueCat)
        Purchases.configure(withAPIKey: apiKey, appUserID: appUserID)
        #else
        statusText = "RevenueCat SDK not linked"
        #endif
    }

    func refreshEntitlements() async {
        #if canImport(RevenueCat)
        do {
            let info = try await Purchases.shared.customerInfo()
            let active = info.entitlements.active[entitlementId] != nil
            isPro = active
            statusText = active ? "Pro Active" : "Free"
        } catch {
            statusText = "Entitlement check failed"
        }
        #else
        isPro = false
        statusText = "RevenueCat SDK not linked"
        #endif
    }
}
