import SwiftUI

@main
struct PagerTabViewControllerApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView(vcCount: 1)
                    .tabItem {
                        Image(systemName: "1.circle.fill") //タブバーの①
                    }
                ContentView(vcCount: 2)
                    .tabItem {
                        Image(systemName: "2.circle.fill") //タブバーの①
                    }
                ContentView(vcCount: 20)
                    .tabItem {
                        Image(systemName: "20.circle.fill") //タブバーの①
                    }
            }
        }
    }
}
