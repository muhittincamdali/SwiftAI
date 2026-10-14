import SwiftUI

@main
struct ModelLabApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem { Label("Quick start", systemImage: "sparkles") }
                ClassifyView()
                    .tabItem { Label("Classify", systemImage: "slider.horizontal.3") }
                BoundariesView()
                    .tabItem { Label("Boundaries", systemImage: "square.grid.3x3") }
            }
        }
    }
}
