import Foundation
import CoreGraphics

struct Ray3 {
    var x: Double
    var y: Double
    var z: Double
    init(_ x: Double, _ y: Double, _ z: Double) {
        let l = (x * x + y * y + z * z).squareRoot()
        self.x = x / l; self.y = y / l; self.z = z / l
    }
}

let keyRay = Ray3(-0.62, -0.60, 0.50)
let fillRay = Ray3(0.55, 0.66, 0.50)
let halfRay = Ray3(-0.62, -0.60, 1.50)

struct RimRun {
    var pts: [CGPoint]
    var power: [Double]
}

func smoothStep(_ v: Double) -> Double {
    let t = max(0.0, min(1.0, v))
    return t * t * (3 - 2 * t)
}

func denseRing(_ ring: [CGPoint], every: Double = 4.0) -> [CGPoint] {
    guard ring.count > 2 else { return ring }
    var total = 0.0
    for i in 0..<ring.count {
        let a = ring[i], b = ring[(i + 1) % ring.count]
        total += hypot(Double(b.x - a.x), Double(b.y - a.y))
    }
    let n = max(24, Int(total / every))
    let closed = resample(ring + [ring[0]], count: n + 1)
    return Array(closed.dropLast())
}

func rimRuns(_ ring: [CGPoint], lx: Double, ly: Double, enter: Double = 0.34, leave: Double = 0.08,
             window: Int = 9, bridge: Int = 10, minRun: Int = 12) -> [RimRun] {
    let pts = denseRing(ring)
    let n = pts.count
    guard n > 8 else { return [] }
    var twice = 0.0
    for i in 0..<n {
        let a = pts[i], b = pts[(i + 1) % n]
        twice += Double(a.x) * Double(b.y) - Double(b.x) * Double(a.y)
    }
    let turn: Double = twice > 0 ? -(.pi / 2) : (.pi / 2)
    var nx = [Double](repeating: 0, count: n)
    var ny = [Double](repeating: 0, count: n)
    var raw = [Double](repeating: 0, count: n)
    var carry = 0.0
    for i in 0..<n {
        let a = pts[(i + n - 2) % n], b = pts[(i + 2) % n]
        let dx = Double(b.x - a.x), dy = Double(b.y - a.y)
        if dx * dx + dy * dy > 1e-9 { carry = atan2(dy, dx) }
        nx[i] = cos(carry + turn)
        ny[i] = sin(carry + turn)
        raw[i] = nx[i] * lx + ny[i] * ly
    }
    var facing = [Double](repeating: 0, count: n)
    let half = max(1, min(window / 2, n / 3))
    for i in 0..<n {
        var acc = 0.0, mass = 0.0
        for k in -half...half {
            let w = 1.0 - Double(abs(k)) / Double(half + 1)
            acc += raw[(i + k + n) % n] * w
            mass += w
        }
        facing[i] = acc / mass
    }
    var lowest = 0
    var peak = facing[0]
    for i in 1..<n {
        if facing[i] < facing[lowest] { lowest = i }
        if facing[i] > peak { peak = facing[i] }
    }
    var lit = [Bool](repeating: false, count: n)
    var on = facing[lowest] > enter
    for k in 0..<n {
        let i = (lowest + k) % n
        if on { if facing[i] < leave { on = false } } else if facing[i] > enter { on = true }
        lit[i] = on
    }
    guard lit.contains(true) else { return [] }
    if lit.contains(false) {
        var fill: [Int] = []
        for i in 0..<n where !lit[i] && lit[(i + n - 1) % n] {
            var len = 0
            while len < n && !lit[(i + len) % n] { len += 1 }
            if len <= bridge { for k in 0..<len { fill.append((i + k) % n) } }
        }
        for i in fill { lit[i] = true }
    }
    var runs: [(Int, Int)] = []
    if lit.contains(false) {
        for i in 0..<n where lit[i] && !lit[(i + n - 1) % n] {
            var len = 0
            while len < n && lit[(i + len) % n] { len += 1 }
            runs.append((i, len))
        }
    } else {
        runs = [(0, n)]
    }
    let spread = max(0.12, peak - leave)
    var out: [RimRun] = []
    for (start, len) in runs where len >= minRun {
        var line: [CGPoint] = []
        var power: [Double] = []
        for k in 0..<len {
            let i = (start + k) % n
            line.append(pts[i])
            power.append(smoothStep((facing[i] - leave) / spread))
        }
        out.append(RimRun(pts: line, power: power))
    }
    return out
}

func rimStroke(_ p: Leaf, _ run: RimRun, weight: Double, colour: Hue, inset: Double = 0, seed: UInt64) {
    let n = run.pts.count
    guard n > 2, weight > 0 else { return }
    var rng = Chip(seed)
    let f1 = rng.r(1.2, 2.6), ph1 = rng.r(0, 6.28)
    var left: [CGPoint] = []
    var right: [CGPoint] = []
    for i in 0..<n {
        let t = Double(i) / Double(n - 1)
        let a = run.pts[max(0, i - 1)], b = run.pts[min(n - 1, i + 1)]
        var tx = Double(b.x - a.x), ty = Double(b.y - a.y)
        let len = (tx * tx + ty * ty).squareRoot()
        if len > 0 { tx /= len; ty /= len } else { tx = 1; ty = 0 }
        let px = -ty, py = tx
        let ends = pow(sin(.pi * t), 0.45)
        let ripple = 1.0 + 0.10 * sin(t * f1 * 6.28 + ph1)
        let hw = max(0, weight * 0.5 * ends * run.power[i] * ripple)
        let cx = Double(run.pts[i].x) + px * inset
        let cy = Double(run.pts[i].y) + py * inset
        left.append(pt(cx + px * hw, cy + py * hw))
        right.append(pt(cx - px * hw, cy - py * hw))
    }
    p.shape(left + right.reversed(), colour)
}

func litEdges(_ p: Leaf, _ ring: [CGPoint], weight: Double, colour: Hue, inset: Double = 0, seed: UInt64) {
    let lx = cos(p.light), ly = sin(p.light)
    for (k, run) in rimRuns(ring, lx: lx, ly: ly).enumerated() {
        rimStroke(p, run, weight: weight, colour: colour, inset: inset, seed: seed &+ UInt64(k * 7 + 1))
    }
}

func darkEdges(_ p: Leaf, _ ring: [CGPoint], weight: Double, colour: Hue, inset: Double = 0, seed: UInt64) {
    let lx = -cos(p.light), ly = -sin(p.light)
    for (k, run) in rimRuns(ring, lx: lx, ly: ly, enter: 0.30, leave: 0.05).enumerated() {
        rimStroke(p, run, weight: weight, colour: colour, inset: inset, seed: seed &+ UInt64(k * 11 + 3))
    }
}

