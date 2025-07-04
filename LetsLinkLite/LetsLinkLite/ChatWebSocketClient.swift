#if false
import Foundation
import Combine

/// Model representing a chat message.
public struct ChatMessage: Codable, Identifiable {
    public let id: Int
    public let sender_id: Int
    public let content: String
    public let timestamp: String
}

/// WebSocket client for real-time chat.
public class ChatWebSocketClient: ObservableObject {
    @Published public private(set) var messages: [ChatMessage] = []
    private var webSocketTask: URLSessionWebSocketTask?
    private let jwtToken: String?
    private let eventURL: String
    private let baseURL: String

    /// Initialize the client.
    /// - Parameters:
    ///   - eventURL: Full event URL string (will be percent-encoded).
    ///   - baseURL: WebSocket server host (e.g. "localhost:8000").
    ///   - jwtToken: Optional Bearer token.
    public init(eventURL: String, baseURL: String, jwtToken: String?) {
        self.eventURL = eventURL
        self.baseURL = baseURL
        self.jwtToken = jwtToken
    }

    /// Connect and start receiving messages.
    public func connect() {
        // Percent-encode the event URL for the path
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove("/")
        let encoded = eventURL.addingPercentEncoding(withAllowedCharacters: allowed) ?? eventURL
        guard let url = URL(string: "ws://\(baseURL)/ws/chat/\(encoded)") else { return }
        var request = URLRequest(url: url)
        if let token = jwtToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        webSocketTask = URLSession.shared.webSocketTask(with: request)
        webSocketTask?.resume()
        listen()
    }

    /// Listen for incoming messages recursively.
    private func listen() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                print("WebSocket error: \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8),
                       let chatMessage = try? JSONDecoder().decode(ChatMessage.self, from: data) {
                        DispatchQueue.main.async {
                            self.messages.append(chatMessage)
                        }
                    }
                default:
                    break
                }
                // Continue listening
                self.listen()
            }
        }
    }

    /// Send a chat message via WebSocket.
    /// - Parameter content: Message text.
    public func sendMessage(_ content: String) {
        let payload = ["content": content]
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let text = String(data: data, encoding: .utf8) else { return }
        webSocketTask?.send(.string(text)) { error in
            if let error = error {
                print("WebSocket send error: \(error)")
            }
        }
    }

    /// Disconnect the WebSocket.
    public func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
    }
}
#endif  // end disabled ChatWebSocketClient definitions