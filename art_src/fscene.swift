import Foundation
import CoreGraphics

struct SkyKey {
    var top: Hue
    var horizon: Hue
    var light: Double
    var warm: Double
    var lamp: Double
    var hour: Double
}

let skySlots: [SkyKey] = [
    SkyKey(top: Hue(r: 0.55, g: 0.62, b: 0.74), horizon: Hue(r: 0.94, g: 0.72, b: 0.52), light: 0.55, warm: 0.8, lamp: 0.2, hour: 6.5),
    SkyKey(top: Hue(r: 0.52, g: 0.68, b: 0.84), horizon: Hue(r: 0.80, g: 0.86, b: 0.90), light: 0.9, warm: 0.3, lamp: 0.0, hour: 9.0),
    SkyKey(top: Hue(r: 0.42, g: 0.62, b: 0.85), horizon: Hue(r: 0.78, g: 0.86, b: 0.92), light: 1.0, warm: 0.1, lamp: 0.0, hour: 12.5),
    SkyKey(top: Hue(r: 0.50, g: 0.66, b: 0.82), horizon: Hue(r: 0.90, g: 0.84, b: 0.72), light: 0.85, warm: 0.4, lamp: 0.0, hour: 16.0),
    SkyKey(top: Hue(r: 0.40, g: 0.38, b: 0.52), horizon: Hue(r: 0.92, g: 0.58, b: 0.36), light: 0.45, warm: 0.9, lamp: 0.4, hour: 19.0),
    SkyKey(top: Hue(r: 0.12, g: 0.14, b: 0.26), horizon: Hue(r: 0.30, g: 0.24, b: 0.36), light: 0.18, warm: 0.2, lamp: 1.0, hour: 21.5),
    SkyKey(top: Hue(r: 0.06, g: 0.08, b: 0.16), horizon: Hue(r: 0.12, g: 0.14, b: 0.24), light: 0.08, warm: 0.0, lamp: 1.0, hour: 1.0)
]

struct GardenLook {
    var season: Int
    var key: SkyKey
    var w: Double
    var h: Double
    var horizon: Double { h * 0.46 }
    var light: Double { key.light }

    func lit(_ c: Hue, _ amount: Double = 1) -> Hue {
        c.mix(Hue(r: 0.07, g: 0.08, b: 0.14), (1 - (0.22 + light * 0.78 * amount)))
    }

    var ground: Hue {
        switch season {
        case 1: return lit(Hue(r: 0.50, g: 0.62, b: 0.34))
        case 2: return lit(Hue(r: 0.42, g: 0.55, b: 0.29))
        case 3: return lit(Hue(r: 0.62, g: 0.54, b: 0.32))
        default: return lit(Hue(r: 0.66, g: 0.63, b: 0.54))
        }
    }

    var hedge: Hue {
        switch season {
        case 1: return lit(Hue(r: 0.34, g: 0.50, b: 0.28))
        case 2: return lit(Hue(r: 0.24, g: 0.40, b: 0.22))
        case 3: return lit(Hue(r: 0.58, g: 0.42, b: 0.20))
        default: return lit(Hue(r: 0.44, g: 0.40, b: 0.34))
        }
    }
}

func paintSky(_ p: Leaf, _ look: GardenLook, seed: UInt64) {
    var rng = Chip(seed)
    let key = look.key
    let skyRect = CGRect(x: 0, y: 0, width: look.w, height: look.horizon + 4)
    let winterGrey = Hue(r: 0.72, g: 0.74, b: 0.76)
    let top = look.season == 0 ? key.top.mix(winterGrey, 0.35 * key.light) : key.top
    let hor = look.season == 0 ? key.horizon.mix(winterGrey, 0.3 * key.light) : key.horizon
    p.gradientRect(skyRect, top.al(0.92), hor.al(0.92))
    for _ in 0..<6 {
        let y = rng.r(look.h * 0.04, look.h * 0.34)
        washBand(p, from: y, to: y + rng.r(18, 40), hor.lt(0.25), strength: 0.12 + 0.1 * key.light, seed: rng.next())
    }
    let sunT = (key.hour - 5.5) / 14.5
    if sunT > 0 && sunT < 1 {
        let sx = look.w * (0.08 + sunT * 0.84)
        let sy = look.horizon - sin(sunT * Double.pi) * look.h * 0.36
        let r = look.w * 0.045
        p.radial(pt(sx, sy), r * 3.2, Hue(r: 1.0, g: 0.92, b: 0.70).al(0.5 * key.light), Hue(r: 1.0, g: 0.92, b: 0.70).al(0))
        let disc = lumpy(cx: sx, cy: sy, rx: r, ry: r, rough: 0.02, steps: 30, seed: seed &+ 3)
        p.shape(disc, Hue(r: 1.0, g: 0.75, b: 0.45).mix(Hue(r: 1.0, g: 0.97, b: 0.88), 1 - key.warm))
        penOutline(p, disc, weight: 1.6, colour: Pot.straw.dk(0.2).al(0.5), seed: seed &+ 4)
    }
    if key.light < 0.35 {
        let alpha = (0.35 - key.light) / 0.35
        for _ in 0..<70 {
            p.dot(rng.r(0, look.w), rng.r(0, look.horizon * 0.85), rng.r(0.6, 1.6), Pot.white.al(0.3 * alpha + 0.5 * alpha * rng.d()))
        }
        let moonT = ((key.hour + 4).truncatingRemainder(dividingBy: 24)) / 10
        if moonT >= 0 && moonT <= 1 {
            let mx = look.w * (0.9 - moonT * 0.8)
            let my = look.horizon - sin(moonT * Double.pi) * look.h * 0.3
            let r = look.w * 0.026
            p.dot(mx, my, r, Hue(r: 0.94, g: 0.93, b: 0.86).al(alpha))
            p.dot(mx + r * 0.5, my - r * 0.35, r * 0.9, top.al(alpha * 0.95))
            p.radial(pt(mx, my), r * 4, Pot.white.al(0.12 * alpha), Pot.white.al(0))
        }
    } else if look.season != 0 {
        for k in 0..<5 {
            let x = rng.r(look.w * 0.3, look.w * 0.9), y = rng.r(look.h * 0.08, look.h * 0.24)
            let s = rng.r(6, 11)
            pen(p, [pt(x - s, y), pt(x, y + s * 0.5), pt(x + s, y)], weight: 1.6, colour: Pot.ink.al(0.55 * key.light), wobble: 0.3, taper: true, seed: seed &+ UInt64(k + 300))
        }
    }
}

