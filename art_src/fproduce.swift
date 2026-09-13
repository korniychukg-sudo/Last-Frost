import Foundation
import CoreGraphics

enum Vessel { case crate, basket, jar, bunch, sack, board }

func vesselFor(_ crop: Crop) -> Vessel {
    switch crop.key {
    case "potato", "sweetpotato": return .sack
    case "garlic", "onion", "thyme", "oregano", "sage", "rosemary", "mint", "chives": return .bunch
    case "basil", "parsley", "cilantro", "dill", "nasturtium", "marigold", "calendula", "scallion": return .jar
    case "strawberry", "pea", "bushbean", "polebean", "fava", "spinach", "chard", "kale", "arugula", "mizuna", "asparagus", "rhubarb", "sunflower", "radish", "lettuce", "endive", "bokchoy": return .basket
    case "pumpkin", "wintersquash", "watermelon", "melon", "cabbage", "cauliflower", "brussels", "celery", "leek", "fennel": return .board
    default: return .crate
    }
}

func veg(_ p: Leaf, _ ring: [CGPoint], tone: Hue, gloss: Double, seed: UInt64) {
    p.shape(ring, tone)
    produce(p, ring, tone: tone, gloss: gloss, seed: seed)
}

func vegRound(_ p: Leaf, at c: CGPoint, r: Double, tone: Hue, rough: Double = 0.03, gloss: Double = 0.6, squash: Double = 0.94, seed: UInt64) {
    veg(p, lumpy(cx: Double(c.x), cy: Double(c.y), rx: r, ry: r * squash, rough: rough, steps: 32, seed: seed), tone: tone, gloss: gloss, seed: seed)
}

func longRing(from a: CGPoint, to b: CGPoint, width: Double, taperEnd: Double, taperStart: Double, bend: Double, seed: UInt64) -> [CGPoint] {
    var rng = Chip(seed)
    let ax = Double(a.x), ay = Double(a.y), bx = Double(b.x), by = Double(b.y)
    let midX = (ax + bx) / 2 + (by - ay) * bend
    let midY = (ay + by) / 2 - (bx - ax) * bend
    let spine = resample([a, pt(midX, midY), b], count: 40)
    var left: [CGPoint] = []
    var right: [CGPoint] = []
    let n = spine.count
    for i in 0..<n {
        let t = Double(i) / Double(n - 1)
        let q0 = spine[max(0, i - 1)], q1 = spine[min(n - 1, i + 1)]
        var tx = Double(q1.x - q0.x), ty = Double(q1.y - q0.y)
        let l = (tx * tx + ty * ty).squareRoot()
        if l > 0 { tx /= l; ty /= l } else { tx = 1; ty = 0 }
        let taper = taperStart + (taperEnd - taperStart) * pow(t, 1.3)
        let hw = width * 0.5 * pow(sin(.pi * t), 0.30) * taper * (1 + rng.r(-0.015, 0.015))
        left.append(pt(Double(spine[i].x) - ty * hw, Double(spine[i].y) + tx * hw))
        right.append(pt(Double(spine[i].x) + ty * hw, Double(spine[i].y) - tx * hw))
    }
    return left + right.reversed()
}

func vegLong(_ p: Leaf, from a: CGPoint, to b: CGPoint, width: Double, tone: Hue, taperEnd: Double = 0.7, taperStart: Double = 1.0, gloss: Double = 0.5, bend: Double = 0.06, seed: UInt64) {
    let ring = longRing(from: a, to: b, width: width, taperEnd: taperEnd, taperStart: taperStart, bend: bend, seed: seed)
    veg(p, ring, tone: tone, gloss: gloss, seed: seed)
}

func ribs(_ p: Leaf, at c: CGPoint, r: Double, count: Int, tone: Hue, seed: UInt64) {
    for k in 0..<count {
        let f = (Double(k) + 0.5) / Double(count) * 2 - 1
        let x = Double(c.x) + f * r * 0.9
        pen(p, [pt(x + f * r * 0.12, Double(c.y) - r * 0.86), pt(x, Double(c.y)), pt(x - f * r * 0.1, Double(c.y) + r * 0.86)], weight: max(0.8, r * 0.03), colour: tone.dk(0.45).al(0.6), wobble: 0.5, taper: true, seed: seed &+ UInt64(k * 5 + 3))
    }
}

func calyxAt(_ p: Leaf, _ c: CGPoint, r: Double, tone: Hue, seed: UInt64) {
    for k in 0..<5 {
        let a = -Double.pi / 2 + Double(k - 2) * 0.9
        blade(p, base: c, angle: a, length: r * 0.42, width: r * 0.16, tone: tone, serrate: 0, curl: 0.1, veins: 1, seed: seed &+ UInt64(k + 1))
    }
    pen(p, [c, pt(Double(c.x) + r * 0.05, Double(c.y) - r * 0.45)], weight: max(1.5, r * 0.06), colour: tone.dk(0.3), wobble: 0.3, taper: true, seed: seed &+ 9)
}

func crateBack(_ p: Leaf, x: Double, y: Double, w: Double, h: Double, seed: UInt64) {
    let back = [pt(x, y), pt(x + w, y), pt(x + w, y + h), pt(x, y + h)]
    wash(p, back, Pot.wood.dk(0.25), strength: 0.92, bleed: 2, seed: seed)
    crossHatch(p, pathOf(back), depth: 2, spacing: 5, colour: Pot.woodDark.al(0.6), seed: seed &+ 1)
    let inner = [pt(x + 10, y + 10), pt(x + w - 10, y + 10), pt(x + w - 10, y + h), pt(x + 10, y + h)]
    wash(p, inner, Pot.woodDark.dk(0.2), strength: 0.7, bleed: 3, seed: seed &+ 2)
}

func crateFront(_ p: Leaf, x: Double, y: Double, w: Double, h: Double, seed: UInt64) {
    var rng = Chip(seed)
    let slats = 3
    for k in 0..<slats {
        let sy = y + Double(k) * (h / Double(slats))
        let slat = [pt(x, sy), pt(x + w, sy), pt(x + w, sy + h / Double(slats) - 6), pt(x, sy + h / Double(slats) - 6)]
        wash(p, slat, Pot.wood.lt(0.05), strength: 0.95, bleed: 1.5, seed: seed &+ UInt64(k + 10))
        p.inside(pathOf(slat)) {
            for j in 0..<14 {
                let gx = x + rng.r(0, w)
                pen(p, [pt(gx, sy + 2), pt(gx + rng.r(-6, 6), sy + h / Double(slats) - 8)], weight: rng.r(0.6, 1.2), colour: Pot.woodDark.al(0.25), wobble: 0.6, taper: true, seed: seed &+ UInt64(k * 20 + j + 30))
            }
        }
        penEdge(p, slat, weight: 2.2, colour: Pot.ink.al(0.85), seed: seed &+ UInt64(k + 40))
        for cx in [x + 16, x + w - 16] {
            p.dot(cx, sy + h / Double(slats) / 2 - 3, 3.2, Pot.ink.lt(0.2))
            p.dot(cx - 1, sy + h / Double(slats) / 2 - 4, 1.2, Pot.white.al(0.6))
        }
    }
    let post = [pt(x - 8, y - 4), pt(x + 8, y - 4), pt(x + 8, y + h + 6), pt(x - 8, y + h + 6)]
    wash(p, post, Pot.wood.dk(0.1), strength: 0.95, bleed: 1.5, seed: seed &+ 50)
    penEdge(p, post, weight: 2, colour: Pot.ink.al(0.85), seed: seed &+ 51)
    let post2 = offsetRing(post, w, 0)
    wash(p, post2, Pot.wood.dk(0.1), strength: 0.95, bleed: 1.5, seed: seed &+ 52)
    penEdge(p, post2, weight: 2, colour: Pot.ink.al(0.85), seed: seed &+ 53)
}

func basketBack(_ p: Leaf, x: Double, y: Double, w: Double, h: Double, seed: UInt64) {
    let back = [pt(x + 10, y), pt(x + w - 10, y), pt(x + w - 30, y + h), pt(x + 30, y + h)]
    wash(p, back, Pot.straw.dk(0.35), strength: 0.95, bleed: 3, seed: seed)
    crossHatch(p, pathOf(back), depth: 2, spacing: 6, colour: Pot.woodDark.al(0.5), seed: seed &+ 1)
}

