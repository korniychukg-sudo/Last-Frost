import SwiftUI

struct SkyTone {
    var top: Color
    var horizon: Color
    var light: Double
    var warm: Double
    var lamp: Double
}

enum SkyLight {
    static let frames: [(Double, SkyTone)] = [
        (0, SkyTone(top: Color(red: 0.06, green: 0.08, blue: 0.16), horizon: Color(red: 0.12, green: 0.14, blue: 0.24), light: 0.08, warm: 0.0, lamp: 1.0)),
        (5, SkyTone(top: Color(red: 0.16, green: 0.18, blue: 0.30), horizon: Color(red: 0.42, green: 0.36, blue: 0.40), light: 0.22, warm: 0.3, lamp: 0.7)),
        (6.5, SkyTone(top: Color(red: 0.55, green: 0.62, blue: 0.74), horizon: Color(red: 0.94, green: 0.72, blue: 0.52), light: 0.55, warm: 0.8, lamp: 0.2)),
        (9, SkyTone(top: Color(red: 0.52, green: 0.68, blue: 0.84), horizon: Color(red: 0.80, green: 0.86, blue: 0.90), light: 0.9, warm: 0.3, lamp: 0.0)),
        (13, SkyTone(top: Color(red: 0.42, green: 0.62, blue: 0.85), horizon: Color(red: 0.78, green: 0.86, blue: 0.92), light: 1.0, warm: 0.1, lamp: 0.0)),
        (17, SkyTone(top: Color(red: 0.50, green: 0.66, blue: 0.82), horizon: Color(red: 0.90, green: 0.84, blue: 0.72), light: 0.85, warm: 0.4, lamp: 0.0)),
        (19.5, SkyTone(top: Color(red: 0.40, green: 0.38, blue: 0.52), horizon: Color(red: 0.92, green: 0.58, blue: 0.36), light: 0.45, warm: 0.9, lamp: 0.4)),
        (21.5, SkyTone(top: Color(red: 0.10, green: 0.12, blue: 0.24), horizon: Color(red: 0.26, green: 0.22, blue: 0.34), light: 0.16, warm: 0.2, lamp: 1.0))
    ]

    static func at(_ hour: Double) -> SkyTone {
        let h = hour.truncatingRemainder(dividingBy: 24)
        var lower = frames[frames.count - 1]
        var upper = frames[0]
        var lowerHour = lower.0 - 24
        var upperHour = upper.0
        for i in 0..<frames.count where frames[i].0 <= h {
            lower = frames[i]
            lowerHour = frames[i].0
            if i + 1 < frames.count { upper = frames[i + 1]; upperHour = frames[i + 1].0 }
            else { upper = frames[0]; upperHour = 24 + frames[0].0 }
        }
        let span = max(0.001, upperHour - lowerHour)
        let t = (h - lowerHour) / span
        let a = lower.1, b = upper.1
        return SkyTone(top: Color.blend(a.top, b.top, t), horizon: Color.blend(a.horizon, b.horizon, t),
                       light: a.light + (b.light - a.light) * t, warm: a.warm + (b.warm - a.warm) * t,
                       lamp: a.lamp + (b.lamp - a.lamp) * t)
    }

    static func hourWords(_ hour: Double, season: Int) -> String {
        let winter = season == 0
        switch Int(hour) {
        case 0..<5: return winter ? "Deep night, and the beds are under frost" : "Night on the plot; the lamp in the shed is the only light"
        case 5..<8: return winter ? "First grey light on frozen ground" : "First light, and the soil still cold to the hand"
        case 8..<11: return winter ? "A low sun that never clears the hedge" : "The morning sun is on the beds and the frames are open"
        case 11..<14: return winter ? "Noon, and the frost has gone from the sunny side only" : "Full sun on the plot; the best hour to see what has come up"
        case 14..<17: return winter ? "The light going already" : "The shed throws its shadow across the near beds"
        case 17..<20: return winter ? "Dark by five, and the frames shut" : "Low sun along the rows; time to water at the root"
        case 20..<23: return winter ? "The lamp lit in the shed against the cold" : "Dusk, and the lamp lit in the shed"
        default: return "Late, and the plot asleep"
        }
    }
}

