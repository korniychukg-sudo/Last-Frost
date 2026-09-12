import Foundation
import CoreGraphics

let lessonKeys: [String] = ["frostdates", "hardening", "sowing", "maturity", "spacing", "succession",
                            "rotation", "companions", "mulchwater", "fallcrops", "seedsaving", "covercrops"]

let lessonTitles: [(String, String)] = [
    ("Reading Frost Dates", "Two dates, and everything counted from them"),
    ("Hardening Off", "A week of days outside and nights in"),
    ("Direct or Indoors", "The drill in the soil and the tray under the lamp"),
    ("Days to Maturity", "The number on the packet, and where it starts"),
    ("Square-Foot Spacing", "One, four, nine or sixteen to the square"),
    ("Succession Sowing", "A short row every fortnight, not a long row once"),
    ("Rotation Families", "Move each family on, season by season"),
    ("Companion Planting", "What is real, what is folklore"),
    ("Mulch and Water", "Deep at the root, and a cover to keep it there"),
    ("Fall and Overwinter", "The second season, counted back from the first frost"),
    ("Seed Saving", "Dry, label, and keep the true ones"),
    ("Cover Crops", "Green manure that holds the soil through winter")
]

func yearRuler(_ p: Leaf, x0: Double, x1: Double, y: Double, lastFrost: Double, firstFrost: Double, seed: UInt64) {
    let months = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]
    pen(p, [pt(x0, y), pt(x1, y)], weight: 3, colour: Pot.ink, wobble: 0.5, taper: false, seed: seed)
    for k in 0...12 {
        let x = x0 + (x1 - x0) * Double(k) / 12
        pen(p, [pt(x, y - 10), pt(x, y + 10)], weight: 2, colour: Pot.ink, wobble: 0.3, taper: false, seed: seed &+ UInt64(k))
        if k < 12 {
            letter(p, months[k], at: x + (x1 - x0) / 24, y + 34, size: 20, colour: Pot.inkPale, face: "Baskerville", align: .centre)
        }
    }
    let lx = x0 + (x1 - x0) * lastFrost, fx = x0 + (x1 - x0) * firstFrost
    wash(p, [pt(x0, y - 30), pt(lx, y - 30), pt(lx, y - 4), pt(x0, y - 4)], Pot.frost, strength: 0.5, bleed: 3, seed: seed &+ 20)
    wash(p, [pt(fx, y - 30), pt(x1, y - 30), pt(x1, y - 4), pt(fx, y - 4)], Pot.frost, strength: 0.5, bleed: 3, seed: seed &+ 21)
    pen(p, [pt(lx, y - 60), pt(lx, y + 14)], weight: 4, colour: Pot.frostDeep, wobble: 0.4, taper: false, seed: seed &+ 22)
    pen(p, [pt(fx, y - 60), pt(fx, y + 14)], weight: 4, colour: Pot.terraDeep, wobble: 0.4, taper: false, seed: seed &+ 23)
    letter(p, "last frost", at: lx, y - 70, size: 18, colour: Pot.frostDeep, face: "Baskerville-Italic", align: .centre)
    letter(p, "first frost", at: fx, y - 70, size: 18, colour: Pot.terraDeep, face: "Baskerville-Italic", align: .centre)
}

func cropBar(_ p: Leaf, x0: Double, x1: Double, y: Double, from: Double, to: Double, tone: Hue, label: String, seed: UInt64) {
    let a = x0 + (x1 - x0) * from, b = x0 + (x1 - x0) * to
    wash(p, [pt(a, y - 12), pt(b, y - 12), pt(b, y + 12), pt(a, y + 12)], tone, strength: 0.7, bleed: 3, seed: seed)
    penEdge(p, [pt(a, y - 12), pt(b, y - 12), pt(b, y + 12), pt(a, y + 12)], weight: 1.6, colour: tone.dk(0.5), seed: seed &+ 1)
    letter(p, label, at: a - 14, y + 7, size: 18, colour: Pot.inkSoft, face: "Baskerville", align: .right)
}

