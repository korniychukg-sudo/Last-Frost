import Foundation

enum NoteKind: Int {
    case rotation = 0, companion, frost

    var title: String {
        switch self {
        case .rotation: return "Rotation puzzle"
        case .companion: return "Companion pairing"
        case .frost: return "Frost drill"
        }
    }
}

struct DailyNote: Equatable {
    var day: Int
    var kind: NoteKind
    var prompt: String
    var options: [String]
    var detail: [String]
    var answer: Int
    var explanation: String
}

enum Notebook {
    static func note(for day: Int, dates: FrostDates, rank: Int) -> DailyNote {
        var rng = Furrow(Almanac.seed(day) ^ 0x7A3D)
        let kinds: [NoteKind] = rank >= 2 ? [.rotation, .companion, .frost] : [.companion, .frost, .rotation]
        let kind = kinds[day % 3 == 0 ? 0 : (day % 3 == 1 ? 1 : 2)]
        switch kind {
        case .rotation: return rotation(day, &rng)
        case .companion: return companion(day, &rng)
        case .frost: return frost(day, dates, &rng)
        }
    }

    static let bedNames = ["the north bed", "the long bed", "the bed by the shed", "the cold-frame bed",
                           "the far bed", "the bed by the compost", "the path bed", "the sunny bed"]

    static func rotation(_ day: Int, _ rng: inout Furrow) -> DailyNote {
        let families: [CropFamily] = [.brassica, .allium, .nightshade, .cucurbit, .legume, .umbel, .amaranth]
        let picked = rng.shuffled(families).prefix(4).map { $0 }
        let breaking = rng.step(0, 2)
        var options: [String] = []
        var detail: [String] = []
        let names = rng.shuffled(bedNames).prefix(3).map { $0 }
        for i in 0..<3 {
            let thisFamily = picked[i]
            let thisCrop = rng.pick(Register.members(of: thisFamily))
            let lastFamily: CropFamily = i == breaking ? thisFamily : picked[(i + 1) % 3 == breaking ? 3 : (i + 1) % 3]
            let lastCrop = rng.pick(Register.members(of: lastFamily).filter { $0.key != thisCrop.key } + [thisCrop])
            options.append(names[i].prefix(1).uppercased() + names[i].dropFirst())
            detail.append("Last season: \(lastCrop.name.lowercased()) (\(lastFamily.name)). This season: \(thisCrop.name.lowercased()) (\(thisFamily.name)).")
        }
        let fam = picked[breaking]
        return DailyNote(day: day, kind: .rotation,
                         prompt: "Three beds are planned for this season. Which one breaks the rotation?",
                         options: options, detail: detail, answer: breaking,
                         explanation: "\(options[breaking]) puts \(fam.name.lowercased()) after \(fam.name.lowercased()). The same family in the same bed two seasons running carries its pests and soil diseases straight over; the plot warns on a repeat and warns hard on a third season.")
    }

    static func companion(_ day: Int, _ rng: inout Furrow) -> DailyNote {
        let anchors = Register.crops.filter { $0.companions.count >= 3 && $0.antagonists.count >= 2 }
        let anchor = rng.pick(anchors)
        let good = rng.pick(anchor.companions)
        var pool = anchor.antagonists
        let neutral = Register.crops.filter {
            !anchor.companions.contains($0.key) && !anchor.antagonists.contains($0.key)
                && !$0.companions.contains(anchor.key) && $0.key != anchor.key
        }
        if let n = neutral.isEmpty ? nil : rng.pick(neutral) { pool.append(n.key) }
        let others = rng.shuffled(pool).prefix(2).map { $0 }
        var options = others + [good]
        options = rng.shuffled(options)
        let answer = options.firstIndex(of: good) ?? 0
        let detail = options.map { key -> String in
            let c = Register.find(key)
            return "\(c.family.name), \(c.hardiness.name.lowercased()), \(c.perCell) per square."
        }
        return DailyNote(day: day, kind: .companion,
                         prompt: "\(anchor.plural) are going into a square. Which of these goes beside them?",
                         options: options.map { Register.find($0).name }, detail: detail, answer: answer,
                         explanation: "\(Register.find(good).name) is a companion to \(anchor.name.lowercased()). \(companionReason(anchor, Register.find(good))) The others are antagonists or simply indifferent neighbours, and an antagonist beside a square costs it a grade at harvest.")
    }

