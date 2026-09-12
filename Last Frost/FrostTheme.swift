import SwiftUI

enum Loam {
    static let page = Color(red: 0.945, green: 0.922, blue: 0.863)
    static let pageDeep = Color(red: 0.890, green: 0.855, blue: 0.780)
    static let card = Color(red: 0.980, green: 0.965, blue: 0.930)
    static let ink = Color(red: 0.149, green: 0.129, blue: 0.106)
    static let inkSoft = Color(red: 0.318, green: 0.286, blue: 0.243)
    static let inkFaint = Color(red: 0.520, green: 0.482, blue: 0.431)
    static let soil = Color(red: 0.294, green: 0.227, blue: 0.165)
    static let soilDark = Color(red: 0.200, green: 0.153, blue: 0.110)
    static let soilLight = Color(red: 0.420, green: 0.337, blue: 0.251)
    static let leaf = Color(red: 0.306, green: 0.478, blue: 0.235)
    static let leafDeep = Color(red: 0.184, green: 0.306, blue: 0.153)
    static let leafPale = Color(red: 0.588, green: 0.702, blue: 0.451)
    static let terracotta = Color(red: 0.722, green: 0.380, blue: 0.227)
    static let terracottaDeep = Color(red: 0.545, green: 0.267, blue: 0.145)
    static let frost = Color(red: 0.616, green: 0.714, blue: 0.769)
    static let frostDeep = Color(red: 0.400, green: 0.510, blue: 0.580)
    static let straw = Color(red: 0.831, green: 0.702, blue: 0.396)
    static let strawPale = Color(red: 0.910, green: 0.831, blue: 0.620)
    static let good = Color(red: 0.310, green: 0.478, blue: 0.325)
    static let warn = Color(red: 0.706, green: 0.502, blue: 0.180)
    static let bad = Color(red: 0.639, green: 0.212, blue: 0.161)
    static let prize = Color(red: 0.741, green: 0.588, blue: 0.235)

    static func title(_ size: CGFloat) -> Font { .custom("Baskerville-Bold", size: size) }
    static func body(_ size: CGFloat) -> Font { .custom("Baskerville", size: size) }
    static func note(_ size: CGFloat) -> Font { .custom("Baskerville-Italic", size: size) }

    static var isPad: Bool { UIScreen.main.bounds.width >= 700 }
    static var isNarrow: Bool { UIScreen.main.bounds.width <= 340 }
    static var gutter: CGFloat { isPad ? 32 : (isNarrow ? 12 : 17) }
    static var plateHeight: CGFloat { isPad ? 300 : 210 }
}

enum Tap {
    static func light() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func firm() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func hard() { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
    static func crisp() { UIImpactFeedbackGenerator(style: .rigid).impactOccurred() }
    static func soft() { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
}

struct RiseIn: ViewModifier {
    let index: Int
    @State private var shown = false
    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 14)
            .onAppear {
                withAnimation(.easeOut(duration: 0.38).delay(Double(index) * 0.05)) { shown = true }
            }
    }
}

extension View {
    func rising(_ index: Int) -> some View { modifier(RiseIn(index: index)) }
}

extension Color {
    static func blend(_ a: Color, _ b: Color, _ t: Double) -> Color {
        let ua = UIColor(a), ub = UIColor(b)
        var r0: CGFloat = 0, g0: CGFloat = 0, b0: CGFloat = 0, a0: CGFloat = 0
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        ua.getRed(&r0, green: &g0, blue: &b0, alpha: &a0)
        ub.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        let k = CGFloat(max(0, min(1, t)))
        return Color(red: Double(r0 + (r1 - r0) * k), green: Double(g0 + (g1 - g0) * k),
                     blue: Double(b0 + (b1 - b0) * k), opacity: Double(a0 + (a1 - a0) * k))
    }
}
