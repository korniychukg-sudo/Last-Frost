import Foundation

var failures: [String: Int] = [:]
var checks = 0

func fail(_ message: String) { failures[message, default: 0] += 1 }
func expect(_ condition: Bool, _ message: @autoclosure () -> String) {
    checks += 1
    if !condition { fail(message()) }
}

let artDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ""

func day(_ year: Int, _ month: Int, _ d: Int) -> Int { Almanac.dayIndex(year: year, month: month, day: d) }

print("== register ==")
let keys = Register.crops.map { $0.key }
expect(Register.crops.count == 60, "register does not hold 60 crops")
expect(Set(keys).count == keys.count, "duplicate crop keys")
for crop in Register.crops {
    expect(!crop.name.isEmpty && !crop.latin.isEmpty && !crop.botanical.isEmpty, "crop \(crop.key) missing names")
    expect(crop.note.split(separator: " ").count >= 55, "crop \(crop.key) note under 55 words (\(crop.note.split(separator: " ").count))")
    expect(crop.note.split(separator: " ").count <= 100, "crop \(crop.key) note over 100 words")
    expect(crop.trouble.split(separator: " ").count >= 35, "crop \(crop.key) trouble note under 35 words")
    expect(crop.trouble.split(separator: " ").count <= 70, "crop \(crop.key) trouble note over 70 words")
    expect(crop.companions.count == 3, "crop \(crop.key) does not list 3 companions")
    expect(crop.antagonists.count == 2, "crop \(crop.key) does not list 2 antagonists")
    for c in crop.companions { expect(Register.exists(c), "companion \(c) of \(crop.key) is not in the register") }
    for a in crop.antagonists { expect(Register.exists(a), "antagonist \(a) of \(crop.key) is not in the register") }
    expect(!crop.companions.contains(crop.key) && !crop.antagonists.contains(crop.key), "crop \(crop.key) lists itself")
    expect(Set(crop.companions).isDisjoint(with: Set(crop.antagonists)), "crop \(crop.key) has a companion that is also an antagonist")
    expect(crop.maturity.lowerBound > 0 && crop.maturity.upperBound >= crop.maturity.lowerBound, "crop \(crop.key) maturity range")
    expect([1, 2, 4, 8, 9, 16].contains(crop.perCell), "crop \(crop.key) per cell \(crop.perCell) not a square-foot count")
    expect(crop.spacing >= 3 && crop.spacing <= 12, "crop \(crop.key) spacing out of range")
    expect(crop.window >= 7, "crop \(crop.key) harvest window under a week")
    expect(crop.indoors != nil || crop.direct != nil || crop.transplant != nil || crop.fall != nil, "crop \(crop.key) has no way in")
    if let i = crop.indoors { expect(i.lowerBound >= 2 && i.upperBound <= 12, "crop \(crop.key) indoor weeks \(i)") }
    if let d = crop.direct { expect(d.lowerBound >= -8 && d.upperBound <= 4, "crop \(crop.key) direct weeks \(d)") }
    if let t = crop.transplant { expect(t.lowerBound >= -4 && t.upperBound <= 4, "crop \(crop.key) transplant weeks \(t)") }
    if let f = crop.fall { expect(f.lowerBound >= 4 && f.upperBound <= 18, "crop \(crop.key) fall weeks \(f)") }
    if !artDir.isEmpty {
        expect(FileManager.default.fileExists(atPath: artDir + "/" + crop.plate + ".jpg"), "plate missing for \(crop.key)")
    }
    let fam = CropFamily.allCases.first { $0 == crop.family }
    expect(fam != nil, "crop \(crop.key) family")
    if crop.family != .sundry { expect(crop.botanical == crop.family.latin, "crop \(crop.key) botanical family does not match its group") }
}
for family in CropFamily.allCases {
    expect(!Register.members(of: family).isEmpty, "family \(family.name) has no members")
    expect(family.lore.split(separator: " ").count >= 50, "family \(family.name) lore is short")
    if !artDir.isEmpty { expect(FileManager.default.fileExists(atPath: artDir + "/" + family.plate + ".jpg"), "family plate missing \(family.rawValue)") }
}
print("   \(Register.crops.count) crops, \(CropFamily.allCases.count) families checked")