func basketFront(_ p: Leaf, x: Double, y: Double, w: Double, h: Double, seed: UInt64) {
    var rng = Chip(seed)
    let front = [pt(x, y), pt(x + w, y), pt(x + w - 28, y + h), pt(x + 28, y + h)]
    wash(p, front, Pot.straw.dk(0.1), strength: 0.97, bleed: 2, seed: seed &+ 2)
    p.inside(pathOf(front)) {
        let rows = Int(h / 14)
        for r in 0..<rows {
            let yy = y + Double(r) * 14 + 7
            var xx = x - 10.0
            var k = 0
            while xx < x + w + 10 {
                let wv = 24.0
                let up = (k + r) % 2 == 0
                pen(p, [pt(xx, yy + (up ? 3 : -3)), pt(xx + wv * 0.5, yy + (up ? -3 : 3)), pt(xx + wv, yy + (up ? 3 : -3))], weight: 5.5, colour: (up ? Pot.straw.lt(0.15) : Pot.straw.dk(0.25)), wobble: 0.3, taper: false, seed: seed &+ UInt64(r * 40 + k + 10))
                xx += wv
                k += 1
            }
        }
        for k in 0..<Int(w / 26) {
            let sx = x + 14 + Double(k) * 26
            pen(p, [pt(sx, y), pt(sx - 18 * (Double(sx - x) / w - 0.5) * 2 * 0.0 + (sx > x + w / 2 ? -8 : 8), y + h)], weight: 2.2, colour: Pot.woodDark.al(0.55), wobble: 0.3, taper: false, seed: seed &+ UInt64(k + 200))
        }
    }
    penEdge(p, front, weight: 2.6, colour: Pot.ink.al(0.85), seed: seed &+ 3)
    let rim = [pt(x - 6, y - 8), pt(x + w + 6, y - 8), pt(x + w + 6, y + 8), pt(x - 6, y + 8)]
    wash(p, rim, Pot.straw.dk(0.3), strength: 0.97, bleed: 1.5, seed: seed &+ 4)
    for k in 0..<Int(w / 16) {
        let sx = x - 6 + Double(k) * 16
        pen(p, [pt(sx, y - 8), pt(sx + 8, y + 8)], weight: 2.4, colour: Pot.woodDark.al(0.6), wobble: 0.2, taper: false, seed: seed &+ UInt64(k + 300))
    }
    penEdge(p, rim, weight: 2, colour: Pot.ink.al(0.85), seed: seed &+ 5)
    _ = rng.d()
}

func basketHandle(_ p: Leaf, x: Double, y: Double, w: Double, seed: UInt64) {
    let arc = ringOf(cx: x + w / 2, cy: y, rx: w * 0.42, ry: w * 0.36, steps: 40)
    let upper = Array(arc[21...39])
    pen(p, upper, weight: 12, colour: Pot.straw.dk(0.3), wobble: 0.4, taper: false, seed: seed)
    pen(p, offsetRing(upper, -2, -2), weight: 3, colour: Pot.strawPale.al(0.7), wobble: 0.3, taper: false, seed: seed &+ 1)
    pen(p, upper, weight: 1.4, colour: Pot.ink.al(0.5), wobble: 0.2, taper: false, seed: seed &+ 2)
    for k in stride(from: 21, to: 39, by: 2) {
        pen(p, [arc[k], pt(Double(arc[k].x) + 4, Double(arc[k].y) + 8)], weight: 1.6, colour: Pot.woodDark.al(0.6), wobble: 0.2, taper: false, seed: seed &+ UInt64(k + 10))
    }
}

func glassJar(_ p: Leaf, x: Double, y: Double, w: Double, h: Double, water: Double, seed: UInt64) {
    let body = [pt(x, y), pt(x + w, y), pt(x + w + 6, y + h * 0.1), pt(x + w + 6, y + h - 14), pt(x + w - 10, y + h), pt(x + 10, y + h), pt(x - 6, y + h - 14), pt(x - 6, y + h * 0.1)]
    if water > 0 {
        let wy = y + h * (1 - water)
        wash(p, [pt(x - 4, wy), pt(x + w + 4, wy), pt(x + w + 4, y + h - 8), pt(x + 8, y + h), pt(x - 4, y + h - 12)], Pot.glass.mix(Pot.frost, 0.4), strength: 0.5, bleed: 2, seed: seed &+ 3)
        pen(p, [pt(x - 4, wy), pt(x + w + 4, wy)], weight: 2, colour: Pot.frostDeep.al(0.5), wobble: 0.3, taper: true, seed: seed &+ 4)
    }
    wash(p, body, Pot.glass.lt(0.2), strength: 0.30, bleed: 2, seed: seed)
    penEdge(p, body, weight: 2.4, colour: Pot.ink.al(0.8), seed: seed &+ 1)
    pen(p, [pt(x + 10, y + h * 0.18), pt(x + 12, y + h * 0.85)], weight: 5, colour: Pot.white.al(0.55), wobble: 0.3, taper: true, seed: seed &+ 2)
    pen(p, [pt(x + w - 14, y + h * 0.3), pt(x + w - 12, y + h * 0.7)], weight: 2.5, colour: Pot.white.al(0.4), wobble: 0.3, taper: true, seed: seed &+ 5)
    let neck = [pt(x + 4, y - 14), pt(x + w - 4, y - 14), pt(x + w, y), pt(x, y)]
    wash(p, neck, Pot.glass.lt(0.1), strength: 0.35, bleed: 1.5, seed: seed &+ 6)
    penEdge(p, neck, weight: 2, colour: Pot.ink.al(0.75), seed: seed &+ 7)
    for k in 0..<3 {
        let ty = y - 12 + Double(k) * 4
        pen(p, [pt(x + 4, ty), pt(x + w - 4, ty)], weight: 1.0, colour: Pot.ink.al(0.35), wobble: 0.2, taper: false, seed: seed &+ UInt64(k + 20))
    }
}

func sackShape(_ p: Leaf, cx: Double, top: Double, w: Double, h: Double, seed: UInt64) -> [CGPoint] {
    var ring: [CGPoint] = []
    for i in 0..<40 {
        let t = Double(i) / 40
        let a = -Double.pi / 2 + t * 2 * .pi
        var rx = w * 0.5, ry = h * 0.5
        if sin(a) < 0 { rx *= 0.72; ry *= 0.9 }
        let k = 1 + 0.05 * sin(t * 26)
        ring.append(pt(cx + cos(a) * rx * k, top + h * 0.5 + sin(a) * ry * k))
    }
    return ring
}

func hessian(_ p: Leaf, _ ring: [CGPoint], seed: UInt64) {
    wash(p, ring, Pot.strawPale.dk(0.25), strength: 0.97, bleed: 3, seed: seed)
    let path = pathOf(ring)
    let box = path.boundingBox
    p.inside(path) {
        var y = Double(box.minY)
        while y < Double(box.maxY) {
            pen(p, [pt(Double(box.minX), y), pt(Double(box.maxX), y + 2)], weight: 1.0, colour: Pot.sepia.al(0.22), wobble: 0.5, taper: false, seed: seed &+ UInt64(Int(y)))
            y += 7
        }
        var x = Double(box.minX)
        while x < Double(box.maxX) {
            pen(p, [pt(x, Double(box.minY)), pt(x + 3, Double(box.maxY))], weight: 1.0, colour: Pot.sepia.al(0.18), wobble: 0.5, taper: false, seed: seed &+ UInt64(Int(x) + 999))
            x += 7
        }
    }
    roundShade(p, ring, inset: 60, depth: 2, spacing: 6, colour: Pot.sepia.dk(0.2), seed: seed &+ 5)
    penOutline(p, ring, weight: 2.6, colour: Pot.ink.al(0.85), seed: seed &+ 6)
}

