import SwiftUI

struct ContentView: View {
    @State private var sessionId: String = ""
    @State private var sourceApp: String = ""
    @State private var statusMessage: String = "Waiting for check-in session"

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.shield")
                    .font(.system(size: 44))
                    .foregroundStyle(.green)

                Text("Check-In")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(statusMessage)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                if !sessionId.isEmpty {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Session ID")
                            Spacer()
                            Text(sessionId)
                                .fontWeight(.semibold)
                        }

                        if !sourceApp.isEmpty {
                            HStack {
                                Text("Source")
                                Spacer()
                                Text(sourceApp)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Text("Deep link format: checkin://start?session=<id>&source=promatch")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Safety")
            .onOpenURL(perform: handleIncomingURL)
        }
    }

    private func handleIncomingURL(_ url: URL) {
        guard url.scheme?.lowercased() == "checkin" else { return }

        if url.host?.lowercased() == "start" {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let queryItems = components?.queryItems ?? []

            sessionId = queryItems.first(where: { $0.name == "session" })?.value ?? ""
            sourceApp = queryItems.first(where: { $0.name == "source" })?.value ?? ""

            if sessionId.isEmpty {
                statusMessage = "Check-in opened, but no session id was provided."
            } else {
                statusMessage = "Check-in session loaded."
            }
        }
    }
}

#Preview {
    ContentView()
}
