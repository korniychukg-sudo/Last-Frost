import Foundation
import CoreGraphics

func biteHoles(_ p: Leaf, in ring: [CGPoint], count: Int, size: ClosedRange<Double>, edge: Bool, seed: UInt64) {
    var rng = Chip(seed)
    let path = pathOf(ring)
    let box = path.boundingBox
    let dense = denseRing(ring, every: 6)
    p.inside(path) {
        for k in 0..<count {
            var x = Double(box.minX) + rng.d() * Double(box.width)
            var y = Double(box.minY) + rng.d() * Double(box.height)
            if edge && k % 2 == 0, let q = dense.isEmpty ? nil : dense[rng.i(0, dense.count - 1)] { x = Double(q.x); y = Double(q.y) }
            let r = rng.r(size.lowerBound, size.upperBound)
            let hole = lumpy(cx: x, cy: y, rx: r, ry: r * rng.r(0.7, 1.0), rough: 0.32, steps: 11, seed: rng.next())
            p.shape(scaledRing(hole, about: pt(x, y), 1.22), Pot.straw.dk(0.35).al(0.45))
            p.shape(hole, Pot.creamWarm.lt(0.05))
            penOutline(p, hole, weight: 1.4, colour: Pot.sepia.al(0.85), seed: rng.next())
        }
    }
}

func caterpillar(_ p: Leaf, from a: CGPoint, to b: CGPoint, width: Double, tone: Hue, chevrons: Bool, horn: Bool, seed: UInt64) {
    let ax = Double(a.x), ay = Double(a.y), bx = Double(b.x), by = Double(b.y)
    let midX = (ax + bx) / 2 + (by - ay) * 0.16, midY = (ay + by) / 2 - (bx - ax) * 0.16
    let spine = resample([a, pt(midX, midY), b], count: 40)
    let ring = bandOf(spine, [width * 0.55, width, width, width * 0.8], per: 3)
    produce(p, ring, tone: tone, gloss: 0.35, seed: seed)
    let body = pathOf(ring)
    p.inside(body) {
        let segs = 11
        for k in 1..<segs {
            let t = Double(k) / Double(segs)
            let q = spine[min(39, Int(t * 39))]
            let n = spine[min(39, Int(t * 39) + 1)]
            let dx = Double(n.x - q.x), dy = Double(n.y - q.y)
            let l = max(0.01, (dx * dx + dy * dy).squareRoot())
            let px = -dy / l, py = dx / l
            pen(p, [pt(Double(q.x) + px * width * 0.55, Double(q.y) + py * width * 0.55), pt(Double(q.x) - px * width * 0.55, Double(q.y) - py * width * 0.55)],
                weight: 1.4, colour: tone.dk(0.5).al(0.7), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 3))
            if chevrons {
                let c = pt(Double(q.x) - px * width * 0.1, Double(q.y) - py * width * 0.1)
                pen(p, [pt(Double(c.x) - dx / l * width * 0.35 + px * width * 0.3, Double(c.y) - dy / l * width * 0.35 + py * width * 0.3), c,
                        pt(Double(c.x) - dx / l * width * 0.35 - px * width * 0.3, Double(c.y) - dy / l * width * 0.35 - py * width * 0.3)],
                    weight: 2.0, colour: Pot.white.al(0.85), wobble: 0.2, taper: true, seed: seed &+ UInt64(k * 7 + 1))
            }
        }
    }
    var rng = Chip(seed &+ 9)
    for k in 0..<8 {
        let t = 0.15 + Double(k) * 0.1
        let q = spine[min(39, Int(t * 39))]
        let n = spine[min(39, Int(t * 39) + 1)]
        let dx = Double(n.x - q.x), dy = Double(n.y - q.y)
        let l = max(0.01, (dx * dx + dy * dy).squareRoot())
        let px = -dy / l, py = dx / l
        let side = 1.0
        pen(p, [pt(Double(q.x) + px * width * 0.45 * side, Double(q.y) + py * width * 0.45 * side), pt(Double(q.x) + px * width * 0.8 * side + rng.r(-2, 2), Double(q.y) + py * width * 0.8 * side + 3)],
            weight: 1.6, colour: tone.dk(0.55), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 11 + 20))
    }
    let head = lumpy(cx: bx, cy: by, rx: width * 0.42, ry: width * 0.42, rough: 0.05, steps: 16, seed: seed &+ 30)
    produce(p, head, tone: tone.dk(0.2), gloss: 0.4, seed: seed &+ 31)
    p.dot(bx + width * 0.12, by - width * 0.1, width * 0.06, Pot.ink)
    if horn {
        let hornSpine = stemRun(a, atan2(ay - by, ax - bx) - 0.6, width * 1.1, curve: 0.5, wobble: 0.02, steps: 4, seed: seed &+ 40)
        pen(p, hornSpine, weight: width * 0.16, colour: Pot.tomato.dk(0.4), wobble: 0.2, taper: true, seed: seed &+ 41)
    }
}

func slug(_ p: Leaf, at c: CGPoint, angle: Double, length: Double, tone: Hue, seed: UInt64) {
    let spine = stemRun(c, angle, length, curve: 0.25, wobble: 0.01, steps: 8, seed: seed)
    let ring = bandOf(spine, [length * 0.10, length * 0.22, length * 0.24, length * 0.16, length * 0.06], per: 4)
    produce(p, ring, tone: tone, gloss: 0.6, seed: seed &+ 1)
    let mantle = bandOf(Array(resample(spine, count: 10)[1...4]), [length * 0.16, length * 0.22, length * 0.2], per: 4)
    wash(p, mantle, tone.dk(0.15), strength: 0.5, bleed: 2, seed: seed &+ 2)
    penOutline(p, mantle, weight: 1.0, colour: tone.dk(0.5).al(0.6), seed: seed &+ 3)
    let head = spine[spine.count - 1]
    for side in [-0.5, 0.5] {
        let tent = stemRun(head, angle + side, length * 0.22, curve: side * 0.4, wobble: 0.02, steps: 4, seed: seed &+ UInt64(side > 0 ? 4 : 5))
        pen(p, tent, weight: 2.4, colour: tone.dk(0.4), wobble: 0.2, taper: true, seed: seed &+ 6)
        let tip = tent[tent.count - 1]
        p.dot(Double(tip.x), Double(tip.y), 2.4, Pot.ink)
    }
    var rng = Chip(seed &+ 7)
    let trail = stemRun(pt(Double(c.x) - cos(angle) * length * 0.9, Double(c.y) - sin(angle) * length * 0.9 + 6), angle, length * 1.6, curve: rng.r(-0.6, 0.6), wobble: 0.08, steps: 10, seed: seed &+ 8)
    pen(p, trail, weight: 3.5, colour: Pot.glass.lt(0.3).al(0.7), wobble: 0.4, taper: true, seed: seed &+ 9)
    pen(p, offsetRing(trail, 0, -1), weight: 1.2, colour: Pot.white.al(0.8), wobble: 0.3, taper: true, seed: seed &+ 10)
}

func aphids(_ p: Leaf, along spine: [CGPoint], count: Int, tone: Hue, seed: UInt64) {
    var rng = Chip(seed)
    let fine = resample(spine, count: max(4, count))
    for (k, q) in fine.enumerated() {
        let side = rng.chance(0.5) ? -1.0 : 1.0
        let x = Double(q.x) + side * rng.r(3, 9), y = Double(q.y) + rng.r(-3, 3)
        let body = lumpy(cx: x, cy: y, rx: rng.r(3.2, 4.6), ry: rng.r(2.4, 3.4), rough: 0.05, steps: 12, seed: seed &+ UInt64(k))
        p.shape(body, tone)
        penOutline(p, body, weight: 0.8, colour: tone.dk(0.6), seed: seed &+ UInt64(k * 3 + 1))
        p.dot(x - 1.2, y - 1, 1.0, Pot.white.al(0.5))
        for j in 0..<3 {
            let a = -Double.pi / 2 + Double(j - 1) * 0.7 + (side > 0 ? 0.3 : -0.3)
            pen(p, [pt(x, y), pt(x + cos(a) * 5, y + sin(a) * 5 + 4)], weight: 0.7, colour: tone.dk(0.6), wobble: 0.2, taper: true, seed: seed &+ UInt64(k * 5 + j + 40))
        }
    }
}

func butterfly(_ p: Leaf, at c: CGPoint, size: Double, seed: UInt64) {
    let cx = Double(c.x), cy = Double(c.y)
    for side in [-1.0, 1.0] {
        let fore = lumpy(cx: cx + side * size * 0.42, cy: cy - size * 0.22, rx: size * 0.42, ry: size * 0.30, rough: 0.05, steps: 22, seed: seed &+ UInt64(side > 0 ? 1 : 2))
        let hind = lumpy(cx: cx + side * size * 0.34, cy: cy + size * 0.20, rx: size * 0.32, ry: size * 0.26, rough: 0.06, steps: 20, seed: seed &+ UInt64(side > 0 ? 3 : 4))
        for ring in [hind, fore] {
            wash(p, ring, Pot.white.lt(0.2), strength: 0.95, bleed: 2, seed: seed &+ 5)
            crossHatch(p, pathOf(ring), depth: 1, spacing: 5, colour: Pot.inkPale.al(0.35), seed: seed &+ 6)
            penOutline(p, ring, weight: 1.4, colour: Pot.ink.al(0.8), seed: seed &+ 7)
        }
        let tip = lumpy(cx: cx + side * size * 0.76, cy: cy - size * 0.42, rx: size * 0.14, ry: size * 0.12, rough: 0.1, steps: 12, seed: seed &+ 8)
        p.inside(pathOf(fore)) { p.shape(tip, Pot.ink.al(0.85)) }
        p.dot(cx + side * size * 0.40, cy - size * 0.16, size * 0.05, Pot.ink.al(0.85))
        p.dot(cx + side * size * 0.24, cy - size * 0.06, size * 0.04, Pot.ink.al(0.75))
    }
    let bodyRing = bandOf([pt(cx, cy - size * 0.35), pt(cx, cy + size * 0.36)], [size * 0.08, size * 0.11, size * 0.06], per: 6)
    p.shape(bodyRing, Pot.ink.lt(0.2))
    for side in [-1.0, 1.0] {
        pen(p, [pt(cx, cy - size * 0.32), pt(cx + side * size * 0.16, cy - size * 0.5)], weight: 1.2, colour: Pot.ink, wobble: 0.2, taper: true, seed: seed &+ 9)
    }
}

