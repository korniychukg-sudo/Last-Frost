import Foundation
import CoreGraphics

func stemRun(_ base: CGPoint, _ angle: Double, _ length: Double, curve: Double, wobble: Double,
             steps: Int = 14, seed: UInt64) -> [CGPoint] {
    var rng = Chip(seed)
    var pts: [CGPoint] = [base]
    var a = angle
    var x = Double(base.x), y = Double(base.y)
    for _ in 0..<steps {
        let seg = length / Double(steps)
        a += curve / Double(steps) + rng.signed() * wobble
        x += cos(a) * seg
        y += sin(a) * seg
        pts.append(pt(x, y))
    }
    return pts
}

func bandOf(_ spine: [CGPoint], _ widths: [Double], per: Int = 6) -> [CGPoint] {
    let fine = resample(spine, count: max(4, spine.count * per))
    var left: [CGPoint] = []
    var right: [CGPoint] = []
    for i in 0..<fine.count {
        let t = Double(i) / Double(fine.count - 1)
        let a = fine[max(0, i - 1)], b = fine[min(fine.count - 1, i + 1)]
        var tx = Double(b.x - a.x), ty = Double(b.y - a.y)
        let l = (tx * tx + ty * ty).squareRoot()
        if l > 0 { tx /= l; ty /= l } else { tx = 1; ty = 0 }
        let idx = t * Double(widths.count - 1)
        let i0 = Int(idx), i1 = min(widths.count - 1, i0 + 1)
        let f = idx - Double(i0)
        let hw = (widths[i0] + (widths[i1] - widths[i0]) * f) * 0.5
        left.append(pt(Double(fine[i].x) - ty * hw, Double(fine[i].y) + tx * hw))
        right.append(pt(Double(fine[i].x) + ty * hw, Double(fine[i].y) - tx * hw))
    }
    return left + right.reversed()
}

func stem(_ p: Leaf, _ spine: [CGPoint], w0: Double, w1: Double, tone: Hue, woody: Bool = false, seed: UInt64) {
    guard spine.count > 1 else { return }
    let outline = bandOf(spine, [w0, (w0 + w1) / 2, w1], per: 6)
    wash(p, outline, tone, strength: woody ? 0.56 : 0.48, bleed: max(1.2, w0 * 0.16), seed: seed &+ 3)
    let body = pathOf(outline)
    crossHatch(p, body, depth: woody ? 3 : 1, spacing: max(2.4, w0 * 0.42), colour: tone.dk(0.45), seed: seed &+ 11)
    if woody {
        var rng = Chip(seed &+ 17)
        let fine = resample(spine, count: 24)
        for k in 0..<Int(max(4, w0 * 1.6)) {
            let idx = rng.i(1, fine.count - 2)
            let a = fine[idx], b = fine[idx + 1]
            var tx = Double(b.x - a.x), ty = Double(b.y - a.y)
            let l = (tx * tx + ty * ty).squareRoot()
            if l <= 0 { continue }
            tx /= l; ty /= l
            let off = rng.signed() * w0 * 0.34
            let run = rng.r(w0 * 1.0, w0 * 3.5)
            let s = pt(Double(a.x) - ty * off, Double(a.y) + tx * off)
            let e = pt(Double(s.x) + tx * run, Double(s.y) + ty * run)
            p.inside(body) {
                pen(p, [s, e], weight: max(0.7, w0 * 0.09), colour: tone.dk(0.55).al(0.7), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 13 + 5))
            }
        }
    }
    penOutline(p, outline, weight: max(1.0, w0 * 0.14), colour: tone.dk(0.62), seed: seed &+ 23)
}

func bladeRing(base: CGPoint, angle: Double, length: Double, width: Double, curl: Double,
               serrate: Double, steps: Int = 26, seed: UInt64 = 5) -> [CGPoint] {
    var rng = Chip(seed)
    var outline: [CGPoint] = []
    func edgePoint(_ t: Double, _ side: Double) -> CGPoint {
        let a = angle + curl * t
        let cx = Double(base.x) + cos(a) * length * t
        let cy = Double(base.y) + sin(a) * length * t
        var half = sin(.pi * pow(t, 0.70)) * width * 0.5
        if serrate > 0 { half *= 1.0 + serrate * 0.5 * (1 + sin(t * 30 + rng.r(-0.2, 0.2))) }
        return pt(cx - sin(a) * half * side, cy + cos(a) * half * side)
    }
    for i in 0...steps { outline.append(edgePoint(Double(i) / Double(steps), 1)) }
    for i in stride(from: steps, through: 0, by: -1) { outline.append(edgePoint(Double(i) / Double(steps), -1)) }
    return outline
}

