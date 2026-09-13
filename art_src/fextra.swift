import Foundation
import CoreGraphics

let extraLessonKeys: [String] = ["pests", "frostcover", "watering", "seedkeeping"]

let extraLessonTitles: [(String, String)] = [
    ("Pests Without Poison", "Look daily, cover early, pick by hand, and let the predators work"),
    ("Frost Protection", "Reading a frost night, and what to throw over the tender crops"),
    ("Reading Thirst", "How much, how often, and the weeks when it decides the crop"),
    ("Keeping Seed", "The germination test, the years a packet lasts, and the January order")
]

func meshOver(_ p: Leaf, x0: Double, x1: Double, top: Double, base: Double, seed: UInt64) {
    var rng = Chip(seed)
    let hoops = 4
    for k in 0..<hoops {
        let hx = x0 + (x1 - x0) * Double(k) / Double(hoops - 1)
        let arc = ringOf(cx: hx, cy: base, rx: 60, ry: base - top, steps: 40)
        pen(p, Array(arc[21...39]), weight: 3.5, colour: Pot.inkSoft, wobble: 0.3, taper: false, seed: seed &+ UInt64(k))
    }
    let cover = [pt(x0 - 60, base), pt(x0 - 40, top + 20), pt(x0, top), pt(x1, top), pt(x1 + 40, top + 20), pt(x1 + 60, base)]
    wash(p, cover, Pot.white, strength: 0.42, bleed: 3, seed: seed &+ 10)
    p.inside(pathOf(cover)) {
        var x = x0 - 60.0
        while x < x1 + 60 {
            pen(p, [pt(x, top), pt(x - 10, base)], weight: 0.7, colour: Pot.ink.al(0.25), wobble: 0.2, taper: false, seed: seed &+ UInt64(Int(x)))
            x += 9
        }
        var y = top
        while y < base {
            pen(p, [pt(x0 - 60, y), pt(x1 + 60, y + 1)], weight: 0.7, colour: Pot.ink.al(0.25), wobble: 0.2, taper: false, seed: seed &+ UInt64(Int(y) + 500))
            y += 9
        }
    }
    penOutline(p, cover, weight: 1.8, colour: Pot.ink.al(0.7), seed: seed &+ 20)
    for k in 0..<6 {
        let px = x0 - 40 + (x1 - x0 + 80) * Double(k) / 5
        pen(p, [pt(px, base), pt(px + rng.r(-3, 3), base + 14)], weight: 3, colour: Pot.woodDark, wobble: 0.2, taper: false, seed: seed &+ UInt64(k + 30))
    }
}

func hoverfly(_ p: Leaf, at c: CGPoint, size: Double, seed: UInt64) {
    let cx = Double(c.x), cy = Double(c.y)
    let body = bandOf([pt(cx - size * 0.5, cy), pt(cx + size * 0.5, cy)], [size * 0.18, size * 0.3, size * 0.12], per: 6)
    produce(p, body, tone: Pot.yellow, gloss: 0.4, seed: seed)
    p.inside(pathOf(body)) {
        for k in 0..<4 {
            let bx = cx - size * 0.2 + Double(k) * size * 0.16
            pen(p, [pt(bx, cy - size * 0.2), pt(bx, cy + size * 0.2)], weight: size * 0.06, colour: Pot.ink, wobble: 0.1, taper: false, seed: seed &+ UInt64(k))
        }
    }
    for side in [-1.0, 1.0] {
        let wing = lumpy(cx: cx - size * 0.1, cy: cy + side * size * 0.24, rx: size * 0.42, ry: size * 0.13, rough: 0.05, steps: 14, seed: seed &+ UInt64(side > 0 ? 5 : 6))
        let rot = rotatedRing(wing, about: pt(cx - size * 0.35, cy), side * 0.4)
        wash(p, rot, Pot.glass.lt(0.3), strength: 0.5, bleed: 1, seed: seed &+ 7)
        penOutline(p, rot, weight: 0.8, colour: Pot.ink.al(0.6), seed: seed &+ 8)
    }
    p.dot(cx - size * 0.55, cy, size * 0.12, Pot.ink.lt(0.2))
}

func fleeceOver(_ p: Leaf, x0: Double, x1: Double, top: Double, base: Double, seed: UInt64) {
    var rng = Chip(seed)
    var ring: [CGPoint] = [pt(x0 - 30, base + 6)]
    var x = x0 - 30.0
    while x <= x1 + 30 {
        let t = (x - (x0 - 30)) / (x1 - x0 + 60)
        ring.append(pt(x, top + (base - top) * 0.15 * (1 - sin(t * .pi)) + rng.r(-4, 4)))
        x += 30
    }
    ring.append(pt(x1 + 30, base + 6))
    wash(p, ring, Pot.white, strength: 0.88, bleed: 5, seed: seed)
    p.inside(pathOf(ring)) {
        for k in 0..<12 {
            let fx = x0 - 20 + (x1 - x0 + 40) * Double(k) / 11
            pen(p, [pt(fx, top + 10), pt(fx + rng.r(-10, 10), base)], weight: 1.4, colour: Pot.frost.dk(0.1).al(0.4), wobble: 0.8, taper: true, seed: seed &+ UInt64(k + 10))
        }
    }
    roundShade(p, ring, inset: 40, depth: 1, spacing: 6, colour: Pot.frostDeep.al(0.35), seed: seed &+ 30)
    penOutline(p, ring, weight: 2, colour: Pot.ink.al(0.6), seed: seed &+ 31)
}

func upturnedPot(_ p: Leaf, at c: CGPoint, size: Double, seed: UInt64) {
    let cx = Double(c.x), cy = Double(c.y)
    let ring = [pt(cx - size * 0.32, cy - size * 0.7), pt(cx + size * 0.32, cy - size * 0.7), pt(cx + size * 0.5, cy), pt(cx - size * 0.5, cy)]
    wash(p, ring, Pot.terracotta, strength: 0.7, bleed: 2, seed: seed)
    crossHatch(p, pathOf(ring), depth: 2, spacing: 4.5, colour: Pot.terraDeep.dk(0.2), seed: seed &+ 1)
    penEdge(p, ring, weight: 2.2, colour: Pot.ink.al(0.8), seed: seed &+ 2)
    p.box(cx - size * 0.34, cy - size * 0.76, size * 0.68, size * 0.09, Pot.terraDeep.al(0.9))
    p.dot(cx, cy - size * 0.71, size * 0.05, Pot.ink)
}

func seedEnvelope(_ p: Leaf, at c: CGPoint, w: Double, h: Double, tilt: Double, label: String, year: String, seed: UInt64) {
    let cx = Double(c.x), cy = Double(c.y)
    let ring = rotatedRing([pt(cx - w / 2, cy - h / 2), pt(cx + w / 2, cy - h / 2), pt(cx + w / 2, cy + h / 2), pt(cx - w / 2, cy + h / 2)], about: c, tilt)
    p.shape(offsetRing(ring, 4, 5), Pot.shadowInk.al(0.15))
    wash(p, ring, Pot.creamWarm.lt(0.3), strength: 0.97, bleed: 1.5, seed: seed)
    penEdge(p, ring, weight: 1.6, colour: Pot.ink.al(0.8), seed: seed &+ 1)
    let flap = rotatedRing([pt(cx - w / 2, cy - h / 2), pt(cx + w / 2, cy - h / 2), pt(cx, cy - h / 2 + h * 0.3)], about: c, tilt)
    penEdge(p, flap, weight: 1.0, colour: Pot.ink.al(0.5), seed: seed &+ 2)
    letter(p, label, at: cx, cy + 6, size: h * 0.2, colour: Pot.ink, face: "Baskerville-Italic", align: .centre, rotate: tilt)
    letter(p, year, at: cx, cy + h * 0.34, size: h * 0.16, colour: Pot.terracotta, face: "Baskerville", align: .centre, rotate: tilt)
}

