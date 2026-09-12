import SwiftUI

struct PlantTones {
    var leaf: Color
    var leafDeep: Color
    var fruit: Color
    var bloom: Color
}

enum PlantPalette {
    static let leafA = Color(red: 0.36, green: 0.55, blue: 0.27)
    static let leafB = Color(red: 0.30, green: 0.48, blue: 0.24)
    static let leafBlue = Color(red: 0.42, green: 0.55, blue: 0.42)
    static let leafPale = Color(red: 0.55, green: 0.68, blue: 0.36)
    static let leafGrey = Color(red: 0.55, green: 0.61, blue: 0.47)
    static let leafDark = Color(red: 0.20, green: 0.34, blue: 0.17)
    static let deepA = Color(red: 0.18, green: 0.31, blue: 0.15)

    static func tones(for crop: Crop) -> PlantTones {
        switch crop.key {
        case "tomato": return PlantTones(leaf: leafA, leafDeep: deepA, fruit: Color(red: 0.80, green: 0.22, blue: 0.16), bloom: Color(red: 0.95, green: 0.85, blue: 0.35))
        case "pepper": return PlantTones(leaf: leafB, leafDeep: deepA, fruit: Color(red: 0.78, green: 0.30, blue: 0.14), bloom: Color(red: 0.95, green: 0.95, blue: 0.85))
        case "eggplant": return PlantTones(leaf: leafGrey, leafDeep: deepA, fruit: Color(red: 0.30, green: 0.14, blue: 0.36), bloom: Color(red: 0.62, green: 0.50, blue: 0.75))
        case "tomatillo": return PlantTones(leaf: leafPale, leafDeep: deepA, fruit: Color(red: 0.62, green: 0.72, blue: 0.36), bloom: Color(red: 0.92, green: 0.82, blue: 0.30))
        case "potato": return PlantTones(leaf: leafB, leafDeep: deepA, fruit: Color(red: 0.76, green: 0.62, blue: 0.40), bloom: Color(red: 0.90, green: 0.90, blue: 0.96))
        case "pea": return PlantTones(leaf: leafPale, leafDeep: leafB, fruit: Color(red: 0.48, green: 0.64, blue: 0.30), bloom: Color(red: 0.98, green: 0.97, blue: 0.94))
        case "bushbean", "polebean": return PlantTones(leaf: leafA, leafDeep: deepA, fruit: Color(red: 0.45, green: 0.60, blue: 0.27), bloom: Color(red: 0.96, green: 0.94, blue: 0.90))
        case "fava": return PlantTones(leaf: leafBlue, leafDeep: deepA, fruit: Color(red: 0.42, green: 0.56, blue: 0.30), bloom: Color(red: 0.96, green: 0.96, blue: 0.94))
        case "carrot": return PlantTones(leaf: leafPale, leafDeep: leafB, fruit: Color(red: 0.90, green: 0.50, blue: 0.16), bloom: .clear)
        case "radish": return PlantTones(leaf: leafA, leafDeep: leafB, fruit: Color(red: 0.80, green: 0.22, blue: 0.30), bloom: .clear)
        case "beet": return PlantTones(leaf: Color(red: 0.36, green: 0.42, blue: 0.24), leafDeep: Color(red: 0.42, green: 0.14, blue: 0.20), fruit: Color(red: 0.50, green: 0.12, blue: 0.24), bloom: .clear)
        case "parsnip": return PlantTones(leaf: leafA, leafDeep: leafB, fruit: Color(red: 0.90, green: 0.86, blue: 0.70), bloom: .clear)
        case "turnip": return PlantTones(leaf: leafA, leafDeep: leafB, fruit: Color(red: 0.86, green: 0.82, blue: 0.80), bloom: .clear)
        case "rutabaga": return PlantTones(leaf: leafBlue, leafDeep: leafB, fruit: Color(red: 0.72, green: 0.58, blue: 0.40), bloom: .clear)
        case "garlic": return PlantTones(leaf: leafBlue, leafDeep: leafB, fruit: Color(red: 0.92, green: 0.88, blue: 0.80), bloom: .clear)
        case "onion": return PlantTones(leaf: leafBlue, leafDeep: leafB, fruit: Color(red: 0.78, green: 0.58, blue: 0.34), bloom: .clear)
        case "kohlrabi": return PlantTones(leaf: leafBlue, leafDeep: leafB, fruit: Color(red: 0.62, green: 0.72, blue: 0.56), bloom: .clear)
        case "fennel": return PlantTones(leaf: leafPale, leafDeep: leafB, fruit: Color(red: 0.90, green: 0.90, blue: 0.82), bloom: Color(red: 0.92, green: 0.85, blue: 0.30))
        case "kale": return PlantTones(leaf: leafBlue, leafDeep: Color(red: 0.24, green: 0.36, blue: 0.30), fruit: .clear, bloom: .clear)
        case "chard": return PlantTones(leaf: leafA, leafDeep: deepA, fruit: Color(red: 0.80, green: 0.30, blue: 0.20), bloom: .clear)
        case "spinach": return PlantTones(leaf: leafDark, leafDeep: deepA, fruit: .clear, bloom: .clear)
        case "arugula", "mizuna": return PlantTones(leaf: leafA, leafDeep: leafB, fruit: .clear, bloom: Color(red: 0.96, green: 0.94, blue: 0.86))
        case "rhubarb": return PlantTones(leaf: leafDark, leafDeep: deepA, fruit: Color(red: 0.76, green: 0.24, blue: 0.22), bloom: .clear)
        case "lettuce": return PlantTones(leaf: leafPale, leafDeep: leafA, fruit: .clear, bloom: .clear)
        case "cabbage": return PlantTones(leaf: leafBlue, leafDeep: leafB, fruit: Color(red: 0.66, green: 0.76, blue: 0.62), bloom: .clear)
        case "broccoli": return PlantTones(leaf: leafBlue, leafDeep: leafB, fruit: Color(red: 0.24, green: 0.40, blue: 0.24), bloom: .clear)
        case "cauliflower": return PlantTones(leaf: leafBlue, leafDeep: leafB, fruit: Color(red: 0.94, green: 0.92, blue: 0.84), bloom: .clear)
        case "bokchoy": return PlantTones(leaf: leafA, leafDeep: leafB, fruit: Color(red: 0.90, green: 0.92, blue: 0.82), bloom: .clear)
        case "endive": return PlantTones(leaf: leafPale, leafDeep: leafA, fruit: Color(red: 0.92, green: 0.92, blue: 0.70), bloom: .clear)
        case "brussels": return PlantTones(leaf: leafBlue, leafDeep: leafB, fruit: Color(red: 0.44, green: 0.58, blue: 0.36), bloom: .clear)
        case "zucchini": return PlantTones(leaf: leafDark, leafDeep: deepA, fruit: Color(red: 0.24, green: 0.40, blue: 0.20), bloom: Color(red: 0.95, green: 0.72, blue: 0.20))
        case "cucumber": return PlantTones(leaf: leafA, leafDeep: deepA, fruit: Color(red: 0.30, green: 0.48, blue: 0.22), bloom: Color(red: 0.95, green: 0.82, blue: 0.25))
        case "wintersquash": return PlantTones(leaf: leafDark, leafDeep: deepA, fruit: Color(red: 0.82, green: 0.62, blue: 0.34), bloom: Color(red: 0.95, green: 0.74, blue: 0.20))
        case "pumpkin": return PlantTones(leaf: leafDark, leafDeep: deepA, fruit: Color(red: 0.86, green: 0.46, blue: 0.14), bloom: Color(red: 0.95, green: 0.74, blue: 0.20))
        case "melon": return PlantTones(leaf: leafA, leafDeep: deepA, fruit: Color(red: 0.78, green: 0.70, blue: 0.48), bloom: Color(red: 0.95, green: 0.82, blue: 0.25))
        case "watermelon": return PlantTones(leaf: leafA, leafDeep: deepA, fruit: Color(red: 0.24, green: 0.42, blue: 0.24), bloom: Color(red: 0.95, green: 0.82, blue: 0.25))
        case "corn": return PlantTones(leaf: leafA, leafDeep: leafB, fruit: Color(red: 0.92, green: 0.80, blue: 0.36), bloom: Color(red: 0.80, green: 0.72, blue: 0.48))
        case "okra": return PlantTones(leaf: leafA, leafDeep: deepA, fruit: Color(red: 0.42, green: 0.58, blue: 0.28), bloom: Color(red: 0.96, green: 0.90, blue: 0.55))
        case "sweetpotato": return PlantTones(leaf: leafA, leafDeep: Color(red: 0.36, green: 0.20, blue: 0.30), fruit: Color(red: 0.66, green: 0.30, blue: 0.22), bloom: .clear)
        case "celery": return PlantTones(leaf: leafPale, leafDeep: leafA, fruit: .clear, bloom: .clear)
        case "leek", "scallion", "chives": return PlantTones(leaf: leafBlue, leafDeep: leafB, fruit: Color(red: 0.92, green: 0.92, blue: 0.88), bloom: Color(red: 0.70, green: 0.50, blue: 0.75))
        case "dill", "cilantro", "parsley": return PlantTones(leaf: leafPale, leafDeep: leafA, fruit: .clear, bloom: Color(red: 0.92, green: 0.88, blue: 0.40))
        case "basil", "mint", "oregano": return PlantTones(leaf: leafA, leafDeep: deepA, fruit: .clear, bloom: Color(red: 0.92, green: 0.90, blue: 0.94))
        case "thyme", "rosemary", "sage": return PlantTones(leaf: leafGrey, leafDeep: Color(red: 0.36, green: 0.42, blue: 0.34), fruit: .clear, bloom: Color(red: 0.70, green: 0.62, blue: 0.82))
        case "strawberry": return PlantTones(leaf: leafA, leafDeep: deepA, fruit: Color(red: 0.82, green: 0.18, blue: 0.20), bloom: Color(red: 0.98, green: 0.97, blue: 0.94))
        case "asparagus": return PlantTones(leaf: leafPale, leafDeep: leafA, fruit: Color(red: 0.50, green: 0.64, blue: 0.40), bloom: .clear)
        case "sunflower": return PlantTones(leaf: leafA, leafDeep: deepA, fruit: Color(red: 0.36, green: 0.24, blue: 0.14), bloom: Color(red: 0.94, green: 0.76, blue: 0.20))
        case "nasturtium": return PlantTones(leaf: leafPale, leafDeep: leafA, fruit: .clear, bloom: Color(red: 0.92, green: 0.46, blue: 0.14))
        case "marigold": return PlantTones(leaf: leafB, leafDeep: deepA, fruit: .clear, bloom: Color(red: 0.92, green: 0.58, blue: 0.14))
        case "calendula": return PlantTones(leaf: leafPale, leafDeep: leafA, fruit: .clear, bloom: Color(red: 0.95, green: 0.66, blue: 0.16))
        default: return PlantTones(leaf: leafA, leafDeep: deepA, fruit: Color(red: 0.7, green: 0.4, blue: 0.2), bloom: Color(red: 0.95, green: 0.85, blue: 0.4))
        }
    }
}

