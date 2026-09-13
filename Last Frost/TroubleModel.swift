import Foundation

enum TroubleKind: String, Codable {
    case pest, disease, disorder

    var name: String {
        switch self {
        case .pest: return "Pest"
        case .disease: return "Disease"
        case .disorder: return "Disorder"
        }
    }

    var meaning: String {
        switch self {
        case .pest: return "An animal that eats the crop. It can be picked, netted or trapped."
        case .disease: return "A fungus, bacterium or virus in the plant. It is managed by removing infected tissue, air and rotation."
        case .disorder: return "Nothing alive at all: water, heat, cold or feeding gone wrong. It is fixed by changing the growing, not by a spray."
        }
    }
}

enum Remedy: String, Codable {
    case pickOff, net, waterBase, mulch, pull

    var title: String {
        switch self {
        case .pickOff: return "Pick off"
        case .net: return "Net the square"
        case .waterBase: return "Water at the base"
        case .mulch: return "Mulch and firm"
        case .pull: return "Pull and bin"
        }
    }

    var instruction: String {
        switch self {
        case .pickOff: return "Tap each one you find on the plant until the square is clean."
        case .net: return "Drag the mesh across the square from left to right so it covers every plant."
        case .waterBase: return "Press and hold at the foot of the plant until the soil is dark and the can is empty."
        case .mulch: return "Scrub back and forth across the square to spread the mulch and firm the roots in."
        case .pull: return "Pull upward on the plant, steadily, until the root gives. It goes in the bin, not the compost."
        }
    }
}

enum Symptom: String, Codable {
    case holes, curl, pale, yellow, spots, powder, wilt, stalk, rot, split, lifted, pulled, tunnel, stripped
}

struct Trouble: Identifiable {
    let key: String
    let name: String
    let kind: TroubleKind
    let crops: [String]
    let monthFrom: Int
    let monthTo: Int
    let signs: String
    let remedy: Remedy
    let action: String
    let prevention: String
    let symptom: Symptom
    let count: Int

    var id: String { key }
    var plate: String { "tr_" + key }

    var season: String {
        let a = Almanac.monthNames[max(0, min(11, monthFrom - 1))]
        let b = Almanac.monthNames[max(0, min(11, monthTo - 1))]
        return monthFrom == monthTo ? a : a + " to " + b
    }

    func inSeason(month: Int) -> Bool {
        if monthFrom <= monthTo { return month >= monthFrom && month <= monthTo }
        return month >= monthFrom || month <= monthTo
    }

    var monthList: [Int] {
        var out: [Int] = []
        var m = monthFrom
        for _ in 0..<12 {
            out.append(m)
            if m == monthTo { break }
            m = m % 12 + 1
        }
        return out
    }

    var cropNames: String {
        crops.prefix(5).map { Register.find($0).name.lowercased() }.joined(separator: ", ") + (crops.count > 5 ? " and others" : "")
    }

    var symptomWords: String {
        switch symptom {
        case .holes: return "holes chewed in the leaves"
        case .curl: return "shoot tips curled and sticky"
        case .pale: return "pale winding blotches in the leaves"
        case .yellow: return "leaves yellowing from the bottom up"
        case .spots: return "brown spots and blotches spreading"
        case .powder: return "a white floury bloom on the leaves"
        case .wilt: return "plants wilting in the sun and not recovering"
        case .stalk: return "a tall flower stalk shooting up"
        case .rot: return "a sunken dark patch on the fruit"
        case .split: return "roots cracked open lengthwise"
        case .lifted: return "plants lifted half out of the soil"
        case .pulled: return "seedlings pulled up and scattered"
        case .tunnel: return "rusty tunnels bored through the root"
        case .stripped: return "stems stripped bare of leaves overnight"
        }
    }
}

extension Trouble {
    init(_ key: String, _ name: String, _ kind: TroubleKind, crops: [String], months: (Int, Int), signs: String,
         remedy: Remedy, action: String, prevention: String, symptom: Symptom, count: Int = 5) {
        self.key = key; self.name = name; self.kind = kind; self.crops = crops; self.monthFrom = months.0; self.monthTo = months.1
        self.signs = signs; self.remedy = remedy; self.action = action; self.prevention = prevention
        self.symptom = symptom; self.count = count
    }
}

enum Troubles {
    static let all: [Trouble] = TroublesA.list + TroublesB.list + TroublesC.list

    private static let index: [String: Int] = {
        var out: [String: Int] = [:]
        for (i, t) in all.enumerated() { out[t.key] = i }
        return out
    }()

    static func find(_ key: String) -> Trouble {
        if let i = index[key] { return all[i] }
        return all[0]
    }

    static func exists(_ key: String) -> Bool { index[key] != nil }

    static func affecting(_ crop: String) -> [Trouble] { all.filter { $0.crops.contains(crop) } }

    static func event(for day: Int, book: PlotBook) -> TroubleEvent? {
        var spots: [(String, Int, String)] = []
        for bed in book.beds {
            for (i, cell) in bed.cells.enumerated() {
                if let p = cell.planting {
                    let s = p.stage(on: day)
                    if s >= .sprout && s <= .mature { spots.append((bed.id, i, p.crop)) }
                }
            }
        }
        guard !spots.isEmpty else { return nil }
        var rng = Furrow(Almanac.seed(day) ^ 0x7B0B)
        if rng.unit() < 0.28 { return nil }
        let spot = rng.pick(spots)
        let month = Almanac.parts(of: day).month
        var pool = affecting(spot.2).filter { $0.inSeason(month: month) }
        if pool.isEmpty { pool = affecting(spot.2) }
        if pool.isEmpty { pool = all.filter { $0.inSeason(month: month) } }
        if pool.isEmpty { pool = all }
        let culprit = rng.pick(pool)
        var decoys = all.filter { $0.key != culprit.key && $0.symptom != culprit.symptom }
        decoys = rng.shuffled(decoys)
        var candidates = [culprit.key]
        for d in decoys where candidates.count < 3 {
            if d.kind == culprit.kind || rng.chance(0.5) { candidates.append(d.key) }
        }
        for d in decoys where candidates.count < 3 && !candidates.contains(d.key) { candidates.append(d.key) }
        candidates = rng.shuffled(candidates)
        return TroubleEvent(day: day, bedId: spot.0, cell: spot.1, crop: spot.2, trouble: culprit.key, candidates: candidates)
    }
}

struct TroubleEvent: Equatable {
    var day: Int
    var bedId: String
    var cell: Int
    var crop: String
    var trouble: String
    var candidates: [String]

    var id: String { "trouble-\(day)" }
}