func beetle(_ p: Leaf, at c: CGPoint, size: Double, tone: Hue, stripes: Bool, seed: UInt64) {
    let cx = Double(c.x), cy = Double(c.y)
    let body = lumpy(cx: cx, cy: cy, rx: size * 0.55, ry: size * 0.42, rough: 0.04, steps: 18, seed: seed)
    produce(p, body, tone: tone, gloss: 0.7, seed: seed &+ 1)
    pen(p, [pt(cx - size * 0.1, cy - size * 0.4), pt(cx - size * 0.1, cy + size * 0.4)], weight: 1.0, colour: tone.dk(0.6), wobble: 0.1, taper: false, seed: seed &+ 2)
    if stripes {
        pen(p, [pt(cx - size * 0.3, cy - size * 0.3), pt(cx - size * 0.3, cy + size * 0.3)], weight: 2.0, colour: Pot.straw.al(0.9), wobble: 0.1, taper: true, seed: seed &+ 3)
        pen(p, [pt(cx + size * 0.12, cy - size * 0.3), pt(cx + size * 0.12, cy + size * 0.3)], weight: 2.0, colour: Pot.straw.al(0.9), wobble: 0.1, taper: true, seed: seed &+ 4)
    }
    let head = lumpy(cx: cx - size * 0.6, cy: cy, rx: size * 0.16, ry: size * 0.16, rough: 0.05, steps: 10, seed: seed &+ 5)
    p.shape(head, tone.dk(0.2))
    for k in 0..<3 {
        for side in [-1.0, 1.0] {
            let bx = cx - size * 0.3 + Double(k) * size * 0.3
            pen(p, [pt(bx, cy + side * size * 0.3), pt(bx + size * 0.1, cy + side * size * 0.62), pt(bx + size * 0.3, cy + side * size * 0.7)], weight: 1.1, colour: tone.dk(0.5), wobble: 0.2, taper: true, seed: seed &+ UInt64(k * 3 + Int(side + 2) + 10))
        }
    }
    for side in [-1.0, 1.0] {
        pen(p, [pt(cx - size * 0.7, cy + side * size * 0.06), pt(cx - size * 1.0, cy + side * size * 0.25)], weight: 0.9, colour: tone.dk(0.5), wobble: 0.2, taper: true, seed: seed &+ UInt64(side > 0 ? 30 : 31))
    }
}

func smallFly(_ p: Leaf, at c: CGPoint, size: Double, seed: UInt64) {
    let cx = Double(c.x), cy = Double(c.y)
    let body = bandOf([pt(cx - size * 0.4, cy), pt(cx + size * 0.5, cy + size * 0.05)], [size * 0.2, size * 0.32, size * 0.14], per: 6)
    produce(p, body, tone: Pot.ink.lt(0.15), gloss: 0.5, seed: seed)
    for side in [-1.0, 1.0] {
        let wing = lumpy(cx: cx + size * 0.05, cy: cy + side * size * 0.28, rx: size * 0.5, ry: size * 0.16, rough: 0.05, steps: 14, seed: seed &+ UInt64(side > 0 ? 1 : 2))
        let rot = rotatedRing(wing, about: pt(cx - size * 0.3, cy), side * 0.35)
        wash(p, rot, Pot.glass.lt(0.2), strength: 0.55, bleed: 1, seed: seed &+ 3)
        penOutline(p, rot, weight: 0.8, colour: Pot.ink.al(0.6), seed: seed &+ 4)
    }
    p.dot(cx - size * 0.5, cy, size * 0.12, Pot.tomato.dk(0.3))
    for k in 0..<3 {
        for side in [-1.0, 1.0] {
            let bx = cx - size * 0.2 + Double(k) * size * 0.2
            pen(p, [pt(bx, cy + side * size * 0.1), pt(bx + size * 0.08, cy + side * size * 0.45)], weight: 0.7, colour: Pot.ink.al(0.8), wobble: 0.1, taper: true, seed: seed &+ UInt64(k * 3 + Int(side + 2) + 10))
        }
    }
}

func grub(_ p: Leaf, at c: CGPoint, length: Double, width: Double, tone: Hue, curled: Bool, seed: UInt64) {
    let spine = stemRun(c, 0.3, length, curve: curled ? 3.6 : 0.4, wobble: 0.01, steps: 12, seed: seed)
    let ring = bandOf(spine, [width * 0.6, width, width, width * 0.7], per: 3)
    produce(p, ring, tone: tone, gloss: 0.45, seed: seed &+ 1)
    p.inside(pathOf(ring)) {
        let fine = resample(spine, count: 12)
        for k in 1..<11 {
            let q = fine[k], n = fine[k + 1]
            let dx = Double(n.x - q.x), dy = Double(n.y - q.y)
            let l = max(0.01, (dx * dx + dy * dy).squareRoot())
            pen(p, [pt(Double(q.x) - dy / l * width * 0.5, Double(q.y) + dx / l * width * 0.5), pt(Double(q.x) + dy / l * width * 0.5, Double(q.y) - dx / l * width * 0.5)],
                weight: 1.1, colour: tone.dk(0.5).al(0.6), wobble: 0.2, taper: true, seed: seed &+ UInt64(k))
        }
    }
    let head = spine[spine.count - 1]
    p.dot(Double(head.x), Double(head.y), width * 0.42, tone.dk(0.45))
    p.dot(Double(head.x), Double(head.y), width * 0.42, Pot.sepia.al(0.5))
}

func pigeon(_ p: Leaf, at c: CGPoint, size: Double, seed: UInt64) {
    let cx = Double(c.x), cy = Double(c.y)
    let body = lumpy(cx: cx, cy: cy, rx: size * 0.55, ry: size * 0.36, rough: 0.05, steps: 24, seed: seed)
    let bodyRot = rotatedRing(body, about: c, -0.25)
    produce(p, bodyRot, tone: Pot.leafGrey.mix(Pot.glass, 0.5).dk(0.15), gloss: 0.25, seed: seed &+ 1)
    let wing = lumpy(cx: cx + size * 0.05, cy: cy - size * 0.05, rx: size * 0.42, ry: size * 0.2, rough: 0.06, steps: 18, seed: seed &+ 2)
    let wingRot = rotatedRing(wing, about: pt(cx + size * 0.05, cy - size * 0.05), -0.4)
    wash(p, wingRot, Pot.inkPale.mix(Pot.glass, 0.3), strength: 0.6, bleed: 2, seed: seed &+ 3)
    crossHatch(p, pathOf(wingRot), depth: 1, spacing: 4, colour: Pot.inkSoft.al(0.5), seed: seed &+ 4)
    penOutline(p, wingRot, weight: 1.2, colour: Pot.ink.al(0.7), seed: seed &+ 5)
    let neck = stemRun(pt(cx - size * 0.4, cy - size * 0.2), -2.2, size * 0.42, curve: 0.3, wobble: 0.01, steps: 5, seed: seed &+ 6)
    stem(p, neck, w0: size * 0.22, w1: size * 0.18, tone: Pot.leafGrey.mix(Pot.glass, 0.5).dk(0.1), seed: seed &+ 7)
    let head = neck[neck.count - 1]
    let headRing = lumpy(cx: Double(head.x), cy: Double(head.y), rx: size * 0.16, ry: size * 0.14, rough: 0.04, steps: 14, seed: seed &+ 8)
    produce(p, headRing, tone: Pot.leafGrey.mix(Pot.glass, 0.5).dk(0.1), gloss: 0.3, seed: seed &+ 9)
    pen(p, [pt(Double(head.x) - size * 0.14, Double(head.y) + size * 0.02), pt(Double(head.x) - size * 0.3, Double(head.y) + size * 0.06)], weight: size * 0.06, colour: Pot.straw.dk(0.3), wobble: 0.1, taper: true, seed: seed &+ 10)
    p.dot(Double(head.x) - size * 0.05, Double(head.y) - size * 0.03, size * 0.03, Pot.ink)
    for k in 0..<2 {
        let lx = cx + size * (0.05 + Double(k) * 0.22)
        pen(p, [pt(lx, cy + size * 0.3), pt(lx - size * 0.04, cy + size * 0.52)], weight: size * 0.05, colour: Pot.tomato.dk(0.35), wobble: 0.1, taper: false, seed: seed &+ UInt64(k + 20))
        for j in 0..<3 {
            pen(p, [pt(lx - size * 0.04, cy + size * 0.52), pt(lx - size * 0.04 + Double(j - 1) * size * 0.1 - size * 0.06, cy + size * 0.6)], weight: size * 0.03, colour: Pot.tomato.dk(0.35), wobble: 0.1, taper: true, seed: seed &+ UInt64(k * 3 + j + 30))
        }
    }
}

func mouldPatch(_ p: Leaf, at c: CGPoint, r: Double, tone: Hue, dots: Bool, seed: UInt64) {
    var rng = Chip(seed)
    let core = lumpy(cx: Double(c.x), cy: Double(c.y), rx: r * 0.7, ry: r * 0.5, rough: 0.3, steps: 16, seed: seed &+ 99)
    p.shape(core, tone.al(0.55))
    for _ in 0..<Int(r * 2.4) {
        let x = Double(c.x) + rng.signed() * r, y = Double(c.y) + rng.signed() * r * 0.7
        p.dot(x, y, rng.r(1.6, 4.2), tone.al(rng.r(0.45, 0.95)))
    }
    if dots {
        for _ in 0..<Int(r * 0.5) {
            p.dot(Double(c.x) + rng.signed() * r * 0.9, Double(c.y) + rng.signed() * r * 0.6, rng.r(0.9, 1.8), Pot.ink.al(0.9))
        }
    }
}