func paintHedge(_ p: Leaf, _ look: GardenLook, seed: UInt64) {
    var rng = Chip(seed)
    var ring: [CGPoint] = [pt(-20, look.horizon + 10)]
    var x = -20.0
    while x < look.w + 20 {
        let bump = look.h * rng.r(0.05, 0.11)
        let step = look.w * rng.r(0.05, 0.10)
        ring.append(pt(x + step * 0.5, look.horizon - bump))
        ring.append(pt(x + step, look.horizon - look.h * 0.05))
        x += step
    }
    ring.append(pt(look.w + 20, look.horizon + 10))
    let tone = look.hedge
    wash(p, ring, tone, strength: 0.72, bleed: 5, seed: seed &+ 1)
    let body = pathOf(ring)
    if look.season == 0 {
        p.inside(body) {
            for k in 0..<260 {
                let tx = rng.r(0, look.w), ty = rng.r(look.horizon - look.h * 0.12, look.horizon)
                let twig = stemRun(pt(tx, ty + 20), -Double.pi / 2 + rng.r(-0.6, 0.6), rng.r(14, 40), curve: rng.r(-0.8, 0.8), wobble: 0.15, steps: 4, seed: seed &+ UInt64(k * 3))
                pen(p, twig, weight: 1.2, colour: Pot.woodDark.al(0.6 * (0.4 + look.light * 0.6)), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 5 + 1))
            }
        }
    } else {
        crossHatch(p, body, depth: 2, spacing: 6, colour: tone.dk(0.5).al(0.7), seed: seed &+ 2)
        p.inside(body) {
            for k in 0..<180 {
                let lx = rng.r(0, look.w), ly = rng.r(look.horizon - look.h * 0.14, look.horizon)
                blade(p, base: pt(lx, ly), angle: rng.r(-2.6, -0.5), length: rng.r(8, 16), width: rng.r(4, 8), tone: tone.lt(rng.r(0, 0.25)), serrate: 0, curl: 0, veins: 0, seed: seed &+ UInt64(k * 7))
            }
        }
    }
    penOutline(p, ring, weight: 2.2, colour: Pot.ink.al(0.5 + 0.3 * (1 - look.light)), seed: seed &+ 3)
    let treeX = look.w * 0.56, treeY = look.horizon - look.h * 0.06
    let trunk = stemRun(pt(treeX, treeY + 10), -Double.pi / 2 + 0.05, look.h * 0.16, curve: -0.2, wobble: 0.03, steps: 6, seed: seed &+ 40)
    stem(p, trunk, w0: look.w * 0.014, w1: look.w * 0.008, tone: look.lit(Pot.woodDark), woody: true, seed: seed &+ 41)
    let crownC = pt(treeX + look.w * 0.01, treeY - look.h * 0.20)
    if look.season == 0 {
        for k in 0..<14 {
            let a = -Double.pi / 2 + rng.r(-1.4, 1.4)
            let branch = stemRun(pt(Double(crownC.x), Double(crownC.y) + look.h * 0.06), a, rng.r(look.h * 0.05, look.h * 0.12), curve: rng.r(-0.6, 0.6), wobble: 0.1, steps: 5, seed: seed &+ UInt64(k * 3 + 50))
            pen(p, branch, weight: 2.2, colour: look.lit(Pot.woodDark), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 5 + 51))
        }
    } else {
        let crownTone: Hue = look.season == 3 ? look.lit(Hue(r: 0.78, g: 0.48, b: 0.20)) : (look.season == 1 ? look.lit(Hue(r: 0.45, g: 0.60, b: 0.32)) : look.lit(Hue(r: 0.28, g: 0.44, b: 0.24)))
        let crown = lumpy(cx: Double(crownC.x), cy: Double(crownC.y), rx: look.w * 0.075, ry: look.h * 0.11, rough: 0.10, steps: 36, seed: seed &+ 60)
        wash(p, crown, crownTone, strength: 0.7, bleed: 6, seed: seed &+ 61)
        crossHatch(p, pathOf(crown), depth: 2, spacing: 6, colour: crownTone.dk(0.5).al(0.6), seed: seed &+ 62)
        penOutline(p, crown, weight: 2, colour: Pot.ink.al(0.6), seed: seed &+ 63)
        if look.season == 1 {
            p.inside(pathOf(crown)) {
                for _ in 0..<60 { p.dot(Double(crownC.x) + rng.r(-look.w * 0.07, look.w * 0.07), Double(crownC.y) + rng.r(-look.h * 0.1, look.h * 0.1), rng.r(2, 4), Pot.white.al(0.8)) }
            }
        }
        if look.season == 3 {
            for _ in 0..<40 {
                let lx = rng.r(look.w * 0.45, look.w * 0.7), ly = rng.r(look.horizon + 4, look.h * 0.6)
                blade(p, base: pt(lx, ly), angle: rng.r(0, 6.2), length: rng.r(6, 11), width: rng.r(4, 7), tone: Hue(r: 0.80, g: 0.50, b: 0.22).lt(rng.r(0, 0.2)), serrate: 0, curl: 0, veins: 0, seed: seed &+ UInt64(Int(lx) + 700))
            }
        }
    }
    let fenceTone = look.lit(Hue(r: 0.50, g: 0.42, b: 0.30))
    let fy = look.horizon
    pen(p, [pt(look.w * 0.30, fy - look.h * 0.028), pt(look.w * 0.68, fy - look.h * 0.028)], weight: 3, colour: fenceTone, wobble: 0.5, taper: false, seed: seed &+ 80)
    pen(p, [pt(look.w * 0.30, fy - look.h * 0.006), pt(look.w * 0.68, fy - look.h * 0.006)], weight: 3, colour: fenceTone, wobble: 0.5, taper: false, seed: seed &+ 81)
    for k in 0..<7 {
        let x = look.w * (0.30 + Double(k) * 0.0633)
        let post = [pt(x - 5, fy - look.h * 0.05), pt(x + 5, fy - look.h * 0.05), pt(x + 5, fy + 4), pt(x - 5, fy + 4)]
        p.shape(post, fenceTone)
        penEdge(p, post, weight: 1.4, colour: Pot.ink.al(0.6), seed: seed &+ UInt64(k + 90))
    }
}

