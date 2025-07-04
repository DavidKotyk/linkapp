import SwiftUI

/// List of event chats for the current user
struct ChatView: View {
    @AppStorage("location") private var location: String = ""
    @AppStorage("accessToken") private var accessToken: String = ""
    @StateObject private var service = EventService()

    var body: some View {
        List {
            if service.events.isEmpty {
                Text("No event chats available.")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                Section(header: Text("Event Chats")) {
                    ForEach(service.events) { event in
                        NavigationLink(destination: EventChatView(event: event)) {
                            HStack(spacing: 12) {
                                Image(systemName: "message.fill")
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(event.title)
                                        .font(.body)
                                        .lineLimit(1)
                                    Text(event.date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Chats")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Load events for chat list, defaulting to saved location or fallback
            let city = location.isEmpty ? "New York, NY" : location
            await service.loadEvents(city: city)
        }
    }
}

#if DEBUG
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView { ChatView() }
    }
}
#endif