func blade(_ p: Leaf, base: CGPoint, angle: Double, length: Double, width: Double,
           tone: Hue, serrate: Double = 0, curl: Double = 0, veins: Int = 5, seed: UInt64) {
    let outline = bladeRing(base: base, angle: angle, length: length, width: width, curl: curl, serrate: serrate, seed: seed)
    wash(p, outline, tone, strength: 0.56, bleed: max(1.2, length * 0.024), seed: seed &+ 3)
    roundShade(p, outline, inset: width * 0.40, depth: 2, spacing: max(2.0, length * 0.03), colour: tone.dk(0.42), seed: seed &+ 7)
    let body = pathOf(outline)
    p.inside(body) {
        let tipA = angle + curl * 0.98
        let tip = pt(Double(base.x) + cos(tipA) * length * 0.98, Double(base.y) + sin(tipA) * length * 0.98)
        pen(p, [base, pt(Double(base.x) + cos(angle + curl * 0.5) * length * 0.5, Double(base.y) + sin(angle + curl * 0.5) * length * 0.5), tip],
            weight: max(0.8, length * 0.014), colour: tone.dk(0.52), wobble: 0.4, taper: true, seed: seed &+ 11)
        for k in 1..<max(2, veins + 1) {
            let t = Double(k) / Double(veins + 1)
            let a = angle + curl * t
            let cx = Double(base.x) + cos(a) * length * t
            let cy = Double(base.y) + sin(a) * length * t
            let span = sin(.pi * pow(t, 0.70)) * width * 0.5
            for side in [-1.0, 1.0] {
                pen(p, [pt(cx, cy), pt(cx + cos(a + 0.85 * side) * span * 1.4, cy + sin(a + 0.85 * side) * span * 1.4)],
                    weight: max(0.5, length * 0.007), colour: tone.dk(0.36).al(0.7), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 7 + 40))
            }
        }
    }
    penOutline(p, outline, weight: max(0.9, length * 0.010), colour: tone.dk(0.6), seed: seed &+ 29)
}

func lobedRing(at c: CGPoint, angle: Double, size: Double, lobes: Int, depth: Double, aspect: Double = 1.0, seed: UInt64) -> [CGPoint] {
    var rng = Chip(seed)
    var out: [CGPoint] = []
    let steps = lobes * 10
    for i in 0..<steps {
        let t = Double(i) / Double(steps)
        let a = t * 2 * .pi
        let lobe = pow(abs(sin(t * Double(lobes) * .pi)), 0.6)
        let rr = size * (1 - depth + depth * lobe) * rng.r(0.97, 1.03)
        let lx = cos(a) * rr * aspect, ly = sin(a) * rr
        out.append(pt(Double(c.x) + cos(angle) * lx - sin(angle) * ly, Double(c.y) + sin(angle) * lx + cos(angle) * ly))
    }
    return out
}

func heartLeaf(_ p: Leaf, at c: CGPoint, angle: Double, size: Double, tone: Hue, lobes: Int = 5, seed: UInt64) {
    let outline = lobedRing(at: c, angle: angle, size: size, lobes: lobes, depth: 0.22, seed: seed)
    wash(p, outline, tone, strength: 0.56, bleed: size * 0.05, seed: seed &+ 3)
    roundShade(p, outline, inset: size * 0.34, depth: 2, spacing: max(2.0, size * 0.05), colour: tone.dk(0.42), seed: seed &+ 7)
    p.inside(pathOf(outline)) {
        for k in 0..<lobes {
            let a = angle + Double(k) / Double(lobes) * 2 * .pi + .pi / Double(lobes)
            pen(p, [c, pt(Double(c.x) + cos(a) * size * 0.92, Double(c.y) + sin(a) * size * 0.92)],
                weight: max(0.7, size * 0.024), colour: tone.dk(0.48), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 9 + 11))
        }
    }
    penOutline(p, outline, weight: max(0.9, size * 0.020), colour: tone.dk(0.6), seed: seed &+ 29)
}

