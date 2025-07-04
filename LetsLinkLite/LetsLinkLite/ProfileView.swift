import SwiftUI
import Foundation

// UserMinimal is defined in UserModel.swift

/// Profile screen showing user information and allowing account deletion
struct ProfileView: View {
    // Stored user info
    @AppStorage("username") private var username: String = "Guest Account"
    @AppStorage("gender") private var gender: String = ""
    @AppStorage("location") private var location: String = ""
    @AppStorage("bio") private var bio: String = ""

    // Authentication state
    @AppStorage("isAuthenticated") private var isAuthenticated: Bool = false
    @AppStorage("accessToken") private var accessToken: String = ""
    @AppStorage("userId") private var userId: Int = 0
    @State private var showDeleteAlert = false
    @State private var deleteError: String? = nil
    // Fetched followers and mutual connections
    @State private var followers: [UserMinimal] = []
    @State private var mutuals: [UserMinimal] = []

    // API base URL: localhost for simulator; Info.plist override for device builds
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Profile overview with progress ring
                VStack {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 6)
                            .frame(width: 120, height: 120)
                        Circle()
                            .trim(from: 0, to: 0.75)
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 120, height: 120)
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    }
                }
                .frame(maxWidth: .infinity)

                // Name, score, and rating
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(username.isEmpty ? "Guest Account" : username)
                            .font(.title2)
                            .bold()
                        Spacer()
                        Text("100")
                            .font(.subheadline)
                    }
                    HStack(spacing: 4) {
                        ForEach(0..<3) { idx in
                            Image(systemName: idx < 2 ? "star.fill" : "star")
                                .foregroundColor(idx < 2 ? .yellow : .gray)
                        }
                    }
                }

                // Primary actions
                HStack(spacing: 12) {
                    NavigationLink(destination: ChatView()) {
                        Text("Link")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    Button(action: {}) {
                        Text("Follow")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }

                // Interests
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Text("🏅 Sports")
                            .padding(8)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                        Text("🎨 Arts")
                            .padding(8)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(8)
                        Text("⚙️ Tech")
                            .padding(8)
                            .foregroundColor(.secondary)
                    }
                }

                // User details
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gender: \(gender.isEmpty ? "N/A" : gender)")
                    Text("Location: \(location.isEmpty ? "N/A" : location)")
                }
                .font(.subheadline)

                // Bio
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bio").font(.headline)
                    Text(bio.isEmpty ? "N/A" : bio).font(.body)
                }

                // Mutual connections
                HStack {
                    Text("Mutual").font(.headline)
                    Spacer()
                    NavigationLink("See all", destination: MutualConnectionsView(mutuals: mutuals))
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: -16) {
                        ForEach(mutuals.prefix(4)) { user in
                            VStack {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                Text(user.displayName)
                                    .font(.caption)
                            }
                        }
                        if mutuals.count > 4 {
                            Text("+\(mutuals.count - 4)")
                                .font(.subheadline)
                                .padding(6)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Followers
                VStack(alignment: .leading, spacing: 4) {
                    Text("Followers").font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: -16) {
                            ForEach(followers.prefix(5)) { user in
                                VStack {
                                    Image(systemName: "person.crop.circle.fill")
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                    Text(user.displayName)
                                        .font(.caption2)
                                }
                            }
                            if followers.count > 5 {
                                Text("+\(followers.count - 5)")
                                    .font(.subheadline)
                                    .padding(6)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Social networks
                HStack(spacing: 24) {
                    Image(systemName: "link")
                    Image(systemName: "link")
                    Image(systemName: "link")
                }
                .font(.title2)
                .padding(.top, 16)

                // Delete Account
                HStack {
                    Spacer()
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Text("Delete Account")
                            .foregroundColor(.red)
                            .font(.body)
                    }
                    Spacer()
                }
                .padding(.top, 16)
                .alert("Delete Account", isPresented: $showDeleteAlert) {
                    Button("Delete", role: .destructive) {
                        Task { await deleteAccount() }
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Are you sure? This cannot be undone.")
                }

                // Error message
                if let error = deleteError {
                    Text(error).foregroundColor(.red).font(.caption)
                }
            }
            .padding()
        }
        .task {
            await fetchFollowers()
            await fetchMutuals()
        }
    }

    @MainActor
    private func deleteAccount() async {
        deleteError = nil
        // Debug: log deletion attempt
        print("ProfileView.deleteAccount: calling DELETE \(baseURL)/auth/me with token=\(accessToken)")
        // If no access token (guest account), just clear local state
        if accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Guest or unauthenticated user: clear local storage and log out
            username = ""
            gender = ""
            location = ""
            bio = ""
            isAuthenticated = false
            return
        }
        // Debug: show token
        print("ProfileView.deleteAccount: token=\(accessToken)")
        guard let url = URL(string: "\(baseURL)/auth/me") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        if !accessToken.trimmingCharacters(in: .whitespaces).isEmpty {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                deleteError = "No HTTP response"
                return
            }
            let body = String(data: data, encoding: .utf8) ?? ""
            print("ProfileView.deleteAccount: response status=\(http.statusCode), body=\(body)")
            if (200...299).contains(http.statusCode) || http.statusCode == 401 {
                // Treat 204 or unauthorized as logout: clear auth and profile data
                accessToken = ""
                userId = 0
                username = ""
                gender = ""
                location = ""
                bio = ""
                isAuthenticated = false
            } else {
                deleteError = "Failed to delete account: \(http.statusCode) - \(body)"
            }
        } catch {
            print("ProfileView.deleteAccount: request error: \(error)")
            deleteError = "Error: \(error.localizedDescription)"
        }
    }

    // MARK: - Fetch Followers & Mutual Connections
    @MainActor
    private func fetchFollowers() async {
        guard userId > 0, let url = URL(string: "\(baseURL)/users/\(userId)/followers") else { return }
        var request = URLRequest(url: url)
        if !accessToken.trimmingCharacters(in: .whitespaces).isEmpty {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                let decoder = JSONDecoder()
                followers = try decoder.decode([UserMinimal].self, from: data)
            } else {
                print("ProfileView.fetchFollowers failed: \(response)")
            }
        } catch {
            print("ProfileView.fetchFollowers error: \(error)")
        }
    }

    @MainActor
    private func fetchMutuals() async {
        guard userId > 0, let url = URL(string: "\(baseURL)/users/\(userId)/mutual") else { return }
        var request = URLRequest(url: url)
        if !accessToken.trimmingCharacters(in: .whitespaces).isEmpty {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                let decoder = JSONDecoder()
                mutuals = try decoder.decode([UserMinimal].self, from: data)
            } else {
                print("ProfileView.fetchMutuals failed: \(response)")
            }
        } catch {
            print("ProfileView.fetchMutuals error: \(error)")
        }
    }
}


#if DEBUG
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
#endif