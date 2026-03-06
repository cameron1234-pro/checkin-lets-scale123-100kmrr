import SwiftUI

struct ContentView: View {
    @StateObject private var pairing = PairingStore()
    @StateObject private var revenue = RevenueCatManager.shared

    @State private var unlocked = false
    @State private var email = ""
    @State private var statusMessage = "Ready"
    @State private var selectedTab: AppTab = .home

    enum AppTab: String, CaseIterable {
        case home = "Home"
        case checkins = "Check-Ins"
        case sos = "SOS"
        case profile = "Profile"
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.black, Color(red: 0.05, green: 0.09, blue: 0.14)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            if unlocked {
                mainShell
            } else {
                authView
            }
        }
        .onOpenURL(perform: handleIncomingURL)
        .task { await revenue.refreshEntitlements() }
    }

    private var authView: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.cyan)

            Text("Check In")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .padding(12)
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(.white)

            SecureField("Password", text: .constant(""))
                .padding(12)
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(.white)

            Button("Access Check In") {
                unlocked = true
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.cyan)
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text("Secure • Encrypted • Check In Companion")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(24)
    }

    private var mainShell: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("Section", selection: $selectedTab) {
                    ForEach(AppTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                ScrollView {
                    VStack(spacing: 12) {
                        card(title: "Status", content: statusMessage)

                        switch selectedTab {
                        case .home:
                            card(title: "Pairing", content: pairing.current?.sessionId ?? "No active session")
                            card(title: "Plan", content: revenue.statusText)
                        case .checkins:
                            card(title: "Recent Check-Ins", content: "• Safe @ Home\n• In transit\n• Safe @ Office")
                        case .sos:
                            card(title: "Emergency", content: "SOS workflow armed. Use when needed.")
                        case .profile:
                            card(title: "Profile", content: email.isEmpty ? "agent@checkin.app" : email)
                        }

                        HStack {
                            Button("Refresh") { Task { await revenue.refreshEntitlements() } }
                                .buttonStyle(.borderedProminent)
                                .tint(.cyan)
                            Button("Lock") { unlocked = false }
                                .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Check In")
        }
        .tint(.cyan)
    }

    private func card(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            Text(content)
                .foregroundStyle(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func handleIncomingURL(_ url: URL) {
        guard url.scheme?.lowercased() == "checkin", url.host?.lowercased() == "start" else { return }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let sessionId = components?.queryItems?.first(where: { $0.name == "session" })?.value ?? ""
        let sourceApp = components?.queryItems?.first(where: { $0.name == "source" })?.value ?? "unknown"
        guard !sessionId.isEmpty else { return }

        pairing.apply(sessionId: sessionId, source: sourceApp)
        statusMessage = "Paired to \(sessionId) via \(sourceApp)"
        unlocked = true
        selectedTab = .home
    }
}

#Preview {
    ContentView()
}
