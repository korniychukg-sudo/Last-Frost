import Foundation

struct Cell: Codable, Equatable {
    var planting: Planting?
    var stake: String?
    var wateredDay: Int?
}

struct Bed: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var cols: Int
    var rows: Int
    var cells: [Cell]
    var history: [[String]]
    var seasonFamilies: [String]?

    static func make(_ id: String, name: String, cols: Int = 4, rows: Int = 2) -> Bed {
        Bed(id: id, name: name, cols: cols, rows: rows,
            cells: Array(repeating: Cell(), count: cols * rows), history: [], seasonFamilies: [])
    }

    var planted: Int { cells.filter { $0.planting != nil }.count }
    var staked: Int { cells.filter { $0.stake != nil && $0.planting == nil }.count }

    func neighbours(of index: Int) -> [Int] {
        let c = index % cols, r = index / cols
        var out: [Int] = []
        if c > 0 { out.append(index - 1) }
        if c < cols - 1 { out.append(index + 1) }
        if r > 0 { out.append(index - cols) }
        if r < rows - 1 { out.append(index + cols) }
        return out
    }

    var familiesThisSeason: [String] {
        var seen: [String] = seasonFamilies ?? []
        for cell in cells {
            if let p = cell.planting {
                let f = Register.find(p.crop).botanical
                if !seen.contains(f) { seen.append(f) }
            }
        }
        return seen
    }

    var lastSeason: [String] { history.last ?? [] }
    var seasonBefore: [String] { history.count >= 2 ? history[history.count - 2] : [] }
}

struct SeedTray: Codable, Identifiable, Equatable {
    var id: String
    var crop: String
    var sowDay: Int
    var hardenedDay: Int?
    var prickedDay: Int?
    var shelf: Int?

    func seedlingHeight(on day: Int) -> Double {
        let c = Register.find(crop)
        let span = Double(max(14, (c.indoors?.lowerBound ?? 4) * 7))
        return max(0, min(1, Double(day - sowDay) / span))
    }

    var pricked: Bool { prickedDay != nil }
    var hardening: Bool { hardenedDay != nil }

    func hardenDaysDone(on day: Int) -> Int {
        guard let h = hardenedDay else { return 0 }
        return max(0, min(7, day - h + 1))
    }

    func canPrick(on day: Int) -> Bool { !pricked && seedlingHeight(on: day) >= 0.35 }
}

struct LarderEntry: Codable, Identifiable, Equatable {
    var crop: String
    var quality: Int
    var day: Int
    var bed: String
    var season: Int
    var count: Int
    var id: String { crop }

    var qualityWord: String {
        switch quality {
        case 2: return "Prize"
        case 1: return "Good"
        default: return "Fair"
        }
    }
}

struct SeasonRecord: Codable, Identifiable, Equatable {
    var number: Int
    var year: Int
    var closedDay: Int
    var harvests: Int
    var prize: Int
    var families: [String]
    var beds: Int
    var sowings: Int
    var id: Int { number }
}

struct PlotBook: Codable {
    var frost: FrostDates = .standard
    var beds: [Bed] = []
    var trays: [SeedTray] = []
    var larder: [LarderEntry] = []
    var seasons: [SeasonRecord] = []
    var seasonNumber: Int = 1
    var points: Int = 0
    var streak: Int = 0
    var bestStreak: Int = 0
    var lastDay: Int = -1
    var daysDone: [Int] = []
    var doneJobs: [String] = []
    var notesSolved: [Int] = []
    var seenIntro: Bool? = nil
    var readLessons: [String]? = nil
    var readTerms: [String]? = nil
    var examBest: Int? = nil
    var examsTaken: Int? = nil
    var badges: [String]? = nil
    var harvestCount: Int? = nil
    var sowCount: Int? = nil
    var coveredDays: [Int]? = nil
    var seasonYear: Int? = nil
    var harvestSeasons: [Int]? = nil
    var bedCounter: Int? = nil
    var noteTries: [Int]? = nil
    var uiTab: Int? = nil
    var uiBed: String? = nil
    var uiCell: Int? = nil
    var uiCrop: String? = nil
    var uiSection: Int? = nil
    var uiLesson: String? = nil
    var uiScrub: Int? = nil
    var troublesSolved: [String]? = nil
    var troubleMisses: [String]? = nil
    var troublesCount: Int? = nil
    var sayingsRead: [String]? = nil
    var hardenCount: Int? = nil
    var prickCount: Int? = nil
    var coverCount: Int? = nil
    var troublesSeen: [String]? = nil
}