func drawExtraLessonFigure(_ p: Leaf, _ key: String, seed: UInt64) {
    var rng = Chip(seed)
    switch key {
    case "pests":
        bedBox(p, x: 160, y: 430, w: 560, h: 200, seed: seed)
        for k in 0..<6 {
            miniature(p, Register.find("cabbage"), at: pt(210 + Double(k) * 92, 560), scale: 0.13)
        }
        meshOver(p, x0: 200, x1: 680, top: 330, base: 440, seed: seed &+ 10)
        let calendulaBase = pt(860, 640)
        let st = stemRun(calendulaBase, -Double.pi / 2 + 0.1, 220, curve: -0.2, wobble: 0.02, steps: 8, seed: seed &+ 20)
        stem(p, st, w0: 8, w1: 5, tone: Pot.leafPale, seed: seed &+ 21)
        for k in 0..<3 {
            blade(p, base: along(st, 0.3 + Double(k) * 0.2), angle: -Double.pi / 2 + (k % 2 == 0 ? -1.0 : 1.0), length: 60, width: 20, tone: Pot.leafPale, serrate: 0, curl: 0, veins: 2, seed: seed &+ UInt64(k + 30))
        }
        daisy(p, at: st[st.count - 1], r: 52, petals: 16, petalTone: Pot.yellow.mix(Pot.pumpkin, 0.3), centreTone: Pot.pumpkin.dk(0.2), petalWidth: 0.3, seed: seed &+ 40)
        hoverfly(p, at: pt(930, 380), size: 40, seed: seed &+ 50)
        hoverfly(p, at: pt(1000, 470), size: 34, seed: seed &+ 51)
        let board = [pt(760, 610), pt(1060, 600), pt(1064, 626), pt(764, 636)]
        wash(p, board, Pot.wood, strength: 0.85, bleed: 2, seed: seed &+ 60)
        penEdge(p, board, weight: 2, colour: Pot.ink.al(0.8), seed: seed &+ 61)
        slug(p, at: pt(800, 660), angle: 0.1, length: 70, tone: Pot.sepia.mix(Pot.straw, 0.4), seed: seed &+ 62)
        slug(p, at: pt(930, 662), angle: 0.2, length: 60, tone: Pot.ink.lt(0.3), seed: seed &+ 63)
        letter(p, "Barrier first, hand second, predators always", at: 600, 260, size: 24, colour: Pot.inkSoft, face: "Baskerville-Italic", align: .centre)
    case "frostcover":
        let sky = [pt(60, 120), pt(1140, 120), pt(1140, 400), pt(60, 400)]
        p.gradientRect(CGRect(x: 60, y: 120, width: 1080, height: 300), Hue(r: 0.16, g: 0.18, b: 0.34), Hue(r: 0.86, g: 0.62, b: 0.42))
        for _ in 0..<60 { p.dot(rng.r(80, 1120), rng.r(130, 280), rng.r(0.8, 2), Pot.white.al(rng.r(0.4, 0.9))) }
        penEdge(p, sky, weight: 2, colour: Pot.ink.al(0.5), seed: seed &+ 1)
        p.dot(980, 200, 30, Hue(r: 0.94, g: 0.93, b: 0.86))
        p.dot(994, 190, 27, Hue(r: 0.22, g: 0.23, b: 0.40))
        soilBand(p, y: 560, depth: 90, x0: 100, x1: 1100, seed: seed &+ 5)
        for _ in 0..<300 { p.dot(rng.r(110, 1090), rng.r(550, 572), rng.r(0.8, 2.2), Pot.white.al(rng.r(0.4, 0.9))) }
        for k in 0..<4 {
            miniature(p, Register.find("bushbean"), at: pt(240 + Double(k) * 90, 540), scale: 0.13)
        }
        fleeceOver(p, x0: 190, x1: 560, top: 440, base: 556, seed: seed &+ 10)
        miniature(p, Register.find("kale"), at: pt(700, 540), scale: 0.15)
        upturnedPot(p, at: pt(860, 556), size: 120, seed: seed &+ 20)
        let cloche = [pt(940, 556), pt(960, 470), pt(1040, 470), pt(1060, 556)]
        wash(p, cloche, Pot.glass.lt(0.2), strength: 0.5, bleed: 2, seed: seed &+ 30)
        penEdge(p, cloche, weight: 2, colour: Pot.ink.al(0.7), seed: seed &+ 31)
        pen(p, [pt(972, 480), pt(966, 540)], weight: 3, colour: Pot.white.al(0.7), wobble: 0.3, taper: true, seed: seed &+ 32)
        for k in 0..<3 {
            let x = 170.0 + Double(k) * 60
            for j in 0..<6 {
                let a = Double(j) / 6 * 2 * Double.pi
                pen(p, [pt(x, 470), pt(x + cos(a) * 20, 470 + sin(a) * 20)], weight: 2, colour: Pot.frost.al(0.9), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 6 + j + 60))
            }
        }
        letter(p, "A clear, still evening: cover before sunset, uncover at dawn", at: 600, 700, size: 24, colour: Pot.inkSoft, face: "Baskerville-Italic", align: .centre)
    case "watering":
        soilBand(p, y: 520, depth: 160, x0: 120, x1: 780, seed: seed)
        wash(p, [pt(120, 520), pt(780, 520), pt(780, 560), pt(120, 560)], Pot.strawPale, strength: 0.55, bleed: 4, seed: seed &+ 1)
        wash(p, [pt(120, 560), pt(780, 560), pt(780, 680), pt(120, 680)], Pot.soilDark, strength: 0.45, bleed: 5, seed: seed &+ 2)
        letter(p, "dry", at: 150, 546, size: 18, colour: Pot.inkPale, face: "Baskerville-Italic", align: .left)
        letter(p, "damp at the second knuckle", at: 150, 600, size: 18, colour: Pot.creamWarm, face: "Baskerville-Italic", align: .left)
        let spine = stemRun(pt(450, 518), -Double.pi / 2, 300, curve: -0.1, wobble: 0.01, steps: 8, seed: seed &+ 10)
        stem(p, spine, w0: 16, w1: 9, tone: Pot.leaf, seed: seed &+ 11)
        for k in 0..<4 {
            pinnateLeaf(p, base: along(spine, 0.3 + Double(k) * 0.18), angle: -Double.pi / 2 + (k % 2 == 0 ? -1.2 : 1.2), length: 120, tone: Pot.leaf, leaflets: 5, leafletSize: 36, serrate: 0.4, seed: seed &+ UInt64(k + 20))
        }
        fruitRound(p, at: pt(430, 330), r: 30, tone: Pot.tomato, rough: 0.03, gloss: 0.6, seed: seed &+ 30)
        for k in 0..<5 {
            let root = stemRun(pt(450, 522), .pi / 2 + Double(k - 2) * 0.4, rng.r(60, 120), curve: rng.r(-0.3, 0.3), wobble: 0.1, steps: 6, seed: seed &+ UInt64(k + 40))
            pen(p, root, weight: 2, colour: Pot.strawPale.dk(0.3), wobble: 0.4, taper: true, seed: seed &+ UInt64(k + 41))
        }
        wateringCan(p, at: pt(700, 400), size: 150, seed: seed &+ 50)
        let mulch = [pt(500, 500), pt(780, 500), pt(780, 522), pt(500, 522)]
        wash(p, mulch, Pot.straw, strength: 0.7, bleed: 3, seed: seed &+ 60)
        p.inside(pathOf(mulch)) {
            for k in 0..<120 {
                let mx = rng.r(500, 780), my = rng.r(500, 522)
                pen(p, [pt(mx, my), pt(mx + rng.r(6, 16), my + rng.r(-3, 3))], weight: 1.4, colour: Pot.straw.dk(0.4).al(0.7), wobble: 0.3, taper: true, seed: seed &+ UInt64(k + 70))
            }
        }
        let gauge = [pt(900, 380), pt(1000, 380), pt(1000, 640), pt(900, 640)]
        wash(p, [pt(902, 560), pt(998, 560), pt(998, 638), pt(902, 638)], Pot.frost, strength: 0.6, bleed: 2, seed: seed &+ 80)
        wash(p, gauge, Pot.glass.lt(0.2), strength: 0.3, bleed: 1.5, seed: seed &+ 81)
        penEdge(p, gauge, weight: 2.4, colour: Pot.ink.al(0.8), seed: seed &+ 82)
        for k in 0..<6 {
            let gy = 640 - Double(k) * 44
            pen(p, [pt(900, gy), pt(k % 2 == 0 ? 930 : 918, gy)], weight: 1.6, colour: Pot.ink.al(0.7), wobble: 0.2, taper: false, seed: seed &+ UInt64(k + 90))
        }
        letter(p, "1 in", at: 1010, 602, size: 18, colour: Pot.inkSoft, face: "Baskerville", align: .left)
        letter(p, "An inch a week, at the root, in the morning", at: 600, 712, size: 24, colour: Pot.inkSoft, face: "Baskerville-Italic", align: .centre)
    default:
        let jar = [pt(180, 330), pt(460, 330), pt(470, 640), pt(170, 640)]
        wash(p, jar, Pot.glass.lt(0.2), strength: 0.3, bleed: 2, seed: seed)
        penEdge(p, jar, weight: 2.4, colour: Pot.ink.al(0.8), seed: seed &+ 1)
        let lid = [pt(170, 300), pt(470, 300), pt(470, 334), pt(170, 334)]
        wash(p, lid, Pot.straw.dk(0.2), strength: 0.85, bleed: 1.5, seed: seed &+ 2)
        penEdge(p, lid, weight: 2, colour: Pot.ink.al(0.8), seed: seed &+ 3)
        p.insideRect(CGRect(x: 175, y: 334, width: 290, height: 302)) {
            seedEnvelope(p, at: pt(250, 480), w: 100, h: 150, tilt: -0.08, label: "Carrot", year: "2026", seed: seed &+ 10)
            seedEnvelope(p, at: pt(330, 470), w: 100, h: 150, tilt: 0.05, label: "Lettuce", year: "2025", seed: seed &+ 11)
            seedEnvelope(p, at: pt(410, 485), w: 100, h: 150, tilt: 0.12, label: "Bean", year: "2024", seed: seed &+ 12)
        }
        let sachet = lumpy(cx: 240, cy: 610, rx: 40, ry: 18, rough: 0.1, steps: 14, seed: seed &+ 20)
        wash(p, sachet, Pot.white, strength: 0.9, bleed: 2, seed: seed &+ 21)
        penOutline(p, sachet, weight: 1.2, colour: Pot.ink.al(0.6), seed: seed &+ 22)
        let towel = [pt(560, 380), pt(1060, 380), pt(1060, 620), pt(560, 620)]
        wash(p, towel, Pot.white.lt(0.1), strength: 0.9, bleed: 4, seed: seed &+ 30)
        p.inside(pathOf(towel)) {
            for k in 0..<24 {
                let ty = 380 + Double(k) * 10
                pen(p, [pt(560, ty), pt(1060, ty + 1)], weight: 0.8, colour: Pot.inkPale.al(0.25), wobble: 0.3, taper: false, seed: seed &+ UInt64(k + 40))
            }
        }
        penEdge(p, towel, weight: 1.6, colour: Pot.ink.al(0.6), seed: seed &+ 31)
        for k in 0..<10 {
            let sx = 620.0 + Double(k % 5) * 100, sy = 450.0 + Double(k / 5) * 100
            let seedRing = lumpy(cx: sx, cy: sy, rx: 16, ry: 11, rough: 0.05, steps: 16, seed: seed &+ UInt64(k + 50))
            produce(p, seedRing, tone: Pot.sepia.mix(Pot.straw, 0.3), gloss: 0.3, seed: seed &+ UInt64(k + 60))
            if k < 6 {
                let sprout = stemRun(pt(sx + 12, sy - 4), rng.r(-1.2, -0.3), rng.r(28, 44), curve: rng.r(-0.8, 0.8), wobble: 0.05, steps: 5, seed: seed &+ UInt64(k + 70))
                pen(p, sprout, weight: 3, colour: Pot.white.dk(0.1), wobble: 0.3, taper: true, seed: seed &+ UInt64(k + 71))
                pen(p, sprout, weight: 1.2, colour: Pot.leafPale.dk(0.2).al(0.8), wobble: 0.3, taper: true, seed: seed &+ UInt64(k + 72))
            }
        }
        letter(p, "6 of 10: sixty percent, sow twice as thick", at: 810, 660, size: 20, colour: Pot.inkSoft, face: "Baskerville-Italic", align: .centre)
        letter(p, "Cool, dry, dark, and the year on every packet", at: 600, 260, size: 24, colour: Pot.inkSoft, face: "Baskerville-Italic", align: .centre)
    }
}

