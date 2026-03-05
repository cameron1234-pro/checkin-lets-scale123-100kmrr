import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var pairing = PairingStore()

    @State private var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        let view = WKWebView(frame: .zero, configuration: config)
        view.scrollView.contentInsetAdjustmentBehavior = .never
        return view
    }()

    @State private var didInitialLoad = false

    /// Lovable preview (source of truth for full parity)
    private let lovableBaseURL = URL(string: "https://id-preview--506e5f1c-9070-44d2-bb99-eb87d9d6bc29.lovable.app/auth")!

    var body: some View {
        ZStack(alignment: .topTrailing) {
            WebViewContainer(webView: webView)
                .ignoresSafeArea()

            HStack(spacing: 10) {
                Button {
                    webView.reload()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }

                Button {
                    if webView.canGoBack { webView.goBack() }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(10)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
            .padding(.trailing, 16)
            .padding(.top, 12)
        }
        .onAppear {
            if !didInitialLoad {
                didInitialLoad = true
                loadLovable()
            }
        }
        .onOpenURL(perform: handleIncomingURL)
    }

    private func loadLovable(extraQuery: [URLQueryItem] = []) {
        var components = URLComponents(url: lovableBaseURL, resolvingAgainstBaseURL: false)
        var items = components?.queryItems ?? []
        items.append(contentsOf: extraQuery)
        components?.queryItems = items.isEmpty ? nil : items

        if let url = components?.url {
            webView.load(URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData))
        }
    }

    private func handleIncomingURL(_ url: URL) {
        guard url.scheme?.lowercased() == "checkin",
              url.host?.lowercased() == "start"
        else { return }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []

        let sessionId = queryItems.first(where: { $0.name == "session" })?.value ?? ""
        let sourceApp = queryItems.first(where: { $0.name == "source" })?.value ?? "unknown"

        guard !sessionId.isEmpty else { return }

        pairing.apply(sessionId: sessionId, source: sourceApp)

        // Forward pairing context into the Lovable app for exact-flow parity.
        loadLovable(extraQuery: [
            URLQueryItem(name: "session", value: sessionId),
            URLQueryItem(name: "source", value: sourceApp)
        ])
    }
}

struct WebViewContainer: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context: Context) -> WKWebView {
        webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

#Preview {
    ContentView()
}