    static func companionReason(_ a: Crop, _ b: Crop) -> String {
        if b.family == .aster && (b.key == "marigold" || b.key == "calendula" || b.key == "sunflower") {
            return "Its flowers feed the hoverflies and wasps that police the aphids."
        }
        if b.family == .mint { return "Its scent is said to confuse the pests that hunt by smell, and it wants the same sun." }
        if b.family == .legume { return "It fixes nitrogen at the root and asks for little in return." }
        if b.family == .allium { return "Its sulphur smell is said to keep the flies off, and its narrow leaves throw no shade." }
        if b.family == .umbel && a.family == .nightshade { return "It draws the predators of the pests that find the fruit." }
        if b.perCell >= 9 { return "It is quick and small, filling the square between the larger plant's roots and finished before they need the room." }
        return "They ask for different things from the soil and shade each other at the right times."
    }

    static func frost(_ day: Int, _ dates: FrostDates, _ rng: inout Furrow) -> DailyNote {
        let tender = Register.crops.filter { $0.hardiness.rawValue >= Hardiness.tender.rawValue }
        let hardy = Register.crops.filter { $0.hardiness == .hardy }
        let target = rng.pick(tender)
        let decoys = rng.shuffled(hardy).prefix(2).map { $0 }
        var options = decoys + [target]
        options = rng.shuffled(options)
        let answer = options.firstIndex { $0.key == target.key } ?? 0
        let fy = FrostYear(dates, year: Almanac.year(of: day))
        let night = dates.frostFree ? "a cold night" : "the night of \(Almanac.label(fy.lastFrost + rng.step(-9, 9)))"
        let detail = options.map { "\($0.hardiness.name): \($0.hardiness.meaning.lowercased())" }
        return DailyNote(day: day, kind: .frost,
                         prompt: "Frost is forecast for \(night). Three squares are up. Which one needs covering?",
                         options: options.map { $0.name }, detail: detail, answer: answer,
                         explanation: "\(target.plural) are \(target.hardiness.name.lowercased()) and a single frost blackens them. \(decoys.map { $0.name }.joined(separator: " and ")) are hardy and stand it without help; most of the hardy crops are sweeter for it.")
    }
}

struct ExamQuestion: Identifiable, Equatable {
    var id: Int
    var prompt: String
    var options: [String]
    var answer: Int
    var explanation: String
}

enum Examiner {
    static func paper(seed: UInt64, count: Int, dates: FrostDates) -> [ExamQuestion] {
        var rng = Furrow(seed)
        var out: [ExamQuestion] = []
        var used: Set<String> = []
        var guardCount = 0
        while out.count < count && guardCount < count * 8 {
            guardCount += 1
            let kind = rng.step(0, 9)
            let q: ExamQuestion?
            switch kind {
            case 0: q = whichFirst(&rng, out.count)
            case 1: q = spacing(&rng, out.count)
            case 2: q = family(&rng, out.count)
            case 3: q = whenToSow(&rng, out.count, dates)
            case 4: q = maturity(&rng, out.count)
            case 5: q = troubleCrop(&rng, out.count)
            case 6: q = troubleAction(&rng, out.count)
            case 7: q = troubleKind(&rng, out.count)
            case 8: q = sayingVerdict(&rng, out.count)
            default: q = authored(&rng, out.count)
            }
            guard let question = q, !used.contains(question.prompt) else { continue }
            used.insert(question.prompt)
            out.append(question)
        }
        return out
    }

    static func earliest(_ c: Crop) -> Int? {
        var starts: [Int] = []
        if let d = c.direct { starts.append(d.lowerBound * 7) }
        if let t = c.transplant { starts.append(t.lowerBound * 7) }
        return starts.min()
    }

