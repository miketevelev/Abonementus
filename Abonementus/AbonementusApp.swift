import SwiftUI

@main
struct AbonementusApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 1000, minHeight: 600)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}