func wiltedRosette(_ p: Leaf, crown: CGPoint, radius: Double, tone: Hue, droop: Double, seed: UInt64) {
    var rng = Chip(seed)
    for k in 0..<7 {
        let u = Double(k) / 6
        let a = -Double.pi / 2 - 1.4 + u * 2.8
        let hang = droop * (0.6 + 0.4 * abs(cos(a)))
        blade(p, base: crown, angle: a + (a < -Double.pi / 2 ? -hang : hang), length: radius * rng.r(0.8, 1.05), width: radius * 0.5, tone: tone.dk(rng.r(0, 0.15)), serrate: 0.1, curl: (a < -Double.pi / 2 ? -1 : 1) * hang * 0.8, veins: 4, seed: seed &+ UInt64(k * 7))
    }
}

func troubleSubtitle(_ t: Trouble) -> String {
    let who: String
    switch t.crops.count {
    case 0...3: who = t.crops.map { Register.find($0).name.lowercased() }.joined(separator: ", ")
    default:
        let fams = Set(t.crops.map { Register.find($0).family })
        who = fams.count == 1 ? "the \(fams.first!.name.lowercased()) family" : t.crops.prefix(3).map { Register.find($0).name.lowercased() }.joined(separator: ", ") + " and more"
    }
    return "\(t.kind.name) of \(who), \(t.season)"
}