func roundLeaf(_ p: Leaf, at c: CGPoint, angle: Double, size: Double, tone: Hue, aspect: Double = 0.62, seed: UInt64) {
    var rng = Chip(seed)
    var outline: [CGPoint] = []
    let steps = 30
    for i in 0...steps {
        let t = Double(i) / Double(steps)
        let a = -Double.pi / 2 + t * .pi
        let rr = size * (0.52 + 0.48 * cos(a * 0.7)) * rng.r(0.96, 1.04)
        let lx = cos(a) * rr * aspect, ly = sin(a) * rr
        outline.append(pt(Double(c.x) + cos(angle) * ly - sin(angle) * lx, Double(c.y) + sin(angle) * ly + cos(angle) * lx))
    }
    for i in stride(from: steps, through: 0, by: -1) {
        let t = Double(i) / Double(steps)
        let a = -Double.pi / 2 + t * .pi
        let rr = size * (0.52 + 0.48 * cos(a * 0.7)) * rng.r(0.96, 1.04)
        let lx = -cos(a) * rr * aspect, ly = sin(a) * rr
        outline.append(pt(Double(c.x) + cos(angle) * ly - sin(angle) * lx, Double(c.y) + sin(angle) * ly + cos(angle) * lx))
    }
    wash(p, outline, tone, strength: 0.56, bleed: size * 0.05, seed: seed &+ 3)
    roundShade(p, outline, inset: size * 0.36, depth: 2, spacing: max(2.0, size * 0.055), colour: tone.dk(0.42), seed: seed &+ 7)
    p.inside(pathOf(outline)) {
        pen(p, [c, pt(Double(c.x) + cos(angle) * size, Double(c.y) + sin(angle) * size)],
            weight: max(0.9, size * 0.035), colour: tone.dk(0.48), wobble: 0.4, taper: true, seed: seed &+ 11)
        for k in 1...3 {
            let t = Double(k) / 4
            let q = pt(Double(c.x) + cos(angle) * size * t, Double(c.y) + sin(angle) * size * t)
            for side in [-1.0, 1.0] {
                pen(p, [q, pt(Double(q.x) + cos(angle + 0.9 * side) * size * 0.28, Double(q.y) + sin(angle + 0.9 * side) * size * 0.28)],
                    weight: max(0.5, size * 0.014), colour: tone.dk(0.36).al(0.7), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 5 + 60))
            }
        }
    }
    penOutline(p, outline, weight: max(0.9, size * 0.026), colour: tone.dk(0.60), seed: seed &+ 29)
}

func crinkleLeaf(_ p: Leaf, base: CGPoint, angle: Double, length: Double, width: Double, tone: Hue, seed: UInt64) {
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
    wash(p, outline, tone, strength: 0.58, bleed: max(1.4, length * 0.02), seed: seed &+ 3)
    roundShade(p, outline, inset: width * 0.36, depth: 3, spacing: max(2.0, length * 0.026), colour: tone.dk(0.44), seed: seed &+ 7)
    p.inside(pathOf(outline)) {
        let tip = pt(Double(base.x) + cos(angle) * length * 0.97, Double(base.y) + sin(angle) * length * 0.97)
        pen(p, [base, tip], weight: max(0.9, length * 0.016), colour: tone.dk(0.52), wobble: 0.5, taper: true, seed: seed &+ 11)
        for k in 1..<7 {
            let t = Double(k) / 7
            let q = pt(Double(base.x) + cos(angle) * length * t, Double(base.y) + sin(angle) * length * t)
            for side in [-1.0, 1.0] {
                pen(p, [q, pt(Double(q.x) + cos(angle + 1.0 * side) * width * 0.45, Double(q.y) + sin(angle + 1.0 * side) * width * 0.45)],
                    weight: max(0.5, length * 0.007), colour: tone.dk(0.36).al(0.7), wobble: 0.6, taper: true, seed: seed &+ UInt64(k * 7 + 40))
            }
        }
    }
    penOutline(p, outline, weight: max(0.9, length * 0.011), colour: tone.dk(0.6), seed: seed &+ 29)
}

func strapLeaf(_ p: Leaf, base: CGPoint, angle: Double, length: Double, width: Double, tone: Hue, curve: Double = 0.4, fold: Bool = false, seed: UInt64) {
    let spine = stemRun(base, angle, length, curve: curve, wobble: 0.01, steps: 12, seed: seed)
    let outline = bandOf(spine, [width * 0.55, width, width * 0.7, width * 0.15], per: 5)
    wash(p, outline, tone, strength: 0.56, bleed: max(1.2, width * 0.12), seed: seed &+ 3)
    let body = pathOf(outline)
    crossHatch(p, body, depth: 1, spacing: max(2.2, width * 0.3), colour: tone.dk(0.42), seed: seed &+ 7)
    if fold {
        p.inside(body) {
            pen(p, spine, weight: max(0.8, width * 0.12), colour: tone.lt(0.35).al(0.8), wobble: 0.3, taper: true, seed: seed &+ 11)
        }
    } else {
        p.inside(body) {
            pen(p, spine, weight: max(0.6, width * 0.08), colour: tone.dk(0.40).al(0.7), wobble: 0.3, taper: true, seed: seed &+ 11)
        }
    }
    penOutline(p, outline, weight: max(0.9, width * 0.09), colour: tone.dk(0.6), seed: seed &+ 29)
}