func paperTag(_ p: Leaf, at c: CGPoint, text: String, angle: Double, seed: UInt64) {
    let w = max(120.0, letterWidth(text, size: 26, face: "Baskerville-Italic") + 44), h = 54.0
    let cx = Double(c.x), cy = Double(c.y)
    let ring = rotatedRing([pt(cx - w / 2, cy - h / 2), pt(cx + w / 2 - 10, cy - h / 2), pt(cx + w / 2, cy), pt(cx + w / 2 - 10, cy + h / 2), pt(cx - w / 2, cy + h / 2)], about: c, angle)
    p.shape(offsetRing(ring, 4, 6), Pot.shadowInk.al(0.18))
    wash(p, ring, Pot.creamWarm.lt(0.35), strength: 0.97, bleed: 1.5, seed: seed)
    penEdge(p, ring, weight: 1.6, colour: Pot.ink.al(0.75), seed: seed &+ 1)
    let hole = rotatedRing([pt(cx + w / 2 - 14, cy)], about: c, angle)[0]
    p.hoop(Double(hole.x), Double(hole.y), 4, 1.4, Pot.ink.al(0.7))
    pen(p, [hole, pt(Double(hole.x) + 26, Double(hole.y) - 30)], weight: 1.4, colour: Pot.sepia, wobble: 0.6, taper: false, seed: seed &+ 2)
    letter(p, text, at: cx - 5, cy + 9, size: 26, colour: Pot.ink, face: "Baskerville-Italic", align: .centre, rotate: angle)
}

func seasonStamp(_ p: Leaf, at c: CGPoint, text: String, angle: Double, seed: UInt64) {
    let w = letterWidth(text, size: 20, face: "Baskerville-Bold") + 36, h = 40.0
    let cx = Double(c.x), cy = Double(c.y)
    let ring = rotatedRing([pt(cx - w / 2, cy - h / 2), pt(cx + w / 2, cy - h / 2), pt(cx + w / 2, cy + h / 2), pt(cx - w / 2, cy + h / 2)], about: c, angle)
    penEdge(p, ring, weight: 2.4, colour: Pot.terracotta.al(0.75), seed: seed)
    penEdge(p, scaledRing(ring, about: c, 0.9), weight: 0.9, colour: Pot.terracotta.al(0.5), seed: seed &+ 1)
    letter(p, text, at: cx, cy + 7, size: 20, colour: Pot.terracotta.al(0.8), face: "Baskerville-Bold", align: .centre, tracking: 2.5, rotate: angle)
}

func produceTone(_ crop: Crop) -> Hue {
    switch crop.key {
    case "tomato": return Pot.tomato
    case "pepper": return Pot.tomato.mix(Pot.pumpkin, 0.35)
    case "eggplant": return Pot.aubergine
    case "tomatillo": return Pot.leafPale.mix(Pot.yellow, 0.3)
    case "potato": return Pot.straw.mix(Pot.soilLight, 0.35)
    case "sweetpotato": return Pot.terracotta.mix(Pot.beet, 0.3)
    case "carrot": return Pot.carrot
    case "parsnip": return Pot.strawPale.lt(0.2)
    case "radish": return Pot.tomato.mix(Pot.beet, 0.3)
    case "beet": return Pot.beet
    case "turnip": return Pot.white.dk(0.06)
    case "rutabaga": return Pot.straw.mix(Pot.beet, 0.25)
    case "kohlrabi": return Pot.leafPale.mix(Pot.glass, 0.3)
    case "onion": return Pot.straw.mix(Pot.terracotta, 0.35)
    case "garlic": return Pot.white.dk(0.05)
    case "leek", "scallion": return Pot.white.dk(0.05)
    case "corn": return Pot.yellow
    case "pumpkin": return Pot.pumpkin
    case "wintersquash": return Pot.straw.mix(Pot.pumpkin, 0.35)
    case "zucchini": return Pot.leafDeep.lt(0.05)
    case "cucumber": return Pot.leaf.dk(0.1)
    case "melon": return Pot.strawPale.mix(Pot.leafGrey, 0.4)
    case "watermelon": return Pot.leafDeep.dk(0.05)
    case "okra": return Pot.leaf.lt(0.1)
    case "strawberry": return Pot.tomato.mix(Pot.beet, 0.2)
    case "cabbage": return Pot.leafBlue.lt(0.15)
    case "cauliflower": return Pot.white.dk(0.04)
    case "broccoli": return Pot.leafDeep.mix(Pot.leafBlue, 0.4)
    case "brussels": return Pot.leaf.mix(Pot.leafBlue, 0.4)
    case "lettuce", "endive": return Pot.leafPale
    case "bokchoy": return Pot.white.dk(0.06)
    case "celery": return Pot.leafPale.lt(0.15)
    case "fennel": return Pot.white.dk(0.08).mix(Pot.leafPale, 0.2)
    case "rhubarb": return Pot.tomato.mix(Pot.beet, 0.35)
    case "asparagus": return Pot.leaf.lt(0.15)
    case "sunflower": return Pot.yellow
    case "nasturtium": return Pot.pumpkin.mix(Pot.tomato, 0.3)
    case "marigold": return Pot.pumpkin
    case "calendula": return Pot.yellow.mix(Pot.pumpkin, 0.3)
    case "pea", "bushbean", "polebean": return Pot.leaf.lt(0.2)
    case "fava": return Pot.leafPale.mix(Pot.leafBlue, 0.3)
    case "kale": return Pot.leafBlue
    case "chard": return Pot.leafDeep.lt(0.08)
    case "spinach": return Pot.leafDeep.lt(0.04)
    case "arugula", "mizuna", "parsley", "cilantro", "dill", "basil", "mint", "chives": return Pot.leaf
    case "thyme", "sage", "rosemary", "oregano": return Pot.leafGrey
    default: return Pot.leaf
    }
}

func pileRound(_ p: Leaf, in rect: CGRect, count: Int, r: Double, tone: Hue, rough: Double, gloss: Double, calyx: Bool, ribbed: Int, squash: Double, seed: UInt64) {
    var rng = Chip(seed)
    var items: [(Double, Double, Double, Double)] = []
    let cols = max(1, Int(Double(rect.width) / (r * 1.7)))
    for k in 0..<count {
        let row = k / cols, col = k % cols
        let x = Double(rect.minX) + r + Double(col) * (Double(rect.width) - 2 * r) / Double(max(1, cols - 1)) + rng.r(-r * 0.2, r * 0.2)
        let y = Double(rect.maxY) - r * 0.9 - Double(row) * r * 1.25 + rng.r(-r * 0.1, r * 0.1)
        items.append((x, y, r * rng.r(0.88, 1.08), rng.r(0, 1)))
    }
    items.sort { $0.1 < $1.1 }
    for (k, it) in items.enumerated() {
        let c = pt(it.0, it.1)
        vegRound(p, at: c, r: it.2, tone: tone.lt(it.3 * 0.12).dk((1 - it.3) * 0.06), rough: rough, gloss: gloss, squash: squash, seed: seed &+ UInt64(k * 7 + 1))
        if ribbed > 0 { ribs(p, at: c, r: it.2 * squash, count: ribbed, tone: tone, seed: seed &+ UInt64(k * 3 + 50)) }
        if calyx { calyxAt(p, pt(it.0 - it.2 * 0.1, it.1 - it.2 * 0.72), r: it.2, tone: Pot.leaf, seed: seed &+ UInt64(k * 5 + 80)) }
    }
}

func pileLong(_ p: Leaf, in rect: CGRect, count: Int, length: Double, width: Double, tone: Hue, taperEnd: Double, gloss: Double, angle: Double, calyx: Bool, seed: UInt64) {
    var rng = Chip(seed)
    var items: [(Double, Double, Double)] = []
    let vertical = abs(sin(angle)) > 0.7
    let rows = vertical ? 1 : (count > 4 ? 2 : 1)
    let perRow = Int(ceil(Double(count) / Double(rows)))
    for k in 0..<count {
        let row = k / perRow, col = k % perRow
        let t = perRow > 1 ? Double(col) / Double(perRow - 1) : 0.5
        let span = vertical ? Double(rect.width) - width * 1.4 : Double(rect.width) - length * 0.9
        let x = Double(rect.minX) + (vertical ? width * 0.7 : length * 0.45) + t * span + rng.r(-8, 8) + Double(row) * width * 0.3
        let y = vertical ? Double(rect.maxY) - length * abs(sin(angle)) * 0.32 + rng.r(-6, 6)
                         : Double(rect.maxY) - width * 0.5 - Double(row) * width * 0.74 + rng.r(-4, 4)
        items.append((x, y, angle + rng.r(-0.1, 0.1)))
    }
    items.sort { $0.1 < $1.1 }
    for (k, it) in items.enumerated() {
        let a = pt(it.0 - cos(it.2) * length * 0.5, it.1 - sin(it.2) * length * 0.5)
        let b = pt(it.0 + cos(it.2) * length * 0.5, it.1 + sin(it.2) * length * 0.5)
        vegLong(p, from: a, to: b, width: width, tone: tone.lt(rng.r(0, 0.1)), taperEnd: taperEnd, gloss: gloss, seed: seed &+ UInt64(k * 11 + 1))
        if calyx { calyxAt(p, a, r: width * 1.2, tone: Pot.leaf, seed: seed &+ UInt64(k * 3 + 60)) }
    }
}