struct PlantPainter {
    var ctx: GraphicsContext
    let crop: Crop
    let tones: PlantTones
    let stage: Stage
    let growth: Double
    let rect: CGRect
    let detail: Bool
    var rng: Furrow

    init(_ ctx: GraphicsContext, crop: Crop, stage: Stage, growth: Double, rect: CGRect, detail: Bool, seed: UInt64) {
        self.ctx = ctx
        self.crop = crop
        self.tones = PlantPalette.tones(for: crop)
        self.stage = stage
        self.growth = growth
        self.rect = rect
        self.detail = detail
        self.rng = Furrow(seed)
    }

    var cx: CGFloat { rect.midX }
    var base: CGFloat { rect.maxY - rect.height * 0.12 }
    var unit: CGFloat { min(rect.width, rect.height) }

    var leafColor: Color { stage == .spent ? Color(red: 0.62, green: 0.52, blue: 0.30) : tones.leaf }
    var deepColor: Color { stage == .spent ? Color(red: 0.46, green: 0.38, blue: 0.22) : tones.leafDeep }

    mutating func draw() {
        switch stage {
        case .bare:
            return
        case .seed:
            drawSeedMark()
        case .sprout:
            drawSprout(size: 0.35 + growth)
        default:
            let scale = stage == .leaf ? 0.55 + growth * 0.45 : 1.0
            switch crop.form {
            case .fruitBush: drawFruitBush(scale)
            case .vine: drawVine(scale)
            case .root: drawRoot(scale)
            case .bulb: drawBulb(scale)
            case .leafy: drawLeafy(scale)
            case .head: drawHead(scale)
            case .bush: drawBush(scale)
            case .tall: drawTall(scale)
            case .stalk: drawStalk(scale)
            case .tuber: drawTuber(scale)
            case .herb: drawHerb(scale)
            case .flower: drawFlower(scale)
            case .runner: drawRunner(scale)
            case .fern: drawFern(scale)
            }
        }
    }