func drawExtraLessonPlate(_ index: Int, dir: String) {
    let key = extraLessonKeys[index]
    let p = Leaf(1200, 900)
    let seed = hashOf("lesson-" + key)
    layPaper(p, seed: seed, tone: Pot.creamWarm)
    p.flipDown()
    p.light = -2.36
    borderRule(p, inset: 30, seed: seed &+ 3)
    drawExtraLessonFigure(p, key, seed: seed &+ 7)
    let title = extraLessonTitles[index]
    plateCaption(p, title: title.0, sub: title.1, y: 740, titleSize: 40)
    p.writeJPG(dir, "ls_" + key, quality: 0.84)
}

func seedTrayObject(_ p: Leaf, at c: CGPoint, w: Double, h: Double, stage: Int, crop: Crop, seed: UInt64) {
    var rng = Chip(seed)
    let x = Double(c.x) - w / 2, y = Double(c.y)
    let ring = [pt(x, y), pt(x + w, y), pt(x + w - 8, y + h), pt(x + 8, y + h)]
    p.shape(offsetRing(ring, 6, 8), Pot.shadowInk.al(0.16))
    wash(p, ring, Pot.ink.lt(0.28), strength: 0.9, bleed: 2, seed: seed)
    penEdge(p, ring, weight: 2.2, colour: Pot.ink, seed: seed &+ 1)
    let soil = [pt(x + 6, y + 4), pt(x + w - 6, y + 4), pt(x + w - 12, y + h * 0.5), pt(x + 12, y + h * 0.5)]
    wash(p, soil, Pot.soilDark, strength: 0.85, bleed: 2, seed: seed &+ 2)
    grit(p, pathOf(soil), density: 0.02, sizeMin: 0.6, sizeMax: 1.6, colour: Pot.soilLight, seed: seed &+ 3)
    let cells = stage >= 2 ? 6 : 8
    if stage >= 2 {
        for k in 0..<cells {
            let cx = x + w * (Double(k) + 0.5) / Double(cells)
            pen(p, [pt(cx + w / Double(cells) / 2, y + 4), pt(cx + w / Double(cells) / 2, y + h * 0.5)], weight: 1.2, colour: Pot.ink.al(0.5), wobble: 0.2, taper: false, seed: seed &+ UInt64(k + 10))
        }
    }
    switch stage {
    case 0:
        for k in 0..<Int(w / 12) {
            p.dot(x + 12 + Double(k) * 12 + rng.r(-2, 2), y + 10 + rng.r(-2, 2), 1.6, Pot.strawPale)
        }
    case 1:
        for k in 0..<cells {
            let cx = x + w * (Double(k) + 0.5) / Double(cells)
            let sp = stemRun(pt(cx, y + 8), -Double.pi / 2 + rng.r(-0.2, 0.2), rng.r(18, 30), curve: rng.r(-0.3, 0.3), wobble: 0.03, steps: 4, seed: seed &+ UInt64(k + 20))
            pen(p, sp, weight: 2.4, colour: Pot.leafPale.dk(0.1), wobble: 0.2, taper: true, seed: seed &+ UInt64(k + 21))
            let e = sp[sp.count - 1]
            blade(p, base: e, angle: -2.4, length: 14, width: 9, tone: Pot.leafPale, serrate: 0, curl: 0, veins: 0, seed: seed &+ UInt64(k + 30))
            blade(p, base: e, angle: -0.7, length: 14, width: 9, tone: Pot.leafPale, serrate: 0, curl: 0, veins: 0, seed: seed &+ UInt64(k + 31))
        }
    default:
        for k in 0..<cells {
            let cx = x + w * (Double(k) + 0.5) / Double(cells)
            p.ctx.saveGState()
            p.ctx.translateBy(x: CGFloat(cx), y: CGFloat(y + 12))
            p.ctx.scaleBy(x: CGFloat(stage == 3 ? 1.5 : 1.15), y: CGFloat(stage == 3 ? 1.5 : 1.15))
            seedlingVignette(p, at: pt(0, 0), tone: leafTone(crop), monocot: isMonocot(crop), seed: seed &+ UInt64(k + 40))
            p.ctx.restoreGState()
        }
    }
    let labelRing = [pt(x + 14, y - 34), pt(x + 26, y - 34), pt(x + 26, y + 10), pt(x + 14, y + 10)]
    wash(p, labelRing, Pot.white.dk(0.05), strength: 0.95, bleed: 1, seed: seed &+ 50)
    penEdge(p, labelRing, weight: 1.2, colour: Pot.ink.al(0.7), seed: seed &+ 51)
    letter(p, crop.name, at: x + 24, y - 30, size: 12, colour: Pot.ink, face: "Baskerville", align: .left, rotate: .pi / 2)
}