func pinnateLeaf(_ p: Leaf, base: CGPoint, angle: Double, length: Double, tone: Hue, leaflets: Int, leafletSize: Double, serrate: Double = 0.3, seed: UInt64) {
    let spine = stemRun(base, angle, length, curve: 0.25, wobble: 0.02, steps: 10, seed: seed)
    let fine = resample(spine, count: leaflets + 2)
    pen(p, spine, weight: max(1.0, length * 0.014), colour: tone.dk(0.5), wobble: 0.5, taper: true, seed: seed &+ 1)
    for k in 0..<leaflets {
        let q = fine[k + 1]
        let a = fine[min(fine.count - 1, k + 2)], b = fine[max(0, k)]
        let dir = atan2(Double(a.y - b.y), Double(a.x - b.x))
        let side: Double = k % 2 == 0 ? 1 : -1
        let sz = leafletSize * (k == leaflets - 1 ? 1.15 : 0.8 + 0.2 * sin(Double(k) / Double(leaflets) * .pi))
        if k == leaflets - 1 {
            blade(p, base: q, angle: dir, length: sz, width: sz * 0.55, tone: tone, serrate: serrate, curl: 0.1, veins: 3, seed: seed &+ UInt64(k * 11 + 3))
        } else {
            blade(p, base: q, angle: dir + side * 1.05, length: sz, width: sz * 0.55, tone: k % 3 == 0 ? tone.dk(0.08) : tone, serrate: serrate, curl: side * 0.2, veins: 3, seed: seed &+ UInt64(k * 11 + 3))
        }
    }
}

func trifoliate(_ p: Leaf, at c: CGPoint, angle: Double, size: Double, tone: Hue, seed: UInt64) {
    for (k, off) in [-0.9, 0.0, 0.9].enumerated() {
        let a = angle + off
        let q = pt(Double(c.x) + cos(a) * size * 0.18, Double(c.y) + sin(a) * size * 0.18)
        blade(p, base: q, angle: a, length: size, width: size * 0.62, tone: k == 1 ? tone : tone.dk(0.06), serrate: 0, curl: off * 0.15, veins: 4, seed: seed &+ UInt64(k * 17 + 2))
    }
}

func featheryLeaf(_ p: Leaf, base: CGPoint, angle: Double, length: Double, tone: Hue, fineness: Int = 7, seed: UInt64) {
    var rng = Chip(seed)
    let spine = stemRun(base, angle, length, curve: 0.35, wobble: 0.03, steps: 10, seed: seed)
    pen(p, spine, weight: max(0.9, length * 0.012), colour: tone.dk(0.45), wobble: 0.5, taper: true, seed: seed &+ 1)
    let fine = resample(spine, count: fineness + 2)
    for k in 0..<fineness {
        let q = fine[k + 1]
        let a = fine[min(fine.count - 1, k + 2)], b = fine[max(0, k)]
        let dir = atan2(Double(a.y - b.y), Double(a.x - b.x))
        let sz = length * (0.22 + 0.16 * sin(Double(k) / Double(fineness) * .pi))
        for side in [-1.0, 1.0] {
            let branch = stemRun(q, dir + side * 0.95, sz, curve: side * 0.3, wobble: 0.04, steps: 6, seed: seed &+ UInt64(k * 3 + Int(side + 2)))
            pen(p, branch, weight: max(0.7, sz * 0.05), colour: tone.dk(0.35), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 5 + 7))
            let sub = resample(branch, count: 5)
            for j in 0..<4 {
                let s = sub[j]
                let d2 = dir + side * 0.95 + side * 0.3 * Double(j) / 4
                for s2 in [-1.0, 1.0] {
                    let len = sz * rng.r(0.22, 0.4)
                    pen(p, [s, pt(Double(s.x) + cos(d2 + s2 * 0.9) * len, Double(s.y) + sin(d2 + s2 * 0.9) * len)],
                        weight: max(0.5, sz * 0.04), colour: tone.dk(rng.r(0.0, 0.3)), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 31 + j * 7 + 1))
                }
            }
        }
    }
}

func sideRosette(_ p: Leaf, crown: CGPoint, radius: Double, tone: Hue, layers: Int, crinkle: Bool, seed: UInt64) {
    var rng = Chip(seed)
    for layer in 0..<layers {
        let f = 1.0 - Double(layer) * (0.22 / Double(max(1, layers - 1)))
        let count = max(4, 8 - layer * 2)
        let spanA = 2.95 - Double(layer) * 0.55
        for k in 0..<count {
            let u = Double(k) / Double(count - 1)
            let a = -Double.pi / 2 - spanA / 2 + u * spanA + rng.r(-0.06, 0.06)
            let len = radius * f * rng.r(0.86, 1.06)
            let outward = (a + Double.pi / 2) * 0.35
            let shade = tone.lt(Double(layer) * 0.09)
            let q = pt(Double(crown.x) + cos(a) * radius * 0.06, Double(crown.y) + sin(a) * radius * 0.06)
            if crinkle {
                crinkleLeaf(p, base: q, angle: a, length: len, width: len * 0.62, tone: shade, seed: seed &+ UInt64(layer * 31 + k * 7))
                _ = outward
            } else {
                blade(p, base: q, angle: a, length: len, width: len * 0.66, tone: shade, serrate: 0.1, curl: outward, veins: 4, seed: seed &+ UInt64(layer * 31 + k * 7))
            }
        }
    }
}

