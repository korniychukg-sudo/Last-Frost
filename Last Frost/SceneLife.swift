import SwiftUI

extension SceneDrawer {
    var month: Int { Almanac.parts(of: day).month }

    var nearFrostDates: Bool {
        let fy = FrostYear(dates, year: Almanac.year(of: day))
        return !dates.frostFree && (abs(day - fy.lastFrost) <= 14 || abs(day - fy.firstFrost) <= 14)
    }

    mutating func drawLife() {
        drawCloudShadow()
        if season == 2 && tone.light > 0.5 { drawSwallows() }
        if season == 3 && tone.light > 0.25 { drawFallingLeaves() }
        if season == 0 && weather == .frost && tone.light > 0.2 { drawSnow() }
        if tone.light < 0.42 && (nearFrostDates || weather == .frost) { drawFrostGlitter() }
        if weather == .clear && tone.light > 0.6 { drawSunMotes() }
    }

    mutating func drawCloudShadow() {
        let strength: Double
        switch weather {
        case .rain: strength = 0.14
        case .cloud: strength = 0.17
        case .frost: strength = 0.06
        case .clear: strength = 0.07
        }
        guard tone.light > 0.3 else { return }
        let span = w * 1.7
        let speed = weather == .clear ? 9.0 : 16.0
        let x = CGFloat((time * speed).truncatingRemainder(dividingBy: Double(span))) - w * 0.35
        let ground = CGRect(x: 0, y: horizon, width: w, height: h - horizon)
        var sub = ctx
        sub.clip(to: Path(ground))
        let rect = CGRect(x: x - w * 0.42, y: horizon - h * 0.05, width: w * 0.84, height: h * 0.7)
        sub.fill(Path(ellipseIn: rect),
                 with: .radialGradient(Gradient(colors: [Color(red: 0.05, green: 0.06, blue: 0.10).opacity(strength * tone.light), Color.clear]),
                                       center: CGPoint(x: rect.midX, y: rect.midY), startRadius: 0, endRadius: rect.width * 0.5))
        let x2 = CGFloat((time * speed * 0.7 + Double(w) * 0.9).truncatingRemainder(dividingBy: Double(span))) - w * 0.35
        let rect2 = CGRect(x: x2 - w * 0.25, y: horizon + h * 0.1, width: w * 0.5, height: h * 0.4)
        sub.fill(Path(ellipseIn: rect2),
                 with: .radialGradient(Gradient(colors: [Color(red: 0.05, green: 0.06, blue: 0.10).opacity(strength * 0.7 * tone.light), Color.clear]),
                                       center: CGPoint(x: rect2.midX, y: rect2.midY), startRadius: 0, endRadius: rect2.width * 0.5))
    }