func streaks(_ p: Leaf, _ clip: CGPath, count: Int, angle: Double, light: Hue, dark: Hue,
             length: ClosedRange<Double>, weight: ClosedRange<Double> = 0.6...1.6, seed: UInt64) {
    var rng = Chip(seed)
    let box = clip.boundingBox
    p.inside(clip) {
        for _ in 0..<count {
            let x = Double(box.minX) + rng.d() * Double(box.width)
            let y = Double(box.minY) + rng.d() * Double(box.height)
            let a = angle + rng.signed() * 0.04
            let len = rng.r(length.lowerBound, length.upperBound)
            let tone = rng.chance(0.5) ? light.al(light.a * rng.r(0.35, 1.0)) : dark.al(dark.a * rng.r(0.35, 1.0))
            p.ctx.setStrokeColor(cg(tone))
            p.ctx.setLineWidth(CGFloat(rng.r(weight.lowerBound, weight.upperBound)))
            p.ctx.setLineCap(.round)
            p.ctx.beginPath()
            p.ctx.move(to: pt(x - cos(a) * len * 0.5, y - sin(a) * len * 0.5))
            p.ctx.addLine(to: pt(x + cos(a) * len * 0.5, y + sin(a) * len * 0.5))
            p.ctx.strokePath()
        }
    }
}

func filmGrain(_ p: Leaf, amount: Double, seed: UInt64) {
    guard let data = p.ctx.data else { return }
    let w = p.ctx.width, h = p.ctx.height, row = p.ctx.bytesPerRow
    let bytes = data.bindMemory(to: UInt8.self, capacity: row * h)
    var rng = Chip(seed)
    for y in 0..<h {
        let base = y * row
        for x in 0..<w {
            let o = base + x * 4
            let n = rng.signed() * amount
            let lum = rng.signed() * amount * 0.35
            for c in 0..<3 {
                let v = Double(bytes[o + c]) + n + (c == 0 ? lum : (c == 2 ? -lum : 0))
                bytes[o + c] = UInt8(max(0, min(255, v.rounded())))
            }
        }
    }
}

struct TrowelFrame {
    let ox: Double
    let oy: Double
    let dx: Double
    let dy: Double
    var cx: Double { -dy }
    var cy: Double { dx }

    func at(_ u: Double, _ v: Double) -> CGPoint {
        pt(ox + dx * u + cx * v, oy + dy * u + cy * v)
    }

    func lambert(_ s: Double, concave: Double = 0) -> (key: Double, fill: Double, spec: Double, up: Double) {
        let ss = max(-1.0, min(1.0, s))
        let across = concave > 0 ? -ss * concave : ss
        let z = (max(0.0, 1 - across * across)).squareRoot()
        let nx = cx * across, ny = cy * across
        let key = nx * keyRay.x + ny * keyRay.y + z * keyRay.z
        let fill = nx * fillRay.x + ny * fillRay.y + z * fillRay.z
        let spec = nx * halfRay.x + ny * halfRay.y + z * halfRay.z
        return (max(0, key), max(0, fill), max(0, spec), -ny * z)
    }
}

let trowel = TrowelFrame(ox: 640, oy: 400, dx: -0.55, dy: 0.835)

func bladeHalfWidth(_ u: Double) -> Double {
    if u < 20 { return 34 }
    if u < 120 { return 34 + (126 - 34) * smoothStep((u - 20) / 100) }
    if u < 220 { return 126 + (148 - 126) * smoothStep((u - 120) / 100) }
    if u < 330 { return 148 - 8 * (u - 220) / 110 }
    if u < 640 { return 140 - 90 * (u - 330) / 310 }
    let t = (u - 640) / 84
    return 50 * (max(0.0, 1 - t * t)).squareRoot()
}

func bladeRingLocal(from u0: Double, to u1: Double, step: Double = 6) -> [CGPoint] {
    var left: [CGPoint] = []
    var right: [CGPoint] = []
    var u = u0
    while u <= u1 {
        let hw = bladeHalfWidth(u)
        left.append(trowel.at(u, hw))
        right.append(trowel.at(u, -hw))
        u += step
    }
    left.append(trowel.at(u1, bladeHalfWidth(u1)))
    right.append(trowel.at(u1, -bladeHalfWidth(u1)))
    return left + right.reversed()
}

func handleRadius(_ u: Double) -> Double {
    var r = 60.0 * (1 + 0.10 * sin((u + 70) / 520 * .pi))
    if u > -136 && u < -124 { r *= 0.92 }
    if u > -396 && u < -382 { r *= 0.93 }
    if u > -96 { r *= 1 - 0.18 * smoothStep((u + 96) / 26) }
    return r
}

func ferruleRadius(_ u: Double) -> Double {
    if u < -62 { return 62 }
    var r = 57.0 - 13.0 * (u + 62) / 92
    if u > -24 && u < -16 { r -= 3 }
    if u > 6 && u < 14 { r -= 3 }
    return r
}

func cylinderBands(_ p: Leaf, from u0: Double, to u1: Double, radius: (Double) -> Double, bands: Int,
                   tone: (Double, Double) -> Hue) {
    var us: [Double] = []
    var u = u0
    while u < u1 { us.append(u); u += 5 }
    us.append(u1)
    for b in 0..<bands {
        let s0 = 1 - 2 * Double(b) / Double(bands)
        let s1 = 1 - 2 * Double(b + 1) / Double(bands) - 0.02
        var top: [CGPoint] = []
        var bottom: [CGPoint] = []
        for uu in us {
            let r = radius(uu)
            top.append(trowel.at(uu, s0 * r))
            bottom.append(trowel.at(uu, s1 * r))
        }
        p.shape(top + bottom.reversed(), tone((s0 + s1) * 0.5, (us.first ?? 0)))
    }
}

func handleTone(_ s: Double, _ u: Double) -> Hue {
    let l = trowel.lambert(s)
    let base = Hue(r: 0.74, g: 0.37, b: 0.20)
    var v = 0.12 + l.key * 0.95 + l.fill * 0.26
    v += pow(l.spec, 14) * 0.34
    let warm = base.mix(Hue(r: 0.98, g: 0.62, b: 0.40), max(0, v - 0.75) * 1.4)
    if v < 0.5 { return warm.dk((0.5 - v) * 1.6) }
    return warm.lt((v - 0.5) * 0.55)
}