func paintShed(_ p: Leaf, _ look: GardenLook, seed: UInt64) {
    var rng = Chip(seed)
    let w = look.w, h = look.h
    let x0 = w * 0.05, x1 = w * 0.28
    let eave = h * 0.27, peak = h * 0.15, bottom = look.horizon + h * 0.01
    let wall = look.lit(Hue(r: 0.46, g: 0.35, b: 0.24))
    let wallShade = look.lit(Hue(r: 0.30, g: 0.22, b: 0.15))
    let front = [pt(x0, eave), pt(x0 + (x1 - x0) * 0.66, eave), pt(x0 + (x1 - x0) * 0.66, bottom), pt(x0, bottom)]
    let side = [pt(x0 + (x1 - x0) * 0.66, eave), pt(x1, eave), pt(x1, bottom), pt(x0 + (x1 - x0) * 0.66, bottom)]
    wash(p, front, wall, strength: 0.8, bleed: 3, seed: seed)
    wash(p, side, wallShade, strength: 0.85, bleed: 3, seed: seed &+ 1)
    crossHatch(p, pathOf(side), depth: 2, spacing: 6, colour: Pot.shadowInk.al(0.6), seed: seed &+ 2)
    for k in 0..<7 {
        let y = eave + (bottom - eave) * Double(k) / 7
        pen(p, [pt(x0, y), pt(x1, y)], weight: 1.4, colour: Pot.shadowInk.al(0.35), wobble: 0.5, taper: false, seed: seed &+ UInt64(k + 10))
    }
    let roof = [pt(x0 - w * 0.02, eave), pt((x0 + x1) / 2, peak), pt(x1 + w * 0.02, eave)]
    let roofTone = look.lit(Hue(r: 0.34, g: 0.30, b: 0.28))
    wash(p, roof, roofTone, strength: 0.85, bleed: 3, seed: seed &+ 20)
    crossHatch(p, pathOf(roof), depth: 1, spacing: 7, colour: Pot.shadowInk.al(0.5), seed: seed &+ 21)
    if look.season == 0 {
        let snow = [pt(x0 - w * 0.02, eave), pt((x0 + x1) / 2, peak), pt(x1 + w * 0.02, eave), pt(x1 + w * 0.01, eave - 6), pt((x0 + x1) / 2, peak - 8), pt(x0 - w * 0.01, eave - 6)]
        wash(p, snow, Pot.white, strength: 0.9, bleed: 4, seed: seed &+ 22)
        wash(p, [pt(x0 - w * 0.02, eave), pt((x0 + x1) / 2, peak), pt(x1 + w * 0.02, eave), pt((x0 + x1) / 2, peak + h * 0.05)], Pot.white, strength: 0.75, bleed: 5, seed: seed &+ 23)
    }
    penEdge(p, roof + [pt(x1 + w * 0.02, eave + 4), pt(x0 - w * 0.02, eave + 4)], weight: 3, colour: Pot.ink.al(0.85), seed: seed &+ 24)
    penEdge(p, front, weight: 2.4, colour: Pot.ink.al(0.8), seed: seed &+ 25)
    penEdge(p, side, weight: 2.4, colour: Pot.ink.al(0.8), seed: seed &+ 26)
    let door = [pt(x0 + (x1 - x0) * 0.12, eave + (bottom - eave) * 0.30), pt(x0 + (x1 - x0) * 0.34, eave + (bottom - eave) * 0.30), pt(x0 + (x1 - x0) * 0.34, bottom), pt(x0 + (x1 - x0) * 0.12, bottom)]
    wash(p, door, look.lit(Hue(r: 0.22, g: 0.16, b: 0.11)), strength: 0.9, bleed: 2, seed: seed &+ 30)
    penEdge(p, door, weight: 2, colour: Pot.ink.al(0.8), seed: seed &+ 31)
    p.dot(x0 + (x1 - x0) * 0.31, eave + (bottom - eave) * 0.66, 3.5, Pot.straw)
    let win = [pt(x0 + (x1 - x0) * 0.44, eave + (bottom - eave) * 0.28), pt(x0 + (x1 - x0) * 0.62, eave + (bottom - eave) * 0.28), pt(x0 + (x1 - x0) * 0.62, eave + (bottom - eave) * 0.54), pt(x0 + (x1 - x0) * 0.44, eave + (bottom - eave) * 0.54)]
    let glass = look.key.top.mix(Hue(r: 0.55, g: 0.62, b: 0.68), 0.5).mix(Hue(r: 1.0, g: 0.80, b: 0.45), look.key.lamp)
    wash(p, win, glass, strength: 0.95, bleed: 1.5, seed: seed &+ 40)
    let wx = (Double(win[0].x) + Double(win[1].x)) / 2, wy = (Double(win[0].y) + Double(win[2].y)) / 2
    pen(p, [pt(wx, Double(win[0].y)), pt(wx, Double(win[2].y))], weight: 2, colour: wallShade, wobble: 0.2, taper: false, seed: seed &+ 41)
    pen(p, [pt(Double(win[0].x), wy), pt(Double(win[1].x), wy)], weight: 2, colour: wallShade, wobble: 0.2, taper: false, seed: seed &+ 42)
    penEdge(p, win, weight: 2, colour: Pot.ink.al(0.8), seed: seed &+ 43)
    if look.key.lamp > 0.05 {
        p.radial(pt(wx, wy), (x1 - x0) * 0.45, Hue(r: 1.0, g: 0.78, b: 0.40).al(0.42 * look.key.lamp), Hue(r: 1.0, g: 0.78, b: 0.40).al(0))
    }
    for k in 0..<2 {
        let tx = x1 + w * (0.012 + Double(k) * 0.016)
        pen(p, [pt(tx, bottom), pt(tx + w * 0.02, eave + (bottom - eave) * (0.35 - Double(k) * 0.06))], weight: 5, colour: look.lit(Hue(r: 0.45, g: 0.36, b: 0.26)), wobble: 0.3, taper: false, seed: seed &+ UInt64(k + 50))
    }
    p.egg(x1 + w * 0.034, eave + (bottom - eave) * 0.29, 9, 5, look.lit(Pot.inkSoft))
    _ = rng.d()
}

func paintColdFrame(_ p: Leaf, _ look: GardenLook, seed: UInt64) {
    let w = look.w, h = look.h
    let x0 = w * 0.70, x1 = w * 0.94
    let back = look.horizon - h * 0.075, front = look.horizon - h * 0.03, base = look.horizon + h * 0.012
    let frame = look.lit(Hue(r: 0.55, g: 0.45, b: 0.30))
    let side = [pt(x0, base), pt(x0, back), pt(x1, front), pt(x1, base)]
    wash(p, side, frame, strength: 0.85, bleed: 2, seed: seed)
    crossHatch(p, pathOf(side), depth: 1, spacing: 5, colour: Pot.shadowInk.al(0.4), seed: seed &+ 1)
    penEdge(p, side, weight: 2.2, colour: Pot.ink.al(0.8), seed: seed &+ 2)
    let glass = [pt(x0 + w * 0.006, back + h * 0.004), pt(x1 - w * 0.006, front + h * 0.002), pt(x1 - w * 0.006, front + h * 0.02), pt(x0 + w * 0.006, back + h * 0.026)]
    let reflect = look.key.top.mix(Pot.white, 0.35 * look.light)
    wash(p, glass, reflect, strength: 0.9, bleed: 1.5, seed: seed &+ 3)
    if look.season == 0 {
        wash(p, glass, Pot.white, strength: 0.5, bleed: 2, seed: seed &+ 4)
    }
    pen(p, [pt(x0 + w * 0.05, back + h * 0.006), pt(x0 + w * 0.10, back + h * 0.02)], weight: 2, colour: Pot.white.al(0.6 * look.light), wobble: 0.2, taper: true, seed: seed &+ 5)
    penEdge(p, glass, weight: 2, colour: Pot.ink.al(0.75), seed: seed &+ 6)
    pen(p, [pt((x0 + x1) / 2, (back + front) / 2 + h * 0.003), pt((x0 + x1) / 2, (back + front) / 2 + h * 0.023)], weight: 2.5, colour: frame.dk(0.3), wobble: 0.2, taper: false, seed: seed &+ 7)
}