print("== windows for every zone ==")
var windowChecks = 0
for zone in 3...10 {
    let dates = FrostDates.forZone(zone)
    for year in [2026, 2027, 2028] {
        let fy = FrostYear(dates, year: year)
        expect(fy.firstFrost > fy.lastFrost, "first frost before last frost in zone \(zone)")
        for crop in Register.crops {
            if let w = crop.indoors, let win = Planner.indoorsWindow(crop, fy) {
                expect(win.start == fy.lastFrost - w.upperBound * 7 && win.end == fy.lastFrost - w.lowerBound * 7, "indoor window arithmetic \(crop.key) zone \(zone)")
                expect(win.end <= fy.lastFrost, "indoor window after last frost \(crop.key)")
            }
            if let w = crop.transplant, let win = Planner.transplantWindow(crop, fy) {
                expect(win.start == fy.lastFrost + w.lowerBound * 7 && win.end == fy.lastFrost + w.upperBound * 7, "transplant window arithmetic \(crop.key)")
                if crop.hardiness == .veryTender { expect(win.start > fy.lastFrost, "very tender \(crop.key) goes out before the last frost") }
                if crop.hardiness == .tender { expect(win.start >= fy.lastFrost, "tender \(crop.key) goes out before the last frost") }
            }
            if let w = crop.direct, let win = Planner.directWindow(crop, fy) {
                expect(win.start == fy.lastFrost + w.lowerBound * 7 && win.end == fy.lastFrost + w.upperBound * 7, "direct window arithmetic \(crop.key)")
                if crop.hardiness == .veryTender || crop.hardiness == .tender { expect(win.start > fy.lastFrost, "tender \(crop.key) sown direct before the last frost") }
                if crop.hardiness == .hardy { expect(win.start < fy.lastFrost, "hardy \(crop.key) not sown before the last frost") }
            }
            if let w = crop.fall, let win = Planner.fallWindow(crop, fy) {
                expect(win.start == fy.firstFrost - w.upperBound * 7 && win.end == fy.firstFrost - w.lowerBound * 7, "fall window arithmetic \(crop.key)")
                expect(win.end < fy.firstFrost, "fall window after the first frost \(crop.key)")
            }
            if let latest = Planner.latestSuccession(crop, fy) {
                expect(latest + crop.maturity.lowerBound <= fy.firstFrost, "succession sowing for \(crop.key) ripens after the first frost")
            }
            if let h = Planner.firstHarvest(crop, fy) {
                expect(h.start > fy.lastFrost - 12 * 7, "first harvest impossibly early \(crop.key)")
            }
            windowChecks += 1
        }
    }
}
print("   \(windowChecks) crop-zone-year window sets checked")

print("== zone 6 landmarks ==")
let six = FrostDates.forZone(6)
let fy6 = FrostYear(six, year: 2026)
expect(Almanac.label(fy6.lastFrost) == "Apr 1" && Almanac.label(fy6.firstFrost) == "Oct 31", "zone 6 frost dates are not Apr 1 / Oct 31")
let tomato = Register.find("tomato")
if let i = Planner.indoorsWindow(tomato, fy6) { expect(i.start == day(2026, 2, 4) && i.end == day(2026, 2, 18), "tomato indoors zone 6 is \(i.label), not Feb 4 to Feb 18") } else { fail("tomato has no indoor window") }
if let t = Planner.transplantWindow(tomato, fy6) { expect(t.start == day(2026, 4, 8) && t.end == day(2026, 4, 15), "tomato out zone 6 is \(t.label), not Apr 8 to Apr 15") } else { fail("tomato has no transplant window") }
if let h = Planner.firstHarvest(tomato, fy6) { expect(h.start == day(2026, 6, 12) && h.end >= day(2026, 7, 8) && h.end <= day(2026, 7, 10), "tomato first harvest zone 6 is \(h.label), not Jun 12 to Jul 10") } else { fail("tomato has no harvest window") }
let pea = Register.find("pea")
if let d = Planner.directWindow(pea, fy6) { expect(d.start == day(2026, 2, 18) && d.end == day(2026, 3, 4), "peas direct zone 6 is \(d.label), not Feb 18 to Mar 4") } else { fail("pea has no direct window") }
let garlic = Register.find("garlic")
if let f = Planner.fallWindow(garlic, fy6) { expect(f.contains(day(2026, 9, 19)), "garlic fall window \(f.label) does not hold Sep 19") } else { fail("garlic has no fall window") }
expect(Register.find("radish").maturity.contains(25), "radish maturity does not contain 25")
expect(Register.find("lettuce").succession == 14 && Register.find("radish").succession == 10 && Register.find("carrot").succession == 21, "succession intervals off")
for zone in 3...10 {
    let d = FrostDates.forZone(zone)
    let row = FrostDates.zoneTable.first { $0.0 == zone }!
    expect(d.lastMonth == row.1 && d.lastDay == row.2 && d.firstMonth == row.3 && d.firstDay == row.4, "zone \(zone) table mismatch")
}
print("   landmarks held")

