import SwiftUI

struct LoginView: View {
    @Binding var isAuthenticated: Bool
    @State private var username = ""
    @State private var password = ""

    @State private var loginErrorMessage: String? = nil
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
    var body: some View {
        VStack(spacing: 12) {
            Text("LetsLink").font(.largeTitle).bold()
            TextField("Username", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.username)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .padding(.horizontal)
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.password)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .padding(.horizontal)
            // Login buttons group
            VStack(spacing: 8) {
                // Regular login
                Button("Login") {
                    // Perform login via backend
                    loginErrorMessage = nil
                    Task { await login() }
                }
                .padding()
                // Guest login option
                Button("Login as Guest") {
                    loginErrorMessage = nil
                    Task { await guestLogin() }
                }
                .padding()
            }
            
            // Error message if login failed
            if let err = loginErrorMessage {
                Text(err)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
            // Divider and sign up link
            // Removed extra spacer for tighter layout
            HStack(spacing: 4) {
                Text("Don't have an account?")
                NavigationLink("Sign up", destination: RegistrationView(isAuthenticated: $isAuthenticated))
            }
            .font(.footnote)
            .padding(.top, 8)
        }
    }

    @MainActor
    private func login() async {
        // Validate input
        let userInput = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userInput.isEmpty, !password.isEmpty else {
            loginErrorMessage = "Please enter both username and password."
            return
        }
        // Prepare request
        guard let url = URL(string: "\(baseURL)/auth/login") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let bodyString = "username=\(userInput)&password=\(password)"
        request.httpBody = bodyString.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                let text = String(data: data, encoding: .utf8) ?? "Login failed"
                loginErrorMessage = text
                return
            }
            struct TokenResponse: Decodable { let access_token: String; let token_type: String; let user_id: Int }
            let decoder = JSONDecoder()
            let tokenResp = try decoder.decode(TokenResponse.self, from: data)
            // Store access token
            UserDefaults.standard.setValue(tokenResp.access_token, forKey: "accessToken")
            // Store user ID for authenticated requests
            UserDefaults.standard.setValue(tokenResp.user_id, forKey: "userId")
            // Fetch user profile
            guard let meURL = URL(string: "\(baseURL)/auth/me") else { return }
            var meRequest = URLRequest(url: meURL)
            meRequest.setValue("Bearer \(tokenResp.access_token)", forHTTPHeaderField: "Authorization")
            let (meData, meResponse) = try await URLSession.shared.data(for: meRequest)
            if let meHttp = meResponse as? HTTPURLResponse, meHttp.statusCode == 200 {
                struct UserRead: Decodable { let id: Int; let email: String; let full_name: String? }
                let userRead = try decoder.decode(UserRead.self, from: meData)
                let name = userRead.full_name ?? userRead.email
                UserDefaults.standard.setValue(name, forKey: "username")
            }
            // Mark authenticated
            isAuthenticated = true
        } catch {
            loginErrorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    private func guestLogin() async {
        // Call guest login endpoint to obtain temporary guest token
        guard let url = URL(string: "\(baseURL)/auth/guest") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                let text = String(data: data, encoding: .utf8) ?? "Guest login failed"
                loginErrorMessage = text
                return
            }
            struct TokenResponse: Decodable { let access_token: String; let token_type: String; let user_id: Int }
            let decoder = JSONDecoder()
            let tokenResp = try decoder.decode(TokenResponse.self, from: data)
            // Store access token and user ID
            UserDefaults.standard.setValue(tokenResp.access_token, forKey: "accessToken")
            UserDefaults.standard.setValue(tokenResp.user_id, forKey: "userId")
            // Fetch profile to retrieve guest name
            guard let meURL = URL(string: "\(baseURL)/auth/me") else { return }
            var meRequest = URLRequest(url: meURL)
            meRequest.setValue("Bearer \(tokenResp.access_token)", forHTTPHeaderField: "Authorization")
            let (meData, meResponse) = try await URLSession.shared.data(for: meRequest)
            if let meHttp = meResponse as? HTTPURLResponse, meHttp.statusCode == 200 {
                struct UserRead: Decodable { let id: Int; let email: String; let full_name: String? }
                let userRead = try decoder.decode(UserRead.self, from: meData)
                let name = userRead.full_name ?? userRead.email
                UserDefaults.standard.setValue(name, forKey: "username")
            }
            // Mark authenticated
            isAuthenticated = true
        } catch {
            loginErrorMessage = error.localizedDescription
        }
    }
}

#if DEBUG
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isAuthenticated: .constant(false))
    }
}
#endif