func paintGround(_ p: Leaf, _ look: GardenLook, seed: UInt64) {
    var rng = Chip(seed)
    let w = look.w, h = look.h
    let region = [pt(-10, look.horizon), pt(w + 10, look.horizon), pt(w + 10, h + 10), pt(-10, h + 10)]
    wash(p, region, look.ground, strength: 0.78, bleed: 4, seed: seed)
    let pathTone = look.lit(Hue(r: 0.72, g: 0.64, b: 0.46))
    washBand(p, from: look.horizon + h * 0.02, to: look.horizon + h * 0.05, pathTone, strength: 0.5, seed: seed &+ 1)
    let tuft = look.ground.mix(Hue(r: 0.2, g: 0.3, b: 0.14), look.season == 0 ? 0.15 : 0.4)
    for k in 0..<Int(w * 0.16) {
        let x = rng.r(0, w), y = rng.r(look.horizon, h)
        pen(p, [pt(x, y), pt(x + rng.r(-2, 2), y - rng.r(3, 8))], weight: rng.r(0.8, 1.5), colour: tuft.al(0.6), wobble: 0.3, taper: true, seed: seed &+ UInt64(k + 10))
    }
    if look.season == 0 {
        for _ in 0..<Int(w * 0.9) {
            p.dot(rng.r(0, w), rng.r(look.horizon, h), rng.r(0.8, 2.2), Pot.white.al(rng.r(0.3, 0.75)))
        }
        for k in 0..<7 {
            let cx = rng.r(0, w), cy = rng.r(look.horizon + 10, h)
            let patch = lumpy(cx: cx, cy: cy, rx: rng.r(30, 90), ry: rng.r(8, 20), rough: 0.2, steps: 20, seed: seed &+ UInt64(k + 200))
            wash(p, patch, Pot.white, strength: 0.6, bleed: 5, seed: seed &+ UInt64(k + 201))
        }
    }
    let compostX = w * 0.90, compostY = h * 0.60
    let boards = look.lit(Hue(r: 0.36, g: 0.28, b: 0.19))
    let bay = [pt(compostX - w * 0.05, compostY), pt(compostX + w * 0.05, compostY), pt(compostX + w * 0.05, compostY + h * 0.10), pt(compostX - w * 0.05, compostY + h * 0.10)]
    let heap = lumpy(cx: compostX, cy: compostY + h * 0.01, rx: w * 0.045, ry: h * 0.03, rough: 0.1, steps: 24, seed: seed &+ 300)
    wash(p, heap, look.lit(Hue(r: 0.26, g: 0.20, b: 0.13)), strength: 0.8, bleed: 3, seed: seed &+ 301)
    wash(p, bay, boards, strength: 0.85, bleed: 2, seed: seed &+ 302)
    for k in 0..<3 {
        let y = compostY + h * 0.03 * Double(k + 1)
        pen(p, [pt(compostX - w * 0.05, y), pt(compostX + w * 0.05, y)], weight: 1.6, colour: Pot.shadowInk.al(0.45), wobble: 0.4, taper: false, seed: seed &+ UInt64(k + 310))
    }
    penEdge(p, bay, weight: 2, colour: Pot.ink.al(0.75), seed: seed &+ 320)
    penOutline(p, heap, weight: 1.6, colour: Pot.ink.al(0.5), seed: seed &+ 321)
}

func nightVeil(_ p: Leaf, _ look: GardenLook) {
    let dark = max(0, 0.6 - look.light) / 0.6
    if dark > 0.02 {
        p.box(0, 0, look.w, look.h, Hue(r: 0.05, g: 0.06, b: 0.14).al(dark * 0.30))
    }
    if let g = CGGradient(colorsSpace: deviceRGB, colors: [cg(Pot.shadowInk.al(0)), cg(Pot.shadowInk.al(0.16 + dark * 0.2))] as CFArray, locations: [0.45, 1]) {
        p.ctx.drawRadialGradient(g, startCenter: CGPoint(x: look.w * 0.5, y: look.h * 0.45), startRadius: 0, endCenter: CGPoint(x: look.w * 0.5, y: look.h * 0.45), endRadius: max(look.w, look.h) * 0.85, options: [.drawsAfterEndLocation])
    }
}

func paintGarden(_ p: Leaf, _ look: GardenLook, seed: UInt64) {
    paintSky(p, look, seed: seed &+ 1)
    paintHedge(p, look, seed: seed &+ 2)
    paintShed(p, look, seed: seed &+ 3)
    paintColdFrame(p, look, seed: seed &+ 4)
    paintGround(p, look, seed: seed &+ 5)
}

func drawScenePlate(season: Int, slot: Int, dir: String) {
    let p = Leaf(1200, 714)
    let seed = hashOf("scene-\(season)-\(slot)")
    layPaper(p, seed: seed, tone: Pot.cream, laid: false)
    p.flipDown()
    p.light = -2.36
    let look = GardenLook(season: season, key: skySlots[slot], w: p.w, h: p.h)
    paintGarden(p, look, seed: seed)
    nightVeil(p, look)
    let names = ["wi", "sp", "su", "au"]
    p.writeJPG(dir, "pl_\(names[season])\(slot)")
}

func seasonCrops(_ season: Int) -> [(String, Double)] {
    switch season {
    case 1: return [("pea", 0.16), ("lettuce", 0.12), ("radish", 0.11), ("spinach", 0.12), ("onion", 0.13), ("carrot", 0.12)]
    case 2: return [("tomato", 0.18), ("zucchini", 0.16), ("bushbean", 0.14), ("corn", 0.18), ("cucumber", 0.15), ("basil", 0.12)]
    case 3: return [("pumpkin", 0.16), ("kale", 0.15), ("leek", 0.14), ("cabbage", 0.14), ("brussels", 0.16), ("beet", 0.12)]
    default: return [("garlic", 0.10), ("kale", 0.12), ("leek", 0.12)]
    }
}

