import SwiftUI
import MapKit

/// Chat interface for a specific event.
struct EventChatView: View {
    let event: Event

    @AppStorage("accessToken") private var accessToken: String = ""
    /// API base URL configured in Info.plist or fallback to localhost for simulator
    // API base URL: localhost for simulator; Info.plist for device
    private var baseURL: String {
        #if targetEnvironment(simulator)
        return "http://127.0.0.1:8000"
        #else
        if let url = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String, !url.isEmpty {
            return url
        }
        assertionFailure("API_BASE_URL must be set in Info.plist for device builds")
        return ""
        #endif
    }

    struct Message: Identifiable, Decodable {
        let id: Int
        let sender_id: Int
        let content: String
        let timestamp: String
    }

    @State private var messages: [Message] = []
    @State private var newMessage: String = ""

    var body: some View {
        VStack {
            List(messages) { msg in
                HStack {
                    VStack(alignment: .leading) {
                        Text(msg.content)
                            .padding(8)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        Text(msg.timestamp)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
            HStack {
                TextField("Type a message...", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Send") {
                    Task { await sendMessage() }
                }
            }
            .padding()
        }
        .navigationTitle(event.title)
        .onAppear {
            Task { await fetchMessages() }
        }
    }

    @MainActor
    private func fetchMessages() async {
        // Percent-encode full URL as a single path segment
        let raw = event.url
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove("/")
        let encodedURL = raw.addingPercentEncoding(withAllowedCharacters: allowed) ?? raw
        guard let url = URL(string: "\(baseURL)/chat/events/\(encodedURL)") else { return }
        var request = URLRequest(url: url)
        if !accessToken.isEmpty {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                let decoder = JSONDecoder()
                messages = try decoder.decode([Message].self, from: data)
            }
        } catch {
            print("EventChatView.fetchMessages error: \(error)")
        }
    }

    @MainActor
    private func sendMessage() async {
        guard !newMessage.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        // Percent-encode full URL as a single path segment
        let raw = event.url
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove("/")
        let encodedURL = raw.addingPercentEncoding(withAllowedCharacters: allowed) ?? raw
        guard let url = URL(string: "\(baseURL)/chat/events/\(encodedURL)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if !accessToken.isEmpty {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["content": newMessage]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                newMessage = ""
                await fetchMessages()
            }
        } catch {
            print("EventChatView.sendMessage error: \(error)")
        }
    }
}

#if DEBUG
struct EventChatView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleEvent = Event(
            title: "Sample Event",
            date: "2025-05-01",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        )
        NavigationView {
            EventChatView(event: sampleEvent)
        }
    }
}
#endif