    static func whichFirst(_ rng: inout Furrow, _ id: Int) -> ExamQuestion? {
        let pool = Register.crops.filter { earliest($0) != nil && $0.fall == nil || ($0.direct != nil) }
        var a = rng.pick(pool), b = rng.pick(pool)
        var tries = 0
        while (a.key == b.key || earliest(a) == earliest(b)) && tries < 20 { b = rng.pick(pool); tries += 1 }
        guard let ea = earliest(a), let eb = earliest(b), ea != eb else { return nil }
        let first = ea < eb ? a : b
        let options = rng.shuffled([a.name, b.name])
        let answer = options.firstIndex(of: first.name) ?? 0
        let later = first.key == a.key ? b : a
        return ExamQuestion(id: id, prompt: "Which goes into the plot first, counted from the last frost?",
                            options: options, answer: answer,
                            explanation: "\(first.plural) go in \(describeStart(first)); \(later.plural.lowercased()) wait until \(describeStart(later)).")
    }

    static func describeStart(_ c: Crop) -> String {
        if let d = c.direct, let t = c.transplant {
            return min(d.lowerBound, t.lowerBound) == d.lowerBound
                ? "direct \(Planner.relativeText(d))" : "as transplants \(Planner.relativeText(t))"
        }
        if let d = c.direct { return "direct \(Planner.relativeText(d))" }
        if let t = c.transplant { return "as transplants \(Planner.relativeText(t))" }
        if let f = c.fall { return "\(Planner.weeksText(f, before: true)) the first fall frost" }
        return "when the window opens"
    }

    static func spacing(_ rng: inout Furrow, _ id: Int) -> ExamQuestion? {
        let c = rng.pick(Register.crops)
        let counts = [1, 2, 4, 8, 9, 16]
        var options = [c.perCell]
        var tries = 0
        while options.count < 4 && tries < 30 {
            let k = rng.pick(counts)
            if !options.contains(k) { options.append(k) }
            tries += 1
        }
        options = rng.shuffled(options)
        let answer = options.firstIndex(of: c.perCell) ?? 0
        return ExamQuestion(id: id, prompt: "How many \(c.plural.lowercased()) go into one square-foot cell?",
                            options: options.map { "\($0)" }, answer: answer,
                            explanation: "\(c.plural) are spaced \(c.spacing) inches apart, which gives \(c.perCell) to a twelve-inch square.")
    }

    static func family(_ rng: inout Furrow, _ id: Int) -> ExamQuestion? {
        let c = rng.pick(Register.crops.filter { $0.family != .sundry })
        var fams: [CropFamily] = [c.family]
        var tries = 0
        while fams.count < 4 && tries < 30 {
            let f = rng.pick(CropFamily.allCases.filter { $0 != .sundry })
            if !fams.contains(f) { fams.append(f) }
            tries += 1
        }
        fams = rng.shuffled(fams)
        let answer = fams.firstIndex(of: c.family) ?? 0
        return ExamQuestion(id: id, prompt: "Which rotation family does \(c.name.lowercased()) belong to?",
                            options: fams.map { "\($0.name) (\($0.latin))" }, answer: answer,
                            explanation: "\(c.name) is \(c.latin), in the \(c.family.latin). \(c.family.signature)")
    }

    static func whenToSow(_ rng: inout Furrow, _ id: Int, _ dates: FrostDates) -> ExamQuestion? {
        let pool = Register.crops.filter { $0.direct != nil || $0.transplant != nil }
        let c = rng.pick(pool)
        let fy = FrostYear(dates, year: Almanac.year(of: Almanac.dayIndex()))
        let useDirect = c.direct != nil && (c.transplant == nil || rng.chance(0.5))
        guard let range = useDirect ? c.direct : c.transplant else { return nil }
        let correct = Planner.relativeText(range)
        var options = [correct]
        let alternatives = [(-8)...(-6), (-6)...(-4), (-4)...(-2), (-2)...0, 0...2, 1...2, 2...3, 2...4, 1...3]
        var tries = 0
        while options.count < 4 && tries < 40 {
            let alt = Planner.relativeText(rng.pick(alternatives))
            if !options.contains(alt) { options.append(alt) }
            tries += 1
        }
        options = rng.shuffled(options)
        let answer = options.firstIndex(of: correct) ?? 0
        let window = useDirect ? Planner.directWindow(c, fy) : Planner.transplantWindow(c, fy)
        let forYou = window.map { "; for your frost dates that is \($0.label)" } ?? ""
        return ExamQuestion(id: id, prompt: useDirect ? "When are \(c.plural.lowercased()) sown direct?" : "When do \(c.plural.lowercased()) go out as transplants?",
                            options: options, answer: answer,
                            explanation: "\(c.plural) \(useDirect ? "are sown direct" : "go out") \(correct)\(forYou). \(c.hardiness.name): \(c.hardiness.meaning.lowercased())")
    }