func potWithSeedling(_ p: Leaf, at c: CGPoint, size: Double, tone: Hue, seed: UInt64) {
    let potRing = [pt(Double(c.x) - size * 0.5, Double(c.y)), pt(Double(c.x) + size * 0.5, Double(c.y)), pt(Double(c.x) + size * 0.38, Double(c.y) + size * 0.7), pt(Double(c.x) - size * 0.38, Double(c.y) + size * 0.7)]
    wash(p, potRing, Pot.terracotta, strength: 0.62, bleed: 2, seed: seed)
    crossHatch(p, pathOf(potRing), depth: 2, spacing: 4, colour: Pot.terraDeep.dk(0.2), seed: seed &+ 1)
    penEdge(p, potRing, weight: 2, colour: Pot.ink.al(0.8), seed: seed &+ 2)
    p.box(Double(c.x) - size * 0.5, Double(c.y) - size * 0.08, size, size * 0.1, Pot.terraDeep.al(0.9))
    wash(p, [pt(Double(c.x) - size * 0.44, Double(c.y) + 2), pt(Double(c.x) + size * 0.44, Double(c.y) + 2), pt(Double(c.x) + size * 0.42, Double(c.y) + size * 0.14), pt(Double(c.x) - size * 0.42, Double(c.y) + size * 0.14)], Pot.soil, strength: 0.7, bleed: 2, seed: seed &+ 3)
    seedlingVignette(p, at: pt(Double(c.x), Double(c.y) + 4), tone: tone, monocot: false, seed: seed &+ 4)
}

func wateringCan(_ p: Leaf, at c: CGPoint, size: Double, seed: UInt64) {
    let bodyRing = [pt(Double(c.x) - size * 0.3, Double(c.y) - size * 0.3), pt(Double(c.x) + size * 0.3, Double(c.y) - size * 0.3), pt(Double(c.x) + size * 0.34, Double(c.y) + size * 0.3), pt(Double(c.x) - size * 0.34, Double(c.y) + size * 0.3)]
    wash(p, bodyRing, Pot.frostDeep.mix(Pot.inkPale, 0.4), strength: 0.7, bleed: 2, seed: seed)
    crossHatch(p, pathOf(bodyRing), depth: 2, spacing: 4.5, colour: Pot.ink.al(0.5), seed: seed &+ 1)
    penEdge(p, bodyRing, weight: 2.4, colour: Pot.ink, seed: seed &+ 2)
    let spout = [pt(Double(c.x) - size * 0.3, Double(c.y) - size * 0.1), pt(Double(c.x) - size * 0.9, Double(c.y) - size * 0.5)]
    pen(p, spout, weight: size * 0.09, colour: Pot.frostDeep.mix(Pot.inkPale, 0.4).dk(0.2), wobble: 0.4, taper: false, seed: seed &+ 3)
    p.egg(Double(c.x) - size * 0.92, Double(c.y) - size * 0.52, size * 0.1, size * 0.07, Pot.inkSoft)
    let handle = ringOf(cx: Double(c.x) + size * 0.3, cy: Double(c.y), rx: size * 0.22, ry: size * 0.3, steps: 24)
    pen(p, Array(handle[18...23] + handle[0...6]), weight: size * 0.06, colour: Pot.ink, wobble: 0.4, taper: false, seed: seed &+ 4)
    var rng = Chip(seed &+ 9)
    for k in 0..<12 {
        let x = Double(c.x) - size * 0.95 + rng.r(-size * 0.2, size * 0.1)
        let y0 = Double(c.y) - size * 0.45 + Double(k) * 4
        pen(p, [pt(x, y0), pt(x - rng.r(4, 14), y0 + rng.r(30, 80))], weight: 1.8, colour: Pot.frostDeep.al(0.7), wobble: 0.4, taper: true, seed: seed &+ UInt64(k + 20))
    }
}

func bedBox(_ p: Leaf, x: Double, y: Double, w: Double, h: Double, seed: UInt64) {
    let ring = [pt(x, y), pt(x + w, y), pt(x + w, y + h), pt(x, y + h)]
    wash(p, ring, Pot.soil, strength: 0.55, bleed: 3, seed: seed)
    grit(p, pathOf(ring), density: 0.010, sizeMin: 0.8, sizeMax: 2.2, colour: Pot.soilDark, seed: seed &+ 1)
    let board = [pt(x - 8, y - 8), pt(x + w + 8, y - 8), pt(x + w + 8, y + h + 8), pt(x, y + h + 8)]
    penEdge(p, board, weight: 5, colour: Pot.woodDark, seed: seed &+ 2)
    penEdge(p, ring, weight: 2, colour: Pot.ink.al(0.6), seed: seed &+ 3)
}

