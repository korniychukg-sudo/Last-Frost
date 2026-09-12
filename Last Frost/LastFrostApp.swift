import SwiftUI

@main
struct LastFrostApp: App {
    @StateObject private var garden = FrostGarden()

    init() {
        let ink = UIColor(red: 0.149, green: 0.129, blue: 0.106, alpha: 1)
        if let face = UIFont(name: "Baskerville-Bold", size: 18) {
            UINavigationBar.appearance().titleTextAttributes = [.font: face, .foregroundColor: ink]
        }
        UINavigationBar.appearance().tintColor = ink
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if garden.book.seenIntro == true {
                    FrostRoot().environmentObject(garden)
                } else {
                    FrostIntro().environmentObject(garden)
                }
            }
            .preferredColorScheme(.light)
        }
    }
}