    static func maturity(_ rng: inout Furrow, _ id: Int) -> ExamQuestion? {
        let c = rng.pick(Register.crops.filter { $0.maturity.upperBound < 200 })
        let correct = "\(c.maturity.lowerBound) to \(c.maturity.upperBound) days"
        var options = [correct]
        var tries = 0
        while options.count < 4 && tries < 40 {
            let shift = rng.pick([-40, -25, -15, 15, 25, 40, 60])
            let lo = max(15, c.maturity.lowerBound + shift)
            let hi = lo + (c.maturity.upperBound - c.maturity.lowerBound)
            let alt = "\(lo) to \(hi) days"
            if !options.contains(alt) { options.append(alt) }
            tries += 1
        }
        options = rng.shuffled(options)
        let answer = options.firstIndex(of: correct) ?? 0
        let from = c.transplant != nil && c.direct == nil ? "from transplanting" : "from sowing"
        return ExamQuestion(id: id, prompt: "How many days does \(c.name.lowercased()) take to maturity, \(from)?",
                            options: options, answer: answer,
                            explanation: "\(c.name): \(correct) \(from), then a harvest window of \(c.window) days.")
    }

    static let authoredA: [(String, [String], Int, String)] = [
        ("What is a last spring frost date?",
         ["The average date of the last 32 F night in spring", "The last day snow is possible", "The first day the soil can be dug", "The date the seed catalogue arrives"], 0,
         "It is a statistical average of the last freezing night, and the anchor every spring sowing is counted from."),
        ("What does hardening off mean?",
         ["Moving seedlings outdoors by degrees for a week before planting", "Letting the soil dry between waterings", "Firming the soil around a transplant", "Cutting back a plant to make it bushier"], 0,
         "Seedlings raised under cover have soft growth; a week of days outside and nights in toughens them before they go out for good."),
        ("Why are peas sown weeks before the last frost while beans wait until after it?",
         ["Peas germinate in cold soil and stand frost; beans rot in cold soil and die in frost", "Peas need more days to mature", "Beans need a longer day to flower", "Peas are a fall crop"], 0,
         "Both are legumes, but pea is hardy and bean is tender. Hardiness, not family, sets the sowing date."),
        ("A crop that bolts has done what?",
         ["Run to flower and seed before it was meant to", "Fallen over in the wind", "Been eaten at the root", "Grown too tall to support itself"], 0,
         "Bolting is premature flowering, usually from heat, long days or a cold check; lettuce, spinach and cilantro do it fastest."),
        ("Why is corn planted in a block rather than a single row?",
         ["It is wind-pollinated and the pollen must fall on neighbouring silks", "To shade the soil", "To keep it upright", "Because the roots spread sideways"], 0,
         "Pollen falls from the tassel onto the silks; in a single row most of it blows away and the ears come in gappy."),
        ("What is the rule of rotation for a bed?",
         ["Do not grow the same family in the same bed two seasons running", "Grow the same crop until the soil tires", "Alternate flowers and vegetables", "Change beds every month"], 0,
         "Families share pests and soil diseases; moving them each season breaks the cycle. Legumes before brassicas is a bonus."),
        ("What does days to maturity count from?",
         ["Sowing for direct-sown crops, transplanting for started crops", "The last frost", "Germination", "The first flower"], 0,
         "A packet's number is measured from the day the plant goes into its final bed."),
        ("Why does garlic go in during autumn?",
         ["It needs a cold spell to split into cloves and roots before winter", "It ripens faster in the cold", "The bulbs store better", "Spring soil is too wet"], 0,
         "Garlic needs vernalisation and time to root before the ground freezes; spring-planted garlic makes a single round."),
        ("What is square-foot spacing for a crop with 4 per cell?",
         ["Six inches apart", "Twelve inches apart", "Three inches apart", "Four inches apart"], 0,
         "Four plants in a twelve-inch square sit six inches apart in a two-by-two grid."),
        ("Blossom-end rot on a tomato is caused by what?",
         ["Uneven watering that starves the fruit of calcium", "A fungus in the soil", "Too much sun", "A virus carried by aphids"], 0,
         "The calcium is usually in the soil; it fails to reach the fruit when water comes in fits and starts. Mulch and a steady schedule cure it.")
    ]