func produce(_ p: Leaf, _ ring: [CGPoint], tone: Hue, gloss: Double = 0.5, seed: UInt64) {
    wash(p, ring, tone, strength: 0.80, bleed: 3, seed: seed)
    let body = pathOf(ring)
    var cx = 0.0, cy = 0.0
    for q in ring { cx += Double(q.x); cy += Double(q.y) }
    cx /= Double(ring.count); cy /= Double(ring.count)
    let boxRect = body.boundingBox
    let rad = Double(max(boxRect.width, boxRect.height)) * 0.6
    let lx = cx + cos(p.light) * rad * 0.35, ly = cy + sin(p.light) * rad * 0.35
    p.radial(pt(lx, ly), rad, tone.lt(0.42 * gloss).al(0.9), tone.dk(0.30).al(0.25), clip: body)
    roundShade(p, ring, inset: rad * 0.45, depth: 2, spacing: max(2.4, rad * 0.06), colour: tone.dk(0.55), seed: seed &+ 7)
    p.inside(body) {
        p.egg(lx, ly, rad * 0.16, rad * 0.10, Pot.white.al(0.34 * gloss))
    }
    penOutline(p, ring, weight: max(1.2, rad * 0.030), colour: tone.dk(0.65), seed: seed &+ 29)
}

func fruitRound(_ p: Leaf, at c: CGPoint, r: Double, tone: Hue, rough: Double = 0.03, gloss: Double = 0.6, seed: UInt64) {
    produce(p, lumpy(cx: Double(c.x), cy: Double(c.y), rx: r, ry: r * 0.94, rough: rough, steps: 32, seed: seed), tone: tone, gloss: gloss, seed: seed)
}

func fruitLong(_ p: Leaf, from a: CGPoint, to b: CGPoint, width: Double, tone: Hue, taperEnd: Double = 0.7, gloss: Double = 0.5, seed: UInt64) {
    let ax = Double(a.x), ay = Double(a.y), bx = Double(b.x), by = Double(b.y)
    let midX = (ax + bx) / 2 + (by - ay) * 0.06
    let midY = (ay + by) / 2 - (bx - ax) * 0.06
    let spine = [a, pt(midX, midY), b]
    let ring = bandOf(spine, [width * 0.7, width, width * taperEnd], per: 10)
    produce(p, ring, tone: tone, gloss: gloss, seed: seed)
}

func podShape(_ p: Leaf, from a: CGPoint, to b: CGPoint, width: Double, tone: Hue, beads: Int, seed: UInt64) {
    let ax = Double(a.x), ay = Double(a.y), bx = Double(b.x), by = Double(b.y)
    let midX = (ax + bx) / 2 + (by - ay) * 0.12
    let midY = (ay + by) / 2 - (bx - ax) * 0.12
    let spine = [a, pt(midX, midY), b]
    let fine = resample(spine, count: beads * 4 + 2)
    var widths: [Double] = []
    for i in 0..<fine.count {
        let t = Double(i) / Double(fine.count - 1)
        let bead = 0.78 + 0.22 * abs(sin(t * Double(beads) * .pi))
        widths.append(width * bead * (t < 0.08 ? 0.5 : (t > 0.92 ? 0.55 : 1)))
    }
    let ring = bandOf(fine, widths, per: 2)
    produce(p, ring, tone: tone, gloss: 0.35, seed: seed)
    p.inside(pathOf(ring)) {
        pen(p, fine, weight: max(0.8, width * 0.08), colour: tone.dk(0.5).al(0.7), wobble: 0.3, taper: false, seed: seed &+ 5)
    }
}

