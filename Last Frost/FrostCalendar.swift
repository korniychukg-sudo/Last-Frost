import Foundation

struct Furrow {
    var s: UInt64
    init(_ seed: UInt64) { s = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 { s ^= s << 13; s ^= s >> 7; s ^= s << 17; return s }
    mutating func unit() -> Double { Double(next() % 1_000_000) / 1_000_000.0 }
    mutating func step(_ a: Int, _ b: Int) -> Int {
        guard b > a else { return a }
        return a + Int(next() % UInt64(b - a + 1))
    }
    mutating func chance(_ p: Double) -> Bool { unit() < p }
    mutating func pick<T>(_ list: [T]) -> T { list[step(0, list.count - 1)] }
    mutating func shuffled<T>(_ list: [T]) -> [T] {
        var out = list
        guard out.count > 1 else { return out }
        for i in stride(from: out.count - 1, to: 0, by: -1) {
            let j = step(0, i)
            out.swapAt(i, j)
        }
        return out
    }
}

func hashOf(_ text: String) -> UInt64 {
    var h: UInt64 = 14695981039346656037
    for b in text.utf8 { h = (h ^ UInt64(b)) &* 1099511628211 }
    return h
}

struct FrostDates: Codable, Equatable {
    var zone: Int
    var lastMonth: Int
    var lastDay: Int
    var firstMonth: Int
    var firstDay: Int

    static let zoneTable: [(Int, Int, Int, Int, Int)] = [
        (3, 5, 15, 9, 15), (4, 5, 1, 10, 1), (5, 4, 15, 10, 15), (6, 4, 1, 10, 31),
        (7, 3, 15, 11, 15), (8, 3, 1, 11, 30), (9, 2, 15, 12, 15), (10, 1, 15, 12, 31)
    ]

    static func forZone(_ zone: Int) -> FrostDates {
        let z = max(3, min(10, zone))
        let row = zoneTable.first { $0.0 == z } ?? zoneTable[3]
        return FrostDates(zone: z, lastMonth: row.1, lastDay: row.2, firstMonth: row.3, firstDay: row.4)
    }

    static let standard = FrostDates.forZone(6)

    var frostFree: Bool { zone >= 10 }
    var lastLabel: String { frostFree ? "No spring frost" : Almanac.monthDay(lastMonth, lastDay) }
    var firstLabel: String { frostFree ? "No fall frost" : Almanac.monthDay(firstMonth, firstDay) }

    var zoneNote: String {
        switch zone {
        case 3: return "A short cold season: last frost mid-May, first frost mid-September."
        case 4: return "Last frost around the first of May, first frost around the first of October."
        case 5: return "Last frost in mid-April, first frost in mid-October."
        case 6: return "Last frost at the start of April, first frost at the end of October."
        case 7: return "Last frost in mid-March, first frost in mid-November."
        case 8: return "Last frost at the start of March, first frost at the end of November."
        case 9: return "Last frost in mid-February, first frost in mid-December."
        default: return "No frost expected; the calendar runs from mid-January."
        }
    }
}

enum Almanac {
    static let epoch: TimeInterval = 1_767_225_600
    static let monthNames = ["January", "February", "March", "April", "May", "June", "July",
                             "August", "September", "October", "November", "December"]
    static let monthShort = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct",
                             "Nov", "Dec"]
    static let daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