func leafBunch(_ p: Leaf, at base: CGPoint, spread: Double, length: Double, tone: Hue, kind: String, count: Int, seed: UInt64) {
    var rng = Chip(seed)
    for k in 0..<count {
        let u = count > 1 ? Double(k) / Double(count - 1) : 0.5
        let a = -Double.pi / 2 + (u - 0.5) * spread + rng.r(-0.08, 0.08)
        let len = length * rng.r(0.8, 1.05)
        switch kind {
        case "crinkle": crinkleLeaf(p, base: base, angle: a, length: len, width: len * 0.55, tone: tone.lt(rng.r(0, 0.15)), seed: seed &+ UInt64(k * 7))
        case "strap": strapLeaf(p, base: base, angle: a, length: len, width: len * 0.14, tone: tone, curve: (u - 0.5) * 0.8, fold: true, seed: seed &+ UInt64(k * 7))
        case "feather": featheryLeaf(p, base: base, angle: a, length: len, tone: tone, fineness: 6, seed: seed &+ UInt64(k * 7))
        case "pinnate": pinnateLeaf(p, base: base, angle: a, length: len, tone: tone, leaflets: 6, leafletSize: len * 0.24, serrate: 0.4, seed: seed &+ UInt64(k * 7))
        case "round": roundLeaf(p, at: pt(Double(base.x) + cos(a) * len * 0.5, Double(base.y) + sin(a) * len * 0.5), angle: a, size: len * 0.5, tone: tone.lt(rng.r(0, 0.12)), seed: seed &+ UInt64(k * 7))
        case "lobed": heartLeaf(p, at: pt(Double(base.x) + cos(a) * len * 0.6, Double(base.y) + sin(a) * len * 0.6), angle: a, size: len * 0.4, tone: tone, lobes: 5, seed: seed &+ UInt64(k * 7))
        case "sprig":
            let sp = stemRun(base, a, len, curve: (u - 0.5) * 0.5, wobble: 0.02, steps: 8, seed: seed &+ UInt64(k * 7))
            pen(p, sp, weight: 2.4, colour: tone.dk(0.5), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 7 + 1))
            for j in 1..<9 {
                let q = along(sp, Double(j) / 9)
                blade(p, base: q, angle: a + (j % 2 == 0 ? 0.9 : -0.9), length: len * 0.12, width: len * 0.05, tone: tone.lt(rng.r(0, 0.1)), serrate: 0, curl: 0, veins: 0, seed: seed &+ UInt64(k * 20 + j))
            }
        default:
            let sp = stemRun(base, a, len * 0.6, curve: (u - 0.5) * 0.6, wobble: 0.02, steps: 6, seed: seed &+ UInt64(k * 7))
            pen(p, sp, weight: 3, colour: tone.dk(0.45), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 7 + 1))
            let e = sp[sp.count - 1]
            blade(p, base: e, angle: a, length: len * 0.45, width: len * 0.3, tone: tone.lt(rng.r(0, 0.12)), serrate: 0.15, curl: (u - 0.5) * 0.3, veins: 4, seed: seed &+ UInt64(k * 7 + 2))
        }
    }
}