print("== verdicts, jobs and sowability ==")
var verdictChecks = 0
for zone in [3, 6, 9] {
    let dates = FrostDates.forZone(zone)
    let fy = FrostYear(dates, year: 2026)
    for crop in Register.crops {
        var d = fy.jan1
        while d <= fy.dec31 {
            let v = Planner.verdict(for: crop, on: d, dates: dates)
            expect(!v.text.isEmpty, "empty verdict")
            let again = Planner.verdict(for: crop, on: d, dates: dates)
            expect(again == v, "verdict not reproducible")
            switch v.kind {
            case .direct:
                let ok = [fy, FrostYear(dates, year: 2027)].contains { y in
                    guard let win = Planner.directWindow(crop, y) else { return false }
                    let latest = Planner.latestSuccession(crop, y) ?? Int.min
                    return d >= win.start && (d <= win.end + 7 || d <= latest)
                }
                expect(ok, "direct verdict outside window \(crop.key) zone \(zone) \(Almanac.label(d))")
            case .fall:
                let ok = [fy, FrostYear(dates, year: 2027)].contains { y in
                    guard let win = Planner.fallWindow(crop, y) else { return false }
                    return d >= win.start && d <= win.end + 7
                }
                expect(ok, "fall verdict outside window \(crop.key)")
            case .transplant:
                let ok = [fy, FrostYear(dates, year: 2027)].contains { y in
                    guard let win = Planner.transplantWindow(crop, y) else { return false }
                    let latest = Planner.latestSuccession(crop, y) ?? Int.min
                    return d >= win.start && (d <= win.end + 14 || d <= latest)
                }
                expect(ok, "transplant verdict outside window \(crop.key)")
            case .startIndoors:
                let ok = [fy, FrostYear(dates, year: 2027)].contains { y in
                    guard let win = Planner.indoorsWindow(crop, y) else { return false }
                    let out = Planner.transplantWindow(crop, y)
                    return d >= win.start && d < (out?.start ?? win.end + 1)
                }
                expect(ok, "indoor verdict outside window \(crop.key) zone \(zone) \(Almanac.label(d))")
            case .wait, .tooLate:
                expect(v.opens != nil && v.opens! > d, "wait verdict without a future opening \(crop.key)")
            case .resting:
                break
            }
            verdictChecks += 1
            d += 3
        }
        var book = PlotBook()
        book.frost = dates
        book.beds = [Bed.make("bed1", name: "Bed 1")]
        book.beds[0].cells[0].stake = crop.key
        var t = fy.jan1
        while t <= fy.dec31 {
            let jobs = Jobs.list(book, today: t)
            for job in jobs where job.crop == crop.key {
                expect(!job.title.isEmpty && !job.detail.isEmpty && job.points > 0, "job text missing")
                switch job.kind {
                case .directSow:
                    if job.id.hasPrefix("direct-") {
                        let v = Planner.verdict(for: crop, on: job.due, dates: dates)
                        expect(v.kind == .direct, "direct-sow job due when not sowable: \(crop.key) zone \(zone) due \(Almanac.label(job.due)) on \(Almanac.label(t))")
                    } else {
                        expect(job.due > t, "ahead job not in the future")
                    }
                case .fallSow:
                    let v = Planner.verdict(for: crop, on: job.due, dates: dates)
                    expect(v.kind == .fall || v.kind == .direct, "fall-sow job due when not sowable: \(crop.key)")
                case .sowIndoors:
                    if let win = Planner.indoorsWindow(crop, fy) { expect(job.due >= win.start, "indoor job before window \(crop.key)") }
                case .transplant:
                    if let win = Planner.transplantWindow(crop, fy) { expect(job.due >= win.start, "set-out job before window \(crop.key)") }
                default:
                    break
                }
            }
            t += 5
        }
    }
}
print("   \(verdictChecks) verdicts checked across zones 3, 6 and 9")