func paintBeds(_ p: Leaf, _ look: GardenLook, season: Int, seed: UInt64, region: CGRect) {
    var rng = Chip(seed)
    let cols = 3, rows = 2
    let gapX = region.width * 0.05, gapY = region.height * 0.12
    let bw = (Double(region.width) - Double(gapX) * Double(cols - 1)) / Double(cols)
    let bh = (Double(region.height) - Double(gapY) * Double(rows - 1)) / Double(rows)
    let crops = seasonCrops(season)
    for k in 0..<(cols * rows) {
        let c = k % cols, r = k / cols
        let x = Double(region.minX) + Double(c) * (bw + Double(gapX))
        let y = Double(region.minY) + Double(r) * (bh + Double(gapY))
        let ring = [pt(x, y), pt(x + bw, y), pt(x + bw, y + bh), pt(x, y + bh)]
        wash(p, ring, look.lit(Pot.soil), strength: 0.8, bleed: 3, seed: seed &+ UInt64(k))
        grit(p, pathOf(ring), density: 0.006, sizeMin: 0.8, sizeMax: 2.0, colour: Pot.soilDark, seed: seed &+ UInt64(k + 20))
        if season == 0 {
            p.inside(pathOf(ring)) {
                for _ in 0..<Int(bw * bh / 60) { p.dot(rng.r(x, x + bw), rng.r(y, y + bh), rng.r(0.8, 2.0), Pot.white.al(rng.r(0.3, 0.8))) }
            }
        }
        penEdge(p, [pt(x - 4, y - 4), pt(x + bw + 4, y - 4), pt(x + bw + 4, y + bh + 4), pt(x - 4, y + bh + 4)], weight: 4, colour: look.lit(Hue(r: 0.55, g: 0.44, b: 0.30)), seed: seed &+ UInt64(k + 40))
        if season == 0 && k % 2 == 1 { continue }
        let (cropKey, scale) = crops[k % crops.count]
        let crop = Register.find(cropKey)
        let count = crop.perCell >= 9 ? 6 : (crop.perCell >= 4 ? 4 : 3)
        for j in 0..<count {
            let px = x + bw * (Double(j) + 0.5) / Double(count)
            let py = y + bh * (0.55 + rng.r(-0.15, 0.25))
            miniature(p, crop, at: pt(px, py), scale: scale * (0.85 + rng.r(0, 0.25)))
        }
    }
}

func drawSeasonPlate(_ season: Int, dir: String) {
    let p = Leaf(1200, 900)
    let seed = hashOf("season-\(season)")
    layPaper(p, seed: seed, tone: Pot.cream, laid: false)
    p.flipDown()
    p.light = -2.36
    let slot = [3, 1, 2, 3][season]
    let look = GardenLook(season: season, key: skySlots[slot], w: p.w, h: p.h * 0.86)
    paintGarden(p, look, seed: seed)
    paintBeds(p, look, season: season, seed: seed &+ 77, region: CGRect(x: p.w * 0.07, y: look.h * 0.53, width: p.w * 0.72, height: look.h * 0.42))
    nightVeil(p, look)
    p.box(0, p.h * 0.86, p.w, p.h * 0.14, Pot.creamWarm)
    layPaperStrip(p, y: p.h * 0.86, seed: seed &+ 9)
    let names = ["Winter", "Spring", "Summer", "Autumn"]
    let subs = ["Bare beds under frost, garlic rooting, kale standing under snow.",
                "Peas up, the first lettuce cut, onion sets and carrots in.",
                "Tomatoes staked, beans picked every other day, corn in a block.",
                "Pumpkins colouring, the brassicas sweetening, leeks for winter."]
    letter(p, names[season], at: p.w / 2, p.h * 0.86 + 52, size: 40, colour: Pot.ink, face: "Baskerville-Bold", align: .centre)
    letter(p, subs[season], at: p.w / 2, p.h * 0.86 + 94, size: 22, colour: Pot.inkSoft, face: "Baskerville-Italic", align: .centre)
    borderRule(p, inset: 22, seed: seed &+ 3)
    p.writeJPG(dir, "se_\(season)")
}

func layPaperStrip(_ p: Leaf, y: Double, seed: UInt64) {
    var rng = Chip(seed)
    for _ in 0..<Int(p.w * (p.h - y) / 900) {
        let fx = rng.r(0, p.w), fy = rng.r(y, p.h)
        let a = rng.r(0, 6.283), len = rng.r(3, 12)
        pen(p, [pt(fx, fy), pt(fx + cos(a) * len, fy + sin(a) * len)], weight: rng.r(0.5, 1.0), colour: Pot.cream.dk(0.2).al(rng.r(0.1, 0.35)), wobble: 0.2, taper: false, seed: rng.next())
    }
    pen(p, [pt(0, y), pt(p.w, y)], weight: 2.6, colour: Pot.ink.al(0.8), wobble: 0.6, taper: false, seed: seed &+ 5)
}

func drawPacket(_ p: Leaf, at c: CGPoint, w: Double, h: Double, crop: Crop, tilt: Double, seed: UInt64) {
    p.ctx.saveGState()
    p.ctx.translateBy(x: CGFloat(Double(c.x)), y: CGFloat(Double(c.y)))
    p.ctx.rotate(by: CGFloat(tilt))
    let ring = [pt(-w / 2, -h / 2), pt(w / 2, -h / 2), pt(w / 2, h / 2), pt(-w / 2, h / 2)]
    wash(p, ring, Pot.creamWarm.lt(0.3), strength: 0.95, bleed: 2, seed: seed)
    penEdge(p, ring, weight: 3, colour: Pot.ink, seed: seed &+ 1)
    let inner = [pt(-w / 2 + 12, -h / 2 + 12), pt(w / 2 - 12, -h / 2 + 12), pt(w / 2 - 12, h / 2 - 12), pt(-w / 2 + 12, h / 2 - 12)]
    penEdge(p, inner, weight: 1.2, colour: Pot.inkSoft, seed: seed &+ 2)
    pen(p, [pt(-w / 2, -h / 2 + h * 0.16), pt(w / 2, -h / 2 + h * 0.16)], weight: 1.4, colour: Pot.inkSoft, wobble: 0.3, taper: false, seed: seed &+ 3)
    letter(p, crop.name, at: 0, -h / 2 + h * 0.11, size: h * 0.075, colour: Pot.ink, face: "Baskerville-Bold", align: .centre)
    p.ctx.saveGState()
    p.ctx.translateBy(x: CGFloat(-plantX * (w / 900) * 0.9), y: CGFloat(-h / 2 + h * 0.2 - 210 * (h / 1200) * 0.9))
    p.ctx.scaleBy(x: CGFloat(w / 900 * 0.9), y: CGFloat(h / 1200 * 0.9))
    drawCropFigure(p, crop)
    p.ctx.restoreGState()
    p.ctx.restoreGState()
}