func growLamp(_ p: Leaf, x0: Double, x1: Double, y: Double, glow: Double, seed: UInt64) {
    let tube = [pt(x0, y), pt(x1, y), pt(x1, y + 22), pt(x0, y + 22)]
    p.gradientRect(CGRect(x: x0 - 40, y: y + 22, width: x1 - x0 + 80, height: 260), Hue(r: 0.96, g: 0.62, b: 0.86, a: 0.36 * glow), Hue(r: 0.96, g: 0.62, b: 0.86, a: 0))
    wash(p, tube, Pot.ink.lt(0.35), strength: 0.9, bleed: 1.5, seed: seed)
    penEdge(p, tube, weight: 2, colour: Pot.ink, seed: seed &+ 1)
    p.box(x0 + 8, y + 14, x1 - x0 - 16, 5, Hue(r: 1.0, g: 0.80, b: 0.95, a: 0.9 * glow))
    for k in 0..<2 {
        let cx = x0 + (x1 - x0) * (0.25 + Double(k) * 0.5)
        pen(p, [pt(cx, y), pt(cx, y - 70)], weight: 2.4, colour: Pot.ink, wobble: 0.2, taper: false, seed: seed &+ UInt64(k + 10))
    }
}

func drawTrayPlate(_ stage: Int, dir: String) {
    let p = Leaf(1200, 900)
    let seed = hashOf("tray-\(stage)")
    layPaper(p, seed: seed, tone: Pot.creamWarm, laid: false)
    p.flipDown()
    p.light = -2.36
    var rng = Chip(seed &+ 3)
    if stage < 3 {
        let wall = [pt(0, 0), pt(p.w, 0), pt(p.w, p.h), pt(0, p.h)]
        wash(p, wall, Pot.creamDeep.mix(Pot.frost, 0.12), strength: 0.35, bleed: 4, seed: seed &+ 1)
        let win = [pt(160, 110), pt(700, 110), pt(700, 470), pt(160, 470)]
        let skyTone = stage == 0 ? Hue(r: 0.55, g: 0.60, b: 0.68) : (stage == 1 ? Hue(r: 0.62, g: 0.72, b: 0.84) : Hue(r: 0.58, g: 0.72, b: 0.86))
        wash(p, win, skyTone, strength: 0.9, bleed: 2, seed: seed &+ 2)
        if stage == 0 {
            p.inside(pathOf(win)) {
                for _ in 0..<160 { p.dot(rng.r(160, 700), rng.r(110, 470), rng.r(1, 3), Pot.white.al(rng.r(0.5, 0.9))) }
                wash(p, [pt(160, 420), pt(700, 400), pt(700, 470), pt(160, 470)], Pot.white, strength: 0.85, bleed: 5, seed: seed &+ 4)
            }
        } else {
            p.inside(pathOf(win)) {
                for k in 0..<4 {
                    let cx = rng.r(200, 660), cy = rng.r(150, 300)
                    let cloud = lumpy(cx: cx, cy: cy, rx: rng.r(60, 120), ry: rng.r(20, 40), rough: 0.15, steps: 20, seed: seed &+ UInt64(k + 5))
                    wash(p, cloud, Pot.white, strength: 0.6, bleed: 6, seed: seed &+ UInt64(k + 6))
                }
                let hedge = [pt(160, 380), pt(700, 360), pt(700, 470), pt(160, 470)]
                wash(p, hedge, stage == 1 ? Pot.leafGrey.dk(0.2) : Pot.leaf, strength: 0.7, bleed: 5, seed: seed &+ 7)
            }
        }
        pen(p, [pt(430, 110), pt(430, 470)], weight: 10, colour: Pot.white.dk(0.06), wobble: 0.2, taper: false, seed: seed &+ 8)
        pen(p, [pt(160, 290), pt(700, 290)], weight: 10, colour: Pot.white.dk(0.06), wobble: 0.2, taper: false, seed: seed &+ 9)
        penEdge(p, win, weight: 12, colour: Pot.white.dk(0.08), seed: seed &+ 10)
        penEdge(p, win, weight: 2.4, colour: Pot.ink.al(0.8), seed: seed &+ 11)
        penEdge(p, [pt(140, 92), pt(720, 92), pt(720, 488), pt(140, 488)], weight: 2, colour: Pot.ink.al(0.6), seed: seed &+ 12)
        let sill = [pt(120, 488), pt(740, 488), pt(740, 520), pt(120, 520)]
        wash(p, sill, Pot.white.dk(0.1), strength: 0.9, bleed: 2, seed: seed &+ 13)
        penEdge(p, sill, weight: 2, colour: Pot.ink.al(0.7), seed: seed &+ 14)
        let shelfY = 720.0
        let shelf = [pt(760, shelfY), pt(1160, shelfY), pt(1160, shelfY + 26), pt(760, shelfY + 26)]
        wash(p, shelf, Pot.wood, strength: 0.85, bleed: 2, seed: seed &+ 20)
        crossHatch(p, pathOf(shelf), depth: 1, spacing: 6, colour: Pot.woodDark.al(0.6), seed: seed &+ 21)
        penEdge(p, shelf, weight: 2.2, colour: Pot.ink.al(0.8), seed: seed &+ 22)
        let shelf2 = offsetRing(shelf, 0, -300)
        wash(p, shelf2, Pot.wood, strength: 0.85, bleed: 2, seed: seed &+ 23)
        penEdge(p, shelf2, weight: 2.2, colour: Pot.ink.al(0.8), seed: seed &+ 24)
        for x in [780.0, 1140.0] {
            pen(p, [pt(x, 150), pt(x, 760)], weight: 8, colour: Pot.woodDark, wobble: 0.2, taper: false, seed: seed &+ UInt64(Int(x)))
        }
        growLamp(p, x0: 800, x1: 1120, y: 300, glow: 1.0, seed: seed &+ 30)
        growLamp(p, x0: 800, x1: 1120, y: 600, glow: 1.0, seed: seed &+ 31)
        let crops = ["tomato", "pepper", "lettuce", "cabbage", "basil", "leek"]
        seedTrayObject(p, at: pt(960, 400), w: 300, h: 60, stage: stage, crop: Register.find(crops[stage % 2 == 0 ? 0 : 1]), seed: seed &+ 40)
        seedTrayObject(p, at: pt(960, 700), w: 300, h: 60, stage: stage, crop: Register.find(crops[2 + stage % 2]), seed: seed &+ 41)
        seedTrayObject(p, at: pt(300, 470), w: 260, h: 56, stage: stage, crop: Register.find(crops[4 + stage % 2]), seed: seed &+ 42)
        seedTrayObject(p, at: pt(580, 470), w: 200, h: 56, stage: stage, crop: Register.find(crops[(stage + 3) % 6]), seed: seed &+ 43)
        wateringCan(p, at: pt(320, 640), size: 130, seed: seed &+ 50)
        for k in 0..<4 {
            seedEnvelope(p, at: pt(520 + Double(k) * 40, 660 + Double(k % 2) * 8), w: 70, h: 100, tilt: -0.2 + Double(k) * 0.1, label: Register.find(crops[k]).name, year: "", seed: seed &+ UInt64(k + 60))
        }
        let words = ["Sown, labelled, and under the lamp", "Up, and thinned to one a cell", "Pricked out, each with its own root", ""]
        letter(p, words[stage], at: 600, 840, size: 30, colour: Pot.ink, face: "Baskerville-Bold", align: .centre)
    } else {
        let look = GardenLook(season: 1, key: skySlots[1], w: p.w, h: p.h * 0.86)
        paintSky(p, look, seed: seed &+ 1)
        paintHedge(p, look, seed: seed &+ 2)
        paintGround(p, look, seed: seed &+ 5)
        let step = [pt(80, 560), pt(620, 560), pt(620, 700), pt(80, 700)]
        wash(p, step, Pot.inkPale.mix(Pot.creamDeep, 0.5), strength: 0.9, bleed: 3, seed: seed &+ 10)
        penEdge(p, step, weight: 2.4, colour: Pot.ink.al(0.8), seed: seed &+ 11)
        let door = [pt(150, 90), pt(450, 90), pt(450, 560), pt(150, 560)]
        wash(p, door, Pot.leafDeep.mix(Pot.frost, 0.35), strength: 0.8, bleed: 2, seed: seed &+ 12)
        for k in 0..<4 {
            let panel = [pt(180 + Double(k % 2) * 140, 130 + Double(k / 2) * 220), pt(300 + Double(k % 2) * 140, 130 + Double(k / 2) * 220), pt(300 + Double(k % 2) * 140, 320 + Double(k / 2) * 220), pt(180 + Double(k % 2) * 140, 320 + Double(k / 2) * 220)]
            penEdge(p, panel, weight: 2, colour: Pot.ink.al(0.6), seed: seed &+ UInt64(k + 13))
        }
        penEdge(p, door, weight: 3, colour: Pot.ink.al(0.85), seed: seed &+ 20)
        p.dot(420, 340, 8, Pot.straw)
        let frame = [pt(130, 70), pt(470, 70), pt(470, 560), pt(130, 560)]
        penEdge(p, frame, weight: 6, colour: Pot.white.dk(0.15), seed: seed &+ 21)
        seedTrayObject(p, at: pt(240, 600), w: 240, h: 56, stage: 3, crop: Register.find("tomato"), seed: seed &+ 30)
        seedTrayObject(p, at: pt(480, 610), w: 200, h: 56, stage: 3, crop: Register.find("basil"), seed: seed &+ 31)
        paintColdFrame(p, look, seed: seed &+ 4)
        seedTrayObject(p, at: pt(900, 640), w: 260, h: 56, stage: 3, crop: Register.find("pepper"), seed: seed &+ 32)
        p.box(0, p.h * 0.86, p.w, p.h * 0.14, Pot.creamWarm)
        layPaperStrip(p, y: p.h * 0.86, seed: seed &+ 9)
        letter(p, "Hardening off: days on the step, nights back in, for a week", at: 600, 840, size: 30, colour: Pot.ink, face: "Baskerville-Bold", align: .centre)
    }
    borderRule(p, inset: 22, seed: seed &+ 99)
    p.writeJPG(dir, "ty_\(stage)", quality: 0.84)
}