    static var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        return cal
    }

    static func dayIndex(_ date: Date = Date()) -> Int {
        let offset = Double(TimeZone.current.secondsFromGMT(for: date))
        return Int(floor((date.timeIntervalSince1970 + offset - epoch) / 86_400))
    }

    static func date(of day: Int) -> Date {
        let utcNoon = Date(timeIntervalSince1970: epoch + Double(day) * 86_400 + 43_200)
        let offset = Double(TimeZone.current.secondsFromGMT(for: utcNoon))
        return Date(timeIntervalSince1970: epoch + Double(day) * 86_400 + 43_200 - offset)
    }

    static func dayIndex(year: Int, month: Int, day: Int) -> Int {
        var parts = DateComponents()
        parts.year = year
        parts.month = month
        parts.day = min(day, daysIn(month: month, year: year))
        parts.hour = 12
        guard let date = calendar.date(from: parts) else { return 0 }
        return dayIndex(date)
    }

    static func daysIn(month: Int, year: Int) -> Int {
        if month == 2 { return leap(year) ? 29 : 28 }
        return daysInMonth[max(0, min(11, month - 1))]
    }

    static func leap(_ year: Int) -> Bool {
        (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
    }

    static func parts(of day: Int) -> (year: Int, month: Int, day: Int) {
        let c = calendar.dateComponents([.year, .month, .day], from: date(of: day))
        return (c.year ?? 2026, c.month ?? 1, c.day ?? 1)
    }

    static func year(of day: Int) -> Int { parts(of: day).year }

    static func monthDay(_ month: Int, _ day: Int) -> String {
        "\(monthShort[max(0, min(11, month - 1))]) \(day)"
    }

    static func label(_ day: Int) -> String {
        let p = parts(of: day)
        return monthDay(p.month, p.day)
    }

    static func labelLong(_ day: Int) -> String {
        let p = parts(of: day)
        return "\(monthNames[p.month - 1]) \(p.day), \(p.year)"
    }

    static func seed(_ day: Int) -> UInt64 {
        var h = UInt64(bitPattern: Int64(day)) &* 0x9E3779B97F4A7C15
        h ^= h >> 29
        h = h &* 0xBF58476D1CE4E5B9
        h ^= h >> 32
        return h == 0 ? 1 : h
    }

    static func hourNow(_ date: Date = Date()) -> Double {
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return Double(c.hour ?? 12) + Double(c.minute ?? 0) / 60
    }

    static func season(of day: Int) -> Int {
        let m = parts(of: day).month
        switch m {
        case 3, 4, 5: return 1
        case 6, 7, 8: return 2
        case 9, 10, 11: return 3
        default: return 0
        }
    }

    static let seasonNames = ["Winter", "Spring", "Summer", "Autumn"]

    static func dayOfYear(_ day: Int) -> Int {
        let p = parts(of: day)
        return day - dayIndex(year: p.year, month: 1, day: 1)
    }

    static func daysInYear(_ year: Int) -> Int { leap(year) ? 366 : 365 }

    static func relative(_ day: Int, to today: Int) -> String {
        let d = day - today
        if d == 0 { return "due today" }
        if d == 1 { return "tomorrow" }
        if d == -1 { return "overdue by a day" }
        if d < 0 { return "overdue by \(-d) days" }
        if d < 14 { return "in \(d) days" }
        if d < 60 { return "in \(d / 7) weeks" }
        return "in \(d / 30) months"
    }
}

struct FrostYear: Equatable {
    let year: Int
    let lastFrost: Int
    let firstFrost: Int

    init(_ dates: FrostDates, year: Int) {
        self.year = year
        lastFrost = Almanac.dayIndex(year: year, month: dates.lastMonth, day: dates.lastDay)
        firstFrost = Almanac.dayIndex(year: year, month: dates.firstMonth, day: dates.firstDay)
    }

    var jan1: Int { Almanac.dayIndex(year: year, month: 1, day: 1) }
    var dec31: Int { Almanac.dayIndex(year: year, month: 12, day: 31) }
}

struct DayWindow: Equatable {
    var start: Int
    var end: Int
    func contains(_ d: Int) -> Bool { d >= start && d <= end }
    var label: String {
        start == end ? Almanac.label(start) : "\(Almanac.label(start)) to \(Almanac.label(end))"
    }
    var length: Int { end - start + 1 }
}

enum SowKind: Equatable {
    case direct, transplant, startIndoors, fall, wait, tooLate, resting
}

struct SowVerdict: Equatable {
    var kind: SowKind
    var text: String
    var opens: Int?
}

enum Planner {
    static func indoorsWindow(_ crop: Crop, _ fy: FrostYear) -> DayWindow? {
        guard let w = crop.indoors else { return nil }
        return DayWindow(start: fy.lastFrost - w.upperBound * 7, end: fy.lastFrost - w.lowerBound * 7)
    }

    static func transplantWindow(_ crop: Crop, _ fy: FrostYear) -> DayWindow? {
        guard let w = crop.transplant else { return nil }
        return DayWindow(start: fy.lastFrost + w.lowerBound * 7, end: fy.lastFrost + w.upperBound * 7)
    }

    static func directWindow(_ crop: Crop, _ fy: FrostYear) -> DayWindow? {
        guard let w = crop.direct else { return nil }
        return DayWindow(start: fy.lastFrost + w.lowerBound * 7, end: fy.lastFrost + w.upperBound * 7)
    }

    static func fallWindow(_ crop: Crop, _ fy: FrostYear) -> DayWindow? {
        guard let w = crop.fall else { return nil }
        return DayWindow(start: fy.firstFrost - w.upperBound * 7, end: fy.firstFrost - w.lowerBound * 7)
    }

    static func harvestWindow(_ crop: Crop, from start: Int) -> DayWindow {
        DayWindow(start: start + crop.maturity.lowerBound,
                  end: start + crop.maturity.upperBound + crop.window)
    }

    static func hardenWindow(_ crop: Crop, _ fy: FrostYear) -> DayWindow? {
        guard let t = transplantWindow(crop, fy) else { return nil }
        return DayWindow(start: t.start - 10, end: t.start - 3)
    }