    mutating func drawSwallows() {
        for k in 0..<3 {
            let phase = Double(k) * 2.1
            let speed = 26.0 + Double(k) * 7
            let span = Double(w) + 80
            let x = CGFloat((time * speed + phase * 90).truncatingRemainder(dividingBy: span)) - 40
            let y = horizon * CGFloat(0.28 + 0.16 * Double(k)) + CGFloat(sin(time * 1.3 + phase) * 14 + sin(time * 0.4 + phase) * 22)
            let flap = sin(time * 14 + phase * 3)
            let s = CGFloat(6 + Double(k))
            var bird = Path()
            bird.move(to: CGPoint(x: x - s * 1.4, y: y - s * CGFloat(0.35 + 0.55 * flap)))
            bird.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: x - s * 0.6, y: y + s * 0.1))
            bird.addQuadCurve(to: CGPoint(x: x + s * 1.4, y: y - s * CGFloat(0.35 + 0.55 * flap)), control: CGPoint(x: x + s * 0.6, y: y + s * 0.1))
            ctx.stroke(bird, with: .color(Color(red: 0.12, green: 0.12, blue: 0.16).opacity(0.85)), style: StrokeStyle(lineWidth: max(1, s * 0.16), lineCap: .round))
            var tail = Path()
            tail.move(to: CGPoint(x: x, y: y))
            tail.addLine(to: CGPoint(x: x - s * 0.5, y: y + s * 0.8))
            tail.move(to: CGPoint(x: x, y: y))
            tail.addLine(to: CGPoint(x: x + s * 0.2, y: y + s * 0.8))
            ctx.stroke(tail, with: .color(Color(red: 0.12, green: 0.12, blue: 0.16).opacity(0.8)), lineWidth: max(0.8, s * 0.12))
        }
    }

    mutating func drawFallingLeaves() {
        var rng = Furrow(0xFA11)
        let tones = [Color(red: 0.80, green: 0.50, blue: 0.22), Color(red: 0.70, green: 0.36, blue: 0.16), Color(red: 0.86, green: 0.66, blue: 0.24), Color(red: 0.55, green: 0.30, blue: 0.14)]
        for k in 0..<11 {
            let phase = rng.unit() * 40
            let x0 = CGFloat(rng.unit()) * w
            let speed = 22.0 + rng.unit() * 18
            let drift = 14.0 + rng.unit() * 16
            let tone = tones[k % tones.count]
            let cycle = Double(h) + 60
            let yy = (time * speed + phase * 30).truncatingRemainder(dividingBy: cycle) - 30
            let xx = Double(x0) + sin(time * 1.6 + phase) * drift + time * 6
            let x = CGFloat(xx.truncatingRemainder(dividingBy: Double(w) + 40)) - 20
            let y = CGFloat(yy)
            let spin = time * 2.2 + phase
            let s = CGFloat(3.5 + rng.unit() * 3)
            var leaf = Path()
            leaf.move(to: CGPoint(x: 0, y: -s))
            leaf.addQuadCurve(to: CGPoint(x: 0, y: s), control: CGPoint(x: s * 1.1, y: 0))
            leaf.addQuadCurve(to: CGPoint(x: 0, y: -s), control: CGPoint(x: -s * 1.1, y: 0))
            let transform = CGAffineTransform(translationX: x, y: y).rotated(by: CGFloat(spin))
            let alpha = 0.35 + tone_light_alpha()
            ctx.fill(leaf.applying(transform), with: .color(tone.opacity(alpha)))
            ctx.stroke(leaf.applying(transform), with: .color(Color(red: 0.25, green: 0.14, blue: 0.06).opacity(alpha * 0.7)), lineWidth: 0.6)
        }
    }

    func tone_light_alpha() -> Double { min(0.55, tone.light * 0.55) }

    mutating func drawSnow() {
        var rng = Furrow(0x5A0)
        for _ in 0..<70 {
            let phase = rng.unit() * 60
            let x0 = CGFloat(rng.unit()) * w
            let speed = 10.0 + rng.unit() * 10
            let cycle = Double(h) + 20
            let y = CGFloat((time * speed + phase * 20).truncatingRemainder(dividingBy: cycle)) - 10
            let x = x0 + CGFloat(sin(time * 0.9 + phase) * 6)
            let r = CGFloat(0.8 + rng.unit() * 1.4)
            ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(Color.white.opacity(0.35 + 0.4 * tone.light)))
        }
    }

    mutating func drawFrostGlitter() {
        var rng = Furrow(0xF057)
        let dark = 1 - tone.light / 0.42
        for k in 0..<64 {
            let x = CGFloat(rng.unit()) * w
            let y = horizon + CGFloat(rng.unit()) * (h - horizon)
            let phase = rng.unit() * 6.28
            let rate = 1.6 + rng.unit() * 2.4
            let tw = pow(max(0, sin(time * rate + phase)), 7)
            guard tw > 0.03 else { continue }
            let s = CGFloat(1.2 + tw * 3.2)
            let alpha = (0.25 + 0.7 * tw) * (0.5 + 0.5 * dark)
            var star = Path()
            star.move(to: CGPoint(x: x - s, y: y))
            star.addLine(to: CGPoint(x: x + s, y: y))
            star.move(to: CGPoint(x: x, y: y - s))
            star.addLine(to: CGPoint(x: x, y: y + s))
            ctx.stroke(star, with: .color(Color(red: 0.90, green: 0.95, blue: 1.0).opacity(alpha)), lineWidth: 0.8)
            if k % 3 == 0 {
                ctx.fill(Path(ellipseIn: CGRect(x: x - s * 0.9, y: y - s * 0.9, width: s * 1.8, height: s * 1.8)), with: .color(Color(red: 0.90, green: 0.95, blue: 1.0).opacity(alpha * 0.25)))
            }
        }
    }

    mutating func drawSunMotes() {
        var rng = Furrow(0x3E7)
        for _ in 0..<14 {
            let phase = rng.unit() * 6.28
            let x0 = CGFloat(rng.unit()) * w
            let y0 = horizon * CGFloat(0.4 + rng.unit() * 0.5)
            let x = x0 + CGFloat(sin(time * 0.5 + phase) * 18)
            let y = y0 + CGFloat(cos(time * 0.37 + phase * 1.3) * 9)
            let tw = 0.5 + 0.5 * sin(time * 1.1 + phase)
            let r = CGFloat(0.8 + tw * 1.2)
            ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(Color(red: 1.0, green: 0.95, blue: 0.75).opacity(0.18 + 0.3 * tw)))
        }
    }
}

