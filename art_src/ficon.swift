import Foundation
import CoreGraphics

func runsFacing(_ ring: [CGPoint], light: Double, lit: Bool) -> [[CGPoint]] {
    guard ring.count > 4 else { return [] }
    var keep = [Bool](repeating: false, count: ring.count)
    for i in 0..<ring.count {
        let a = ring[i], b = ring[(i + 1) % ring.count]
        let ang = atan2(Double(b.y - a.y), Double(b.x - a.x))
        let facing = cos(ang + .pi / 2 - light)
        keep[i] = lit ? (facing > 0.12) : (facing < -0.12)
    }
    var runs: [[CGPoint]] = []
    var current: [CGPoint] = []
    for i in 0..<ring.count {
        if keep[i] {
            if current.isEmpty { current.append(ring[i]) }
            current.append(ring[(i + 1) % ring.count])
        } else if !current.isEmpty {
            runs.append(current); current = []
        }
    }
    if !current.isEmpty {
        if !runs.isEmpty && keep[0] { runs[0] = current + runs[0] } else { runs.append(current) }
    }
    return runs.filter { $0.count > 1 }
}

func fillRing(_ p: Leaf, _ ring: [CGPoint], _ colour: Hue) { p.shape(ring, colour) }

func grainStrokes(_ p: Leaf, _ clip: CGPath, count: Int, angle: Double, light: Hue, dark: Hue, length: ClosedRange<Double>, seed: UInt64) {
    var rng = Chip(seed)
    let box = clip.boundingBox
    p.inside(clip) {
        for _ in 0..<count {
            let x = Double(box.minX) + rng.d() * Double(box.width)
            let y = Double(box.minY) + rng.d() * Double(box.height)
            let a = angle + rng.signed() * 0.25
            let len = rng.r(length.lowerBound, length.upperBound)
            let tone = rng.chance(0.5) ? light.al(light.a * rng.r(0.4, 1.0)) : dark.al(dark.a * rng.r(0.4, 1.0))
            p.ctx.setStrokeColor(cg(tone))
            p.ctx.setLineWidth(rng.r(0.6, 1.6))
            p.ctx.beginPath()
            p.ctx.move(to: pt(x, y))
            p.ctx.addLine(to: pt(x + cos(a) * len, y + sin(a) * len))
            p.ctx.strokePath()
        }
    }
}