    static let authoredB: [(String, [String], Int, String)] = [
        ("Which companion claim has a study behind it?",
         ["French marigold roots suppress root-knot nematodes", "Basil makes tomatoes taste better", "Carrots love tomatoes", "Mint keeps all pests away"], 0,
         "Tagetes roots release a compound that reduces nematode populations over a full season; most other pairings are habit and folklore."),
        ("Why is fennel planted alone?",
         ["Its roots give off a compound that checks the growth of neighbours", "It shades everything", "It draws every pest in the plot", "It needs more water than anything else"], 0,
         "Fennel is allelopathic; beside beans and tomatoes it stunts them."),
        ("What is succession sowing?",
         ["Sowing a short row every two or three weeks for a steady supply", "Sowing a second crop after the first is cleared", "Sowing two crops in one square", "Saving seed from the best plant"], 0,
         "Radish, lettuce, carrot and beans are sown little and often so the harvest is spread instead of arriving in a glut."),
        ("What makes a brassica after a legume a good rotation?",
         ["Legumes fix nitrogen and brassicas are heavy feeders", "They share the same pests", "Legumes lime the soil", "Brassicas shade the legume roots"], 0,
         "Rhizobia in the pea and bean roots leave nitrogen in the bed, and the cabbage family takes it up."),
        ("A cover crop is grown for what?",
         ["To protect and feed the soil over winter", "To be sold at market", "To shade tender seedlings", "To keep the paths dry"], 0,
         "Rye, vetch or clover sown after the last harvest holds the soil, smothers weeds and is dug in as green manure in spring."),
        ("Why is thinning necessary after direct sowing?",
         ["Seed is sown thicker than the final spacing and crowded plants make no roots", "To let light reach the soil", "To remove diseased seedlings", "It is not necessary"], 0,
         "Sowing thick allows for losses; thinning to the crop's spacing gives each plant its square inches."),
        ("What is a hardy crop?",
         ["One that stands a hard frost", "One that grows without water", "One that needs no feeding", "One that stores well"], 0,
         "Hardiness is frost tolerance: hardy crops are sown weeks before the last frost, very tender ones weeks after it."),
        ("Which of these is direct-sown only, because it hates root disturbance?",
         ["Carrot", "Tomato", "Cabbage", "Leek"], 0,
         "Carrot, parsnip and most of the umbel family fork or check when transplanted; they are sown where they will grow."),
        ("The harvest window is what?",
         ["The span of days a crop is at its best after maturity", "The hours of the day to pick", "The last week before frost", "The time the larder stays full"], 0,
         "Radish has a week, lettuce two, chard three months. Pull inside it for the best grade."),
        ("What tells the plan that a tray of tomatoes should go out?",
         ["The transplant window counted from the last frost and a week of hardening off", "The size of the seedlings", "The date on the packet", "The first warm day"], 0,
         "One to two weeks after the last frost, once the tray has been hardened off; nights should hold above fifty degrees.")
    ]