struct SymptomPainter {
    var ctx: GraphicsContext
    let symptom: Symptom
    let rect: CGRect
    let time: Double
    let seed: UInt64

    mutating func draw() {
        var rng = Furrow(seed)
        let w = rect.width, h = rect.height
        let paper = Color(red: 0.95, green: 0.92, blue: 0.86)
        let rim = Color(red: 0.36, green: 0.27, blue: 0.18)
        switch symptom {
        case .holes:
            for _ in 0..<6 {
                let x = rect.minX + w * CGFloat(0.2 + rng.unit() * 0.6), y = rect.minY + h * CGFloat(0.15 + rng.unit() * 0.5)
                let r = w * CGFloat(0.03 + rng.unit() * 0.04)
                ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(paper))
                ctx.stroke(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(rim.opacity(0.8)), lineWidth: 0.8)
            }
        case .curl:
            for k in 0..<7 {
                let x = rect.minX + w * CGFloat(0.42 + Double(k % 3) * 0.06 + rng.unit() * 0.04), y = rect.minY + h * CGFloat(0.12 + Double(k) * 0.05)
                let r = w * 0.022
                ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r * 0.8, width: r * 2, height: r * 1.6)), with: .color(Color(red: 0.16, green: 0.24, blue: 0.10)))
            }
            var curl = Path()
            curl.move(to: CGPoint(x: rect.midX - w * 0.1, y: rect.minY + h * 0.14))
            curl.addQuadCurve(to: CGPoint(x: rect.midX + w * 0.05, y: rect.minY + h * 0.08), control: CGPoint(x: rect.midX + w * 0.12, y: rect.minY + h * 0.2))
            ctx.stroke(curl, with: .color(Color(red: 0.36, green: 0.52, blue: 0.24)), lineWidth: max(1, w * 0.03))
        case .pale:
            for k in 0..<4 {
                var path = Path()
                let x0 = rect.minX + w * CGFloat(0.25 + Double(k) * 0.14), y0 = rect.minY + h * CGFloat(0.2 + rng.unit() * 0.3)
                path.move(to: CGPoint(x: x0, y: y0))
                path.addCurve(to: CGPoint(x: x0 + w * 0.12, y: y0 + h * 0.2), control1: CGPoint(x: x0 + w * 0.12, y: y0 - h * 0.05), control2: CGPoint(x: x0 - w * 0.05, y: y0 + h * 0.18))
                ctx.stroke(path, with: .color(Color(red: 0.92, green: 0.88, blue: 0.70).opacity(0.95)), style: StrokeStyle(lineWidth: max(1.5, w * 0.035), lineCap: .round))
            }
        case .yellow:
            ctx.fill(Path(ellipseIn: CGRect(x: rect.minX + w * 0.1, y: rect.minY + h * 0.4, width: w * 0.8, height: h * 0.5)),
                     with: .radialGradient(Gradient(colors: [Color(red: 0.90, green: 0.80, blue: 0.30).opacity(0.55), Color.clear]), center: CGPoint(x: rect.midX, y: rect.minY + h * 0.65), startRadius: 0, endRadius: w * 0.45))
        case .spots:
            for _ in 0..<7 {
                let x = rect.minX + w * CGFloat(0.2 + rng.unit() * 0.6), y = rect.minY + h * CGFloat(0.12 + rng.unit() * 0.55)
                let r = w * CGFloat(0.025 + rng.unit() * 0.03)
                ctx.fill(Path(ellipseIn: CGRect(x: x - r * 1.5, y: y - r * 1.5, width: r * 3, height: r * 3)), with: .color(Color(red: 0.88, green: 0.78, blue: 0.40).opacity(0.5)))
                ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(Color(red: 0.40, green: 0.24, blue: 0.10)))
            }
        case .powder:
            for _ in 0..<40 {
                let x = rect.minX + w * CGFloat(0.15 + rng.unit() * 0.7), y = rect.minY + h * CGFloat(0.1 + rng.unit() * 0.6)
                let r = w * CGFloat(0.008 + rng.unit() * 0.012)
                ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(Color.white.opacity(0.85)))
            }
        case .wilt:
            for k in 0..<3 {
                var droop = Path()
                let x0 = rect.midX + w * CGFloat(Double(k - 1) * 0.16)
                droop.move(to: CGPoint(x: x0, y: rect.minY + h * 0.3))
                droop.addQuadCurve(to: CGPoint(x: x0 + w * CGFloat(Double(k - 1) * 0.2 + 0.05), y: rect.minY + h * 0.72), control: CGPoint(x: x0 + w * CGFloat(Double(k - 1) * 0.25), y: rect.minY + h * 0.35))
                ctx.stroke(droop, with: .color(Color(red: 0.55, green: 0.55, blue: 0.30).opacity(0.9)), style: StrokeStyle(lineWidth: max(1.5, w * 0.05), lineCap: .round))
            }
        case .stalk:
            var stalk = Path()
            stalk.move(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.5))
            stalk.addLine(to: CGPoint(x: rect.midX + w * 0.04, y: rect.minY - h * 0.05))
            ctx.stroke(stalk, with: .color(Color(red: 0.55, green: 0.68, blue: 0.36)), lineWidth: max(1.5, w * 0.04))
            for k in 0..<5 {
                let a = Double(k) / 5 * 6.28
                let x = rect.midX + w * 0.04 + CGFloat(cos(a)) * w * 0.05, y = rect.minY - h * 0.05 + CGFloat(sin(a)) * w * 0.05
                ctx.fill(Path(ellipseIn: CGRect(x: x - w * 0.02, y: y - w * 0.02, width: w * 0.04, height: w * 0.04)), with: .color(Color(red: 0.93, green: 0.78, blue: 0.30)))
            }
        case .rot:
            let r = w * 0.12
            ctx.fill(Path(ellipseIn: CGRect(x: rect.midX - r + w * 0.08, y: rect.minY + h * 0.5 - r, width: r * 2, height: r * 1.5)), with: .color(Color(red: 0.16, green: 0.12, blue: 0.08)))
            ctx.fill(Path(ellipseIn: CGRect(x: rect.midX - r * 0.6 + w * 0.08, y: rect.minY + h * 0.5 - r * 0.6, width: r * 1.2, height: r * 0.8)), with: .color(Color(red: 0.32, green: 0.22, blue: 0.12)))
        case .split:
            var crack = Path()
            crack.move(to: CGPoint(x: rect.midX - w * 0.02, y: rect.minY + h * 0.45))
            crack.addLine(to: CGPoint(x: rect.midX + w * 0.03, y: rect.minY + h * 0.6))
            crack.addLine(to: CGPoint(x: rect.midX - w * 0.01, y: rect.minY + h * 0.78))
            ctx.stroke(crack, with: .color(Color(red: 0.95, green: 0.90, blue: 0.75)), style: StrokeStyle(lineWidth: max(2, w * 0.05), lineCap: .round, lineJoin: .round))
            ctx.stroke(crack, with: .color(Color(red: 0.36, green: 0.2, blue: 0.08)), lineWidth: max(0.8, w * 0.015))
        case .lifted:
            for k in 0..<5 {
                var root = Path()
                let x0 = rect.midX + w * CGFloat(Double(k - 2) * 0.05)
                root.move(to: CGPoint(x: x0, y: rect.maxY - h * 0.2))
                root.addLine(to: CGPoint(x: x0 + w * CGFloat(Double(k - 2) * 0.06), y: rect.maxY - h * 0.02))
                ctx.stroke(root, with: .color(Color(red: 0.88, green: 0.82, blue: 0.64)), lineWidth: max(1, w * 0.02))
            }
            for _ in 0..<10 {
                let x = rect.minX + w * CGFloat(rng.unit()), y = rect.maxY - h * CGFloat(0.05 + rng.unit() * 0.25)
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)), with: .color(Color.white.opacity(0.7)))
            }
        case .pulled:
            var lay = Path()
            lay.move(to: CGPoint(x: rect.minX + w * 0.2, y: rect.maxY - h * 0.22))
            lay.addLine(to: CGPoint(x: rect.minX + w * 0.75, y: rect.maxY - h * 0.35))
            ctx.stroke(lay, with: .color(Color(red: 0.55, green: 0.68, blue: 0.36)), style: StrokeStyle(lineWidth: max(1.5, w * 0.04), lineCap: .round))
            for k in 0..<3 {
                var print = Path()
                let x0 = rect.minX + w * CGFloat(0.25 + Double(k) * 0.22), y0 = rect.maxY - h * 0.08
                for j in 0..<3 {
                    print.move(to: CGPoint(x: x0, y: y0))
                    print.addLine(to: CGPoint(x: x0 + w * CGFloat(Double(j - 1) * 0.04), y: y0 - h * 0.08))
                }
                ctx.stroke(print, with: .color(Color(red: 0.2, green: 0.15, blue: 0.1).opacity(0.8)), lineWidth: 1)
            }
        case .tunnel:
            for k in 0..<3 {
                var t = Path()
                let x0 = rect.midX + w * CGFloat(Double(k - 1) * 0.06)
                t.move(to: CGPoint(x: x0, y: rect.minY + h * 0.55))
                t.addQuadCurve(to: CGPoint(x: x0 + w * 0.03, y: rect.maxY - h * 0.1), control: CGPoint(x: x0 - w * 0.06, y: rect.minY + h * 0.75))
                ctx.stroke(t, with: .color(Color(red: 0.42, green: 0.22, blue: 0.08)), style: StrokeStyle(lineWidth: max(1.2, w * 0.03), lineCap: .round))
            }
        case .stripped:
            for k in 0..<4 {
                var stub = Path()
                let y = rect.minY + h * CGFloat(0.2 + Double(k) * 0.12)
                stub.move(to: CGPoint(x: rect.midX, y: y))
                stub.addLine(to: CGPoint(x: rect.midX + w * CGFloat(k % 2 == 0 ? -0.16 : 0.16), y: y - h * 0.04))
                ctx.stroke(stub, with: .color(Color(red: 0.36, green: 0.42, blue: 0.22)), style: StrokeStyle(lineWidth: max(1.2, w * 0.03), lineCap: .round))
            }
            for _ in 0..<4 {
                let x = rect.minX + w * CGFloat(0.3 + rng.unit() * 0.4), y = rect.maxY - h * CGFloat(0.05 + rng.unit() * 0.15)
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: w * 0.03, height: w * 0.02)), with: .color(Color(red: 0.12, green: 0.1, blue: 0.08)))
            }
        }
        let pulse = 0.5 + 0.5 * sin(time * 2.4)
        let marker = CGRect(x: rect.maxX - w * 0.2, y: rect.minY - h * 0.02, width: w * 0.16, height: w * 0.16)
        var tri = Path()
        tri.move(to: CGPoint(x: marker.midX, y: marker.minY))
        tri.addLine(to: CGPoint(x: marker.maxX, y: marker.maxY))
        tri.addLine(to: CGPoint(x: marker.minX, y: marker.maxY))
        tri.closeSubpath()
        ctx.fill(tri, with: .color(Loam.terracotta.opacity(0.55 + 0.45 * pulse)))
        ctx.stroke(tri, with: .color(Loam.card), lineWidth: 1)
        ctx.fill(Path(CGRect(x: marker.midX - 0.8, y: marker.minY + marker.height * 0.35, width: 1.6, height: marker.height * 0.32)), with: .color(Loam.card))
        ctx.fill(Path(ellipseIn: CGRect(x: marker.midX - 1, y: marker.maxY - marker.height * 0.22, width: 2, height: 2)), with: .color(Loam.card))
    }
}