func drawProduceFigure(_ p: Leaf, _ crop: Crop, seed: UInt64) {
    var rng = Chip(seed)
    let tone = produceTone(crop)
    let vessel = vesselFor(crop)
    let floorY = 720.0
    switch vessel {
    case .crate:
        let x = 170.0, w = 560.0, y = 530.0, h = 170.0
        crateBack(p, x: x, y: y - 60, w: w, h: h + 60, seed: seed &+ 1)
        let inner = CGRect(x: x + 24, y: 300, width: w - 48, height: 262)
        switch crop.key {
        case "tomato": pileRound(p, in: inner, count: 11, r: 62, tone: tone, rough: 0.03, gloss: 0.75, calyx: true, ribbed: 0, squash: 0.9, seed: seed &+ 2)
        case "tomatillo": pileRound(p, in: inner, count: 12, r: 52, tone: tone, rough: 0.03, gloss: 0.55, calyx: true, ribbed: 0, squash: 0.95, seed: seed &+ 2)
        case "pepper": pileLong(p, in: inner, count: 7, length: 190, width: 88, tone: tone, taperEnd: 0.45, gloss: 0.8, angle: -0.35, calyx: true, seed: seed &+ 2)
        case "eggplant": pileLong(p, in: inner, count: 5, length: 230, width: 110, tone: tone, taperEnd: 0.5, gloss: 0.85, angle: -0.3, calyx: true, seed: seed &+ 2)
        case "zucchini": pileLong(p, in: inner, count: 6, length: 300, width: 72, tone: tone, taperEnd: 0.8, gloss: 0.6, angle: -0.15, calyx: false, seed: seed &+ 2)
        case "cucumber": pileLong(p, in: inner, count: 7, length: 250, width: 62, tone: tone, taperEnd: 0.8, gloss: 0.55, angle: -0.12, calyx: false, seed: seed &+ 2)
        case "okra": pileLong(p, in: inner, count: 12, length: 160, width: 40, tone: tone, taperEnd: 0.15, gloss: 0.45, angle: -0.45, calyx: true, seed: seed &+ 2)
        case "carrot": pileLong(p, in: inner, count: 10, length: 230, width: 54, tone: tone, taperEnd: 0.1, gloss: 0.45, angle: 1.25, calyx: true, seed: seed &+ 2)
        case "parsnip": pileLong(p, in: inner, count: 8, length: 230, width: 70, tone: tone, taperEnd: 0.06, gloss: 0.35, angle: 1.2, calyx: true, seed: seed &+ 2)
        case "beet": pileRound(p, in: inner, count: 10, r: 58, tone: tone, rough: 0.05, gloss: 0.5, calyx: false, ribbed: 0, squash: 1.0, seed: seed &+ 2)
        case "turnip": pileRound(p, in: inner, count: 10, r: 60, tone: tone, rough: 0.04, gloss: 0.5, calyx: false, ribbed: 0, squash: 0.85, seed: seed &+ 2)
        case "rutabaga": pileRound(p, in: inner, count: 8, r: 70, tone: tone, rough: 0.05, gloss: 0.4, calyx: false, ribbed: 0, squash: 0.9, seed: seed &+ 2)
        case "kohlrabi": pileRound(p, in: inner, count: 9, r: 64, tone: tone, rough: 0.05, gloss: 0.45, calyx: false, ribbed: 0, squash: 0.85, seed: seed &+ 2)
        case "onion": pileRound(p, in: inner, count: 12, r: 56, tone: tone, rough: 0.03, gloss: 0.55, calyx: false, ribbed: 5, squash: 1.0, seed: seed &+ 2)
        case "corn":
            pileLong(p, in: inner, count: 6, length: 290, width: 70, tone: tone, taperEnd: 0.5, gloss: 0.4, angle: -0.2, calyx: false, seed: seed &+ 2)
        case "wintersquash": pileRound(p, in: inner, count: 5, r: 92, tone: tone, rough: 0.04, gloss: 0.45, calyx: false, ribbed: 7, squash: 0.8, seed: seed &+ 2)
        case "melon": pileRound(p, in: inner, count: 5, r: 96, tone: tone, rough: 0.03, gloss: 0.35, calyx: false, ribbed: 0, squash: 0.92, seed: seed &+ 2)
        default: pileRound(p, in: inner, count: 10, r: 60, tone: tone, rough: 0.04, gloss: 0.5, calyx: false, ribbed: 0, squash: 0.92, seed: seed &+ 2)
        }
        if crop.key == "corn" {
            for k in 0..<6 {
                let cxk = 250.0 + Double(k) * 84
                for j in 0..<9 {
                    pen(p, [pt(cxk - 80, 500 + Double(j) * 9 - Double(k % 2) * 24), pt(cxk + 60, 495 + Double(j) * 9 - Double(k % 2) * 24)], weight: 1.0, colour: Pot.straw.dk(0.45).al(0.5), wobble: 0.3, taper: false, seed: seed &+ UInt64(k * 9 + j + 300))
                }
            }
        }
        if crop.key == "melon" {
            p.inside(pathOf([pt(x, y - 200), pt(x + w, y - 200), pt(x + w, y + h), pt(x, y + h)])) {
                for k in 0..<400 {
                    let px = rng.r(x, x + w), py = rng.r(y - 120, y + 140)
                    pen(p, [pt(px, py), pt(px + rng.r(-6, 6), py + rng.r(-6, 6))], weight: 1.2, colour: Pot.strawPale.lt(0.3).al(0.7), wobble: 0.3, taper: true, seed: seed &+ UInt64(k + 400))
                }
            }
        }
        crateFront(p, x: x, y: y, w: w, h: h, seed: seed &+ 3)
    case .basket:
        let x = 170.0, w = 560.0, y = 560.0, h = 140.0
        basketBack(p, x: x, y: y - 50, w: w, h: h + 50, seed: seed &+ 1)
        switch crop.key {
        case "strawberry":
            var items: [(Double, Double)] = []
            for k in 0..<18 { items.append((x + 60 + Double(k % 6) * 88 + rng.r(-10, 10), y - 110 + Double(k / 6) * 38 + rng.r(-6, 6))) }
            items.sort { $0.1 < $1.1 }
            for (k, it) in items.enumerated() {
                let berry = [pt(it.0 - 26, it.1 - 22), pt(it.0 + 26, it.1 - 22), pt(it.0 + 30, it.1), pt(it.0 + 4, it.1 + 32), pt(it.0 - 4, it.1 + 32), pt(it.0 - 30, it.1)]
                veg(p, resample(berry + [berry[0]], count: 30), tone: tone, gloss: 0.7, seed: seed &+ UInt64(k * 3 + 10))
                p.inside(pathOf(berry)) {
                    for _ in 0..<9 { p.egg(it.0 + rng.r(-20, 20), it.1 + rng.r(-14, 20), 1.6, 2.2, Pot.yellow.al(0.85)) }
                }
                for j in 0..<5 {
                    let a = -Double.pi / 2 + Double(j - 2) * 0.55
                    blade(p, base: pt(it.0, it.1 - 20), angle: a, length: 16, width: 8, tone: Pot.leaf, serrate: 0, curl: 0, veins: 0, seed: seed &+ UInt64(k * 5 + j + 40))
                }
            }
        case "pea", "bushbean", "polebean", "fava":
            let beads = crop.key == "fava" ? 4 : (crop.key == "pea" ? 6 : 5)
            let widthPod = crop.key == "fava" ? 44.0 : (crop.key == "pea" ? 26.0 : 22.0)
            let lenPod = crop.key == "fava" ? 190.0 : (crop.key == "pea" ? 130.0 : 150.0)
            for k in 0..<12 {
                let px = x + 70 + Double(k % 6) * 88 + rng.r(-10, 10), py = y - 100 + Double(k / 6) * 56
                let a = -0.4 + rng.r(-0.3, 0.3)
                let s = pt(px - cos(a) * lenPod / 2, py - sin(a) * lenPod / 2), e = pt(px + cos(a) * lenPod / 2, py + sin(a) * lenPod / 2)
                p.shape(bandOf([s, e], [widthPod * 0.5, widthPod, widthPod * 0.5], per: 6), tone)
                podShape(p, from: s, to: e, width: widthPod, tone: tone.lt(rng.r(0, 0.1)), beads: beads, seed: seed &+ UInt64(k * 7 + 10))
            }
        case "radish":
            for k in 0..<3 {
                let bx = x + 120 + Double(k) * 160
                for j in 0..<6 {
                    let a = -Double.pi / 2 + Double(j - 3) * 0.16
                    strapLeaf(p, base: pt(bx, y - 30), angle: a, length: 170, width: 26, tone: Pot.leaf, curve: Double(j - 3) * 0.2, fold: false, seed: seed &+ UInt64(k * 10 + j))
                }
                for j in 0..<4 {
                    vegRound(p, at: pt(bx - 40 + Double(j) * 26, y - 20 + Double(j % 2) * 18), r: 26, tone: tone, rough: 0.04, gloss: 0.6, squash: 1.0, seed: seed &+ UInt64(k * 10 + j + 50))
                    pen(p, [pt(bx - 40 + Double(j) * 26, y + 4 + Double(j % 2) * 18), pt(bx - 38 + Double(j) * 26, y + 34 + Double(j % 2) * 18)], weight: 2, colour: Pot.strawPale.dk(0.3), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 10 + j + 70))
                }
            }
        case "asparagus", "rhubarb":
            let n = crop.key == "asparagus" ? 14 : 7
            let wSp = crop.key == "asparagus" ? 22.0 : 40.0
            for k in 0..<n {
                let px = x + 80 + Double(k) * (w - 160) / Double(n - 1) + rng.r(-4, 4)
                vegLong(p, from: pt(px + 20, y + 40), to: pt(px - 30, y - 300), width: wSp, tone: crop.key == "asparagus" ? tone.mix(Pot.aubergine, Double(k % 3) * 0.12) : tone, taperEnd: 0.55, taperStart: 0.9, gloss: 0.5, bend: 0.03, seed: seed &+ UInt64(k * 3 + 10))
                if crop.key == "asparagus" {
                    for j in 0..<4 {
                        let t = 0.55 + Double(j) * 0.12
                        let q = pt(px + 20 - 50 * t, y + 40 - 340 * t)
                        blade(p, base: q, angle: -Double.pi / 2 + (j % 2 == 0 ? 0.6 : -0.6), length: 14, width: 7, tone: Pot.aubergine.mix(Pot.leaf, 0.5), serrate: 0, curl: 0, veins: 0, seed: seed &+ UInt64(k * 5 + j + 50))
                    }
                } else {
                    heartLeaf(p, at: pt(px - 44, y - 350), angle: -Double.pi / 2, size: 48, tone: Pot.leafDeep.lt(0.1), lobes: 5, seed: seed &+ UInt64(k + 60))
                }
            }
            let tie = [pt(x + 60, y - 90), pt(x + w - 60, y - 90)]
            pen(p, tie, weight: 8, colour: Pot.sepia, wobble: 0.4, taper: false, seed: seed &+ 90)
        case "spinach", "chard", "kale", "arugula", "mizuna", "lettuce", "endive", "bokchoy":
            let kind: String = crop.key == "kale" || crop.key == "lettuce" || crop.key == "endive" ? "crinkle" : (crop.key == "chard" || crop.key == "bokchoy" ? "leaf" : (crop.key == "arugula" || crop.key == "mizuna" ? "lobed" : "round"))
            let leafTone: Hue = crop.key == "chard" ? Pot.leafDeep.lt(0.08) : tone
            for k in 0..<3 {
                let bx = x + 120 + Double(k) * 160
                leafBunch(p, at: pt(bx, y + 30), spread: 1.9, length: 250, tone: leafTone, kind: kind, count: 7, seed: seed &+ UInt64(k * 100 + 10))
                if crop.key == "chard" {
                    for j in 0..<5 {
                        let a = -Double.pi / 2 + Double(j - 2) * 0.35
                        pen(p, [pt(bx, y + 30), pt(bx + cos(a) * 170, y + 30 + sin(a) * 170)], weight: 9, colour: Pot.tomato.mix(Pot.yellow, Double(j % 2) * 0.6), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 10 + j + 200))
                    }
                }
                if crop.key == "bokchoy" {
                    for j in 0..<5 {
                        let a = -Double.pi / 2 + Double(j - 2) * 0.3
                        pen(p, [pt(bx, y + 30), pt(bx + cos(a) * 140, y + 30 + sin(a) * 140)], weight: 18, colour: Pot.white.dk(0.06), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 10 + j + 200))
                    }
                }
            }
        case "sunflower":
            let head = pt(450, 330)
            for k in 0..<26 {
                let a = Double(k) / 26 * 2 * .pi
                blade(p, base: pt(Double(head.x) + cos(a) * 110, Double(head.y) + sin(a) * 110), angle: a, length: 110, width: 34, tone: Pot.yellow.lt(Double(k % 2) * 0.1), serrate: 0, curl: 0, veins: 1, seed: seed &+ UInt64(k + 10))
            }
            let disc = lumpy(cx: Double(head.x), cy: Double(head.y), rx: 120, ry: 116, rough: 0.02, steps: 40, seed: seed &+ 40)
            veg(p, disc, tone: Pot.sepia.dk(0.3), gloss: 0.15, seed: seed &+ 41)
            p.inside(pathOf(disc)) {
                for k in 0..<700 {
                    let rr = (Double(k) / 700).squareRoot() * 112
                    let a = Double(k) * 2.39996
                    p.dot(Double(head.x) + cos(a) * rr, Double(head.y) + sin(a) * rr, 3.2, k % 2 == 0 ? Pot.ink.lt(0.15) : Pot.strawPale.dk(0.2))
                }
            }
            pen(p, [pt(Double(head.x) + 40, Double(head.y) + 150), pt(Double(head.x) + 90, y + 20)], weight: 14, colour: Pot.leaf.dk(0.2), wobble: 0.4, taper: false, seed: seed &+ 60)
        default:
            leafBunch(p, at: pt(450, y + 20), spread: 2.2, length: 260, tone: tone, kind: "leaf", count: 9, seed: seed &+ 10)
        }
        basketFront(p, x: x, y: y, w: w, h: h, seed: seed &+ 3)
        basketHandle(p, x: x, y: y, w: w, seed: seed &+ 4)
    case .jar:
        let jx = 340.0, jw = 220.0, jy = 430.0, jh = 260.0
        p.shape(offsetRing([pt(jx - 6, jy), pt(jx + jw + 6, jy), pt(jx + jw + 6, jy + jh), pt(jx - 6, jy + jh)], 14, 12), Pot.shadowInk.al(0.14))
        let kind: String
        switch crop.key {
        case "dill": kind = "feather"
        case "cilantro", "parsley": kind = "pinnate"
        case "basil": kind = "leaf"
        case "scallion": kind = "strap"
        default: kind = "round"
        }
        let base = pt(jx + jw / 2, jy + jh - 40)
        if ["nasturtium", "marigold", "calendula"].contains(crop.key) {
            for k in 0..<7 {
                let a = -Double.pi / 2 + Double(k - 3) * 0.28
                let sp = stemRun(base, a, 300, curve: Double(k - 3) * 0.15, wobble: 0.02, steps: 8, seed: seed &+ UInt64(k))
                pen(p, sp, weight: 4, colour: Pot.leaf.dk(0.3), wobble: 0.3, taper: true, seed: seed &+ UInt64(k + 1))
                if crop.key == "nasturtium" {
                    roundLeaf(p, at: along(sp, 0.5), angle: a + 0.5, size: 40, tone: Pot.leafPale, aspect: 0.9, seed: seed &+ UInt64(k + 20))
                }
                let e = sp[sp.count - 1]
                daisy(p, at: e, r: crop.key == "marigold" ? 42 : 48, petals: crop.key == "marigold" ? 16 : 12, petalTone: tone.lt(Double(k % 2) * 0.1), centreTone: crop.key == "nasturtium" ? tone.dk(0.2) : Pot.sepia.mix(Pot.pumpkin, 0.4), petalWidth: crop.key == "marigold" ? 0.3 : 0.4, seed: seed &+ UInt64(k + 30))
            }
        } else {
            leafBunch(p, at: base, spread: 1.4, length: 300, tone: tone, kind: kind, count: 9, seed: seed &+ 10)
        }
        glassJar(p, x: jx, y: jy, w: jw, h: jh, water: 0.6, seed: seed &+ 5)
    case .bunch:
        let nail = pt(450, 130)
        p.dot(Double(nail.x), Double(nail.y), 6, Pot.ink.lt(0.2))
        p.dot(Double(nail.x) - 1.5, Double(nail.y) - 1.5, 2, Pot.white.al(0.6))
        switch crop.key {
        case "garlic", "onion":
            let plaitTone = crop.key == "garlic" ? Pot.strawPale.dk(0.15) : Pot.straw.mix(Pot.terracotta, 0.3).dk(0.1)
            let spine = stemRun(nail, .pi / 2, 480, curve: 0.08, wobble: 0.01, steps: 10, seed: seed)
            let braid = bandOf(spine, [18, 36, 40, 34, 22], per: 4)
            wash(p, braid, plaitTone, strength: 0.95, bleed: 2, seed: seed &+ 1)
            p.inside(pathOf(braid)) {
                for k in 0..<22 {
                    let q = along(spine, Double(k) / 22)
                    pen(p, [pt(Double(q.x) - 18, Double(q.y)), pt(Double(q.x) + 18, Double(q.y) + 10)], weight: 2.2, colour: Pot.sepia.al(0.5), wobble: 0.4, taper: true, seed: seed &+ UInt64(k + 10))
                }
            }
            penOutline(p, braid, weight: 1.8, colour: Pot.ink.al(0.7), seed: seed &+ 40)
            var bulbs: [(Double, Double, Double)] = []
            for k in 0..<9 {
                let t = 0.25 + Double(k) * 0.085
                let q = along(spine, t)
                let side = k % 2 == 0 ? -1.0 : 1.0
                bulbs.append((Double(q.x) + side * 52, Double(q.y) + 10, 44 + Double(k % 3) * 4))
            }
            for (k, b) in bulbs.enumerated() {
                let ring = lumpy(cx: b.0, cy: b.1, rx: b.2, ry: b.2 * 0.92, rough: 0.03, steps: 28, seed: seed &+ UInt64(k + 60))
                var shaped: [CGPoint] = []
                for (i, q) in ring.enumerated() {
                    let a = Double(i) / Double(ring.count) * 2 * .pi
                    let neck = sin(a) < 0 ? 1 - 0.35 * pow(-sin(a), 2) : 1
                    shaped.append(pt(b.0 + (Double(q.x) - b.0) * neck, Double(q.y)))
                }
                veg(p, shaped, tone: tone, gloss: 0.45, seed: seed &+ UInt64(k + 70))
                p.inside(pathOf(shaped)) {
                    for j in 0..<6 {
                        let f = (Double(j) + 0.5) / 6 * 2 - 1
                        pen(p, [pt(b.0 + f * b.2 * 0.5, b.1 - b.2 * 0.8), pt(b.0 + f * b.2 * 0.85, b.1 + b.2 * 0.1), pt(b.0 + f * b.2 * 0.55, b.1 + b.2 * 0.85)], weight: 1.6, colour: tone.dk(0.4).al(0.6), wobble: 0.5, taper: true, seed: seed &+ UInt64(k * 9 + j + 100))
                    }
                }
                for j in 0..<6 {
                    pen(p, [pt(b.0 + Double(j - 3) * 8, b.1 + b.2 * 0.9), pt(b.0 + Double(j - 3) * 12, b.1 + b.2 * 0.9 + rng.r(10, 22))], weight: 1.4, colour: Pot.strawPale.dk(0.4), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 9 + j + 130))
                }
            }
        default:
            let tie = pt(450, 190)
            let bunchTone = tone
            let kind = crop.key == "chives" ? "strap" : (crop.key == "mint" || crop.key == "sage" ? "leaf" : "sprig")
            p.ctx.saveGState()
            p.ctx.translateBy(x: CGFloat(Double(tie.x)), y: CGFloat(Double(tie.y)))
            p.ctx.scaleBy(x: 1, y: -1)
            p.ctx.translateBy(x: CGFloat(-Double(tie.x)), y: CGFloat(-Double(tie.y)))
            leafBunch(p, at: tie, spread: 1.5, length: crop.key == "chives" ? 380 : 330, tone: bunchTone, kind: kind, count: crop.key == "chives" ? 24 : 11, seed: seed &+ 10)
            p.ctx.restoreGState()
            pen(p, [nail, tie], weight: 2.4, colour: Pot.sepia, wobble: 0.4, taper: false, seed: seed &+ 20)
            for k in 0..<4 {
                pen(p, [pt(Double(tie.x) - 30, Double(tie.y) + 6 + Double(k) * 7), pt(Double(tie.x) + 30, Double(tie.y) + 2 + Double(k) * 7)], weight: 3.6, colour: Pot.sepia.lt(0.1), wobble: 0.4, taper: false, seed: seed &+ UInt64(k + 30))
            }
        }
    case .sack:
        let ring = sackShape(p, cx: 450, top: 260, w: 460, h: 440, seed: seed)
        p.shape(offsetRing(ring, 16, 12), Pot.shadowInk.al(0.16))
        hessian(p, ring, seed: seed &+ 1)
        let mouth = [pt(300, 290), pt(600, 290), pt(560, 340), pt(340, 340)]
        wash(p, mouth, Pot.soilDark.dk(0.2), strength: 0.95, bleed: 3, seed: seed &+ 2)
        var items: [(Double, Double, Double)] = []
        for k in 0..<9 { items.append((330 + Double(k % 5) * 62 + rng.r(-8, 8), 250 + Double(k / 5) * 40 + rng.r(-10, 10), rng.r(30, 42))) }
        items.sort { $0.1 < $1.1 }
        for (k, it) in items.enumerated() {
            let potato = lumpy(cx: it.0, cy: it.1, rx: it.2, ry: it.2 * 0.72, rough: 0.07, steps: 22, seed: seed &+ UInt64(k + 10))
            let rot = rotatedRing(potato, about: pt(it.0, it.1), rng.r(-0.5, 0.5))
            veg(p, rot, tone: tone.lt(rng.r(0, 0.1)), gloss: 0.2, seed: seed &+ UInt64(k + 20))
            p.inside(pathOf(rot)) {
                for _ in 0..<5 { p.dot(it.0 + rng.r(-it.2 * 0.6, it.2 * 0.6), it.1 + rng.r(-it.2 * 0.4, it.2 * 0.4), rng.r(1.5, 2.6), tone.dk(0.5).al(0.6)) }
            }
        }
        for (k, q) in [pt(250, 620), pt(650, 640), pt(310, 690)].enumerated() {
            let potato = lumpy(cx: Double(q.x), cy: Double(q.y), rx: 40, ry: 30, rough: 0.07, steps: 22, seed: seed &+ UInt64(k + 60))
            veg(p, potato, tone: tone.lt(0.05), gloss: 0.2, seed: seed &+ UInt64(k + 70))
        }
        for k in 0..<12 {
            let tx = 300.0 + Double(k) * 27
            pen(p, [pt(tx, 292), pt(tx + 6, 330)], weight: 2, colour: Pot.sepia.al(0.6), wobble: 0.3, taper: true, seed: seed &+ UInt64(k + 80))
        }
    case .board:
        let board = [pt(120, 640), pt(780, 640), pt(760, 720), pt(140, 720)]
        wash(p, board, Pot.wood.lt(0.1), strength: 0.95, bleed: 2, seed: seed &+ 1)
        p.inside(pathOf(board)) {
            for k in 0..<30 {
                let gy = 645 + rng.r(0, 70)
                pen(p, [pt(130, gy), pt(770, gy + rng.r(-3, 3))], weight: rng.r(0.6, 1.4), colour: Pot.woodDark.al(0.3), wobble: 0.6, taper: true, seed: seed &+ UInt64(k + 10))
            }
        }
        penEdge(p, board, weight: 2.6, colour: Pot.ink.al(0.85), seed: seed &+ 2)
        let bench = [pt(100, 720), pt(800, 720), pt(800, 740), pt(100, 740)]
        wash(p, bench, Pot.woodDark, strength: 0.9, bleed: 2, seed: seed &+ 3)
        switch crop.key {
        case "pumpkin", "wintersquash":
            let big = lumpy(cx: 420, cy: 470, rx: 210, ry: 170, rough: 0.03, steps: 40, seed: seed &+ 10)
            p.shape(offsetRing(big, 20, 30), Pot.shadowInk.al(0.18))
            veg(p, big, tone: tone, gloss: 0.5, seed: seed &+ 11)
            ribs(p, at: pt(420, 470), r: 175, count: crop.key == "pumpkin" ? 8 : 6, tone: tone, seed: seed &+ 12)
            let stalk = stemRun(pt(420, 305), -Double.pi / 2 + 0.3, 70, curve: 0.6, wobble: 0.02, steps: 5, seed: seed &+ 13)
            stem(p, stalk, w0: 30, w1: 20, tone: Pot.leafGrey.dk(0.2), woody: true, seed: seed &+ 14)
            vegRound(p, at: pt(690, 590), r: 62, tone: tone.lt(0.1), rough: 0.04, gloss: 0.5, squash: 0.8, seed: seed &+ 15)
            ribs(p, at: pt(690, 590), r: 52, count: 6, tone: tone, seed: seed &+ 16)
        case "watermelon", "melon":
            let big = lumpy(cx: 400, cy: 500, rx: 200, ry: 150, rough: 0.02, steps: 40, seed: seed &+ 10)
            p.shape(offsetRing(big, 20, 30), Pot.shadowInk.al(0.18))
            veg(p, big, tone: tone, gloss: 0.5, seed: seed &+ 11)
            if crop.key == "watermelon" {
                p.inside(pathOf(big)) {
                    for k in 0..<9 {
                        let sx = 230 + Double(k) * 42
                        let stripe = stemRun(pt(sx, 350), .pi / 2 + 0.1, 320, curve: (Double(k) - 4) * 0.08, wobble: 0.06, steps: 10, seed: seed &+ UInt64(k + 20))
                        pen(p, stripe, weight: 14, colour: Pot.leafPale.dk(0.1).al(0.9), wobble: 1.2, taper: true, seed: seed &+ UInt64(k + 21))
                    }
                }
                let wedge = [pt(560, 640), pt(760, 640), pt(660, 470)]
                veg(p, wedge, tone: Pot.tomato.mix(Pot.beet, 0.15), gloss: 0.3, seed: seed &+ 30)
                let rind = [pt(560, 640), pt(760, 640), pt(760, 660), pt(560, 660)]
                wash(p, rind, Pot.leafPale, strength: 0.95, bleed: 1.5, seed: seed &+ 31)
                penEdge(p, rind, weight: 1.6, colour: Pot.ink.al(0.7), seed: seed &+ 32)
                for _ in 0..<10 { p.egg(600 + rng.r(0, 120), 540 + rng.r(0, 80), 3, 4.5, Pot.ink.lt(0.15)) }
            } else {
                p.inside(pathOf(big)) {
                    for k in 0..<500 {
                        let px = rng.r(200, 600), py = rng.r(350, 650)
                        pen(p, [pt(px, py), pt(px + rng.r(-7, 7), py + rng.r(-7, 7))], weight: 1.3, colour: Pot.strawPale.lt(0.3).al(0.8), wobble: 0.3, taper: true, seed: seed &+ UInt64(k + 40))
                    }
                }
                let half = [pt(560, 640), pt(770, 640), pt(760, 560), pt(690, 500), pt(600, 520)]
                veg(p, resample(half + [half[0]], count: 30), tone: Pot.pumpkin.mix(Pot.strawPale, 0.5), gloss: 0.4, seed: seed &+ 30)
                let seeds = lumpy(cx: 680, cy: 585, rx: 50, ry: 26, rough: 0.1, steps: 16, seed: seed &+ 31)
                wash(p, seeds, Pot.strawPale.dk(0.1), strength: 0.9, bleed: 2, seed: seed &+ 32)
            }
        case "cabbage":
            let head = lumpy(cx: 400, cy: 480, rx: 180, ry: 160, rough: 0.04, steps: 36, seed: seed &+ 10)
            p.shape(offsetRing(head, 20, 30), Pot.shadowInk.al(0.18))
            veg(p, head, tone: tone, gloss: 0.35, seed: seed &+ 11)
            p.inside(pathOf(head)) {
                for k in 0..<7 {
                    let a = -Double.pi / 2 + Double(k - 3) * 0.5
                    let vein = stemRun(pt(400, 640), a, 300, curve: -Double(k - 3) * 0.3, wobble: 0.02, steps: 8, seed: seed &+ UInt64(k + 20))
                    pen(p, vein, weight: 5, colour: Pot.white.al(0.75), wobble: 0.5, taper: true, seed: seed &+ UInt64(k + 21))
                }
            }
            for k in 0..<4 {
                let a = -Double.pi / 2 + Double(k - 2) * 0.9 + 0.4
                crinkleLeaf(p, base: pt(420, 640), angle: a, length: 220, width: 160, tone: Pot.leafBlue.dk(0.05), seed: seed &+ UInt64(k + 40))
            }
            vegRound(p, at: pt(690, 590), r: 70, tone: tone.lt(0.05), rough: 0.04, gloss: 0.35, squash: 0.9, seed: seed &+ 50)
        case "cauliflower", "broccoli":
            let head = lumpy(cx: 420, cy: 500, rx: 190, ry: 140, rough: 0.06, steps: 36, seed: seed &+ 10)
            p.shape(offsetRing(head, 20, 30), Pot.shadowInk.al(0.18))
            for k in 0..<5 {
                let a = -Double.pi / 2 + Double(k - 2) * 0.7
                crinkleLeaf(p, base: pt(420, 640), angle: a - (k < 2 ? 0.5 : (k > 2 ? -0.5 : 0)), length: 260, width: 150, tone: Pot.leafBlue, seed: seed &+ UInt64(k + 20))
            }
            veg(p, head, tone: tone, gloss: 0.25, seed: seed &+ 11)
            p.inside(pathOf(head)) {
                for k in 0..<140 {
                    let px = 420 + rng.r(-180, 180), py = 500 + rng.r(-130, 130)
                    let curd = lumpy(cx: px, cy: py, rx: rng.r(12, 26), ry: rng.r(10, 20), rough: 0.25, steps: 10, seed: seed &+ UInt64(k + 30))
                    p.shape(curd, tone.lt(rng.r(0, 0.15)).dk(rng.r(0, 0.08)))
                    penOutline(p, curd, weight: 0.9, colour: tone.dk(0.5).al(0.5), seed: seed &+ UInt64(k + 31))
                }
            }
            roundShade(p, head, inset: 80, depth: 2, spacing: 6, colour: tone.dk(0.55), seed: seed &+ 60)
        case "brussels":
            let stalk = stemRun(pt(200, 690), -0.35, 560, curve: 0.05, wobble: 0.01, steps: 10, seed: seed &+ 10)
            stem(p, stalk, w0: 44, w1: 32, tone: Pot.leafBlue.dk(0.2), woody: true, seed: seed &+ 11)
            for k in 0..<22 {
                let q = along(stalk, 0.1 + Double(k) * 0.04)
                let side = k % 2 == 0 ? -1.0 : 1.0
                vegRound(p, at: pt(Double(q.x) + side * 34, Double(q.y) - 8), r: 26, tone: tone.lt(Double(k % 3) * 0.05), rough: 0.05, gloss: 0.45, squash: 0.95, seed: seed &+ UInt64(k + 20))
            }
            for k in 0..<3 {
                crinkleLeaf(p, base: along(stalk, 0.98), angle: -Double.pi / 2 + Double(k - 1) * 0.8 - 0.3, length: 150, width: 100, tone: Pot.leafBlue, seed: seed &+ UInt64(k + 60))
            }
        case "celery", "leek", "fennel":
            for k in 0..<3 {
                let bx = 250.0 + Double(k) * 200
                if crop.key == "fennel" {
                    let bulb = [pt(bx - 70, 640), pt(bx + 70, 640), pt(bx + 60, 520), pt(bx, 470), pt(bx - 60, 520)]
                    veg(p, resample(bulb + [bulb[0]], count: 30), tone: tone, gloss: 0.4, seed: seed &+ UInt64(k + 10))
                    for j in 0..<5 {
                        pen(p, [pt(bx - 50 + Double(j) * 25, 636), pt(bx - 40 + Double(j) * 20, 500)], weight: 2, colour: tone.dk(0.35).al(0.6), wobble: 0.5, taper: true, seed: seed &+ UInt64(k * 8 + j + 20))
                    }
                    for j in 0..<5 {
                        let a = -Double.pi / 2 + Double(j - 2) * 0.28
                        let st = stemRun(pt(bx - 30 + Double(j) * 15, 480), a, 200, curve: Double(j - 2) * 0.2, wobble: 0.02, steps: 6, seed: seed &+ UInt64(k * 8 + j + 40))
                        pen(p, st, weight: 6, colour: Pot.leafPale, wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 8 + j + 41))
                        featheryLeaf(p, base: st[st.count - 1], angle: a, length: 90, tone: Pot.leafPale, fineness: 5, seed: seed &+ UInt64(k * 8 + j + 60))
                    }
                } else {
                    let stalks = crop.key == "leek" ? 1 : 7
                    for j in 0..<stalks {
                        let sx = bx + Double(j - stalks / 2) * 16
                        let wS = crop.key == "leek" ? 64.0 : 22.0
                        vegLong(p, from: pt(sx + 6, 640), to: pt(sx - 6, 320), width: wS, tone: crop.key == "leek" ? tone : tone.lt(Double(j % 2) * 0.1), taperEnd: crop.key == "leek" ? 0.85 : 0.9, taperStart: 1.0, gloss: 0.35, bend: 0.02, seed: seed &+ UInt64(k * 10 + j + 10))
                        if crop.key == "leek" {
                            p.inside(pathOf(bandOf([pt(sx + 6, 640), pt(sx - 6, 320)], [wS, wS * 0.9], per: 4))) {
                                wash(p, [pt(sx - 40, 470), pt(sx + 40, 470), pt(sx + 30, 300), pt(sx - 50, 300)], Pot.leafBlue, strength: 0.6, bleed: 4, seed: seed &+ UInt64(k + 100))
                            }
                            for j2 in 0..<4 {
                                strapLeaf(p, base: pt(sx - 6, 340), angle: -Double.pi / 2 + Double(j2 - 2) * 0.35 + 0.15, length: 180, width: 44, tone: Pot.leafBlue, curve: Double(j2 - 2) * 0.35, fold: true, seed: seed &+ UInt64(k * 10 + j2 + 120))
                            }
                            for j2 in 0..<9 {
                                pen(p, [pt(sx - 24 + Double(j2) * 6, 640), pt(sx - 26 + Double(j2) * 7, 640 + rng.r(14, 30))], weight: 1.6, colour: Pot.strawPale.dk(0.4), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 10 + j2 + 140))
                            }
                        } else {
                            featheryLeaf(p, base: pt(sx - 6, 320), angle: -Double.pi / 2 + Double(j - 3) * 0.2, length: 90, tone: Pot.leaf, fineness: 4, seed: seed &+ UInt64(k * 10 + j + 160))
                        }
                    }
                }
            }
        default:
            break
        }
    }
}

