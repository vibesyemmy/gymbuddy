import SwiftData
import SwiftUI

@main
struct GymBuddyApp: App {
    @AppStorage("programStart") private var programStart: Double = 0

    var body: some Scene {
        WindowGroup {
            RootView()
                .onAppear {
                    if programStart == 0 { programStart = Date().timeIntervalSince1970 }
                }
        }
        .modelContainer(for: [RunLog.self, GymLog.self, SetLog.self, BodyEntry.self])
    }
}
