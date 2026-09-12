import Foundation
import CoreGraphics

func miniature(_ p: Leaf, _ crop: Crop, at origin: CGPoint, scale: Double) {
    p.ctx.saveGState()
    p.ctx.translateBy(x: CGFloat(Double(origin.x) - plantX * scale), y: CGFloat(Double(origin.y) - (groundY + 40) * scale))
    p.ctx.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
    drawCropFigure(p, crop)
    p.ctx.restoreGState()
}

func crossFlower(_ p: Leaf, at c: CGPoint, r: Double, tone: Hue, seed: UInt64) {
    for k in 0..<4 {
        let a = Double(k) / 4 * 2 * Double.pi + Double.pi / 4
        blade(p, base: pt(Double(c.x) + cos(a) * r * 0.16, Double(c.y) + sin(a) * r * 0.16), angle: a, length: r, width: r * 0.62, tone: tone, serrate: 0, curl: 0, veins: 1, seed: seed &+ UInt64(k * 7))
    }
    p.dot(Double(c.x), Double(c.y), r * 0.14, Pot.leafPale.dk(0.2))
    for k in 0..<6 {
        let a = Double(k) / 6 * 2 * Double.pi
        p.dot(Double(c.x) + cos(a) * r * 0.22, Double(c.y) + sin(a) * r * 0.22, r * 0.05, Pot.yellow.dk(0.2))
    }
}

func starFlower(_ p: Leaf, at c: CGPoint, r: Double, tone: Hue, seed: UInt64) {
    for k in 0..<5 {
        let a = Double(k) / 5 * 2 * Double.pi - Double.pi / 2
        blade(p, base: pt(Double(c.x) + cos(a) * r * 0.1, Double(c.y) + sin(a) * r * 0.1), angle: a, length: r, width: r * 0.5, tone: tone, serrate: 0, curl: 0, veins: 1, seed: seed &+ UInt64(k * 7))
    }
    let cone = ringOf(cx: Double(c.x), cy: Double(c.y), rx: r * 0.16, ry: r * 0.2, steps: 20)
    produce(p, cone, tone: Pot.yellow, gloss: 0.4, seed: seed &+ 40)
}

