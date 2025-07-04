import SwiftUI

/// Sign up screen for creating a new account
struct RegistrationView: View {
    @Binding var isAuthenticated: Bool
    @State private var email: String = ""
    @State private var fullName: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var gender: String = ""
    @State private var location: String = ""
    @State private var bio: String = ""
    @State private var errorMessage: String? = nil

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
        VStack(spacing: 16) {
            Text("Sign Up")
                .font(.largeTitle)
                .bold()
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            TextField("Full Name", text: $fullName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            // Additional profile info
            TextField("Gender", text: $gender)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            TextField("Location", text: $location)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            TextEditor(text: $bio)
                .frame(height: 80)
                .padding(.horizontal)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
            Button("Sign Up") {
                Task { await signUp() }
            }
            .padding()
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
            Spacer()
        }
        .navigationBarTitle("Sign Up", displayMode: .inline)
    }

    @MainActor
    private func signUp() async {
        errorMessage = nil
        // Basic validation
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty,
              !fullName.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.isEmpty else {
            errorMessage = "All fields are required."
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        // Prepare request
        guard let url = URL(string: "\(baseURL)/auth/register") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Build JSON body including optional profile fields
        var body: [String: Any] = [
            "email": email,
            "password": password,
            "full_name": fullName
        ]
        if !gender.trimmingCharacters(in: .whitespaces).isEmpty {
            body["gender"] = gender
        }
        if !location.trimmingCharacters(in: .whitespaces).isEmpty {
            body["location"] = location
        }
        if !bio.trimmingCharacters(in: .whitespaces).isEmpty {
            body["bio"] = bio
        }
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                // Parse token response
                struct TokenResponse: Decodable {
                    let access_token: String
                    let token_type: String
                    let user_id: Int
                }
                let decoder = JSONDecoder()
                let tokenResp = try decoder.decode(TokenResponse.self, from: data)
                // Store access token and initial username
                // Store access token and initial profile data
                UserDefaults.standard.setValue(tokenResp.access_token, forKey: "accessToken")
                // Store user ID for authenticated requests
                UserDefaults.standard.setValue(tokenResp.user_id, forKey: "userId")
                UserDefaults.standard.setValue(fullName, forKey: "username")
                UserDefaults.standard.setValue(gender, forKey: "gender")
                UserDefaults.standard.setValue(location, forKey: "location")
                UserDefaults.standard.setValue(bio, forKey: "bio")
                // Success: mark authenticated
                isAuthenticated = true
            } else {
                let text = String(data: data, encoding: .utf8) ?? "Server error"
                errorMessage = text
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#if DEBUG
struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RegistrationView(isAuthenticated: .constant(false))
        }
    }
}
#endif