enum RotationVerdict: Int {
    case clear = 0, warn, strong, bonus

    var text: String {
        switch self {
        case .clear: return "Rotation is clear: this family did not stand here last season."
        case .warn: return "Same family as last season in this bed; pests and disease carry over."
        case .strong: return "This family has held this bed two seasons running; a third is asking for trouble."
        case .bonus: return "Legumes stood here last season and left nitrogen for a brassica. Good rotation."
        }
    }
}

struct NeighbourReport: Equatable {
    var companions: [String]
    var antagonists: [String]
    var text: String {
        if companions.isEmpty && antagonists.isEmpty { return "No companions or antagonists beside it." }
        var parts: [String] = []
        if !companions.isEmpty {
            parts.append("Beside a companion: " + companions.map { Register.find($0).name.lowercased() }.joined(separator: ", "))
        }
        if !antagonists.isEmpty {
            parts.append("Beside an antagonist: " + antagonists.map { Register.find($0).name.lowercased() }.joined(separator: ", "))
        }
        return parts.joined(separator: ". ") + "."
    }
}

enum Rotation {
    static func check(_ crop: Crop, in bed: Bed) -> RotationVerdict {
        let family = crop.botanical
        let last = bed.lastSeason
        let before = bed.seasonBefore
        if last.contains(family) && before.contains(family) { return .strong }
        if last.contains(family) { return .warn }
        if family == "Brassicaceae" && last.contains("Fabaceae") { return .bonus }
        return .clear
    }

    static func neighbours(of crop: Crop, at index: Int, in bed: Bed) -> NeighbourReport {
        var companions: [String] = []
        var antagonists: [String] = []
        for n in bed.neighbours(of: index) {
            guard let other = bed.cells[n].planting?.crop ?? bed.cells[n].stake else { continue }
            let otherCrop = Register.find(other)
            let friendly = crop.companions.contains(other) || otherCrop.companions.contains(crop.key)
            let hostile = crop.antagonists.contains(other) || otherCrop.antagonists.contains(crop.key)
            if hostile { if !antagonists.contains(other) { antagonists.append(other) } }
            else if friendly { if !companions.contains(other) { companions.append(other) } }
        }
        return NeighbourReport(companions: companions, antagonists: antagonists)
    }

    static func quality(inWindow: Bool, rotation: Int, companions: Int, antagonists: Int, spacing: Int) -> Int {
        var score = 0
        if inWindow { score += 2 }
        if rotation == RotationVerdict.clear.rawValue || rotation == RotationVerdict.bonus.rawValue { score += 1 }
        if companions > 0 && antagonists == 0 { score += 1 }
        if spacing >= 70 { score += 1 }
        if antagonists > 0 { score -= 1 }
        if score >= 4 { return 2 }
        if score >= 2 { return 1 }
        return 0
    }
}

enum JobKind: String, Codable {
    case layout, sowIndoors, harden, transplant, directSow, fallSow, thin, water, harvest, clear, cover, closeSeason
}

struct Job: Identifiable, Equatable {
    var id: String
    var kind: JobKind
    var title: String
    var detail: String
    var due: Int
    var crop: String?
    var bed: String?
    var cell: Int?
    var tray: String?
    var points: Int

    var needsPlot: Bool { kind == .transplant || kind == .directSow || kind == .fallSow || kind == .harvest }
}