func drawOnboardPlate(_ k: Int, dir: String) {
    let p = Leaf(1200, 900)
    let seed = hashOf("onboard-\(k)")
    layPaper(p, seed: seed, tone: Pot.creamWarm)
    p.flipDown()
    p.light = -2.36
    borderRule(p, inset: 30, seed: seed &+ 3)
    var rng = Chip(seed &+ 9)
    switch k {
    case 0:
        soilBand(p, y: 640, depth: 110, x0: 120, x1: 1080, seed: seed &+ 20)
        for _ in 0..<500 { p.dot(rng.r(130, 1070), rng.r(628, 650), rng.r(0.8, 2.4), Pot.white.al(rng.r(0.4, 0.9))) }
        for k in 0..<3 {
            let x = 200.0 + Double(k) * 90
            for j in 0..<6 {
                let a = Double(j) / 6 * 2 * Double.pi
                pen(p, [pt(x, 200), pt(x + cos(a) * 26, 200 + sin(a) * 26)], weight: 2.2, colour: Pot.frostDeep.al(0.8), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 7 + j + 60))
            }
        }
        drawPacket(p, at: pt(480, 430), w: 300, h: 400, crop: Register.find("tomato"), tilt: -0.08, seed: seed &+ 30)
        drawPacket(p, at: pt(760, 470), w: 260, h: 350, crop: Register.find("pea"), tilt: 0.12, seed: seed &+ 31)
        seedVignette(p, at: pt(1000, 600), kind: "bean", tone: Pot.beet.mix(Pot.sepia, 0.4), seed: seed &+ 40)
        letter(p, "Everything counts from the frost", at: 600, 800, size: 34, colour: Pot.ink, face: "Baskerville-Bold", align: .centre)
    case 1:
        yearRuler(p, x0: 140, x1: 1060, y: 300, lastFrost: 0.25, firstFrost: 0.83, seed: seed)
        let bars: [(Double, Double, Hue, String)] = [(0.10, 0.21, Pot.leafPale, "peas direct"), (0.11, 0.19, Pot.tomato.lt(0.4), "tomatoes indoors"), (0.27, 0.31, Pot.tomato.lt(0.2), "tomatoes out"), (0.19, 0.24, Pot.carrot.lt(0.3), "carrots direct"), (0.29, 0.36, Pot.leaf.lt(0.2), "beans direct"), (0.60, 0.72, Pot.leafBlue.lt(0.2), "kale for autumn"), (0.72, 0.80, Pot.white.dk(0.15), "garlic in")]
        for (i, bar) in bars.enumerated() {
            cropBar(p, x0: 140, x1: 1060, y: 380 + Double(i) * 50, from: bar.0, to: bar.1, tone: bar.2, label: bar.3, seed: seed &+ UInt64(i + 40))
        }
        letter(p, "Sixty crops, each with its own bar on your year", at: 600, 800, size: 34, colour: Pot.ink, face: "Baskerville-Bold", align: .centre)
    case 2:
        bedBox(p, x: 160, y: 250, w: 880, h: 300, seed: seed)
        for k in 0...4 { pen(p, [pt(160 + Double(k) * 220, 250), pt(160 + Double(k) * 220, 550)], weight: 2, colour: Pot.strawPale.al(0.9), wobble: 0.4, taper: false, seed: seed &+ UInt64(k + 10)) }
        pen(p, [pt(160, 400), pt(1040, 400)], weight: 2, colour: Pot.strawPale.al(0.9), wobble: 0.4, taper: false, seed: seed &+ 20)
        miniature(p, Register.find("lettuce"), at: pt(270, 360), scale: 0.15)
        miniature(p, Register.find("carrot"), at: pt(490, 360), scale: 0.15)
        miniature(p, Register.find("tomato"), at: pt(710, 380), scale: 0.2)
        miniature(p, Register.find("bushbean"), at: pt(930, 370), scale: 0.15)
        wash(p, [pt(180, 470), pt(600, 470), pt(600, 486), pt(180, 486)], Pot.soilDark, strength: 0.6, bleed: 3, seed: seed &+ 30)
        for k in 0..<9 { p.dot(200 + Double(k) * 48, 478, 5, Pot.sepia); p.hoop(200 + Double(k) * 48, 478, 5, 1, Pot.ink.al(0.6)) }
        let hand = stemRun(pt(680, 520), Double.pi + 0.35, 100, curve: 0.2, wobble: 0.02, steps: 5, seed: seed &+ 40)
        pen(p, hand, weight: 10, colour: Pot.wood, wobble: 0.4, taper: true, seed: seed &+ 41)
        pen(p, [pt(140, 660), pt(1060, 660)], weight: 4, colour: Pot.ink, wobble: 0.5, taper: false, seed: seed &+ 50)
        for m in 0...12 {
            let x = 140 + 920 * Double(m) / 12
            pen(p, [pt(x, 650), pt(x, 670)], weight: 2, colour: Pot.ink, wobble: 0.3, taper: false, seed: seed &+ UInt64(m + 60))
        }
        let knob = ringOf(cx: 520, cy: 660, rx: 18, ry: 18, steps: 24)
        produce(p, knob, tone: Pot.terracotta, gloss: 0.5, seed: seed &+ 70)
        letter(p, "Drag, drill, and scrub the year", at: 600, 800, size: 34, colour: Pot.ink, face: "Baskerville-Bold", align: .centre)
    default:
        let look = GardenLook(season: 1, key: skySlots[1], w: p.w, h: p.h * 0.8)
        p.insideRect(CGRect(x: 40, y: 40, width: p.w - 80, height: p.h * 0.72)) {
            p.ctx.saveGState()
            p.ctx.translateBy(x: 40, y: 40)
            p.ctx.scaleBy(x: CGFloat((p.w - 80) / p.w), y: CGFloat((p.h * 0.72) / (p.h * 0.8)))
            paintGarden(p, look, seed: seed &+ 80)
            paintBeds(p, look, season: 1, seed: seed &+ 81, region: CGRect(x: p.w * 0.07, y: look.h * 0.53, width: p.w * 0.72, height: look.h * 0.42))
            p.ctx.restoreGState()
        }
        penEdge(p, [pt(40, 40), pt(p.w - 40, 40), pt(p.w - 40, 40 + p.h * 0.72), pt(40, 40 + p.h * 0.72)], weight: 3, colour: Pot.ink, seed: seed &+ 90)
        letter(p, "Set your frost dates and the plot begins", at: 600, 800, size: 34, colour: Pot.ink, face: "Baskerville-Bold", align: .centre)
    }
    p.writeJPG(dir, "ob_p\(k)")
}