    static func latestSuccession(_ crop: Crop, _ fy: FrostYear) -> Int? {
        guard crop.succession != nil else { return nil }
        let margin = crop.hardiness == .hardy ? 0 : 7
        return fy.firstFrost - crop.maturity.lowerBound - margin
    }

    static func firstHarvest(_ crop: Crop, _ fy: FrostYear) -> DayWindow? {
        if let t = transplantWindow(crop, fy) {
            return DayWindow(start: t.start + crop.maturity.lowerBound, end: t.end + crop.maturity.upperBound)
        }
        if let d = directWindow(crop, fy) {
            return DayWindow(start: d.start + crop.maturity.lowerBound, end: d.end + crop.maturity.upperBound)
        }
        if let f = fallWindow(crop, fy) {
            return DayWindow(start: f.start + crop.maturity.lowerBound, end: f.end + crop.maturity.upperBound)
        }
        return nil
    }

    static func weeksText(_ r: ClosedRange<Int>, before: Bool) -> String {
        let a = abs(r.lowerBound), b = abs(r.upperBound)
        let span = a == b ? "\(a)" : "\(min(a, b)) to \(max(a, b))"
        let unit = max(a, b) == 1 ? "week" : "weeks"
        return "\(span) \(unit) \(before ? "before" : "after")"
    }

    static func relativeText(_ r: ClosedRange<Int>) -> String {
        if r.upperBound <= 0 && r.lowerBound < 0 {
            return weeksText(r, before: true) + " the last frost"
        }
        if r.lowerBound >= 0 && r.upperBound > 0 {
            return weeksText(r, before: false) + " the last frost"
        }
        if r.lowerBound == 0 && r.upperBound == 0 { return "at the last frost" }
        return "from \(abs(r.lowerBound)) weeks before to \(r.upperBound) weeks after the last frost"
    }

    static func openVerdict(for crop: Crop, on day: Int, _ fy: FrostYear) -> SowVerdict? {
        let grace = 7
        if let d = directWindow(crop, fy) {
            if d.contains(day) || (day > d.end && day <= d.end + grace) {
                return SowVerdict(kind: .direct, text: "\(crop.plural) can be sown direct now; the window is \(d.label).", opens: nil)
            }
            if let latest = latestSuccession(crop, fy), day > d.end, day <= latest {
                return SowVerdict(kind: .direct, text: "\(crop.plural) can still be sown direct as a succession; the last sowing that ripens before the first frost is \(Almanac.label(latest)).", opens: nil)
            }
        }
        if let f = fallWindow(crop, fy), f.contains(day) || (day > f.end && day <= f.end + grace) {
            return SowVerdict(kind: .fall, text: "This is the fall sowing for \(crop.plural.lowercased()): \(f.label), counted back from your first frost on \(Almanac.label(fy.firstFrost)).", opens: nil)
        }
        if let t = transplantWindow(crop, fy) {
            if t.contains(day) || (day > t.end && day <= t.end + 14) {
                return SowVerdict(kind: .transplant, text: "\(crop.plural) go out as transplants now; the window is \(t.label).", opens: nil)
            }
            if let latest = latestSuccession(crop, fy), day > t.end, day <= latest {
                return SowVerdict(kind: .transplant, text: "\(crop.plural) can still go out as a late succession; the last planting that ripens before the first frost is \(Almanac.label(latest)).", opens: nil)
            }
        }
        if let i = indoorsWindow(crop, fy), i.contains(day) || (day > i.end && day < (transplantWindow(crop, fy)?.start ?? i.end)) {
            let t = transplantWindow(crop, fy)
            let outText = t.map { "they go out \(relativeText(crop.transplant ?? 0...0)); that is \($0.label) for you" } ?? ""
            return SowVerdict(kind: .startIndoors, text: "\(crop.plural) \(outText). Start them indoors now instead.", opens: t?.start)
        }
        return nil
    }

