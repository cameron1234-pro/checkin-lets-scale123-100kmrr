import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var pairing = PairingStore()
    @StateObject private var revenue = RevenueCatManager.shared

    @State private var unlocked = true
    @State private var email = ""
    @State private var password = ""
    @State private var statusMessage = "Ready"
    @State private var selectedTab: AppTab = .home

    @State private var activeCheckIns: [CheckInProtocol] = []
    @State private var pastCheckIns: [CheckInProtocol] = []
    @State private var contacts: [EmergencyContact] = [
        .init(name: "Primary Contact", relation: "Family", phone: "(555) 123-4567", isPrimary: true)
    ]

    @State private var showCreateSheet = false
    @State private var showAddContactSheet = false

    @State private var newCheckInTitle = ""
    @State private var newCheckInType = "Travel"
    @State private var newCheckInContactId: UUID?

    @State private var newContactName = ""
    @State private var newContactRelation = ""
    @State private var newContactPhone = ""

    @State private var sosArmed = false
    @State private var sosCountdown = 10
    @State private var sosTimer: Timer?
    @State private var showSosAlert = false

    @State private var lastAlertTimestamp: Date?
    @State private var pulseCritical = false

    @AppStorage("hasCompletedIntake") private var hasCompletedIntake = false
    @State private var rideshareConcern = false
    @State private var goesOnDates = false
    @State private var intakeContactName = ""
    @State private var intakeContactPhone = ""

    let checkInTypes = ["Travel", "Meetup", "Night Out", "Custom"]

    enum AppTab: String, CaseIterable {
        case home = "Home"
        case contacts = "Contacts"
        case history = "History"
        case sos = "SOS"
        case profile = "Profile"
    }

    private var primaryActiveCheckIn: CheckInProtocol? { activeCheckIns.first }

    var body: some View {
        ZStack {
            backgroundView

            if unlocked {
                if hasCompletedIntake {
                    mainShell
                } else {
                    intakeView
                }
            } else {
                authView
            }
        }
        .onOpenURL(perform: handleIncomingURL)
        .task { await revenue.refreshEntitlements() }
        .onDisappear { sosTimer?.invalidate() }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseCritical.toggle()
            }
        }
        .sheet(isPresented: $showCreateSheet) { createCheckInSheet }
        .sheet(isPresented: $showAddContactSheet) { addContactSheet }
        .alert("SOS Triggered", isPresented: $showSosAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Emergency flow triggered. Contact alert has been prepared.")
        }
    }

    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.02, green: 0.08, blue: 0.20), Color(red: 0.10, green: 0.05, blue: 0.28), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.cyan.opacity(0.12))
                .frame(width: 260, height: 260)
                .blur(radius: 30)
                .offset(x: -130, y: -280)

            Circle()
                .fill(Color.purple.opacity(0.15))
                .frame(width: 280, height: 280)
                .blur(radius: 34)
                .offset(x: 160, y: -220)

            Circle()
                .fill(Color.blue.opacity(0.14))
                .frame(width: 220, height: 220)
                .blur(radius: 24)
                .offset(x: -160, y: 280)
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

            Text("Secure companion access")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.7))

            TextField("Email", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .padding(12)
                .background(.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(.white)

            SecureField("Password", text: $password)
                .padding(12)
                .background(.white.opacity(0.1))
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


    private var intakeView: some View {
        VStack(spacing: 16) {
            Text("Before we start")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            card(title: "Safety setup", content: "Let’s personalize Check In for your routine.")

            Toggle(isOn: $rideshareConcern) {
                Text("Have you ever been uncomfortable in a rideshare?")
                    .foregroundStyle(.white)
            }
            .toggleStyle(.switch)
            .tint(.cyan)
            .padding(12)
            .background(.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Toggle(isOn: $goesOnDates) {
                Text("Do you go on a lot of dates?")
                    .foregroundStyle(.white)
            }
            .toggleStyle(.switch)
            .tint(.purple)
            .padding(12)
            .background(.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            TextField("Trusted contact name", text: $intakeContactName)
                .padding(12)
                .background(.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(.white)

            TextField("Trusted contact phone", text: $intakeContactPhone)
                .keyboardType(.phonePad)
                .padding(12)
                .background(.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(.white)

            Button("Finish Setup") {
                completeIntake()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(LinearGradient(colors: [.cyan, .purple], startPoint: .leading, endPoint: .trailing))
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .disabled(intakeContactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || intakeContactPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            Text("You can change this later in Contacts.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))
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
                        currentStatusBanner
                        card(title: "Status", content: statusMessage)

                        switch selectedTab {
                        case .home:
                            homeView
                        case .contacts:
                            contactsView
                        case .history:
                            historyView
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
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if selectedTab == .home {
                        Button {
                            showCreateSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .foregroundStyle(.cyan)
                    }

                    Button("Lock") { unlocked = false }
                        .foregroundStyle(.cyan)
                }
            }
        }
        .tint(.cyan)
    }

    private var currentStatusBanner: some View {
        let status = primaryActiveCheckIn?.status ?? .allGood
        return HStack(spacing: 10) {
            Circle()
                .fill(status.color)
                .frame(width: 12, height: 12)
                .shadow(color: status.color.opacity(0.8), radius: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text("Current Safety Tier")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
                Text("Tier \(status.tier) • \(status.rawValue)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(status.color.opacity(0.22))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(status.color.opacity(0.85), lineWidth: 1))
                .shadow(color: status.color.opacity(status.isCritical ? (pulseCritical ? 0.8 : 0.45) : 0.2), radius: status.isCritical ? 16 : 6)
        )
        .animation(.easeInOut(duration: 0.25), value: status)
    }

    private var homeView: some View {
        Group {
            card(
                title: "Pairing",
                content: pairing.current.map { "Session \($0.sessionId) • Source \($0.source)" } ?? "No active session"
            )

            card(title: "Plan", content: revenue.statusText)

            if let last = lastAlertTimestamp {
                card(title: "Last contact alert sent", content: last.formatted(date: .abbreviated, time: .shortened))
            }

            quickActionsRow

            if activeCheckIns.isEmpty {
                card(title: "No Active Protocols", content: "Start a check-in to begin live safety tracking.")
                Button("Create Check-In") {
                    showCreateSheet = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
            } else {
                ForEach(activeCheckIns) { checkIn in
                    VStack(spacing: 8) {
                        statusCard(for: checkIn)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(SafetyStatus.allCases, id: \.self) { status in
                                    Button(status.shortLabel) {
                                        withAnimation(.easeInOut(duration: 0.24)) {
                                            updateStatus(checkIn.id, status)
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(status.color)
                                    .accessibilityLabel(status.rawValue)
                                }
                                Button("End") { endCheckIn(checkIn.id) }
                                    .buttonStyle(.bordered)
                            }
                        }

                        if checkIn.status.isCritical {
                            Text("Tier \(checkIn.status.tier) will notify your contact")
                                .font(.caption)
                                .foregroundStyle(checkIn.status.color)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
    }

    private var quickActionsRow: some View {
        HStack {
            Button {
                openMapsToSafety()
            } label: {
                Label("Share Location", systemImage: "location.fill")
            }
            .buttonStyle(.bordered)

            Button {
                callPrimaryContact()
            } label: {
                Label("Call Contact", systemImage: "phone.fill")
            }
            .buttonStyle(.bordered)

            Button {
                if let id = activeCheckIns.first?.id {
                    updateStatus(id, .wantOut)
                }
            } label: {
                Label("Tier 4", systemImage: "exclamationmark.triangle.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
    }

    private func statusCard(for checkIn: CheckInProtocol) -> some View {
        let current = checkIn.status
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(checkIn.icon) \(checkIn.title)")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("Tier \(current.tier)")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.18))
                    .clipShape(Capsule())
                    .foregroundStyle(.white)
            }

            Text("Type: \(checkIn.type)")
                .foregroundStyle(.white.opacity(0.9))

            Text(current.rawValue)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            if let contact = primaryContact(for: checkIn) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(.white.opacity(0.24))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text(contact.initials)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                        )
                    Text("Contact: \(contact.name)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            LinearGradient(
                colors: [current.color.opacity(0.86), .black.opacity(0.64)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(current.color.opacity(0.9), lineWidth: 1)
        )
        .shadow(color: current.color.opacity(current.isCritical ? (pulseCritical ? 0.8 : 0.4) : 0.25), radius: current.isCritical ? 16 : 6)
        .animation(.easeInOut(duration: 0.25), value: current)
    }

    private var contactsView: some View {
        VStack(spacing: 10) {
            Button("Add Contact") {
                showAddContactSheet = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)

            if contacts.isEmpty {
                card(title: "No Contacts", content: "Add at least one emergency contact.")
            } else {
                ForEach(contacts) { contact in
                    VStack(spacing: 8) {
                        card(
                            title: contact.isPrimary ? "⭐︎ \(contact.name)" : contact.name,
                            content: "\(contact.relation)\n\(contact.phone)"
                        )

                        HStack {
                            Button("Set Primary") { setPrimary(contact.id) }
                                .buttonStyle(.bordered)
                            Button("Delete", role: .destructive) { deleteContact(contact.id) }
                                .buttonStyle(.bordered)
                        }
                    }
                }
            }
        }
    }

    private var historyView: some View {
        Group {
            if pastCheckIns.isEmpty {
                card(title: "No History", content: "Completed check-ins will appear here.")
            } else {
                ForEach(pastCheckIns) { item in
                    card(title: "\(item.icon) \(item.title)", content: "\(item.type) • \(item.status.rawValue) • \(item.createdAt.formatted(date: .abbreviated, time: .shortened))")
                }
            }
        }
    }

    private var sosView: some View {
        VStack(spacing: 12) {
            card(
                title: sosArmed ? "SOS Countdown" : "Emergency",
                content: sosArmed ? "Triggering in \(sosCountdown)s" : "Arm emergency mode for immediate escalation."
            )

            if sosArmed {
                sosRing
            }

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

    private var sosRing: some View {
        let progress = CGFloat(max(0, min(1, Double(10 - sosCountdown) / 10.0)))
        return ZStack {
            Circle()
                .stroke(.white.opacity(0.2), lineWidth: 10)
                .frame(width: 90, height: 90)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(colors: [.yellow, .orange, .red], center: .center),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 90, height: 90)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: progress)
            Text("\(sosCountdown)")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
        }
    }

    private var profileView: some View {
        Group {
            card(title: "Email", content: email.isEmpty ? "agent@checkin.app" : email)
            card(title: "Entitlement", content: revenue.isPro ? "Pro" : "Free")
            card(title: "Pairing Session", content: pairing.current?.sessionId ?? "None")

            HStack {
                Button("Refresh Plan") { Task { await revenue.refreshEntitlements() } }
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

    private var createCheckInSheet: some View {
        NavigationStack {
            Form {
                Section("Protocol") {
                    TextField("Title", text: $newCheckInTitle)
                    Picker("Type", selection: $newCheckInType) {
                        ForEach(checkInTypes, id: \.self) { t in
                            Text(t).tag(t)
                        }
                    }

                    Picker("Emergency Contact", selection: $newCheckInContactId) {
                        Text("None").tag(UUID?.none)
                        ForEach(contacts) { contact in
                            Text(contact.name).tag(Optional(contact.id))
                        }
                    }
                }
            }
            .navigationTitle("Create Check-In")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showCreateSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") { createCheckIn() }
                        .disabled(newCheckInTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var addContactSheet: some View {
        NavigationStack {
            Form {
                Section("Emergency Contact") {
                    TextField("Name", text: $newContactName)
                    TextField("Relation", text: $newContactRelation)
                    TextField("Phone", text: $newContactPhone)
                        .keyboardType(.phonePad)
                }
            }
            .navigationTitle("Add Contact")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showAddContactSheet = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { addContact() }
                        .disabled(newContactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func card(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            Text(content)
                .foregroundStyle(.white.opacity(0.88))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.white.opacity(0.18), .white.opacity(0.06)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        )
    }

    private func completeIntake() {
        let name = intakeContactName.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = intakeContactPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !phone.isEmpty else { return }

        contacts = [EmergencyContact(name: name, relation: "Trusted Contact", phone: phone, isPrimary: true)] + contacts.map { c in
            var mutable = c
            mutable.isPrimary = false
            return mutable
        }

        statusMessage = "Safety setup complete"
        if rideshareConcern { statusMessage += " • Rideshare watch enabled" }
        if goesOnDates { statusMessage += " • Date safety watch enabled" }

        hasCompletedIntake = true
    }

    private func createCheckIn() {
        let title = newCheckInTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }

        let protocolItem = CheckInProtocol(
            title: title,
            type: newCheckInType,
            emergencyContactId: newCheckInContactId,
            status: .allGood
        )

        activeCheckIns.insert(protocolItem, at: 0)
        statusMessage = "Check-in started: \(title)"

        newCheckInTitle = ""
        newCheckInType = "Travel"
        newCheckInContactId = nil
        showCreateSheet = false
    }

    private func updateStatus(_ id: UUID, _ status: SafetyStatus) {
        guard let idx = activeCheckIns.firstIndex(where: { $0.id == id }) else { return }
        activeCheckIns[idx].status = status
        statusMessage = "\(activeCheckIns[idx].title): \(status.rawValue)"

        if status.shouldNotifyContact {
            sendAlertToContact(for: activeCheckIns[idx], status: status)
        }
    }

    private func endCheckIn(_ id: UUID) {
        guard let idx = activeCheckIns.firstIndex(where: { $0.id == id }) else { return }
        let finished = activeCheckIns.remove(at: idx)
        pastCheckIns.insert(finished, at: 0)
        statusMessage = "Ended: \(finished.title)"
    }

    private func addContact() {
        let name = newContactName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        let contact = EmergencyContact(
            name: name,
            relation: newContactRelation.isEmpty ? "Contact" : newContactRelation,
            phone: newContactPhone.isEmpty ? "Not set" : newContactPhone,
            isPrimary: contacts.isEmpty
        )

        contacts.append(contact)
        statusMessage = "Added contact: \(contact.name)"

        newContactName = ""
        newContactRelation = ""
        newContactPhone = ""
        showAddContactSheet = false
    }

    private func deleteContact(_ id: UUID) {
        contacts.removeAll { $0.id == id }
        if contacts.allSatisfy({ !$0.isPrimary }), let first = contacts.indices.first {
            contacts[first].isPrimary = true
        }
        statusMessage = "Contact deleted"
    }

    private func setPrimary(_ id: UUID) {
        for i in contacts.indices {
            contacts[i].isPrimary = contacts[i].id == id
        }
        statusMessage = "Primary contact updated"
    }

    private func primaryContact(for checkIn: CheckInProtocol) -> EmergencyContact? {
        if let id = checkIn.emergencyContactId,
           let linked = contacts.first(where: { $0.id == id }) {
            return linked
        }
        return contacts.first(where: { $0.isPrimary }) ?? contacts.first
    }

    private func callPrimaryContact() {
        guard let contact = contacts.first(where: { $0.isPrimary }) ?? contacts.first else {
            statusMessage = "No contact to call"
            return
        }

        let cleanNumber = contact.phone.filter { "0123456789+".contains($0) }
        if let url = URL(string: "tel://\(cleanNumber)") {
            UIApplication.shared.open(url)
            statusMessage = "Calling \(contact.name)"
        } else {
            statusMessage = "Could not start call"
        }
    }

    private func openMapsToSafety() {
        if let url = URL(string: "maps://") {
            UIApplication.shared.open(url)
            statusMessage = "Opened Maps for location share"
        } else {
            statusMessage = "Maps unavailable"
        }
    }

    private func sendAlertToContact(for checkIn: CheckInProtocol, status: SafetyStatus) {
        guard let contact = primaryContact(for: checkIn) else {
            statusMessage = "Alert queued: add a contact first"
            return
        }

        let body = "Check In Alert: \(checkIn.title) is now at Tier \(status.tier) (\(status.rawValue)). Please check in immediately."
        let cleanNumber = contact.phone.filter { "0123456789+".contains($0) }
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "sms:\(cleanNumber)&body=\(encodedBody)") {
            UIApplication.shared.open(url)
            lastAlertTimestamp = .now
            statusMessage = "Alert sent to \(contact.name)"
        } else {
            statusMessage = "Could not open SMS for \(contact.name)"
        }
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
        if let first = activeCheckIns.first {
            sendAlertToContact(for: first, status: .emergency)
        }
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

private struct CheckInProtocol: Identifiable {
    let id = UUID()
    let title: String
    let type: String
    let emergencyContactId: UUID?
    var status: SafetyStatus
    let createdAt: Date = .now

    var icon: String {
        switch type {
        case "Travel": return "✈️"
        case "Meetup": return "🤝"
        case "Night Out": return "🌙"
        default: return "📍"
        }
    }
}

private struct EmergencyContact: Identifiable {
    let id = UUID()
    var name: String
    var relation: String
    var phone: String
    var isPrimary: Bool

    var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? "?"
        let second = parts.dropFirst().first?.prefix(1) ?? ""
        return "\(first)\(second)"
    }
}

private enum SafetyStatus: String, CaseIterable {
    case allGood = "Everything is okay — this is great"
    case okayButWary = "Still okay, but wary"
    case okayThisIsWeird = "Okay… this is weird"
    case wantOut = "I want to get out of here"
    case emergency = "Emergency — this is bad"

    var tier: Int {
        switch self {
        case .allGood: return 1
        case .okayButWary: return 2
        case .okayThisIsWeird: return 3
        case .wantOut: return 4
        case .emergency: return 5
        }
    }

    var shortLabel: String { "T\(tier)" }

    var shouldNotifyContact: Bool {
        self == .wantOut || self == .emergency
    }

    var isCritical: Bool {
        self == .wantOut || self == .emergency
    }

    var color: Color {
        switch self {
        case .allGood: return .green
        case .okayButWary: return .teal
        case .okayThisIsWeird: return .yellow
        case .wantOut: return .orange
        case .emergency: return .red
        }
    }
}

#Preview {
    ContentView()
}