enum Jobs {
    static func list(_ book: PlotBook, today: Int) -> [Job] {
        var out: [Job] = []
        let dates = book.frost
        let year = Almanac.year(of: today)
        let fy = FrostYear(dates, year: year)
        let weather = Weather.at(day: today, dates: dates)

        if book.beds.isEmpty || book.beds.allSatisfy({ $0.planted == 0 && $0.staked == 0 }) {
            out.append(Job(id: "layout-\(book.seasonNumber)", kind: .layout, title: "Lay out a bed and stake a crop",
                           detail: "The plot is empty. Open the Plot, add a bed and drag a crop onto a square to plan the first sowing.",
                           due: today, crop: nil, bed: nil, cell: nil, tray: nil, points: 5))
        }

        for tray in book.trays {
            let crop = Register.find(tray.crop)
            guard let t = Planner.transplantWindow(crop, fy) else { continue }
            let ready = tray.sowDay + (crop.indoors.map { $0.lowerBound * 7 } ?? 21)
            let latest = Planner.latestSuccession(crop, fy) ?? (t.end + 14)
            let outDue = max(t.start, ready)
            guard outDue <= latest || today <= latest else { continue }
            let hardenDue = outDue - 7
            if tray.hardenedDay == nil && today >= hardenDue - 3 {
                out.append(Job(id: "harden-\(tray.id)", kind: .harden, title: "Harden off the \(crop.plural.lowercased())",
                               detail: "A week of days outside and nights in, before they go out on \(Almanac.label(outDue)).",
                               due: hardenDue, crop: crop.key, bed: nil, cell: nil, tray: tray.id, points: 6))
            }
            if today >= outDue - 2 {
                out.append(Job(id: "transplant-\(tray.id)", kind: .transplant, title: "Set out the \(crop.plural.lowercased())",
                               detail: "The window is \(t.label)\(outDue > t.end ? ", and a late succession is still in time" : ""). Drag the tray chip onto a square in the Plot.",
                               due: outDue, crop: crop.key, bed: nil, cell: nil, tray: tray.id, points: 10))
            }
        }

        for bed in book.beds {
            var wateringWanted = false
            var tenderOut = false
            for (i, cell) in bed.cells.enumerated() {
                if let stake = cell.stake, cell.planting == nil {
                    let crop = Register.find(stake)
                    let v = Planner.verdict(for: crop, on: today, dates: dates)
                    switch v.kind {
                    case .direct:
                        let window = Planner.directWindow(crop, fy)
                        let inWindow = window.map { today <= $0.end + 7 } ?? false
                        let due = inWindow ? min(window?.start ?? today, today) : today
                        out.append(Job(id: "direct-\(bed.id)-\(i)-\(stake)-\(year)", kind: .directSow,
                                       title: "Direct-sow \(crop.plural.lowercased()) in \(bed.name)",
                                       detail: inWindow ? "Press and hold the staked square, then draw the drill along the row."
                                            : "A succession sowing is still in time until \(Almanac.label(Planner.latestSuccession(crop, fy) ?? today)). Press and hold the staked square, then draw the drill.",
                                       due: due, crop: stake, bed: bed.id, cell: i, tray: nil, points: 10))
                    case .fall:
                        let start = Planner.fallWindow(crop, fy)?.start ?? today
                        out.append(Job(id: "fall-\(bed.id)-\(i)-\(stake)-\(year)", kind: .fallSow,
                                       title: "Fall-sow \(crop.plural.lowercased()) in \(bed.name)",
                                       detail: "Counted back from the first frost on \(Almanac.label(fy.firstFrost)).",
                                       due: min(start, today), crop: stake, bed: bed.id, cell: i, tray: nil, points: 10))
                    case .startIndoors:
                        if !book.trays.contains(where: { $0.crop == stake }) {
                            let start = Planner.indoorsWindow(crop, fy)?.start ?? today
                            out.append(Job(id: "indoors-\(stake)-\(year)", kind: .sowIndoors,
                                           title: "Sow \(crop.plural.lowercased()) indoors",
                                           detail: "\(Planner.weeksText(crop.indoors ?? 6...8, before: true)) the last frost. Tick to start a seed tray.",
                                           due: min(start, today), crop: stake, bed: bed.id, cell: i, tray: nil, points: 8))
                        }
                    case .transplant:
                        if !book.trays.contains(where: { $0.crop == stake }) && crop.indoors == nil {
                            let window = Planner.transplantWindow(crop, fy)
                            let inWindow = window.map { today <= $0.end + 14 } ?? false
                            out.append(Job(id: "setout-\(bed.id)-\(i)-\(stake)-\(year)", kind: .transplant,
                                           title: "Plant \(crop.plural.lowercased()) in \(bed.name)",
                                           detail: "Crowns or sets go in now; press and hold the staked square.",
                                           due: inWindow ? min(window?.start ?? today, today) : today, crop: stake, bed: bed.id, cell: i, tray: nil, points: 10))
                        }
                    case .wait:
                        if let opens = v.opens, opens - today <= 21 {
                            let indoorsFirst = Planner.indoorsWindow(crop, fy).map { $0.start == opens } ?? false
                            out.append(Job(id: "ahead-\(bed.id)-\(i)-\(stake)-\(opens)", kind: indoorsFirst ? .sowIndoors : .directSow,
                                           title: indoorsFirst ? "Sow \(crop.plural.lowercased()) indoors" : "Sow \(crop.plural.lowercased()) in \(bed.name)",
                                           detail: "The window opens on \(Almanac.label(opens)).",
                                           due: opens, crop: stake, bed: bed.id, cell: i, tray: nil, points: indoorsFirst ? 8 : 10))
                        }
                    default:
                        break
                    }
                }
                if let p = cell.planting {
                    let crop = Register.find(p.crop)
                    let stage = p.stage(on: today)
                    if stage >= .seed && stage <= .mature { wateringWanted = true }
                    if stage >= .sprout && stage <= .mature && crop.hardiness.rawValue >= Hardiness.tender.rawValue { tenderOut = true }
                    if p.tooDense && !p.thinned && stage >= .sprout && stage <= .leaf {
                        let due = p.sowDay + max(5, Int(Double(crop.maturity.lowerBound) * 0.12))
                        out.append(Job(id: "thin-\(bed.id)-\(i)-\(p.sowDay)", kind: .thin,
                                       title: "Thin the \(crop.plural.lowercased()) in \(bed.name)",
                                       detail: "\(p.seeds) seeds went into a square that takes \(crop.perCell). Thin to \(crop.perCell), \(crop.spacing) inches apart.",
                                       due: due, crop: p.crop, bed: bed.id, cell: i, tray: nil, points: 8))
                    }
                    if stage == .mature {
                        let w = p.harvest(crop)
                        let left = w.end - today
                        out.append(Job(id: "harvest-\(bed.id)-\(i)-\(p.sowDay)", kind: .harvest,
                                       title: "Harvest \(crop.plural.lowercased()) in \(bed.name)",
                                       detail: "In the window since \(Almanac.label(w.start)); \(left == 0 ? "the last day is today" : "\(left) days left"). Pull the square in the Plot to send it to the larder.",
                                       due: today, crop: p.crop, bed: bed.id, cell: i, tray: nil, points: 12))
                    }
                    if stage == .spent {
                        let w = p.harvest(crop)
                        out.append(Job(id: "clear-\(bed.id)-\(i)-\(p.sowDay)", kind: .clear,
                                       title: "Clear the spent \(crop.plural.lowercased()) in \(bed.name)",
                                       detail: "The window closed on \(Almanac.label(w.end)). Clear the square and compost the plant.",
                                       due: w.end + 1, crop: p.crop, bed: bed.id, cell: i, tray: nil, points: 5))
                    }
                }
            }
            let bedWatered = bed.cells.contains { $0.wateredDay == today }
            if wateringWanted && weather != .rain && !bedWatered && !(deepWinter(today, fy) && !dates.frostFree) {
                out.append(Job(id: "water-\(bed.id)-\(today)", kind: .water, title: "Water \(bed.name)",
                               detail: weather == .clear ? "A clear day; give the bed a deep watering at the root."
                                    : "Overcast, but the soil is drying. Water at the root, not the leaf.",
                               due: today, crop: nil, bed: bed.id, cell: nil, tray: nil, points: 4))
            }
            if tenderOut && weather == .frost && !(book.coveredDays ?? []).contains(today) {
                out.append(Job(id: "cover-\(bed.id)-\(today)", kind: .cover, title: "Cover the tender crops in \(bed.name)",
                               detail: "Frost is forecast tonight. Fleece or an upturned pot over anything tender.",
                               due: today, crop: nil, bed: bed.id, cell: nil, tray: nil, points: 8))
            }
        }

        if !dates.frostFree && today > fy.firstFrost + 7 && (book.seasonYear ?? year) <= year
            && book.beds.contains(where: { $0.planted > 0 }) {
            out.append(Job(id: "close-\(year)", kind: .closeSeason, title: "Close the season",
                           detail: "The first frost has passed. Record this year's families in each bed so next year's rotation can be checked.",
                           due: fy.firstFrost + 7, crop: nil, bed: nil, cell: nil, tray: nil, points: 20))
        }

        return out.sorted { a, b in
            if a.due != b.due { return a.due < b.due }
            return a.title < b.title
        }
    }