func drawJar(_ p: Leaf, at c: CGPoint, w: Double, h: Double, fill: Hue, label: String, seed: UInt64) {
    var rng = Chip(seed)
    let x = Double(c.x), y = Double(c.y)
    let ring = [pt(x - w * 0.42, y - h * 0.42), pt(x + w * 0.42, y - h * 0.42), pt(x + w * 0.5, y - h * 0.34), pt(x + w * 0.5, y + h * 0.44), pt(x + w * 0.42, y + h * 0.5), pt(x - w * 0.42, y + h * 0.5), pt(x - w * 0.5, y + h * 0.44), pt(x - w * 0.5, y - h * 0.34)]
    let contents = [pt(x - w * 0.48, y - h * 0.2), pt(x + w * 0.48, y - h * 0.2), pt(x + w * 0.48, y + h * 0.42), pt(x - w * 0.48, y + h * 0.42)]
    wash(p, contents, fill, strength: 0.8, bleed: 3, seed: seed)
    p.inside(pathOf(contents)) {
        for _ in 0..<Int(w * h / 140) {
            let r = lumpy(cx: rng.r(x - w * 0.45, x + w * 0.45), cy: rng.r(y - h * 0.18, y + h * 0.4), rx: w * 0.09, ry: w * 0.07, rough: 0.1, steps: 12, seed: rng.next())
            p.shape(r, fill.dk(rng.r(0.05, 0.3)).al(0.7))
        }
    }
    wash(p, ring, Pot.glass, strength: 0.28, bleed: 2, seed: seed &+ 1)
    penEdge(p, ring, weight: 2.6, colour: Pot.ink.al(0.85), seed: seed &+ 2)
    pen(p, [pt(x - w * 0.36, y - h * 0.3), pt(x - w * 0.34, y + h * 0.3)], weight: 3, colour: Pot.white.al(0.6), wobble: 0.3, taper: true, seed: seed &+ 3)
    let lid = [pt(x - w * 0.46, y - h * 0.5), pt(x + w * 0.46, y - h * 0.5), pt(x + w * 0.46, y - h * 0.4), pt(x - w * 0.46, y - h * 0.4)]
    wash(p, lid, Pot.straw.dk(0.2), strength: 0.85, bleed: 1.5, seed: seed &+ 4)
    penEdge(p, lid, weight: 2, colour: Pot.ink.al(0.85), seed: seed &+ 5)
    let tag = [pt(x - w * 0.3, y - h * 0.05), pt(x + w * 0.3, y - h * 0.05), pt(x + w * 0.3, y + h * 0.15), pt(x - w * 0.3, y + h * 0.15)]
    wash(p, tag, Pot.creamWarm.lt(0.3), strength: 0.95, bleed: 1, seed: seed &+ 6)
    penEdge(p, tag, weight: 1.2, colour: Pot.ink.al(0.6), seed: seed &+ 7)
    letter(p, label, at: x, y + h * 0.085, size: h * 0.075, colour: Pot.ink, face: "Baskerville-Italic", align: .centre)
}

func drawCrate(_ p: Leaf, at c: CGPoint, w: Double, h: Double, produceTone: Hue, kind: String, seed: UInt64) {
    var rng = Chip(seed)
    let x = Double(c.x), y = Double(c.y)
    let ring = [pt(x - w / 2, y - h / 2), pt(x + w / 2, y - h / 2), pt(x + w / 2, y + h / 2), pt(x - w / 2, y + h / 2)]
    wash(p, ring, Pot.wood, strength: 0.7, bleed: 2, seed: seed)
    crossHatch(p, pathOf(ring), depth: 1, spacing: 5, colour: Pot.woodDark.al(0.5), seed: seed &+ 1)
    for k in 0..<3 {
        let yy = y - h / 2 + h * (Double(k) + 0.5) / 3
        pen(p, [pt(x - w / 2, yy), pt(x + w / 2, yy)], weight: 2, colour: Pot.woodDark.al(0.6), wobble: 0.4, taper: false, seed: seed &+ UInt64(k + 5))
    }
    penEdge(p, ring, weight: 2.6, colour: Pot.ink.al(0.85), seed: seed &+ 9)
    for k in 0..<Int(w / 22) {
        let px = x - w / 2 + 14 + Double(k) * 20 + rng.r(-4, 4)
        let py = y - h / 2 - 10 + rng.r(-8, 6)
        switch kind {
        case "carrot":
            fruitLong(p, from: pt(px, py - 4), to: pt(px + 6, py + 40), width: 13, tone: produceTone, taperEnd: 0.2, gloss: 0.3, seed: seed &+ UInt64(k * 3 + 20))
        case "potato":
            let ring2 = lumpy(cx: px, cy: py, rx: 15, ry: 11, rough: 0.06, steps: 18, seed: seed &+ UInt64(k * 3 + 20))
            produce(p, ring2, tone: produceTone, gloss: 0.15, seed: seed &+ UInt64(k * 3 + 21))
        default:
            fruitRound(p, at: pt(px, py), r: 14, tone: produceTone.lt(rng.r(0, 0.15)), rough: 0.03, gloss: 0.6, seed: seed &+ UInt64(k * 3 + 20))
        }
    }
}