print("== growth stages and the season slider ==")
var stageChecks = 0
for crop in Register.crops {
    for method in [0, 1] {
        let p = Planting(crop: crop.key, sowDay: 1000, method: method, seeds: crop.perCell, spacing: 100, thinned: true, rotation: 0, companions: 0, antagonists: 0, watered: nil)
        let end = 1000 + crop.maturity.upperBound + crop.window
        var lastStage = Stage.bare
        for d in 990...(end + 40) {
            let s = p.stage(on: d)
            if d < 1000 { expect(s == .bare, "crop shown before its sow date \(crop.key)") }
            if d > end + 14 { expect(s == .bare, "crop shown after its window plus 14 days \(crop.key)") }
            if d >= 1000 && d <= end {
                expect(s != .bare, "crop vanished inside its life \(crop.key) day \(d - 1000)")
            }
            if d > end && d <= end + 14 { expect(s == .spent, "crop not spent after its window \(crop.key)") }
            if p.inWindow(on: d) { expect(s == .mature, "in window but not mature \(crop.key)") }
            if s == .mature { expect(p.inWindow(on: d), "mature but not in window \(crop.key)") }
            if d >= 1000 && d <= end { expect(s.rawValue >= lastStage.rawValue || s == .spent, "stage went backwards \(crop.key)") }
            let g = p.growth(on: d)
            expect(g >= 0 && g <= 1, "growth out of range")
            if d >= 1000 && d <= end { lastStage = s }
            stageChecks += 1
        }
        let harvest = p.harvest(crop)
        expect(harvest.start == 1000 + crop.maturity.lowerBound && harvest.end == end, "harvest window arithmetic \(crop.key)")
    }
}
print("   \(stageChecks) stage days checked")

print("== rotation and neighbours ==")
var rotationChecks = 0
for a in Register.crops {
    for b in Register.crops {
        var bed = Bed.make("r", name: "R")
        bed.history = [[b.botanical]]
        let v = Rotation.check(a, in: bed)
        if a.botanical == b.botanical { expect(v == .warn, "same family repeat not flagged \(a.key) after \(b.key)") }
        else if a.botanical == "Brassicaceae" && b.botanical == "Fabaceae" { expect(v == .bonus, "legume before brassica not rewarded") }
        else { expect(v == .clear, "different family flagged \(a.key) after \(b.key)") }
        bed.history = [[b.botanical], [b.botanical]]
        let v2 = Rotation.check(a, in: bed)
        if a.botanical == b.botanical { expect(v2 == .strong, "third season not strongly flagged") } else { expect(v2 != .warn && v2 != .strong, "different family flagged on two seasons") }
        rotationChecks += 1
    }
    var bed = Bed.make("n", name: "N")
    bed.cells[1].stake = a.companions[0]
    bed.cells[4].stake = a.antagonists[0]
    let report = Rotation.neighbours(of: a, at: 0, in: bed)
    expect(report.companions.contains(a.companions[0]), "companion beside not seen \(a.key)")
    expect(report.antagonists.contains(a.antagonists[0]), "antagonist beside not seen \(a.key)")
    let far = Rotation.neighbours(of: a, at: 3, in: bed)
    expect(far.companions.isEmpty && far.antagonists.isEmpty, "neighbour seen across the bed \(a.key)")
}
for inWindow in [true, false] {
    for rotation in 0...3 {
        for companions in 0...2 {
            for antagonists in 0...2 {
                for spacing in stride(from: 0, through: 100, by: 10) {
                    let q = Rotation.quality(inWindow: inWindow, rotation: rotation, companions: companions, antagonists: antagonists, spacing: spacing)
                    expect(q >= 0 && q <= 2, "quality outside 0...2")
                    if inWindow && (rotation == 0 || rotation == 3) && companions > 0 && antagonists == 0 && spacing >= 70 { expect(q == 2, "the perfect square is not prize") }
                    if !inWindow && antagonists > 0 { expect(q == 0, "late pull beside an antagonist is not fair") }
                }
            }
        }
    }
}
for seeds in 0...40 {
    for crop in Register.crops {
        let ideal = crop.perCell
        let score = max(0, min(100, 100 - Int(Double(abs(seeds - ideal)) / Double(max(1, ideal)) * 100)))
        expect(score >= 0 && score <= 100, "spacing score outside 0...100")
        if seeds == ideal { expect(score == 100, "ideal sowing not 100") }
    }
}
print("   \(rotationChecks) family pairs checked, quality grid checked")