    static func deepWinter(_ day: Int, _ fy: FrostYear) -> Bool {
        day < fy.lastFrost - 42 || day > fy.firstFrost + 21
    }
}

enum Ladder {
    static let steps: [(Int, String, String)] = [
        (0, "Allotment Novice", "You have a plot, a packet of seed and the frost dates. Everything else is ahead of you."),
        (120, "Kitchen Gardener", "The first sowings are in and the first jobs ticked. The plan is starting to run itself."),
        (400, "Head of Beds", "You keep the rotation, thin on time and harvest inside the window. The beds answer to you."),
        (900, "Master Grower", "Succession, companions and the fall sowings are second nature. The larder is filling."),
        (1700, "Head Gardener", "The whole year is in your head before it happens. Nothing above this but the weather.")
    ]

    static func index(for points: Int) -> Int {
        var i = 0
        for (k, step) in steps.enumerated() where points >= step.0 { i = k }
        return i
    }
}

struct Badge: Identifiable {
    let key: String
    let name: String
    let text: String
    var id: String { key }

    static let all: [Badge] = [
        Badge(key: "firstSowing", name: "First Sowing", text: "The first seed went into the ground."),
        Badge(key: "firstHarvest", name: "First Harvest", text: "The first square was pulled inside its window."),
        Badge(key: "fullRotation", name: "Full Rotation", text: "One bed has held three different families over three seasons."),
        Badge(key: "fourSeason", name: "Four-Season Plot", text: "Harvests logged in winter, spring, summer and autumn."),
        Badge(key: "examined", name: "Examined", text: "Passed the examination in the Book with four correct in five."),
        Badge(key: "larderTwenty", name: "Full Shelves", text: "Twenty different crops on the larder shelves."),
        Badge(key: "plantDoctor", name: "Plant Doctor", text: "Ten troubles in the beds identified and put right."),
        Badge(key: "underLamp", name: "Under the Lamp", text: "A tray of seedlings pricked out into cells."),
        Badge(key: "hardenedOff", name: "Hardened Off", text: "Five trays carried out to the doorstep and hardened off."),
        Badge(key: "oldSaying", name: "Old Saying", text: "Twelve of the almanac's sayings read and weighed."),
        Badge(key: "prizeTen", name: "Ten at Prize", text: "Ten larder slots at the Prize grade."),
        Badge(key: "weatherEye", name: "Weather Eye", text: "The tender crops covered on three frost nights.")
    ]
}