    func stroke(_ path: Path, _ color: Color, _ width: CGFloat) {
        ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    func fill(_ path: Path, _ color: Color) { ctx.fill(path, with: .color(color)) }

    func leaf(at p: CGPoint, angle: Double, length: CGFloat, width: CGFloat, color: Color) {
        var path = Path()
        let tip = CGPoint(x: p.x + CGFloat(cos(angle)) * length, y: p.y + CGFloat(sin(angle)) * length)
        let nx = -CGFloat(sin(angle)) * width, ny = CGFloat(cos(angle)) * width
        let mid = CGPoint(x: (p.x + tip.x) / 2, y: (p.y + tip.y) / 2)
        path.move(to: p)
        path.addQuadCurve(to: tip, control: CGPoint(x: mid.x + nx, y: mid.y + ny))
        path.addQuadCurve(to: p, control: CGPoint(x: mid.x - nx, y: mid.y - ny))
        fill(path, color)
        if detail && length > 6 {
            var vein = Path()
            vein.move(to: p)
            vein.addLine(to: tip)
            stroke(vein, deepColor.opacity(0.5), max(0.5, length * 0.05))
        }
    }

    func dot(_ p: CGPoint, _ r: CGFloat, _ color: Color) {
        fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)), color)
    }

    func drawSeedMark() {
        let r = unit * 0.06
        let p = CGPoint(x: cx, y: base - r)
        fill(Path(ellipseIn: CGRect(x: cx - unit * 0.22, y: base - unit * 0.05, width: unit * 0.44, height: unit * 0.09)),
             Loam.soilDark.opacity(0.35))
        dot(p, r, Color(red: 0.82, green: 0.74, blue: 0.56))
    }

    mutating func drawSprout(size: Double) {
        let h = unit * 0.30 * CGFloat(size)
        var stem = Path()
        stem.move(to: CGPoint(x: cx, y: base))
        stem.addQuadCurve(to: CGPoint(x: cx + h * 0.08, y: base - h), control: CGPoint(x: cx - h * 0.12, y: base - h * 0.5))
        stroke(stem, deepColor, max(0.8, unit * 0.025))
        let top = CGPoint(x: cx + h * 0.08, y: base - h)
        leaf(at: top, angle: -2.4, length: h * 0.55, width: h * 0.22, color: leafColor)
        leaf(at: top, angle: -0.7, length: h * 0.55, width: h * 0.22, color: leafColor)
    }

    mutating func drawFruitBush(_ s: Double) {
        let h = unit * 0.78 * CGFloat(s)
        var stem = Path()
        stem.move(to: CGPoint(x: cx, y: base))
        stem.addLine(to: CGPoint(x: cx, y: base - h))
        stroke(stem, deepColor, max(0.8, unit * 0.03))
        if detail {
            var stake = Path()
            stake.move(to: CGPoint(x: cx + unit * 0.06, y: base))
            stake.addLine(to: CGPoint(x: cx + unit * 0.06, y: base - h * 1.05))
            stroke(stake, Loam.soilLight.opacity(0.7), max(0.6, unit * 0.02))
        }
        let n = detail ? 6 : 4
        for k in 0..<n {
            let t = 0.25 + Double(k) / Double(n) * 0.7
            let y = base - h * CGFloat(t)
            let side: Double = k % 2 == 0 ? -1 : 1
            leaf(at: CGPoint(x: cx, y: y), angle: side > 0 ? -0.5 : -2.6, length: unit * 0.24 * CGFloat(s), width: unit * 0.09 * CGFloat(s), color: k % 3 == 0 ? deepColor : leafColor)
        }
        if stage == .flower {
            for k in 0..<3 {
                let y = base - h * CGFloat(0.45 + Double(k) * 0.18)
                dot(CGPoint(x: cx + (k % 2 == 0 ? -1 : 1) * unit * 0.10, y: y), unit * 0.03, tones.bloom)
            }
        }
        if stage == .mature || stage == .spent {
            let fruitR = unit * (crop.key == "eggplant" ? 0.08 : 0.07)
            for k in 0..<(detail ? 4 : 3) {
                let y = base - h * CGFloat(0.35 + Double(k) * 0.16)
                let x = cx + (k % 2 == 0 ? -1 : 1) * unit * 0.11
                if crop.key == "eggplant" {
                    fill(Path(ellipseIn: CGRect(x: x - fruitR * 0.7, y: y - fruitR, width: fruitR * 1.4, height: fruitR * 2.2)), tones.fruit)
                } else if crop.key == "pepper" {
                    fill(Path(roundedRect: CGRect(x: x - fruitR * 0.6, y: y - fruitR, width: fruitR * 1.2, height: fruitR * 2.0), cornerRadius: fruitR * 0.4), tones.fruit)
                } else {
                    dot(CGPoint(x: x, y: y), fruitR, stage == .spent ? tones.fruit.opacity(0.5) : tones.fruit)
                    if detail { dot(CGPoint(x: x - fruitR * 0.3, y: y - fruitR * 0.3), fruitR * 0.3, Color.white.opacity(0.35)) }
                }
            }
        }
    }

    mutating func drawVine(_ s: Double) {
        let spread = unit * 0.42 * CGFloat(s)
        let climbing = crop.key == "pea" || crop.key == "polebean" || crop.key == "cucumber"
        if climbing {
            let h = unit * 0.82 * CGFloat(s)
            if detail {
                var pole = Path()
                pole.move(to: CGPoint(x: cx, y: base))
                pole.addLine(to: CGPoint(x: cx, y: base - h * 1.08))
                stroke(pole, Loam.soilLight.opacity(0.75), max(0.6, unit * 0.02))
            }
            var vine = Path()
            vine.move(to: CGPoint(x: cx - unit * 0.05, y: base))
            let steps = 5
            for k in 1...steps {
                let t = CGFloat(k) / CGFloat(steps)
                vine.addQuadCurve(to: CGPoint(x: cx + (k % 2 == 0 ? -1 : 1) * unit * 0.07, y: base - h * t),
                                  control: CGPoint(x: cx + (k % 2 == 0 ? 1 : -1) * unit * 0.12, y: base - h * (t - 0.1)))
            }
            stroke(vine, deepColor, max(0.7, unit * 0.022))
            for k in 0..<(detail ? 6 : 4) {
                let t = 0.2 + Double(k) / 6 * 0.75
                let y = base - h * CGFloat(t)
                let side: Double = k % 2 == 0 ? -1 : 1
                leaf(at: CGPoint(x: cx, y: y), angle: side > 0 ? -0.35 : -2.8, length: unit * 0.20 * CGFloat(s), width: unit * 0.09 * CGFloat(s), color: leafColor)
            }
            if stage == .flower {
                for k in 0..<3 { dot(CGPoint(x: cx + (k % 2 == 0 ? -1 : 1) * unit * 0.09, y: base - h * CGFloat(0.5 + Double(k) * 0.15)), unit * 0.03, tones.bloom) }
            }
            if stage == .mature || stage == .spent {
                for k in 0..<3 {
                    let y = base - h * CGFloat(0.4 + Double(k) * 0.17)
                    let x = cx + (k % 2 == 0 ? -1 : 1) * unit * 0.10
                    var pod = Path()
                    pod.move(to: CGPoint(x: x, y: y))
                    pod.addQuadCurve(to: CGPoint(x: x + unit * 0.02, y: y + unit * (crop.key == "cucumber" ? 0.22 : 0.16)),
                                     control: CGPoint(x: x + unit * 0.06, y: y + unit * 0.08))
                    stroke(pod, tones.fruit, unit * (crop.key == "cucumber" ? 0.06 : 0.035))
                }
            }
        } else {
            for k in 0..<(detail ? 7 : 5) {
                let a = -0.2 + Double(k) / 6 * 3.6
                let d = spread * CGFloat(0.45 + (k % 2 == 0 ? 0.35 : 0.1))
                let p = CGPoint(x: cx + CGFloat(cos(a)) * d, y: base - unit * 0.08 - CGFloat(abs(sin(a))) * spread * 0.55)
                var runner = Path()
                runner.move(to: CGPoint(x: cx, y: base - unit * 0.06))
                runner.addQuadCurve(to: p, control: CGPoint(x: (cx + p.x) / 2, y: p.y - unit * 0.06))
                stroke(runner, deepColor, max(0.6, unit * 0.02))
                leaf(at: p, angle: a - 3.2 + 0.4, length: unit * 0.26 * CGFloat(s), width: unit * 0.15 * CGFloat(s), color: k % 2 == 0 ? leafColor : deepColor)
            }
            if stage == .flower {
                dot(CGPoint(x: cx + unit * 0.12, y: base - unit * 0.3), unit * 0.045, tones.bloom)
                dot(CGPoint(x: cx - unit * 0.18, y: base - unit * 0.22), unit * 0.04, tones.bloom)
            }
            if stage == .mature || stage == .spent {
                let r = unit * (crop.key == "pumpkin" || crop.key == "watermelon" ? 0.16 : 0.12)
                let p = CGPoint(x: cx + unit * 0.12, y: base - r * 0.9)
                if crop.key == "watermelon" {
                    fill(Path(ellipseIn: CGRect(x: p.x - r * 1.2, y: p.y - r * 0.8, width: r * 2.4, height: r * 1.6)), tones.fruit)
                    if detail {
                        for k in 0..<3 {
                            var stripe = Path()
                            let x = p.x - r * 0.7 + CGFloat(k) * r * 0.7
                            stripe.move(to: CGPoint(x: x, y: p.y - r * 0.7))
                            stripe.addQuadCurve(to: CGPoint(x: x, y: p.y + r * 0.7), control: CGPoint(x: x + r * 0.2, y: p.y))
                            stroke(stripe, Color(red: 0.55, green: 0.68, blue: 0.40), r * 0.12)
                        }
                    }
                } else if crop.key == "pumpkin" || crop.key == "wintersquash" {
                    fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r * 0.8, width: r * 2, height: r * 1.6)), tones.fruit)
                    if detail {
                        for k in 0..<3 {
                            var rib = Path()
                            let x = p.x - r * 0.5 + CGFloat(k) * r * 0.5
                            rib.move(to: CGPoint(x: x, y: p.y - r * 0.75))
                            rib.addLine(to: CGPoint(x: x, y: p.y + r * 0.75))
                            stroke(rib, tones.fruit.opacity(0.4), r * 0.1)
                        }
                        var stalk = Path()
                        stalk.move(to: CGPoint(x: p.x, y: p.y - r * 0.8))
                        stalk.addLine(to: CGPoint(x: p.x + r * 0.15, y: p.y - r * 1.1))
                        stroke(stalk, deepColor, r * 0.15)
                    }
                } else {
                    dot(p, r, tones.fruit)
                    if detail && crop.key == "melon" {
                        for k in 0..<4 {
                            let a = Double(k) * 0.8
                            var net = Path()
                            net.move(to: CGPoint(x: p.x + CGFloat(cos(a)) * r * 0.8, y: p.y + CGFloat(sin(a)) * r * 0.8))
                            net.addLine(to: CGPoint(x: p.x - CGFloat(cos(a + 0.5)) * r * 0.8, y: p.y - CGFloat(sin(a + 0.5)) * r * 0.8))
                            stroke(net, Color.white.opacity(0.25), r * 0.08)
                        }
                    }
                }
            }
        }
    }

    mutating func drawRoot(_ s: Double) {
        let h = unit * 0.55 * CGFloat(s)
        let feathery = crop.key == "carrot" || crop.key == "parsnip"
        let n = detail ? 7 : 5
        for k in 0..<n {
            let a = -Double.pi / 2 + (Double(k) - Double(n - 1) / 2) * 0.34
            if feathery {
                var fr = Path()
                fr.move(to: CGPoint(x: cx, y: base))
                let tip = CGPoint(x: cx + CGFloat(cos(a)) * h, y: base + CGFloat(sin(a)) * h)
                fr.addQuadCurve(to: tip, control: CGPoint(x: cx + CGFloat(cos(a)) * h * 0.5 + CGFloat(sin(a)) * h * 0.12, y: base + CGFloat(sin(a)) * h * 0.5))
                stroke(fr, k % 2 == 0 ? leafColor : deepColor, max(0.6, unit * 0.03))
                if detail {
                    for j in 1...3 {
                        let t = CGFloat(j) / 4
                        let p = CGPoint(x: cx + CGFloat(cos(a)) * h * t, y: base + CGFloat(sin(a)) * h * t)
                        var tuft = Path()
                        tuft.move(to: p)
                        tuft.addLine(to: CGPoint(x: p.x + CGFloat(cos(a - 0.7)) * h * 0.14, y: p.y + CGFloat(sin(a - 0.7)) * h * 0.14))
                        tuft.move(to: p)
                        tuft.addLine(to: CGPoint(x: p.x + CGFloat(cos(a + 0.7)) * h * 0.14, y: p.y + CGFloat(sin(a + 0.7)) * h * 0.14))
                        stroke(tuft, leafColor, max(0.4, unit * 0.015))
                    }
                }
            } else {
                leaf(at: CGPoint(x: cx, y: base), angle: a, length: h, width: h * 0.28, color: k % 2 == 0 ? leafColor : deepColor)
            }
        }
        if stage == .mature || stage == .spent {
            let r = unit * 0.12
            let shoulder = CGRect(x: cx - r, y: base - r * 0.5, width: r * 2, height: r * 0.9)
            fill(Path(ellipseIn: shoulder), tones.fruit)
            if detail {
                fill(Path(ellipseIn: CGRect(x: cx - r * 0.6, y: base - r * 0.4, width: r * 0.6, height: r * 0.3)), Color.white.opacity(0.25))
            }
        }
    }

    mutating func drawBulb(_ s: Double) {
        let h = unit * 0.7 * CGFloat(s)
        let n = detail ? 6 : 4
        for k in 0..<n {
            let a = -Double.pi / 2 + (Double(k) - Double(n - 1) / 2) * 0.22
            var blade = Path()
            blade.move(to: CGPoint(x: cx, y: base))
            let tip = CGPoint(x: cx + CGFloat(cos(a)) * h, y: base + CGFloat(sin(a)) * h)
            blade.addQuadCurve(to: tip, control: CGPoint(x: cx + CGFloat(cos(a)) * h * 0.4 + CGFloat(cos(a)) * h * 0.2, y: base + CGFloat(sin(a)) * h * 0.55))
            stroke(blade, k % 2 == 0 ? leafColor : deepColor, max(0.7, unit * (crop.key == "kohlrabi" ? 0.06 : 0.035)))
        }
        if stage == .mature || stage == .spent || (crop.key == "kohlrabi" && stage == .flower) {
            let r = unit * (crop.key == "kohlrabi" || crop.key == "fennel" ? 0.15 : 0.11)
            fill(Path(ellipseIn: CGRect(x: cx - r, y: base - r * 1.1, width: r * 2, height: r * 1.5)), tones.fruit)
            if detail {
                var lines = Path()
                lines.move(to: CGPoint(x: cx - r * 0.4, y: base - r * 1.0))
                lines.addLine(to: CGPoint(x: cx - r * 0.3, y: base + r * 0.2))
                lines.move(to: CGPoint(x: cx + r * 0.4, y: base - r * 1.0))
                lines.addLine(to: CGPoint(x: cx + r * 0.3, y: base + r * 0.2))
                stroke(lines, tones.fruit.opacity(0.5), r * 0.1)
            }
        }
    }

    mutating func drawLeafy(_ s: Double) {
        let h = unit * 0.62 * CGFloat(s)
        let n = detail ? 8 : 5
        for k in 0..<n {
            let a = -Double.pi / 2 + (Double(k) - Double(n - 1) / 2) * (Double.pi * 0.9 / Double(n))
            let len = h * CGFloat(0.75 + (k % 2 == 0 ? 0.25 : 0.0))
            leaf(at: CGPoint(x: cx, y: base), angle: a, length: len, width: len * (crop.key == "kale" ? 0.30 : 0.34), color: k % 2 == 0 ? leafColor : deepColor)
        }
        if crop.key == "chard" && detail {
            for k in 0..<3 {
                let a = -Double.pi / 2 + (Double(k) - 1) * 0.5
                var rib = Path()
                rib.move(to: CGPoint(x: cx, y: base))
                rib.addLine(to: CGPoint(x: cx + CGFloat(cos(a)) * h * 0.6, y: base + CGFloat(sin(a)) * h * 0.6))
                stroke(rib, tones.fruit, max(0.6, unit * 0.025))
            }
        }
    }

    mutating func drawHead(_ s: Double) {
        let r = unit * 0.36 * CGFloat(s)
        let c = CGPoint(x: cx, y: base - r * 0.55)
        let n = detail ? 9 : 6
        for k in 0..<n {
            let a = Double(k) / Double(n) * 2 * Double.pi + 0.3
            leaf(at: c, angle: a, length: r * 1.05, width: r * 0.42, color: k % 2 == 0 ? deepColor : leafColor)
        }
        if stage == .mature || stage == .spent || stage == .flower {
            let inner = r * (stage == .flower ? 0.45 : 0.62)
            let tone: Color
            switch crop.key {
            case "broccoli", "cauliflower", "cabbage", "bokchoy", "endive": tone = tones.fruit
            default: tone = leafColor.opacity(0.9)
            }
            dot(c, inner, tone)
            if detail && crop.key == "broccoli" {
                for k in 0..<5 {
                    let a = Double(k) / 5 * 2 * Double.pi
                    dot(CGPoint(x: c.x + CGFloat(cos(a)) * inner * 0.5, y: c.y + CGFloat(sin(a)) * inner * 0.5), inner * 0.32, tones.fruit.opacity(0.85))
                }
            } else if detail && crop.key == "cauliflower" {
                for k in 0..<5 {
                    let a = Double(k) / 5 * 2 * Double.pi
                    dot(CGPoint(x: c.x + CGFloat(cos(a)) * inner * 0.45, y: c.y + CGFloat(sin(a)) * inner * 0.45), inner * 0.3, Color.white.opacity(0.5))
                }
            } else if detail && (crop.key == "cabbage" || crop.key == "lettuce") {
                var swirl = Path()
                swirl.addArc(center: c, radius: inner * 0.5, startAngle: .degrees(20), endAngle: .degrees(300), clockwise: false)
                stroke(swirl, deepColor.opacity(0.5), max(0.5, inner * 0.08))
            }
        }
    }

    mutating func drawBush(_ s: Double) {
        let h = unit * 0.6 * CGFloat(s)
        let big = crop.key == "zucchini"
        let n = detail ? 7 : 5
        for k in 0..<n {
            let a = -Double.pi / 2 + (Double(k) - Double(n - 1) / 2) * 0.42
            let len = h * (big ? 1.0 : 0.8)
            leaf(at: CGPoint(x: cx, y: base), angle: a, length: len, width: len * (big ? 0.42 : 0.28), color: k % 2 == 0 ? leafColor : deepColor)
        }
        if stage == .flower && big {
            dot(CGPoint(x: cx + unit * 0.15, y: base - h * 0.35), unit * 0.06, tones.bloom)
        } else if stage == .flower {
            for k in 0..<3 { dot(CGPoint(x: cx + CGFloat(k - 1) * unit * 0.12, y: base - h * 0.5), unit * 0.025, tones.bloom) }
        }
        if stage == .mature || stage == .spent {
            if big {
                var fruit = Path()
                fruit.move(to: CGPoint(x: cx - unit * 0.05, y: base - unit * 0.06))
                fruit.addLine(to: CGPoint(x: cx + unit * 0.30, y: base - unit * 0.02))
                stroke(fruit, tones.fruit, unit * 0.09)
            } else {
                for k in 0..<4 {
                    let x = cx + CGFloat(k - 2) * unit * 0.10 + unit * 0.05
                    var pod = Path()
                    pod.move(to: CGPoint(x: x, y: base - h * 0.45))
                    pod.addLine(to: CGPoint(x: x + unit * 0.02, y: base - h * 0.15))
                    stroke(pod, tones.fruit, unit * 0.035)
                }
            }
        }
    }

    mutating func drawTall(_ s: Double) {
        let h = unit * 0.92 * CGFloat(s)
        var stalk = Path()
        stalk.move(to: CGPoint(x: cx, y: base))
        stalk.addLine(to: CGPoint(x: cx, y: base - h))
        stroke(stalk, deepColor, max(0.9, unit * (crop.key == "corn" ? 0.045 : 0.035)))
        let n = detail ? 6 : 4
        for k in 0..<n {
            let t = 0.2 + Double(k) / Double(n) * 0.65
            let y = base - h * CGFloat(t)
            let side: Double = k % 2 == 0 ? -1 : 1
            if crop.key == "corn" {
                var blade = Path()
                blade.move(to: CGPoint(x: cx, y: y))
                blade.addQuadCurve(to: CGPoint(x: cx + CGFloat(side) * unit * 0.34, y: y - unit * 0.02),
                                   control: CGPoint(x: cx + CGFloat(side) * unit * 0.14, y: y - unit * 0.14))
                stroke(blade, k % 2 == 0 ? leafColor : deepColor, max(0.8, unit * 0.04))
            } else {
                leaf(at: CGPoint(x: cx, y: y), angle: side > 0 ? -0.55 : -2.6, length: unit * 0.22 * CGFloat(s), width: unit * 0.08 * CGFloat(s), color: k % 2 == 0 ? leafColor : deepColor)
            }
        }
        if crop.key == "corn" && (stage == .flower || stage == .mature || stage == .spent) {
            for k in 0..<3 {
                var tassel = Path()
                tassel.move(to: CGPoint(x: cx, y: base - h))
                tassel.addLine(to: CGPoint(x: cx + CGFloat(k - 1) * unit * 0.08, y: base - h - unit * 0.12))
                stroke(tassel, tones.bloom, max(0.5, unit * 0.02))
            }
        }
        if stage == .mature || stage == .spent {
            if crop.key == "corn" {
                fill(Path(roundedRect: CGRect(x: cx + unit * 0.02, y: base - h * 0.55, width: unit * 0.09, height: unit * 0.22), cornerRadius: unit * 0.04), tones.fruit)
            } else if crop.key == "brussels" {
                for k in 0..<5 { dot(CGPoint(x: cx + (k % 2 == 0 ? -1 : 1) * unit * 0.05, y: base - h * CGFloat(0.25 + Double(k) * 0.12)), unit * 0.04, tones.fruit) }
            } else if crop.key == "okra" {
                for k in 0..<3 {
                    var pod = Path()
                    pod.move(to: CGPoint(x: cx, y: base - h * CGFloat(0.5 + Double(k) * 0.15)))
                    pod.addLine(to: CGPoint(x: cx + (k % 2 == 0 ? -1 : 1) * unit * 0.09, y: base - h * CGFloat(0.62 + Double(k) * 0.15)))
                    stroke(pod, tones.fruit, unit * 0.035)
                }
            } else {
                for k in 0..<4 {
                    var pod = Path()
                    let y = base - h * CGFloat(0.3 + Double(k) * 0.14)
                    pod.move(to: CGPoint(x: cx, y: y))
                    pod.addLine(to: CGPoint(x: cx + (k % 2 == 0 ? -1 : 1) * unit * 0.04, y: y + unit * 0.14))
                    stroke(pod, tones.fruit, unit * 0.045)
                }
            }
        } else if stage == .flower && crop.key != "corn" {
            for k in 0..<3 { dot(CGPoint(x: cx + (k % 2 == 0 ? -1 : 1) * unit * 0.06, y: base - h * CGFloat(0.45 + Double(k) * 0.15)), unit * 0.03, tones.bloom) }
        }
    }

    mutating func drawStalk(_ s: Double) {
        let h = unit * 0.7 * CGFloat(s)
        let n = detail ? 7 : 5
        let thick = crop.key == "leek" || crop.key == "celery"
        for k in 0..<n {
            let off = (CGFloat(k) - CGFloat(n - 1) / 2) * unit * (thick ? 0.06 : 0.045)
            var blade = Path()
            blade.move(to: CGPoint(x: cx + off * 0.4, y: base))
            blade.addQuadCurve(to: CGPoint(x: cx + off * 2.2, y: base - h * CGFloat(0.8 + Double(k % 3) * 0.08)),
                               control: CGPoint(x: cx + off * 0.6, y: base - h * 0.5))
            stroke(blade, k % 2 == 0 ? leafColor : deepColor, max(0.6, unit * (thick ? 0.045 : 0.025)))
        }
        if thick && (stage == .mature || stage == .spent) {
            fill(Path(roundedRect: CGRect(x: cx - unit * 0.06, y: base - h * 0.32, width: unit * 0.12, height: h * 0.34), cornerRadius: unit * 0.03), tones.fruit)
        }
        if crop.key == "chives" && stage == .flower {
            for k in 0..<3 { dot(CGPoint(x: cx + CGFloat(k - 1) * unit * 0.12, y: base - h * 0.85), unit * 0.05, tones.bloom) }
        }
        if crop.key == "celery" && detail {
            for k in 0..<3 {
                let x = cx + CGFloat(k - 1) * unit * 0.1
                leaf(at: CGPoint(x: x, y: base - h * 0.75), angle: -1.57 + Double(k - 1) * 0.4, length: h * 0.25, width: h * 0.1, color: leafColor)
            }
        }
    }

    mutating func drawTuber(_ s: Double) {
        let h = unit * 0.55 * CGFloat(s)
        let n = detail ? 8 : 5
        for k in 0..<n {
            let a = -Double.pi / 2 + (Double(k) - Double(n - 1) / 2) * 0.36
            let len = h * CGFloat(0.8 + Double(k % 2) * 0.2)
            leaf(at: CGPoint(x: cx, y: base - unit * 0.04), angle: a, length: len, width: len * 0.26, color: k % 2 == 0 ? leafColor : deepColor)
        }
        if detail {
            fill(Path(ellipseIn: CGRect(x: cx - unit * 0.3, y: base - unit * 0.06, width: unit * 0.6, height: unit * 0.12)), Loam.soilDark.opacity(0.35))
        }
        if stage == .flower {
            for k in 0..<3 { dot(CGPoint(x: cx + CGFloat(k - 1) * unit * 0.1, y: base - h * 0.9), unit * 0.03, tones.bloom) }
        }
        if stage == .mature || stage == .spent {
            for k in 0..<3 {
                dot(CGPoint(x: cx + CGFloat(k - 1) * unit * 0.13, y: base + unit * 0.02), unit * 0.06, tones.fruit)
            }
        }
    }

    mutating func drawHerb(_ s: Double) {
        let h = unit * 0.5 * CGFloat(s)
        let fine = crop.key == "dill" || crop.key == "cilantro" || crop.key == "parsley" || crop.key == "rosemary" || crop.key == "thyme"
        let n = detail ? 9 : 6
        for k in 0..<n {
            let a = -Double.pi / 2 + (Double(k) - Double(n - 1) / 2) * 0.3
            let len = h * CGFloat(0.7 + Double(k % 3) * 0.15)
            if fine {
                var sprig = Path()
                sprig.move(to: CGPoint(x: cx, y: base))
                let tip = CGPoint(x: cx + CGFloat(cos(a)) * len, y: base + CGFloat(sin(a)) * len)
                sprig.addQuadCurve(to: tip, control: CGPoint(x: cx + CGFloat(cos(a)) * len * 0.5 - CGFloat(sin(a)) * len * 0.1, y: base + CGFloat(sin(a)) * len * 0.5))
                stroke(sprig, k % 2 == 0 ? leafColor : deepColor, max(0.5, unit * 0.022))
                if detail {
                    for j in 1...2 {
                        let t = CGFloat(j) / 3
                        let p = CGPoint(x: cx + CGFloat(cos(a)) * len * t, y: base + CGFloat(sin(a)) * len * t)
                        var tuft = Path()
                        tuft.move(to: p)
                        tuft.addLine(to: CGPoint(x: p.x + CGFloat(cos(a - 0.8)) * len * 0.16, y: p.y + CGFloat(sin(a - 0.8)) * len * 0.16))
                        tuft.move(to: p)
                        tuft.addLine(to: CGPoint(x: p.x + CGFloat(cos(a + 0.8)) * len * 0.16, y: p.y + CGFloat(sin(a + 0.8)) * len * 0.16))
                        stroke(tuft, leafColor, max(0.4, unit * 0.014))
                    }
                }
            } else {
                var stem = Path()
                stem.move(to: CGPoint(x: cx, y: base))
                let tip = CGPoint(x: cx + CGFloat(cos(a)) * len, y: base + CGFloat(sin(a)) * len)
                stem.addLine(to: tip)
                stroke(stem, deepColor, max(0.5, unit * 0.018))
                leaf(at: CGPoint(x: (cx + tip.x) / 2, y: (base + tip.y) / 2), angle: a - 0.9, length: len * 0.32, width: len * 0.16, color: leafColor)
                leaf(at: tip, angle: a + 0.6, length: len * 0.3, width: len * 0.15, color: leafColor)
            }
        }
        if stage == .flower || stage == .mature {
            let tone = tones.bloom
            if tone != .clear {
                for k in 0..<3 { dot(CGPoint(x: cx + CGFloat(k - 1) * unit * 0.14, y: base - h * CGFloat(0.85 - Double(k % 2) * 0.1)), unit * 0.03, tone) }
            }
        }
    }

    mutating func drawFlower(_ s: Double) {
        let tall = crop.key == "sunflower"
        let h = unit * (tall ? 0.95 : 0.6) * CGFloat(s)
        var stem = Path()
        stem.move(to: CGPoint(x: cx, y: base))
        stem.addLine(to: CGPoint(x: cx, y: base - h))
        stroke(stem, deepColor, max(0.8, unit * (tall ? 0.04 : 0.025)))
        for k in 0..<(detail ? 4 : 2) {
            let t = 0.3 + Double(k) * 0.18
            let side: Double = k % 2 == 0 ? -1 : 1
            leaf(at: CGPoint(x: cx, y: base - h * CGFloat(t)), angle: side > 0 ? -0.5 : -2.6, length: unit * 0.2 * CGFloat(s), width: unit * 0.09 * CGFloat(s), color: leafColor)
        }
        if stage == .flower || stage == .mature || stage == .spent {
            let r = unit * (tall ? 0.16 : 0.09)
            let c = CGPoint(x: cx, y: base - h)
            let petals = tall ? 12 : 8
            for k in 0..<petals {
                let a = Double(k) / Double(petals) * 2 * Double.pi
                leaf(at: c, angle: a, length: r * 1.4, width: r * 0.45, color: stage == .spent ? tones.bloom.opacity(0.5) : tones.bloom)
            }
            dot(c, r * 0.6, tall ? tones.fruit : tones.bloom.opacity(0.7))
            if !tall && detail {
                for k in 0..<2 {
                    let side = CGFloat(k == 0 ? -1 : 1)
                    let c2 = CGPoint(x: cx + side * unit * 0.18, y: base - h * 0.7)
                    for j in 0..<6 {
                        let a = Double(j) / 6 * 2 * Double.pi
                        leaf(at: c2, angle: a, length: r * 0.9, width: r * 0.3, color: tones.bloom)
                    }
                    dot(c2, r * 0.35, tones.bloom.opacity(0.7))
                }
            }
        }
    }

    mutating func drawRunner(_ s: Double) {
        let spread = unit * 0.44 * CGFloat(s)
        let n = detail ? 8 : 5
        for k in 0..<n {
            let a = 0.1 + Double(k) / Double(n - 1) * 2.9
            let d = spread * CGFloat(0.5 + (k % 2 == 0 ? 0.4 : 0.1))
            let p = CGPoint(x: cx + CGFloat(cos(a)) * d, y: base - unit * 0.06 - CGFloat(abs(sin(a))) * spread * 0.4)
            var runner = Path()
            runner.move(to: CGPoint(x: cx, y: base - unit * 0.05))
            runner.addQuadCurve(to: p, control: CGPoint(x: (cx + p.x) / 2, y: p.y - unit * 0.04))
            stroke(runner, deepColor, max(0.5, unit * 0.018))
            if crop.key == "strawberry" {
                for j in 0..<3 {
                    leaf(at: p, angle: a - 3.6 + Double(j) * 0.6, length: unit * 0.13 * CGFloat(s), width: unit * 0.07 * CGFloat(s), color: j == 1 ? leafColor : deepColor)
                }
            } else {
                dot(p, unit * 0.09 * CGFloat(s), k % 2 == 0 ? leafColor : deepColor)
                if detail { dot(p, unit * 0.025, deepColor.opacity(0.6)) }
            }
        }
        if stage == .flower || stage == .mature || stage == .spent {
            let tone = crop.key == "strawberry" && stage != .flower ? tones.fruit : tones.bloom
            if tone != .clear {
                for k in 0..<3 {
                    dot(CGPoint(x: cx + CGFloat(k - 1) * unit * 0.2, y: base - unit * (0.12 + Double(k % 2) * 0.1)), unit * (crop.key == "strawberry" ? 0.045 : 0.05), tone)
                }
            }
        }
        if crop.key == "sweetpotato" && (stage == .mature || stage == .spent) {
            for k in 0..<2 { fill(Path(ellipseIn: CGRect(x: cx + CGFloat(k) * unit * 0.14 - unit * 0.1, y: base - unit * 0.02, width: unit * 0.14, height: unit * 0.07)), tones.fruit) }
        }
    }

    mutating func drawFern(_ s: Double) {
        let h = unit * 0.9 * CGFloat(s)
        if stage == .mature {
            for k in 0..<4 {
                let x = cx + CGFloat(k - 2) * unit * 0.11 + unit * 0.05
                var spear = Path()
                spear.move(to: CGPoint(x: x, y: base))
                spear.addLine(to: CGPoint(x: x, y: base - unit * 0.3))
                stroke(spear, tones.fruit, unit * 0.045)
                dot(CGPoint(x: x, y: base - unit * 0.3), unit * 0.03, deepColor)
            }
            return
        }
        let n = detail ? 3 : 2
        for k in 0..<n {
            let x = cx + CGFloat(k - n / 2) * unit * 0.12
            var stem = Path()
            stem.move(to: CGPoint(x: x, y: base))
            stem.addLine(to: CGPoint(x: x + unit * 0.03, y: base - h))
            stroke(stem, deepColor, max(0.5, unit * 0.02))
            for j in 0..<(detail ? 6 : 4) {
                let t = 0.25 + Double(j) / 6 * 0.7
                let y = base - h * CGFloat(t)
                var frond = Path()
                frond.move(to: CGPoint(x: x, y: y))
                frond.addLine(to: CGPoint(x: x + (j % 2 == 0 ? -1 : 1) * unit * 0.16, y: y - unit * 0.06))
                stroke(frond, leafColor, max(0.4, unit * 0.014))
            }
        }
    }
}

struct PlantGlyph: View {
    var crop: Crop
    var stage: Stage
    var growth: Double = 1
    var size: CGFloat
    var detail: Bool = true

    var body: some View {
        Canvas { ctx, area in
            var painter = PlantPainter(ctx, crop: crop, stage: stage, growth: growth,
                                       rect: CGRect(origin: .zero, size: area), detail: detail,
                                       seed: hashOf(crop.key))
            painter.draw()
        }
        .frame(width: size, height: size)
    }
}