func drawShelfPlate(_ k: Int, dir: String) {
    let p = Leaf(1200, 600)
    let seed = hashOf("shelf-\(k)")
    layPaper(p, seed: seed, tone: Pot.creamDeep.mix(Pot.wood, 0.25), laid: false)
    p.flipDown()
    p.light = -2.36
    var rng = Chip(seed &+ 5)
    let wall = [pt(0, 0), pt(p.w, 0), pt(p.w, p.h), pt(0, p.h)]
    wash(p, wall, Pot.creamDeep.dk(0.05), strength: 0.35, bleed: 4, seed: seed &+ 1)
    for kk in 0..<9 {
        let x = 60.0 + Double(kk) * 140
        pen(p, [pt(x, 0), pt(x + rng.r(-3, 3), p.h)], weight: 2, colour: Pot.woodDark.al(0.18), wobble: 0.6, taper: false, seed: seed &+ UInt64(kk + 10))
    }
    let shelfY = 470.0
    let board = [pt(0, shelfY), pt(p.w, shelfY), pt(p.w, shelfY + 34), pt(0, shelfY + 34)]
    wash(p, board, Pot.wood.dk(0.1), strength: 0.85, bleed: 2, seed: seed &+ 20)
    crossHatch(p, pathOf(board), depth: 1, spacing: 6, colour: Pot.woodDark.al(0.6), seed: seed &+ 21)
    pen(p, [pt(0, shelfY), pt(p.w, shelfY)], weight: 3, colour: Pot.ink.al(0.85), wobble: 0.4, taper: false, seed: seed &+ 22)
    pen(p, [pt(0, shelfY + 34), pt(p.w, shelfY + 34)], weight: 2.4, colour: Pot.ink.al(0.7), wobble: 0.4, taper: false, seed: seed &+ 23)
    for kk in 0..<3 {
        let x = 200.0 + Double(kk) * 400
        pen(p, [pt(x, shelfY + 34), pt(x - 30, shelfY + 90)], weight: 8, colour: Pot.woodDark, wobble: 0.4, taper: false, seed: seed &+ UInt64(kk + 30))
    }
    p.box(0, shelfY + 34, p.w, 20, Pot.shadowInk.al(0.18))
    switch k % 3 {
    case 0:
        drawJar(p, at: pt(180, 380), w: 110, h: 180, fill: Pot.tomato.lt(0.1), label: "passata", seed: seed &+ 40)
        drawJar(p, at: pt(330, 395), w: 100, h: 150, fill: Pot.leafPale.dk(0.1), label: "pickles", seed: seed &+ 41)
        drawCrate(p, at: pt(600, 410), w: 260, h: 110, produceTone: Pot.tomato, kind: "round", seed: seed &+ 42)
        drawJar(p, at: pt(860, 370), w: 120, h: 200, fill: Pot.pumpkin.lt(0.1), label: "chutney", seed: seed &+ 43)
        drawCrate(p, at: pt(1060, 415), w: 200, h: 100, produceTone: Pot.carrot, kind: "carrot", seed: seed &+ 44)
    case 1:
        drawCrate(p, at: pt(240, 410), w: 300, h: 110, produceTone: Pot.straw.mix(Pot.soilLight, 0.3), kind: "potato", seed: seed &+ 40)
        drawJar(p, at: pt(500, 385), w: 110, h: 170, fill: Pot.beet, label: "beets", seed: seed &+ 41)
        drawJar(p, at: pt(640, 400), w: 90, h: 140, fill: Pot.yellow.dk(0.1), label: "honey", seed: seed &+ 42)
        for j in 0..<3 {
            let x = 820.0 + Double(j) * 70
            pen(p, [pt(x, 40), pt(x + 4, 330)], weight: 3, colour: Pot.straw.dk(0.3), wobble: 0.5, taper: false, seed: seed &+ UInt64(j + 50))
            for m in 0..<5 {
                let yy = 120.0 + Double(m) * 42
                bulb(p, at: pt(x + Double(m % 2 == 0 ? -12 : 12), yy), rx: 22, ry: 20, tone: j == 1 ? Pot.white.dk(0.05) : Pot.straw.mix(Pot.terracotta, 0.25), striate: 5, neck: 0.5, seed: seed &+ UInt64(j * 7 + m + 60))
            }
        }
        drawCrate(p, at: pt(1080, 415), w: 180, h: 100, produceTone: Pot.leafDeep.lt(0.05), kind: "round", seed: seed &+ 44)
    default:
        let basket = [pt(140, 340), pt(420, 340), pt(400, 450), pt(160, 450)]
        wash(p, basket, Pot.straw.dk(0.15), strength: 0.8, bleed: 3, seed: seed &+ 40)
        crossHatch(p, pathOf(basket), depth: 2, spacing: 7, colour: Pot.woodDark.al(0.55), seed: seed &+ 41)
        penEdge(p, basket, weight: 2.6, colour: Pot.ink.al(0.85), seed: seed &+ 42)
        let handle = ringOf(cx: 280, cy: 340, rx: 120, ry: 90, steps: 30)
        pen(p, Array(handle[16...29]), weight: 7, colour: Pot.straw.dk(0.35), wobble: 0.5, taper: false, seed: seed &+ 43)
        for j in 0..<7 {
            fruitRound(p, at: pt(180 + Double(j) * 38, 322 + Double(j % 2) * 14), r: 20, tone: Pot.tomato.mix(Pot.yellow, Double(j % 3) * 0.2), rough: 0.03, gloss: 0.6, seed: seed &+ UInt64(j + 50))
        }
        drawJar(p, at: pt(560, 380), w: 120, h: 180, fill: Pot.leaf.lt(0.05), label: "beans", seed: seed &+ 60)
        drawJar(p, at: pt(720, 400), w: 90, h: 140, fill: Pot.tomato.mix(Pot.beet, 0.3), label: "jam", seed: seed &+ 61)
        let sack = lumpy(cx: 960, cy: 380, rx: 120, ry: 100, rough: 0.05, steps: 30, seed: seed &+ 70)
        wash(p, sack, Pot.strawPale.dk(0.2), strength: 0.85, bleed: 4, seed: seed &+ 71)
        crossHatch(p, pathOf(sack), depth: 2, spacing: 6, colour: Pot.sepia.al(0.4), seed: seed &+ 72)
        penOutline(p, sack, weight: 2.6, colour: Pot.ink.al(0.85), seed: seed &+ 73)
        for j in 0..<5 {
            let ring2 = lumpy(cx: 900 + Double(j) * 30, cy: 290 + Double(j % 2) * 16, rx: 20, ry: 14, rough: 0.06, steps: 18, seed: seed &+ UInt64(j * 3 + 80))
            produce(p, ring2, tone: Pot.straw.mix(Pot.soilLight, 0.3), gloss: 0.15, seed: seed &+ UInt64(j * 3 + 81))
        }
    }
    if k >= 3 {
        for j in 0..<6 {
            let x = 120.0 + Double(j) * 200
            let herb = stemRun(pt(x, 60), Double.pi / 2, 120, curve: 0, wobble: 0.02, steps: 6, seed: seed &+ UInt64(j + 90))
            pen(p, herb, weight: 3, colour: Pot.sepia, wobble: 0.3, taper: true, seed: seed &+ UInt64(j + 91))
            for m in 0..<8 {
                let q = along(herb, 0.2 + Double(m) * 0.1)
                blade(p, base: q, angle: Double.pi / 2 + Double(m % 2 == 0 ? -1.0 : 1.0), length: 26, width: 10, tone: Pot.leafGrey.dk(0.2), serrate: 0, curl: 0, veins: 0, seed: seed &+ UInt64(j * 13 + m + 100))
            }
        }
    }
    p.writeJPG(dir, "sh_\(k)")
}
