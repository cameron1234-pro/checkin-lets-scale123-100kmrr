import SwiftUI

struct ContentView: View {
    @StateObject private var pairing = PairingStore()
    @StateObject private var revenue = RevenueCatManager.shared

    @State private var statusMessage = "Ready"
    @State private var email = ""
    @State private var password = ""
    @State private var unlocked = false
    @State private var selectedTab: TerminalTab = .home

    enum TerminalTab: String, CaseIterable {
        case home = "Home"
        case checkins = "Check-Ins"
        case sos = "SOS"
        case profile = "Profile"

        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .checkins: return "clock.arrow.circlepath"
            case .sos: return "exclamationmark.triangle.fill"
            case .profile: return "person.crop.circle"
            }
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.04, green: 0.07, blue: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if unlocked {
                terminalView
            } else {
                authView
            }
        }
        .onOpenURL(perform: handleIncomingURL)
        .task {
            await revenue.refreshEntitlements()
        }
    }

    private var authView: some View {
        VStack(spacing: 20) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.cyan)

            VStack(spacing: 4) {
                Text("CheckIn_")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Access your protocols")
                    .foregroundStyle(.white.opacity(0.7))
            }

            VStack(spacing: 12) {
                field("Email", text: $email, icon: "envelope.fill", placeholder: "agent@sentinel.io")
                field("Password", text: $password, icon: "lock.fill", placeholder: "••••••••", secure: true)

                Button {
                    unlocked = true
                } label: {
                    HStack {
                        Text("Access Terminal")
                        Image(systemName: "arrow.right")
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.cyan)
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button("New agent? Create account") {}
                    .foregroundStyle(.white.opacity(0.8))
                    .font(.footnote)
            }
            .padding(18)
            .background(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Text("SECURE · ENCRYPTED · PROTECTED")
                .font(.caption2)
                .tracking(1)
                .foregroundStyle(.white.opacity(0.55))
        }
        .padding(24)
    }

    private var terminalView: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Picker("Section", selection: $selectedTab) {
                    ForEach(TerminalTab.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                ScrollView {
                    VStack(spacing: 14) {
                        switch selectedTab {
                        case .home:
                            terminalHeader
                            pairingCard
                            monetizationCard
                        case .checkins:
                            checkinsCard
                            actionsCard
                        case .sos:
                            sosCard
                            actionsCard
                        case .profile:
                            profileCard
                            actionsCard
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Terminal")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .tint(.cyan)
    }

    private var terminalHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Safety + Pairing", systemImage: "checkmark.shield.fill")
                .font(.headline)
                .foregroundStyle(.cyan)
            Text("Status: \(statusMessage)")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
        }
        .terminalCard()
    }

    private var pairingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pairing Session")
                .font(.headline)
                .foregroundStyle(.white)

            if let current = pairing.current {
                row("Session", current.sessionId)
                row("Source", current.source)
                row("Connected", current.createdAt.formatted(date: .abbreviated, time: .shortened))
            } else {
                Text("No active session. Open deep link:")
                    .foregroundStyle(.white.opacity(0.7))
                Text("checkin://start?session=<id>&source=promatch")
                    .font(.footnote.monospaced())
                    .foregroundStyle(.white.opacity(0.55))
            }
        }
        .terminalCard()
    }

    private var monetizationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Monetization")
                .font(.headline)
                .foregroundStyle(.white)
            row("Plan", revenue.statusText)
            row("Monthly Product", revenue.monthlyProductId)
            row("Entitlement", revenue.entitlementId)
        }
        .terminalCard()
    }

    private var checkinsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Check-Ins")
                .font(.headline)
                .foregroundStyle(.white)
            checkinRow("12:15 PM", "Safe", "Office")
            checkinRow("8:42 AM", "Traveling", "I-270")
            checkinRow("6:50 AM", "Safe", "Home")
        }
        .terminalCard()
    }

    private var sosCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Emergency Protocol")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Triggering SOS will notify paired contacts and include the latest check-in session data.")
                .foregroundStyle(.white.opacity(0.75))
            Button {
                statusMessage = "SOS simulation started"
            } label: {
                Label("Simulate SOS", systemImage: "exclamationmark.triangle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        .terminalCard()
    }

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Agent Profile")
                .font(.headline)
                .foregroundStyle(.white)
            row("Email", email.isEmpty ? "agent@sentinel.io" : email)
            row("Protocol Tier", revenue.isPro ? "Pro" : "Standard")
            row("Region", "DMV")
        }
        .terminalCard()
    }

    private func checkinRow(_ time: String, _ state: String, _ location: String) -> some View {
        HStack {
            Text(time)
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Text(state)
                .fontWeight(.semibold)
                .foregroundStyle(state == "Safe" ? .green : .yellow)
            Text("•")
                .foregroundStyle(.white.opacity(0.5))
            Text(location)
                .foregroundStyle(.white)
        }
        .font(.subheadline)
    }

    private var actionsCard: some View {
        HStack(spacing: 10) {
            Button("Refresh") {
                Task { await revenue.refreshEntitlements() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)

            Button("Reset Pairing") {
                pairing.clear()
                statusMessage = "Pairing reset"
            }
            .buttonStyle(.bordered)
            .tint(.white.opacity(0.9))

            Button("Lock") {
                unlocked = false
            }
            .buttonStyle(.bordered)
            .tint(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func field(_ title: String, text: Binding<String>, icon: String, placeholder: String, secure: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .foregroundStyle(.white.opacity(0.85))
                .font(.footnote)
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(.white.opacity(0.6))
                if secure {
                    SecureField(placeholder, text: text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else {
                    TextField(placeholder, text: text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .padding(10)
            .background(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(.white)
        }
    }

    private func row(_ key: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(key)
                .foregroundStyle(.white.opacity(0.75))
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
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
        unlocked = true
        selectedTab = .home
        statusMessage = "Paired to session \(sessionId)"
    }
}

private extension View {
    func terminalCard() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    ContentView()
}