    static let authoredC: [(String, [String], Int, String)] = [
        ("Why are lettuce and spinach sown again in late summer?",
         ["They grow best in the cool of autumn and bolt in summer heat", "The soil is warmer", "The seed keeps better", "There is more rain"], 0,
         "Cool-season greens bolt in long hot days; the fall sowing grows into cooling weather and stands into the frosts."),
        ("Which crop is set out as slips rather than seed?",
         ["Sweet potato", "Sweet corn", "Cucumber", "Radish"], 0,
         "Sweet potato slips are rooted shoots sprouted from a stored tuber, set out into warm soil after the last frost."),
        ("What is a first fall frost date used for?",
         ["Counting back fall sowings and knowing when tender crops end", "Deciding when to prune", "Timing the spring sowing", "Nothing; it is only a record"], 0,
         "Garlic, fall peas, spinach and the late brassicas are counted back from it, and it is the end of the tomatoes."),
        ("How deep is a pea seed sown?",
         ["About an inch", "On the surface", "Four inches", "Six inches"], 0,
         "Most seed is sown at two to three times its own depth; a pea goes an inch down, a bean an inch or two, a carrot a quarter inch."),
        ("Why does the plan keep carrots away from a freshly thinned neighbour?",
         ["Carrot fly finds the crop by the smell of bruised leaves", "The roots tangle", "They compete for water", "The shade stunts them"], 0,
         "The fly lays at the crown when it smells a thinned row; thin in the evening and firm the soil back."),
        ("What does a seed tray entry in the plan represent?",
         ["A crop started indoors, waiting to be hardened off and set out", "A crop sown direct", "A harvest in store", "A bed left empty"], 0,
         "The tray holds the indoor start; the plan tells you when to harden it off and when its window opens."),
        ("A Prize grade at harvest needs what?",
         ["Inside the window, clear rotation, a companion beside it and good spacing", "The largest fruit", "The earliest date", "Watering every day"], 0,
         "Quality is scored from the window, the rotation, the neighbours and the spacing of the sowing."),
        ("Which of these families is the tallest and goes on the north side?",
         ["Grass (corn) and sunflowers", "Amaranth (beet, chard)", "Allium (onion, garlic)", "Aster (lettuce)"], 0,
         "Tall crops shade what stands south of them; corn and sunflowers go where their shadow falls on the path."),
        ("What is seed saving easiest from?",
         ["Self-pollinating annuals like tomato, bean and lettuce", "Biennials like carrot and cabbage", "Hybrids", "Squash and corn"], 0,
         "Self-pollinators come true; biennials need two years; cucurbits and corn cross with everything in reach."),
        ("Mulch does what for a bed in summer?",
         ["Holds water, evens the soil temperature and smothers weeds", "Feeds the plants directly", "Keeps frost off", "Attracts pollinators"], 0,
         "Straw, leaf mould or compost on the surface stops evaporation and keeps blossom-end rot away from the tomatoes.")
    ]

    static let authoredD: [(String, [String], Int, String)] = [
        ("Why does a spray for aphids usually make the aphids worse a fortnight later?",
         ["It kills the ladybirds and hoverfly larvae that were eating them", "It feeds the plant", "Aphids like the smell", "It warms the leaves"], 0,
         "The predators breed slower than the aphids, so a garden with no predators is recolonised by aphids first. Squash them by hand and leave the ladybirds."),
        ("A vine of zucchini wilts suddenly and there is sawdust at the base of the stem. What is inside?",
         ["A squash vine borer grub", "A slug", "A wireworm", "Nothing; it needs water"], 0,
         "The moist frass at the base marks the hole. Slit the stem, pick out the grub and bury the stem to root again."),
        ("What does a black, sunken patch on the bottom of a tomato mean?",
         ["Uneven watering; the calcium could not reach the fruit", "Blight from the potatoes", "Too much sun", "A caterpillar inside"], 0,
         "Blossom-end rot is a disorder, not a disease. Even watering and a mulch cure the next truss; nothing needs spraying."),
        ("A cabbage wilts in the afternoon sun and its root is a swollen club. How long does the bed stay off brassicas?",
         ["As long as the plan allows, seven years if possible", "One season", "A month", "Until the next rain"], 0,
         "Clubroot spores persist for years. Lime the bed toward pH 7.2 and keep the family away from it."),
        ("Which of these keeps carrot fly off a row?",
         ["A fine mesh barrier two feet high", "A spray of soap", "Sowing thickly and thinning often", "Watering in the evening"], 0,
         "The fly hunts low and by smell. A barrier stops it; thinning releases the smell that draws it."),
        ("Ten seeds on a damp towel sprouted four. What do you do with the packet?",
         ["Throw it away; under forty percent is not worth sowing", "Sow it at the usual rate", "Sow it half as thick", "Keep it another year"], 0,
         "Forty percent germination gives a patchy drill even sown thick. Buy fresh seed and write the year on it."),
        ("A saying that is true for zone 6 and a calendar date everywhere else:",
         ["Plant peas on St Patrick's Day", "April showers bring May flowers", "Frost sweetens the parsnip", "Red sky at night, gardener's delight"], 0,
         "March 17 is inside the pea window only where the last frost is around April 1. The almanac counts the window for every zone instead."),
        ("On a clear, still, dry evening near the frost date, what do you do before sunset?",
         ["Cover the tender crops and water the bed", "Nothing; clear skies mean warmth", "Prune the tomatoes", "Turn the compost"], 0,
         "A radiation frost comes on a clear still night. A cover put on before sunset traps the ground's heat, and wet soil holds more of it.")
    ]