func brassTone(_ s: Double, _ u: Double) -> Hue {
    let l = trowel.lambert(s)
    let base = Hue(r: 0.74, g: 0.56, b: 0.24)
    var v = 0.10 + l.key * 0.80 + l.fill * 0.30 + pow(l.spec, 22) * 0.95
    v += 0.10 * sin(s * 9.0)
    if v < 0.5 { return base.dk((0.5 - v) * 1.7) }
    return base.mix(Hue(r: 1.0, g: 0.96, b: 0.80), (v - 0.5) * 1.1)
}

func steelTone(_ s: Double, _ u: Double) -> Hue {
    let rim = abs(s) > 0.84 ? 1.0 : 0.0
    let inner = trowel.lambert(s, concave: 0.72)
    let outer = trowel.lambert(s)
    let key = inner.key * (1 - rim) + outer.key * rim
    let fill = inner.fill * (1 - rim) + outer.fill * rim
    let up = inner.up * (1 - rim) + outer.up * rim
    let sky = Hue(r: 0.20, g: 0.23, b: 0.27)
    let soil = Hue(r: 0.44, g: 0.33, b: 0.21)
    let near = smoothStep((u - 320) / 150)
    let env = up > 0 ? sky.mix(Hue(r: 0.30, g: 0.33, b: 0.37), up) : sky.mix(soil, min(1, -up * 1.4))
    let steel = Hue(r: 0.62, g: 0.65, b: 0.68)
    var v = 0.04 + key * 0.92 + fill * 0.26
    let band = exp(-pow((s - 0.38) / 0.15, 2)) * 1.05 + exp(-pow((s + 0.16) / 0.28, 2)) * 0.30
    v += band * (0.55 + 0.3 * (1 - near))
    var tone = steel.mix(env, 0.42)
    tone = tone.mix(soil.dk(0.2), near * 0.35)
    if v < 0.5 { tone = tone.dk((0.5 - v) * 1.7) } else { tone = tone.mix(Hue(r: 0.98, g: 0.98, b: 1.0), min(1, (v - 0.5) * 1.25)) }
    return tone
}

func granule(_ p: Leaf, x: Double, y: Double, r: Double, inShadow: Bool, rng: inout Chip) {
    let clod = lumpy(cx: x, cy: y, rx: r, ry: r * rng.r(0.6, 0.9), rough: 0.22, steps: 7, seed: rng.next())
    let baseTone = Hue(r: 0.27, g: 0.19, b: 0.12).mix(Hue(r: 0.40, g: 0.30, b: 0.19), rng.d() * 0.5)
    p.egg(x + r * 0.55, y + r * 0.45, r * 0.8, r * 0.52, Hue(r: 0.03, g: 0.02, b: 0.01, a: 0.45))
    p.shape(clod, (inShadow ? baseTone.dk(0.45) : baseTone).dk(rng.d() * 0.25))
    if !inShadow && r > 2.2 {
        p.egg(x - r * 0.42, y - r * 0.38, r * 0.34, r * 0.22, Hue(r: 0.76, g: 0.62, b: 0.44, a: rng.r(0.35, 0.8)))
    }
}

func drawSoilGranules(_ p: Leaf, region: CGPath, horizon: Double, count: Int, shadow: CGPath?, seed: UInt64, big: Bool) {
    var rng = Chip(seed)
    let box = region.boundingBox
    p.inside(region) {
        for _ in 0..<count {
            let x = Double(box.minX) + rng.d() * Double(box.width)
            let y = Double(box.minY) + rng.d() * Double(box.height)
            let depth = max(0.0, min(1.0, (y - horizon) / (1024 - horizon)))
            let r = (big ? rng.r(4, 11) : rng.r(1.4, 3.2) + depth * rng.r(2, 7))
            let inShadow = shadow.map { $0.contains(pt(x, y)) } ?? false
            granule(p, x: x, y: y, r: r, inShadow: inShadow, rng: &rng)
        }
    }
}

func drawFrostGlints(_ p: Leaf, region: CGPath, count: Int, seed: UInt64) {
    var rng = Chip(seed)
    let box = region.boundingBox
    p.inside(region) {
        for k in 0..<count {
            let x = Double(box.minX) + rng.d() * Double(box.width)
            let y = Double(box.minY) + rng.d() * Double(box.height)
            let r = rng.r(2.5, 8)
            let a = rng.r(0.35, 0.9)
            p.radial(pt(x, y), r * 2.2, Hue(r: 0.85, g: 0.92, b: 1.0, a: a * 0.35), Hue(r: 0.85, g: 0.92, b: 1.0, a: 0))
            let spin = rng.r(0, 1)
            for j in 0..<3 {
                let ang = spin + Double(j) * .pi / 3
                pen(p, [pt(x - cos(ang) * r, y - sin(ang) * r), pt(x + cos(ang) * r, y + sin(ang) * r)],
                    weight: 1.6, colour: Hue(r: 0.94, g: 0.97, b: 1.0, a: a), wobble: 0.1, taper: true, seed: seed &+ UInt64(k * 5 + j))
            }
            p.dot(x, y, r * 0.22, Hue(r: 1, g: 1, b: 1, a: min(1, a + 0.2)))
        }
    }
}