func taproot(_ p: Leaf, top: CGPoint, length: Double, width: Double, tone: Hue, forked: Bool = false, rings: Bool = false, seed: UInt64) {
    var rng = Chip(seed)
    let spine = stemRun(top, .pi / 2, length, curve: rng.r(-0.15, 0.15), wobble: 0.02, steps: 10, seed: seed)
    let ring = bandOf(spine, [width, width * 0.92, width * 0.6, width * 0.22, width * 0.05], per: 5)
    produce(p, ring, tone: tone, gloss: 0.3, seed: seed)
    if rings {
        p.inside(pathOf(ring)) {
            let fine = resample(spine, count: 9)
            for k in 1..<8 {
                let q = fine[k]
                let t = Double(k) / 8
                let hw = width * (1 - t * 0.85) * 0.5
                pen(p, [pt(Double(q.x) - hw, Double(q.y)), pt(Double(q.x) + hw, Double(q.y) + 1)],
                    weight: max(0.6, width * 0.02), colour: tone.dk(0.45).al(0.6), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 7))
            }
        }
    }
    let fine = resample(spine, count: 12)
    for k in 2..<11 {
        guard rng.chance(0.7) else { continue }
        let q = fine[k]
        let side = rng.chance(0.5) ? -1.0 : 1.0
        let hair = stemRun(q, side > 0 ? 0.3 : .pi - 0.3, rng.r(width * 0.6, width * 1.6), curve: side * 0.6, wobble: 0.1, steps: 5, seed: seed &+ UInt64(k))
        pen(p, hair, weight: max(0.6, width * 0.03), colour: tone.dk(0.5).al(0.8), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 3 + 1))
    }
    if forked {
        let q = fine[6]
        let fork = stemRun(q, .pi / 2 + 0.5, length * 0.35, curve: 0.2, wobble: 0.05, steps: 6, seed: seed &+ 77)
        let ring2 = bandOf(fork, [width * 0.4, width * 0.2, width * 0.04], per: 5)
        produce(p, ring2, tone: tone, gloss: 0.3, seed: seed &+ 78)
    }
}

func bulb(_ p: Leaf, at c: CGPoint, rx: Double, ry: Double, tone: Hue, striate: Int = 7, neck: Double = 0.35, seed: UInt64) {
    var ring: [CGPoint] = []
    for i in 0..<36 {
        let a = Double(i) / 36 * 2 * .pi
        var r = 1.0
        if sin(a) < 0 { r = 1 - neck * pow(-sin(a), 2.2) }
        ring.append(pt(Double(c.x) + cos(a) * rx * r, Double(c.y) + sin(a) * ry * (sin(a) < 0 ? 1.05 : 1)))
    }
    produce(p, ring, tone: tone, gloss: 0.4, seed: seed)
    p.inside(pathOf(ring)) {
        for k in 0..<striate {
            let f = (Double(k) + 0.5) / Double(striate) * 2 - 1
            let x = Double(c.x) + f * rx * 0.85
            let curveOff = f * rx * 0.25
            pen(p, [pt(x + curveOff * 0.5, Double(c.y) - ry * 0.85), pt(x, Double(c.y)), pt(x - curveOff * 0.3, Double(c.y) + ry * 0.9)],
                weight: max(0.7, rx * 0.025), colour: tone.dk(0.42).al(0.65), wobble: 0.5, taper: true, seed: seed &+ UInt64(k * 5 + 3))
        }
    }
    var rng = Chip(seed &+ 9)
    for k in 0..<9 {
        let x = Double(c.x) + rng.r(-rx * 0.5, rx * 0.5)
        let root = stemRun(pt(x, Double(c.y) + ry * 0.95), .pi / 2 + rng.r(-0.6, 0.6), rng.r(ry * 0.25, ry * 0.6), curve: rng.r(-0.5, 0.5), wobble: 0.1, steps: 5, seed: seed &+ UInt64(k * 3))
        pen(p, root, weight: max(0.6, rx * 0.03), colour: Pot.strawPale.dk(0.35), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 11))
    }
}

func daisy(_ p: Leaf, at c: CGPoint, r: Double, petals: Int, petalTone: Hue, centreTone: Hue, petalWidth: Double = 0.36, seed: UInt64) {
    var rng = Chip(seed)
    let phase = rng.r(0, 1)
    for k in 0..<petals {
        let a = phase + Double(k) / Double(petals) * 2 * .pi
        let q = pt(Double(c.x) + cos(a) * r * 0.28, Double(c.y) + sin(a) * r * 0.28)
        blade(p, base: q, angle: a, length: r * 0.78, width: r * petalWidth, tone: k % 2 == 0 ? petalTone : petalTone.lt(0.08), serrate: 0, curl: rng.r(-0.1, 0.1), veins: 1, seed: seed &+ UInt64(k * 13 + 1))
    }
    let disc = lumpy(cx: Double(c.x), cy: Double(c.y), rx: r * 0.32, ry: r * 0.30, rough: 0.05, steps: 24, seed: seed &+ 5)
    produce(p, disc, tone: centreTone, gloss: 0.2, seed: seed &+ 6)
    p.inside(pathOf(disc)) {
        for _ in 0..<Int(r * 0.6) {
            p.dot(Double(c.x) + rng.signed() * r * 0.28, Double(c.y) + rng.signed() * r * 0.26, rng.r(0.6, 1.6), centreTone.dk(0.5).al(0.6))
        }
    }
}