func drawTroubleFigure(_ p: Leaf, _ t: Trouble, seed: UInt64) {
    var rng = Chip(seed)
    let cx = 450.0
    switch t.key {
    case "clubroot":
        soilBand(p, y: 560, depth: 220, x0: 150, x1: 750, seed: seed)
        let crown = pt(cx, 556)
        wiltedRosette(p, crown: crown, radius: 200, tone: Pot.leafBlue.mix(Pot.aubergine, 0.18), droop: 0.55, seed: seed &+ 1)
        var club: [CGPoint] = []
        for i in 0..<40 {
            let a = Double(i) / 40 * 2 * .pi
            let bulge = 1 + 0.35 * abs(sin(a * 3.5 + 0.4)) + 0.15 * abs(sin(a * 7))
            club.append(pt(cx + cos(a) * 70 * bulge * (sin(a) > 0 ? 1 : 0.55), 640 + sin(a) * 95 * bulge))
        }
        produce(p, club, tone: Pot.strawPale.mix(Pot.soilLight, 0.4), gloss: 0.25, seed: seed &+ 5)
        for k in 0..<5 {
            let root = stemRun(pt(cx + rng.r(-50, 50), 720 + rng.r(0, 30)), .pi / 2 + rng.r(-0.7, 0.7), rng.r(20, 50), curve: rng.r(-0.5, 0.5), wobble: 0.1, steps: 5, seed: seed &+ UInt64(k + 10))
            pen(p, root, weight: 2.2, colour: Pot.strawPale.dk(0.45), wobble: 0.3, taper: true, seed: seed &+ UInt64(k + 11))
        }
    case "carrotfly":
        cutawaySoil(p, seed: seed)
        featheryLeaf(p, base: pt(cx - 20, 786), angle: -Double.pi / 2 - 0.35, length: 250, tone: Pot.leafPale.mix(Pot.terracotta, 0.35), fineness: 7, seed: seed &+ 1)
        featheryLeaf(p, base: pt(cx + 20, 786), angle: -Double.pi / 2 + 0.3, length: 240, tone: Pot.leafPale.mix(Pot.terracotta, 0.25), fineness: 6, seed: seed &+ 2)
        let root = taprootRing(top: pt(cx, 792), length: 260, width: 70, seed: seed &+ 3)
        produce(p, root, tone: Pot.carrot, gloss: 0.3, seed: seed &+ 4)
        p.inside(pathOf(root)) {
            for k in 0..<5 {
                let tunnel = stemRun(pt(cx + rng.r(-24, 24), 830 + Double(k) * 38), .pi / 2 + rng.r(-0.4, 0.4), rng.r(40, 90), curve: rng.r(-1.2, 1.2), wobble: 0.1, steps: 8, seed: seed &+ UInt64(k + 20))
                pen(p, tunnel, weight: 6, colour: Pot.sepia.dk(0.2), wobble: 0.6, taper: true, seed: seed &+ UInt64(k + 21))
                pen(p, tunnel, weight: 2.5, colour: Pot.soilDark, wobble: 0.4, taper: true, seed: seed &+ UInt64(k + 22))
            }
        }
        grub(p, at: pt(cx + 90, 900), length: 30, width: 8, tone: Pot.strawPale, curled: false, seed: seed &+ 30)
        smallFly(p, at: pt(700, 420), size: 34, seed: seed &+ 40)
    case "cabbagewhite":
        groundLine(p, seed: seed)
        let leaf = crinkleRing(base: pt(cx, 790), angle: -Double.pi / 2, length: 460, width: 380, seed: seed &+ 1)
        wash(p, leaf, Pot.leafBlue, strength: 0.58, bleed: 6, seed: seed &+ 2)
        roundShade(p, leaf, inset: 120, depth: 3, spacing: 7, colour: Pot.leafBlue.dk(0.45), seed: seed &+ 3)
        veinsIn(p, leaf, base: pt(cx, 790), tip: pt(cx, 340), tone: Pot.leafBlue.dk(0.5), count: 6, seed: seed &+ 4)
        penOutline(p, leaf, weight: 2.4, colour: Pot.leafBlue.dk(0.6), seed: seed &+ 5)
        biteHoles(p, in: leaf, count: 9, size: 16...44, edge: true, seed: seed &+ 6)
        caterpillar(p, from: pt(cx - 120, 560), to: pt(cx + 10, 600), width: 22, tone: Pot.leafPale.dk(0.1), chevrons: false, horn: false, seed: seed &+ 7)
        caterpillar(p, from: pt(cx + 60, 440), to: pt(cx + 150, 400), width: 18, tone: Pot.yellow.mix(Pot.leaf, 0.4), chevrons: false, horn: false, seed: seed &+ 8)
        for k in 0..<14 {
            let ex = cx + 110 + Double(k % 7) * 9, ey = 660 + Double(k / 7) * 11
            p.egg(ex, ey, 4, 6, Pot.yellow)
            p.hoop(ex, ey, 4, 0.8, Pot.sepia.al(0.7))
        }
        butterfly(p, at: pt(690, 300), size: 110, seed: seed &+ 9)
    case "aphids":
        groundLine(p, seed: seed)
        let spine = stemRun(pt(cx, 790), -Double.pi / 2 + 0.05, 470, curve: -0.35, wobble: 0.01, steps: 12, seed: seed &+ 1)
        stem(p, spine, w0: 20, w1: 10, tone: Pot.leafPale, seed: seed &+ 2)
        for k in 0..<5 {
            let q = along(spine, 0.2 + Double(k) * 0.16)
            let side: Double = k % 2 == 0 ? -1 : 1
            blade(p, base: q, angle: -Double.pi / 2 + side * 1.2, length: 120 - Double(k) * 12, width: 70 - Double(k) * 6, tone: Pot.leafPale.dk(0.05), serrate: 0, curl: side * (0.6 + Double(k) * 0.25), veins: 3, seed: seed &+ UInt64(k + 3))
        }
        let tip = spine[spine.count - 1]
        for k in 0..<4 {
            let leafSpine = stemRun(tip, -Double.pi / 2 + Double(k - 2) * 0.5, 70, curve: Double(k - 2) * 1.4, wobble: 0.02, steps: 6, seed: seed &+ UInt64(k + 10))
            let ring = bandOf(leafSpine, [8, 26, 20, 4], per: 4)
            wash(p, ring, Pot.leafPale.dk(0.15), strength: 0.6, bleed: 2, seed: seed &+ UInt64(k + 20))
            penOutline(p, ring, weight: 1.2, colour: Pot.leafDeep.al(0.8), seed: seed &+ UInt64(k + 30))
        }
        aphids(p, along: Array(resample(spine, count: 20)[9...19]), count: 34, tone: Pot.leafDeep.dk(0.55).mix(Pot.leaf, 0.3), seed: seed &+ 40)
        let lensC = pt(690, 330)
        p.dot(Double(lensC.x), Double(lensC.y), 96, Pot.glass.lt(0.5).al(0.9))
        p.ctx.saveGState()
        p.ctx.addEllipse(in: CGRect(x: 690 - 92, y: 330 - 92, width: 184, height: 184))
        p.ctx.clip()
        let shoot = stemRun(pt(640, 420), -Double.pi / 2 + 0.3, 200, curve: -0.4, wobble: 0.01, steps: 8, seed: seed &+ 70)
        stem(p, shoot, w0: 34, w1: 22, tone: Pot.leafPale, seed: seed &+ 71)
        var big = Chip(seed &+ 72)
        for k in 0..<9 {
            let q = along(shoot, 0.2 + Double(k) * 0.09)
            let side = k % 2 == 0 ? -1.0 : 1.0
            let ax = Double(q.x) + side * big.r(14, 24), ay = Double(q.y) + big.r(-6, 6)
            let body = lumpy(cx: ax, cy: ay, rx: 13, ry: 9, rough: 0.05, steps: 16, seed: seed &+ UInt64(k + 80))
            produce(p, body, tone: Pot.leafDeep.dk(0.4).mix(Pot.leaf, 0.35), gloss: 0.5, seed: seed &+ UInt64(k + 90))
            for j in 0..<3 {
                let a = -Double.pi / 2 + Double(j - 1) * 0.7 + side * 0.4
                pen(p, [pt(ax, ay), pt(ax + cos(a) * 18, ay + sin(a) * 18 + 12)], weight: 1.4, colour: Pot.ink.al(0.8), wobble: 0.2, taper: true, seed: seed &+ UInt64(k * 3 + j + 100))
            }
            pen(p, [pt(ax + side * 9, ay - 6), pt(ax + side * 22, ay - 16)], weight: 1.0, colour: Pot.ink.al(0.7), wobble: 0.2, taper: true, seed: seed &+ UInt64(k + 110))
        }
        p.ctx.restoreGState()
        p.hoop(Double(lensC.x), Double(lensC.y), 94, 5, Pot.ink.lt(0.15))
        p.hoop(Double(lensC.x), Double(lensC.y), 88, 1.2, Pot.white.al(0.7))
        pen(p, [pt(690 + 66, 330 + 66), pt(690 + 130, 330 + 130)], weight: 14, colour: Pot.woodDark, wobble: 0.2, taper: false, seed: seed &+ 120)
        for k in 0..<8 {
            let q = along(spine, 0.55 + Double(k) * 0.05)
            p.dot(Double(q.x) + rng.r(-14, 14), Double(q.y) + rng.r(-4, 4), rng.r(1.5, 2.5), Pot.ink.al(0.85))
        }
        for k in 0..<3 {
            let q = along(spine, 0.3 + Double(k) * 0.1)
            let ant = lumpy(cx: Double(q.x) + 12, cy: Double(q.y), rx: 6, ry: 3.2, rough: 0.05, steps: 10, seed: seed &+ UInt64(k + 50))
            p.shape(ant, Pot.ink.lt(0.15))
            p.dot(Double(q.x) + 19, Double(q.y), 2.4, Pot.ink.lt(0.15))
        }
    case "slugs":
        groundLine(p, seed: seed)
        sideRosette(p, crown: pt(cx, 780), radius: 250, tone: Pot.leafPale, layers: 2, crinkle: true, seed: seed &+ 1)
        let outer = crinkleRing(base: pt(cx, 780), angle: -Double.pi / 2 - 0.9, length: 240, width: 150, seed: seed &+ 2)
        biteHoles(p, in: outer, count: 7, size: 14...36, edge: true, seed: seed &+ 3)
        let outer2 = crinkleRing(base: pt(cx, 780), angle: -Double.pi / 2 + 0.9, length: 240, width: 150, seed: seed &+ 2)
        biteHoles(p, in: outer2, count: 6, size: 14...36, edge: true, seed: seed &+ 4)
        slug(p, at: pt(cx + 170, 800), angle: .pi + 0.4, length: 120, tone: Pot.sepia.mix(Pot.straw, 0.4), seed: seed &+ 5)
        slug(p, at: pt(cx - 260, 730), angle: 0.6, length: 90, tone: Pot.ink.lt(0.3), seed: seed &+ 6)
        for k in 0..<3 {
            let stump = stemRun(pt(cx - 200 + Double(k) * 40, 790), -Double.pi / 2, 22, curve: 0, wobble: 0.05, steps: 3, seed: seed &+ UInt64(k + 60))
            pen(p, stump, weight: 4, colour: Pot.leafPale.dk(0.3), wobble: 0.3, taper: true, seed: seed &+ UInt64(k + 61))
        }
    case "blossomend":
        groundLine(p, seed: seed, wide: false)
        let fruit = lumpy(cx: cx, cy: 560, rx: 170, ry: 160, rough: 0.03, steps: 40, seed: seed &+ 1)
        produce(p, fruit, tone: Pot.tomato, gloss: 0.7, seed: seed &+ 2)
        let patch = lumpy(cx: cx + 20, cy: 690, rx: 90, ry: 42, rough: 0.2, steps: 22, seed: seed &+ 3)
        p.inside(pathOf(fruit)) {
            wash(p, patch, Pot.ink.mix(Pot.sepia, 0.4), strength: 0.92, bleed: 4, seed: seed &+ 4)
            crossHatch(p, pathOf(patch), depth: 2, spacing: 4, colour: Pot.ink, seed: seed &+ 5)
            wash(p, scaledRing(patch, about: pt(cx + 20, 690), 1.25), Pot.straw.dk(0.2), strength: 0.3, bleed: 6, seed: seed &+ 6)
        }
        penOutline(p, patch, weight: 1.8, colour: Pot.ink.al(0.9), seed: seed &+ 7)
        let calyx = pt(cx - 10, 405)
        for k in 0..<6 {
            let a = Double(k) / 6 * 2 * .pi
            blade(p, base: calyx, angle: a, length: 62, width: 16, tone: Pot.leaf, serrate: 0, curl: 0.1, veins: 1, seed: seed &+ UInt64(k + 10))
        }
        pen(p, [calyx, pt(cx - 14, 340)], weight: 9, colour: Pot.leaf.dk(0.3), wobble: 0.3, taper: true, seed: seed &+ 20)
        wateringCan(p, at: pt(700, 700), size: 110, seed: seed &+ 30)
    case "blight":
        groundLine(p, seed: seed)
        let spine = stemRun(pt(cx, 790), -Double.pi / 2 + 0.04, 450, curve: -0.2, wobble: 0.01, steps: 12, seed: seed &+ 1)
        stem(p, spine, w0: 22, w1: 12, tone: Pot.leaf.mix(Pot.sepia, 0.35), seed: seed &+ 2)
        p.inside(pathOf(bandOf(spine, [22, 17, 12], per: 6))) {
            for k in 0..<4 {
                let q = along(spine, 0.25 + Double(k) * 0.18)
                let streak = stemRun(q, -Double.pi / 2, 40, curve: 0, wobble: 0.05, steps: 4, seed: seed &+ UInt64(k + 5))
                pen(p, streak, weight: 8, colour: Pot.ink.al(0.75), wobble: 0.4, taper: true, seed: seed &+ UInt64(k + 6))
            }
        }
        for k in 0..<4 {
            let q = along(spine, 0.2 + Double(k) * 0.2)
            let side: Double = k % 2 == 0 ? -1 : 1
            pinnateLeaf(p, base: q, angle: -Double.pi / 2 + side * 1.35, length: 190, tone: Pot.leaf, leaflets: 5, leafletSize: 58, serrate: 0.4, seed: seed &+ UInt64(k + 10))
        }
        for k in 0..<9 {
            let x = cx + rng.r(-300, 300), y = rng.r(360, 720)
            let blot = lumpy(cx: x, cy: y, rx: rng.r(12, 30), ry: rng.r(9, 22), rough: 0.25, steps: 14, seed: seed &+ UInt64(k + 40))
            wash(p, scaledRing(blot, about: pt(x, y), 1.5), Pot.yellow.mix(Pot.strawPale, 0.5), strength: 0.5, bleed: 5, seed: seed &+ UInt64(k + 50))
            wash(p, blot, Pot.sepia.dk(0.25), strength: 0.85, bleed: 3, seed: seed &+ UInt64(k + 60))
        }
        let fruit = lumpy(cx: cx + 150, cy: 560, rx: 62, ry: 58, rough: 0.03, steps: 30, seed: seed &+ 70)
        produce(p, fruit, tone: Pot.tomato.mix(Pot.leafPale, 0.35), gloss: 0.5, seed: seed &+ 71)
        let rotPatch = lumpy(cx: cx + 170, cy: 585, rx: 34, ry: 26, rough: 0.2, steps: 16, seed: seed &+ 72)
        p.inside(pathOf(fruit)) { wash(p, rotPatch, Pot.sepia.dk(0.4), strength: 0.9, bleed: 3, seed: seed &+ 73) }
    case "powdery":
        groundLine(p, seed: seed)
        let leaf = lobedRing(at: pt(cx, 540), angle: -Double.pi / 2, size: 250, lobes: 5, depth: 0.3, aspect: 1.05, seed: seed &+ 1)
        wash(p, leaf, Pot.leafDeep.lt(0.12), strength: 0.58, bleed: 6, seed: seed &+ 2)
        roundShade(p, leaf, inset: 90, depth: 2, spacing: 7, colour: Pot.leafDeep.dk(0.4), seed: seed &+ 3)
        p.inside(pathOf(leaf)) {
            for k in 0..<5 {
                let a = -Double.pi / 2 + Double(k) / 5 * 2 * .pi + .pi / 5
                pen(p, [pt(cx, 560), pt(cx + cos(a) * 230, 540 + sin(a) * 230)], weight: 3.2, colour: Pot.leafDeep.dk(0.5), wobble: 0.4, taper: true, seed: seed &+ UInt64(k + 10))
            }
        }
        penOutline(p, leaf, weight: 2.2, colour: Pot.leafDeep.dk(0.6), seed: seed &+ 4)
        p.inside(pathOf(leaf)) {
            for k in 0..<12 {
                mouldPatch(p, at: pt(cx + rng.r(-170, 170), 540 + rng.r(-170, 170)), r: rng.r(40, 80), tone: Pot.white.lt(0.3), dots: false, seed: seed &+ UInt64(k + 20))
            }
        }
        pen(p, [pt(cx, 780), pt(cx - 10, 700), pt(cx, 620)], weight: 12, colour: Pot.leaf.dk(0.2), wobble: 0.5, taper: false, seed: seed &+ 30)
        hairs(p, pathOf(bandOf([pt(cx, 780), pt(cx, 620)], [14, 14], per: 4)), count: 40, length: 6, weight: 0.9, spread: 0.6, colour: Pot.leafDeep, seed: seed &+ 31)
    case "bolting":
        groundLine(p, seed: seed)
        sideRosette(p, crown: pt(cx, 780), radius: 170, tone: Pot.leafPale, layers: 2, crinkle: true, seed: seed &+ 1)
        let stalk = stemRun(pt(cx, 770), -Double.pi / 2, 520, curve: -0.1, wobble: 0.01, steps: 14, seed: seed &+ 2)
        stem(p, stalk, w0: 18, w1: 7, tone: Pot.leafPale.dk(0.1), seed: seed &+ 3)
        for k in 0..<7 {
            let q = along(stalk, 0.35 + Double(k) * 0.09)
            let side: Double = k % 2 == 0 ? -1 : 1
            blade(p, base: q, angle: -Double.pi / 2 + side * 0.9, length: 70 - Double(k) * 6, width: 26, tone: Pot.leafPale.dk(0.08), serrate: 0, curl: side * 0.2, veins: 2, seed: seed &+ UInt64(k + 10))
        }
        let top = stalk[stalk.count - 1]
        for k in 0..<9 {
            let a = -Double.pi / 2 + Double(k - 4) * 0.32
            let branch = stemRun(top, a, rng.r(50, 90), curve: 0.1, wobble: 0.03, steps: 5, seed: seed &+ UInt64(k + 30))
            pen(p, branch, weight: 3, colour: Pot.leafPale.dk(0.3), wobble: 0.3, taper: true, seed: seed &+ UInt64(k + 31))
            let e = branch[branch.count - 1]
            daisy(p, at: e, r: 16, petals: 9, petalTone: Pot.yellow, centreTone: Pot.yellow.dk(0.3), petalWidth: 0.3, seed: seed &+ UInt64(k + 40))
        }
        for _ in 0..<5 {
            let q = pt(cx + rng.r(-90, 90), 700 + rng.r(-20, 20))
            p.dot(Double(q.x), Double(q.y), rng.r(2, 4), Pot.white.al(0.9))
        }
    case "dampingoff":
        let tray = [pt(200, 700), pt(700, 700), pt(680, 790), pt(220, 790)]
        wash(p, tray, Pot.ink.lt(0.25), strength: 0.85, bleed: 2, seed: seed)
        penEdge(p, tray, weight: 2.4, colour: Pot.ink, seed: seed &+ 1)
        wash(p, [pt(215, 700), pt(685, 700), pt(670, 740), pt(230, 740)], Pot.soilDark, strength: 0.8, bleed: 3, seed: seed &+ 2)
        for k in 0..<11 {
            let x = 250.0 + Double(k) * 40
            let fallen = k >= 3 && k <= 7
            if fallen {
                let lay = stemRun(pt(x, 700), (k % 2 == 0 ? -0.3 : Double.pi + 0.3), 60, curve: 0.2, wobble: 0.02, steps: 5, seed: seed &+ UInt64(k + 10))
                pen(p, lay, weight: 4, colour: Pot.leafPale.mix(Pot.sepia, 0.5), wobble: 0.3, taper: true, seed: seed &+ UInt64(k + 11))
                let e = lay[lay.count - 1]
                blade(p, base: e, angle: -1.2, length: 28, width: 18, tone: Pot.leafPale.mix(Pot.sepia, 0.3), serrate: 0, curl: 0, veins: 1, seed: seed &+ UInt64(k + 12))
                blade(p, base: e, angle: -2.0, length: 28, width: 18, tone: Pot.leafPale.mix(Pot.sepia, 0.35), serrate: 0, curl: 0, veins: 1, seed: seed &+ UInt64(k + 13))
                p.egg(x, 702, 5, 3, Pot.sepia.dk(0.3))
            } else {
                seedlingVignette(p, at: pt(x, 700), tone: Pot.leafPale, monocot: false, seed: seed &+ UInt64(k + 20))
            }
        }
        mouldPatch(p, at: pt(430, 712), r: 60, tone: Pot.white, dots: false, seed: seed &+ 40)
        letter(p, "sown too thick, kept too wet", at: cx, 850, size: 20, colour: Pot.inkPale, face: "Baskerville-Italic", align: .centre)
        let lamp = [pt(300, 300), pt(600, 300), pt(600, 330), pt(300, 330)]
        wash(p, lamp, Pot.ink.lt(0.3), strength: 0.9, bleed: 1.5, seed: seed &+ 50)
        penEdge(p, lamp, weight: 2, colour: Pot.ink, seed: seed &+ 51)
        p.gradientRect(CGRect(x: 250, y: 332, width: 400, height: 240), Hue(r: 0.95, g: 0.70, b: 0.85, a: 0.35), Hue(r: 0.95, g: 0.70, b: 0.85, a: 0))
        pen(p, [pt(450, 220), pt(450, 300)], weight: 3, colour: Pot.ink, wobble: 0.2, taper: false, seed: seed &+ 52)
    case "fleabeetle":
        groundLine(p, seed: seed)
        for k in 0..<5 {
            let a = -Double.pi / 2 + Double(k - 2) * 0.5
            let leaf = lobedLeafRing(base: pt(cx, 780), angle: a, length: 300 - Double(abs(k - 2)) * 30, width: 110, seed: seed &+ UInt64(k))
            wash(p, leaf, Pot.leaf.lt(0.05), strength: 0.58, bleed: 4, seed: seed &+ UInt64(k + 10))
            roundShade(p, leaf, inset: 40, depth: 2, spacing: 5, colour: Pot.leaf.dk(0.45), seed: seed &+ UInt64(k + 20))
            penOutline(p, leaf, weight: 1.8, colour: Pot.leafDeep.dk(0.3), seed: seed &+ UInt64(k + 30))
            biteHoles(p, in: leaf, count: 22, size: 3...7, edge: false, seed: seed &+ UInt64(k + 40))
        }
        for k in 0..<6 {
            beetle(p, at: pt(cx + rng.r(-200, 200), rng.r(400, 720)), size: 14, tone: Pot.ink.lt(0.1), stripes: k % 2 == 0, seed: seed &+ UInt64(k + 60))
        }
        beetle(p, at: pt(690, 330), size: 40, tone: Pot.ink.lt(0.1), stripes: true, seed: seed &+ 70)
        for k in 0..<3 {
            pen(p, [pt(650 - Double(k) * 30, 360 + Double(k) * 20), pt(640 - Double(k) * 30, 340 + Double(k) * 20)], weight: 1.2, colour: Pot.inkPale, wobble: 0.3, taper: true, seed: seed &+ UInt64(k + 80))
        }
    case "cutworm":
        cutawaySoil(p, seed: seed)
        let stub = stemRun(pt(cx - 120, 790), -Double.pi / 2, 30, curve: 0, wobble: 0.02, steps: 3, seed: seed &+ 1)
        stem(p, stub, w0: 12, w1: 11, tone: Pot.leaf, seed: seed &+ 2)
        let lay = stemRun(pt(cx - 110, 762), 0.2, 180, curve: 0.15, wobble: 0.02, steps: 8, seed: seed &+ 3)
        stem(p, lay, w0: 11, w1: 7, tone: Pot.leaf.dk(0.1), seed: seed &+ 4)
        for k in 0..<4 {
            let q = along(lay, 0.4 + Double(k) * 0.18)
            blade(p, base: q, angle: (k % 2 == 0 ? -0.9 : 0.9) + 0.2, length: 60, width: 34, tone: Pot.leaf.dk(0.05), serrate: 0, curl: 0, veins: 3, seed: seed &+ UInt64(k + 10))
        }
        let ok = stemRun(pt(cx + 170, 790), -Double.pi / 2, 200, curve: -0.1, wobble: 0.02, steps: 8, seed: seed &+ 20)
        stem(p, ok, w0: 12, w1: 7, tone: Pot.leaf, seed: seed &+ 21)
        for k in 0..<4 {
            let q = along(ok, 0.35 + Double(k) * 0.2)
            blade(p, base: q, angle: -Double.pi / 2 + (k % 2 == 0 ? -1.1 : 1.1), length: 64, width: 36, tone: Pot.leaf, serrate: 0, curl: 0, veins: 3, seed: seed &+ UInt64(k + 30))
        }
        let collar = [pt(cx + 140, 760), pt(cx + 200, 760), pt(cx + 204, 800), pt(cx + 136, 800)]
        wash(p, collar, Pot.strawPale.dk(0.1), strength: 0.9, bleed: 1.5, seed: seed &+ 40)
        penEdge(p, collar, weight: 1.6, colour: Pot.ink.al(0.8), seed: seed &+ 41)
        grub(p, at: pt(cx - 160, 830), length: 90, width: 20, tone: Pot.inkPale.mix(Pot.sepia, 0.3), curled: true, seed: seed &+ 50)
    case "hornworm":
        groundLine(p, seed: seed)
        let spine = stemRun(pt(cx, 790), -Double.pi / 2 + 0.05, 470, curve: -0.3, wobble: 0.01, steps: 12, seed: seed &+ 1)
        stem(p, spine, w0: 20, w1: 10, tone: Pot.leaf, seed: seed &+ 2)
        for k in 0..<4 {
            let q = along(spine, 0.15 + Double(k) * 0.12)
            let side: Double = k % 2 == 0 ? -1 : 1
            if k < 2 {
                pinnateLeaf(p, base: q, angle: -Double.pi / 2 + side * 1.35, length: 170, tone: Pot.leaf, leaflets: 5, leafletSize: 52, serrate: 0.4, seed: seed &+ UInt64(k + 10))
            } else {
                let stubby = stemRun(q, -Double.pi / 2 + side * 1.3, 60, curve: 0.1, wobble: 0.02, steps: 4, seed: seed &+ UInt64(k + 10))
                pen(p, stubby, weight: 5, colour: Pot.leaf.dk(0.3), wobble: 0.3, taper: true, seed: seed &+ UInt64(k + 11))
            }
        }
        for k in 0..<5 {
            let q = along(spine, 0.62 + Double(k) * 0.08)
            let side: Double = k % 2 == 0 ? -1 : 1
            let stubby = stemRun(q, -Double.pi / 2 + side * 1.2, 50, curve: 0.1, wobble: 0.02, steps: 4, seed: seed &+ UInt64(k + 20))
            pen(p, stubby, weight: 4, colour: Pot.leaf.dk(0.35), wobble: 0.3, taper: true, seed: seed &+ UInt64(k + 21))
        }
        caterpillar(p, from: pt(cx - 30, 610), to: pt(cx + 40, 380), width: 44, tone: Pot.leaf.lt(0.15), chevrons: true, horn: true, seed: seed &+ 30)
        for k in 0..<6 {
            let q = along(spine, 0.2 + Double(k) * 0.06)
            let pellet = lumpy(cx: Double(q.x) + rng.r(-40, 40), cy: Double(q.y) + rng.r(0, 30), rx: 6, ry: 4, rough: 0.2, steps: 8, seed: seed &+ UInt64(k + 40))
            p.shape(pellet, Pot.ink.lt(0.1))
        }
    case "vineborer":
        groundLine(p, seed: seed)
        let vine = stemRun(pt(180, 700), 0.15, 520, curve: -0.3, wobble: 0.02, steps: 14, seed: seed &+ 1)
        stem(p, vine, w0: 30, w1: 18, tone: Pot.leafDeep.lt(0.15), seed: seed &+ 2)
        hairs(p, pathOf(bandOf(vine, [30, 24, 18], per: 4)), count: 90, length: 7, weight: 1.0, spread: 0.8, colour: Pot.leafDeep, seed: seed &+ 3)
        for k in 0..<3 {
            let q = along(vine, 0.3 + Double(k) * 0.25)
            let leaf = lobedRing(at: pt(Double(q.x) + 20, Double(q.y) - 120 - Double(k) * 10), angle: -Double.pi / 2 + Double(k - 1) * 0.3, size: 120, lobes: 5, depth: 0.28, aspect: 1.0, seed: seed &+ UInt64(k + 10))
            wash(p, leaf, Pot.leafDeep.lt(0.12).mix(Pot.straw, k == 1 ? 0.35 : 0.1), strength: 0.58, bleed: 4, seed: seed &+ UInt64(k + 20))
            roundShade(p, leaf, inset: 40, depth: 2, spacing: 5, colour: Pot.leafDeep.dk(0.4), seed: seed &+ UInt64(k + 30))
            penOutline(p, leaf, weight: 1.8, colour: Pot.leafDeep.dk(0.5), seed: seed &+ UInt64(k + 40))
            pen(p, [q, pt(Double(q.x) + 16, Double(q.y) - 70 - Double(k) * 10)], weight: 7, colour: Pot.leafDeep.lt(0.1), wobble: 0.5, taper: false, seed: seed &+ UInt64(k + 50))
        }
        let hole = along(vine, 0.16)
        p.dot(Double(hole.x), Double(hole.y) + 4, 9, Pot.soilDark)
        mouldPatch(p, at: pt(Double(hole.x) + 10, Double(hole.y) + 26), r: 26, tone: Pot.strawPale, dots: false, seed: seed &+ 60)
        let slit = [along(vine, 0.5), along(vine, 0.72)]
        pen(p, slit, weight: 3, colour: Pot.strawPale, wobble: 0.3, taper: false, seed: seed &+ 61)
        grub(p, at: pt(Double(along(vine, 0.6).x) - 20, Double(along(vine, 0.6).y) + 60), length: 70, width: 18, tone: Pot.white.dk(0.05), curled: false, seed: seed &+ 62)
    case "leafminer":
        groundLine(p, seed: seed)
        let leaf = crinkleRing(base: pt(cx, 790), angle: -Double.pi / 2, length: 470, width: 330, seed: seed &+ 1)
        wash(p, leaf, Pot.leafDeep.lt(0.1), strength: 0.58, bleed: 6, seed: seed &+ 2)
        roundShade(p, leaf, inset: 110, depth: 3, spacing: 7, colour: Pot.leafDeep.dk(0.45), seed: seed &+ 3)
        veinsIn(p, leaf, base: pt(cx, 790), tip: pt(cx, 330), tone: Pot.tomato.dk(0.1), count: 7, seed: seed &+ 4)
        penOutline(p, leaf, weight: 2.4, colour: Pot.leafDeep.dk(0.6), seed: seed &+ 5)
        p.inside(pathOf(leaf)) {
            for k in 0..<5 {
                let start = pt(cx + rng.r(-120, 120), rng.r(400, 700))
                let tunnel = stemRun(start, rng.r(0, 6.2), rng.r(90, 180), curve: rng.r(-2.5, 2.5), wobble: 0.15, steps: 12, seed: seed &+ UInt64(k + 10))
                let ring = bandOf(tunnel, [4, 9, 14, 18], per: 3)
                wash(p, ring, Pot.strawPale.lt(0.2), strength: 0.9, bleed: 1.5, seed: seed &+ UInt64(k + 20))
                pen(p, tunnel, weight: 2, colour: Pot.sepia.al(0.5), wobble: 0.6, taper: true, seed: seed &+ UInt64(k + 30))
                let blister = lumpy(cx: Double(tunnel[tunnel.count - 1].x), cy: Double(tunnel[tunnel.count - 1].y), rx: 26, ry: 18, rough: 0.2, steps: 14, seed: seed &+ UInt64(k + 40))
                wash(p, blister, Pot.strawPale.lt(0.15), strength: 0.9, bleed: 3, seed: seed &+ UInt64(k + 50))
            }
        }
        smallFly(p, at: pt(690, 330), size: 26, seed: seed &+ 60)
        for k in 0..<6 { p.egg(cx + 130 + Double(k) * 9, 620, 2.5, 4, Pot.white) }
    case "whiterot":
        cutawaySoil(p, seed: seed)
        for k in 0..<3 {
            let a = -Double.pi / 2 + Double(k - 1) * 0.35
            strapLeaf(p, base: pt(cx, 760), angle: a, length: 260, width: 26, tone: Pot.leafBlue.mix(Pot.straw, k == 1 ? 0.5 : 0.25), curve: Double(k - 1) * 0.5, fold: true, seed: seed &+ UInt64(k))
        }
        bulb(p, at: pt(cx, 820), rx: 80, ry: 70, tone: Pot.straw.mix(Pot.terracotta, 0.25), striate: 7, neck: 0.4, seed: seed &+ 10)
        mouldPatch(p, at: pt(cx, 885), r: 110, tone: Pot.white, dots: true, seed: seed &+ 20)
        mouldPatch(p, at: pt(cx - 60, 850), r: 50, tone: Pot.white, dots: true, seed: seed &+ 21)
        mouldPatch(p, at: pt(cx + 60, 855), r: 45, tone: Pot.white, dots: true, seed: seed &+ 22)
        for k in 0..<2 {
            let nx = cx + Double(k == 0 ? -210 : 210)
            for j in 0..<3 {
                strapLeaf(p, base: pt(nx, 770), angle: -Double.pi / 2 + Double(j - 1) * 0.3, length: 200, width: 20, tone: Pot.leafBlue, curve: Double(j - 1) * 0.4, fold: true, seed: seed &+ UInt64(k * 5 + j + 30))
            }
            bulb(p, at: pt(nx, 815), rx: 52, ry: 46, tone: Pot.straw.mix(Pot.terracotta, 0.25), striate: 5, neck: 0.4, seed: seed &+ UInt64(k + 40))
        }
    case "rust":
        groundLine(p, seed: seed)
        for k in 0..<5 {
            let a = -Double.pi / 2 + Double(k - 2) * 0.28
            let base = pt(cx + Double(k - 2) * 14, 790)
            let spineL = stemRun(base, a, 440 - Double(abs(k - 2)) * 40, curve: Double(k - 2) * 0.25, wobble: 0.01, steps: 10, seed: seed &+ UInt64(k))
            let ring = bandOf(spineL, [34, 42, 30, 8], per: 5)
            wash(p, ring, Pot.leafBlue.mix(Pot.leaf, 0.3), strength: 0.6, bleed: 3, seed: seed &+ UInt64(k + 10))
            crossHatch(p, pathOf(ring), depth: 1, spacing: 5, colour: Pot.leafBlue.dk(0.45), seed: seed &+ UInt64(k + 20))
            penOutline(p, ring, weight: 1.8, colour: Pot.leafBlue.dk(0.6), seed: seed &+ UInt64(k + 30))
            p.inside(pathOf(ring)) {
                for j in 0..<34 {
                    let q = along(spineL, 0.12 + Double(j) * 0.025)
                    let px = Double(q.x) + rng.r(-13, 13), py = Double(q.y)
                    p.egg(px, py, rng.r(4.5, 7.5), rng.r(3, 5), Pot.pumpkin)
                    p.egg(px - 1.5, py - 1.5, 2.0, 1.4, Pot.yellow.al(0.9))
                    p.hoop(px, py, rng.r(5, 8), 1.0, Pot.sepia.dk(0.2).al(0.7))
                }
            }
        }
        for j in 0..<60 {
            p.dot(cx + rng.r(-200, 200), 740 + Double(j % 10) * 4 + rng.r(0, 20), rng.r(1, 2.6), Pot.pumpkin.al(0.8))
        }
    case "downy":
        groundLine(p, seed: seed)
        let leaf = roundLeafRing(at: pt(cx, 560), angle: -Double.pi / 2, size: 250, seed: seed &+ 1)
        wash(p, leaf, Pot.leafDeep.lt(0.05), strength: 0.6, bleed: 5, seed: seed &+ 2)
        roundShade(p, leaf, inset: 100, depth: 2, spacing: 6, colour: Pot.leafDeep.dk(0.45), seed: seed &+ 3)
        veinsIn(p, leaf, base: pt(cx, 790), tip: pt(cx, 330), tone: Pot.leafDeep.dk(0.5), count: 6, seed: seed &+ 4)
        penOutline(p, leaf, weight: 2.2, colour: Pot.leafDeep.dk(0.6), seed: seed &+ 5)
        p.inside(pathOf(leaf)) {
            for k in 0..<7 {
                let c = pt(cx + rng.r(-160, 160), rng.r(400, 720))
                let patch = [pt(Double(c.x) - 40, Double(c.y) - 10), pt(Double(c.x) + 10, Double(c.y) - 46), pt(Double(c.x) + 44, Double(c.y) + 6), pt(Double(c.x) + 4, Double(c.y) + 40)]
                wash(p, patch, Pot.yellow.mix(Pot.strawPale, 0.4), strength: 0.75, bleed: 3, seed: seed &+ UInt64(k + 10))
                if k % 2 == 0 { mouldPatch(p, at: c, r: 22, tone: Pot.aubergine.lt(0.3).mix(Pot.glass, 0.4), dots: false, seed: seed &+ UInt64(k + 20)) }
            }
        }
        pen(p, [pt(cx, 790), pt(cx - 4, 700)], weight: 8, colour: Pot.leafDeep.lt(0.1), wobble: 0.4, taper: false, seed: seed &+ 40)
        for _ in 0..<30 {
            p.dot(rng.r(200, 700), rng.r(300, 360), rng.r(1, 2.2), Pot.frost.al(0.6))
        }
    case "birds":
        soilBand(p, y: 700, depth: 90, x0: 150, x1: 750, seed: seed)
        for k in 0..<4 {
            let x = 230.0 + Double(k) * 90
            let lay = stemRun(pt(x, 690), k % 2 == 0 ? 0.4 : Double.pi - 0.5, 50, curve: 0.1, wobble: 0.02, steps: 4, seed: seed &+ UInt64(k))
            pen(p, lay, weight: 3.5, colour: Pot.leafPale.dk(0.2), wobble: 0.3, taper: true, seed: seed &+ UInt64(k + 10))
            let e = lay[lay.count - 1]
            blade(p, base: e, angle: -0.8, length: 26, width: 16, tone: Pot.leafPale, serrate: 0, curl: 0, veins: 1, seed: seed &+ UInt64(k + 20))
            blade(p, base: e, angle: -2.3, length: 26, width: 16, tone: Pot.leafPale, serrate: 0, curl: 0, veins: 1, seed: seed &+ UInt64(k + 21))
            for j in 0..<4 {
                pen(p, [pt(x, 690), pt(x + rng.r(-12, 12), 690 + rng.r(8, 18))], weight: 1, colour: Pot.strawPale.dk(0.4), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 4 + j + 30))
            }
        }
        for k in 0..<2 {
            seedlingVignette(p, at: pt(600 + Double(k) * 70, 700), tone: Pot.leafPale, monocot: false, seed: seed &+ UInt64(k + 40))
        }
        for k in 0..<3 {
            let fx = 300.0 + Double(k) * 110, fy = 745.0
            for j in 0..<3 {
                pen(p, [pt(fx, fy + 10), pt(fx + Double(j - 1) * 9, fy - 6)], weight: 1.4, colour: Pot.soilDark, wobble: 0.2, taper: true, seed: seed &+ UInt64(k * 3 + j + 50))
            }
            pen(p, [pt(fx, fy + 10), pt(fx + 2, fy + 18)], weight: 1.4, colour: Pot.soilDark, wobble: 0.2, taper: true, seed: seed &+ UInt64(k + 60))
        }
        pigeon(p, at: pt(560, 520), size: 170, seed: seed &+ 70)
        for k in 0..<4 {
            let hx = 200.0 + Double(k) * 60
            pen(p, [pt(hx, 690), pt(hx + 30, 610), pt(hx + 60, 690)], weight: 2.2, colour: Pot.inkSoft, wobble: 0.3, taper: false, seed: seed &+ UInt64(k + 80))
        }
        pen(p, [pt(195, 640), pt(445, 640)], weight: 1.2, colour: Pot.inkSoft.al(0.6), wobble: 0.3, taper: false, seed: seed &+ 90)
    case "frostheave":
        soilBand(p, y: 700, depth: 100, x0: 150, x1: 750, seed: seed)
        for _ in 0..<500 { p.dot(rng.r(160, 740), rng.r(690, 712), rng.r(0.8, 2.4), Pot.white.al(rng.r(0.4, 0.9))) }
        for k in 0..<3 {
            let x = 260.0 + Double(k) * 190
            let lift = k == 1 ? 46.0 : 30.0
            let crown = pt(x, 700 - lift)
            for j in 0..<3 {
                strapLeaf(p, base: crown, angle: -Double.pi / 2 + Double(j - 1) * 0.35 + (k == 1 ? 0.5 : 0), length: 150, width: 18, tone: Pot.leafBlue, curve: Double(j - 1) * 0.5, fold: true, seed: seed &+ UInt64(k * 5 + j))
            }
            let clove = lumpy(cx: x, cy: 700 - lift + 22, rx: 22, ry: 30, rough: 0.05, steps: 16, seed: seed &+ UInt64(k + 20))
            produce(p, clove, tone: Pot.white.dk(0.08), gloss: 0.3, seed: seed &+ UInt64(k + 21))
            for j in 0..<7 {
                let root = stemRun(pt(x + rng.r(-14, 14), 700 - lift + 50), .pi / 2 + rng.r(-0.9, 0.9), rng.r(20, 50), curve: rng.r(-0.6, 0.6), wobble: 0.1, steps: 5, seed: seed &+ UInt64(k * 7 + j + 30))
                pen(p, root, weight: 1.6, colour: Pot.strawPale.dk(0.4), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 7 + j + 31))
            }
        }
        for k in 0..<6 {
            let x = 200.0 + Double(k) * 90
            for j in 0..<6 {
                let a = Double(j) / 6 * 2 * Double.pi
                pen(p, [pt(x, 380 + Double(k % 2) * 60), pt(x + cos(a) * 22, 380 + Double(k % 2) * 60 + sin(a) * 22)], weight: 2, colour: Pot.frostDeep.al(0.8), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 6 + j + 60))
            }
        }
    case "sunscald":
        groundLine(p, seed: seed, wide: false)
        let fruit = bandOf(stemRun(pt(cx, 380), .pi / 2 + 0.05, 330, curve: 0.08, wobble: 0.01, steps: 8, seed: seed &+ 1), [90, 170, 175, 150, 60], per: 5)
        produce(p, fruit, tone: Pot.tomato.mix(Pot.pumpkin, 0.3), gloss: 0.7, seed: seed &+ 2)
        let scald = lumpy(cx: cx + 60, cy: 560, rx: 70, ry: 95, rough: 0.15, steps: 22, seed: seed &+ 3)
        p.inside(pathOf(fruit)) {
            wash(p, scald, Pot.strawPale.lt(0.3), strength: 0.95, bleed: 4, seed: seed &+ 4)
            crossHatch(p, pathOf(scald), depth: 1, spacing: 5, colour: Pot.straw.dk(0.3).al(0.5), seed: seed &+ 5)
            mouldPatch(p, at: pt(cx + 70, 590), r: 28, tone: Pot.inkPale, dots: false, seed: seed &+ 6)
        }
        penOutline(p, scald, weight: 1.4, colour: Pot.sepia.al(0.7), seed: seed &+ 7)
        let calyx = pt(cx, 372)
        for k in 0..<5 {
            let a = -Double.pi / 2 + Double(k - 2) * 0.55
            blade(p, base: calyx, angle: a + .pi, length: 40, width: 22, tone: Pot.leaf, serrate: 0, curl: 0, veins: 1, seed: seed &+ UInt64(k + 10))
        }
        pen(p, [calyx, pt(cx + 6, 300)], weight: 9, colour: Pot.leaf.dk(0.3), wobble: 0.3, taper: true, seed: seed &+ 20)
        let sun = lumpy(cx: 720, cy: 300, rx: 46, ry: 46, rough: 0.02, steps: 30, seed: seed &+ 30)
        p.shape(sun, Pot.yellow)
        penOutline(p, sun, weight: 1.6, colour: Pot.straw.dk(0.2).al(0.7), seed: seed &+ 31)
        for k in 0..<8 {
            let a = Double(k) / 8 * 2 * .pi
            pen(p, [pt(720 + cos(a) * 58, 300 + sin(a) * 58), pt(720 + cos(a) * 84, 300 + sin(a) * 84)], weight: 2.4, colour: Pot.straw.dk(0.2), wobble: 0.3, taper: true, seed: seed &+ UInt64(k + 40))
        }
    case "splitroot":
        cutawaySoil(p, seed: seed)
        featheryLeaf(p, base: pt(cx - 10, 786), angle: -Double.pi / 2 - 0.3, length: 230, tone: Pot.leafPale, fineness: 6, seed: seed &+ 1)
        featheryLeaf(p, base: pt(cx + 10, 786), angle: -Double.pi / 2 + 0.3, length: 220, tone: Pot.leafPale, fineness: 6, seed: seed &+ 2)
        let root = taprootRing(top: pt(cx, 792), length: 250, width: 84, seed: seed &+ 3)
        produce(p, root, tone: Pot.carrot, gloss: 0.3, seed: seed &+ 4)
        let crack = stemRun(pt(cx - 6, 800), .pi / 2, 170, curve: 0.15, wobble: 0.08, steps: 12, seed: seed &+ 5)
        let crackRing = bandOf(crack, [3, 16, 22, 12, 2], per: 3)
        p.inside(pathOf(root)) {
            wash(p, crackRing, Pot.carrot.lt(0.35), strength: 0.95, bleed: 1.5, seed: seed &+ 6)
            crossHatch(p, pathOf(crackRing), depth: 1, spacing: 3, colour: Pot.carrot.dk(0.5).al(0.6), seed: seed &+ 7)
            penOutline(p, crackRing, weight: 1.6, colour: Pot.carrot.dk(0.65), seed: seed &+ 8)
        }
        let beetRoot = lumpy(cx: cx + 200, cy: 860, rx: 48, ry: 52, rough: 0.05, steps: 24, seed: seed &+ 10)
        produce(p, beetRoot, tone: Pot.beet, gloss: 0.35, seed: seed &+ 11)
        let crack2 = [pt(cx + 190, 820), pt(cx + 205, 860), pt(cx + 196, 900)]
        p.inside(pathOf(beetRoot)) {
            pen(p, crack2, weight: 7, colour: Pot.beet.lt(0.4), wobble: 0.5, taper: true, seed: seed &+ 12)
            pen(p, crack2, weight: 2, colour: Pot.beet.dk(0.5), wobble: 0.4, taper: true, seed: seed &+ 13)
        }
        wateringCan(p, at: pt(190, 640), size: 100, seed: seed &+ 20)
    case "nitrogen":
        groundLine(p, seed: seed)
        let stalk = stemRun(pt(cx, 790), -Double.pi / 2, 500, curve: 0.02, wobble: 0.005, steps: 10, seed: seed &+ 1)
        stem(p, stalk, w0: 26, w1: 14, tone: Pot.leafPale.mix(Pot.straw, 0.2), seed: seed &+ 2)
        for k in 0..<6 {
            let q = along(stalk, 0.12 + Double(k) * 0.15)
            let side: Double = k % 2 == 0 ? -1 : 1
            let yellow = k < 3 ? 0.75 - Double(k) * 0.2 : 0.05
            strapLeaf(p, base: q, angle: -Double.pi / 2 + side * 1.25, length: 250 - Double(k) * 15, width: 44, tone: Pot.leaf.mix(Pot.yellow.mix(Pot.strawPale, 0.3), yellow), curve: side * 0.9, fold: false, seed: seed &+ UInt64(k + 10))
        }
        for k in 0..<3 {
            let q = along(stalk, 0.12 + Double(k) * 0.15)
            let side: Double = k % 2 == 0 ? -1 : 1
            pen(p, [pt(Double(q.x) + side * 40, Double(q.y) - 6), pt(Double(q.x) + side * 150, Double(q.y) - 40)], weight: 3, colour: Pot.yellow.mix(Pot.straw, 0.3), wobble: 0.4, taper: true, seed: seed &+ UInt64(k + 30))
        }
        let heap = lumpy(cx: 690, cy: 760, rx: 90, ry: 40, rough: 0.12, steps: 22, seed: seed &+ 40)
        wash(p, heap, Pot.soilDark, strength: 0.85, bleed: 4, seed: seed &+ 41)
        grit(p, pathOf(heap), density: 0.02, sizeMin: 0.8, sizeMax: 2.4, colour: Pot.soilLight, seed: seed &+ 42)
        penOutline(p, heap, weight: 2, colour: Pot.ink.al(0.7), seed: seed &+ 43)
        letter(p, "compost", at: 690, 820, size: 18, colour: Pot.inkPale, face: "Baskerville-Italic", align: .centre)
    case "wireworm":
        cutawaySoil(p, seed: seed)
        let tuber = lumpy(cx: cx, cy: 860, rx: 130, ry: 80, rough: 0.06, steps: 30, seed: seed &+ 1)
        produce(p, tuber, tone: Pot.straw.mix(Pot.soilLight, 0.3), gloss: 0.2, seed: seed &+ 2)
        p.inside(pathOf(tuber)) {
            for _ in 0..<7 {
                let hx = cx + rng.r(-100, 100), hy = 860 + rng.r(-50, 50)
                p.dot(hx, hy, rng.r(3.5, 5.5), Pot.soilDark)
                p.hoop(hx, hy, rng.r(5, 7), 1.2, Pot.sepia.al(0.7))
            }
        }
        for k in 0..<3 {
            let root = stemRun(pt(cx - 80 + Double(k) * 80, 800), -Double.pi / 2 + rng.r(-0.3, 0.3), 40, curve: 0, wobble: 0.1, steps: 4, seed: seed &+ UInt64(k + 10))
            pen(p, root, weight: 2, colour: Pot.strawPale.dk(0.4), wobble: 0.3, taper: true, seed: seed &+ UInt64(k + 11))
        }
        let spine = stemRun(pt(cx, 786), -Double.pi / 2, 300, curve: -0.15, wobble: 0.01, steps: 8, seed: seed &+ 20)
        stem(p, spine, w0: 16, w1: 9, tone: Pot.leaf, seed: seed &+ 21)
        for k in 0..<4 {
            let q = along(spine, 0.3 + Double(k) * 0.2)
            pinnateLeaf(p, base: q, angle: -Double.pi / 2 + (k % 2 == 0 ? -1.2 : 1.2), length: 120, tone: Pot.leaf, leaflets: 5, leafletSize: 34, serrate: 0.1, seed: seed &+ UInt64(k + 30))
        }
        grub(p, at: pt(cx + 150, 900), length: 70, width: 8, tone: Pot.pumpkin.mix(Pot.straw, 0.4), curled: false, seed: seed &+ 40)
        grub(p, at: pt(cx - 200, 920), length: 60, width: 7, tone: Pot.pumpkin.mix(Pot.straw, 0.4), curled: false, seed: seed &+ 41)
    default:
        break
    }
}