func leafForm(_ p: Leaf, ring: [CGPoint], base: Hue, veinFrom: CGPoint, veinTo: CGPoint, sideVeins: Int, seed: UInt64) {
    let path = pathOf(ring)
    var cx = 0.0, cy = 0.0
    for q in ring { cx += Double(q.x); cy += Double(q.y) }
    cx /= Double(ring.count); cy /= Double(ring.count)
    let box = path.boundingBox
    let rad = Double(max(box.width, box.height)) * 0.75
    p.shape(ring, base)
    p.radial(pt(cx - rad * 0.4, cy - rad * 0.4), rad * 1.3, base.lt(0.45), base.dk(0.45), clip: path)
    p.radial(pt(cx + rad * 0.5, cy + rad * 0.5), rad * 0.9, Hue(r: 0.85, g: 0.62, b: 0.30, a: 0.18), Hue(r: 0.85, g: 0.62, b: 0.30, a: 0), clip: path)
    let axisA = atan2(Double(veinTo.y - veinFrom.y), Double(veinTo.x - veinFrom.x))
    streaks(p, path, count: 420, angle: axisA + 0.2, light: Hue(r: 0.88, g: 0.96, b: 0.66, a: 0.10), dark: Hue(r: 0.06, g: 0.14, b: 0.03, a: 0.14), length: 3...11, weight: 0.5...1.1, seed: seed &+ 5)
    p.inside(path) {
        pen(p, [veinFrom, veinTo], weight: 3.2, colour: base.dk(0.55).al(0.85), wobble: 0.3, taper: true, seed: seed &+ 11)
        pen(p, [pt(Double(veinFrom.x) - 1.6, Double(veinFrom.y) - 1.6), pt(Double(veinTo.x) - 1.6, Double(veinTo.y) - 1.6)], weight: 1.5, colour: Hue(r: 0.85, g: 0.95, b: 0.65, a: 0.5), wobble: 0.2, taper: true, seed: seed &+ 12)
        let len = hypot(Double(veinTo.x - veinFrom.x), Double(veinTo.y - veinFrom.y))
        for k in 1...max(1, sideVeins) {
            let t = Double(k) / Double(sideVeins + 1)
            let qx = Double(veinFrom.x) + (Double(veinTo.x) - Double(veinFrom.x)) * t
            let qy = Double(veinFrom.y) + (Double(veinTo.y) - Double(veinFrom.y)) * t
            for side in [-1.0, 1.0] {
                let a = axisA + side * 0.95
                let e = pt(qx + cos(a) * len * 0.42 * (1 - t * 0.5), qy + sin(a) * len * 0.42 * (1 - t * 0.5))
                pen(p, [pt(qx, qy), e], weight: 1.8, colour: base.dk(0.5).al(0.6), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 3 + Int(side + 2) + 20))
                pen(p, [pt(qx - 1.2, qy - 1.2), pt(Double(e.x) - 1.2, Double(e.y) - 1.2)], weight: 0.9, colour: Hue(r: 0.85, g: 0.95, b: 0.65, a: 0.30), wobble: 0.2, taper: true, seed: seed &+ UInt64(k * 3 + Int(side + 2) + 40))
            }
        }
    }
    litEdges(p, ring, weight: 4.2, colour: Hue(r: 0.92, g: 0.98, b: 0.72, a: 0.85), inset: 1.5, seed: seed &+ 60)
    darkEdges(p, ring, weight: 4.0, colour: Hue(r: 0.03, g: 0.07, b: 0.02, a: 0.7), inset: 1.5, seed: seed &+ 70)
    penOutline(p, ring, weight: 1.8, colour: Hue(r: 0.06, g: 0.12, b: 0.04, a: 0.85), seed: seed &+ 80)
}

func cotyledonRing(at c: CGPoint, angle: Double, length: Double, width: Double, seed: UInt64) -> [CGPoint] {
    var rng = Chip(seed)
    var ring: [CGPoint] = []
    for i in 0..<40 {
        let t = Double(i) / 40 * 2 * .pi
        let lx = cos(t) * length * 0.5 * (1 + 0.06 * cos(3 * t))
        let ly = sin(t) * width * 0.5 * (1 + rng.r(-0.02, 0.02))
        ring.append(pt(Double(c.x) + cos(angle) * lx - sin(angle) * ly, Double(c.y) + sin(angle) * lx + cos(angle) * ly))
    }
    return ring
}

func drawSeedling(_ p: Leaf, base: CGPoint, soilClip: CGPath, seed: UInt64) {
    let bx = Double(base.x), by = Double(base.y)
    let top = pt(bx + 14, by - 118)
    let stemSpine = [base, pt(bx + 4, by - 60), top]
    let stemRing = bandOf(stemSpine, [15, 12, 10], per: 8)
    let leftC = pt(Double(top.x) - 62, Double(top.y) - 14)
    let rightC = pt(Double(top.x) + 66, Double(top.y) - 10)
    let left = cotyledonRing(at: leftC, angle: -2.72, length: 118, width: 62, seed: seed &+ 1)
    let right = cotyledonRing(at: rightC, angle: -0.40, length: 122, width: 64, seed: seed &+ 2)
    let trueC = pt(Double(top.x) + 10, Double(top.y) - 78)
    let trueLeaf = lobedRing(at: trueC, angle: -1.35, size: 52, lobes: 5, depth: 0.28, aspect: 1.15, seed: seed &+ 3)
    p.inside(soilClip) {
        for ring in [left, right, trueLeaf, stemRing] {
            let cast = ring.map { q -> CGPoint in
                let dy = (by - Double(q.y)) * 0.45
                return pt(Double(q.x) + 38 + dy * 0.6, by + 8 + dy * 0.28)
            }
            for k in stride(from: 3, through: 0, by: -1) {
                p.shape(offsetRing(cast, Double(k) * 2.2, Double(k) * 1.6), Hue(r: 0.02, g: 0.015, b: 0.01, a: 0.16))
            }
        }
    }
    let stemTone = Hue(r: 0.58, g: 0.70, b: 0.40)
    p.shape(stemRing, stemTone)
    p.radial(pt(bx - 20, by - 70), 120, stemTone.lt(0.35), stemTone.dk(0.45), clip: pathOf(stemRing))
    streaks(p, pathOf(stemRing), count: 220, angle: -1.45, light: Hue(r: 0.95, g: 1.0, b: 0.8, a: 0.14), dark: Hue(r: 0.1, g: 0.2, b: 0.05, a: 0.16), length: 6...20, weight: 0.5...1.2, seed: seed &+ 9)
    litEdges(p, stemRing, weight: 3.2, colour: Hue(r: 0.95, g: 1.0, b: 0.85, a: 0.8), inset: 1.2, seed: seed &+ 10)
    darkEdges(p, stemRing, weight: 3.4, colour: Hue(r: 0.05, g: 0.10, b: 0.03, a: 0.7), inset: 1.2, seed: seed &+ 11)
    penOutline(p, stemRing, weight: 1.6, colour: Hue(r: 0.08, g: 0.14, b: 0.05, a: 0.85), seed: seed &+ 12)
    let leafTone = Hue(r: 0.36, g: 0.56, b: 0.24)
    leafForm(p, ring: right, base: leafTone.dk(0.06), veinFrom: pt(Double(top.x) + 8, Double(top.y) - 4), veinTo: pt(Double(rightC.x) + 52, Double(rightC.y) - 22), sideVeins: 3, seed: seed &+ 20)
    leafForm(p, ring: left, base: leafTone, veinFrom: pt(Double(top.x) - 6, Double(top.y) - 4), veinTo: pt(Double(leftC.x) - 50, Double(leftC.y) - 24), sideVeins: 3, seed: seed &+ 30)
    let petiole = [pt(Double(top.x) + 2, Double(top.y) - 2), pt(Double(trueC.x) - 4, Double(trueC.y) + 30)]
    pen(p, petiole, weight: 7, colour: stemTone.dk(0.1), wobble: 0.3, taper: false, seed: seed &+ 40)
    pen(p, offsetRing(petiole, -1.5, -1.5), weight: 2.2, colour: Hue(r: 0.95, g: 1.0, b: 0.85, a: 0.6), wobble: 0.2, taper: true, seed: seed &+ 41)
    leafForm(p, ring: trueLeaf, base: leafTone.lt(0.06), veinFrom: pt(Double(trueC.x) - 6, Double(trueC.y) + 40), veinTo: pt(Double(trueC.x) + 10, Double(trueC.y) - 44), sideVeins: 4, seed: seed &+ 50)
    let husk = lumpy(cx: Double(rightC.x) + 50, cy: Double(rightC.y) - 26, rx: 17, ry: 11, rough: 0.08, steps: 16, seed: seed &+ 61)
    let huskRot = rotatedRing(husk, about: pt(Double(rightC.x) + 50, Double(rightC.y) - 26), -0.5)
    p.shape(huskRot, Hue(r: 0.30, g: 0.17, b: 0.10))
    p.radial(pt(Double(rightC.x) + 44, Double(rightC.y) - 32), 26, Hue(r: 0.58, g: 0.36, b: 0.22), Hue(r: 0.18, g: 0.09, b: 0.05), clip: pathOf(huskRot))
    penOutline(p, huskRot, weight: 1.4, colour: Hue(r: 0.10, g: 0.05, b: 0.03, a: 0.9), seed: seed &+ 62)
}