func drawFamilySignature(_ p: Leaf, _ family: CropFamily, seed: UInt64) {
    var rng = Chip(seed)
    let cx = 330.0, base = 640.0
    switch family {
    case .brassica:
        let st = stemRun(pt(cx, base), -Double.pi / 2 + 0.05, 330, curve: -0.15, wobble: 0.02, steps: 10, seed: seed)
        stem(p, st, w0: 12, w1: 6, tone: Pot.leafBlue.dk(0.1), seed: seed &+ 1)
        crinkleLeaf(p, base: pt(cx - 4, base - 40), angle: -Double.pi / 2 - 1.05, length: 240, width: 130, tone: Pot.leafBlue, seed: seed &+ 3)
        crinkleLeaf(p, base: pt(cx + 4, base - 120), angle: -Double.pi / 2 + 0.95, length: 200, width: 110, tone: Pot.leafBlue.dk(0.08), seed: seed &+ 4)
        for k in 0..<5 {
            let q = along(st, 0.72 + Double(k) * 0.07)
            crossFlower(p, at: pt(Double(q.x) + Double(k % 2 == 0 ? -34 : 34), Double(q.y)), r: 30 - Double(k) * 2, tone: Pot.yellow.lt(0.15), seed: seed &+ UInt64(k * 11 + 50))
        }
        podShape(p, from: pt(cx - 8, base - 210), to: pt(cx - 70, base - 300), width: 9, tone: Pot.leafPale, beads: 8, seed: seed &+ 90)
    case .allium:
        bulb(p, at: pt(cx, base - 40), rx: 70, ry: 62, tone: Pot.straw.mix(Pot.terracotta, 0.2), striate: 7, neck: 0.4, seed: seed &+ 5)
        for k in 0..<5 {
            let a = -Double.pi / 2 + Double(k - 2) * 0.18
            strapLeaf(p, base: pt(cx, base - 100), angle: a, length: rng.r(200, 280), width: 18, tone: k % 2 == 0 ? Pot.leafBlue : Pot.leafBlue.dk(0.1), curve: Double(k - 2) * 0.15, fold: false, seed: seed &+ UInt64(k * 13))
        }
        let scape = stemRun(pt(cx + 6, base - 100), -Double.pi / 2 + 0.08, 270, curve: 0.05, wobble: 0.01, steps: 8, seed: seed &+ 60)
        pen(p, scape, weight: 7, colour: Pot.leafBlue.dk(0.2), wobble: 0.4, taper: true, seed: seed &+ 61)
        let top = scape[scape.count - 1]
        let globe = lumpy(cx: Double(top.x), cy: Double(top.y) - 30, rx: 56, ry: 52, rough: 0.08, steps: 36, seed: seed &+ 62)
        produce(p, globe, tone: Hue(r: 0.78, g: 0.62, b: 0.80), gloss: 0.3, seed: seed &+ 63)
        p.inside(pathOf(globe)) {
            for _ in 0..<80 { p.dot(Double(top.x) + rng.r(-54, 54), Double(top.y) - 30 + rng.r(-50, 50), rng.r(1.2, 3), Hue(r: 0.55, g: 0.36, b: 0.62).al(0.6)) }
        }
    case .nightshade:
        let st = stemRun(pt(cx, base), -Double.pi / 2, 320, curve: -0.1, wobble: 0.02, steps: 10, seed: seed)
        stem(p, st, w0: 12, w1: 7, tone: Pot.leaf.dk(0.15), woody: true, seed: seed &+ 1)
        pinnateLeaf(p, base: along(st, 0.4), angle: -Double.pi / 2 - 1.0, length: 190, tone: Pot.leaf, leaflets: 5, leafletSize: 62, serrate: 0.5, seed: seed &+ 3)
        pinnateLeaf(p, base: along(st, 0.65), angle: -Double.pi / 2 + 0.9, length: 170, tone: Pot.leaf.dk(0.06), leaflets: 5, leafletSize: 56, serrate: 0.5, seed: seed &+ 4)
        starFlower(p, at: pt(cx - 90, base - 300), r: 46, tone: Pot.yellow, seed: seed &+ 50)
        starFlower(p, at: pt(cx + 60, base - 330), r: 38, tone: Pot.yellow.lt(0.1), seed: seed &+ 51)
        fruitRound(p, at: pt(cx + 80, base - 150), r: 44, tone: Pot.tomato, rough: 0.03, gloss: 0.7, seed: seed &+ 70)
        fruitRound(p, at: pt(cx + 40, base - 90), r: 34, tone: Pot.tomato.mix(Pot.yellow, 0.4), rough: 0.03, gloss: 0.7, seed: seed &+ 71)
    case .cucurbit:
        let run = stemRun(pt(cx - 200, base), 0.2, 420, curve: -0.6, wobble: 0.05, steps: 12, seed: seed)
        stem(p, run, w0: 12, w1: 7, tone: Pot.leaf.dk(0.15), seed: seed &+ 1)
        heartLeaf(p, at: pt(cx - 80, base - 190), angle: -1.4, size: 130, tone: Pot.leafDeep.lt(0.12), lobes: 5, seed: seed &+ 3)
        heartLeaf(p, at: pt(cx + 120, base - 120), angle: -0.6, size: 100, tone: Pot.leaf, lobes: 5, seed: seed &+ 4)
        let tendril = stemRun(pt(cx + 40, base - 60), -0.8, 120, curve: 6.0, wobble: 0.1, steps: 16, seed: seed &+ 20)
        pen(p, tendril, weight: 3, colour: Pot.leaf.dk(0.3), wobble: 0.4, taper: true, seed: seed &+ 21)
        let flowerBase = pt(cx + 90, base - 260)
        for j in 0..<5 {
            blade(p, base: flowerBase, angle: -2.3 + Double(j) * 0.4, length: 84, width: 30, tone: j % 2 == 0 ? Pot.yellow : Pot.yellow.mix(Pot.pumpkin, 0.3), serrate: 0, curl: 0, veins: 1, seed: seed &+ UInt64(j + 50))
        }
        fruitLong(p, from: pt(cx - 190, base - 30), to: pt(cx - 40, base - 10), width: 44, tone: Pot.leafDeep, taperEnd: 0.8, gloss: 0.5, seed: seed &+ 80)
    case .legume:
        let st = stemRun(pt(cx, base), -Double.pi / 2 + 0.1, 340, curve: -0.3, wobble: 0.03, steps: 10, seed: seed)
        stem(p, st, w0: 9, w1: 5, tone: Pot.leaf.dk(0.1), seed: seed &+ 1)
        pinnateLeaf(p, base: along(st, 0.45), angle: -Double.pi / 2 - 1.0, length: 120, tone: Pot.leafPale, leaflets: 4, leafletSize: 44, serrate: 0, seed: seed &+ 3)
        trifoliate(p, at: pt(cx + 90, base - 200), angle: -0.8, size: 70, tone: Pot.leaf, seed: seed &+ 4)
        podShape(p, from: pt(cx - 30, base - 250), to: pt(cx - 90, base - 150), width: 26, tone: Pot.leafPale.lt(0.1), beads: 6, seed: seed &+ 40)
        let flowerC = pt(cx + 40, base - 320)
        blade(p, base: flowerC, angle: -Double.pi / 2 - 0.3, length: 56, width: 60, tone: Pot.white, serrate: 0, curl: 0, veins: 2, seed: seed &+ 50)
        blade(p, base: flowerC, angle: -0.2, length: 36, width: 26, tone: Hue(r: 0.72, g: 0.50, b: 0.72), serrate: 0, curl: 0, veins: 1, seed: seed &+ 51)
        blade(p, base: flowerC, angle: -Double.pi + 0.2, length: 36, width: 26, tone: Hue(r: 0.72, g: 0.50, b: 0.72), serrate: 0, curl: 0, veins: 1, seed: seed &+ 52)
        soilBand(p, y: base, depth: 70, x0: cx - 170, x1: cx + 170, seed: seed &+ 200)
        for k in 0..<5 {
            let root = stemRun(pt(cx, base + 4), Double.pi / 2 + Double(k - 2) * 0.45, rng.r(40, 62), curve: 0, wobble: 0.1, steps: 5, seed: seed &+ UInt64(k * 3 + 300))
            pen(p, root, weight: 2.2, colour: Pot.strawPale.dk(0.4), wobble: 0.4, taper: true, seed: seed &+ UInt64(k + 301))
            for j in 0..<3 {
                let q = along(root, 0.4 + Double(j) * 0.25)
                p.dot(Double(q.x) + rng.r(-5, 5), Double(q.y) + rng.r(-3, 3), 4.5, Hue(r: 0.85, g: 0.72, b: 0.62))
                p.hoop(Double(q.x) + rng.r(-5, 5), Double(q.y) + rng.r(-3, 3), 4.5, 1, Pot.sepia.al(0.6))
            }
        }
    case .umbel:
        soilBand(p, y: base, depth: 80, x0: cx - 170, x1: cx + 170, seed: seed &+ 200)
        taproot(p, top: pt(cx, base - 6), length: 70, width: 40, tone: Pot.strawPale.lt(0.2), rings: true, seed: seed &+ 5)
        for k in 0..<3 {
            featheryLeaf(p, base: pt(cx, base - 4), angle: -Double.pi / 2 + Double(k - 1) * 0.5, length: 220, tone: Pot.leafPale, fineness: 6, seed: seed &+ UInt64(k * 13))
        }
        let st = stemRun(pt(cx + 8, base - 4), -Double.pi / 2 + 0.1, 380, curve: -0.1, wobble: 0.01, steps: 8, seed: seed &+ 60)
        pen(p, st, weight: 5, colour: Pot.leaf.dk(0.3), wobble: 0.4, taper: true, seed: seed &+ 61)
        umbel(p, top: st[st.count - 1], spread: 120, tone: Pot.white, rays: 11, seed: seed &+ 62)
    case .aster:
        let st = stemRun(pt(cx, base), -Double.pi / 2, 330, curve: 0.08, wobble: 0.02, steps: 10, seed: seed)
        stem(p, st, w0: 9, w1: 6, tone: Pot.leaf.dk(0.15), seed: seed &+ 1)
        blade(p, base: along(st, 0.35), angle: -Double.pi / 2 - 0.9, length: 130, width: 44, tone: Pot.leafPale, serrate: 0.4, curl: -0.2, veins: 4, seed: seed &+ 3)
        blade(p, base: along(st, 0.55), angle: -Double.pi / 2 + 0.8, length: 110, width: 40, tone: Pot.leafPale.dk(0.06), serrate: 0.4, curl: 0.2, veins: 4, seed: seed &+ 4)
        daisy(p, at: pt(cx + 4, base - 330), r: 110, petals: 20, petalTone: Pot.pumpkin.mix(Pot.yellow, 0.4), centreTone: Pot.sepia.lt(0.1), petalWidth: 0.3, seed: seed &+ 50)
        p.inside(pathOf(ringOf(cx: cx + 4, cy: base - 330, rx: 36, ry: 34, steps: 30))) {
            for k in 0..<90 {
                let a = Double(k) * 2.39996
                let r = 3.6 * (Double(k)).squareRoot()
                p.dot(cx + 4 + cos(a) * r, base - 330 + sin(a) * r, 2.4, k % 2 == 0 ? Pot.sepia.dk(0.3) : Pot.straw.dk(0.2))
            }
        }
        crinkleLeaf(p, base: pt(cx - 150, base), angle: -Double.pi / 2 - 0.5, length: 140, width: 90, tone: Pot.leafPale.lt(0.1), seed: seed &+ 80)
        crinkleLeaf(p, base: pt(cx - 150, base), angle: -Double.pi / 2 + 0.4, length: 120, width: 80, tone: Pot.leafPale, seed: seed &+ 81)
    case .amaranth:
        soilBand(p, y: base, depth: 70, x0: cx - 170, x1: cx + 170, seed: seed &+ 200)
        let ring = lumpy(cx: cx, cy: base + 26, rx: 52, ry: 50, rough: 0.02, steps: 32, seed: seed &+ 5)
        produce(p, ring, tone: Pot.beet, gloss: 0.5, seed: seed &+ 5)
        for k in 0..<5 {
            let a = -Double.pi / 2 + Double(k - 2) * 0.32
            crinkleLeaf(p, base: pt(cx, base - 8), angle: a, length: rng.r(220, 280), width: 110, tone: k % 2 == 0 ? Pot.leafDeep.lt(0.15) : Pot.leaf, seed: seed &+ UInt64(k * 13))
            pen(p, [pt(cx, base - 8), pt(cx + cos(a) * 130, base - 8 + sin(a) * 130)], weight: 5, colour: Pot.beet.lt(0.2).al(0.85), wobble: 0.5, taper: true, seed: seed &+ UInt64(k * 3 + 400))
        }
        for k in 0..<7 {
            let q = pt(cx - 170 + Double(k) * 18, base - 320 + Double(k % 2) * 8)
            let cluster = lumpy(cx: Double(q.x), cy: Double(q.y), rx: 9, ry: 8, rough: 0.2, steps: 14, seed: seed &+ UInt64(k * 3 + 500))
            p.shape(cluster, Pot.sepia.lt(0.2))
            penOutline(p, cluster, weight: 1, colour: Pot.sepia.dk(0.4), seed: seed &+ UInt64(k * 3 + 501))
        }
        letter(p, "corky seed clusters", at: cx - 110, base - 285, size: 16, colour: Pot.inkPale, face: "Baskerville-Italic", align: .centre)
    case .grass:
        let st = stemRun(pt(cx, base), -Double.pi / 2, 330, curve: 0, wobble: 0.01, steps: 10, seed: seed)
        stem(p, st, w0: 22, w1: 10, tone: Pot.leafPale.dk(0.1), seed: seed &+ 1)
        for k in 0..<4 {
            let t = 0.2 + Double(k) * 0.18
            let side: Double = k % 2 == 0 ? -1 : 1
            strapLeaf(p, base: along(st, t), angle: side > 0 ? -0.9 : -2.25, length: rng.r(200, 260), width: 40, tone: k % 2 == 0 ? Pot.leaf : Pot.leaf.dk(0.1), curve: side * 0.9, fold: true, seed: seed &+ UInt64(k * 13))
        }
        let top = st[st.count - 1]
        for k in 0..<7 {
            let a = -Double.pi / 2 + Double(k - 3) * 0.3
            let tassel = stemRun(top, a, rng.r(80, 120), curve: Double(k - 3) * 0.15, wobble: 0.04, steps: 6, seed: seed &+ UInt64(k * 5 + 60))
            pen(p, tassel, weight: 3, colour: Pot.straw.dk(0.2), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 5 + 61))
        }
    case .mint:
        let st = stemRun(pt(cx, base), -Double.pi / 2, 330, curve: 0, wobble: 0.01, steps: 10, seed: seed)
        let outline = bandOf(st, [16, 12, 9], per: 4)
        wash(p, outline, Pot.leaf.dk(0.15), strength: 0.5, bleed: 2, seed: seed &+ 1)
        penEdge(p, outline, weight: 2.4, colour: Pot.ink.al(0.8), seed: seed &+ 2)
        p.inside(pathOf(outline)) {
            pen(p, offsetRing(st, 4, 0), weight: 2, colour: Pot.leaf.dk(0.5).al(0.6), wobble: 0.2, taper: false, seed: seed &+ 3)
        }
        for k in 0..<4 {
            let q = along(st, 0.2 + Double(k) * 0.2)
            for side in [-1.0, 1.0] {
                blade(p, base: q, angle: -Double.pi / 2 + side * 1.1, length: 110 - Double(k) * 12, width: 60, tone: k % 2 == 0 ? Pot.leaf : Pot.leaf.dk(0.08), serrate: 0.7, curl: side * 0.2, veins: 4, seed: seed &+ UInt64(k * 19 + Int(side + 2)))
            }
        }
        let top = st[st.count - 1]
        for j in 0..<9 {
            p.dot(Double(top.x) + Double(j % 2 == 0 ? -9 : 9), Double(top.y) - Double(j) * 10, 6, Hue(r: 0.72, g: 0.52, b: 0.74))
            p.hoop(Double(top.x) + Double(j % 2 == 0 ? -9 : 9), Double(top.y) - Double(j) * 10, 6, 1.0, Pot.ink.al(0.6))
        }
        let sect = ringOf(cx: cx + 170, cy: base - 300, rx: 40, ry: 40, steps: 4)
        wash(p, rotatedRing(sect, about: pt(cx + 170, base - 300), Double.pi / 4), Pot.leaf.lt(0.2), strength: 0.5, bleed: 2, seed: seed &+ 90)
        penEdge(p, rotatedRing(sect, about: pt(cx + 170, base - 300), Double.pi / 4), weight: 2.2, colour: Pot.ink.al(0.8), seed: seed &+ 91)
        letter(p, "square stem", at: cx + 170, base - 236, size: 16, colour: Pot.inkPale, face: "Baskerville-Italic", align: .centre)
    case .sundry:
        miniature(p, Register.find("okra"), at: pt(cx - 120, base + 20), scale: 0.42)
        miniature(p, Register.find("strawberry"), at: pt(cx + 120, base + 20), scale: 0.42)
        miniature(p, Register.find("asparagus"), at: pt(cx, base + 20), scale: 0.3)
    }
}

