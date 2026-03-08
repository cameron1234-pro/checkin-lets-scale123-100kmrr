import SwiftUI

struct ContentView: View {
    @StateObject private var pairing = PairingStore()
    @StateObject private var revenue = RevenueCatManager.shared

    @State private var unlocked = false
    @State private var email = ""
    @State private var password = ""
    @State private var statusMessage = "Ready"
    @State private var selectedTab: AppTab = .home

    @State private var checkinNote = ""
    @State private var checkins: [CheckInEvent] = [
        .init(state: "Safe @ Home", note: "Evening check in complete."),
        .init(state: "In transit", note: "Driving to work."),
        .init(state: "Safe @ Office", note: "Arrived and settled.")
    ]

    @State private var sosArmed = false
    @State private var sosCountdown = 10
    @State private var sosTimer: Timer?
    @State private var showSosAlert = false

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
        .onDisappear { sosTimer?.invalidate() }
        .alert("SOS Triggered", isPresented: $showSosAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Emergency flow triggered. Notify trusted contacts and dispatch services if this were production-linked.")
        }
    }

    private var authView: some View {
        VStack(spacing: 16) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.cyan)

            Text("Check In")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Welcome back. Sign in to continue.")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.7))

            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .padding(12)
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(.white)

            SecureField("Password", text: $password)
                .padding(12)
                .background(.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(.white)

            Button("Access Check In") {
                statusMessage = "Authenticated"
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
                            homeView
                        case .checkins:
                            checkinsView
                        case .sos:
                            sosView
                        case .profile:
                            profileView
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Check In")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Lock") { unlocked = false }
                        .foregroundStyle(.cyan)
                }
            }
        }
        .tint(.cyan)
    }

    private var homeView: some View {
        Group {
            card(
                title: "Pairing",
                content: pairing.current.map { "Session \($0.sessionId) • Source \($0.source)" } ?? "No active session"
            )

            card(title: "Plan", content: revenue.statusText)

            HStack {
                Button("Refresh Plan") {
                    Task { await revenue.refreshEntitlements() }
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)

                Button("Clear Pair") {
                    pairing.clear()
                    statusMessage = "Pairing cleared"
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var checkinsView: some View {
        VStack(spacing: 10) {
            VStack(spacing: 8) {
                TextField("Optional note", text: $checkinNote)
                    .padding(10)
                    .background(.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)

                HStack {
                    Button("I’m Safe") { logCheckIn(state: "Safe", note: checkinNote) }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)

                    Button("Need Help") { logCheckIn(state: "Needs Help", note: checkinNote) }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                }
            }

            ForEach(checkins) { item in
                card(title: item.state, content: "\(item.note)\n\(item.createdAt.formatted(date: .abbreviated, time: .shortened))")
            }
        }
    }

    private var sosView: some View {
        VStack(spacing: 12) {
            card(
                title: sosArmed ? "SOS Countdown" : "Emergency",
                content: sosArmed ? "Triggering in \(sosCountdown)s" : "Press and hold mindset: confirm before trigger."
            )

            Button(sosArmed ? "Cancel SOS" : "Arm SOS") {
                sosArmed ? cancelSos() : armSos()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(sosArmed ? .orange : .red)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var profileView: some View {
        Group {
            card(title: "Email", content: email.isEmpty ? "agent@checkin.app" : email)
            card(title: "Entitlement", content: revenue.isPro ? "Pro" : "Free")
            card(
                title: "Pairing Session",
                content: pairing.current?.sessionId ?? "None"
            )
        }
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

    private func logCheckIn(state: String, note: String) {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = state == "Safe" ? "User confirmed safe." : "User requested assistance."
        checkins.insert(.init(state: state, note: trimmed.isEmpty ? fallback : trimmed), at: 0)
        checkinNote = ""
        statusMessage = "Latest check-in: \(state)"
    }

    private func armSos() {
        sosArmed = true
        sosCountdown = 10
        statusMessage = "SOS armed"
        sosTimer?.invalidate()
        sosTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if sosCountdown > 1 {
                sosCountdown -= 1
            } else {
                triggerSos()
            }
        }
    }

    private func cancelSos() {
        sosTimer?.invalidate()
        sosTimer = nil
        sosArmed = false
        sosCountdown = 10
        statusMessage = "SOS cancelled"
    }

    private func triggerSos() {
        cancelSos()
        statusMessage = "SOS triggered"
        showSosAlert = true
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

private struct CheckInEvent: Identifiable {
    let id = UUID()
    let state: String
    let note: String
    let createdAt: Date = .now
}

#Preview {
    ContentView()
}