print("== daily notes ==")
var noteChecks = 0
for d in 0..<3000 {
    for rank in 0...4 {
        let note = Notebook.note(for: d, dates: six, rank: rank)
        let again = Notebook.note(for: d, dates: six, rank: rank)
        expect(note == again, "daily note not reproducible")
        expect(note.options.count == 3, "note without 3 options")
        expect(note.answer >= 0 && note.answer < note.options.count, "note answer out of range")
        expect(!note.prompt.isEmpty && !note.explanation.isEmpty, "note text missing")
        expect(Set(note.options).count == note.options.count, "note options repeat")
        expect(note.detail.count == note.options.count, "note details do not match options")
        if note.kind == .companion {
            let names = note.options
            let good = Register.crops.first { $0.name == names[note.answer] }
            expect(good != nil, "companion note answer is not a crop")
        }
        if note.kind == .frost {
            let target = Register.crops.first { $0.name == note.options[note.answer] }
            expect(target != nil && target!.hardiness.rawValue >= Hardiness.tender.rawValue, "frost drill answer is not tender")
            for (i, name) in note.options.enumerated() where i != note.answer {
                let c = Register.crops.first { $0.name == name }
                expect(c != nil && c!.hardiness == .hardy, "frost drill decoy is not hardy")
            }
        }
        noteChecks += 1
    }
}
print("   \(noteChecks) daily notes checked")

print("== examination papers ==")
var examChecks = 0
for k in 0..<400 {
    let paper = Examiner.paper(seed: UInt64(k) &* 7919 &+ 13, count: 30, dates: FrostDates.forZone(3 + k % 8))
    expect(paper.count == 30, "paper does not hold 30 questions (\(paper.count))")
    let again = Examiner.paper(seed: UInt64(k) &* 7919 &+ 13, count: 30, dates: FrostDates.forZone(3 + k % 8))
    expect(again.map { $0.prompt } == paper.map { $0.prompt }, "paper not reproducible")
    expect(Set(paper.map { $0.prompt }).count == paper.count, "paper repeats a question")
    for q in paper {
        expect(q.options.count >= 2 && q.options.count <= 4, "question option count")
        expect(q.answer >= 0 && q.answer < q.options.count, "question answer out of range")
        expect(Set(q.options).count == q.options.count, "question repeats an option")
        expect(!q.explanation.isEmpty, "question without explanation")
        examChecks += 1
    }
}
expect(Set(Examiner.authoredAll.map { $0.0 }).count == Examiner.authoredAll.count, "authored questions repeat")
for q in Examiner.authoredAll { expect(q.2 >= 0 && q.2 < q.1.count && Set(q.1).count == q.1.count, "authored question malformed") }
print("   \(examChecks) questions checked")

print("== weather, seasons and the calendar ==")
for d in 0..<2000 {
    let w = Weather.at(day: d, dates: six)
    expect(w == Weather.at(day: d, dates: six), "weather not reproducible")
    let s = Almanac.season(of: d)
    expect(s >= 0 && s <= 3, "season out of range")
    let parts = Almanac.parts(of: d)
    expect(Almanac.dayIndex(year: parts.year, month: parts.month, day: parts.day) == d, "day index does not round trip through the calendar")
}
let today = Almanac.dayIndex()
expect(today > 200 && today < 4000, "today index out of expected range \(today)")
expect(Almanac.relative(today, to: today) == "due today" && Almanac.relative(today - 3, to: today) == "overdue by 3 days", "relative wording")
print("   calendar round trips")