func drawFamilyPlate(_ family: CropFamily, dir: String) {
    let p = Leaf(1200, 900)
    let seed = hashOf("family-" + family.rawValue)
    layPaper(p, seed: seed, tone: Pot.creamWarm)
    p.flipDown()
    p.light = -2.36
    borderRule(p, inset: 30, seed: seed &+ 3)
    letter(p, family.name, at: 330, 120, size: 52, colour: Pot.ink, face: "Baskerville-Bold", align: .centre)
    letter(p, family.latin, at: 330, 158, size: 26, colour: Pot.inkSoft, face: "Baskerville-Italic", align: .centre)
    p.box(120, 180, 420, 1.4, Pot.ink.al(0.35))
    drawFamilySignature(p, family, seed: seed &+ 7)
    let members = Register.members(of: family).prefix(4)
    p.box(660, 80, 1.2, 700, Pot.ink.al(0.18))
    letter(p, "Members of the family", at: 930, 118, size: 22, colour: Pot.inkPale, face: "Baskerville-Italic", align: .centre)
    for (k, crop) in members.enumerated() {
        let col = k % 2, row = k / 2
        let ox = 800.0 + Double(col) * 260
        let oy = 400.0 + Double(row) * 300
        miniature(p, crop, at: pt(ox, oy), scale: 0.30)
        letter(p, crop.name, at: ox, oy + 30, size: 20, colour: Pot.ink, face: "Baskerville", align: .centre)
    }
    p.box(90, 790, 1020, 1.2, Pot.ink.al(0.28))
    for (i, line) in wrapText(family.signature, width: 1000, size: 22, face: "Baskerville-Italic").prefix(2).enumerated() {
        letter(p, line, at: 600, 822 + Double(i) * 30, size: 22, colour: Pot.inkSoft, face: "Baskerville-Italic", align: .centre)
    }
    p.writeJPG(dir, family.plate)
}
