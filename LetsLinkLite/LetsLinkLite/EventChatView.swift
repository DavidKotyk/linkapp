import SwiftUI
import Foundation
import MapKit
import Combine

/// Model representing a chat message received via WebSocket.
struct ChatMessageWS: Codable, Identifiable {
    let id: Int
    let sender_id: Int
    let content: String
    let timestamp: String
}

/// WebSocket client for real-time chat.
class ChatWebSocketClient: ObservableObject {
    @Published var messages: [ChatMessageWS] = []
    private var webSocketTask: URLSessionWebSocketTask?
    private let jwtToken: String?
    private let eventURL: String
    private let baseURL: String

    init(eventURL: String, baseURL: String, jwtToken: String?) {
        self.eventURL = eventURL
        self.baseURL = baseURL
        self.jwtToken = jwtToken
    }

    /// Open WebSocket and start listening for messages.
    func connect() {
        var allowedChars = CharacterSet.urlPathAllowed
        allowedChars.remove("/")
        let encoded = eventURL.addingPercentEncoding(withAllowedCharacters: allowedChars) ?? eventURL
        guard let url = URL(string: "ws://\(baseURL)/ws/chat/\(encoded)") else { return }
        var request = URLRequest(url: url)
        if let token = jwtToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        webSocketTask = URLSession.shared.webSocketTask(with: request)
        webSocketTask?.resume()
        listen()
    }

    /// Recursively listen for incoming WebSocket messages.
    private func listen() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                print("WebSocket error: \(error)")
            case .success(let message):
                if case let .string(text) = message,
                   let data = text.data(using: .utf8),
                   let chat = try? JSONDecoder().decode(ChatMessageWS.self, from: data) {
                    DispatchQueue.main.async {
                        self.messages.append(chat)
                    }
                }
                self.listen()
            }
        }
    }

    /// Send a chat message via WebSocket.
    func sendMessage(_ content: String) {
        let payload = ["content": content]
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let text = String(data: data, encoding: .utf8) else { return }
        webSocketTask?.send(.string(text)) { error in
            if let error = error { print("WebSocket send error: \(error)") }
        }
    }

    /// Close the WebSocket connection.
    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
    }
}

/// Chat interface for a specific event.
struct EventChatView: View {
    let event: Event
    /// WebSocket chat client for real-time updates
    @StateObject private var socketClient: ChatWebSocketClient
    @State private var newMessage: String = ""

    /// Initialize with event and setup WebSocket client
    init(event: Event) {
        self.event = event
        // Determine host:port for WebSocket by stripping scheme
        let rawBase: String
        #if targetEnvironment(simulator)
        rawBase = "127.0.0.1:8000"
        #else
        if let urlString = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           !urlString.isEmpty {
            if urlString.hasPrefix("http://") {
                rawBase = String(urlString.dropFirst("http://".count))
            } else if urlString.hasPrefix("https://") {
                rawBase = String(urlString.dropFirst("https://".count))
            } else {
                rawBase = urlString
            }
        } else {
            rawBase = ""
        }
        #endif
        // Load persisted token for authenticated chat, or nil for guest
        let stored = UserDefaults.standard.string(forKey: "accessToken") ?? ""
        let tokenToUse = stored.isEmpty ? nil : stored
        _socketClient = StateObject(wrappedValue:
            ChatWebSocketClient(eventURL: event.url,
                                baseURL: rawBase,
                                jwtToken: tokenToUse)
        )
    }

    var body: some View {
        VStack {
            List(socketClient.messages) { msg in
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
                    sendMessage()
                }
            }
            .padding()
        }
        .navigationTitle(event.title)
        .onAppear {
            socketClient.connect()
        }
        .onDisappear {
            socketClient.disconnect()
        }
    }

    // Send message via WebSocket
    private func sendMessage() {
        let trimmed = newMessage.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        socketClient.sendMessage(trimmed)
        newMessage = ""
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