print("== book ==")
expect(Lessons.all.count >= 12, "fewer than 12 lessons")
expect(Set(Lessons.all.map { $0.key }).count == Lessons.all.count, "lesson keys repeat")
expect(Set(Lessons.all.map { $0.title }).count == Lessons.all.count, "lesson titles repeat")
for lesson in Lessons.all {
    let words = lesson.text.split(separator: " ").count
    expect(words >= 250 && words <= 520, "lesson \(lesson.key) has \(words) words")
    if !artDir.isEmpty { expect(FileManager.default.fileExists(atPath: artDir + "/" + lesson.plate + ".jpg"), "lesson plate missing \(lesson.key)") }
}
expect(Glossary.terms.count == 60, "glossary does not hold 60 terms (\(Glossary.terms.count))")
expect(Set(Glossary.terms.map { $0.term }).count == Glossary.terms.count, "glossary terms repeat")
for t in Glossary.terms { expect(t.means.split(separator: " ").count >= 12, "term \(t.term) is thin") }
expect(Badge.all.count == 12 && Set(Badge.all.map { $0.key }).count == 12, "badges")
expect(Lessons.all.count == 17, "lessons are not 17 (\(Lessons.all.count))")
for key in ["pests", "frostcover", "watering", "seedkeeping"] { expect(Lessons.all.contains { $0.key == key }, "new lesson \(key) missing") }
expect(Ladder.steps.count == 5 && Ladder.index(for: 0) == 0 && Ladder.index(for: 5000) == 4, "ladder")
if !artDir.isEmpty {
    for s in ["wi", "sp", "su", "au"] { for h in 0..<7 { expect(FileManager.default.fileExists(atPath: artDir + "/pl_\(s)\(h).jpg"), "scene plate missing pl_\(s)\(h)") } }
    for k in 0..<4 { expect(FileManager.default.fileExists(atPath: artDir + "/se_\(k).jpg"), "season plate missing"); expect(FileManager.default.fileExists(atPath: artDir + "/ob_p\(k).jpg"), "onboarding plate missing") }
    for k in 0..<6 { expect(FileManager.default.fileExists(atPath: artDir + "/sh_\(k).jpg"), "shelf plate missing") }
    for k in 0..<4 { expect(FileManager.default.fileExists(atPath: artDir + "/ty_\(k).jpg"), "tray plate missing ty_\(k)") }
    for m in 1...12 { expect(FileManager.default.fileExists(atPath: artDir + "/mo_\(m).jpg"), "month plate missing mo_\(m)") }
    for crop in Register.crops { expect(FileManager.default.fileExists(atPath: artDir + "/pr_" + crop.key + ".jpg"), "produce plate missing for \(crop.key)") }
}

print("== troubles ==")
expect(Troubles.all.count == 24, "troubles are not 24 (\(Troubles.all.count))")
expect(Set(Troubles.all.map { $0.key }).count == Troubles.all.count, "trouble keys repeat")
expect(Set(Troubles.all.map { $0.name }).count == Troubles.all.count, "trouble names repeat")
for t in Troubles.all {
    expect(t.signs.split(separator: " ").count >= 40 && t.signs.split(separator: " ").count <= 90, "trouble \(t.key) signs length \(t.signs.split(separator: " ").count)")
    expect(t.action.split(separator: " ").count >= 35 && t.action.split(separator: " ").count <= 90, "trouble \(t.key) action length \(t.action.split(separator: " ").count)")
    expect(t.prevention.split(separator: " ").count >= 30 && t.prevention.split(separator: " ").count <= 80, "trouble \(t.key) prevention length \(t.prevention.split(separator: " ").count)")
    expect(!t.crops.isEmpty && t.crops.count <= 16, "trouble \(t.key) crop list size")
    for c in t.crops { expect(Register.exists(c), "trouble \(t.key) names unknown crop \(c)") }
    expect(Set(t.crops).count == t.crops.count, "trouble \(t.key) repeats a crop")
    expect(t.monthFrom >= 1 && t.monthFrom <= 12 && t.monthTo >= 1 && t.monthTo <= 12, "trouble \(t.key) months")
    expect(!t.monthList.isEmpty && t.monthList.count <= 12, "trouble \(t.key) month list")
    expect(!t.symptomWords.isEmpty && !t.season.isEmpty && !t.remedy.instruction.isEmpty, "trouble \(t.key) text")
    expect(t.count >= 3 && t.count <= 8, "trouble \(t.key) count")
    if !artDir.isEmpty { expect(FileManager.default.fileExists(atPath: artDir + "/" + t.plate + ".jpg"), "trouble plate missing \(t.key)") }
}
for crop in Register.crops {
    expect(!Troubles.affecting(crop.key).isEmpty, "crop \(crop.key) has no trouble in the register")
}
var eventChecks = 0
var eventDays = 0
var growingDays = 0
var sample = PlotBook()
sample.frost = FrostDates.forZone(6)
sample.beds = [Bed.make("bed1", name: "North"), Bed.make("bed2", name: "South")]
for (i, key) in ["tomato", "cabbage", "carrot", "lettuce", "zucchini", "onion", "bushbean", "spinach"].enumerated() {
    sample.beds[i / 4].cells[i % 4].planting = Planting(crop: key, sowDay: 900, method: 0, seeds: 4, spacing: 100, thinned: true, rotation: 0, companions: 0, antagonists: 0, watered: nil)
}
for d in 905..<1600 {
    let growing = sample.beds.contains { bed in bed.cells.contains { cell in
        guard let p = cell.planting else { return false }
        let st = p.stage(on: d)
        return st >= .sprout && st <= .mature } }
    if growing { growingDays += 1 }
    let e = Troubles.event(for: d, book: sample)
    if !growing { expect(e == nil, "event on a day with nothing growing") }
    let again = Troubles.event(for: d, book: sample)
    expect(e == again, "trouble event not reproducible on day \(d)")
    if let ev = e {
        eventDays += 1
        expect(ev.candidates.count == 3 && Set(ev.candidates).count == 3, "event candidates malformed")
        expect(ev.candidates.contains(ev.trouble), "event candidates omit the culprit")
        expect(Troubles.exists(ev.trouble), "event names unknown trouble")
        expect(sample.beds.contains { $0.id == ev.bedId }, "event names unknown bed")
        let bed = sample.beds.first { $0.id == ev.bedId }!
        expect(ev.cell < bed.cells.count && bed.cells[ev.cell].planting?.crop == ev.crop, "event cell does not hold its crop")
        let stage = bed.cells[ev.cell].planting!.stage(on: d)
        expect(stage >= .sprout && stage <= .mature, "event on a bare or spent square")
        let culprit = Troubles.find(ev.trouble)
        for c in ev.candidates where c != ev.trouble { expect(Troubles.find(c).symptom != culprit.symptom, "decoy shares the culprit symptom") }
        expect(ev.id == "trouble-\(d)", "event id")
    }
    eventChecks += 1
}
expect(growingDays > 60 && Double(eventDays) >= Double(growingDays) * 0.6 && eventDays < growingDays, "event frequency off (\(eventDays) of \(growingDays) growing days)")
expect(Troubles.event(for: 1000, book: PlotBook()) == nil, "event on an empty plot")
print("   \(Troubles.all.count) troubles, \(eventChecks) days checked, \(growingDays) growing, \(eventDays) with an event")