func drawLessonFigure(_ p: Leaf, _ index: Int, seed: UInt64) {
    var rng = Chip(seed)
    switch index {
    case 0:
        yearRuler(p, x0: 140, x1: 1060, y: 420, lastFrost: 0.25, firstFrost: 0.83, seed: seed)
        cropBar(p, x0: 140, x1: 1060, y: 520, from: 0.10, to: 0.21, tone: Pot.leafPale, label: "peas", seed: seed &+ 40)
        cropBar(p, x0: 140, x1: 1060, y: 570, from: 0.27, to: 0.31, tone: Pot.tomato.lt(0.3), label: "tomatoes out", seed: seed &+ 41)
        cropBar(p, x0: 140, x1: 1060, y: 620, from: 0.72, to: 0.80, tone: Pot.white.dk(0.15), label: "garlic in", seed: seed &+ 42)
        for k in 0..<3 {
            let x = 200.0 + Double(k) * 70
            for j in 0..<6 {
                let a = Double(j) / 6 * 2 * Double.pi
                pen(p, [pt(x, 250), pt(x + cos(a) * 28, 250 + sin(a) * 28)], weight: 2.2, colour: Pot.frostDeep.al(0.8), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 7 + j + 60))
            }
        }
        letter(p, "Counted from two nights, not from a month on the calendar", at: 600, 300, size: 24, colour: Pot.inkSoft, face: "Baskerville-Italic", align: .centre)
    case 1:
        let bench = [pt(200, 560), pt(760, 560), pt(760, 590), pt(200, 590)]
        wash(p, bench, Pot.wood, strength: 0.6, bleed: 3, seed: seed)
        crossHatch(p, pathOf(bench), depth: 1, spacing: 5, colour: Pot.woodDark, seed: seed &+ 1)
        penEdge(p, bench, weight: 3, colour: Pot.ink, seed: seed &+ 2)
        for x in [230.0, 730.0] {
            pen(p, [pt(x, 590), pt(x, 690)], weight: 12, colour: Pot.woodDark, wobble: 0.5, taper: false, seed: seed &+ UInt64(Int(x)))
        }
        for k in 0..<4 {
            potWithSeedling(p, at: pt(280 + Double(k) * 140, 500), size: 80, tone: k % 2 == 0 ? Pot.leaf : Pot.leafPale, seed: seed &+ UInt64(k * 11 + 10))
        }
        let frame = [pt(820, 470), pt(1080, 420), pt(1080, 600), pt(820, 600)]
        wash(p, frame, Pot.wood, strength: 0.55, bleed: 3, seed: seed &+ 30)
        penEdge(p, frame, weight: 3, colour: Pot.ink, seed: seed &+ 31)
        let lid = [pt(820, 470), pt(1080, 420), pt(1040, 330), pt(790, 380)]
        wash(p, lid, Pot.glass, strength: 0.5, bleed: 2, seed: seed &+ 32)
        penEdge(p, lid, weight: 2.4, colour: Pot.ink, seed: seed &+ 33)
        pen(p, [pt(860, 462), pt(1000, 436)], weight: 2, colour: Pot.white.al(0.7), wobble: 0.3, taper: true, seed: seed &+ 34)
        pen(p, [pt(1040, 330), pt(1040, 420)], weight: 5, colour: Pot.woodDark, wobble: 0.4, taper: false, seed: seed &+ 35)
        daisy(p, at: pt(180, 220), r: 60, petals: 12, petalTone: Pot.yellow.lt(0.2), centreTone: Pot.yellow, petalWidth: 0.25, seed: seed &+ 50)
        letter(p, "days out, nights in, for a week", at: 480, 300, size: 24, colour: Pot.inkSoft, face: "Baskerville-Italic", align: .centre)
        pen(p, [pt(330, 330), pt(560, 330), pt(540, 316)], weight: 2.4, colour: Pot.inkSoft, wobble: 0.3, taper: false, seed: seed &+ 60)
        pen(p, [pt(560, 330), pt(540, 344)], weight: 2.4, colour: Pot.inkSoft, wobble: 0.3, taper: false, seed: seed &+ 61)
    case 2:
        let tray = [pt(150, 520), pt(520, 520), pt(500, 600), pt(170, 600)]
        wash(p, tray, Pot.ink.lt(0.3), strength: 0.55, bleed: 2, seed: seed)
        penEdge(p, tray, weight: 2.6, colour: Pot.ink, seed: seed &+ 1)
        for k in 0..<5 {
            let x = 190.0 + Double(k) * 72
            pen(p, [pt(x, 522), pt(x - 6, 598)], weight: 1.4, colour: Pot.ink.al(0.5), wobble: 0.2, taper: false, seed: seed &+ UInt64(k + 5))
            seedlingVignette(p, at: pt(x + 36, 526), tone: Pot.leaf, monocot: false, seed: seed &+ UInt64(k * 3 + 20))
        }
        let lamp = [pt(250, 250), pt(420, 250), pt(460, 300), pt(210, 300)]
        wash(p, lamp, Pot.ink.lt(0.2), strength: 0.7, bleed: 2, seed: seed &+ 40)
        penEdge(p, lamp, weight: 2.4, colour: Pot.ink, seed: seed &+ 41)
        pen(p, [pt(335, 180), pt(335, 250)], weight: 5, colour: Pot.ink, wobble: 0.3, taper: false, seed: seed &+ 42)
        wash(p, [pt(210, 300), pt(460, 300), pt(560, 520), pt(110, 520)], Pot.yellow, strength: 0.18, bleed: 8, seed: seed &+ 43)
        letter(p, "indoors, 6 to 8 weeks before", at: 335, 660, size: 22, colour: Pot.inkSoft, face: "Baskerville-Italic", align: .centre)
        soilBand(p, y: 520, depth: 90, x0: 640, x1: 1080, seed: seed &+ 60)
        pen(p, [pt(660, 520), pt(1060, 520)], weight: 3, colour: Pot.soilDark, wobble: 1.2, taper: false, seed: seed &+ 61)
        wash(p, [pt(660, 512), pt(1060, 512), pt(1060, 530), pt(660, 530)], Pot.soilDark, strength: 0.5, bleed: 3, seed: seed &+ 62)
        for k in 0..<8 {
            let x = 690.0 + Double(k) * 50
            p.dot(x, 522, 5, Pot.sepia)
            p.hoop(x, 522, 5, 1, Pot.ink.al(0.6))
        }
        let hand = stemRun(pt(1040, 380), Double.pi / 2 + 0.6, 120, curve: -0.3, wobble: 0.02, steps: 6, seed: seed &+ 70)
        pen(p, hand, weight: 8, colour: Pot.wood, wobble: 0.4, taper: true, seed: seed &+ 71)
        for k in 0..<4 {
            let q = pt(Double(hand[hand.count - 1].x) + Double(k - 1) * 4, Double(hand[hand.count - 1].y) + Double(k) * 6)
            p.dot(Double(q.x), Double(q.y), 4.5, Pot.sepia)
        }
        letter(p, "direct, in a drill, when the soil is ready", at: 860, 660, size: 22, colour: Pot.inkSoft, face: "Baskerville-Italic", align: .centre)
    case 3:
        pen(p, [pt(120, 620), pt(1080, 620)], weight: 3, colour: Pot.ink, wobble: 0.5, taper: false, seed: seed)
        let stages = ["day 0", "day 20", "day 40", "day 60", "day 80"]
        for (k, label) in stages.enumerated() {
            let x = 200.0 + Double(k) * 200
            pen(p, [pt(x, 612), pt(x, 630)], weight: 2, colour: Pot.ink, wobble: 0.3, taper: false, seed: seed &+ UInt64(k))
            letter(p, label, at: x, 660, size: 20, colour: Pot.inkPale, face: "Baskerville", align: .centre)
            switch k {
            case 0:
                p.dot(x, 600, 6, Pot.sepia)
                p.hoop(x, 600, 6, 1, Pot.ink.al(0.6))
            case 1:
                seedlingVignette(p, at: pt(x, 606), tone: Pot.leafPale, monocot: false, seed: seed &+ 20)
            case 2:
                p.ctx.saveGState()
                p.ctx.translateBy(x: CGFloat(x - plantX * 0.28), y: CGFloat(606 - (groundY + 10) * 0.28))
                p.ctx.scaleBy(x: 0.28, y: 0.28)
                let spine = mainStem(p, top: 450, w0: 14, w1: 8, tone: Pot.leaf.dk(0.15), seed: seed &+ 30)
                for j in 0..<5 {
                    let q = along(spine, 0.3 + Double(j) * 0.15)
                    pinnateLeaf(p, base: q, angle: j % 2 == 0 ? -2.6 : -0.5, length: 120, tone: Pot.leaf, leaflets: 5, leafletSize: 44, serrate: 0.5, seed: seed &+ UInt64(j * 7 + 31))
                }
                p.ctx.restoreGState()
            default:
                p.ctx.saveGState()
                p.ctx.translateBy(x: CGFloat(x - plantX * 0.30), y: CGFloat(606 - (groundY + 10) * 0.30))
                p.ctx.scaleBy(x: 0.30, y: 0.30)
                drawCropFigure(p, Register.find("tomato"))
                if k == 3 {
                    wash(p, [pt(100, 200), pt(800, 200), pt(800, 900), pt(100, 900)], Pot.creamWarm, strength: 0.35, bleed: 1, seed: seed &+ 50)
                }
                p.ctx.restoreGState()
            }
        }
        letter(p, "counted from the day it goes into its final bed", at: 600, 300, size: 24, colour: Pot.inkSoft, face: "Baskerville-Italic", align: .centre)
    case 4:
        let gx = 240.0, gy = 210.0, cell = 150.0
        bedBox(p, x: gx, y: gy, w: cell * 4, h: cell * 3, seed: seed)
        for k in 0...4 { pen(p, [pt(gx + Double(k) * cell, gy), pt(gx + Double(k) * cell, gy + cell * 3)], weight: 2, colour: Pot.strawPale.al(0.9), wobble: 0.4, taper: false, seed: seed &+ UInt64(k + 10)) }
        for k in 0...3 { pen(p, [pt(gx, gy + Double(k) * cell), pt(gx + cell * 4, gy + Double(k) * cell)], weight: 2, colour: Pot.strawPale.al(0.9), wobble: 0.4, taper: false, seed: seed &+ UInt64(k + 20)) }
        let layouts: [(Int, Int, Int, Hue)] = [(0, 0, 1, Pot.leafDeep), (1, 0, 4, Pot.leaf), (2, 0, 9, Pot.leafPale), (3, 0, 16, Pot.leafBlue)]
        for (c, r, n, tone) in layouts {
            let side = Int(Double(n).squareRoot().rounded())
            for i in 0..<side {
                for j in 0..<side {
                    let px = gx + Double(c) * cell + cell * (Double(i) + 0.5) / Double(side)
                    let py = gy + Double(r) * cell + cell * (Double(j) + 0.5) / Double(side)
                    let rad = cell * 0.36 / Double(side)
                    for m in 0..<6 {
                        let a = Double(m) / 6 * 2 * Double.pi
                        blade(p, base: pt(px, py), angle: a, length: rad * 1.5, width: rad * 0.7, tone: m % 2 == 0 ? tone : tone.dk(0.1), serrate: 0, curl: 0, veins: 1, seed: seed &+ UInt64(c * 97 + i * 13 + j * 7 + m))
                    }
                }
            }
            letter(p, "\(n)", at: gx + Double(c) * cell + cell / 2, gy + cell * 3 + 40, size: 26, colour: Pot.ink, face: "Baskerville-Bold", align: .centre)
            letter(p, ["12 in", "6 in", "4 in", "3 in"][c], at: gx + Double(c) * cell + cell / 2, gy + cell * 3 + 70, size: 18, colour: Pot.inkPale, face: "Baskerville-Italic", align: .centre)
        }
        for c in 0..<4 {
            let names = ["tomato", "lettuce", "beet", "carrot"]
            miniature(p, Register.find(names[c]), at: pt(gx + Double(c) * cell + cell / 2, gy + cell * 2.9), scale: 0.17)
        }
        letter(p, "one square foot, and how many of each fit inside it", at: 600, 160, size: 24, colour: Pot.inkSoft, face: "Baskerville-Italic", align: .centre)
    case 5:
        for row in 0..<3 {
            let y = 300.0 + Double(row) * 150
            bedBox(p, x: 200, y: y - 40, w: 800, h: 90, seed: seed &+ UInt64(row))
            let scale = [0.34, 0.22, 0.10][row]
            for k in 0..<6 {
                let x = 260.0 + Double(k) * 140
                p.ctx.saveGState()
                p.ctx.translateBy(x: CGFloat(x - plantX * scale), y: CGFloat(y + 40 - (groundY + 10) * scale))
                p.ctx.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
                if row == 2 {
                    seedlingVignette(p, at: pt(plantX, groundY), tone: Pot.leafPale, monocot: false, seed: seed &+ UInt64(k * 5 + 40))
                } else {
                    sideRosette(p, crown: pt(plantX, groundY - 8), radius: row == 0 ? 280 : 200, tone: Pot.leafPale, layers: row == 0 ? 3 : 2, crinkle: true, seed: seed &+ UInt64(row * 31 + k * 7))
                }
                p.ctx.restoreGState()
            }
            letter(p, ["sown six weeks ago", "sown four weeks ago", "sown two weeks ago"][row], at: 1030, y + 10, size: 20, colour: Pot.inkSoft, face: "Baskerville-Italic", align: .left)
        }
        letter(p, "a short row every fortnight keeps a cutting coming every week", at: 600, 200, size: 24, colour: Pot.inkSoft, face: "Baskerville-Italic", align: .centre)
    case 6:
        let c = pt(600, 420)
        let names = ["Legume", "Brassica", "Root and Umbel", "Nightshade"]
        let crops = ["pea", "cabbage", "carrot", "tomato"]
        let tones = [Pot.leafPale, Pot.leafBlue, Pot.carrot.lt(0.2), Pot.tomato.lt(0.3)]
        for k in 0..<4 {
            let a = -Double.pi / 2 + Double(k) / 4 * 2 * Double.pi
            let bx = Double(c.x) + cos(a) * 320, by = Double(c.y) + sin(a) * 170
            bedBox(p, x: bx - 110, y: by - 60, w: 220, h: 120, seed: seed &+ UInt64(k))
            wash(p, [pt(bx - 106, by - 56), pt(bx + 106, by - 56), pt(bx + 106, by + 56), pt(bx - 106, by + 56)], tones[k], strength: 0.25, bleed: 4, seed: seed &+ UInt64(k + 10))
            miniature(p, Register.find(crops[k]), at: pt(bx, by + 40), scale: 0.16)
            letter(p, names[k], at: bx, by + 92, size: 20, colour: Pot.ink, face: "Baskerville-Bold", align: .centre)
            let a2 = a + Double.pi / 4
            let ax = Double(c.x) + cos(a2) * 320, ay = Double(c.y) + sin(a2) * 170
            let arrow = stemRun(pt(ax - cos(a2 + 1.5) * 40, ay - sin(a2 + 1.5) * 28), a2 + 1.55, 70, curve: 0.5, wobble: 0.02, steps: 6, seed: seed &+ UInt64(k * 3 + 50))
            pen(p, arrow, weight: 3, colour: Pot.inkSoft, wobble: 0.3, taper: true, seed: seed &+ UInt64(k + 60))
            let tip = arrow[arrow.count - 1], prev = arrow[arrow.count - 2]
            let d = atan2(Double(tip.y - prev.y), Double(tip.x - prev.x))
            pen(p, [pt(Double(tip.x) - cos(d - 0.5) * 16, Double(tip.y) - sin(d - 0.5) * 16), tip, pt(Double(tip.x) - cos(d + 0.5) * 16, Double(tip.y) - sin(d + 0.5) * 16)], weight: 3, colour: Pot.inkSoft, wobble: 0.3, taper: false, seed: seed &+ UInt64(k + 70))
        }
        letter(p, "next season", at: Double(c.x), Double(c.y) + 8, size: 22, colour: Pot.inkPale, face: "Baskerville-Italic", align: .centre)
    case 7:
        bedBox(p, x: 160, y: 300, w: 560, h: 260, seed: seed)
        miniature(p, Register.find("tomato"), at: pt(330, 540), scale: 0.36)
        miniature(p, Register.find("basil"), at: pt(520, 540), scale: 0.26)
        miniature(p, Register.find("marigold"), at: pt(640, 545), scale: 0.22)
        letter(p, "tomato, basil, marigold", at: 440, 610, size: 22, colour: Pot.ink, face: "Baskerville", align: .centre)
        bedBox(p, x: 820, y: 300, w: 240, h: 260, seed: seed &+ 5)
        miniature(p, Register.find("fennel"), at: pt(940, 545), scale: 0.26)
        pen(p, [pt(860, 330), pt(1020, 530)], weight: 6, colour: Pot.tomato.dk(0.2).al(0.75), wobble: 0.5, taper: false, seed: seed &+ 20)
        pen(p, [pt(1020, 330), pt(860, 530)], weight: 6, colour: Pot.tomato.dk(0.2).al(0.75), wobble: 0.5, taper: false, seed: seed &+ 21)
        letter(p, "fennel, alone", at: 940, 610, size: 22, colour: Pot.ink, face: "Baskerville", align: .centre)
        letter(p, "a companion beside the square, an antagonist kept a bed away", at: 600, 220, size: 24, colour: Pot.inkSoft, face: "Baskerville-Italic", align: .centre)
    case 8:
        bedBox(p, x: 180, y: 480, w: 700, h: 130, seed: seed)
        for k in 0..<160 {
            let x = rng.r(190, 870), y = rng.r(486, 606)
            pen(p, [pt(x, y), pt(x + rng.r(-16, 16), y + rng.r(-6, 6))], weight: rng.r(1.4, 2.4), colour: Pot.straw.dk(rng.r(0, 0.3)).al(0.85), wobble: 0.4, taper: true, seed: seed &+ UInt64(k + 10))
        }
        miniature(p, Register.find("tomato"), at: pt(330, 560), scale: 0.36)
        miniature(p, Register.find("pepper"), at: pt(560, 560), scale: 0.32)
        miniature(p, Register.find("basil"), at: pt(760, 560), scale: 0.26)
        wateringCan(p, at: pt(990, 330), size: 140, seed: seed &+ 50)
        letter(p, "straw over the soil, water at the root", at: 520, 700, size: 24, colour: Pot.inkSoft, face: "Baskerville-Italic", align: .centre)
    case 9:
        soilBand(p, y: 560, depth: 80, x0: 140, x1: 1060, seed: seed)
        for k in 0..<240 {
            p.dot(rng.r(150, 1050), rng.r(548, 562), rng.r(0.8, 2.2), Pot.white.al(rng.r(0.4, 0.9)))
        }
        let cloche = ringOf(cx: 380, cy: 560, rx: 190, ry: 150, steps: 40)
        let dome = Array(cloche[20...39]) + [cloche[0]]
        wash(p, dome + [pt(570, 560), pt(190, 560)], Pot.glass, strength: 0.42, bleed: 3, seed: seed &+ 10)
        pen(p, dome, weight: 3, colour: Pot.ink.al(0.85), wobble: 0.5, taper: false, seed: seed &+ 11)
        pen(p, [pt(230, 470), pt(300, 430)], weight: 2.4, colour: Pot.white.al(0.8), wobble: 0.3, taper: true, seed: seed &+ 12)
        for k in 0..<3 {
            miniature(p, Register.find("spinach"), at: pt(290 + Double(k) * 90, 566), scale: 0.16)
        }
        miniature(p, Register.find("kale"), at: pt(720, 566), scale: 0.3)
        for k in 0..<7 {
            let a = Double(k) / 7 * 2 * Double.pi
            pen(p, [pt(720, 300), pt(720 + cos(a) * 30, 300 + sin(a) * 30)], weight: 2.2, colour: Pot.frostDeep.al(0.8), wobble: 0.3, taper: true, seed: seed &+ UInt64(k + 30))
        }
        seedVignette(p, at: pt(940, 610), kind: "clove", tone: Pot.white.dk(0.05), seed: seed &+ 40)
        letter(p, "garlic in", at: 940, 690, size: 20, colour: Pot.inkPale, face: "Baskerville-Italic", align: .centre)
        letter(p, "sown in late summer, counted back from the first frost", at: 600, 200, size: 24, colour: Pot.inkSoft, face: "Baskerville-Italic", align: .centre)
    case 10:
        for k in 0..<3 {
            let x = 220.0 + Double(k) * 170, y = 480.0
            let env = [pt(x - 70, y - 50), pt(x + 70, y - 50), pt(x + 70, y + 50), pt(x - 70, y + 50)]
            wash(p, env, Pot.strawPale.lt(0.3), strength: 0.7, bleed: 2, seed: seed &+ UInt64(k))
            penEdge(p, env, weight: 2.2, colour: Pot.ink.al(0.8), seed: seed &+ UInt64(k + 3))
            pen(p, [pt(x - 70, y - 50), pt(x, y), pt(x + 70, y - 50)], weight: 1.8, colour: Pot.ink.al(0.7), wobble: 0.3, taper: false, seed: seed &+ UInt64(k + 6))
            letter(p, ["Bean 2025", "Tomato", "Lettuce"][k], at: x, y + 34, size: 16, colour: Pot.inkSoft, face: "Baskerville-Italic", align: .centre)
        }
        let jar = [pt(760, 380), pt(900, 380), pt(910, 400), pt(910, 600), pt(750, 600), pt(750, 400)]
        wash(p, jar, Pot.glass, strength: 0.35, bleed: 2, seed: seed &+ 20)
        penEdge(p, jar, weight: 2.6, colour: Pot.ink.al(0.85), seed: seed &+ 21)
        p.box(756, 366, 148, 16, Pot.inkSoft)
        p.inside(pathOf(jar)) {
            for k in 0..<60 {
                let ring = lumpy(cx: rng.r(760, 900), cy: rng.r(470, 596), rx: 12, ry: 7, rough: 0.06, steps: 14, seed: seed &+ UInt64(k + 40))
                p.shape(ring, Pot.beet.mix(Pot.sepia, 0.4).lt(rng.r(0, 0.2)))
                penOutline(p, ring, weight: 1, colour: Pot.ink.al(0.5), seed: seed &+ UInt64(k + 100))
            }
        }
        let saucer = ringOf(cx: 1040, cy: 560, rx: 90, ry: 30, steps: 30)
        wash(p, saucer, Pot.white, strength: 0.7, bleed: 2, seed: seed &+ 200)
        penEdge(p, saucer, weight: 2, colour: Pot.ink.al(0.7), seed: seed &+ 201)
        for k in 0..<18 {
            let ring = lumpy(cx: rng.r(980, 1100), cy: rng.r(548, 572), rx: 5, ry: 3.5, rough: 0.1, steps: 10, seed: seed &+ UInt64(k + 300))
            p.shape(ring, Pot.strawPale.dk(0.2))
        }
        fruitRound(p, at: pt(1040, 440), r: 44, tone: Pot.tomato, rough: 0.03, gloss: 0.6, seed: seed &+ 400)
        letter(p, "dried, labelled, kept cool; self-pollinators come true", at: 600, 220, size: 24, colour: Pot.inkSoft, face: "Baskerville-Italic", align: .centre)
    default:
        bedBox(p, x: 160, y: 430, w: 880, h: 200, seed: seed)
        for k in 0..<140 {
            let x = rng.r(170, 1030)
            let h = rng.r(40, 110)
            let blade = stemRun(pt(x, 630), -Double.pi / 2 + rng.r(-0.25, 0.25), h, curve: rng.r(-0.4, 0.4), wobble: 0.04, steps: 5, seed: seed &+ UInt64(k * 3))
            pen(p, blade, weight: rng.r(1.6, 3.2), colour: (k % 3 == 0 ? Pot.leafPale : Pot.leaf).dk(rng.r(0, 0.2)), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 5 + 1))
            if k % 9 == 0 {
                let top = blade[blade.count - 1]
                for j in 0..<3 {
                    blade2(p, at: top, angle: -Double.pi / 2 + Double(j - 1) * 0.9, tone: Pot.leaf, seed: seed &+ UInt64(k * 7 + j))
                }
            }
        }
        let fork = [pt(1010, 280), pt(980, 470)]
        pen(p, fork, weight: 9, colour: Pot.wood, wobble: 0.4, taper: false, seed: seed &+ 50)
        pen(p, [pt(996, 250), pt(1024, 250)], weight: 9, colour: Pot.wood, wobble: 0.3, taper: false, seed: seed &+ 51)
        pen(p, [pt(1010, 250), pt(1010, 282)], weight: 7, colour: Pot.wood, wobble: 0.3, taper: false, seed: seed &+ 52)
        for k in 0..<4 {
            let x = 956.0 + Double(k) * 16
            pen(p, [pt(x, 470), pt(x - 6, 560)], weight: 4, colour: Pot.inkSoft, wobble: 0.3, taper: false, seed: seed &+ UInt64(k + 60))
        }
        pen(p, [pt(950, 470), pt(1006, 470)], weight: 6, colour: Pot.inkSoft, wobble: 0.3, taper: false, seed: seed &+ 64)
        letter(p, "rye and clover through the winter, dug in before spring", at: 600, 200, size: 24, colour: Pot.inkSoft, face: "Baskerville-Italic", align: .centre)
    }
}

func blade2(_ p: Leaf, at c: CGPoint, angle: Double, tone: Hue, seed: UInt64) {
    blade(p, base: c, angle: angle, length: 22, width: 12, tone: tone, serrate: 0, curl: 0, veins: 1, seed: seed)
}

func drawLessonPlate(_ index: Int, _ key: String, dir: String) {
    let p = Leaf(1200, 900)
    let seed = hashOf("lesson-" + key)
    layPaper(p, seed: seed, tone: Pot.creamWarm)
    p.flipDown()
    p.light = -2.36
    borderRule(p, inset: 30, seed: seed &+ 3)
    drawLessonFigure(p, index, seed: seed &+ 7)
    let title = lessonTitles[index]
    plateCaption(p, title: title.0, sub: title.1, y: 740, titleSize: 40)
    p.writeJPG(dir, "ls_" + key)
}
