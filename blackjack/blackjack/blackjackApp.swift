import SwiftUI
import Firebase

@main
struct YourAppNameApp: App {
    init() {
        FirebaseApp.configure() // Ensure this is only called once
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