struct PlotScene: View {
    var hour: Double
    var day: Int
    var beds: [Bed]
    var dates: FrostDates
    var rain: Double
    var backdrop: String? = nil

    var body: some View {
        Canvas { ctx, size in
            var drawer = SceneDrawer(ctx: ctx, size: size, hour: hour, day: day, beds: beds, dates: dates, rain: rain, backdrop: backdrop)
            drawer.draw()
        }
    }
}

struct SceneDrawer {
    var ctx: GraphicsContext
    let size: CGSize
    let hour: Double
    let day: Int
    let beds: [Bed]
    let dates: FrostDates
    let rain: Double
    let backdrop: String?

    var w: CGFloat { size.width }
    var h: CGFloat { size.height }
    var tone: SkyTone { SkyLight.at(hour) }
    var season: Int { Almanac.season(of: day) }
    var weather: Weather { Weather.at(day: day, dates: dates) }
    var horizon: CGFloat { h * 0.46 }

    var deepWinter: Bool {
        let fy = FrostYear(dates, year: Almanac.year(of: day))
        return !dates.frostFree && (day < fy.lastFrost - 21 || day > fy.firstFrost + 21)
    }

    var groundTone: Color {
        let light = tone.light
        let base: Color
        switch season {
        case 1: base = Color(red: 0.50, green: 0.62, blue: 0.34)
        case 2: base = Color(red: 0.42, green: 0.55, blue: 0.29)
        case 3: base = Color(red: 0.62, green: 0.54, blue: 0.32)
        default: base = Color(red: 0.60, green: 0.57, blue: 0.48)
        }
        return Color.blend(Color(red: 0.08, green: 0.09, blue: 0.14), base, 0.25 + light * 0.75)
    }

    var hedgeTone: Color {
        let base: Color
        switch season {
        case 1: base = Color(red: 0.34, green: 0.50, blue: 0.28)
        case 2: base = Color(red: 0.24, green: 0.40, blue: 0.22)
        case 3: base = Color(red: 0.56, green: 0.42, blue: 0.22)
        default: base = Color(red: 0.42, green: 0.38, blue: 0.32)
        }
        return Color.blend(Color(red: 0.06, green: 0.07, blue: 0.12), base, 0.2 + tone.light * 0.8)
    }

    func lit(_ c: Color, _ amount: Double = 1) -> Color {
        Color.blend(Color(red: 0.07, green: 0.08, blue: 0.14), c, 0.22 + tone.light * 0.78 * amount)
    }

    mutating func draw() {
        if let plate = backdrop, let image = Plates.load(plate) {
            let iw = image.size.width, ih = image.size.height
            let scale = max(w / iw, h / ih)
            let dw = iw * scale, dh = ih * scale
            ctx.draw(Image(uiImage: image), in: CGRect(x: (w - dw) / 2, y: (h - dh) / 2, width: dw, height: dh))
        } else {
            drawSky()
            drawHedge()
            drawShed()
            drawColdFrame()
            drawGround()
        }
        drawBeds()
        drawWeather()
        drawNight()
    }

