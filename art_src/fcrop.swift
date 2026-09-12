import Foundation
import CoreGraphics

let groundY = 790.0
let plantX = 450.0

func leafTone(_ crop: Crop) -> Hue {
    switch crop.key {
    case "kale", "cabbage", "broccoli", "cauliflower", "brussels", "kohlrabi", "rutabaga", "garlic", "onion", "leek", "fava":
        return Pot.leafBlue
    case "sage", "thyme", "rosemary", "eggplant":
        return Pot.leafGrey
    case "lettuce", "endive", "mizuna", "celery", "dill", "cilantro", "carrot", "fennel", "pea", "calendula", "nasturtium", "tomatillo", "arugula", "asparagus":
        return Pot.leafPale
    case "spinach", "rhubarb", "zucchini", "wintersquash", "pumpkin", "chard", "sunflower":
        return Pot.leafDeep.lt(0.12)
    default:
        return Pot.leaf
    }
}

func seedKind(_ crop: Crop) -> String {
    switch crop.key {
    case "bushbean", "polebean", "fava": return "bean"
    case "pea", "chickpea": return "pea"
    case "cucumber", "zucchini", "wintersquash", "pumpkin", "melon", "watermelon", "sunflower", "okra": return "flat"
    case "nasturtium", "beet", "chard", "corn", "spinach", "cilantro": return "disc"
    case "garlic": return "clove"
    case "potato": return "tuber"
    case "strawberry", "rhubarb", "asparagus", "mint", "chives": return "crown"
    case "sweetpotato", "rosemary", "thyme", "oregano", "sage": return "slip"
    default: return "fine"
    }
}

func isMonocot(_ crop: Crop) -> Bool {
    ["garlic", "onion", "leek", "scallion", "chives", "corn", "asparagus"].contains(crop.key)
}

func groundLine(_ p: Leaf, seed: UInt64, wide: Bool = true) {
    var rng = Chip(seed)
    let x0 = wide ? 150.0 : 250.0, x1 = wide ? 750.0 : 650.0
    let band = [pt(x0, groundY), pt(x1 - 20, groundY - 2), pt(x1, groundY + 6), pt(x1 - 30, groundY + 24), pt(x0 + 40, groundY + 22), pt(x0 - 10, groundY + 10)]
    wash(p, band, Pot.soilLight, strength: 0.26, bleed: 5, seed: seed)
    penBroken(p, [pt(x0, groundY), pt(x1, groundY)], weight: 2.2, colour: Pot.ink.al(0.7), pieces: 5, gap: 0.06, seed: seed &+ 3)
    for k in 0..<16 {
        let x = rng.r(x0, x1)
        pen(p, [pt(x, groundY + rng.r(3, 14)), pt(x + rng.r(4, 12), groundY + rng.r(3, 16))], weight: rng.r(0.8, 1.6), colour: Pot.soil.al(0.5), wobble: 0.5, taper: true, seed: seed &+ UInt64(k * 7 + 11))
    }
}

func cutawaySoil(_ p: Leaf, seed: UInt64) {
    soilBand(p, y: groundY, depth: 92, x0: 200, x1: 700, seed: seed)
}

func stakeLine(_ p: Leaf, x: Double, top: Double, seed: UInt64) {
    let spine = [pt(x, groundY + 30), pt(x + 3, top)]
    stem(p, spine, w0: 11, w1: 9, tone: Pot.wood, woody: true, seed: seed)
}

func mainStem(_ p: Leaf, top: Double, w0: Double, w1: Double, tone: Hue, curve: Double = -0.08, woody: Bool = false, seed: UInt64) -> [CGPoint] {
    let spine = stemRun(pt(plantX, groundY + 4), -Double.pi / 2, groundY - top, curve: curve, wobble: 0.015, steps: 12, seed: seed)
    stem(p, spine, w0: w0, w1: w1, tone: tone, woody: woody, seed: seed &+ 1)
    return spine
}

func along(_ spine: [CGPoint], _ t: Double) -> CGPoint {
    let fine = resample(spine, count: 40)
    return fine[max(0, min(39, Int(t * 39)))]
}

func drawFruitBushCrop(_ p: Leaf, _ crop: Crop, _ rng: inout Chip) {
    let seed = hashOf(crop.key)
    let tone = leafTone(crop)
    groundLine(p, seed: seed &+ 77)
    if crop.key == "tomato" || crop.key == "tomatillo" { stakeLine(p, x: plantX + 26, top: 250, seed: seed &+ 200) }
    let spine = mainStem(p, top: crop.key == "tomato" ? 270 : 330, w0: 15, w1: 8, tone: Pot.leaf.dk(0.15), curve: crop.key == "tomatillo" ? 0.25 : -0.06, woody: true, seed: seed)
    let leaves = crop.key == "eggplant" ? 6 : 8
    for k in 0..<leaves {
        let t = 0.22 + Double(k) / Double(leaves) * 0.72
        let q = along(spine, t)
        let side: Double = k % 2 == 0 ? -1 : 1
        let a = side > 0 ? -0.55 + rng.r(-0.2, 0.2) : -2.6 + rng.r(-0.2, 0.2)
        switch crop.key {
        case "tomato", "tomatillo":
            pinnateLeaf(p, base: q, angle: a, length: rng.r(150, 210), tone: tone, leaflets: 5, leafletSize: 60, serrate: 0.5, seed: seed &+ UInt64(k * 19 + 3))
        case "eggplant":
            blade(p, base: q, angle: a, length: rng.r(150, 190), width: 110, tone: tone, serrate: 0.15, curl: side * 0.15, veins: 5, seed: seed &+ UInt64(k * 19 + 3))
        default:
            blade(p, base: q, angle: a, length: rng.r(130, 175), width: 72, tone: tone, serrate: 0, curl: side * 0.12, veins: 4, seed: seed &+ UInt64(k * 19 + 3))
        }
    }
    switch crop.key {
    case "tomato":
        for k in 0..<3 {
            let q = along(spine, 0.45 + Double(k) * 0.16)
            let f = pt(Double(q.x) + (k % 2 == 0 ? -88 : 84), Double(q.y) + 50)
            pen(p, [q, pt((Double(q.x) + Double(f.x)) / 2, Double(f.y) - 36), f], weight: 3, colour: Pot.leaf.dk(0.4), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 7 + 90))
            fruitRound(p, at: f, r: 46 - Double(k) * 3, tone: k == 2 ? Pot.tomato.mix(Pot.yellow, 0.35) : Pot.tomato, rough: 0.03, gloss: 0.7, seed: seed &+ UInt64(k * 7 + 91))
            for j in 0..<5 {
                let a = Double(j) / 5 * 2 * .pi
                blade(p, base: pt(Double(f.x), Double(f.y) - 38 + Double(k) * 2), angle: a, length: 17, width: 7, tone: Pot.leafDeep, serrate: 0, curl: 0, veins: 0, seed: seed &+ UInt64(k * 5 + j + 200))
            }
        }
        let top = along(spine, 0.95)
        for j in 0..<5 {
            let a = Double(j) / 5 * 2 * .pi
            blade(p, base: pt(Double(top.x) + 26, Double(top.y) + 10), angle: a, length: 13, width: 7, tone: Pot.yellow, serrate: 0, curl: 0, veins: 0, seed: seed &+ UInt64(j + 300))
        }
    case "pepper":
        for k in 0..<3 {
            let q = along(spine, 0.5 + Double(k) * 0.17)
            let f = pt(Double(q.x) + (k % 2 == 0 ? -48 : 52), Double(q.y) + 30)
            pen(p, [q, f], weight: 3, colour: Pot.leaf.dk(0.4), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 7 + 90))
            let tone2 = k == 1 ? Pot.leaf.mix(Pot.yellow, 0.2) : Pot.tomato.mix(Pot.terracotta, 0.4)
            let ring = [pt(Double(f.x) - 22, Double(f.y)), pt(Double(f.x) - 26, Double(f.y) + 40), pt(Double(f.x) - 16, Double(f.y) + 92), pt(Double(f.x) + 2, Double(f.y) + 100), pt(Double(f.x) + 18, Double(f.y) + 88), pt(Double(f.x) + 26, Double(f.y) + 36), pt(Double(f.x) + 22, Double(f.y))]
            produce(p, resample(ring + [ring[0]], count: 40), tone: tone2, gloss: 0.75, seed: seed &+ UInt64(k * 9 + 91))
            p.inside(pathOf(ring)) {
                pen(p, [pt(Double(f.x) - 8, Double(f.y) + 4), pt(Double(f.x) - 12, Double(f.y) + 90)], weight: 2.2, colour: tone2.dk(0.35).al(0.5), wobble: 0.5, taper: true, seed: seed &+ UInt64(k + 400))
            }
            for j in 0..<4 {
                let a = Double(j) / 4 * 2 * .pi
                blade(p, base: pt(Double(f.x), Double(f.y)), angle: a, length: 14, width: 7, tone: Pot.leafDeep, serrate: 0, curl: 0, veins: 0, seed: seed &+ UInt64(k * 5 + j + 200))
            }
        }
    case "eggplant":
        for k in 0..<2 {
            let q = along(spine, 0.55 + Double(k) * 0.2)
            let f = pt(Double(q.x) + (k % 2 == 0 ? -56 : 60), Double(q.y) + 50)
            pen(p, [q, f], weight: 4, colour: Pot.leaf.dk(0.4), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 7 + 90))
            let ring = [pt(Double(f.x) - 20, Double(f.y)), pt(Double(f.x) - 32, Double(f.y) + 50), pt(Double(f.x) - 30, Double(f.y) + 100), pt(Double(f.x), Double(f.y) + 128), pt(Double(f.x) + 30, Double(f.y) + 100), pt(Double(f.x) + 32, Double(f.y) + 50), pt(Double(f.x) + 20, Double(f.y))]
            produce(p, resample(ring + [ring[0]], count: 40), tone: Pot.aubergine, gloss: 0.9, seed: seed &+ UInt64(k * 9 + 91))
            for j in 0..<5 {
                let a = Double(j) / 5 * 2 * .pi
                blade(p, base: pt(Double(f.x), Double(f.y) + 4), angle: a, length: 24, width: 10, tone: Pot.leafDeep, serrate: 0, curl: 0, veins: 0, seed: seed &+ UInt64(k * 5 + j + 200))
            }
        }
        daisy(p, at: pt(plantX + 70, 330), r: 26, petals: 6, petalTone: Hue(r: 0.62, g: 0.50, b: 0.75), centreTone: Pot.yellow, petalWidth: 0.5, seed: seed &+ 500)
    default:
        for k in 0..<3 {
            let q = along(spine, 0.5 + Double(k) * 0.17)
            let f = pt(Double(q.x) + (k % 2 == 0 ? -50 : 54), Double(q.y) + 34)
            pen(p, [q, f], weight: 3, colour: Pot.leaf.dk(0.4), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 7 + 90))
            let husk = [pt(Double(f.x), Double(f.y) - 8), pt(Double(f.x) - 34, Double(f.y) + 26), pt(Double(f.x) - 30, Double(f.y) + 64), pt(Double(f.x), Double(f.y) + 78), pt(Double(f.x) + 30, Double(f.y) + 64), pt(Double(f.x) + 34, Double(f.y) + 26)]
            produce(p, resample(husk + [husk[0]], count: 36), tone: Pot.strawPale.mix(Pot.leafPale, 0.4), gloss: 0.15, seed: seed &+ UInt64(k * 9 + 91))
            p.inside(pathOf(husk)) {
                fruitRound(p, at: pt(Double(f.x), Double(f.y) + 46), r: 22, tone: Pot.leaf.lt(0.2), rough: 0.02, gloss: 0.6, seed: seed &+ UInt64(k * 9 + 92))
                for j in 0..<5 {
                    let x = Double(f.x) - 24 + Double(j) * 12
                    pen(p, [pt(x, Double(f.y) + 4), pt(x + 2, Double(f.y) + 70)], weight: 1.4, colour: Pot.sepia.al(0.45), wobble: 0.5, taper: true, seed: seed &+ UInt64(j + k * 3 + 300))
                }
            }
        }
        daisy(p, at: pt(plantX - 60, 320), r: 20, petals: 5, petalTone: Pot.yellow, centreTone: Pot.sepia, petalWidth: 0.6, seed: seed &+ 500)
    }
}

func drawVineCrop(_ p: Leaf, _ crop: Crop, _ rng: inout Chip) {
    let seed = hashOf(crop.key)
    let tone = leafTone(crop)
    let climbing = ["pea", "polebean", "cucumber"].contains(crop.key)
    groundLine(p, seed: seed &+ 77)
    if climbing {
        let poleTop = crop.key == "cucumber" ? 300.0 : 250.0
        if crop.key == "pea" {
            for k in 0..<3 {
                let x = plantX - 30 + Double(k) * 30
                let twig = stemRun(pt(x, groundY + 20), -Double.pi / 2 + Double(k - 1) * 0.07, groundY - poleTop, curve: Double(k - 1) * 0.05, wobble: 0.03, steps: 8, seed: seed &+ UInt64(k * 41))
                stem(p, twig, w0: 7, w1: 3, tone: Pot.woodDark, woody: true, seed: seed &+ UInt64(k * 43))
            }
        } else {
            stakeLine(p, x: plantX, top: poleTop, seed: seed &+ 200)
        }
        let vine = stemRun(pt(plantX - 20, groundY + 4), -Double.pi / 2 - 0.25, groundY - poleTop - 10, curve: 0.55, wobble: 0.16, steps: 16, seed: seed)
        stem(p, vine, w0: 8, w1: 4, tone: Pot.leaf.dk(0.1), seed: seed &+ 1)
        let count = 7
        for k in 0..<count {
            let t = 0.15 + Double(k) / Double(count) * 0.8
            let q = along(vine, t)
            let side: Double = k % 2 == 0 ? -1 : 1
            let a = side > 0 ? -0.45 + rng.r(-0.25, 0.25) : -2.7 + rng.r(-0.25, 0.25)
            switch crop.key {
            case "pea":
                pinnateLeaf(p, base: q, angle: a, length: 90, tone: tone, leaflets: 4, leafletSize: 36, serrate: 0, seed: seed &+ UInt64(k * 19 + 3))
                let tendril = stemRun(pt(Double(q.x) + cos(a) * 90, Double(q.y) + sin(a) * 90), a, 60, curve: 5.0, wobble: 0.1, steps: 12, seed: seed &+ UInt64(k * 5 + 60))
                pen(p, tendril, weight: 1.6, colour: Pot.leaf.dk(0.3), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 5 + 61))
            case "cucumber":
                heartLeaf(p, at: pt(Double(q.x) + cos(a) * 60, Double(q.y) + sin(a) * 60), angle: a, size: rng.r(64, 84), tone: tone, lobes: 5, seed: seed &+ UInt64(k * 19 + 3))
                let tendril = stemRun(q, a + 0.6, 70, curve: 4.5, wobble: 0.1, steps: 12, seed: seed &+ UInt64(k * 5 + 60))
                pen(p, tendril, weight: 1.6, colour: Pot.leaf.dk(0.3), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 5 + 61))
            default:
                trifoliate(p, at: pt(Double(q.x) + cos(a) * 50, Double(q.y) + sin(a) * 50), angle: a, size: 62, tone: tone, seed: seed &+ UInt64(k * 19 + 3))
            }
        }
        for k in 0..<3 {
            let q = along(vine, 0.35 + Double(k) * 0.2)
            let side: Double = k % 2 == 0 ? 1 : -1
            let f0 = pt(Double(q.x) + side * 30, Double(q.y) + 10)
            switch crop.key {
            case "pea":
                podShape(p, from: f0, to: pt(Double(f0.x) + side * 34, Double(f0.y) + 104), width: 19, tone: Pot.leafPale.lt(0.1), beads: 6, seed: seed &+ UInt64(k * 9 + 91))
                daisy(p, at: pt(Double(q.x) - side * 34, Double(q.y) - 30), r: 16, petals: 4, petalTone: Pot.white, centreTone: Pot.leafPale, petalWidth: 0.6, seed: seed &+ UInt64(k + 500))
            case "cucumber":
                fruitLong(p, from: f0, to: pt(Double(f0.x) + side * 12, Double(f0.y) + 150), width: 40, tone: Pot.leafDeep.lt(0.08), taperEnd: 0.8, gloss: 0.5, seed: seed &+ UInt64(k * 9 + 91))
                daisy(p, at: pt(Double(q.x) - side * 36, Double(q.y) - 26), r: 17, petals: 5, petalTone: Pot.yellow, centreTone: Pot.yellow.dk(0.3), petalWidth: 0.6, seed: seed &+ UInt64(k + 500))
            default:
                podShape(p, from: f0, to: pt(Double(f0.x) + side * 10, Double(f0.y) + 140), width: 16, tone: Pot.leaf.lt(0.1), beads: 7, seed: seed &+ UInt64(k * 9 + 91))
            }
        }
    } else {
        let count = 5
        for k in 0..<count {
            let a = -Double.pi + Double(k) / Double(count - 1) * .pi
            let len = k == 2 ? 120.0 : 250.0
            let run = stemRun(pt(plantX, groundY - 10), a, len, curve: -(a + .pi / 2) * 0.35, wobble: 0.08, steps: 10, seed: seed &+ UInt64(k * 17))
            stem(p, run, w0: 9, w1: 5, tone: Pot.leaf.dk(0.15), seed: seed &+ UInt64(k * 17 + 1))
            let fine = resample(run, count: 5)
            for j in 1..<5 {
                let q = fine[j]
                let la = a + (j % 2 == 0 ? 0.9 : -0.9) + rng.r(-0.2, 0.2)
                heartLeaf(p, at: pt(Double(q.x) + cos(la) * 46, Double(q.y) + sin(la) * 40), angle: la, size: rng.r(58, 82) * (j == 4 ? 0.8 : 1), tone: j % 2 == 0 ? tone : tone.dk(0.08), lobes: crop.key == "watermelon" ? 7 : 5, seed: seed &+ UInt64(k * 19 + j * 3))
            }
            let tendril = stemRun(run[run.count - 1], a + 0.4, 50, curve: 5.5, wobble: 0.1, steps: 12, seed: seed &+ UInt64(k * 5 + 60))
            pen(p, tendril, weight: 1.6, colour: Pot.leaf.dk(0.3), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 5 + 61))
        }
        let fc = pt(plantX + 30, groundY - 80)
        switch crop.key {
        case "pumpkin":
            let ring = lumpy(cx: Double(fc.x), cy: Double(fc.y), rx: 118, ry: 88, rough: 0.02, steps: 40, seed: seed &+ 91)
            produce(p, ring, tone: Pot.pumpkin, gloss: 0.5, seed: seed &+ 91)
            p.inside(pathOf(ring)) {
                for k in 0..<6 {
                    let f = (Double(k) + 0.5) / 6 * 2 - 1
                    pen(p, [pt(Double(fc.x) + f * 90, Double(fc.y) - 80), pt(Double(fc.x) + f * 116, Double(fc.y)), pt(Double(fc.x) + f * 90, Double(fc.y) + 82)], weight: 3.0, colour: Pot.pumpkin.dk(0.5).al(0.6), wobble: 0.6, taper: true, seed: seed &+ UInt64(k * 5 + 300))
                }
            }
            stem(p, [pt(Double(fc.x) - 4, Double(fc.y) - 84), pt(Double(fc.x) + 10, Double(fc.y) - 118)], w0: 16, w1: 12, tone: Pot.leaf.dk(0.3), woody: true, seed: seed &+ 92)
        case "wintersquash":
            let ring = [pt(Double(fc.x) - 34, Double(fc.y) - 120), pt(Double(fc.x) - 40, Double(fc.y) - 40), pt(Double(fc.x) - 66, Double(fc.y) + 10), pt(Double(fc.x) - 60, Double(fc.y) + 70), pt(Double(fc.x), Double(fc.y) + 96), pt(Double(fc.x) + 60, Double(fc.y) + 70), pt(Double(fc.x) + 66, Double(fc.y) + 10), pt(Double(fc.x) + 40, Double(fc.y) - 40), pt(Double(fc.x) + 34, Double(fc.y) - 120)]
            produce(p, resample(ring + [ring[0]], count: 50), tone: Pot.strawPale.mix(Pot.terracotta, 0.35), gloss: 0.35, seed: seed &+ 91)
            stem(p, [pt(Double(fc.x), Double(fc.y) - 122), pt(Double(fc.x) + 6, Double(fc.y) - 150)], w0: 12, w1: 8, tone: Pot.leaf.dk(0.3), woody: true, seed: seed &+ 92)
        case "melon":
            let ring = lumpy(cx: Double(fc.x), cy: Double(fc.y), rx: 92, ry: 84, rough: 0.02, steps: 40, seed: seed &+ 91)
            produce(p, ring, tone: Pot.strawPale.mix(Pot.leafGrey, 0.3), gloss: 0.25, seed: seed &+ 91)
            p.inside(pathOf(ring)) {
                for k in 0..<160 {
                    let x = Double(fc.x) + rng.r(-92, 92), y = Double(fc.y) + rng.r(-84, 84)
                    let a = rng.r(0, 6.28)
                    pen(p, [pt(x, y), pt(x + cos(a) * 12, y + sin(a) * 12)], weight: 1.5, colour: Pot.strawPale.lt(0.3).al(0.85), wobble: 0.6, taper: true, seed: seed &+ UInt64(k + 700))
                }
            }
        case "watermelon":
            let ring = lumpy(cx: Double(fc.x), cy: Double(fc.y), rx: 130, ry: 84, rough: 0.015, steps: 40, seed: seed &+ 91)
            produce(p, ring, tone: Pot.leafDeep.lt(0.15), gloss: 0.5, seed: seed &+ 91)
            p.inside(pathOf(ring)) {
                for k in 0..<7 {
                    let x = Double(fc.x) - 110 + Double(k) * 36
                    pen(p, [pt(x, Double(fc.y) - 84), pt(x + 10, Double(fc.y) - 20), pt(x - 6, Double(fc.y) + 40), pt(x + 8, Double(fc.y) + 84)], weight: 13, colour: Pot.leafPale.lt(0.2).al(0.75), wobble: 2.0, taper: true, seed: seed &+ UInt64(k * 5 + 300))
                }
            }
        default:
            break
        }
        daisy(p, at: pt(plantX - 150, groundY - 200), r: 22, petals: 5, petalTone: Pot.yellow, centreTone: Pot.yellow.dk(0.35), petalWidth: 0.6, seed: seed &+ 500)
    }
}

func drawRootCrop(_ p: Leaf, _ crop: Crop, _ rng: inout Chip) {
    let seed = hashOf(crop.key)
    let tone = leafTone(crop)
    cutawaySoil(p, seed: seed &+ 77)
    let crown = pt(plantX, groundY - 4)
    switch crop.key {
    case "carrot":
        taproot(p, top: pt(plantX, groundY - 14), length: 100, width: 60, tone: Pot.carrot, rings: true, seed: seed &+ 5)
        for k in 0..<7 {
            let a = -Double.pi / 2 + Double(k - 3) * 0.30
            featheryLeaf(p, base: crown, angle: a, length: rng.r(300, 380), tone: k % 2 == 0 ? tone : tone.dk(0.1), fineness: 7, seed: seed &+ UInt64(k * 13))
        }
    case "parsnip":
        taproot(p, top: pt(plantX, groundY - 10), length: 100, width: 76, tone: Pot.strawPale.lt(0.3), rings: true, seed: seed &+ 5)
        for k in 0..<6 {
            let a = -Double.pi / 2 + Double(k) / 5 * 2.4 - 1.2
            pinnateLeaf(p, base: crown, angle: a, length: rng.r(220, 290), tone: k % 2 == 0 ? tone : tone.dk(0.08), leaflets: 6, leafletSize: 54, serrate: 0.5, seed: seed &+ UInt64(k * 13))
        }
    case "radish":
        let ring = lumpy(cx: plantX, cy: groundY + 22, rx: 44, ry: 46, rough: 0.02, steps: 32, seed: seed &+ 5)
        produce(p, ring, tone: Pot.tomato.mix(Pot.beet, 0.3), gloss: 0.6, seed: seed &+ 5)
        taproot(p, top: pt(plantX, groundY + 60), length: 50, width: 10, tone: Pot.white, seed: seed &+ 6)
        p.inside(pathOf(ring)) { p.egg(plantX, groundY + 62, 22, 10, Pot.white.al(0.7)) }
        for k in 0..<7 {
            let a = -Double.pi / 2 + Double(k - 3) * 0.3
            blade(p, base: crown, angle: a, length: rng.r(150, 200), width: 70, tone: k % 2 == 0 ? tone : tone.dk(0.1), serrate: 0.5, curl: Double(k - 3) * 0.06, veins: 5, seed: seed &+ UInt64(k * 13))
        }
    case "beet":
        let ring = lumpy(cx: plantX, cy: groundY + 30, rx: 58, ry: 56, rough: 0.02, steps: 32, seed: seed &+ 5)
        produce(p, ring, tone: Pot.beet, gloss: 0.5, seed: seed &+ 5)
        taproot(p, top: pt(plantX, groundY + 80), length: 40, width: 12, tone: Pot.beet, seed: seed &+ 6)
        for k in 0..<7 {
            let a = -Double.pi / 2 + Double(k - 3) * 0.28
            crinkleLeaf(p, base: crown, angle: a, length: rng.r(190, 250), width: 88, tone: k % 2 == 0 ? Pot.leafDeep.lt(0.15) : Pot.leaf, seed: seed &+ UInt64(k * 13))
            pen(p, [crown, pt(plantX + cos(a) * 120, groundY - 4 + sin(a) * 120)], weight: 4, colour: Pot.beet.lt(0.2).al(0.85), wobble: 0.5, taper: true, seed: seed &+ UInt64(k * 3 + 400))
        }
    case "turnip":
        let ring = lumpy(cx: plantX, cy: groundY + 14, rx: 66, ry: 50, rough: 0.02, steps: 32, seed: seed &+ 5)
        produce(p, ring, tone: Pot.white.dk(0.05), gloss: 0.5, seed: seed &+ 5)
        p.inside(pathOf(ring)) { wash(p, [pt(plantX - 70, groundY - 40), pt(plantX + 70, groundY - 40), pt(plantX + 66, groundY - 2), pt(plantX - 66, groundY - 2)], Pot.aubergine.lt(0.2), strength: 0.6, bleed: 5, seed: seed &+ 8) }
        taproot(p, top: pt(plantX, groundY + 60), length: 44, width: 10, tone: Pot.white, seed: seed &+ 6)
        for k in 0..<7 {
            let a = -Double.pi / 2 + Double(k - 3) * 0.3
            blade(p, base: crown, angle: a, length: rng.r(170, 230), width: 64, tone: k % 2 == 0 ? tone : tone.dk(0.1), serrate: 0.7, curl: Double(k - 3) * 0.05, veins: 5, seed: seed &+ UInt64(k * 13))
        }
    case "rutabaga":
        let ring = lumpy(cx: plantX, cy: groundY + 22, rx: 70, ry: 62, rough: 0.025, steps: 32, seed: seed &+ 5)
        produce(p, ring, tone: Pot.straw.mix(Pot.strawPale, 0.5), gloss: 0.3, seed: seed &+ 5)
        p.inside(pathOf(ring)) { wash(p, [pt(plantX - 74, groundY - 44), pt(plantX + 74, groundY - 44), pt(plantX + 70, groundY + 6), pt(plantX - 70, groundY + 6)], Pot.aubergine.lt(0.1), strength: 0.55, bleed: 6, seed: seed &+ 8) }
        taproot(p, top: pt(plantX, groundY + 80), length: 34, width: 14, tone: Pot.strawPale, seed: seed &+ 6)
        for k in 0..<6 {
            let a = -Double.pi / 2 + Double(k) / 5 * 2.0 - 1.0
            blade(p, base: pt(plantX, groundY - 30), angle: a, length: rng.r(180, 240), width: 80, tone: k % 2 == 0 ? tone : tone.dk(0.1), serrate: 0.2, curl: 0, veins: 5, seed: seed &+ UInt64(k * 13))
        }
    default:
        break
    }
}

func drawBulbCrop(_ p: Leaf, _ crop: Crop, _ rng: inout Chip) {
    let seed = hashOf(crop.key)
    let tone = leafTone(crop)
    switch crop.key {
    case "garlic":
        cutawaySoil(p, seed: seed &+ 77)
        bulb(p, at: pt(plantX, groundY + 44), rx: 56, ry: 50, tone: Pot.white.dk(0.04), striate: 6, neck: 0.5, seed: seed &+ 5)
        for k in 0..<7 {
            let a = -Double.pi / 2 + Double(k - 3) * 0.16
            strapLeaf(p, base: pt(plantX, groundY - 10), angle: a, length: rng.r(300, 420), width: 22, tone: k % 2 == 0 ? tone : tone.dk(0.1), curve: Double(k - 3) * 0.12, fold: true, seed: seed &+ UInt64(k * 13))
        }
        let scape = stemRun(pt(plantX + 4, groundY - 10), -Double.pi / 2 + 0.1, 380, curve: 0.9, wobble: 0.02, steps: 14, seed: seed &+ 90)
        pen(p, scape, weight: 5, colour: tone.dk(0.2), wobble: 0.4, taper: true, seed: seed &+ 91)
        let tip = scape[scape.count - 1]
        blade(p, base: tip, angle: 0.6, length: 44, width: 14, tone: Pot.strawPale.mix(tone, 0.4), serrate: 0, curl: 0.3, veins: 1, seed: seed &+ 92)
    case "onion":
        cutawaySoil(p, seed: seed &+ 77)
        bulb(p, at: pt(plantX, groundY + 40), rx: 62, ry: 58, tone: Pot.straw.mix(Pot.terracotta, 0.25), striate: 7, neck: 0.4, seed: seed &+ 5)
        for k in 0..<8 {
            let a = -Double.pi / 2 + (Double(k) - 3.5) * 0.15
            strapLeaf(p, base: pt(plantX, groundY - 14), angle: a, length: rng.r(300, 400), width: 20, tone: k % 2 == 0 ? tone : tone.dk(0.1), curve: (Double(k) - 3.5) * 0.10, fold: false, seed: seed &+ UInt64(k * 13))
        }
    case "kohlrabi":
        groundLine(p, seed: seed &+ 77)
        let ring = lumpy(cx: plantX, cy: groundY - 70, rx: 84, ry: 74, rough: 0.02, steps: 36, seed: seed &+ 5)
        produce(p, ring, tone: Pot.leafPale.mix(Pot.leafGrey, 0.5), gloss: 0.35, seed: seed &+ 5)
        for k in 0..<7 {
            let a = -Double.pi / 2 + Double(k - 3) * 0.32
            let base = pt(plantX + cos(a) * 60, groundY - 70 + sin(a) * 60)
            let leafBase = pt(plantX + cos(a) * 150, groundY - 70 + sin(a) * 140)
            stem(p, [base, leafBase], w0: 9, w1: 6, tone: tone.dk(0.1), seed: seed &+ UInt64(k * 7))
            blade(p, base: leafBase, angle: a, length: rng.r(130, 170), width: 90, tone: k % 2 == 0 ? tone : tone.dk(0.1), serrate: 0.2, curl: 0, veins: 5, seed: seed &+ UInt64(k * 13))
        }
        for k in 0..<5 {
            let a = 0.3 + Double(k) * 0.6
            let base = pt(plantX + cos(a) * 70, groundY - 70 + sin(a) * 62)
            pen(p, [base, pt(Double(base.x) + cos(a) * 30, Double(base.y) + sin(a) * 30)], weight: 3, colour: Pot.strawPale.dk(0.4), wobble: 0.5, taper: true, seed: seed &+ UInt64(k + 300))
        }
    case "fennel":
        groundLine(p, seed: seed &+ 77)
        let ring = [pt(plantX - 66, groundY - 10), pt(plantX - 74, groundY - 90), pt(plantX - 50, groundY - 160), pt(plantX, groundY - 176), pt(plantX + 50, groundY - 160), pt(plantX + 74, groundY - 90), pt(plantX + 66, groundY - 10)]
        produce(p, resample(ring + [ring[0]], count: 40), tone: Pot.white.dk(0.06).mix(Pot.leafPale, 0.25), gloss: 0.3, seed: seed &+ 5)
        p.inside(pathOf(ring)) {
            for k in 0..<7 {
                let f = (Double(k) + 0.5) / 7 * 2 - 1
                pen(p, [pt(plantX + f * 60, groundY - 20), pt(plantX + f * 40, groundY - 170)], weight: 3.4, colour: Pot.leafPale.dk(0.4).al(0.55), wobble: 0.5, taper: true, seed: seed &+ UInt64(k * 5 + 300))
            }
        }
        for k in 0..<7 {
            let a = -Double.pi / 2 + Double(k - 3) * 0.24
            let base = pt(plantX + Double(k - 3) * 14, groundY - 168)
            let st = stemRun(base, a, 130, curve: Double(k - 3) * 0.1, wobble: 0.02, steps: 6, seed: seed &+ UInt64(k * 9))
            stem(p, st, w0: 7, w1: 4, tone: Pot.leafPale.dk(0.15), seed: seed &+ UInt64(k * 9 + 1))
            featheryLeaf(p, base: st[st.count - 1], angle: a, length: rng.r(160, 230), tone: k % 2 == 0 ? tone : tone.dk(0.08), fineness: 6, seed: seed &+ UInt64(k * 13))
        }
    default:
        break
    }
}

func drawLeafyCrop(_ p: Leaf, _ crop: Crop, _ rng: inout Chip) {
    let seed = hashOf(crop.key)
    let tone = leafTone(crop)
    groundLine(p, seed: seed &+ 77)
    switch crop.key {
    case "kale":
        let spine = mainStem(p, top: 430, w0: 22, w1: 14, tone: Pot.leafBlue.dk(0.2), woody: true, seed: seed)
        for k in 0..<9 {
            let t = 0.3 + Double(k) / 9 * 0.7
            let q = along(spine, t)
            let side: Double = k % 2 == 0 ? -1 : 1
            let a = side > 0 ? -0.55 + Double(k) * 0.05 : -2.6 - Double(k) * 0.05
            crinkleLeaf(p, base: q, angle: a, length: rng.r(200, 260) * (1 - t * 0.35), width: 96, tone: k % 3 == 0 ? tone.dk(0.1) : tone, seed: seed &+ UInt64(k * 13))
        }
        for k in 0..<4 {
            let a = -Double.pi / 2 + (Double(k) - 1.5) * 0.5
            crinkleLeaf(p, base: along(spine, 0.98), angle: a, length: 150, width: 70, tone: tone.lt(0.1), seed: seed &+ UInt64(k * 13 + 900))
        }
        for k in 0..<6 {
            let t = 0.05 + Double(k) * 0.045
            let q = along(spine, t)
            pen(p, [q, pt(Double(q.x) + (k % 2 == 0 ? -18 : 18), Double(q.y) - 8)], weight: 3.5, colour: Pot.leafBlue.dk(0.5), wobble: 0.4, taper: true, seed: seed &+ UInt64(k + 500))
        }
    case "chard":
        for k in 0..<7 {
            let a = -Double.pi / 2 + Double(k - 3) * 0.28
            let base = pt(plantX + Double(k - 3) * 8, groundY - 2)
            let stalkEnd = pt(plantX + cos(a) * 150, groundY - 2 + sin(a) * 150)
            let stalkTone = k % 2 == 0 ? Pot.tomato.mix(Pot.terracotta, 0.3) : Pot.yellow.mix(Pot.terracotta, 0.2)
            stem(p, [base, stalkEnd], w0: 20, w1: 12, tone: stalkTone, seed: seed &+ UInt64(k * 7))
            crinkleLeaf(p, base: stalkEnd, angle: a, length: rng.r(220, 290), width: 150, tone: k % 2 == 0 ? tone : tone.dk(0.08), seed: seed &+ UInt64(k * 13))
        }
    case "spinach":
        for k in 0..<10 {
            let a = -Double.pi / 2 + (Double(k) - 4.5) * 0.3
            let stalk = pt(plantX + cos(a) * 60, groundY - 6 + sin(a) * 40)
            pen(p, [pt(plantX, groundY - 4), stalk], weight: 6, colour: Pot.leafPale.dk(0.2), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 7))
            roundLeaf(p, at: stalk, angle: a, size: rng.r(120, 170), tone: k % 2 == 0 ? tone : tone.dk(0.1), aspect: 0.66, seed: seed &+ UInt64(k * 13))
        }
    case "arugula":
        for k in 0..<11 {
            let a = -Double.pi / 2 + Double(k - 5) * 0.27
            let len = rng.r(180, 260)
            let ring = lobedRing(at: pt(plantX + cos(a) * len * 0.5, groundY - 4 + sin(a) * len * 0.5), angle: a, size: len * 0.5, lobes: 7, depth: 0.45, aspect: 1.9, seed: seed &+ UInt64(k * 5))
            wash(p, ring, k % 2 == 0 ? tone : tone.dk(0.1), strength: 0.56, bleed: 3, seed: seed &+ UInt64(k * 13))
            roundShade(p, ring, inset: 20, depth: 2, spacing: 3, colour: tone.dk(0.42), seed: seed &+ UInt64(k * 13 + 1))
            pen(p, [pt(plantX, groundY - 4), pt(plantX + cos(a) * len, groundY - 4 + sin(a) * len)], weight: 3, colour: tone.dk(0.5), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 13 + 2))
            penOutline(p, ring, weight: 1.6, colour: tone.dk(0.6), seed: seed &+ UInt64(k * 13 + 3))
        }
        let flowerStem = stemRun(pt(plantX + 10, groundY - 20), -Double.pi / 2 + 0.15, 330, curve: -0.2, wobble: 0.02, steps: 8, seed: seed &+ 600)
        pen(p, flowerStem, weight: 4, colour: tone.dk(0.3), wobble: 0.4, taper: true, seed: seed &+ 601)
        for k in 0..<4 {
            let q = along(flowerStem, 0.7 + Double(k) * 0.1)
            daisy(p, at: pt(Double(q.x) + Double(k % 2 == 0 ? -22 : 22), Double(q.y)), r: 15, petals: 4, petalTone: Pot.white, centreTone: Pot.yellow, petalWidth: 0.55, seed: seed &+ UInt64(k + 700))
        }
    case "mizuna":
        for k in 0..<13 {
            let a = -Double.pi / 2 + Double(k - 6) * 0.24
            let len = rng.r(200, 300)
            let spine = stemRun(pt(plantX, groundY - 4), a, len, curve: Double(k - 6) * 0.05, wobble: 0.02, steps: 8, seed: seed &+ UInt64(k * 5))
            pen(p, spine, weight: 4, colour: Pot.white.dk(0.15), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 13 + 2))
            let fine = resample(spine, count: 8)
            for j in 2..<8 {
                let q = fine[j]
                for side in [-1.0, 1.0] {
                    blade(p, base: q, angle: a + side * 1.1, length: 26 + Double(j) * 3, width: 12, tone: k % 2 == 0 ? tone : tone.dk(0.1), serrate: 0.8, curl: side * 0.3, veins: 1, seed: seed &+ UInt64(k * 31 + j * 3))
                }
            }
        }
    case "rhubarb":
        for k in 0..<5 {
            let a = -Double.pi / 2 + Double(k - 2) * 0.4
            let base = pt(plantX + Double(k - 2) * 12, groundY - 2)
            let stalkEnd = pt(plantX + cos(a) * 260, groundY - 2 + sin(a) * 260)
            stem(p, [base, stalkEnd], w0: 26, w1: 16, tone: Pot.tomato.mix(Pot.beet, 0.3).lt(0.1), seed: seed &+ UInt64(k * 7))
            heartLeaf(p, at: pt(Double(stalkEnd.x) + cos(a) * 110, Double(stalkEnd.y) + sin(a) * 110), angle: a, size: rng.r(120, 150), tone: k % 2 == 0 ? tone : tone.dk(0.08), lobes: 5, seed: seed &+ UInt64(k * 13))
        }
    default:
        break
    }
}

func drawHeadCrop(_ p: Leaf, _ crop: Crop, _ rng: inout Chip) {
    let seed = hashOf(crop.key)
    let tone = leafTone(crop)
    groundLine(p, seed: seed &+ 77)
    let c = pt(plantX, groundY - 150)
    switch crop.key {
    case "lettuce":
        sideRosette(p, crown: pt(plantX, groundY - 8), radius: 300, tone: Pot.leafPale, layers: 3, crinkle: true, seed: seed &+ 5)
    case "endive":
        for layer in 0..<3 {
            let count = 10 + layer * 4
            for k in 0..<count {
                let a = Double(k) / Double(count) * 2 * .pi + Double(layer) * 0.3
                let r = 220.0 - Double(layer) * 60
                let spine = stemRun(pt(plantX, groundY - 100), a, r, curve: 0.2, wobble: 0.04, steps: 8, seed: seed &+ UInt64(layer * 100 + k))
                pen(p, spine, weight: 3, colour: Pot.leafPale.lt(0.2 + Double(layer) * 0.15).dk(0.2), wobble: 0.4, taper: true, seed: seed &+ UInt64(layer * 100 + k + 1))
                let fine = resample(spine, count: 6)
                for j in 1..<6 {
                    for side in [-1.0, 1.0] {
                        let len = 22.0 + Double(j) * 3
                        pen(p, [fine[j], pt(Double(fine[j].x) + cos(a + side * 1.0) * len, Double(fine[j].y) + sin(a + side * 1.0) * len)], weight: 2.4, colour: Pot.leafPale.lt(Double(layer) * 0.2), wobble: 0.6, taper: true, seed: seed &+ UInt64(layer * 300 + k * 7 + j))
                    }
                }
            }
        }
    case "cabbage":
        sideRosette(p, crown: pt(plantX, groundY - 8), radius: 250, tone: Pot.leafBlue, layers: 1, crinkle: false, seed: seed &+ 5)
        let head = lumpy(cx: plantX, cy: groundY - 190, rx: 165, ry: 150, rough: 0.02, steps: 40, seed: seed &+ 9)
        produce(p, head, tone: Pot.leafBlue.lt(0.25), gloss: 0.3, seed: seed &+ 9)
        p.inside(pathOf(head)) {
            for k in 0..<5 {
                let a0 = Double(k) * 1.3
                var arc: [CGPoint] = []
                for j in 0..<12 {
                    let a = a0 + Double(j) / 11 * 2.6
                    let r = 44.0 + Double(k) * 26
                    arc.append(pt(plantX + cos(a) * r, groundY - 190 + sin(a) * r * 0.9))
                }
                pen(p, arc, weight: 3, colour: Pot.leafBlue.dk(0.4).al(0.6), wobble: 0.8, taper: true, seed: seed &+ UInt64(k * 7 + 300))
            }
        }
        for k in 0..<2 {
            let a = -Double.pi / 2 + (k == 0 ? -0.9 : 0.9)
            blade(p, base: pt(plantX + (k == 0 ? -70 : 70), groundY - 20), angle: a - (k == 0 ? 0.55 : -0.55), length: 250, width: 170, tone: Pot.leafBlue.lt(0.05), serrate: 0.1, curl: (k == 0 ? 0.6 : -0.6), veins: 4, seed: seed &+ UInt64(k * 13 + 700))
        }
    case "broccoli", "cauliflower":
        let spine = mainStem(p, top: groundY - 170, w0: 30, w1: 26, tone: Pot.leafBlue.dk(0.05), seed: seed)
        for k in 0..<6 {
            let a = -Double.pi / 2 + (Double(k) - 2.5) * 0.5
            let base = along(spine, 0.5 + Double(k % 3) * 0.15)
            blade(p, base: base, angle: a, length: rng.r(200, 260), width: 110, tone: k % 2 == 0 ? tone : tone.dk(0.1), serrate: 0.2, curl: (Double(k) - 2.5) * 0.1, veins: 5, seed: seed &+ UInt64(k * 13))
        }
        let headTone = crop.key == "broccoli" ? Pot.leafDeep.lt(0.05) : Pot.white.dk(0.03)
        let head = lumpy(cx: plantX, cy: groundY - 240, rx: 120, ry: 84, rough: 0.05, steps: 40, seed: seed &+ 9)
        produce(p, head, tone: headTone, gloss: 0.2, seed: seed &+ 9)
        p.inside(pathOf(head)) {
            for k in 0..<(crop.key == "broccoli" ? 420 : 240) {
                let x = plantX + rng.r(-120, 120), y = groundY - 240 + rng.r(-84, 84)
                p.dot(x, y, rng.r(2, 5), (crop.key == "broccoli" ? headTone.dk(rng.r(0, 0.4)) : headTone.dk(rng.r(0, 0.15))).al(0.6))
                if k % 3 == 0 { p.dot(x - 1, y - 1, rng.r(1, 2), headTone.lt(0.4).al(0.7)) }
            }
        }
    case "bokchoy":
        for k in 0..<9 {
            let a = -Double.pi / 2 + Double(k - 4) * 0.2
            let base = pt(plantX + Double(k - 4) * 9, groundY - 4)
            let end = pt(plantX + cos(a) * 170, groundY - 4 + sin(a) * 170)
            stem(p, [base, end], w0: 30, w1: 20, tone: Pot.white.dk(0.04).mix(Pot.leafPale, 0.2), seed: seed &+ UInt64(k * 7))
            blade(p, base: pt(Double(end.x) - cos(a) * 30, Double(end.y) - sin(a) * 30), angle: a, length: rng.r(150, 190), width: 110, tone: k % 2 == 0 ? Pot.leafDeep.lt(0.1) : Pot.leaf, serrate: 0.05, curl: 0, veins: 5, seed: seed &+ UInt64(k * 13))
        }
    default:
        _ = c
    }
}

func drawBushCrop(_ p: Leaf, _ crop: Crop, _ rng: inout Chip) {
    let seed = hashOf(crop.key)
    let tone = leafTone(crop)
    groundLine(p, seed: seed &+ 77)
    if crop.key == "zucchini" {
        for k in 0..<6 {
            let a = -Double.pi / 2 + (Double(k) - 2.5) * 0.5
            let st = stemRun(pt(plantX, groundY - 10), a, rng.r(180, 240), curve: 0, wobble: 0.02, steps: 6, seed: seed &+ UInt64(k * 9))
            stem(p, st, w0: 16, w1: 10, tone: Pot.leafPale.dk(0.1), seed: seed &+ UInt64(k * 9 + 1))
            heartLeaf(p, at: pt(Double(st[st.count - 1].x) + cos(a) * 90, Double(st[st.count - 1].y) + sin(a) * 90), angle: a, size: rng.r(110, 140), tone: k % 2 == 0 ? tone : tone.dk(0.08), lobes: 5, seed: seed &+ UInt64(k * 13))
        }
        fruitLong(p, from: pt(plantX - 40, groundY - 24), to: pt(plantX + 190, groundY - 12), width: 54, tone: Pot.leafDeep, taperEnd: 0.75, gloss: 0.6, seed: seed &+ 91)
        let flowerBase = pt(plantX - 130, groundY - 60)
        for j in 0..<5 {
            blade(p, base: flowerBase, angle: -2.2 + Double(j) * 0.35, length: 70, width: 26, tone: j % 2 == 0 ? Pot.yellow : Pot.yellow.mix(Pot.pumpkin, 0.3), serrate: 0, curl: 0, veins: 1, seed: seed &+ UInt64(j + 500))
        }
    } else {
        let spine = mainStem(p, top: groundY - 260, w0: 12, w1: 7, tone: Pot.leaf.dk(0.1), seed: seed)
        for k in 0..<7 {
            let t = 0.25 + Double(k) / 7 * 0.72
            let q = along(spine, t)
            let side: Double = k % 2 == 0 ? -1 : 1
            let a = side > 0 ? -0.5 + rng.r(-0.2, 0.2) : -2.65 + rng.r(-0.2, 0.2)
            let st = stemRun(q, a, 60, curve: 0, wobble: 0.02, steps: 4, seed: seed &+ UInt64(k * 9))
            pen(p, st, weight: 3.5, colour: tone.dk(0.3), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 9 + 1))
            trifoliate(p, at: st[st.count - 1], angle: a, size: rng.r(60, 80), tone: k % 2 == 0 ? tone : tone.dk(0.08), seed: seed &+ UInt64(k * 13))
        }
        for k in 0..<5 {
            let q = along(spine, 0.35 + Double(k) * 0.12)
            let side: Double = k % 2 == 0 ? 1 : -1
            podShape(p, from: pt(Double(q.x) + side * 14, Double(q.y) + 10), to: pt(Double(q.x) + side * 34, Double(q.y) + 120), width: 14, tone: Pot.leaf.lt(0.15), beads: 6, seed: seed &+ UInt64(k * 9 + 91))
        }
        daisy(p, at: along(spine, 0.9), r: 14, petals: 5, petalTone: Pot.white, centreTone: Pot.leafPale, petalWidth: 0.6, seed: seed &+ 500)
    }
}

func drawTallCrop(_ p: Leaf, _ crop: Crop, _ rng: inout Chip) {
    let seed = hashOf(crop.key)
    let tone = leafTone(crop)
    groundLine(p, seed: seed &+ 77)
    switch crop.key {
    case "corn":
        let spine = mainStem(p, top: 330, w0: 26, w1: 12, tone: Pot.leafPale.dk(0.1), seed: seed)
        for k in 0..<8 {
            let t = 0.15 + Double(k) / 8 * 0.7
            let q = along(spine, t)
            let side: Double = k % 2 == 0 ? -1 : 1
            strapLeaf(p, base: q, angle: side > 0 ? -0.9 : -2.25, length: rng.r(220, 300), width: 44, tone: k % 2 == 0 ? tone : tone.dk(0.1), curve: side * 0.9, fold: true, seed: seed &+ UInt64(k * 13))
        }
        let top = along(spine, 0.99)
        for k in 0..<7 {
            let a = -Double.pi / 2 + Double(k - 3) * 0.3
            let tassel = stemRun(top, a, rng.r(90, 130), curve: Double(k - 3) * 0.15, wobble: 0.04, steps: 6, seed: seed &+ UInt64(k * 5 + 60))
            pen(p, tassel, weight: 3, colour: Pot.straw.dk(0.2), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 5 + 61))
            for j in 0..<6 {
                let q = along(tassel, Double(j) / 6 + 0.1)
                p.dot(Double(q.x) + rng.r(-6, 6), Double(q.y) + rng.r(-4, 4), 2.2, Pot.straw.dk(0.35).al(0.8))
            }
        }
        let earBase = along(spine, 0.5)
        let ear = [pt(Double(earBase.x) + 8, Double(earBase.y) - 40), pt(Double(earBase.x) + 44, Double(earBase.y) - 60), pt(Double(earBase.x) + 74, Double(earBase.y) - 20), pt(Double(earBase.x) + 70, Double(earBase.y) + 90), pt(Double(earBase.x) + 44, Double(earBase.y) + 130), pt(Double(earBase.x) + 14, Double(earBase.y) + 100)]
        produce(p, resample(ear + [ear[0]], count: 36), tone: Pot.leafPale.dk(0.05), gloss: 0.3, seed: seed &+ 91)
        let kernels = [pt(Double(earBase.x) + 36, Double(earBase.y) - 50), pt(Double(earBase.x) + 62, Double(earBase.y) - 30), pt(Double(earBase.x) + 62, Double(earBase.y) + 30), pt(Double(earBase.x) + 36, Double(earBase.y) + 34)]
        produce(p, resample(kernels + [kernels[0]], count: 24), tone: Pot.yellow, gloss: 0.5, seed: seed &+ 92)
        p.inside(pathOf(kernels)) {
            for r in 0..<6 { for c in 0..<3 { p.dot(Double(earBase.x) + 42 + Double(c) * 9, Double(earBase.y) - 44 + Double(r) * 13, 3.6, Pot.yellow.dk(0.25).al(0.7)) } }
        }
        for k in 0..<7 {
            let silk = stemRun(pt(Double(earBase.x) + 50, Double(earBase.y) - 58), -Double.pi / 2 + rng.r(-0.6, 0.6), rng.r(40, 70), curve: rng.r(-0.8, 0.8), wobble: 0.1, steps: 5, seed: seed &+ UInt64(k * 3 + 700))
            pen(p, silk, weight: 1.4, colour: Pot.straw.mix(Pot.terracotta, 0.3), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 3 + 701))
        }
    case "fava":
        let spine = mainStem(p, top: 260, w0: 16, w1: 9, tone: Pot.leafBlue.dk(0.15), seed: seed)
        for k in 0..<8 {
            let t = 0.2 + Double(k) / 8 * 0.75
            let q = along(spine, t)
            for side in [-1.0, 1.0] {
                let a = side > 0 ? -0.4 : -2.75
                let st = stemRun(q, a, 60, curve: 0, wobble: 0.02, steps: 3, seed: seed &+ UInt64(k * 9))
                pen(p, st, weight: 3.5, colour: tone.dk(0.3), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 9 + 1))
                for j in 0..<2 {
                    roundLeaf(p, at: pt(Double(st[st.count - 1].x) + cos(a) * Double(j) * 46, Double(st[st.count - 1].y) + sin(a) * Double(j) * 46), angle: a + (j == 0 ? side * 0.6 : 0), size: 54, tone: k % 2 == 0 ? tone : tone.dk(0.08), aspect: 0.55, seed: seed &+ UInt64(k * 13 + j))
                }
            }
        }
        for k in 0..<3 {
            let q = along(spine, 0.32 + Double(k) * 0.15)
            let side: Double = k % 2 == 0 ? 1 : -1
            podShape(p, from: pt(Double(q.x) + side * 12, Double(q.y)), to: pt(Double(q.x) + side * 30, Double(q.y) - 110), width: 30, tone: Pot.leaf.lt(0.05), beads: 4, seed: seed &+ UInt64(k * 9 + 91))
        }
        for k in 0..<3 {
            let q = along(spine, 0.62 + Double(k) * 0.12)
            let side: Double = k % 2 == 0 ? -1 : 1
            blade(p, base: pt(Double(q.x) + side * 10, Double(q.y)), angle: side > 0 ? -0.3 : -2.8, length: 30, width: 18, tone: Pot.white, serrate: 0, curl: 0, veins: 0, seed: seed &+ UInt64(k + 500))
            p.dot(Double(q.x) + side * 24, Double(q.y) - 6, 5, Pot.ink.al(0.8))
        }
    case "okra":
        let spine = mainStem(p, top: 250, w0: 18, w1: 9, tone: Pot.leaf.dk(0.15), woody: true, seed: seed)
        for k in 0..<5 {
            let t = 0.2 + Double(k) / 5 * 0.7
            let q = along(spine, t)
            let side: Double = k % 2 == 0 ? -1 : 1
            let a = side > 0 ? -0.6 : -2.55
            let st = stemRun(q, a, 90, curve: 0, wobble: 0.02, steps: 4, seed: seed &+ UInt64(k * 9))
            stem(p, st, w0: 8, w1: 5, tone: tone.dk(0.15), seed: seed &+ UInt64(k * 9 + 1))
            let ring = lobedRing(at: pt(Double(st[st.count - 1].x) + cos(a) * 60, Double(st[st.count - 1].y) + sin(a) * 60), angle: a, size: rng.r(80, 100), lobes: 5, depth: 0.5, seed: seed &+ UInt64(k * 13))
            wash(p, ring, k % 2 == 0 ? tone : tone.dk(0.08), strength: 0.56, bleed: 4, seed: seed &+ UInt64(k * 13 + 1))
            roundShade(p, ring, inset: 30, depth: 2, spacing: 3.5, colour: tone.dk(0.42), seed: seed &+ UInt64(k * 13 + 2))
            penOutline(p, ring, weight: 1.6, colour: tone.dk(0.6), seed: seed &+ UInt64(k * 13 + 3))
        }
        for k in 0..<4 {
            let q = along(spine, 0.45 + Double(k) * 0.13)
            let side: Double = k % 2 == 0 ? 1 : -1
            let podRing = bandOf([pt(Double(q.x), Double(q.y)), pt(Double(q.x) + side * 40, Double(q.y) - 60), pt(Double(q.x) + side * 62, Double(q.y) - 120)], [22, 14, 4], per: 8)
            produce(p, podRing, tone: Pot.leaf.lt(0.1), gloss: 0.3, seed: seed &+ UInt64(k * 9 + 91))
            p.inside(pathOf(podRing)) {
                for j in 0..<3 {
                    pen(p, [pt(Double(q.x) + Double(j - 1) * 6, Double(q.y)), pt(Double(q.x) + side * 60 + Double(j - 1) * 3, Double(q.y) - 116)], weight: 1.6, colour: Pot.leaf.dk(0.45).al(0.6), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 7 + j + 300))
                }
            }
        }
        daisy(p, at: pt(plantX + 80, 330), r: 40, petals: 5, petalTone: Pot.yellow.lt(0.2), centreTone: Pot.beet, petalWidth: 0.7, seed: seed &+ 500)
    case "brussels":
        let spine = mainStem(p, top: 400, w0: 30, w1: 20, tone: Pot.leafBlue.dk(0.15), woody: true, seed: seed)
        for k in 0..<12 {
            let t = 0.15 + Double(k) / 12 * 0.7
            let q = along(spine, t)
            let side: Double = k % 2 == 0 ? -1 : 1
            fruitRound(p, at: pt(Double(q.x) + side * 24, Double(q.y)), r: 17, tone: Pot.leafBlue.lt(0.15), rough: 0.06, gloss: 0.3, seed: seed &+ UInt64(k * 9 + 91))
            pen(p, [pt(Double(q.x) + side * 22, Double(q.y) + 6), pt(Double(q.x) + side * 60, Double(q.y) + 20)], weight: 3.5, colour: Pot.leafBlue.dk(0.4), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 7 + 200))
        }
        for k in 0..<7 {
            let a = -Double.pi / 2 + Double(k - 3) * 0.42
            blade(p, base: along(spine, 0.97), angle: a, length: rng.r(160, 210), width: 110, tone: k % 2 == 0 ? tone : tone.dk(0.1), serrate: 0.1, curl: Double(k - 3) * 0.08, veins: 5, seed: seed &+ UInt64(k * 13))
        }
    default:
        break
    }
}

func drawStalkCrop(_ p: Leaf, _ crop: Crop, _ rng: inout Chip) {
    let seed = hashOf(crop.key)
    let tone = leafTone(crop)
    switch crop.key {
    case "leek":
        cutawaySoil(p, seed: seed &+ 77)
        let shank = bandOf([pt(plantX, groundY + 100), pt(plantX, groundY - 80)], [40, 46, 48], per: 4)
        produce(p, shank, tone: Pot.white.dk(0.02), gloss: 0.25, seed: seed &+ 5)
        p.inside(pathOf(shank)) {
            for k in 0..<5 {
                pen(p, [pt(plantX - 18 + Double(k) * 9, groundY + 96), pt(plantX - 18 + Double(k) * 9, groundY - 78)], weight: 1.8, colour: Pot.leafPale.dk(0.3).al(0.5), wobble: 0.4, taper: true, seed: seed &+ UInt64(k + 300))
            }
        }
        for k in 0..<8 {
            let side: Double = k % 2 == 0 ? -1 : 1
            let a = -Double.pi / 2 + side * (0.25 + Double(k / 2) * 0.18)
            strapLeaf(p, base: pt(plantX + side * 10, groundY - 60 - Double(k / 2) * 30), angle: a, length: rng.r(260, 340), width: 46, tone: k % 3 == 0 ? tone.dk(0.1) : tone, curve: side * 0.35, fold: true, seed: seed &+ UInt64(k * 13))
        }
        var rng2 = Chip(seed &+ 9)
        for k in 0..<12 {
            let root = stemRun(pt(plantX + rng2.r(-18, 18), groundY + 98), .pi / 2 + rng2.r(-0.8, 0.8), rng2.r(20, 50), curve: rng2.r(-0.5, 0.5), wobble: 0.1, steps: 5, seed: seed &+ UInt64(k * 3))
            pen(p, root, weight: 1.6, colour: Pot.strawPale.dk(0.4), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 11))
        }
    case "scallion":
        cutawaySoil(p, seed: seed &+ 77)
        for k in 0..<7 {
            let x = plantX - 60 + Double(k) * 20
            let shank = bandOf([pt(x, groundY + 50), pt(x + Double(k - 3) * 3, groundY - 40)], [14, 15, 13], per: 4)
            produce(p, shank, tone: Pot.white, gloss: 0.2, seed: seed &+ UInt64(k * 5))
            for j in 0..<3 {
                let a = -Double.pi / 2 + Double(j - 1) * 0.18 + Double(k - 3) * 0.06
                strapLeaf(p, base: pt(x + Double(k - 3) * 3, groundY - 36), angle: a, length: rng.r(280, 380), width: 13, tone: j == 1 ? tone : tone.dk(0.08), curve: Double(j - 1) * 0.3 + Double(k - 3) * 0.05, fold: false, seed: seed &+ UInt64(k * 13 + j))
            }
            for j in 0..<4 {
                let root = stemRun(pt(x + rng.r(-5, 5), groundY + 48), .pi / 2 + rng.r(-0.7, 0.7), rng.r(14, 34), curve: rng.r(-0.5, 0.5), wobble: 0.1, steps: 4, seed: seed &+ UInt64(k * 7 + j))
                pen(p, root, weight: 1.3, colour: Pot.strawPale.dk(0.4), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 11 + j + 60))
            }
        }
    case "chives":
        groundLine(p, seed: seed &+ 77)
        for k in 0..<28 {
            let a = -Double.pi / 2 + Double(k - 14) * 0.075
            strapLeaf(p, base: pt(plantX + Double(k - 14) * 3, groundY - 4), angle: a, length: rng.r(220, 330), width: 7, tone: k % 3 == 0 ? tone.dk(0.1) : tone, curve: Double(k - 14) * 0.04, fold: false, seed: seed &+ UInt64(k * 13))
        }
        for k in 0..<5 {
            let x = plantX - 90 + Double(k) * 45
            let st = stemRun(pt(x, groundY - 8), -Double.pi / 2 + Double(k - 2) * 0.1, rng.r(300, 360), curve: Double(k - 2) * 0.1, wobble: 0.01, steps: 6, seed: seed &+ UInt64(k * 3 + 400))
            pen(p, st, weight: 4, colour: tone.dk(0.2), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 3 + 401))
            let top = st[st.count - 1]
            let ring = lumpy(cx: Double(top.x), cy: Double(top.y), rx: 26, ry: 24, rough: 0.12, steps: 30, seed: seed &+ UInt64(k * 3 + 402))
            produce(p, ring, tone: Hue(r: 0.70, g: 0.46, b: 0.72), gloss: 0.3, seed: seed &+ UInt64(k * 3 + 403))
            p.inside(pathOf(ring)) {
                for _ in 0..<40 {
                    p.dot(Double(top.x) + rng.r(-24, 24), Double(top.y) + rng.r(-22, 22), rng.r(1, 2.4), Hue(r: 0.50, g: 0.28, b: 0.56).al(0.6))
                }
            }
        }
    case "celery":
        groundLine(p, seed: seed &+ 77)
        for k in 0..<9 {
            let side = Double(k - 4)
            let a = -Double.pi / 2 + side * 0.1
            let base = pt(plantX + side * 14, groundY - 2)
            let st = stemRun(base, a, rng.r(260, 330), curve: side * 0.08, wobble: 0.01, steps: 8, seed: seed &+ UInt64(k * 5))
            stem(p, st, w0: 22, w1: 12, tone: Pot.leafPale.lt(0.15), seed: seed &+ UInt64(k * 5 + 1))
            p.inside(pathOf(bandOf(st, [22, 16, 12], per: 4))) {
                for j in 0..<3 {
                    let off = Double(j - 1) * 6
                    pen(p, offsetRing(st, off, 0), weight: 1.6, colour: Pot.leafPale.dk(0.35).al(0.55), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 7 + j + 200))
                }
            }
            let top = st[st.count - 1]
            for j in 0..<3 {
                let la = a + Double(j - 1) * 0.7
                blade(p, base: top, angle: la, length: 60, width: 44, tone: j == 1 ? tone : tone.dk(0.1), serrate: 0.7, curl: 0, veins: 3, seed: seed &+ UInt64(k * 13 + j))
            }
        }
    default:
        break
    }
}

func drawTuberCrop(_ p: Leaf, _ crop: Crop, _ rng: inout Chip) {
    let seed = hashOf(crop.key)
    let tone = leafTone(crop)
    cutawaySoil(p, seed: seed &+ 77)
    for k in 0..<5 {
        let q = pt(plantX - 130 + Double(k) * 65 + rng.r(-10, 10), groundY + 40 + Double(k % 2) * 40 + rng.r(-6, 6))
        pen(p, [pt(plantX, groundY + 6), q], weight: 2.2, colour: Pot.strawPale.dk(0.5), wobble: 0.6, taper: true, seed: seed &+ UInt64(k * 3 + 200))
        let ring = lumpy(cx: Double(q.x), cy: Double(q.y), rx: rng.r(30, 40), ry: rng.r(22, 28), rough: 0.05, steps: 26, seed: seed &+ UInt64(k * 5))
        produce(p, ring, tone: Pot.straw.mix(Pot.soilLight, 0.3), gloss: 0.15, seed: seed &+ UInt64(k * 5 + 1))
        p.inside(pathOf(ring)) {
            for _ in 0..<5 { p.dot(Double(q.x) + rng.r(-24, 24), Double(q.y) + rng.r(-14, 14), 2.2, Pot.soil.al(0.5)) }
        }
    }
    for k in 0..<4 {
        let a = -Double.pi / 2 + (Double(k) - 1.5) * 0.36
        let st = stemRun(pt(plantX, groundY - 2), a, rng.r(180, 240), curve: (Double(k) - 1.5) * 0.08, wobble: 0.02, steps: 8, seed: seed &+ UInt64(k * 9))
        stem(p, st, w0: 10, w1: 6, tone: Pot.leaf.dk(0.2), seed: seed &+ UInt64(k * 9 + 1))
        let fine = resample(st, count: 4)
        for j in 1..<4 {
            let side: Double = j % 2 == 0 ? 1 : -1
            pinnateLeaf(p, base: fine[j], angle: a + side * 0.8, length: 110, tone: j % 2 == 0 ? tone : tone.dk(0.08), leaflets: 5, leafletSize: 40, serrate: 0, seed: seed &+ UInt64(k * 19 + j * 3))
        }
        if k == 1 {
            let top = st[st.count - 1]
            for j in 0..<3 {
                daisy(p, at: pt(Double(top.x) + Double(j - 1) * 26, Double(top.y) - 20 + Double(j % 2) * 10), r: 15, petals: 5, petalTone: Pot.white.mix(Hue(r: 0.7, g: 0.6, b: 0.8), 0.4), centreTone: Pot.yellow, petalWidth: 0.6, seed: seed &+ UInt64(j + 500))
            }
        }
    }
}

func drawHerbCrop(_ p: Leaf, _ crop: Crop, _ rng: inout Chip) {
    let seed = hashOf(crop.key)
    let tone = leafTone(crop)
    groundLine(p, seed: seed &+ 77, wide: false)
    switch crop.key {
    case "dill", "cilantro":
        for k in 0..<5 {
            let a = -Double.pi / 2 + Double(k - 2) * 0.28
            let st = stemRun(pt(plantX, groundY - 2), a, rng.r(300, 400), curve: Double(k - 2) * 0.06, wobble: 0.01, steps: 8, seed: seed &+ UInt64(k * 9))
            pen(p, st, weight: 5, colour: tone.dk(0.25), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 9 + 1))
            let fine = resample(st, count: 5)
            for j in 1..<4 {
                let side: Double = j % 2 == 0 ? 1 : -1
                if crop.key == "dill" {
                    featheryLeaf(p, base: fine[j], angle: a + side * 0.9, length: 100, tone: j % 2 == 0 ? tone : tone.dk(0.08), fineness: 5, seed: seed &+ UInt64(k * 19 + j * 3))
                } else {
                    for m in 0..<3 {
                        blade(p, base: fine[j], angle: a + side * 0.9 + Double(m - 1) * 0.6, length: 44, width: 30, tone: tone, serrate: 0.9, curl: 0, veins: 2, seed: seed &+ UInt64(k * 19 + j * 3 + m))
                    }
                }
            }
            if k % 2 == 0 {
                umbel(p, top: st[st.count - 1], spread: 80, tone: crop.key == "dill" ? Pot.yellow : Pot.white, rays: 9, seed: seed &+ UInt64(k * 7 + 500))
            } else {
                featheryLeaf(p, base: st[st.count - 1], angle: a, length: 90, tone: tone, fineness: 4, seed: seed &+ UInt64(k * 19 + 800))
            }
        }
    case "parsley":
        for k in 0..<9 {
            let a = -Double.pi / 2 + Double(k - 4) * 0.24
            let st = stemRun(pt(plantX, groundY - 2), a, rng.r(200, 280), curve: Double(k - 4) * 0.05, wobble: 0.01, steps: 6, seed: seed &+ UInt64(k * 9))
            pen(p, st, weight: 4, colour: tone.dk(0.3), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 9 + 1))
            let top = st[st.count - 1]
            for m in 0..<3 {
                let ring = lobedRing(at: pt(Double(top.x) + cos(a + Double(m - 1) * 0.8) * 34, Double(top.y) + sin(a + Double(m - 1) * 0.8) * 34), angle: a + Double(m - 1) * 0.8, size: 34, lobes: 5, depth: 0.5, seed: seed &+ UInt64(k * 19 + m))
                wash(p, ring, m == 1 ? tone : tone.dk(0.1), strength: 0.58, bleed: 3, seed: seed &+ UInt64(k * 13 + m))
                roundShade(p, ring, inset: 12, depth: 2, spacing: 2.6, colour: tone.dk(0.42), seed: seed &+ UInt64(k * 13 + m + 1))
                penOutline(p, ring, weight: 1.3, colour: tone.dk(0.6), seed: seed &+ UInt64(k * 13 + m + 2))
            }
        }
    case "basil", "mint", "oregano":
        if crop.key == "mint" {
            let potRing = [pt(plantX - 120, groundY - 60), pt(plantX + 120, groundY - 60), pt(plantX + 100, groundY + 70), pt(plantX - 100, groundY + 70)]
            wash(p, potRing, Pot.terracotta, strength: 0.6, bleed: 4, seed: seed &+ 800)
            crossHatch(p, pathOf(potRing), depth: 2, spacing: 5, colour: Pot.terraDeep.dk(0.2), seed: seed &+ 801)
            penEdge(p, potRing, weight: 3, colour: Pot.ink.al(0.8), seed: seed &+ 802)
            pen(p, [pt(plantX - 126, groundY - 48), pt(plantX + 126, groundY - 48)], weight: 5, colour: Pot.terraDeep, wobble: 0.5, taper: false, seed: seed &+ 803)
        }
        let stems = crop.key == "oregano" ? 6 : 4
        for k in 0..<stems {
            let frac = Double(k) / Double(max(1, stems - 1))
            let a = -Double.pi / 2 + frac * 1.2 - 0.6
            let baseY = crop.key == "mint" ? groundY - 60 : groundY - 2
            let st = stemRun(pt(plantX + Double(k - stems / 2) * 20, baseY), a, rng.r(220, 320), curve: (crop.key == "oregano" ? -1 : 1) * Double(k - stems / 2) * 0.12, wobble: 0.02, steps: 8, seed: seed &+ UInt64(k * 9))
            stem(p, st, w0: 8, w1: 5, tone: crop.key == "basil" ? tone.dk(0.15) : Pot.terraDeep.mix(tone, 0.5), seed: seed &+ UInt64(k * 9 + 1))
            let fine = resample(st, count: 6)
            for j in 1..<6 {
                for side in [-1.0, 1.0] {
                    let size = crop.key == "oregano" ? 34.0 : (crop.key == "basil" ? 66.0 : 52.0)
                    blade(p, base: fine[j], angle: a + side * 1.05, length: size * (1 - Double(j) * 0.08), width: size * (crop.key == "basil" ? 0.62 : 0.55), tone: j % 2 == 0 ? tone : tone.dk(0.08), serrate: crop.key == "mint" ? 0.8 : 0.15, curl: side * 0.2, veins: 3, seed: seed &+ UInt64(k * 19 + j * 3 + Int(side + 2)))
                }
            }
            if k % 2 == 0 {
                let top = st[st.count - 1]
                for j in 0..<5 {
                    p.dot(Double(top.x) + Double(j % 2 == 0 ? -7 : 7), Double(top.y) - Double(j) * 9, 5, crop.key == "basil" ? Pot.white : Hue(r: 0.74, g: 0.52, b: 0.72))
                    p.hoop(Double(top.x) + Double(j % 2 == 0 ? -7 : 7), Double(top.y) - Double(j) * 9, 5, 1.0, Pot.ink.al(0.6))
                }
            }
        }
    case "thyme", "rosemary", "sage":
        let woody = crop.key == "rosemary"
        let stems = crop.key == "thyme" ? 9 : (woody ? 5 : 5)
        for k in 0..<stems {
            let spread = crop.key == "thyme" ? 2.6 : 1.3
            let frac = Double(k) / Double(max(1, stems - 1))
            let a = -Double.pi / 2 + (frac - 0.5) * spread
            let st = stemRun(pt(plantX, groundY - 2), a, crop.key == "thyme" ? rng.r(150, 220) : rng.r(240, 330), curve: crop.key == "thyme" ? -(a + .pi / 2) * 0.5 : Double(k - 2) * 0.05, wobble: 0.03, steps: 8, seed: seed &+ UInt64(k * 9))
            stem(p, st, w0: woody ? 9 : 6, w1: 4, tone: Pot.woodDark.mix(tone, 0.5), woody: woody, seed: seed &+ UInt64(k * 9 + 1))
            let fine = resample(st, count: woody ? 14 : 8)
            for j in 1..<fine.count {
                for side in [-1.0, 1.0] {
                    let angle = a + side * (woody ? 0.7 : 1.0)
                    switch crop.key {
                    case "rosemary":
                        pen(p, [fine[j], pt(Double(fine[j].x) + cos(angle) * 28, Double(fine[j].y) + sin(angle) * 28)], weight: 3.4, colour: j % 2 == 0 ? tone : tone.dk(0.2), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 31 + j * 3 + Int(side + 2)))
                    case "thyme":
                        blade(p, base: fine[j], angle: angle, length: 16, width: 9, tone: tone, serrate: 0, curl: 0, veins: 0, seed: seed &+ UInt64(k * 31 + j * 3 + Int(side + 2)))
                    default:
                        blade(p, base: fine[j], angle: angle, length: 62 * (1 - Double(j) * 0.06), width: 30, tone: j % 2 == 0 ? tone : tone.dk(0.08), serrate: 0.1, curl: side * 0.15, veins: 4, seed: seed &+ UInt64(k * 31 + j * 3 + Int(side + 2)))
                    }
                }
            }
            if k % 2 == 0 {
                let top = st[st.count - 1]
                let bloom = crop.key == "sage" ? Hue(r: 0.42, g: 0.30, b: 0.62) : Hue(r: 0.72, g: 0.66, b: 0.84)
                for j in 0..<(crop.key == "sage" ? 7 : 4) {
                    p.dot(Double(top.x) + Double(j % 2 == 0 ? -6 : 6), Double(top.y) - Double(j) * 8, crop.key == "sage" ? 6 : 4, bloom)
                    p.hoop(Double(top.x) + Double(j % 2 == 0 ? -6 : 6), Double(top.y) - Double(j) * 8, crop.key == "sage" ? 6 : 4, 1.0, Pot.ink.al(0.5))
                }
            }
        }
    default:
        break
    }
}

func drawFlowerCrop(_ p: Leaf, _ crop: Crop, _ rng: inout Chip) {
    let seed = hashOf(crop.key)
    let tone = leafTone(crop)
    groundLine(p, seed: seed &+ 77)
    switch crop.key {
    case "sunflower":
        let spine = mainStem(p, top: 400, w0: 22, w1: 12, tone: Pot.leaf.dk(0.15), woody: true, seed: seed)
        for k in 0..<6 {
            let t = 0.2 + Double(k) / 6 * 0.6
            let q = along(spine, t)
            let side: Double = k % 2 == 0 ? -1 : 1
            let a = side > 0 ? -0.5 : -2.65
            let st = stemRun(q, a, 50, curve: 0, wobble: 0.02, steps: 3, seed: seed &+ UInt64(k * 9))
            pen(p, st, weight: 5, colour: tone.dk(0.3), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 9 + 1))
            heartLeaf(p, at: pt(Double(st[st.count - 1].x) + cos(a) * 70, Double(st[st.count - 1].y) + sin(a) * 70), angle: a, size: rng.r(80, 105), tone: k % 2 == 0 ? tone : tone.dk(0.08), lobes: 3, seed: seed &+ UInt64(k * 13))
        }
        daisy(p, at: pt(plantX + 10, 400), r: 140, petals: 22, petalTone: Pot.yellow, centreTone: Pot.sepia.dk(0.2), petalWidth: 0.3, seed: seed &+ 500)
        p.inside(pathOf(ringOf(cx: plantX + 10, cy: 400, rx: 46, ry: 44, steps: 30))) {
            for k in 0..<140 {
                let a = Double(k) * 2.39996
                let r = 3.8 * (Double(k)).squareRoot()
                p.dot(plantX + 10 + cos(a) * r, 400 + sin(a) * r, 2.6, k % 2 == 0 ? Pot.sepia.dk(0.4) : Pot.straw.dk(0.3))
            }
        }
    case "marigold", "calendula":
        let stems = 5
        for k in 0..<stems {
            let a = -Double.pi / 2 + Double(k - 2) * 0.3
            let st = stemRun(pt(plantX, groundY - 2), a, rng.r(220, 300), curve: Double(k - 2) * 0.05, wobble: 0.02, steps: 8, seed: seed &+ UInt64(k * 9))
            stem(p, st, w0: 8, w1: 5, tone: tone.dk(0.2), seed: seed &+ UInt64(k * 9 + 1))
            let fine = resample(st, count: 5)
            for j in 1..<4 {
                let side: Double = j % 2 == 0 ? 1 : -1
                if crop.key == "marigold" {
                    pinnateLeaf(p, base: fine[j], angle: a + side * 1.0, length: 70, tone: j % 2 == 0 ? tone : tone.dk(0.08), leaflets: 5, leafletSize: 22, serrate: 0.8, seed: seed &+ UInt64(k * 19 + j * 3))
                } else {
                    blade(p, base: fine[j], angle: a + side * 1.0, length: 80, width: 30, tone: j % 2 == 0 ? tone : tone.dk(0.08), serrate: 0.1, curl: side * 0.2, veins: 3, seed: seed &+ UInt64(k * 19 + j * 3))
                }
            }
            let top = st[st.count - 1]
            if crop.key == "marigold" {
                for layer in 0..<2 {
                    daisy(p, at: top, r: 46 - Double(layer) * 14, petals: 12, petalTone: layer == 0 ? Pot.pumpkin.mix(Pot.tomato, 0.3) : Pot.yellow.mix(Pot.pumpkin, 0.5), centreTone: Pot.yellow, petalWidth: 0.55, seed: seed &+ UInt64(k * 7 + layer + 500))
                }
            } else {
                daisy(p, at: top, r: 50, petals: 16, petalTone: Pot.pumpkin.mix(Pot.yellow, 0.35), centreTone: Pot.pumpkin.dk(0.3), petalWidth: 0.3, seed: seed &+ UInt64(k * 7 + 500))
            }
        }
    default:
        break
    }
}

func drawRunnerCrop(_ p: Leaf, _ crop: Crop, _ rng: inout Chip) {
    let seed = hashOf(crop.key)
    let tone = leafTone(crop)
    switch crop.key {
    case "strawberry":
        groundLine(p, seed: seed &+ 77)
        for k in 0..<7 {
            let a = -Double.pi / 2 + Double(k - 3) * 0.42
            let st = stemRun(pt(plantX, groundY - 2), a, rng.r(120, 170), curve: 0, wobble: 0.02, steps: 4, seed: seed &+ UInt64(k * 9))
            pen(p, st, weight: 4, colour: tone.dk(0.3), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 9 + 1))
            trifoliate(p, at: st[st.count - 1], angle: a, size: rng.r(60, 74), tone: k % 2 == 0 ? tone : tone.dk(0.08), seed: seed &+ UInt64(k * 13))
        }
        for k in 0..<4 {
            let a = -Double.pi / 2 + (Double(k) - 1.5) * 0.5
            let st = stemRun(pt(plantX, groundY - 2), a, 110, curve: 0, wobble: 0.02, steps: 4, seed: seed &+ UInt64(k * 9 + 300))
            pen(p, st, weight: 3, colour: tone.dk(0.3), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 9 + 301))
            let top = st[st.count - 1]
            if k % 2 == 0 {
                let tx = Double(top.x), ty = Double(top.y)
                let berry: [CGPoint] = [pt(tx - 26, ty), pt(tx - 30, ty + 30), pt(tx, ty + 66), pt(tx + 30, ty + 30), pt(tx + 26, ty)]
                produce(p, resample(berry + [berry[0]], count: 30), tone: Pot.tomato, gloss: 0.6, seed: seed &+ UInt64(k * 5 + 400))
                p.inside(pathOf(berry)) {
                    for _ in 0..<22 { p.dot(Double(top.x) + rng.r(-24, 24), Double(top.y) + rng.r(4, 56), 1.8, Pot.yellow.al(0.8)) }
                }
                for j in 0..<5 {
                    blade(p, base: pt(Double(top.x), Double(top.y) + 2), angle: Double(j) / 5 * 2 * .pi, length: 16, width: 8, tone: Pot.leafDeep, serrate: 0, curl: 0, veins: 0, seed: seed &+ UInt64(k * 5 + j + 420))
                }
            } else {
                daisy(p, at: top, r: 22, petals: 5, petalTone: Pot.white, centreTone: Pot.yellow, petalWidth: 0.6, seed: seed &+ UInt64(k + 500))
            }
        }
        let runner = stemRun(pt(plantX + 30, groundY - 6), 0.1, 240, curve: 0.2, wobble: 0.05, steps: 8, seed: seed &+ 600)
        pen(p, runner, weight: 3, colour: Pot.tomato.mix(tone, 0.5), wobble: 0.4, taper: true, seed: seed &+ 601)
        trifoliate(p, at: pt(Double(runner[runner.count - 1].x), Double(runner[runner.count - 1].y) - 20), angle: -Double.pi / 2, size: 34, tone: tone.lt(0.1), seed: seed &+ 602)
    case "sweetpotato":
        cutawaySoil(p, seed: seed &+ 77)
        for k in 0..<4 {
            let q = pt(plantX - 110 + Double(k) * 75 + rng.r(-8, 8), groundY + 50 + Double(k % 2) * 30)
            let ring = bandOf([pt(Double(q.x) - 36, Double(q.y) - 8), pt(Double(q.x), Double(q.y) + 4), pt(Double(q.x) + 40, Double(q.y) - 6)], [14, 34, 12], per: 8)
            produce(p, ring, tone: Pot.terracotta.mix(Pot.beet, 0.35), gloss: 0.3, seed: seed &+ UInt64(k * 5))
            pen(p, [pt(plantX, groundY + 4), pt(Double(q.x) - 30, Double(q.y) - 6)], weight: 2, colour: Pot.strawPale.dk(0.5), wobble: 0.5, taper: true, seed: seed &+ UInt64(k + 200))
        }
        for k in 0..<5 {
            let a = -Double.pi + Double(k) / 4 * .pi
            let run = stemRun(pt(plantX, groundY - 8), a, k == 2 ? 100 : 230, curve: -(a + .pi / 2) * 0.4, wobble: 0.06, steps: 8, seed: seed &+ UInt64(k * 17))
            stem(p, run, w0: 7, w1: 4, tone: Pot.aubergine.mix(tone, 0.5), seed: seed &+ UInt64(k * 17 + 1))
            let fine = resample(run, count: 5)
            for j in 1..<5 {
                let la = a + (j % 2 == 0 ? 0.9 : -0.9)
                heartLeaf(p, at: pt(Double(fine[j].x) + cos(la) * 36, Double(fine[j].y) + sin(la) * 36), angle: la, size: rng.r(48, 62), tone: j % 2 == 0 ? tone : tone.dk(0.08), lobes: 3, seed: seed &+ UInt64(k * 19 + j * 3))
            }
        }
    case "nasturtium":
        groundLine(p, seed: seed &+ 77)
        for k in 0..<6 {
            let a = -Double.pi + Double(k) / 5 * .pi
            let run = stemRun(pt(plantX, groundY - 8), a, rng.r(160, 240), curve: -(a + .pi / 2) * 0.3, wobble: 0.05, steps: 8, seed: seed &+ UInt64(k * 17))
            stem(p, run, w0: 6, w1: 4, tone: tone.dk(0.1), seed: seed &+ UInt64(k * 17 + 1))
            let fine = resample(run, count: 4)
            for j in 1..<4 {
                let c = pt(Double(fine[j].x) + rng.r(-10, 10), Double(fine[j].y) - 40 - rng.r(0, 20))
                pen(p, [fine[j], c], weight: 3, colour: tone.dk(0.3), wobble: 0.4, taper: true, seed: seed &+ UInt64(k * 19 + j))
                let ring = lumpy(cx: Double(c.x), cy: Double(c.y), rx: rng.r(36, 50), ry: rng.r(30, 40), rough: 0.03, steps: 30, seed: seed &+ UInt64(k * 19 + j * 3))
                wash(p, ring, j % 2 == 0 ? tone : tone.dk(0.08), strength: 0.56, bleed: 3, seed: seed &+ UInt64(k * 13 + j))
                roundShade(p, ring, inset: 16, depth: 2, spacing: 3, colour: tone.dk(0.42), seed: seed &+ UInt64(k * 13 + j + 1))
                p.inside(pathOf(ring)) {
                    for m in 0..<7 {
                        let ra = Double(m) / 7 * 2 * .pi
                        let vx = Double(c.x) + cos(ra) * 40
                        let vy = Double(c.y) + sin(ra) * 34
                        pen(p, [c, pt(vx, vy)], weight: 1.4, colour: tone.lt(0.3).al(0.8), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 41 + j * 7 + m))
                    }
                }
                penOutline(p, ring, weight: 1.5, colour: tone.dk(0.6), seed: seed &+ UInt64(k * 13 + j + 2))
            }
            if k % 2 == 1 {
                let top = pt(Double(run[run.count - 1].x), Double(run[run.count - 1].y) - 30)
                daisy(p, at: top, r: 34, petals: 5, petalTone: k == 1 ? Pot.pumpkin : Pot.tomato.mix(Pot.pumpkin, 0.5), centreTone: Pot.yellow.dk(0.2), petalWidth: 0.7, seed: seed &+ UInt64(k + 500))
            }
        }
    default:
        break
    }
}

func drawFernCrop(_ p: Leaf, _ crop: Crop, _ rng: inout Chip) {
    let seed = hashOf(crop.key)
    let tone = leafTone(crop)
    cutawaySoil(p, seed: seed &+ 77)
    pen(p, [pt(plantX - 120, groundY + 40), pt(plantX + 120, groundY + 44)], weight: 9, colour: Pot.strawPale.dk(0.35), wobble: 1.0, taper: true, seed: seed &+ 5)
    for k in 0..<14 {
        let x = plantX - 110 + Double(k) * 17
        let root = stemRun(pt(x, groundY + 42), .pi / 2 + rng.r(-0.4, 0.4), rng.r(30, 70), curve: rng.r(-0.3, 0.3), wobble: 0.1, steps: 5, seed: seed &+ UInt64(k * 3))
        pen(p, root, weight: 3, colour: Pot.strawPale.dk(0.35), wobble: 0.5, taper: true, seed: seed &+ UInt64(k * 11))
    }
    for k in 0..<4 {
        let x = plantX - 60 + Double(k) * 40
        let spear = bandOf([pt(x, groundY + 36), pt(x + Double(k - 2) * 4, groundY - 60 - Double(k % 2) * 40)], [16, 14, 8], per: 5)
        produce(p, spear, tone: Pot.leafPale.mix(Pot.leaf, 0.3), gloss: 0.3, seed: seed &+ UInt64(k * 5 + 100))
        let tip = pt(x + Double(k - 2) * 4, groundY - 60 - Double(k % 2) * 40)
        for j in 0..<5 {
            blade(p, base: pt(Double(tip.x), Double(tip.y) + 14 + Double(j) * 8), angle: -Double.pi / 2 + Double(j % 2 == 0 ? -0.5 : 0.5), length: 12, width: 6, tone: Pot.aubergine.mix(Pot.leaf, 0.5), serrate: 0, curl: 0, veins: 0, seed: seed &+ UInt64(k * 7 + j + 200))
        }
    }
    for k in 0..<2 {
        let x = plantX + 70 + Double(k) * 50
        let st = stemRun(pt(x, groundY + 36), -Double.pi / 2 + Double(k) * 0.1, 520, curve: -0.15 + Double(k) * 0.1, wobble: 0.01, steps: 12, seed: seed &+ UInt64(k * 9 + 300))
        stem(p, st, w0: 7, w1: 3, tone: tone.dk(0.2), seed: seed &+ UInt64(k * 9 + 301))
        let fine = resample(st, count: 14)
        for j in 3..<14 {
            for side in [-1.0, 1.0] {
                let a = -Double.pi / 2 + side * 1.0
                let branch = stemRun(fine[j], a, 46 - Double(j) * 2, curve: 0, wobble: 0.03, steps: 5, seed: seed &+ UInt64(k * 31 + j * 3 + Int(side + 2)))
                pen(p, branch, weight: 1.6, colour: tone.dk(0.2), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 41 + j * 5 + Int(side + 2)))
                let sub = resample(branch, count: 6)
                for m in 1..<6 {
                    for s2 in [-1.0, 1.0] {
                        pen(p, [sub[m], pt(Double(sub[m].x) + cos(a + s2 * 0.9) * 10, Double(sub[m].y) + sin(a + s2 * 0.9) * 10)], weight: 1.0, colour: tone.dk(rng.r(0, 0.25)), wobble: 0.2, taper: true, seed: seed &+ UInt64(k * 91 + j * 11 + m * 3 + Int(s2 + 2)))
                    }
                }
            }
        }
    }
}

func drawCropFigure(_ p: Leaf, _ crop: Crop) {
    var rng = Chip(hashOf(crop.key) &+ 99)
    switch crop.form {
    case .fruitBush: drawFruitBushCrop(p, crop, &rng)
    case .vine: drawVineCrop(p, crop, &rng)
    case .root: drawRootCrop(p, crop, &rng)
    case .bulb: drawBulbCrop(p, crop, &rng)
    case .leafy: drawLeafyCrop(p, crop, &rng)
    case .head: drawHeadCrop(p, crop, &rng)
    case .bush: drawBushCrop(p, crop, &rng)
    case .tall: drawTallCrop(p, crop, &rng)
    case .stalk: drawStalkCrop(p, crop, &rng)
    case .tuber: drawTuberCrop(p, crop, &rng)
    case .herb: drawHerbCrop(p, crop, &rng)
    case .flower: drawFlowerCrop(p, crop, &rng)
    case .runner: drawRunnerCrop(p, crop, &rng)
    case .fern: drawFernCrop(p, crop, &rng)
    }
}

func packetFrame(_ p: Leaf, seed: UInt64) {
    var rng = Chip(seed)
    let inset = 44.0
    let c: [CGPoint] = [pt(inset, inset), pt(p.w - inset, inset), pt(p.w - inset, p.h - inset), pt(inset, p.h - inset)]
    for k in 0..<4 {
        pen(p, [c[k], c[(k + 1) % 4]], weight: 3.2, colour: Pot.ink, wobble: 0.6, taper: false, seed: seed &+ UInt64(k * 7 + 1))
    }
    let i2 = inset + 12
    let c2: [CGPoint] = [pt(i2, i2), pt(p.w - i2, i2), pt(p.w - i2, p.h - i2), pt(i2, p.h - i2)]
    for k in 0..<4 {
        pen(p, [c2[k], c2[(k + 1) % 4]], weight: 1.2, colour: Pot.inkSoft, wobble: 0.6, taper: false, seed: seed &+ UInt64(k * 7 + 31))
    }
    for k in 0..<4 {
        let corner = c2[k]
        let dx = Double(corner.x) < p.w / 2 ? 1.0 : -1.0
        let dy = Double(corner.y) < p.h / 2 ? 1.0 : -1.0
        let sprig = stemRun(pt(Double(corner.x) + dx * 10, Double(corner.y) + dy * 10), atan2(dy, dx), 34, curve: dx * dy * 0.6, wobble: 0.05, steps: 5, seed: seed &+ UInt64(k * 9 + 50))
        pen(p, sprig, weight: 1.8, colour: Pot.leafDeep.al(0.8), wobble: 0.3, taper: true, seed: seed &+ UInt64(k * 9 + 51))
        for j in 1..<4 {
            let q = along(sprig, Double(j) / 4)
            blade(p, base: q, angle: atan2(dy, dx) + (j % 2 == 0 ? 0.9 : -0.9), length: 12, width: 6, tone: Pot.leaf, serrate: 0, curl: 0, veins: 0, seed: seed &+ UInt64(k * 9 + j + 60))
        }
    }
    _ = rng.d()
}

func sowLine(_ crop: Crop) -> String {
    var parts: [String] = []
    if let i = crop.indoors { parts.append("Indoors " + Planner.weeksText(i, before: true) + " the last frost") }
    if let t = crop.transplant { parts.append("out " + Planner.relativeText(t)) }
    if let d = crop.direct { parts.append("direct " + Planner.relativeText(d)) }
    if let f = crop.fall { parts.append("fall sowing " + Planner.weeksText(f, before: true) + " the first frost") }
    var line = parts.joined(separator: "; ")
    if let first = line.first { line = String(first).uppercased() + line.dropFirst() }
    return line + "."
}

func drawCropPlate(_ crop: Crop, dir: String) {
    let p = Leaf(900, 1200)
    let seed = hashOf("plate-" + crop.key)
    layPaper(p, seed: seed, tone: Pot.creamWarm)
    p.flipDown()
    p.light = -2.36
    packetFrame(p, seed: seed &+ 3)
    letter(p, crop.name, at: p.w / 2, 138, size: 58, colour: Pot.ink, face: "Baskerville-Bold", align: .centre)
    letter(p, crop.latin, at: p.w / 2, 178, size: 27, colour: Pot.inkSoft, face: "Baskerville-Italic", align: .centre)
    p.box(p.w * 0.16, 200, p.w * 0.68, 1.4, Pot.ink.al(0.35))
    drawCropFigure(p, crop)
    let vigY = 960.0
    p.box(90, 905, 1.2, 150, Pot.ink.al(0.18))
    seedVignette(p, at: pt(170, vigY), kind: seedKind(crop), tone: seedTone(crop), seed: seed &+ 40)
    letter(p, "seed", at: 170, vigY + 62, size: 18, colour: Pot.inkPale, face: "Baskerville-Italic", align: .centre)
    seedlingVignette(p, at: pt(300, vigY + 22), tone: leafTone(crop), monocot: isMonocot(crop), seed: seed &+ 41)
    letter(p, "seedling", at: 300, vigY + 62, size: 18, colour: Pot.inkPale, face: "Baskerville-Italic", align: .centre)
    p.box(372, 905, 1.2, 150, Pot.ink.al(0.18))
    let rows: [(String, String)] = [
        ("FAMILY", crop.family.name == crop.botanical ? crop.botanical : crop.family.name + " (" + crop.botanical + ")"),
        ("DAYS", "\(crop.maturity.lowerBound) to \(crop.maturity.upperBound)"),
        ("PER SQUARE", "\(crop.perCell), \(crop.spacing) in apart"),
        ("HARDINESS", crop.hardiness.name)
    ]
    for (i, row) in rows.enumerated() {
        let y = 935.0 + Double(i) * 36
        letter(p, row.0, at: 396, y, size: 14, colour: Pot.inkPale, face: "Baskerville", align: .left, tracking: 2.2)
        letter(p, row.1, at: 520, y, size: 21, colour: Pot.ink, face: "Baskerville", align: .left)
    }
    p.box(p.w * 0.10, 1076, p.w * 0.80, 1.2, Pot.ink.al(0.28))
    for (i, line) in wrapText(sowLine(crop), width: p.w * 0.78, size: 20, face: "Baskerville-Italic").prefix(2).enumerated() {
        letter(p, line, at: p.w / 2, 1106 + Double(i) * 27, size: 20, colour: Pot.inkSoft, face: "Baskerville-Italic", align: .centre)
    }
    p.writeJPG(dir, crop.plate)
}

func seedTone(_ crop: Crop) -> Hue {
    switch crop.key {
    case "bushbean", "polebean": return Pot.beet.mix(Pot.sepia, 0.4)
    case "fava": return Pot.strawPale.dk(0.2)
    case "pea": return Pot.leafPale.dk(0.1)
    case "corn": return Pot.yellow
    case "beet", "chard": return Pot.sepia.lt(0.3)
    case "garlic": return Pot.white.dk(0.05)
    case "potato": return Pot.straw.mix(Pot.soilLight, 0.3)
    case "sunflower": return Pot.ink.lt(0.3)
    case "nasturtium": return Pot.strawPale.dk(0.3)
    case "pumpkin", "wintersquash", "zucchini", "cucumber", "melon": return Pot.strawPale
    case "watermelon": return Pot.ink.lt(0.4)
    case "okra": return Pot.leafGrey.dk(0.2)
    default: return Pot.sepia
    }
}