    static func verdict(for crop: Crop, on day: Int, dates: FrostDates) -> SowVerdict {
        let year = Almanac.year(of: day)
        let fy = FrostYear(dates, year: year)
        let next = FrostYear(dates, year: year + 1)
        if let open = openVerdict(for: crop, on: day, fy) { return open }
        if let open = openVerdict(for: crop, on: day, next) { return open }
        let candidates: [Int] = [directWindow(crop, fy)?.start, transplantWindow(crop, fy)?.start,
                                 indoorsWindow(crop, fy)?.start, fallWindow(crop, fy)?.start,
                                 directWindow(crop, next)?.start, transplantWindow(crop, next)?.start,
                                 indoorsWindow(crop, next)?.start, fallWindow(crop, next)?.start]
            .compactMap { $0 }.filter { $0 > day }
        if let soonest = candidates.min() {
            let wait = soonest - day
            let how: String
            if directWindow(crop, fy)?.start == soonest || directWindow(crop, next)?.start == soonest { how = "direct sowing opens" }
            else if transplantWindow(crop, fy)?.start == soonest || transplantWindow(crop, next)?.start == soonest { how = "planting out opens" }
            else if indoorsWindow(crop, fy)?.start == soonest || indoorsWindow(crop, next)?.start == soonest { how = "the indoor start opens" }
            else if fallWindow(crop, fy)?.start == soonest || fallWindow(crop, next)?.start == soonest { how = "the fall sowing opens" }
            else { how = "the next window opens" }
            if wait > 120 {
                return SowVerdict(kind: .tooLate, text: "Too late for \(crop.plural.lowercased()) this season; \(how) on \(Almanac.label(soonest)).", opens: soonest)
            }
            return SowVerdict(kind: .wait, text: "Wait \(wait) days: \(how) on \(Almanac.label(soonest)) for your frost dates.", opens: soonest)
        }
        return SowVerdict(kind: .resting, text: "\(crop.plural) have no window left this year.", opens: nil)
    }

    static func summaryLine(_ crop: Crop, _ dates: FrostDates, year: Int) -> String {
        let fy = FrostYear(dates, year: year)
        var parts: [String] = []
        if let i = indoorsWindow(crop, fy) { parts.append("indoors \(i.label)") }
        if let t = transplantWindow(crop, fy) { parts.append("out \(t.label)") }
        if let d = directWindow(crop, fy) { parts.append("direct \(d.label)") }
        if let f = fallWindow(crop, fy) { parts.append("fall \(f.label)") }
        return parts.joined(separator: "; ")
    }
}

enum Stage: Int, Codable, Comparable {
    case bare = 0, seed, sprout, leaf, flower, mature, spent

    static func < (a: Stage, b: Stage) -> Bool { a.rawValue < b.rawValue }

    var name: String {
        switch self {
        case .bare: return "Bare"
        case .seed: return "Sown"
        case .sprout: return "Sprouting"
        case .leaf: return "In leaf"
        case .flower: return "Flowering"
        case .mature: return "Ready"
        case .spent: return "Spent"
        }
    }
}

struct Planting: Codable, Equatable {
    var crop: String
    var sowDay: Int
    var method: Int
    var seeds: Int
    var spacing: Int
    var thinned: Bool
    var rotation: Int
    var companions: Int
    var antagonists: Int
    var watered: Int?

    var isTransplant: Bool { method == 1 }

    func stage(on day: Int) -> Stage {
        let c = Register.find(crop)
        if day < sowDay { return .bare }
        let elapsed = day - sowDay
        let lo = max(1, c.maturity.lowerBound)
        let harvestEnd = c.maturity.upperBound + c.window
        if elapsed > harvestEnd + 14 { return .bare }
        if elapsed > harvestEnd { return .spent }
        if elapsed >= lo { return .mature }
        var f = Double(elapsed) / Double(lo)
        if isTransplant { f = 0.30 + f * 0.70 }
        if f < 0.10 { return .seed }
        if f < 0.30 { return .sprout }
        if f < 0.62 { return .leaf }
        return .flower
    }

    func growth(on day: Int) -> Double {
        let c = Register.find(crop)
        guard day >= sowDay else { return 0 }
        let lo = max(1, c.maturity.lowerBound)
        var f = Double(day - sowDay) / Double(lo)
        if isTransplant { f = 0.30 + f * 0.70 }
        return max(0, min(1, f))
    }

    func harvest(_ c: Crop) -> DayWindow { Planner.harvestWindow(c, from: sowDay) }

    func inWindow(on day: Int) -> Bool { harvest(Register.find(crop)).contains(day) }

    var tooDense: Bool { seeds > Register.find(crop).perCell }
}

enum Weather: Int {
    case clear = 0, cloud, rain, frost

    var name: String {
        switch self {
        case .clear: return "Clear"
        case .cloud: return "Overcast"
        case .rain: return "Rain"
        case .frost: return "Frost"
        }
    }

    static func at(day: Int, dates: FrostDates) -> Weather {
        var rng = Furrow(Almanac.seed(day) ^ 0x5EA5)
        let fy = FrostYear(dates, year: Almanac.year(of: day))
        let nearFrost = abs(day - fy.lastFrost) <= 14 || abs(day - fy.firstFrost) <= 14
        let deepCold = !dates.frostFree && (day < fy.lastFrost - 14 || day > fy.firstFrost + 14)
        let roll = rng.unit()
        if deepCold {
            if roll < 0.40 { return .frost }
            if roll < 0.60 { return .cloud }
            if roll < 0.78 { return .rain }
            return .clear
        }
        if nearFrost && roll < 0.22 { return .frost }
        if roll < 0.47 { return .rain }
        if roll < 0.70 { return .cloud }
        return .clear
    }
}
