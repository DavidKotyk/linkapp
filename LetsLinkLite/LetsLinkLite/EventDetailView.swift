import SwiftUI
import Foundation
import MapKit

// MARK: - UserRow for attendee navigation
struct UserRow: View {
    let user: UserMinimal

    var body: some View {
        NavigationLink(destination: ProfileView()) {
            VStack(spacing: 4) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                Text(user.displayName)
                    .font(.caption2)
                    .lineLimit(1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EventDetailView: View {
    let event: Event

    // Preview region for embedded map
    @State private var mapRegion: MKCoordinateRegion
    // Authentication and network context
    @AppStorage("accessToken") private var accessToken: String = ""
    @AppStorage("userId") private var userId: Int = 0
    @State private var isAttending: Bool = false
    @State private var attendeesCount: Int = 0
    @State private var attendees: [UserMinimal] = []
    @State private var followings: [UserMinimal] = []
    @State private var friendsAttending: [UserMinimal] = []

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

    init(event: Event) {
        self.event = event
        // Initialize map region around event location
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        _mapRegion = State(initialValue: MKCoordinateRegion(center: event.coordinate, span: span))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Event info with source link upfront
                VStack(alignment: .leading, spacing: 8) {
                    Text(event.title)
                        .font(.title)
                        .bold()
                    // Source link
                    if let linkURL = URL(string: event.url) {
                        Link(event.source, destination: linkURL)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    HStack {
                        Text("Starts: \(event.date)")
                        Spacer()
                        Text("Ends: NA")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    HStack(spacing: 16) {
                        Text("Participants: NA")
                        Text("|")
                        Text("Likes: NA")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }

                // Location map preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Location")
                        .font(.headline)
                    Map(coordinateRegion: $mapRegion,
                        annotationItems: [event]) { evt in
                        MapMarker(coordinate: evt.coordinate, tint: .red)
                    }
                    .frame(height: 200)
                    .cornerRadius(8)
                }

                // Actions
                VStack(spacing: 16) {
                    Button(action: {
                        Task { await toggleAttendance() }
                    }) {
                        Text(isAttending ? "Leave" : "Join")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isAttending ? Color.red : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    HStack(spacing: 16) {
                        Button(action: { /* Like functionality */ }) {
                            Label("Like", systemImage: "hand.thumbsup.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        }
                        NavigationLink(destination: EventChatView(event: event)) {
                            Label("Chat", systemImage: "message")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.blue, lineWidth: 1)
                                )
                        }
                    }
                }

                // Description + Source Link
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                    // Show source as clickable link first
                    if let linkURL = URL(string: event.url) {
                        Link(event.source, destination: linkURL)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    // Then the event description
                    Text(event.description)
                        .font(.body)
                }

                // Participants overview
                // Participants overview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Participants (\(attendeesCount))")
                        .font(.headline)
                    if attendees.isEmpty {
                        Text("No participants yet.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(attendees.prefix(10)) { user in
                                    UserRow(user: user)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                // Friends attending
                // Friends attending
                VStack(alignment: .leading, spacing: 8) {
                    Text("Friends Attending (\(friendsAttending.count))")
                        .font(.headline)
                    if friendsAttending.isEmpty {
                        Text("No friends attending.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(friendsAttending.prefix(5)) { user in
                                    VStack(spacing: 4) {
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .frame(width: 50, height: 50)
                                        Text(user.displayName)
                                            .font(.caption2)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                // Photo gallery
                VStack(alignment: .leading, spacing: 8) {
                    Text("Photo Gallery")
                        .font(.headline)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(0..<6) { idx in
                            Color.gray
                                .frame(height: 100)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(event.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { Task { await fetchAttendees() } }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { /* Bookmark */ }) {
                    Image(systemName: "bookmark")
                }
            }
        }
    }
    
    @MainActor
    private func fetchAttendees() async {
        // Fetch participants for this event
        // Percent-encode full URL as a single path segment
        let raw = event.url
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove("/")  // ensure slashes are percent-encoded
        let encodedURL = raw.addingPercentEncoding(withAllowedCharacters: allowed) ?? raw
        guard let url = URL(string: "\(baseURL)/events/\(encodedURL)/attendees") else { return }
        var request = URLRequest(url: url)
        if !accessToken.isEmpty {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                switch http.statusCode {
                case 200:
                    let decoder = JSONDecoder()
                    // Decode list of users attending
                    let users = try decoder.decode([UserMinimal].self, from: data)
                    // Update state
                    attendees = users
                    attendeesCount = users.count
                    isAttending = users.contains(where: { $0.id == userId })
                    // After loading attendees, fetch followings and compute friends attending
                    await fetchFollowings()
                case 401:
                    // Unauthorized: clear token and prompt re-login
                    accessToken = ""
                    userId = 0
                case 404:
                    // No attendees or event not found
                    attendees = []
                    attendeesCount = 0
                default:
                    break
                }
            }
        } catch {
            print("EventDetailView.fetchAttendees error: \(error)")
        }
    }

    @MainActor
    private func toggleAttendance() async {
        // Percent-encode full URL as a single path segment
        let raw = event.url
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove("/")
        let encodedURL = raw.addingPercentEncoding(withAllowedCharacters: allowed) ?? raw
        guard let url = URL(string: "\(baseURL)/events/\(encodedURL)/attend") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = isAttending ? "DELETE" : "POST"
        if !accessToken.isEmpty {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse {
                switch http.statusCode {
                case 200...299:
                    // Successful join/leave; update state and refresh
                    isAttending.toggle()
                    attendeesCount += isAttending ? 1 : -1
                    await fetchAttendees()
                case 401:
                    // Unauthorized: clear token and prompt re-login
                    accessToken = ""
                    userId = 0
                case 404:
                    // Event not found: no-op or show user message
                    break
                default:
                    // Other errors: log or handle as needed
                    break
                }
            }
        } catch {
            print("EventDetailView.toggleAttendance error: \(error)")
        }
    }
    
    /// Fetch users that current user is following, and compute friends attending
    @MainActor
    private func fetchFollowings() async {
        guard userId > 0,
              let url = URL(string: "\(baseURL)/users/\(userId)/following") else { return }
        var request = URLRequest(url: url)
        if !accessToken.isEmpty {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                let decoder = JSONDecoder()
                followings = try decoder.decode([UserMinimal].self, from: data)
                // Compute intersection of attendees and followings
                let followingIDs = Set(followings.map { $0.id })
                friendsAttending = attendees.filter { followingIDs.contains($0.id) }
            }
        } catch {
            print("EventDetailView.fetchFollowings error: \(error)")
        }
    }
}

#if DEBUG
struct EventDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleEvent = Event(
            title: "Sample Event",
            date: "2025-05-01",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        )
        NavigationView {
            EventDetailView(event: sampleEvent)
        }
    }
}
#endif