func crinkleRing(base: CGPoint, angle: Double, length: Double, width: Double, seed: UInt64) -> [CGPoint] {
    var rng = Chip(seed)
    var outline: [CGPoint] = []
    let steps = 40
    func edge(_ t: Double, _ side: Double) -> CGPoint {
        let a = angle + 0.15 * t * side
        let cx = Double(base.x) + cos(a) * length * t
        let cy = Double(base.y) + sin(a) * length * t
        let half = sin(.pi * pow(t, 0.6)) * width * 0.5 * (1 + 0.16 * sin(t * 22 + rng.r(-0.4, 0.4)) + 0.08 * sin(t * 53))
        return pt(cx - sin(a) * half * side, cy + cos(a) * half * side)
    }
    for i in 0...steps { outline.append(edge(Double(i) / Double(steps), 1)) }
    for i in stride(from: steps, through: 0, by: -1) { outline.append(edge(Double(i) / Double(steps), -1)) }
    return outline
}

func lobedLeafRing(base: CGPoint, angle: Double, length: Double, width: Double, seed: UInt64) -> [CGPoint] {
    var rng = Chip(seed)
    var outline: [CGPoint] = []
    let steps = 44
    func edge(_ t: Double, _ side: Double) -> CGPoint {
        let cx = Double(base.x) + cos(angle) * length * t
        let cy = Double(base.y) + sin(angle) * length * t
        let lobe = 1 + 0.35 * abs(sin(t * 12.5)) * (t > 0.15 && t < 0.95 ? 1 : 0)
        let half = sin(.pi * pow(t, 0.75)) * width * 0.5 * lobe * rng.r(0.97, 1.03)
        return pt(cx - sin(angle) * half * side, cy + cos(angle) * half * side)
    }
    for i in 0...steps { outline.append(edge(Double(i) / Double(steps), 1)) }
    for i in stride(from: steps, through: 0, by: -1) { outline.append(edge(Double(i) / Double(steps), -1)) }
    return outline
}