    mutating func drawSky() {
        ctx.fill(Path(CGRect(x: 0, y: 0, width: w, height: horizon + 2)),
                 with: .linearGradient(Gradient(colors: [tone.top, tone.horizon]),
                                       startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: horizon)))
        let sunT = (hour - 5.5) / 14.5
        if sunT > -0.05 && sunT < 1.05 {
            let sx = w * CGFloat(0.08 + sunT * 0.84)
            let sy = horizon - CGFloat(sin(max(0, min(1, sunT)) * Double.pi)) * h * 0.36
            let r = w * 0.05
            ctx.fill(Path(ellipseIn: CGRect(x: sx - r * 3, y: sy - r * 3, width: r * 6, height: r * 6)),
                     with: .radialGradient(Gradient(colors: [Color(red: 1.0, green: 0.92, blue: 0.70).opacity(0.45 * tone.light), Color.clear]),
                                           center: CGPoint(x: sx, y: sy), startRadius: 0, endRadius: r * 3))
            ctx.fill(Path(ellipseIn: CGRect(x: sx - r, y: sy - r, width: r * 2, height: r * 2)),
                     with: .color(Color.blend(Color(red: 1.0, green: 0.75, blue: 0.45), Color(red: 1.0, green: 0.97, blue: 0.88), 1 - tone.warm)))
        }
        if tone.light < 0.35 {
            var rng = Furrow(0xA11CE)
            let alpha = (0.35 - tone.light) / 0.35
            for _ in 0..<42 {
                let x = CGFloat(rng.unit()) * w
                let y = CGFloat(rng.unit()) * horizon * 0.85
                let r = CGFloat(0.5 + rng.unit() * 1.1)
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)), with: .color(Color.white.opacity(0.35 * alpha + 0.4 * alpha * rng.unit())))
            }
            let moonT = ((hour + 4).truncatingRemainder(dividingBy: 24)) / 10
            if moonT >= 0 && moonT <= 1 {
                let mx = w * CGFloat(0.9 - moonT * 0.8)
                let my = horizon - CGFloat(sin(moonT * Double.pi)) * h * 0.3
                let r = w * 0.028
                ctx.fill(Path(ellipseIn: CGRect(x: mx - r, y: my - r, width: r * 2, height: r * 2)), with: .color(Color(red: 0.94, green: 0.93, blue: 0.86).opacity(alpha)))
                ctx.fill(Path(ellipseIn: CGRect(x: mx - r * 0.5, y: my - r * 1.1, width: r * 2, height: r * 2)), with: .color(tone.top.opacity(alpha * 0.9)))
            }
        }
        if weather == .cloud || weather == .rain {
            var rng = Furrow(Almanac.seed(day) ^ 0xC10D)
            let cloudTone = Color.blend(Color(red: 0.16, green: 0.17, blue: 0.22), Color(red: 0.80, green: 0.80, blue: 0.82), tone.light)
            for k in 0..<5 {
                let cx = w * CGFloat(0.1 + Double(k) * 0.2 + rng.unit() * 0.1)
                let cy = h * CGFloat(0.06 + rng.unit() * 0.16)
                let cw = w * CGFloat(0.22 + rng.unit() * 0.16)
                let ch = h * CGFloat(0.07 + rng.unit() * 0.04)
                ctx.fill(Path(ellipseIn: CGRect(x: cx - cw / 2, y: cy - ch / 2, width: cw, height: ch)), with: .color(cloudTone.opacity(weather == .rain ? 0.85 : 0.7)))
                ctx.fill(Path(ellipseIn: CGRect(x: cx - cw * 0.25, y: cy - ch * 0.9, width: cw * 0.5, height: ch * 1.2)), with: .color(cloudTone.opacity(weather == .rain ? 0.85 : 0.7)))
            }
        }
    }

    mutating func drawHedge() {
        var rng = Furrow(0x4ED6E)
        var path = Path()
        path.move(to: CGPoint(x: 0, y: horizon))
        var x: CGFloat = 0
        while x < w {
            let bump = h * CGFloat(0.05 + rng.unit() * 0.06)
            let step = w * CGFloat(0.05 + rng.unit() * 0.05)
            path.addQuadCurve(to: CGPoint(x: x + step, y: horizon - h * 0.05), control: CGPoint(x: x + step / 2, y: horizon - bump - h * 0.04))
            x += step
        }
        path.addLine(to: CGPoint(x: w, y: horizon))
        path.closeSubpath()
        ctx.fill(path, with: .color(hedgeTone))
        if season == 0 && detailFrost {
            var frost = Path()
            frost.addRect(CGRect(x: 0, y: horizon - h * 0.10, width: w, height: h * 0.10))
            ctx.fill(frost, with: .color(Color.white.opacity(0.08)))
        }
        let fenceTone = lit(Color(red: 0.50, green: 0.42, blue: 0.30))
        var rails = Path()
        rails.move(to: CGPoint(x: w * 0.30, y: horizon - h * 0.028))
        rails.addLine(to: CGPoint(x: w * 0.68, y: horizon - h * 0.028))
        rails.move(to: CGPoint(x: w * 0.30, y: horizon - h * 0.006))
        rails.addLine(to: CGPoint(x: w * 0.68, y: horizon - h * 0.006))
        ctx.stroke(rails, with: .color(fenceTone), lineWidth: max(1, h * 0.006))
        for k in 0..<7 {
            let x = w * (0.30 + CGFloat(k) * 0.0633)
            ctx.fill(Path(CGRect(x: x - h * 0.005, y: horizon - h * 0.05, width: h * 0.01, height: h * 0.055)), with: .color(fenceTone))
        }
    }

    var detailFrost: Bool { weather == .frost || deepWinter }

    mutating func drawShed() {
        let x0 = w * 0.05, x1 = w * 0.28
        let eave = h * 0.27, peak = h * 0.15, bottom = horizon + h * 0.01
        let wall = lit(Color(red: 0.42, green: 0.32, blue: 0.22))
        let wallShade = lit(Color(red: 0.30, green: 0.22, blue: 0.15))
        ctx.fill(Path(CGRect(x: x0, y: eave, width: x1 - x0, height: bottom - eave)), with: .color(wall))
        ctx.fill(Path(CGRect(x: x0 + (x1 - x0) * 0.66, y: eave, width: (x1 - x0) * 0.34, height: bottom - eave)), with: .color(wallShade))
        for k in 0..<6 {
            let y = eave + (bottom - eave) * CGFloat(k) / 6
            var plank = Path()
            plank.move(to: CGPoint(x: x0, y: y))
            plank.addLine(to: CGPoint(x: x1, y: y))
            ctx.stroke(plank, with: .color(Color.black.opacity(0.12)), lineWidth: 1)
        }
        var roof = Path()
        roof.move(to: CGPoint(x: x0 - w * 0.02, y: eave))
        roof.addLine(to: CGPoint(x: (x0 + x1) / 2, y: peak))
        roof.addLine(to: CGPoint(x: x1 + w * 0.02, y: eave))
        roof.closeSubpath()
        let roofTone = detailFrost && season == 0 ? Color.blend(lit(Color(red: 0.34, green: 0.30, blue: 0.28)), Color.white, 0.55)
            : lit(Color(red: 0.34, green: 0.30, blue: 0.28))
        ctx.fill(roof, with: .color(roofTone))
        ctx.stroke(roof, with: .color(Color.black.opacity(0.25)), lineWidth: 1)
        let doorRect = CGRect(x: x0 + (x1 - x0) * 0.12, y: eave + (bottom - eave) * 0.30, width: (x1 - x0) * 0.22, height: (bottom - eave) * 0.70)
        ctx.fill(Path(doorRect), with: .color(lit(Color(red: 0.22, green: 0.16, blue: 0.11))))
        let winRect = CGRect(x: x0 + (x1 - x0) * 0.44, y: eave + (bottom - eave) * 0.28, width: (x1 - x0) * 0.18, height: (bottom - eave) * 0.26)
        let lampGlow = tone.lamp
        let glass = Color.blend(Color.blend(tone.top, Color(red: 0.55, green: 0.62, blue: 0.68), 0.5),
                                Color(red: 1.0, green: 0.80, blue: 0.45), lampGlow)
        ctx.fill(Path(winRect), with: .color(glass))
        var bars = Path()
        bars.move(to: CGPoint(x: winRect.midX, y: winRect.minY))
        bars.addLine(to: CGPoint(x: winRect.midX, y: winRect.maxY))
        bars.move(to: CGPoint(x: winRect.minX, y: winRect.midY))
        bars.addLine(to: CGPoint(x: winRect.maxX, y: winRect.midY))
        ctx.stroke(bars, with: .color(wallShade), lineWidth: 1.2)
        if lampGlow > 0.05 {
            ctx.fill(Path(ellipseIn: winRect.insetBy(dx: -winRect.width * 1.4, dy: -winRect.height * 1.4)),
                     with: .radialGradient(Gradient(colors: [Color(red: 1.0, green: 0.78, blue: 0.40).opacity(0.35 * lampGlow), Color.clear]),
                                           center: CGPoint(x: winRect.midX, y: winRect.midY), startRadius: 0, endRadius: winRect.width * 2.2))
        }
        var tools = Path()
        tools.move(to: CGPoint(x: x1 + w * 0.01, y: bottom))
        tools.addLine(to: CGPoint(x: x1 + w * 0.03, y: eave + (bottom - eave) * 0.35))
        tools.move(to: CGPoint(x: x1 + w * 0.025, y: bottom))
        tools.addLine(to: CGPoint(x: x1 + w * 0.048, y: eave + (bottom - eave) * 0.30))
        ctx.stroke(tools, with: .color(lit(Color(red: 0.45, green: 0.36, blue: 0.26))), style: StrokeStyle(lineWidth: max(1, w * 0.006), lineCap: .round))
    }

    mutating func drawColdFrame() {
        let x0 = w * 0.70, x1 = w * 0.94
        let back = horizon - h * 0.075, front = horizon - h * 0.03, base = horizon + h * 0.012
        let frame = lit(Color(red: 0.55, green: 0.45, blue: 0.30))
        var side = Path()
        side.move(to: CGPoint(x: x0, y: base))
        side.addLine(to: CGPoint(x: x0, y: back))
        side.addLine(to: CGPoint(x: x1, y: front))
        side.addLine(to: CGPoint(x: x1, y: base))
        side.closeSubpath()
        ctx.fill(side, with: .color(frame))
        var glass = Path()
        glass.move(to: CGPoint(x: x0 + w * 0.006, y: back + h * 0.004))
        glass.addLine(to: CGPoint(x: x1 - w * 0.006, y: front + h * 0.002))
        glass.addLine(to: CGPoint(x: x1 - w * 0.006, y: front + h * 0.018))
        glass.addLine(to: CGPoint(x: x0 + w * 0.006, y: back + h * 0.024))
        glass.closeSubpath()
        let reflect = Color.blend(tone.top, Color.white, 0.35 * tone.light)
        ctx.fill(glass, with: .color(reflect.opacity(0.8)))
        var glint = Path()
        glint.move(to: CGPoint(x: x0 + w * 0.05, y: back + h * 0.006))
        glint.addLine(to: CGPoint(x: x0 + w * 0.09, y: back + h * 0.02))
        ctx.stroke(glint, with: .color(Color.white.opacity(0.5 * tone.light)), lineWidth: max(1, w * 0.004))
        var bar = Path()
        bar.move(to: CGPoint(x: (x0 + x1) / 2, y: (back + front) / 2 + h * 0.002))
        bar.addLine(to: CGPoint(x: (x0 + x1) / 2, y: (back + front) / 2 + h * 0.022))
        ctx.stroke(bar, with: .color(frame), lineWidth: max(1, w * 0.005))
    }

    mutating func drawGround() {
        ctx.fill(Path(CGRect(x: 0, y: horizon, width: w, height: h - horizon)), with: .color(groundTone))
        let pathTone = lit(Color(red: 0.72, green: 0.64, blue: 0.46))
        ctx.fill(Path(CGRect(x: 0, y: horizon + h * 0.02, width: w, height: h * 0.025)), with: .color(pathTone.opacity(0.55)))
        var rng = Furrow(0x6A55)
        let tuft = Color.blend(groundTone, Color(red: 0.2, green: 0.3, blue: 0.14), season == 0 ? 0.15 : 0.35)
        for _ in 0..<70 {
            let x = CGFloat(rng.unit()) * w
            let y = horizon + CGFloat(rng.unit()) * (h - horizon)
            var blade = Path()
            blade.move(to: CGPoint(x: x, y: y))
            blade.addLine(to: CGPoint(x: x + CGFloat(rng.unit() - 0.5) * 3, y: y - 2 - CGFloat(rng.unit()) * 3))
            ctx.stroke(blade, with: .color(tuft.opacity(0.7)), lineWidth: 0.8)
        }
        let compostX = w * 0.90, compostY = h * 0.60
        let boards = lit(Color(red: 0.36, green: 0.28, blue: 0.19))
        ctx.fill(Path(CGRect(x: compostX - w * 0.05, y: compostY, width: w * 0.10, height: h * 0.10)), with: .color(boards))
        ctx.fill(Path(ellipseIn: CGRect(x: compostX - w * 0.045, y: compostY - h * 0.02, width: w * 0.09, height: h * 0.05)), with: .color(lit(Color(red: 0.26, green: 0.20, blue: 0.13))))
        for k in 0..<3 {
            var slat = Path()
            let y = compostY + h * 0.03 * CGFloat(k + 1)
            slat.move(to: CGPoint(x: compostX - w * 0.05, y: y))
            slat.addLine(to: CGPoint(x: compostX + w * 0.05, y: y))
            ctx.stroke(slat, with: .color(Color.black.opacity(0.18)), lineWidth: 1)
        }
    }

    mutating func drawBeds() {
        let n = beds.count
        let region = CGRect(x: w * 0.06, y: h * 0.515, width: w * (n > 0 ? 0.76 : 0.80), height: h * 0.44)
        guard n > 0 else {
            drawEmptyBeds(region)
            return
        }
        let cols = n <= 2 ? n : (n <= 6 ? 3 : 4)
        let rows = Int(ceil(Double(n) / Double(cols)))
        let gapX = w * 0.025, gapY = h * 0.03
        let bw = (region.width - gapX * CGFloat(cols - 1)) / CGFloat(cols)
        let bh = min(h * 0.16, (region.height - gapY * CGFloat(rows - 1)) / CGFloat(rows))
        for (k, bed) in beds.enumerated() {
            let c = k % cols, r = k / cols
            let rect = CGRect(x: region.minX + CGFloat(c) * (bw + gapX), y: region.minY + CGFloat(r) * (bh + gapY), width: bw, height: bh)
            drawBed(bed, in: rect)
        }
    }

    mutating func drawEmptyBeds(_ region: CGRect) {
        let bw = region.width * 0.42, bh = h * 0.14
        for k in 0..<2 {
            let rect = CGRect(x: region.minX + CGFloat(k) * (bw + w * 0.05), y: region.minY + h * 0.03, width: bw, height: bh)
            let soil = lit(Loam.soil)
            ctx.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(soil))
            ctx.stroke(Path(roundedRect: rect, cornerRadius: 2), with: .color(lit(Color(red: 0.55, green: 0.44, blue: 0.30))), lineWidth: max(1.5, w * 0.008))
            sprinkle(rect)
        }
    }

    func sprinkle(_ rect: CGRect) {
        var rng = Furrow(UInt64(bitPattern: Int64(rect.minX * 7 + rect.minY * 13)) ^ 0x51)
        for _ in 0..<Int(rect.width * rect.height / 90) {
            let x = rect.minX + CGFloat(rng.unit()) * rect.width
            let y = rect.minY + CGFloat(rng.unit()) * rect.height
            ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.2, height: 1.2)), with: .color(Color.black.opacity(0.18)))
        }
        if detailFrost {
            for _ in 0..<Int(rect.width * rect.height / 60) {
                let x = rect.minX + CGFloat(rng.unit()) * rect.width
                let y = rect.minY + CGFloat(rng.unit()) * rect.height
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.4, height: 1.4)), with: .color(Color.white.opacity(0.55)))
            }
        }
    }

    mutating func drawBed(_ bed: Bed, in rect: CGRect) {
        let wet = weather == .rain
        let soil = lit(wet ? Loam.soilDark : Loam.soil)
        let board = lit(Color(red: 0.55, green: 0.44, blue: 0.30))
        ctx.fill(Path(roundedRect: rect.insetBy(dx: 0, dy: 0), cornerRadius: 2), with: .color(soil))
        ctx.stroke(Path(roundedRect: rect, cornerRadius: 2), with: .color(board), lineWidth: max(1.5, w * 0.008))
        sprinkle(rect.insetBy(dx: 2, dy: 2))
        let cellW = rect.width / CGFloat(bed.cols)
        let cellH = rect.height / CGFloat(bed.rows)
        for (i, cell) in bed.cells.enumerated() {
            let c = i % bed.cols, r = i / bed.cols
            let cr = CGRect(x: rect.minX + CGFloat(c) * cellW, y: rect.minY + CGFloat(r) * cellH, width: cellW, height: cellH)
            if let p = cell.planting {
                let crop = Register.find(p.crop)
                let stage = p.stage(on: day)
                guard stage != .bare else { continue }
                let shade = stage == .spent ? 0.7 : 1.0
                var sub = ctx
                sub.opacity = 0.35 + tone.light * 0.65 * shade
                var painter = PlantPainter(sub, crop: crop, stage: stage, growth: p.growth(on: day),
                                           rect: cr.insetBy(dx: cellW * 0.08, dy: cellH * 0.05), detail: false,
                                           seed: hashOf(bed.id + "\(i)"))
                painter.draw()
            } else if cell.stake != nil {
                var stake = Path()
                stake.move(to: CGPoint(x: cr.midX, y: cr.maxY - cellH * 0.15))
                stake.addLine(to: CGPoint(x: cr.midX, y: cr.minY + cellH * 0.3))
                ctx.stroke(stake, with: .color(lit(Color(red: 0.86, green: 0.82, blue: 0.70))), lineWidth: max(1, cellW * 0.08))
            }
        }
    }

    mutating func drawWeather() {
        if weather == .rain {
            var rng = Furrow(0x8A1)
            let alpha = 0.18 + tone.light * 0.22
            for _ in 0..<70 {
                let x = CGFloat(rng.unit()) * w * 1.1 - w * 0.05
                let y0 = (CGFloat(rng.unit()) * h + CGFloat(rain) * h).truncatingRemainder(dividingBy: h)
                let len = h * CGFloat(0.03 + rng.unit() * 0.04)
                var drop = Path()
                drop.move(to: CGPoint(x: x, y: y0))
                drop.addLine(to: CGPoint(x: x - len * 0.25, y: y0 + len))
                ctx.stroke(drop, with: .color(Color(red: 0.80, green: 0.86, blue: 0.92).opacity(alpha)), lineWidth: 1)
            }
        }
    }

    mutating func drawNight() {
        let dark = max(0, 0.6 - tone.light) / 0.6
        if dark > 0.02 {
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(red: 0.05, green: 0.06, blue: 0.14).opacity(dark * 0.34)))
        }
        ctx.fill(Path(CGRect(origin: .zero, size: size)),
                 with: .radialGradient(Gradient(colors: [Color.clear, Color.black.opacity(0.18 + dark * 0.2)]),
                                       center: CGPoint(x: w * 0.5, y: h * 0.45), startRadius: min(w, h) * 0.35, endRadius: max(w, h) * 0.85))
    }
}