    static var authoredAll: [(String, [String], Int, String)] { authoredA + authoredB + authoredC + authoredD }

    static func troubleCrop(_ rng: inout Furrow, _ id: Int) -> ExamQuestion? {
        let t = rng.pick(Troubles.all)
        let victim = Register.find(rng.pick(t.crops))
        let others = Register.crops.filter { !t.crops.contains($0.key) }
        var options = [victim.name]
        var tries = 0
        while options.count < 4 && tries < 40 {
            let c = rng.pick(others)
            if !options.contains(c.name) { options.append(c.name) }
            tries += 1
        }
        guard options.count == 4 else { return nil }
        options = rng.shuffled(options)
        let answer = options.firstIndex(of: victim.name) ?? 0
        return ExamQuestion(id: id, prompt: "Which of these crops suffers from \(t.name.lowercased())?",
                            options: options, answer: answer,
                            explanation: "\(t.name) is a \(t.kind.name.lowercased()) of \(t.cropNames), seen \(t.season). The sign is \(t.symptomWords).")
    }

    static func troubleAction(_ rng: inout Furrow, _ id: Int) -> ExamQuestion? {
        let t = rng.pick(Troubles.all)
        let remedies: [Remedy] = [.pickOff, .net, .waterBase, .mulch, .pull]
        var options = [t.remedy.title]
        for r in rng.shuffled(remedies) where options.count < 4 && !options.contains(r.title) { options.append(r.title) }
        options = rng.shuffled(options)
        let answer = options.firstIndex(of: t.remedy.title) ?? 0
        return ExamQuestion(id: id, prompt: "The bed shows \(t.symptomWords), and it is \(t.name.lowercased()). What is the first thing to do?",
                            options: options, answer: answer,
                            explanation: String(t.action.split(separator: ".").first.map { $0 + "." } ?? t.action))
    }

    static func troubleKind(_ rng: inout Furrow, _ id: Int) -> ExamQuestion? {
        let t = rng.pick(Troubles.all)
        let kinds: [TroubleKind] = [.pest, .disease, .disorder]
        let options = kinds.map { "A \($0.name.lowercased())" }
        let answer = kinds.firstIndex(of: t.kind) ?? 0
        return ExamQuestion(id: id, prompt: "\(t.name): is it a pest, a disease or a disorder?",
                            options: options, answer: answer,
                            explanation: "\(t.name) is a \(t.kind.name.lowercased()). \(t.kind.meaning)")
    }

    static func sayingVerdict(_ rng: inout Furrow, _ id: Int) -> ExamQuestion? {
        let saying = rng.pick(Sayings.all)
        let verdicts: [SayingVerdict] = [.truth, .half, .myth]
        let options = verdicts.map { $0.name }
        let answer = verdicts.firstIndex(of: saying.verdict) ?? 0
        return ExamQuestion(id: id, prompt: "The old saying goes: \(saying.text) Truth, half-truth or myth?",
                            options: options, answer: answer,
                            explanation: saying.note)
    }

    static func authored(_ rng: inout Furrow, _ id: Int) -> ExamQuestion? {
        let q = rng.pick(authoredAll)
        let correct = q.1[q.2]
        let options = rng.shuffled(q.1)
        let answer = options.firstIndex(of: correct) ?? 0
        return ExamQuestion(id: id, prompt: q.0, options: options, answer: answer, explanation: q.3)
    }
}