print("== sayings ==")
expect(Sayings.all.count == 36, "sayings are not 36 (\(Sayings.all.count))")
expect(Set(Sayings.all.map { $0.text }).count == Sayings.all.count, "sayings repeat")
for m in 1...12 { expect(Sayings.forMonth(m).count == 3, "month \(m) does not hold 3 sayings") }
for s in Sayings.all {
    expect(s.note.split(separator: " ").count >= 35 && s.note.split(separator: " ").count <= 110, "saying note length \(s.text) \(s.note.split(separator: " ").count)")
    expect(s.text.hasSuffix(".") , "saying without a full stop: \(s.text)")
}
for d in 0..<1500 {
    let s = Sayings.ofDay(d)
    expect(s == Sayings.ofDay(d), "saying of day not reproducible")
    expect(s.month == Almanac.parts(of: d).month, "saying of day is not of the month")
}
print("   \(Sayings.all.count) sayings checked")

print("== tray growth ==")
for crop in Register.crops where crop.indoors != nil {
    let tray = SeedTray(id: "t", crop: crop.key, sowDay: 100, hardenedDay: nil, prickedDay: nil, shelf: nil)
    expect(tray.seedlingHeight(on: 99) == 0 && tray.seedlingHeight(on: 100) == 0, "tray grows before sowing \(crop.key)")
    var last = 0.0
    for d in 100...200 {
        let h = tray.seedlingHeight(on: d)
        expect(h >= last && h <= 1, "tray growth not monotone \(crop.key)")
        last = h
    }
    expect(tray.seedlingHeight(on: 400) == 1, "tray never reaches full height \(crop.key)")
    expect(!tray.canPrick(on: 101) && tray.canPrick(on: 400), "prick-out gate \(crop.key)")
    var hard = tray
    hard.hardenedDay = 150
    expect(hard.hardenDaysDone(on: 150) == 1 && hard.hardenDaysDone(on: 156) == 7 && hard.hardenDaysDone(on: 170) == 7, "harden day count \(crop.key)")
}
print("   tray growth checked")

