import SwiftUI

/// View displaying mutual connections
struct MutualConnectionsView: View {
    /// List of mutual connection users
    let mutuals: [UserMinimal]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(mutuals) { user in
                    VStack {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                        Text(user.displayName)
                            .font(.caption)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Mutual")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Previews
#if DEBUG
struct MutualConnectionsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MutualConnectionsView(mutuals: [
                UserMinimal(id: 1, email: "alice@example.com", full_name: "Alice"),
                UserMinimal(id: 2, email: "bob@example.com", full_name: "Bob"),
                UserMinimal(id: 3, email: "charlie@example.com", full_name: "Charlie"),
                UserMinimal(id: 4, email: "dana@example.com", full_name: "Dana"),
                UserMinimal(id: 5, email: "eve@example.com", full_name: "Eve")
            ])
        }
    }
}
#endif