func drawMonthPlate(_ month: Int, dir: String) {
    let p = Leaf(1200, 900)
    let seed = hashOf("month-\(month)")
    layPaper(p, seed: seed, tone: Pot.creamWarm)
    p.flipDown()
    p.light = -2.36
    borderRule(p, inset: 30, seed: seed &+ 3)
    var rng = Chip(seed &+ 5)
    switch month {
    case 1:
        let table = [pt(100, 560), pt(1100, 560), pt(1100, 700), pt(100, 700)]
        wash(p, table, Pot.wood.lt(0.1), strength: 0.85, bleed: 3, seed: seed &+ 10)
        penEdge(p, table, weight: 2.4, colour: Pot.ink.al(0.8), seed: seed &+ 11)
        for k in 0..<5 {
            seedEnvelope(p, at: pt(260 + Double(k) * 110, 500 + Double(k % 2) * 20), w: 110, h: 160, tilt: -0.25 + Double(k) * 0.12, label: ["Pea", "Carrot", "Tomato", "Kale", "Bean"][k], year: "2026", seed: seed &+ UInt64(k + 20))
        }
        let mug = [pt(880, 420), pt(980, 420), pt(972, 540), pt(888, 540)]
        wash(p, mug, Pot.frostDeep.mix(Pot.white, 0.3), strength: 0.9, bleed: 2, seed: seed &+ 30)
        penEdge(p, mug, weight: 2.2, colour: Pot.ink.al(0.8), seed: seed &+ 31)
        pen(p, Array(ringOf(cx: 990, cy: 480, rx: 30, ry: 36, steps: 24)[18...23] + ringOf(cx: 990, cy: 480, rx: 30, ry: 36, steps: 24)[0...6]), weight: 8, colour: Pot.frostDeep.mix(Pot.white, 0.3), wobble: 0.3, taper: false, seed: seed &+ 32)
        for k in 0..<3 {
            let steam = stemRun(pt(910 + Double(k) * 25, 410), -Double.pi / 2, 70, curve: rng.r(-0.8, 0.8), wobble: 0.1, steps: 5, seed: seed &+ UInt64(k + 33))
            pen(p, steam, weight: 2, colour: Pot.inkPale.al(0.5), wobble: 0.5, taper: true, seed: seed &+ UInt64(k + 36))
        }
        let win = [pt(140, 120), pt(560, 120), pt(560, 400), pt(140, 400)]
        wash(p, win, Hue(r: 0.60, g: 0.64, b: 0.70), strength: 0.9, bleed: 2, seed: seed &+ 40)
        p.inside(pathOf(win)) { for _ in 0..<200 { p.dot(rng.r(140, 560), rng.r(120, 400), rng.r(1, 3), Pot.white.al(rng.r(0.5, 0.9))) } }
        penEdge(p, win, weight: 10, colour: Pot.white.dk(0.08), seed: seed &+ 41)
        penEdge(p, win, weight: 2.2, colour: Pot.ink.al(0.8), seed: seed &+ 42)
        pen(p, [pt(350, 120), pt(350, 400)], weight: 8, colour: Pot.white.dk(0.08), wobble: 0.2, taper: false, seed: seed &+ 43)
    case 2:
        let sill = [pt(140, 560), pt(1060, 560), pt(1060, 600), pt(140, 600)]
        wash(p, sill, Pot.white.dk(0.1), strength: 0.9, bleed: 2, seed: seed &+ 10)
        penEdge(p, sill, weight: 2.2, colour: Pot.ink.al(0.8), seed: seed &+ 11)
        let box = [pt(300, 470), pt(900, 470), pt(890, 560), pt(310, 560)]
        wash(p, box, Pot.strawPale.dk(0.2), strength: 0.9, bleed: 2, seed: seed &+ 12)
        penEdge(p, box, weight: 2.2, colour: Pot.ink.al(0.8), seed: seed &+ 13)
        for k in 0..<6 {
            let cx = 350.0 + Double(k) * 100
            let potato = lumpy(cx: cx, cy: 470, rx: 40, ry: 30, rough: 0.07, steps: 22, seed: seed &+ UInt64(k + 20))
            produce(p, potato, tone: Pot.straw.mix(Pot.soilLight, 0.35), gloss: 0.2, seed: seed &+ UInt64(k + 30))
            for j in 0..<3 {
                let sprout = stemRun(pt(cx + rng.r(-20, 20), 448), -Double.pi / 2 + rng.r(-0.5, 0.5), rng.r(14, 30), curve: rng.r(-0.4, 0.4), wobble: 0.05, steps: 4, seed: seed &+ UInt64(k * 3 + j + 40))
                pen(p, sprout, weight: 4, colour: Pot.aubergine.mix(Pot.leafPale, 0.5), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 3 + j + 60))
            }
            pen(p, [pt(cx + 50, 470), pt(cx + 50, 560)], weight: 1.4, colour: Pot.ink.al(0.4), wobble: 0.3, taper: false, seed: seed &+ UInt64(k + 80))
        }
        let win = [pt(200, 120), pt(1000, 120), pt(1000, 470), pt(200, 470)]
        wash(p, win, Hue(r: 0.66, g: 0.72, b: 0.80), strength: 0.85, bleed: 2, seed: seed &+ 90)
        penEdge(p, win, weight: 10, colour: Pot.white.dk(0.08), seed: seed &+ 91)
        penEdge(p, win, weight: 2.2, colour: Pot.ink.al(0.8), seed: seed &+ 92)
        pen(p, [pt(600, 120), pt(600, 470)], weight: 8, colour: Pot.white.dk(0.08), wobble: 0.2, taper: false, seed: seed &+ 93)
        for k in 0..<3 {
            let base = pt(1000 + Double(k) * 30, 700)
            let st = stemRun(base, -Double.pi / 2 + Double(k - 1) * 0.15, 120, curve: 0, wobble: 0.02, steps: 5, seed: seed &+ UInt64(k + 100))
            pen(p, st, weight: 3, colour: Pot.leaf.dk(0.2), wobble: 0.3, taper: true, seed: seed &+ UInt64(k + 101))
            let e = st[st.count - 1]
            for j in 0..<3 {
                blade(p, base: e, angle: .pi / 2 + Double(j - 1) * 0.5, length: 28, width: 12, tone: Pot.white, serrate: 0, curl: 0, veins: 0, seed: seed &+ UInt64(k * 3 + j + 110))
            }
        }
    case 3:
        soilBand(p, y: 540, depth: 150, x0: 120, x1: 1080, seed: seed)
        let drill = [pt(180, 560), pt(1020, 556), pt(1020, 580), pt(180, 584)]
        wash(p, drill, Pot.soilDark, strength: 0.7, bleed: 3, seed: seed &+ 10)
        for k in 0..<11 {
            let sx = 220.0 + Double(k) * 78
            fruitRound(p, at: pt(sx, 570), r: 9, tone: Pot.leafPale.dk(0.1), rough: 0.05, gloss: 0.3, seed: seed &+ UInt64(k + 20))
        }
        for k in 0..<6 {
            let sx = 260.0 + Double(k) * 130
            let stick = stemRun(pt(sx, 556), -Double.pi / 2 + rng.r(-0.1, 0.1), 300, curve: rng.r(-0.2, 0.2), wobble: 0.03, steps: 6, seed: seed &+ UInt64(k + 40))
            pen(p, stick, weight: 5, colour: Pot.woodDark, wobble: 0.4, taper: true, seed: seed &+ UInt64(k + 41))
            for j in 0..<4 {
                let q = along(stick, 0.4 + Double(j) * 0.15)
                let twig = stemRun(q, -Double.pi / 2 + (j % 2 == 0 ? -0.9 : 0.9), rng.r(30, 60), curve: 0.2, wobble: 0.05, steps: 4, seed: seed &+ UInt64(k * 4 + j + 50))
                pen(p, twig, weight: 2.4, colour: Pot.woodDark, wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 4 + j + 70))
            }
        }
        let dibber = stemRun(pt(1000, 420), .pi / 2 + 0.5, 170, curve: 0, wobble: 0.01, steps: 4, seed: seed &+ 90)
        stem(p, dibber, w0: 26, w1: 8, tone: Pot.wood, woody: true, seed: seed &+ 91)
        p.dot(1000, 420, 22, Pot.wood.dk(0.1))
        p.hoop(1000, 420, 22, 2, Pot.ink.al(0.8))
    case 4:
        let branch = stemRun(pt(120, 620), -0.55, 900, curve: -0.25, wobble: 0.02, steps: 14, seed: seed &+ 10)
        stem(p, branch, w0: 16, w1: 6, tone: Pot.woodDark, woody: true, seed: seed &+ 11)
        for k in 0..<40 {
            let q = along(branch, 0.08 + Double(k) * 0.023)
            let side = k % 2 == 0 ? -1.0 : 1.0
            let a = -0.55 + side * 1.2 + rng.r(-0.3, 0.3)
            for j in 0..<4 {
                blade(p, base: q, angle: a + Double(j) * 1.57, length: 30, width: 11, tone: Pot.yellow.lt(Double(j % 2) * 0.1), serrate: 0, curl: 0, veins: 0, seed: seed &+ UInt64(k * 4 + j + 20))
            }
        }
        for k in 0..<180 {
            let x = rng.r(100, 1100), y0 = rng.r(100, 700)
            pen(p, [pt(x, y0), pt(x - 6, y0 + 26)], weight: 1.2, colour: Pot.frostDeep.al(0.45), wobble: 0.2, taper: true, seed: seed &+ UInt64(k + 300))
        }
        for k in 0..<3 {
            seedTrayObject(p, at: pt(320 + Double(k) * 280, 660), w: 220, h: 50, stage: 1, crop: Register.find(["lettuce", "pea", "broccoli"][k]), seed: seed &+ UInt64(k + 400))
        }
    case 5:
        let branch = stemRun(pt(80, 200), 0.35, 500, curve: 0.2, wobble: 0.02, steps: 10, seed: seed &+ 10)
        stem(p, branch, w0: 14, w1: 6, tone: Pot.woodDark, woody: true, seed: seed &+ 11)
        for k in 0..<12 {
            let q = along(branch, 0.15 + Double(k) * 0.07)
            heartLeaf(p, at: pt(Double(q.x) + rng.r(-30, 30), Double(q.y) + rng.r(-30, 30)), angle: rng.r(0, 6), size: 26, tone: Pot.leaf, lobes: 5, seed: seed &+ UInt64(k + 20))
            for j in 0..<5 {
                daisy(p, at: pt(Double(q.x) + rng.r(-40, 40), Double(q.y) + rng.r(-40, 40)), r: 11, petals: 5, petalTone: Pot.white, centreTone: Pot.yellow.dk(0.1), petalWidth: 0.7, seed: seed &+ UInt64(k * 5 + j + 40))
            }
        }
        bedBox(p, x: 560, y: 440, w: 520, h: 220, seed: seed &+ 60)
        for k in 0..<3 {
            miniature(p, Register.find("tomato"), at: pt(660 + Double(k) * 150, 560), scale: 0.16)
            stakeLineAt(p, x: 690 + Double(k) * 150, top: 360, base: 640, seed: seed &+ UInt64(k + 70))
        }
        fleeceOver(p, x0: 160, x1: 460, top: 560, base: 660, seed: seed &+ 80)
        for k in 0..<3 {
            let q = pt(180 + Double(k) * 90, 600)
            heartLeaf(p, at: q, angle: -Double.pi / 2 + Double(k - 1) * 0.4, size: 30, tone: Pot.leafPale, lobes: 7, seed: seed &+ UInt64(k + 90))
        }
    case 6:
        bedBox(p, x: 120, y: 380, w: 960, h: 280, seed: seed)
        for k in 0..<7 {
            miniature(p, Register.find(["lettuce", "bushbean", "carrot", "zucchini", "pea", "lettuce", "onion"][k]), at: pt(190 + Double(k) * 140, 560 + Double(k % 2) * 30), scale: 0.16)
        }
        let flower = pt(560, 250)
        pen(p, [pt(560, 380), flower], weight: 5, colour: Pot.leaf.dk(0.2), wobble: 0.3, taper: true, seed: seed &+ 20)
        for k in 0..<3 {
            blade(p, base: pt(Double(flower.x), Double(flower.y) + Double(k) * 30), angle: -Double.pi / 2 + Double(k - 1) * 0.9, length: 34, width: 22, tone: Pot.white, serrate: 0, curl: 0, veins: 1, seed: seed &+ UInt64(k + 30))
        }
        let bee = lumpy(cx: 620, cy: 240, rx: 22, ry: 14, rough: 0.05, steps: 16, seed: seed &+ 40)
        produce(p, bee, tone: Pot.yellow, gloss: 0.3, seed: seed &+ 41)
        p.inside(pathOf(bee)) {
            for j in 0..<3 { pen(p, [pt(606 + Double(j) * 11, 226), pt(606 + Double(j) * 11, 254)], weight: 5, colour: Pot.ink, wobble: 0.2, taper: false, seed: seed &+ UInt64(j + 42)) }
        }
        for side in [-1.0, 1.0] {
            let wing = lumpy(cx: 616, cy: 224 + side * 0, rx: 18, ry: 8, rough: 0.05, steps: 12, seed: seed &+ UInt64(side > 0 ? 45 : 46))
            wash(p, rotatedRing(wing, about: pt(606, 232), side * 0.6 - 0.6), Pot.glass.lt(0.3), strength: 0.5, bleed: 1, seed: seed &+ 47)
        }
        wateringCan(p, at: pt(960, 260), size: 130, seed: seed &+ 50)
    case 7:
        soilBand(p, y: 520, depth: 160, x0: 120, x1: 780, seed: seed)
        let drill = [pt(160, 540), pt(740, 536), pt(740, 556), pt(160, 560)]
        wash(p, drill, Pot.soilDark, strength: 0.7, bleed: 3, seed: seed &+ 10)
        for k in 0..<14 { p.dot(190 + Double(k) * 40, 548, 3, Pot.sepia) }
        let sun = lumpy(cx: 960, cy: 240, rx: 70, ry: 70, rough: 0.02, steps: 30, seed: seed &+ 20)
        p.shape(sun, Pot.yellow)
        penOutline(p, sun, weight: 1.8, colour: Pot.straw.dk(0.2).al(0.7), seed: seed &+ 21)
        for k in 0..<12 {
            let a = Double(k) / 12 * 2 * .pi
            pen(p, [pt(960 + cos(a) * 86, 240 + sin(a) * 86), pt(960 + cos(a) * 124, 240 + sin(a) * 124)], weight: 3, colour: Pot.straw.dk(0.2), wobble: 0.3, taper: true, seed: seed &+ UInt64(k + 30))
        }
        butterfly(p, at: pt(300, 300), size: 100, seed: seed &+ 40)
        let cloud = lumpy(cx: 620, cy: 200, rx: 160, ry: 60, rough: 0.15, steps: 26, seed: seed &+ 50)
        wash(p, cloud, Pot.inkPale.mix(Pot.frost, 0.5), strength: 0.7, bleed: 6, seed: seed &+ 51)
        crossHatch(p, pathOf(cloud), depth: 1, spacing: 6, colour: Pot.inkSoft.al(0.4), seed: seed &+ 52)
        pen(p, [pt(600, 260), pt(580, 320), pt(610, 330), pt(590, 400)], weight: 5, colour: Pot.yellow.dk(0.1), wobble: 0.3, taper: true, seed: seed &+ 53)
        miniature(p, Register.find("turnip"), at: pt(900, 620), scale: 0.2)
    case 8:
        let rack = [pt(140, 420), pt(1060, 420), pt(1060, 440), pt(140, 440)]
        wash(p, rack, Pot.wood, strength: 0.85, bleed: 2, seed: seed &+ 10)
        penEdge(p, rack, weight: 2, colour: Pot.ink.al(0.8), seed: seed &+ 11)
        for k in 0..<3 {
            let x = 200.0 + Double(k) * 380
            pen(p, [pt(x, 440), pt(x - 20, 700)], weight: 8, colour: Pot.woodDark, wobble: 0.3, taper: false, seed: seed &+ UInt64(k + 12))
            pen(p, [pt(x + 60, 440), pt(x + 80, 700)], weight: 8, colour: Pot.woodDark, wobble: 0.3, taper: false, seed: seed &+ UInt64(k + 15))
        }
        for k in 0..<9 {
            let x = 200.0 + Double(k) * 100
            bulb(p, at: pt(x, 380), rx: 40, ry: 36, tone: Pot.straw.mix(Pot.terracotta, 0.3), striate: 6, neck: 0.45, seed: seed &+ UInt64(k + 20))
            for j in 0..<3 {
                strapLeaf(p, base: pt(x, 344), angle: -Double.pi / 2 + Double(j - 1) * 0.3 + 0.9, length: 120, width: 12, tone: Pot.straw.dk(0.3), curve: 0.6, fold: false, seed: seed &+ UInt64(k * 3 + j + 40))
            }
        }
        for k in 0..<5 {
            fruitRound(p, at: pt(300 + Double(k) * 90, 620), r: 34, tone: k < 3 ? Pot.tomato : Pot.tomato.mix(Pot.yellow, 0.5), rough: 0.03, gloss: 0.6, seed: seed &+ UInt64(k + 60))
        }
        miniature(p, Register.find("spinach"), at: pt(900, 640), scale: 0.16)
    case 9:
        let cane = stemRun(pt(100, 640), -0.4, 900, curve: -0.35, wobble: 0.02, steps: 14, seed: seed &+ 10)
        stem(p, cane, w0: 10, w1: 5, tone: Pot.aubergine.mix(Pot.woodDark, 0.5), woody: true, seed: seed &+ 11)
        for k in 0..<14 {
            let q = along(cane, 0.1 + Double(k) * 0.065)
            let side = k % 2 == 0 ? -1.0 : 1.0
            pinnateLeaf(p, base: q, angle: -0.4 + side * 1.3, length: 90, tone: Pot.leafDeep.lt(0.1), leaflets: 3, leafletSize: 40, serrate: 0.5, seed: seed &+ UInt64(k + 20))
            if k % 3 == 1 {
                let bc = pt(Double(q.x) + side * 40, Double(q.y) - 30)
                for j in 0..<9 {
                    let a = Double(j) / 9 * 2 * .pi
                    p.dot(Double(bc.x) + cos(a) * 10, Double(bc.y) + sin(a) * 10, 6, k > 6 ? Pot.ink.lt(0.15) : Pot.tomato.dk(0.3))
                    p.dot(Double(bc.x) + cos(a) * 10 - 1.5, Double(bc.y) + sin(a) * 10 - 1.5, 1.6, Pot.white.al(0.6))
                }
                p.dot(Double(bc.x), Double(bc.y), 6, k > 6 ? Pot.ink.lt(0.15) : Pot.tomato.dk(0.3))
            }
        }
        for k in 0..<6 {
            seedVignette(p, at: pt(800 + Double(k % 3) * 90, 560 + Double(k / 3) * 70), kind: "clove", tone: Pot.white.dk(0.05), seed: seed &+ UInt64(k + 100))
        }
        p.gradientRect(CGRect(x: 60, y: 60, width: 1080, height: 180), Hue(r: 0.95, g: 0.55, b: 0.35, a: 0.35), Hue(r: 0.95, g: 0.55, b: 0.35, a: 0))
    case 10:
        soilBand(p, y: 600, depth: 90, x0: 100, x1: 1100, seed: seed)
        for k in 0..<3 {
            let r = 90.0 - Double(k) * 15
            let cx = 250.0 + Double(k) * 210
            let pumpkin = lumpy(cx: cx, cy: 560, rx: r, ry: r * 0.75, rough: 0.03, steps: 36, seed: seed &+ UInt64(k + 10))
            produce(p, pumpkin, tone: Pot.pumpkin.lt(Double(k) * 0.08), gloss: 0.5, seed: seed &+ UInt64(k + 11))
            ribs(p, at: pt(cx, 560), r: r * 0.8, count: 7, tone: Pot.pumpkin, seed: seed &+ UInt64(k + 12))
            pen(p, [pt(cx, 560 - r * 0.75), pt(cx + 10, 560 - r * 0.75 - 30)], weight: 12, colour: Pot.leafGrey.dk(0.2), wobble: 0.3, taper: false, seed: seed &+ UInt64(k + 13))
        }
        for k in 0..<40 {
            let x = rng.r(100, 1100), y = rng.r(80, 660)
            blade(p, base: pt(x, y), angle: rng.r(0, 6.2), length: rng.r(18, 34), width: rng.r(12, 22), tone: Hue(r: 0.80, g: 0.50, b: 0.22).lt(rng.r(0, 0.25)), serrate: 0.2, curl: 0, veins: 1, seed: seed &+ UInt64(k + 300))
        }
        miniature(p, Register.find("parsnip"), at: pt(920, 600), scale: 0.2)
        for _ in 0..<200 { p.dot(rng.r(110, 1090), rng.r(592, 612), rng.r(0.8, 2.2), Pot.white.al(rng.r(0.4, 0.9))) }
    case 11:
        soilBand(p, y: 560, depth: 140, x0: 100, x1: 700, seed: seed)
        for k in 0..<5 {
            let x = 180.0 + Double(k) * 110
            seedVignette(p, at: pt(x, 600), kind: "clove", tone: Pot.white.dk(0.05), seed: seed &+ UInt64(k + 10))
            pen(p, [pt(x, 560), pt(x + 2, 500)], weight: 2, colour: Pot.leafBlue, wobble: 0.3, taper: true, seed: seed &+ UInt64(k + 20))
        }
        let stalk = stemRun(pt(900, 700), -Double.pi / 2 + 0.05, 520, curve: 0.02, wobble: 0.01, steps: 10, seed: seed &+ 30)
        stem(p, stalk, w0: 30, w1: 22, tone: Pot.leafBlue.dk(0.2), woody: true, seed: seed &+ 31)
        for k in 0..<18 {
            let q = along(stalk, 0.1 + Double(k) * 0.045)
            let side = k % 2 == 0 ? -1.0 : 1.0
            fruitRound(p, at: pt(Double(q.x) + side * 26, Double(q.y)), r: 18, tone: Pot.leaf.mix(Pot.leafBlue, 0.4), rough: 0.05, gloss: 0.4, seed: seed &+ UInt64(k + 40))
        }
        for k in 0..<3 {
            crinkleLeaf(p, base: along(stalk, 0.98), angle: -Double.pi / 2 + Double(k - 1) * 0.8, length: 120, width: 80, tone: Pot.leafBlue, seed: seed &+ UInt64(k + 60))
        }
        for _ in 0..<300 { p.dot(rng.r(110, 1090), rng.r(180, 700), rng.r(0.8, 2.0), Pot.white.al(rng.r(0.3, 0.8))) }
        for k in 0..<4 {
            let x = 180.0 + Double(k) * 60
            for j in 0..<6 {
                let a = Double(j) / 6 * 2 * Double.pi
                pen(p, [pt(x, 300), pt(x + cos(a) * 22, 300 + sin(a) * 22)], weight: 2, colour: Pot.frostDeep.al(0.8), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 6 + j + 70))
            }
        }
    default:
        soilBand(p, y: 520, depth: 180, x0: 100, x1: 1100, seed: seed)
        for k in 0..<12 {
            let cx = 150.0 + Double(k) * 80, cy = 540.0 + rng.r(0, 40)
            let clod = lumpy(cx: cx, cy: cy, rx: rng.r(30, 50), ry: rng.r(18, 30), rough: 0.25, steps: 14, seed: seed &+ UInt64(k + 10))
            wash(p, clod, Pot.soilDark, strength: 0.8, bleed: 3, seed: seed &+ UInt64(k + 11))
            penOutline(p, clod, weight: 1.6, colour: Pot.ink.al(0.6), seed: seed &+ UInt64(k + 12))
        }
        for _ in 0..<500 { p.dot(rng.r(110, 1090), rng.r(510, 620), rng.r(0.8, 2.4), Pot.white.al(rng.r(0.4, 0.9))) }
        let spade = stemRun(pt(900, 420), .pi / 2 + 0.15, 200, curve: 0, wobble: 0.01, steps: 4, seed: seed &+ 30)
        stem(p, spade, w0: 18, w1: 16, tone: Pot.wood, woody: true, seed: seed &+ 31)
        let bladeRing = [pt(860, 600), pt(980, 600), pt(975, 720), pt(920, 750), pt(865, 720)]
        wash(p, bladeRing, Pot.inkPale.mix(Pot.glass, 0.4), strength: 0.85, bleed: 2, seed: seed &+ 32)
        crossHatch(p, pathOf(bladeRing), depth: 1, spacing: 5, colour: Pot.ink.al(0.4), seed: seed &+ 33)
        penEdge(p, bladeRing, weight: 2.4, colour: Pot.ink.al(0.85), seed: seed &+ 34)
        let holly = pt(240, 250)
        for k in 0..<3 {
            let a = -0.6 + Double(k) * 1.1
            let leaf = lobedLeafRing(base: holly, angle: a, length: 110, width: 60, seed: seed &+ UInt64(k + 40))
            wash(p, leaf, Pot.leafDeep, strength: 0.65, bleed: 3, seed: seed &+ UInt64(k + 41))
            crossHatch(p, pathOf(leaf), depth: 1, spacing: 5, colour: Pot.leafDeep.dk(0.5), seed: seed &+ UInt64(k + 42))
            penOutline(p, leaf, weight: 1.8, colour: Pot.leafDeep.dk(0.6), seed: seed &+ UInt64(k + 43))
        }
        for k in 0..<5 {
            fruitRound(p, at: pt(Double(holly.x) + rng.r(-14, 14), Double(holly.y) + rng.r(-14, 14)), r: 9, tone: Pot.tomato, rough: 0.03, gloss: 0.7, seed: seed &+ UInt64(k + 50))
        }
    }
    let names = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    let subs = ["Seed catalogues, a hot mug, and snow on the beds", "Potatoes chitting on the sill, snowdrops in the border", "Peas in the drill, sticks in, mud on the boots", "Forsythia out: the signal for peas and lettuce", "Hawthorn in flower, tomatoes going out under fleece", "Bees on the bean flowers and the can in daily use", "Turnips sown on St James's Day under a thunder sky", "Onions curing, tomatoes colouring, spinach sown", "Blackberries at their last and garlic ready for the ground", "Pumpkins in, leaves down, parsnips left for the frost", "Garlic in by Bonfire Night, sprouts sweetening in the cold", "The beds dug rough for the frost to break down"]
    plateCaption(p, title: names[month - 1], sub: subs[month - 1], y: 740, titleSize: 40)
    p.writeJPG(dir, "mo_\(month)", quality: 0.84)
}

func stakeLineAt(_ p: Leaf, x: Double, top: Double, base: Double, seed: UInt64) {
    let spine = [pt(x, base), pt(x + 3, top)]
    stem(p, spine, w0: 9, w1: 7, tone: Pot.wood, woody: true, seed: seed)
}