func drawIcon(_ dir: String) {
    let previous = sheetScale
    sheetScale = 1.0
    let p = Leaf(1024, 1024)
    p.fillAll(Hue(r: 0.07, g: 0.06, b: 0.05))
    p.flipDown()
    p.light = -2.36
    var rng = Chip(hashOf("lastfrost-trowel-icon"))
    let whole = CGMutablePath()
    whole.addRect(CGRect(x: 0, y: 0, width: 1024, height: 1024))

    p.radial(pt(230, 180), 1250, Hue(r: 0.23, g: 0.21, b: 0.16), Hue(r: 0.03, g: 0.03, b: 0.03), clip: whole)
    for _ in 0..<7 {
        let x = rng.r(-100, 1100), y = rng.r(180, 560)
        let rx = rng.r(160, 420)
        p.radial(pt(x, y), rx, Hue(r: 0.09, g: 0.12, b: 0.07, a: 0.55), Hue(r: 0.09, g: 0.12, b: 0.07, a: 0), clip: whole)
    }
    let boardY = 545.0
    p.gradientRect(CGRect(x: 0, y: boardY - 70, width: 1024, height: 74), Hue(r: 0.12, g: 0.10, b: 0.07, a: 0), Hue(r: 0.26, g: 0.20, b: 0.13, a: 0.9))
    p.gradientRect(CGRect(x: 0, y: boardY, width: 1024, height: 26), Hue(r: 0.30, g: 0.23, b: 0.15), Hue(r: 0.12, g: 0.09, b: 0.06))

    let horizon = 566.0
    var soilRing: [CGPoint] = [pt(-30, 1060), pt(-30, horizon + 6)]
    var x = -30.0
    while x < 1060 {
        soilRing.append(pt(x, horizon + rng.r(-9, 9)))
        x += rng.r(30, 60)
    }
    soilRing.append(pt(1060, horizon))
    soilRing.append(pt(1060, 1060))
    let soilPath = pathOf(soilRing)
    p.shape(soilRing, Hue(r: 0.22, g: 0.16, b: 0.10))
    p.radial(pt(320, 640), 980, Hue(r: 0.44, g: 0.34, b: 0.22), Hue(r: 0.10, g: 0.07, b: 0.05), clip: soilPath)
    p.gradientRect(CGRect(x: 0, y: horizon - 4, width: 1024, height: 90), Hue(r: 0.05, g: 0.04, b: 0.03, a: 0.75), Hue(r: 0.05, g: 0.04, b: 0.03, a: 0))

    let shadowBlade = bladeRingLocal(from: 20, to: 500).map { q -> CGPoint in
        let lift = max(0, 760 - Double(q.y)) * 0.42
        return pt(Double(q.x) + 96 + lift * 0.9, Double(q.y) + 48 + lift * 0.28)
    }
    var shadowHandle: [CGPoint] = []
    for uu in stride(from: -600.0, through: -60.0, by: 20) {
        shadowHandle.append(trowel.at(uu, handleRadius(uu) + 6))
    }
    for uu in stride(from: -60.0, through: -600.0, by: -20) {
        shadowHandle.append(trowel.at(uu, -handleRadius(uu) - 6))
    }
    let shadowHandleCast = shadowHandle.map { q -> CGPoint in
        let lift = max(0, 760 - Double(q.y)) * 0.42
        return pt(Double(q.x) + 96 + lift * 0.9, Double(q.y) + 48 + lift * 0.28)
    }
    let shadowPath = CGMutablePath()
    shadowPath.addPath(pathOf(shadowBlade))
    shadowPath.addPath(pathOf(shadowHandleCast))

    drawSoilGranules(p, region: soilPath, horizon: horizon, count: 5200, shadow: shadowPath, seed: rng.next(), big: false)
    p.inside(soilPath) {
        for k in stride(from: 5, through: 0, by: -1) {
            let d = Double(k) * 7
            p.shape(offsetRing(shadowBlade, d * 0.7, d * 0.5), Hue(r: 0.01, g: 0.01, b: 0.005, a: 0.11))
            p.shape(offsetRing(shadowHandleCast, d * 0.7, d * 0.5), Hue(r: 0.01, g: 0.01, b: 0.005, a: 0.09))
        }
    }

    let frostRegion = CGMutablePath()
    frostRegion.addRect(CGRect(x: 560, y: horizon, width: 470, height: 470))
    frostRegion.addPath(pathOf(shadowBlade))
    p.inside(soilPath) { drawFrostGlints(p, region: frostRegion, count: 150, seed: rng.next()) }
    p.inside(soilPath) {
        for _ in 0..<900 {
            let fx = rng.r(560, 1024), fy = rng.r(horizon, 1024)
            p.dot(fx, fy, rng.r(0.7, 1.8), Hue(r: 0.85, g: 0.90, b: 0.98, a: rng.r(0.15, 0.55)))
        }
    }

    cylinderBands(p, from: -640, to: -60, radius: handleRadius, bands: 44, tone: handleTone)
    let handleRingPts = (stride(from: -640.0, through: -60.0, by: 8).map { trowel.at($0, handleRadius($0)) }
                         + stride(from: -60.0, through: -640.0, by: -8).map { trowel.at($0, -handleRadius($0)) })
    let handlePath = pathOf(handleRingPts)
    var chips = Chip(rng.next())
    for _ in 0..<9 {
        let cu = chips.r(-600, -150), cs = chips.r(-0.75, 0.8)
        let centre = trowel.at(cu, cs * handleRadius(cu))
        let chip = lumpy(cx: Double(centre.x), cy: Double(centre.y), rx: chips.r(9, 30), ry: chips.r(5, 12), rough: 0.35, steps: 12, seed: chips.next())
        let chipRot = rotatedRing(chip, about: centre, atan2(trowel.dy, trowel.dx) + chips.r(-0.3, 0.3))
        let l = trowel.lambert(cs)
        let v = 0.18 + l.key * 0.85 + l.fill * 0.25
        let wood = Hue(r: 0.70, g: 0.56, b: 0.37)
        let woodLit = v < 0.5 ? wood.dk((0.5 - v) * 1.4) : wood.lt((v - 0.5) * 0.5)
        p.insideBoth(pathOf(chipRot), handlePath) {
            p.shape(chipRot, woodLit)
            streaks(p, pathOf(chipRot), count: 90, angle: atan2(trowel.dy, trowel.dx), light: Hue(r: 0.95, g: 0.86, b: 0.66, a: 0.35), dark: Hue(r: 0.32, g: 0.20, b: 0.10, a: 0.45), length: 6...30, weight: 0.6...1.3, seed: chips.next())
        }
        p.inside(handlePath) {
            penOutline(p, chipRot, weight: 1.6, colour: Hue(r: 0.28, g: 0.12, b: 0.06, a: 0.85), seed: chips.next())
            penOutline(p, offsetRing(chipRot, 1.4, 1.4), weight: 0.9, colour: Hue(r: 1.0, g: 0.80, b: 0.62, a: 0.30), seed: chips.next())
        }
    }
    for _ in 0..<28 {
        let su = chips.r(-620, -110), ss = chips.r(-0.9, 0.9)
        let a = trowel.at(su, ss * handleRadius(su))
        let len = chips.r(10, 60)
        let ang = atan2(trowel.dy, trowel.dx) + chips.r(-0.25, 0.25)
        p.inside(handlePath) {
            pen(p, [a, pt(Double(a.x) + cos(ang) * len, Double(a.y) + sin(ang) * len)], weight: 1.3, colour: Hue(r: 0.30, g: 0.14, b: 0.07, a: 0.55), wobble: 0.3, taper: true, seed: chips.next())
            pen(p, [pt(Double(a.x) - 1, Double(a.y) - 1), pt(Double(a.x) + cos(ang) * len - 1, Double(a.y) + sin(ang) * len - 1)], weight: 0.8, colour: Hue(r: 1.0, g: 0.82, b: 0.66, a: 0.28), wobble: 0.2, taper: true, seed: chips.next())
        }
    }
    streaks(p, handlePath, count: 900, angle: atan2(trowel.dy, trowel.dx), light: Hue(r: 1.0, g: 0.80, b: 0.62, a: 0.07), dark: Hue(r: 0.25, g: 0.10, b: 0.04, a: 0.09), length: 8...50, weight: 0.6...1.4, seed: rng.next())
    for gu in [-130.0, -390.0] {
        let ring = [trowel.at(gu - 6, handleRadius(gu - 6)), trowel.at(gu + 6, handleRadius(gu + 6)), trowel.at(gu + 6, -handleRadius(gu + 6)), trowel.at(gu - 6, -handleRadius(gu - 6))]
        p.shape(ring, Hue(r: 0.20, g: 0.08, b: 0.03, a: 0.55))
        pen(p, [trowel.at(gu + 8, handleRadius(gu + 8) * 0.98), trowel.at(gu + 8, -handleRadius(gu + 8) * 0.98)], weight: 2.2, colour: Hue(r: 1.0, g: 0.86, b: 0.70, a: 0.35), wobble: 0.2, taper: true, seed: rng.next())
    }
    litEdges(p, handleRingPts, weight: 7, colour: Hue(r: 1.0, g: 0.90, b: 0.78, a: 0.92), inset: 2, seed: rng.next())
    darkEdges(p, handleRingPts, weight: 6, colour: Hue(r: 0.10, g: 0.04, b: 0.02, a: 0.8), inset: 2, seed: rng.next())
    penOutline(p, handleRingPts, weight: 2.2, colour: Hue(r: 0.12, g: 0.05, b: 0.02, a: 0.8), seed: rng.next())

    cylinderBands(p, from: -74, to: 30, radius: ferruleRadius, bands: 40, tone: brassTone)
    let ferrulePts = (stride(from: -74.0, through: 30.0, by: 4).map { trowel.at($0, ferruleRadius($0)) }
                      + stride(from: 30.0, through: -74.0, by: -4).map { trowel.at($0, -ferruleRadius($0)) })
    let ferrulePath = pathOf(ferrulePts)
    streaks(p, ferrulePath, count: 700, angle: atan2(trowel.dy, trowel.dx) + .pi / 2, light: Hue(r: 1.0, g: 0.96, b: 0.80, a: 0.16), dark: Hue(r: 0.20, g: 0.12, b: 0.03, a: 0.20), length: 6...40, weight: 0.5...1.4, seed: rng.next())
    for gu in [-20.0, 10.0] {
        pen(p, [trowel.at(gu, ferruleRadius(gu) * 0.97), trowel.at(gu, -ferruleRadius(gu) * 0.97)], weight: 3.0, colour: Hue(r: 0.20, g: 0.12, b: 0.03, a: 0.7), wobble: 0.2, taper: true, seed: rng.next())
        pen(p, [trowel.at(gu + 3, ferruleRadius(gu) * 0.97), trowel.at(gu + 3, -ferruleRadius(gu) * 0.97)], weight: 1.6, colour: Hue(r: 1.0, g: 0.96, b: 0.80, a: 0.45), wobble: 0.2, taper: true, seed: rng.next())
    }
    let lipRing = [trowel.at(-74, 62), trowel.at(-62, 62), trowel.at(-62, -62), trowel.at(-74, -62)]
    p.shape(lipRing, Hue(r: 0.30, g: 0.20, b: 0.06, a: 0.55))
    litEdges(p, ferrulePts, weight: 5, colour: Hue(r: 1.0, g: 0.97, b: 0.84, a: 0.95), inset: 1.5, seed: rng.next())
    darkEdges(p, ferrulePts, weight: 5, colour: Hue(r: 0.10, g: 0.06, b: 0.01, a: 0.8), inset: 1.5, seed: rng.next())
    penOutline(p, ferrulePts, weight: 2.0, colour: Hue(r: 0.12, g: 0.07, b: 0.02, a: 0.8), seed: rng.next())

    let bladeRing = bladeRingLocal(from: 16, to: 724)
    let bladePath = pathOf(bladeRing)
    var sidePts: [CGPoint] = []
    var uu = 16.0
    while uu <= 724 { sidePts.append(trowel.at(uu, -bladeHalfWidth(uu))); uu += 6 }
    let sideRing = sidePts + sidePts.reversed().map { pt(Double($0.x) + 9, Double($0.y) + 7) }
    p.shape(sideRing, Hue(r: 0.16, g: 0.16, b: 0.17))
    p.radial(pt(700, 900), 500, Hue(r: 0.40, g: 0.32, b: 0.24), Hue(r: 0.10, g: 0.10, b: 0.11), clip: pathOf(sideRing))
    pen(p, sidePts.map { pt(Double($0.x) + 9, Double($0.y) + 7) }, weight: 1.6, colour: Hue(r: 0.70, g: 0.60, b: 0.48, a: 0.45), wobble: 0.2, taper: true, seed: rng.next())

    let bladeBands = 60
    var us: [Double] = []
    var u = 16.0
    while u < 724 { us.append(u); u += 5 }
    us.append(724)
    for b in 0..<bladeBands {
        let s0 = 1 - 2 * Double(b) / Double(bladeBands)
        let s1 = 1 - 2 * Double(b + 1) / Double(bladeBands) - 0.02
        var top: [CGPoint] = []
        var bottom: [CGPoint] = []
        for uu in us {
            let hw = bladeHalfWidth(uu)
            top.append(trowel.at(uu, s0 * hw))
            bottom.append(trowel.at(uu, s1 * hw))
        }
        let sMid = (s0 + s1) * 0.5
        let chunks = 6
        let per = max(1, top.count / chunks)
        for c in 0..<chunks {
            let i0 = c * per
            let i1 = c == chunks - 1 ? top.count - 1 : min(top.count - 1, (c + 1) * per)
            guard i1 > i0 else { continue }
            let uMid = (us[i0] + us[i1]) * 0.5
            p.shape(Array(top[i0...i1]) + Array(bottom[i0...i1]).reversed(), steelTone(sMid, uMid))
        }
    }
    streaks(p, bladePath, count: 2600, angle: atan2(trowel.dy, trowel.dx), light: Hue(r: 1.0, g: 1.0, b: 1.0, a: 0.13), dark: Hue(r: 0.05, g: 0.06, b: 0.08, a: 0.16), length: 14...110, weight: 0.5...1.3, seed: rng.next())
    p.inside(bladePath) {
        let hot = [trowel.at(30, 44), trowel.at(200, 84), trowel.at(500, 62), trowel.at(500, 44), trowel.at(200, 56), trowel.at(30, 30)]
        p.shape(hot, Hue(r: 1.0, g: 1.0, b: 1.0, a: 0.20))
        let hot2 = [trowel.at(60, 64), trowel.at(380, 80), trowel.at(380, 72), trowel.at(60, 56)]
        p.shape(hot2, Hue(r: 1.0, g: 1.0, b: 1.0, a: 0.32))
        var scratches = Chip(rng.next())
        for _ in 0..<22 {
            let su = scratches.r(60, 460), ss = scratches.r(-0.85, 0.85)
            let a = trowel.at(su, ss * bladeHalfWidth(su))
            let ang = atan2(trowel.dy, trowel.dx) + scratches.r(-0.7, 0.7)
            let len = scratches.r(12, 70)
            pen(p, [a, pt(Double(a.x) + cos(ang) * len, Double(a.y) + sin(ang) * len)], weight: 1.0, colour: Hue(r: 0.06, g: 0.07, b: 0.09, a: 0.45), wobble: 0.2, taper: true, seed: scratches.next())
            pen(p, [pt(Double(a.x) + 1, Double(a.y) + 1), pt(Double(a.x) + cos(ang) * len + 1, Double(a.y) + sin(ang) * len + 1)], weight: 0.7, colour: Hue(r: 1.0, g: 1.0, b: 1.0, a: 0.35), wobble: 0.2, taper: true, seed: scratches.next())
        }
        let stampC = trowel.at(70, -10)
        let stamp = rotatedRing(lumpy(cx: Double(stampC.x), cy: Double(stampC.y), rx: 26, ry: 11, rough: 0.02, steps: 20, seed: 5), about: stampC, atan2(trowel.dy, trowel.dx))
        penOutline(p, stamp, weight: 1.8, colour: Hue(r: 0.05, g: 0.06, b: 0.08, a: 0.7), seed: rng.next())
        penOutline(p, offsetRing(stamp, 1.2, 1.2), weight: 0.9, colour: Hue(r: 1.0, g: 1.0, b: 1.0, a: 0.45), seed: rng.next())
        for k in 0..<3 {
            let q0 = trowel.at(58 + Double(k) * 12, -4), q1 = trowel.at(58 + Double(k) * 12, -16)
            pen(p, [q0, q1], weight: 1.6, colour: Hue(r: 0.05, g: 0.06, b: 0.08, a: 0.7), wobble: 0.1, taper: false, seed: rng.next())
            pen(p, offsetRing([q0, q1], 1.2, 1.2), weight: 0.8, colour: Hue(r: 1.0, g: 1.0, b: 1.0, a: 0.4), wobble: 0.1, taper: false, seed: rng.next())
        }
        let smear = lumpy(cx: Double(trowel.at(410, -40).x), cy: Double(trowel.at(410, -40).y), rx: 120, ry: 70, rough: 0.3, steps: 22, seed: rng.next())
        p.shape(smear, Hue(r: 0.30, g: 0.21, b: 0.13, a: 0.28))
        let smear2 = lumpy(cx: Double(trowel.at(440, 40).x), cy: Double(trowel.at(440, 40).y), rx: 90, ry: 60, rough: 0.35, steps: 20, seed: rng.next())
        p.shape(smear2, Hue(r: 0.26, g: 0.18, b: 0.11, a: 0.34))
    }
    let tangRing = [trowel.at(16, 40), trowel.at(30, 40), trowel.at(30, -40), trowel.at(16, -40)]
    p.shape(tangRing, Hue(r: 0.05, g: 0.05, b: 0.06, a: 0.5))
    litEdges(p, bladeRing, weight: 9, colour: Hue(r: 1.0, g: 1.0, b: 1.0, a: 0.95), inset: 2.5, seed: rng.next())
    litEdges(p, bladeRing, weight: 20, colour: Hue(r: 1.0, g: 1.0, b: 1.0, a: 0.18), inset: 8, seed: rng.next())
    darkEdges(p, bladeRing, weight: 6, colour: Hue(r: 0.04, g: 0.04, b: 0.05, a: 0.85), inset: 2, seed: rng.next())
    penOutline(p, bladeRing, weight: 2.4, colour: Hue(r: 0.05, g: 0.05, b: 0.06, a: 0.9), seed: rng.next())

    var entry: [CGPoint] = [pt(-30, 1060)]
    x = -30
    while x < 1060 {
        let bump = 778 + 20 * sin(x / 95) + rng.r(-9, 9)
        entry.append(pt(x, bump))
        x += rng.r(22, 44)
    }
    entry.append(pt(1060, 772))
    entry.append(pt(1060, 1060))
    let nearPath = pathOf(entry)
    p.shape(entry, Hue(r: 0.20, g: 0.14, b: 0.09))
    p.radial(pt(300, 800), 900, Hue(r: 0.44, g: 0.34, b: 0.22), Hue(r: 0.09, g: 0.07, b: 0.05), clip: nearPath)
    p.inside(nearPath) {
        for k in stride(from: 5, through: 0, by: -1) {
            let d = Double(k) * 7
            p.shape(offsetRing(shadowBlade, d * 0.7, d * 0.5), Hue(r: 0.01, g: 0.01, b: 0.005, a: 0.10))
        }
    }
    drawSoilGranules(p, region: nearPath, horizon: horizon, count: 6200, shadow: shadowPath, seed: rng.next(), big: false)
    let heap = lumpy(cx: Double(trowel.at(470, 0).x), cy: Double(trowel.at(470, 0).y) + 4, rx: 215, ry: 54, rough: 0.28, steps: 28, seed: rng.next())
    p.shape(offsetRing(heap, 0, 6), Hue(r: 0.20, g: 0.14, b: 0.09))
    p.radial(pt(Double(trowel.at(470, 0).x) - 60, Double(trowel.at(470, 0).y) - 20), 220, Hue(r: 0.40, g: 0.30, b: 0.19), Hue(r: 0.16, g: 0.11, b: 0.07), clip: pathOf(offsetRing(heap, 0, 6)))
    drawSoilGranules(p, region: pathOf(heap), horizon: horizon, count: 420, shadow: nil, seed: rng.next(), big: true)
    let lip = lumpy(cx: Double(trowel.at(448, 118).x), cy: Double(trowel.at(448, 118).y), rx: 84, ry: 38, rough: 0.3, steps: 20, seed: rng.next())
    drawSoilGranules(p, region: pathOf(lip), horizon: horizon, count: 160, shadow: nil, seed: rng.next(), big: true)
    var clods = Chip(rng.next())
    for _ in 0..<300 {
        let cu = clods.r(436, 505)
        let cs = clods.r(-1.08, 1.08)
        let c = trowel.at(cu, cs * bladeHalfWidth(min(cu, 640)))
        let inShadow = cs < -0.5
        granule(p, x: Double(c.x), y: Double(c.y) + clods.r(-4, 10), r: clods.r(3.5, 11), inShadow: inShadow, rng: &clods)
    }
    for _ in 0..<70 {
        let cu = clods.r(400, 445)
        let cs = clods.chance(0.5) ? clods.r(0.72, 1.0) : clods.r(-1.0, -0.72)
        let c = trowel.at(cu, cs * bladeHalfWidth(cu))
        granule(p, x: Double(c.x), y: Double(c.y), r: clods.r(2.5, 7), inShadow: cs < 0, rng: &clods)
    }
    p.inside(bladePath) {
        var crumbs = Chip(rng.next())
        for _ in 0..<34 {
            let cu = crumbs.r(260, 470), cs = crumbs.r(-0.9, 0.9)
            let c = trowel.at(cu, cs * bladeHalfWidth(cu))
            let r = crumbs.r(2.5, 7)
            let clod = lumpy(cx: Double(c.x), cy: Double(c.y), rx: r, ry: r * 0.7, rough: 0.25, steps: 8, seed: crumbs.next())
            p.shape(clod, Hue(r: 0.24, g: 0.16, b: 0.10))
            p.egg(Double(c.x) + r * 0.5, Double(c.y) + r * 0.45, r * 0.8, r * 0.45, Hue(r: 0.02, g: 0.02, b: 0.01, a: 0.4))
            p.egg(Double(c.x) - r * 0.4, Double(c.y) - r * 0.35, r * 0.32, r * 0.2, Hue(r: 0.78, g: 0.64, b: 0.46, a: 0.7))
        }
    }
    p.inside(nearPath) { drawFrostGlints(p, region: pathOf(shadowBlade), count: 40, seed: rng.next()) }

    p.ctx.saveGState()
    p.ctx.translateBy(x: 222, y: 842)
    p.ctx.scaleBy(x: 1.38, y: 1.38)
    p.ctx.translateBy(x: -222, y: -842)
    drawSeedling(p, base: pt(222, 842), soilClip: soilPath, seed: hashOf("seedling"))
    p.ctx.restoreGState()

    p.radial(pt(1024, 1024), 900, Hue(r: 1.0, g: 0.72, b: 0.40, a: 0.14), Hue(r: 1.0, g: 0.72, b: 0.40, a: 0), clip: whole)
    p.radial(pt(120, 60), 900, Hue(r: 1.0, g: 0.97, b: 0.88, a: 0.10), Hue(r: 1.0, g: 0.97, b: 0.88, a: 0), clip: whole)
    if let g = CGGradient(colorsSpace: deviceRGB, colors: [cg(Hue(r: 0, g: 0, b: 0, a: 0)), cg(Hue(r: 0, g: 0, b: 0, a: 0.50))] as CFArray, locations: [0.52, 1]) {
        p.ctx.drawRadialGradient(g, startCenter: CGPoint(x: 480, y: 500), startRadius: 0, endCenter: CGPoint(x: 480, y: 500), endRadius: 820, options: [.drawsAfterEndLocation])
    }
    filmGrain(p, amount: 4.5, seed: rng.next())
    p.writePNG(dir, "AppIcon-1024")
    sheetScale = previous
}