print("== new examination kinds ==")
var kindCounts = [0, 0, 0, 0]
for k in 0..<300 {
    var rng = Furrow(UInt64(k) &* 31 &+ 7)
    if let q = Examiner.troubleCrop(&rng, k) { kindCounts[0] += 1; expect(q.options.count == 4 && Set(q.options).count == 4 && q.answer < 4 && !q.explanation.isEmpty, "trouble crop question malformed") }
    if let q = Examiner.troubleAction(&rng, k) { kindCounts[1] += 1; expect(q.options.count == 4 && Set(q.options).count == 4 && q.answer < 4, "trouble action question malformed") }
    if let q = Examiner.troubleKind(&rng, k) { kindCounts[2] += 1; expect(q.options.count == 3 && q.answer < 3, "trouble kind question malformed") }
    if let q = Examiner.sayingVerdict(&rng, k) { kindCounts[3] += 1; expect(q.options.count == 3 && q.answer < 3, "saying question malformed") }
}
expect(kindCounts.allSatisfy { $0 >= 280 }, "new question kinds fail too often \(kindCounts)")
print("   \(kindCounts) new-kind questions checked")
print("   \(Lessons.all.count) lessons, \(Glossary.terms.count) terms, \(Examiner.authoredAll.count) authored questions")

print("== old snapshot still decodes ==")
let legacy = "{\"frost\":{\"zone\":6,\"lastMonth\":4,\"lastDay\":1,\"firstMonth\":10,\"firstDay\":31},\"beds\":[],\"trays\":[{\"id\":\"t1\",\"crop\":\"tomato\",\"sowDay\":10}],\"larder\":[],\"seasons\":[],\"seasonNumber\":1,\"points\":12,\"streak\":1,\"bestStreak\":1,\"lastDay\":5,\"daysDone\":[5],\"doneJobs\":[],\"notesSolved\":[]}"
if let old = try? JSONDecoder().decode(PlotBook.self, from: legacy.data(using: .utf8)!) {
    expect(old.trays.count == 1 && old.trays[0].prickedDay == nil && old.troublesSolved == nil && old.points == 12, "legacy snapshot fields")
} else {
    fail("legacy snapshot without the new fields does not decode")
}
print("   legacy snapshot decodes")

print("== persistence round trip ==")
var book = PlotBook()
book.frost = FrostDates.forZone(7)
book.beds = [Bed.make("bed1", name: "North"), Bed.make("bed2", name: "South")]
book.beds[0].cells[0].planting = Planting(crop: "tomato", sowDay: today - 40, method: 1, seeds: 1, spacing: 100, thinned: false, rotation: 0, companions: 1, antagonists: 0, watered: nil)
book.beds[0].history = [["Fabaceae"]]
book.larder = [LarderEntry(crop: "radish", quality: 2, day: today - 10, bed: "North", season: 1, count: 3)]
book.trays = [SeedTray(id: "tray-pepper", crop: "pepper", sowDay: today - 30, hardenedDay: nil, prickedDay: today - 10, shelf: 1)]
book.troublesSolved = ["trouble-1"]
book.sayingsRead = [Sayings.all[0].id]
book.troublesCount = 1
book.seasons = [SeasonRecord(number: 1, year: 2025, closedDay: today - 300, harvests: 12, prize: 3, families: ["Solanaceae"], beds: 2, sowings: 20)]
if let data = try? JSONEncoder().encode(book), let back = try? JSONDecoder().decode(PlotBook.self, from: data) {
    expect(back.beds == book.beds && back.larder == book.larder && back.trays == book.trays && back.seasons == book.seasons && back.frost == book.frost, "snapshot does not round trip")
    expect(back.troublesSolved == book.troublesSolved && back.sayingsRead == book.sayingsRead && back.troublesCount == 1, "new fields do not round trip")
} else {
    fail("snapshot does not encode")
}
let jobs = Jobs.list(book, today: today)
expect(jobs.allSatisfy { !$0.id.isEmpty && !$0.title.isEmpty }, "jobs malformed")
expect(Set(jobs.map { $0.id }).count == jobs.count, "job ids repeat")
print("   snapshot round trips, \(jobs.count) jobs generated for a sample plot")

print("")
print("\(checks) checks")
if failures.isEmpty {
    print("ALL PASSED")
} else {
    for (message, count) in failures.sorted(by: { $0.value > $1.value }) {
        print("FAIL x\(count): \(message)")
    }
    exit(1)
}
