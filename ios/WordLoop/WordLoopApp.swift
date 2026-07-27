import SwiftUI

@main
struct WordLoopApp: App {
    @StateObject private var store = WordStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .preferredColorScheme(.light)
        }
    }
}