func iconLeaf(_ p: Leaf, at c: CGPoint, angle: Double, size: Double, seed: UInt64) {
    var rng = Chip(seed)
    var ring: [CGPoint] = []
    let steps = 72
    for i in 0..<steps {
        let t = Double(i) / Double(steps) * 2 * Double.pi
        let hx = 16 * pow(sin(t), 3)
        let hy = 13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t)
        let lx = -hy / 17 * size
        let ly = hx / 17 * size * 0.9
        ring.append(pt(Double(c.x) + cos(angle) * lx - sin(angle) * ly, Double(c.y) + sin(angle) * lx + cos(angle) * ly))
    }
    let path = pathOf(ring)
    var slide = CGAffineTransform(translationX: 16, y: 20)
    if let cast = path.copy(using: &slide) {
        p.ctx.setFillColor(cg(Hue(r: 0.03, g: 0.03, b: 0.02, a: 0.55)))
        p.ctx.beginPath(); p.ctx.addPath(cast); p.ctx.fillPath()
    }
    fillRing(p, ring, Hue(r: 0.22, g: 0.36, b: 0.16))
    let lx = Double(c.x) + cos(p.light) * size * 0.4, ly = Double(c.y) + sin(p.light) * size * 0.4
    p.radial(pt(lx, ly), size * 1.5, Hue(r: 0.55, g: 0.72, b: 0.36), Hue(r: 0.16, g: 0.28, b: 0.12), clip: path)
    grainStrokes(p, path, count: 900, angle: angle + 0.3, light: Hue(r: 0.85, g: 0.95, b: 0.65, a: 0.10), dark: Hue(r: 0.05, g: 0.12, b: 0.03, a: 0.14), length: 4...14, seed: seed &+ 5)
    let tip = pt(Double(c.x) + cos(angle) * size * 0.98, Double(c.y) + sin(angle) * size * 0.98)
    let stemEnd = pt(Double(c.x) - cos(angle) * size * 0.62, Double(c.y) - sin(angle) * size * 0.62)
    p.inside(path) {
        pen(p, [stemEnd, c, tip], weight: 4.5, colour: Hue(r: 0.10, g: 0.20, b: 0.08, a: 0.75), wobble: 0.4, taper: true, seed: seed &+ 11)
        pen(p, offsetRing([stemEnd, c, tip], -2.5, -2.5), weight: 2.2, colour: Hue(r: 0.80, g: 0.92, b: 0.62, a: 0.45), wobble: 0.3, taper: true, seed: seed &+ 12)
        for k in 1..<6 {
            let t = Double(k) / 6
            let q = pt(Double(stemEnd.x) + (Double(tip.x) - Double(stemEnd.x)) * t, Double(stemEnd.y) + (Double(tip.y) - Double(stemEnd.y)) * t)
            for side in [-1.0, 1.0] {
                let e = pt(Double(q.x) + cos(angle + side * 1.0) * size * 0.5, Double(q.y) + sin(angle + side * 1.0) * size * 0.4)
                pen(p, [q, e], weight: 2.6, colour: Hue(r: 0.10, g: 0.20, b: 0.08, a: 0.5), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 3 + Int(side + 2) + 20))
                pen(p, offsetRing([q, e], -1.8, -1.8), weight: 1.4, colour: Hue(r: 0.80, g: 0.92, b: 0.62, a: 0.32), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 3 + Int(side + 2) + 30))
            }
        }
    }
    for run in runsFacing(ring, light: p.light, lit: true) {
        pen(p, offsetRing(run, -2, -2), weight: 5.0, colour: Hue(r: 0.88, g: 0.96, b: 0.70, a: 0.75), wobble: 0.5, taper: false, seed: rng.next())
    }
    for run in runsFacing(ring, light: p.light, lit: false) {
        pen(p, offsetRing(run, 2, 2), weight: 5.5, colour: Hue(r: 0.04, g: 0.08, b: 0.03, a: 0.7), wobble: 0.5, taper: false, seed: rng.next())
    }
    penOutline(p, ring, weight: 2.4, colour: Hue(r: 0.08, g: 0.14, b: 0.06, a: 0.85), seed: rng.next())
}