func drawProducePlate(_ crop: Crop, dir: String) {
    let previous = sheetScale
    sheetScale = 1.25
    let p = Leaf(900, 900)
    let seed = hashOf("produce-" + crop.key)
    layPaper(p, seed: seed, tone: Pot.creamWarm, laid: false)
    p.flipDown()
    p.light = -2.36
    let wall = [pt(0, 0), pt(p.w, 0), pt(p.w, p.h), pt(0, p.h)]
    wash(p, wall, Pot.creamDeep.mix(Pot.wood, 0.15), strength: 0.25, bleed: 4, seed: seed &+ 1)
    var rng = Chip(seed &+ 5)
    for k in 0..<7 {
        let x = 60.0 + Double(k) * 130
        pen(p, [pt(x, 0), pt(x + rng.r(-3, 3), p.h)], weight: 2, colour: Pot.woodDark.al(0.12), wobble: 0.6, taper: false, seed: seed &+ UInt64(k + 10))
    }
    let shelfY = 720.0
    let vessel = vesselFor(crop)
    if vessel != .board {
        let board = [pt(0, shelfY), pt(p.w, shelfY), pt(p.w, shelfY + 30), pt(0, shelfY + 30)]
        wash(p, board, Pot.wood.dk(0.1), strength: 0.85, bleed: 2, seed: seed &+ 20)
        crossHatch(p, pathOf(board), depth: 1, spacing: 6, colour: Pot.woodDark.al(0.6), seed: seed &+ 21)
        pen(p, [pt(0, shelfY), pt(p.w, shelfY)], weight: 3, colour: Pot.ink.al(0.85), wobble: 0.4, taper: false, seed: seed &+ 22)
        p.box(0, shelfY + 30, p.w, 16, Pot.shadowInk.al(0.16))
        if vessel != .bunch {
            let shadow = lumpy(cx: 470, cy: shelfY - 4, rx: 300, ry: 26, rough: 0.1, steps: 20, seed: seed &+ 23)
            p.shape(shadow, Pot.shadowInk.al(0.18))
        }
    }
    drawProduceFigure(p, crop, seed: seed &+ 30)
    paperTag(p, at: pt(vessel == .bunch ? 690 : 640, vessel == .bunch ? 640 : 770), text: crop.name, angle: -0.06, seed: seed &+ 40)
    seasonStamp(p, at: pt(190, 800), text: crop.family.name.uppercased(), angle: -0.1, seed: seed &+ 41)
    p.writeJPG(dir, "pr_" + crop.key, quality: 0.84)
    sheetScale = previous
}
