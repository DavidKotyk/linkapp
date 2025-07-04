//
// DebugAgentView.swift
// DEBUG only: scrape Facebook mobile Events and list titles
#if DEBUG
import SwiftUI
import WebKit

/// A SwiftUI wrapper for WKWebView that scrapes FB mobile events page
struct DebugAgentView: View {
    @State private var events: [String] = []
    var body: some View {
        VStack(spacing: 16) {
            // Display the loaded Events page in a WebView
            WebView(events: $events)
                .frame(height: 300)
                .cornerRadius(8)
                .shadow(radius: 4)
            Text("Scraped Events:")
                .font(.headline)
                .padding(.top)
            List(events, id: \.self) { title in
                Text(title)
            }
            .listStyle(PlainListStyle())
            .frame(height: 300)
            Spacer()
        }
    }
}

/// UIViewRepresentable that loads /events and scrapes titles
struct WebView: UIViewRepresentable {
    @Binding var events: [String]

    func makeCoordinator() -> Coordinator {
        Coordinator(onEvents: { self.events = $0 })
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.navigationDelegate = context.coordinator
        if let url = URL(string: "https://m.facebook.com/events") {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    class Coordinator: NSObject, WKNavigationDelegate {
        let onEvents: ([String]) -> Void
        init(onEvents: @escaping ([String]) -> Void) {
            self.onEvents = onEvents
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let js = """
            (() => {
                const anchors = Array.from(document.querySelectorAll('a[href*="/events/"]'));
                const seen = new Set();
                const out = [];
                anchors.forEach(a => {
                    const t = (a.textContent || '').trim();
                    if (t && !seen.has(t)) { seen.add(t); out.push(t); }
                });
                return JSON.stringify(out);
            })();
            """
            // Delay scraping to allow dynamic content to load
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                webView.evaluateJavaScript(js) { result, error in
                    if let json = result as? String,
                       let data = json.data(using: .utf8),
                       let list = try? JSONDecoder().decode([String].self, from: data) {
                        DispatchQueue.main.async {
                            self.onEvents(list)
                        }
                    }
                }
            }
        }
    }
}

// Preview for SwiftUI Canvas
struct DebugAgentView_Previews: PreviewProvider {
    static var previews: some View {
        DebugAgentView()
    }
}
#endif