func drawIcon(_ dir: String) {
    let previous = sheetScale
    sheetScale = 1.0
    let p = Leaf(1024, 1024)
    p.fillAll(Hue(r: 0.09, g: 0.07, b: 0.05))
    p.flipDown()
    p.light = -2.36
    var rng = Chip(hashOf("lastfrost-icon"))

    let ground = CGMutablePath()
    ground.addRect(CGRect(x: 0, y: 0, width: 1024, height: 1024))
    p.radial(pt(260, 220), 1100, Hue(r: 0.30, g: 0.24, b: 0.16), Hue(r: 0.06, g: 0.05, b: 0.04), clip: ground)

    let soilTop = 660.0
    var soilRing: [CGPoint] = [pt(-20, 1044), pt(-20, soilTop + 30)]
    var x = -20.0
    while x < 1044 {
        soilRing.append(pt(x, soilTop + rng.r(-14, 14)))
        x += rng.r(40, 80)
    }
    soilRing.append(pt(1044, soilTop + 10))
    soilRing.append(pt(1044, 1044))
    let soilPath = pathOf(soilRing)
    fillRing(p, soilRing, Hue(r: 0.20, g: 0.14, b: 0.09))
    p.radial(pt(300, soilTop + 40), 900, Hue(r: 0.36, g: 0.26, b: 0.17), Hue(r: 0.10, g: 0.07, b: 0.05), clip: soilPath)
    p.inside(soilPath) {
        for _ in 0..<2600 {
            let cx = rng.r(0, 1024), cy = rng.r(soilTop - 14, 1024)
            let r = rng.r(1.5, 7)
            let clod = lumpy(cx: cx, cy: cy, rx: r, ry: r * 0.7, rough: 0.2, steps: 8, seed: rng.next())
            p.shape(clod, rng.chance(0.55) ? Hue(r: 0.05, g: 0.03, b: 0.02, a: rng.r(0.2, 0.6)) : Hue(r: 0.55, g: 0.42, b: 0.28, a: rng.r(0.08, 0.30)))
        }
        for _ in 0..<160 {
            let cx = rng.r(0, 1024), cy = rng.r(soilTop - 10, 1024)
            let r = rng.r(6, 16)
            let clod = lumpy(cx: cx, cy: cy, rx: r, ry: r * 0.65, rough: 0.25, steps: 10, seed: rng.next())
            p.shape(clod, Hue(r: 0.16, g: 0.11, b: 0.07, a: 0.8))
            for run in runsFacing(clod, light: p.light, lit: true) {
                pen(p, run, weight: 1.6, colour: Hue(r: 0.70, g: 0.56, b: 0.38, a: 0.35), wobble: 0.3, taper: false, seed: rng.next())
            }
        }
    }
    for run in runsFacing(soilRing, light: p.light, lit: true) where run.count > 1 {
        pen(p, run, weight: 3.0, colour: Hue(r: 0.62, g: 0.50, b: 0.34, a: 0.30), wobble: 0.8, taper: false, seed: rng.next())
    }

    let a = pt(250, -120), b = pt(1150, -30), c = pt(1105, 700), d = pt(320, 640)
    let face = [a, b, c, d]
    let depthX = 44.0, depthY = 30.0
    let sideRight = [b, pt(Double(b.x) + depthX, Double(b.y) + depthY), pt(Double(c.x) + depthX, Double(c.y) + depthY), c]
    let sideBottom = [d, c, pt(Double(c.x) + depthX, Double(c.y) + depthY), pt(Double(d.x) + depthX, Double(d.y) + depthY)]
    for k in stride(from: 8, through: 1, by: -1) {
        let spread = Double(k) * 9.0
        fillRing(p, offsetRing(face, 40 + spread * 0.6, 46 + spread * 0.7), Hue(r: 0.02, g: 0.015, b: 0.01, a: 0.09))
    }
    fillRing(p, sideBottom, Hue(r: 0.42, g: 0.36, b: 0.27))
    fillRing(p, sideRight, Hue(r: 0.52, g: 0.45, b: 0.34))
    grainStrokes(p, pathOf(sideRight), count: 400, angle: Double.pi / 2 + 0.06, light: Hue(r: 0.9, g: 0.85, b: 0.7, a: 0.08), dark: Hue(r: 0.1, g: 0.08, b: 0.05, a: 0.16), length: 6...24, seed: rng.next())
    let facePath = pathOf(face)
    fillRing(p, face, Pot.creamWarm.lt(0.15))
    p.radial(pt(330, 60), 1200, Hue(r: 0.99, g: 0.96, b: 0.90), Hue(r: 0.70, g: 0.62, b: 0.48), clip: facePath)
    grainStrokes(p, facePath, count: 5200, angle: 0.08, light: Hue(r: 1.0, g: 0.98, b: 0.92, a: 0.10), dark: Hue(r: 0.30, g: 0.22, b: 0.12, a: 0.07), length: 5...22, seed: rng.next())
    var creases = Chip(rng.next())
    for _ in 0..<40 {
        let sx = creases.r(280, 1060), sy = creases.r(-100, 640)
        let ang = creases.r(-0.5, 0.5) + (creases.chance(0.5) ? 0 : Double.pi / 2)
        let len = creases.r(20, 90)
        p.inside(facePath) {
            pen(p, [pt(sx, sy), pt(sx + cos(ang) * len, sy + sin(ang) * len)], weight: 1.6, colour: Hue(r: 0.35, g: 0.28, b: 0.18, a: 0.16), wobble: 0.4, taper: true, seed: creases.next())
            pen(p, [pt(sx - 1.5, sy - 1.5), pt(sx + cos(ang) * len - 1.5, sy + sin(ang) * len - 1.5)], weight: 1.0, colour: Hue(r: 1.0, g: 1.0, b: 0.95, a: 0.28), wobble: 0.3, taper: true, seed: creases.next())
        }
    }

    func onFace(_ u: Double, _ v: Double) -> CGPoint {
        let topX = Double(a.x) + (Double(b.x) - Double(a.x)) * u
        let topY = Double(a.y) + (Double(b.y) - Double(a.y)) * u
        let lowX = Double(d.x) + (Double(c.x) - Double(d.x)) * u
        let lowY = Double(d.y) + (Double(c.y) - Double(d.y)) * u
        return pt(topX + (lowX - topX) * v, topY + (lowY - topY) * v)
    }
    let band = [onFace(0.0, 0.30), onFace(1.0, 0.30), onFace(1.0, 0.44), onFace(0.0, 0.44)]
    p.inside(facePath) {
        fillRing(p, band, Pot.terracotta.dk(0.08))
        p.radial(pt(400, 100), 1000, Pot.terracotta.lt(0.25), Pot.terraDeep.dk(0.25), clip: pathOf(band))
        grainStrokes(p, pathOf(band), count: 1200, angle: 0.08, light: Hue(r: 1.0, g: 0.85, b: 0.70, a: 0.12), dark: Hue(r: 0.25, g: 0.08, b: 0.02, a: 0.14), length: 5...20, seed: rng.next())
        let frame = [onFace(0.07, 0.08), onFace(0.93, 0.08), onFace(0.93, 0.92), onFace(0.07, 0.92)]
        penEdge(p, frame, weight: 6, colour: Pot.leafDeep.dk(0.2).al(0.85), seed: rng.next())
        penEdge(p, offsetRing(frame, -2.5, -2.5), weight: 2, colour: Hue(r: 1.0, g: 1.0, b: 0.9, a: 0.35), seed: rng.next())
        let inner = [onFace(0.10, 0.11), onFace(0.90, 0.11), onFace(0.90, 0.89), onFace(0.10, 0.89)]
        penEdge(p, inner, weight: 2.2, colour: Pot.leafDeep.al(0.6), seed: rng.next())
        for k in 0..<6 {
            let u = 0.12 + Double(k) * 0.15
            let q = onFace(u, 0.37)
            let leafRing = bladeRing(base: pt(Double(q.x) - 22, Double(q.y) + 6), angle: -0.3, length: 46, width: 22, curl: 0.1, serrate: 0, steps: 14, seed: rng.next())
            p.shape(leafRing, Pot.creamWarm.al(0.92))
            penOutline(p, leafRing, weight: 1.4, colour: Pot.terraDeep.dk(0.3).al(0.8), seed: rng.next())
        }
        let emblemC = onFace(0.70, 0.64)
        let emblem = lobedRing(at: emblemC, angle: -0.9, size: 130, lobes: 3, depth: 0.2, aspect: 1.1, seed: rng.next())
        fillRing(p, emblem, Pot.leaf.dk(0.05))
        p.radial(pt(Double(emblemC.x) - 60, Double(emblemC.y) - 60), 320, Pot.leafPale, Pot.leafDeep.dk(0.2), clip: pathOf(emblem))
        grainStrokes(p, pathOf(emblem), count: 700, angle: -0.9, light: Hue(r: 0.9, g: 0.98, b: 0.7, a: 0.12), dark: Hue(r: 0.05, g: 0.12, b: 0.02, a: 0.14), length: 4...14, seed: rng.next())
        penOutline(p, emblem, weight: 3, colour: Pot.leafDeep.dk(0.4).al(0.9), seed: rng.next())
        pen(p, [pt(Double(emblemC.x) - 110, Double(emblemC.y) + 86), emblemC, pt(Double(emblemC.x) + 96, Double(emblemC.y) - 78)], weight: 4, colour: Pot.leafDeep.dk(0.4).al(0.8), wobble: 0.4, taper: true, seed: rng.next())
    }
    for run in runsFacing(face, light: p.light, lit: true) {
        pen(p, run, weight: 9.0, colour: Hue(r: 1.0, g: 0.98, b: 0.92, a: 0.9), wobble: 0.7, taper: false, seed: rng.next())
        pen(p, offsetRing(run, 5, 5), weight: 3.0, colour: Hue(r: 1.0, g: 0.96, b: 0.85, a: 0.35), wobble: 0.5, taper: false, seed: rng.next())
    }
    for run in runsFacing(face, light: p.light, lit: false) {
        pen(p, run, weight: 7.0, colour: Hue(r: 0.18, g: 0.12, b: 0.06, a: 0.85), wobble: 0.7, taper: false, seed: rng.next())
    }
    penEdge(p, sideRight, weight: 3, colour: Hue(r: 0.12, g: 0.08, b: 0.04, a: 0.8), seed: rng.next())

    let packetShadow = [pt(330, 650), pt(1120, 712), pt(1060, 790), pt(360, 730)]
    p.inside(soilPath) {
        fillRing(p, packetShadow, Hue(r: 0.02, g: 0.015, b: 0.01, a: 0.55))
    }

    let stemBase = pt(500, 800)
    let stemSpine = stemRun(stemBase, -Double.pi / 2 + 0.25, 330, curve: -0.9, wobble: 0.01, steps: 12, seed: 77)
    let stemRing = bandOf(stemSpine, [46, 40, 32, 26], per: 6)
    fillRing(p, offsetRing(stemRing, 14, 16), Hue(r: 0.02, g: 0.015, b: 0.01, a: 0.45))
    fillRing(p, stemRing, Hue(r: 0.55, g: 0.68, b: 0.38))
    p.radial(pt(420, 620), 500, Hue(r: 0.78, g: 0.86, b: 0.56), Hue(r: 0.30, g: 0.42, b: 0.20), clip: pathOf(stemRing))
    grainStrokes(p, pathOf(stemRing), count: 700, angle: -Double.pi / 2 + 0.2, light: Hue(r: 0.95, g: 1.0, b: 0.8, a: 0.14), dark: Hue(r: 0.1, g: 0.2, b: 0.05, a: 0.18), length: 6...26, seed: rng.next())
    for run in runsFacing(stemRing, light: p.light, lit: true) {
        pen(p, offsetRing(run, -2, -2), weight: 4.5, colour: Hue(r: 0.95, g: 1.0, b: 0.85, a: 0.8), wobble: 0.4, taper: false, seed: rng.next())
    }
    for run in runsFacing(stemRing, light: p.light, lit: false) {
        pen(p, offsetRing(run, 2, 2), weight: 5.0, colour: Hue(r: 0.05, g: 0.10, b: 0.03, a: 0.7), wobble: 0.4, taper: false, seed: rng.next())
    }
    penOutline(p, stemRing, weight: 2.4, colour: Hue(r: 0.10, g: 0.16, b: 0.06, a: 0.85), seed: rng.next())
    let top = stemSpine[stemSpine.count - 1]
    let seedCoat = lumpy(cx: Double(top.x) + 6, cy: Double(top.y) + 10, rx: 34, ry: 22, rough: 0.05, steps: 24, seed: 91)
    fillRing(p, seedCoat, Hue(r: 0.40, g: 0.22, b: 0.14))
    p.radial(pt(Double(top.x) - 10, Double(top.y) - 4), 70, Hue(r: 0.62, g: 0.36, b: 0.24), Hue(r: 0.22, g: 0.10, b: 0.06), clip: pathOf(seedCoat))
    penOutline(p, seedCoat, weight: 2, colour: Hue(r: 0.12, g: 0.06, b: 0.03, a: 0.9), seed: rng.next())
    let leafA = -2.95, leafB = -0.25
    let sizeA = 178.0, sizeB = 184.0
    pen(p, [pt(Double(top.x) + 2, Double(top.y) + 4), pt(Double(top.x) + cos(leafA) * 46, Double(top.y) + sin(leafA) * 46)], weight: 12, colour: Hue(r: 0.45, g: 0.60, b: 0.32), wobble: 0.3, taper: false, seed: 103)
    pen(p, [pt(Double(top.x) + 2, Double(top.y) + 4), pt(Double(top.x) + cos(leafB) * 46, Double(top.y) + sin(leafB) * 46)], weight: 12, colour: Hue(r: 0.45, g: 0.60, b: 0.32), wobble: 0.3, taper: false, seed: 104)
    iconLeaf(p, at: pt(Double(top.x) + cos(leafA) * (40 + sizeA * 0.30), Double(top.y) + sin(leafA) * (40 + sizeA * 0.30)), angle: leafA, size: sizeA, seed: 101)
    iconLeaf(p, at: pt(Double(top.x) + cos(leafB) * (40 + sizeB * 0.30), Double(top.y) + sin(leafB) * (40 + sizeB * 0.30)), angle: leafB, size: sizeB, seed: 102)
    p.inside(soilPath) {
        fillRing(p, lumpy(cx: Double(stemBase.x) + 10, cy: Double(stemBase.y) + 6, rx: 70, ry: 18, rough: 0.2, steps: 20, seed: 111), Hue(r: 0.02, g: 0.015, b: 0.01, a: 0.5))
    }
    p.radial(pt(150, 100), 800, Hue(r: 1, g: 0.95, b: 0.82, a: 0.12), Hue(r: 1, g: 0.95, b: 0.82, a: 0.0), clip: ground)
    p.writePNG(dir, "AppIcon-1024")
    sheetScale = previous
}
