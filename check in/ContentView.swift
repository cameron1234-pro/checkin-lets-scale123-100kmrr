import SwiftUI

struct ContentView: View {
    @StateObject private var pairing = PairingStore()
    @StateObject private var revenue = RevenueCatManager.shared

    @State private var statusMessage: String = "Ready"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    pairingCard
                    monetizationCard
                    actionsCard
                }
                .padding()
            }
            .navigationTitle("Check In")
            .onOpenURL(perform: handleIncomingURL)
            .task {
                await revenue.refreshEntitlements()
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Safety + Pairing", systemImage: "checkmark.shield.fill")
                .font(.headline)
                .foregroundStyle(.green)

            Text("Lovable-style flow target: paired session, fast status updates, SOS, and monetized pro features.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Status: \(statusMessage)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var pairingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pairing")
                .font(.headline)

            if let current = pairing.current {
                pairRow("Session", current.sessionId)
                pairRow("Source", current.source)
                pairRow("Connected", current.createdAt.formatted(date: .abbreviated, time: .shortened))
            } else {
                Text("No pairing session yet. Open with deep link:")
                    .foregroundStyle(.secondary)
                Text("checkin://start?session=<id>&source=promatch")
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var monetizationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Monetization (RevenueCat)")
                .font(.headline)
            pairRow("Plan", revenue.statusText)
            pairRow("Monthly Product", revenue.monthlyProductId)
            pairRow("Entitlement", revenue.entitlementId)
            Text("Pro gates can be attached to SOS automation, extended check-in history, and premium contact workflows.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var actionsCard: some View {
        HStack(spacing: 12) {
            Button("Refresh Entitlements") {
                Task { await revenue.refreshEntitlements() }
            }
            .buttonStyle(.borderedProminent)

            Button("Clear Pairing") {
                pairing.clear()
                statusMessage = "Pairing reset"
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func pairRow(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }

    private func handleIncomingURL(_ url: URL) {
        guard url.scheme?.lowercased() == "checkin",
              url.host?.lowercased() == "start"
        else { return }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []

        let sessionId = queryItems.first(where: { $0.name == "session" })?.value ?? ""
        let sourceApp = queryItems.first(where: { $0.name == "source" })?.value ?? "unknown"

        guard !sessionId.isEmpty else {
            statusMessage = "Check-in opened, but no session id was provided."
            return
        }

        pairing.apply(sessionId: sessionId, source: sourceApp)
        statusMessage = "Paired to session \(sessionId)"
    }
}

#Preview {
    ContentView()
}