func roundLeafRing(at c: CGPoint, angle: Double, size: Double, seed: UInt64) -> [CGPoint] {
    var rng = Chip(seed)
    var outline: [CGPoint] = []
    for i in 0..<48 {
        let a = Double(i) / 48 * 2 * .pi
        let rr = size * (0.92 + 0.08 * cos(a * 3)) * rng.r(0.97, 1.03)
        outline.append(pt(Double(c.x) + cos(a) * rr * 0.85, Double(c.y) + sin(a) * rr))
    }
    return outline
}

func taprootRing(top: CGPoint, length: Double, width: Double, seed: UInt64) -> [CGPoint] {
    let spine = stemRun(top, .pi / 2, length, curve: 0.05, wobble: 0.01, steps: 10, seed: seed)
    return bandOf(spine, [width, width * 0.92, width * 0.6, width * 0.22, width * 0.05], per: 5)
}

func veinsIn(_ p: Leaf, _ ring: [CGPoint], base: CGPoint, tip: CGPoint, tone: Hue, count: Int, seed: UInt64) {
    p.inside(pathOf(ring)) {
        pen(p, [base, tip], weight: 3.4, colour: tone, wobble: 0.5, taper: true, seed: seed)
        let dx = Double(tip.x - base.x), dy = Double(tip.y - base.y)
        let axis = atan2(dy, dx)
        for k in 1...count {
            let t = Double(k) / Double(count + 1)
            let q = pt(Double(base.x) + dx * t, Double(base.y) + dy * t)
            let len = hypot(dx, dy) * 0.42 * (1 - t * 0.5)
            for side in [-1.0, 1.0] {
                pen(p, [q, pt(Double(q.x) + cos(axis + side * 0.95) * len, Double(q.y) + sin(axis + side * 0.95) * len)], weight: 1.8, colour: tone.al(0.75), wobble: 0.5, taper: true, seed: seed &+ UInt64(k * 3 + Int(side + 2)))
            }
        }
    }
}

