import SwiftUI

 struct ContentView: View {
    @AppStorage("isAuthenticated") private var isAuthenticated = false

    var body: some View {
        if isAuthenticated {
            MainTabView()
        } else {
            // Wrap login/signup in a navigation stack
            NavigationView {
                LoginView(isAuthenticated: $isAuthenticated)
            }
        }
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif