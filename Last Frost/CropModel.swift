import Foundation

enum CropFamily: String, Codable, CaseIterable {
    case brassica, allium, nightshade, cucurbit, legume, umbel, aster, amaranth, grass, mint, sundry

    var name: String {
        switch self {
        case .brassica: return "Brassica"
        case .allium: return "Allium"
        case .nightshade: return "Solanaceae"
        case .cucurbit: return "Cucurbit"
        case .legume: return "Legume"
        case .umbel: return "Apiaceae"
        case .aster: return "Aster"
        case .amaranth: return "Amaranth"
        case .grass: return "Grass"
        case .mint: return "Herb"
        case .sundry: return "Sundry"
        }
    }

    var latin: String {
        switch self {
        case .brassica: return "Brassicaceae"
        case .allium: return "Amaryllidaceae"
        case .nightshade: return "Solanaceae"
        case .cucurbit: return "Cucurbitaceae"
        case .legume: return "Fabaceae"
        case .umbel: return "Apiaceae"
        case .aster: return "Asteraceae"
        case .amaranth: return "Amaranthaceae"
        case .grass: return "Poaceae"
        case .mint: return "Lamiaceae"
        case .sundry: return "Several families"
        }
    }

    var plate: String { "fa_" + rawValue }

    var signature: String {
        switch self {
        case .brassica: return "Four petals in a cross, a waxy blue-green leaf, and a hunger for nitrogen and lime."
        case .allium: return "A hollow or strap leaf, a bulb or a thickened stem, and a sulphur smell when cut."
        case .nightshade: return "A five-pointed star of a flower, a berry-fruit, and no patience for cold at all."
        case .cucurbit: return "A rough hairy vine, tendrils, separate male and female flowers, and a thirst."
        case .legume: return "A pea-flower, a pod, and root nodules that fix nitrogen from the air."
        case .umbel: return "Ferny leaves, an umbrella of tiny flowers, and a taproot that hates being moved."
        case .aster: return "A composite head of many florets, milky sap in lettuce, and a tendency to bolt in heat."
        case .amaranth: return "A clustered seed in a corky husk, a fleshy leaf, and a taste for potash."
        case .grass: return "A single stalk, wind-pollinated, planted in blocks so the silks catch the pollen."
        case .mint: return "A square stem, opposite leaves, oil glands, and flowers the bees will not leave alone."
        case .sundry: return "Each in a family of its own, so they rotate freely and fill the gaps in a plan."
        }
    }

    var lore: String {
        switch self {
        case .brassica:
            return "The cabbage family is one plant pulled a dozen ways: kale is the wild leaf, cabbage the terminal bud, broccoli and cauliflower the flower, kohlrabi the stem, Brussels sprouts the side buds. They share clubroot, a soil fungus that persists seven years, and the cabbage white, which is why the family moves every season and why lime goes on before them. They stand frost better than almost anything else in the plot and most of them sweeten after it."
        case .allium:
            return "Onions, garlic, leeks and chives are the sulphur family. They are light feeders, hate competition from weeds because their leaves throw no shade, and are the classic follow-on after a heavy feeder has been cleared. White rot, once in a bed, keeps for fifteen years, so the alliums move on and do not return for as long as the plan allows. Beans and peas resent them as neighbours."
        case .nightshade:
            return "Tomato, potato, pepper, eggplant and tomatillo are all one family and share blight, wilt and the same beetles. This is the family that came from the Americas and turned Old World cooking upside down. Every one of them is killed by the lightest frost, so every one of them is counted forward from the last spring frost and started under cover to steal the weeks the season will not give."
        case .cucurbit:
            return "Squash, cucumber, melon and pumpkin sprawl or climb, drink like nothing else in the plot, and carry both sexes of flower on one vine. They are direct-sown only when the soil is properly warm, and they resent root disturbance, so if they are started early it is in a pot they can be tipped out of whole. Powdery mildew and the squash bug are the shared enemies."
        case .legume:
            return "Peas and beans carry rhizobia in their root nodules and leave the ground richer in nitrogen than they found it. The plan uses that: a bed that grew legumes this year grows a brassica next year and the cabbages feed on what the peas left. Peas go in cold, weeks before the last frost; beans wait until the soil is warm and go in after it."
        case .umbel:
            return "Carrot, parsnip, celery, parsley, dill, fennel and cilantro carry their flowers in an umbel and their roots straight down. Almost none of them transplant well, so they are direct-sown and thinned, and they are slow and fussy to germinate. Carrot fly finds the whole family by smell, which is why the plan keeps them away from a freshly thinned neighbour."
        case .aster:
            return "Lettuce, endive, sunflower, marigold and calendula belong to the daisies. Lettuce is the workhorse: sown every fortnight, harvested in six weeks, and bolting to a bitter tower the moment the days grow long and hot. The flowering members earn their place as insectary plants, pulling in hoverflies and predatory wasps that police the rest of the plot."
        case .amaranth:
            return "Beet, chard and spinach are cousins that look nothing alike above ground. Beet seed is a cluster, so several seedlings come from one sowing and must be thinned. Chard is beet grown for its leaf and will be cut for months. Spinach is the earliest of the three and the first to bolt, so it is sown cold and sown again in autumn."
        case .grass:
            return "Sweet corn is a grass and behaves like one: shallow-rooted, wind-pollinated, hungry for nitrogen. It is planted in a block rather than a row so the pollen falling from the tassels lands on the silks below, and it is the tallest thing in the plot, so it goes where it will not shade the rest."
        case .mint:
            return "Basil, thyme, oregano, sage, rosemary and mint are the square-stemmed family, grown for oil rather than bulk. Most of them want lean, dry soil and full sun; basil alone wants warmth and water. Mint spreads by runner and is kept in a sunk pot. They are the plants a plan puts at the ends of beds and along paths."
        case .sundry:
            return "Okra, sweet potato, strawberry, rhubarb, asparagus and nasturtium each belong to a botanical family of their own. That makes them easy in rotation, since nothing else in the plot shares their diseases. Rhubarb and asparagus are perennials that hold a bed for years, and the plan treats their cells as permanent."
        }
    }
}

enum Hardiness: Int, Codable, CaseIterable {
    case hardy = 0, halfHardy, tender, veryTender

    var name: String {
        switch self {
        case .hardy: return "Hardy"
        case .halfHardy: return "Half-hardy"
        case .tender: return "Tender"
        case .veryTender: return "Very tender"
        }
    }

    var meaning: String {
        switch self {
        case .hardy: return "Stands a hard frost; sow or set out weeks before the last frost."
        case .halfHardy: return "Takes a light frost; sow a little before the last frost."
        case .tender: return "Killed by frost; wait until the last frost has passed."
        case .veryTender: return "Killed by frost and sulks in cold soil; wait a week or two beyond it."
        }
    }
}

enum PlantForm: String, Codable {
    case fruitBush, vine, root, bulb, leafy, head, bush, tall, stalk, tuber, herb, flower, runner, fern
}

struct Crop: Identifiable {
    let key: String
    let name: String
    let latin: String
    let family: CropFamily
    let botanical: String
    let indoors: ClosedRange<Int>?
    let transplant: ClosedRange<Int>?
    let direct: ClosedRange<Int>?
    let maturity: ClosedRange<Int>
    let perCell: Int
    let spacing: Int
    let hardiness: Hardiness
    let succession: Int?
    let window: Int
    let fall: ClosedRange<Int>?
    let companions: [String]
    let antagonists: [String]
    let form: PlantForm
    let tint: Int
    let note: String
    let trouble: String

    var id: String { key }
    var plate: String { "cr_" + key }
    var isPerennial: Bool { maturity.lowerBound >= 300 }
    var startsIndoorsOnly: Bool { indoors != nil && direct == nil }
    var directOnly: Bool { indoors == nil && direct != nil }

    var plural: String {
        switch key {
        case "lettuce", "kale", "cabbage", "broccoli", "cauliflower", "spinach", "chard", "garlic",
             "corn", "okra", "celery", "arugula", "mizuna", "bokchoy", "endive", "fennel", "dill",
             "basil", "parsley", "cilantro", "chives", "thyme", "oregano", "sage", "rosemary", "mint",
             "rhubarb", "asparagus", "sweetpotato", "wintersquash", "brussels":
            return name
        case "tomato", "potato": return name + "es"
        case "strawberry": return "Strawberries"
        default: return name + "s"
        }
    }
}

extension Crop {
    init(_ key: String, _ name: String, _ latin: String, _ family: CropFamily, _ botanical: String,
         indoors: ClosedRange<Int>?, out: ClosedRange<Int>?, direct: ClosedRange<Int>?,
         days: ClosedRange<Int>, per: Int, inches: Int, hardy: Hardiness, again: Int?, window: Int,
         fall: ClosedRange<Int>?, with: [String], against: [String], form: PlantForm, tint: Int,
         note: String, trouble: String) {
        self.key = key; self.name = name; self.latin = latin; self.family = family
        self.botanical = botanical
        self.indoors = indoors; self.transplant = out; self.direct = direct
        self.maturity = days; self.perCell = per; self.spacing = inches
        self.hardiness = hardy; self.succession = again; self.window = window; self.fall = fall
        self.companions = with; self.antagonists = against; self.form = form; self.tint = tint
        self.note = note; self.trouble = trouble
    }
}

enum Register {
    static let crops: [Crop] = CropsA.list + CropsB.list + CropsC.list + CropsD.list + CropsE.list + CropsF.list

    private static let index: [String: Int] = {
        var out: [String: Int] = [:]
        for (i, c) in crops.enumerated() { out[c.key] = i }
        return out
    }()

    static func find(_ key: String) -> Crop {
        if let i = index[key] { return crops[i] }
        return crops[0]
    }

    static func exists(_ key: String) -> Bool { index[key] != nil }

    static func members(of family: CropFamily) -> [Crop] { crops.filter { $0.family == family } }

    static var keys: [String] { crops.map { $0.key } }
}