func drawTroublePlate(_ t: Trouble, dir: String) {
    let previous = sheetScale
    sheetScale = 1.3
    let p = Leaf(900, 1200)
    let seed = hashOf("trouble-" + t.key)
    layPaper(p, seed: seed, tone: Pot.creamWarm)
    p.flipDown()
    p.light = -2.36
    packetFrame(p, seed: seed &+ 3)
    letter(p, t.name, at: p.w / 2, 138, size: 54, colour: Pot.ink, face: "Baskerville-Bold", align: .centre)
    letter(p, troubleSubtitle(t), at: p.w / 2, 178, size: 24, colour: Pot.inkSoft, face: "Baskerville-Italic", align: .centre)
    p.box(p.w * 0.16, 200, p.w * 0.68, 1.4, Pot.ink.al(0.35))
    p.ctx.saveGState()
    p.ctx.translateBy(x: 0, y: 40)
    drawTroubleFigure(p, t, seed: seed &+ 11)
    p.ctx.restoreGState()
    p.box(p.w * 0.10, 940, p.w * 0.80, 1.2, Pot.ink.al(0.28))
    letter(p, "WHAT YOU SEE", at: 96, 972, size: 13, colour: Pot.inkPale, face: "Baskerville", align: .left, tracking: 2.2)
    let sign = t.symptomWords.prefix(1).uppercased() + t.symptomWords.dropFirst() + "."
    letter(p, sign, at: 96, 1000, size: 21, colour: Pot.ink, face: "Baskerville", align: .left)
    letter(p, "DO THIS", at: 96, 1046, size: 13, colour: Pot.inkPale, face: "Baskerville", align: .left, tracking: 2.2)
    letter(p, t.remedy.title + ".", at: 96, 1074, size: 21, colour: Pot.ink, face: "Baskerville", align: .left)
    let stampW = 200.0, stampH = 54.0
    let sx = 700.0, sy = 1010.0
    let stamp = rotatedRing([pt(sx - stampW / 2, sy - stampH / 2), pt(sx + stampW / 2, sy - stampH / 2), pt(sx + stampW / 2, sy + stampH / 2), pt(sx - stampW / 2, sy + stampH / 2)], about: pt(sx, sy), -0.08)
    penEdge(p, stamp, weight: 2.6, colour: Pot.terracotta.al(0.8), seed: seed &+ 40)
    penEdge(p, scaledRing(stamp, about: pt(sx, sy), 0.92), weight: 1.0, colour: Pot.terracotta.al(0.55), seed: seed &+ 41)
    letter(p, t.kind.name.uppercased(), at: sx, sy + 9, size: 22, colour: Pot.terracotta.al(0.85), face: "Baskerville-Bold", align: .centre, tracking: 3, rotate: -0.08)
    p.writeJPG(dir, t.plate, quality: 0.84)
    sheetScale = previous
}