func umbel(_ p: Leaf, top: CGPoint, spread: Double, tone: Hue, rays: Int = 9, seed: UInt64) {
    var rng = Chip(seed)
    for k in 0..<rays {
        let a = -Double.pi / 2 + (Double(k) / Double(rays - 1) - 0.5) * 2.4
        let tip = pt(Double(top.x) + cos(a) * spread, Double(top.y) + sin(a) * spread * 0.55)
        pen(p, [top, tip], weight: max(0.7, spread * 0.018), colour: Pot.leaf.dk(0.3), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 7))
        for j in 0..<6 {
            let b = a + (Double(j) / 5 - 0.5) * 1.2
            let q = pt(Double(tip.x) + cos(b) * spread * 0.16, Double(tip.y) + sin(b) * spread * 0.10)
            pen(p, [tip, q], weight: max(0.5, spread * 0.012), colour: Pot.leaf.dk(0.2), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 11 + j))
            p.dot(Double(q.x), Double(q.y), spread * rng.r(0.018, 0.03), tone)
            p.dot(Double(q.x) + 1, Double(q.y) - 1, spread * 0.010, tone.lt(0.5).al(0.8))
        }
    }
}

func seedVignette(_ p: Leaf, at c: CGPoint, kind: String, tone: Hue, seed: UInt64) {
    var rng = Chip(seed)
    let s = 30.0
    switch kind {
    case "bean":
        let ring = lumpy(cx: Double(c.x), cy: Double(c.y), rx: s * 0.9, ry: s * 0.55, rough: 0.04, steps: 26, seed: seed)
        produce(p, ring, tone: tone, gloss: 0.5, seed: seed)
        pen(p, [pt(Double(c.x) - s * 0.3, Double(c.y) - s * 0.1), pt(Double(c.x) + s * 0.3, Double(c.y) - s * 0.12)], weight: 2.2, colour: Pot.white.al(0.8), wobble: 0.3, taper: true, seed: seed &+ 3)
    case "pea":
        for k in 0..<3 {
            let q = pt(Double(c.x) + Double(k - 1) * s * 0.9, Double(c.y) + (k == 1 ? -s * 0.3 : s * 0.2))
            fruitRound(p, at: q, r: s * 0.42, tone: tone, rough: 0.05, gloss: 0.4, seed: seed &+ UInt64(k))
        }
    case "flat":
        for k in 0..<3 {
            let q = pt(Double(c.x) + Double(k - 1) * s * 0.85, Double(c.y) + Double(k % 2) * s * 0.3)
            let ring = lumpy(cx: Double(q.x), cy: Double(q.y), rx: s * 0.42, ry: s * 0.28, rough: 0.06, steps: 20, seed: seed &+ UInt64(k))
            produce(p, ring, tone: tone, gloss: 0.2, seed: seed &+ UInt64(k * 3))
        }
    case "disc":
        for k in 0..<3 {
            let q = pt(Double(c.x) + Double(k - 1) * s * 0.85, Double(c.y) + Double(k % 2) * s * 0.3)
            let ring = lumpy(cx: Double(q.x), cy: Double(q.y), rx: s * 0.36, ry: s * 0.36, rough: 0.03, steps: 20, seed: seed &+ UInt64(k))
            produce(p, ring, tone: tone, gloss: 0.15, seed: seed &+ UInt64(k * 3))
            p.hoop(Double(q.x), Double(q.y), s * 0.22, 1.2, tone.dk(0.5).al(0.6))
        }
    case "clove":
        let ring = [pt(Double(c.x) - s * 0.5, Double(c.y) + s * 0.6), pt(Double(c.x) - s * 0.62, Double(c.y)), pt(Double(c.x) - s * 0.2, Double(c.y) - s * 0.8), pt(Double(c.x) + s * 0.15, Double(c.y) - s * 0.85), pt(Double(c.x) + s * 0.6, Double(c.y) - s * 0.1), pt(Double(c.x) + s * 0.5, Double(c.y) + s * 0.6)]
        produce(p, resample(ring + [ring[0]], count: 30), tone: tone, gloss: 0.3, seed: seed)
    case "tuber":
        let ring = lumpy(cx: Double(c.x), cy: Double(c.y), rx: s * 0.95, ry: s * 0.6, rough: 0.08, steps: 26, seed: seed)
        produce(p, ring, tone: tone, gloss: 0.2, seed: seed)
        for k in 0..<3 {
            let q = pt(Double(c.x) + rng.r(-s * 0.6, s * 0.6), Double(c.y) + rng.r(-s * 0.3, s * 0.3))
            pen(p, [q, pt(Double(q.x) + rng.r(-6, 6), Double(q.y) - rng.r(8, 16))], weight: 2.0, colour: Pot.leafPale.dk(0.2), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 5 + 40))
        }
    case "crown":
        pen(p, [pt(Double(c.x) - s * 0.9, Double(c.y)), pt(Double(c.x) + s * 0.9, Double(c.y))], weight: 3.0, colour: Pot.sepia, wobble: 0.5, taper: true, seed: seed)
        for k in 0..<7 {
            let x = Double(c.x) - s * 0.8 + Double(k) * s * 0.27
            pen(p, [pt(x, Double(c.y)), pt(x + rng.r(-6, 6), Double(c.y) + rng.r(14, 30))], weight: 1.6, colour: Pot.sepia.al(0.85), wobble: 0.5, taper: true, seed: seed &+ UInt64(k * 3))
        }
        for k in 0..<3 {
            let x = Double(c.x) - s * 0.3 + Double(k) * s * 0.3
            pen(p, [pt(x, Double(c.y)), pt(x + rng.r(-4, 4), Double(c.y) - rng.r(10, 18))], weight: 2.4, colour: Pot.terracotta.dk(0.2), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 3 + 50))
        }
    case "slip":
        pen(p, [pt(Double(c.x), Double(c.y) + s * 0.7), pt(Double(c.x) + 4, Double(c.y) - s * 0.5)], weight: 3.0, colour: Pot.leaf.dk(0.3), wobble: 0.4, taper: true, seed: seed)
        heartLeaf(p, at: pt(Double(c.x) + 10, Double(c.y) - s * 0.5), angle: -1.2, size: s * 0.36, tone: Pot.leaf, lobes: 3, seed: seed &+ 3)
        for k in 0..<4 {
            pen(p, [pt(Double(c.x), Double(c.y) + s * 0.6), pt(Double(c.x) + rng.r(-14, 14), Double(c.y) + s * 0.9 + rng.r(0, 8))], weight: 1.2, colour: Pot.strawPale.dk(0.4), wobble: 0.4, taper: true, seed: seed &+ UInt64(k + 20))
        }
    default:
        for k in 0..<7 {
            let q = pt(Double(c.x) + rng.r(-s * 0.9, s * 0.9), Double(c.y) + rng.r(-s * 0.35, s * 0.35))
            let ring = lumpy(cx: Double(q.x), cy: Double(q.y), rx: s * 0.13, ry: s * 0.09, rough: 0.1, steps: 12, seed: seed &+ UInt64(k))
            p.shape(ring, tone.dk(Double(k % 3) * 0.1))
            penOutline(p, ring, weight: 0.9, colour: tone.dk(0.6), seed: seed &+ UInt64(k * 3))
        }
    }
}

func seedlingVignette(_ p: Leaf, at base: CGPoint, tone: Hue, monocot: Bool, seed: UInt64) {
    let h = 46.0
    if monocot {
        for k in 0..<3 {
            let a = -Double.pi / 2 + Double(k - 1) * 0.35
            strapLeaf(p, base: base, angle: a, length: h * (k == 1 ? 1.1 : 0.85), width: 7, tone: tone, curve: Double(k - 1) * 0.3, seed: seed &+ UInt64(k * 5))
        }
    } else {
        let spine = stemRun(base, -Double.pi / 2 + 0.1, h * 0.7, curve: -0.2, wobble: 0.02, steps: 6, seed: seed)
        stem(p, spine, w0: 5, w1: 3.5, tone: Pot.leafPale.dk(0.1), seed: seed &+ 1)
        let top = spine[spine.count - 1]
        blade(p, base: top, angle: -2.5, length: h * 0.55, width: h * 0.34, tone: tone, serrate: 0, curl: -0.2, veins: 2, seed: seed &+ 3)
        blade(p, base: top, angle: -0.6, length: h * 0.55, width: h * 0.34, tone: tone.lt(0.08), serrate: 0, curl: 0.2, veins: 2, seed: seed &+ 4)
        blade(p, base: pt(Double(top.x) + 2, Double(top.y) + 2), angle: -1.55, length: h * 0.36, width: h * 0.16, tone: tone.dk(0.1), serrate: 0.2, curl: 0, veins: 2, seed: seed &+ 5)
    }
    var rng = Chip(seed &+ 9)
    for k in 0..<5 {
        let root = stemRun(base, .pi / 2 + rng.r(-0.7, 0.7), rng.r(10, 26), curve: rng.r(-0.5, 0.5), wobble: 0.15, steps: 5, seed: seed &+ UInt64(k * 3 + 30))
        pen(p, root, weight: 1.1, colour: Pot.strawPale.dk(0.45), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 11 + 31))
    }
}
