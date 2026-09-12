import Foundation
import SwiftUI

final class FrostGarden: ObservableObject {
    @Published var book: PlotBook { didSet { save() } }
    @Published var wantedTab: Int? = nil
    @Published var wantedBed: String? = nil
    @Published var clockDay: Int = Almanac.dayIndex()
    private let key = "last.frost.plotbook.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(PlotBook.self, from: data) {
            book = decoded
        } else {
            book = PlotBook()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(book) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    var today: Int { clockDay }

    func refreshClock() {
        let d = Almanac.dayIndex()
        if d != clockDay { clockDay = d }
    }

    var dates: FrostDates { book.frost }

    var frostYear: FrostYear { FrostYear(book.frost, year: Almanac.year(of: today)) }

    var liveStreak: Int {
        guard book.lastDay == today || book.lastDay == today - 1 else { return 0 }
        return book.streak
    }

    var rankIndex: Int { Ladder.index(for: book.points) }

    var rank: (String, String, Int, Int) {
        let i = rankIndex
        let current = Ladder.steps[i]
        let ceiling = i + 1 < Ladder.steps.count ? Ladder.steps[i + 1].0 : current.0
        return (current.1, current.2, book.points, ceiling)
    }

    func award(_ n: Int) {
        book.points += n
        recordDay()
    }

    func recordDay() {
        let day = today
        guard !book.daysDone.contains(day) else { return }
        book.daysDone.append(day)
        if book.daysDone.count > 400 { book.daysDone.removeFirst(book.daysDone.count - 400) }
        if book.lastDay == day - 1 { book.streak += 1 } else { book.streak = 1 }
        book.lastDay = day
        book.bestStreak = max(book.bestStreak, book.streak)
    }

    func workedToday() -> Bool { book.daysDone.contains(today) }

    func setFrost(_ dates: FrostDates) { book.frost = dates }

    func setZone(_ zone: Int) { book.frost = FrostDates.forZone(zone) }

    var jobs: [Job] { Jobs.list(book, today: today) }

    var openJobs: [Job] { jobs.filter { !book.doneJobs.contains($0.id) } }

    func isDone(_ job: Job) -> Bool { book.doneJobs.contains(job.id) }

    private func markDone(_ id: String, points: Int) {
        guard !book.doneJobs.contains(id) else { return }
        book.doneJobs.append(id)
        if book.doneJobs.count > 600 { book.doneJobs.removeFirst(book.doneJobs.count - 600) }
        award(points)
    }

    func bedIndex(_ id: String) -> Int? { book.beds.firstIndex { $0.id == id } }

    func bed(_ id: String) -> Bed? { book.beds.first { $0.id == id } }

    @discardableResult
    func addBed(cols: Int = 4, rows: Int = 2) -> Bed? {
        guard book.beds.count < 12 else { return nil }
        let n = (book.bedCounter ?? book.beds.count) + 1
        book.bedCounter = n
        let bed = Bed.make("bed\(n)", name: "Bed \(n)", cols: cols, rows: rows)
        book.beds.append(bed)
        return bed
    }

    func removeBed(_ id: String) {
        book.beds.removeAll { $0.id == id }
    }

    func renameBed(_ id: String, _ name: String) {
        guard let i = bedIndex(id) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        book.beds[i].name = trimmed.isEmpty ? book.beds[i].name : String(trimmed.prefix(18))
    }

    func stake(_ bedId: String, _ cell: Int, _ crop: String) {
        guard let i = bedIndex(bedId), cell < book.beds[i].cells.count else { return }
        guard book.beds[i].cells[cell].planting == nil else { return }
        book.beds[i].cells[cell].stake = crop
    }

    func unstake(_ bedId: String, _ cell: Int) {
        guard let i = bedIndex(bedId), cell < book.beds[i].cells.count else { return }
        book.beds[i].cells[cell].stake = nil
    }

    func sow(_ bedId: String, _ cell: Int, crop: String, seeds: Int, transplant: Bool, tray: String? = nil) {
        guard let i = bedIndex(bedId), cell < book.beds[i].cells.count else { return }
        let c = Register.find(crop)
        let bed = book.beds[i]
        let rotation = Rotation.check(c, in: bed)
        let report = Rotation.neighbours(of: c, at: cell, in: bed)
        let ideal = c.perCell
        let spacingScore = transplant ? 100 : max(0, min(100, 100 - Int(Double(abs(seeds - ideal)) / Double(max(1, ideal)) * 100)))
        let planting = Planting(crop: crop, sowDay: today, method: transplant ? 1 : 0,
                                seeds: transplant ? ideal : max(1, seeds), spacing: spacingScore,
                                thinned: false, rotation: rotation.rawValue,
                                companions: report.companions.count, antagonists: report.antagonists.count,
                                watered: nil)
        book.beds[i].cells[cell].planting = planting
        book.beds[i].cells[cell].stake = nil
        if let tray = tray { book.trays.removeAll { $0.id == tray } }
        book.sowCount = (book.sowCount ?? 0) + 1
        book.seasonYear = Almanac.year(of: today)
        let year = Almanac.year(of: today)
        for id in ["direct-\(bedId)-\(cell)-\(crop)-\(year)", "fall-\(bedId)-\(cell)-\(crop)-\(year)",
                   "setout-\(bedId)-\(cell)-\(crop)-\(year)"] {
            if !book.doneJobs.contains(id) { book.doneJobs.append(id) }
        }
        if let tray = tray, !book.doneJobs.contains("transplant-\(tray)") { book.doneJobs.append("transplant-\(tray)") }
        award(transplant ? 10 : 10 + spacingScore / 25)
        earn("firstSowing")
    }

    @discardableResult
    func startTray(_ crop: String) -> SeedTray {
        if let existing = book.trays.first(where: { $0.crop == crop }) { return existing }
        let tray = SeedTray(id: "tray-\(crop)-\(today)", crop: crop, sowDay: today, hardenedDay: nil)
        book.trays.append(tray)
        let year = Almanac.year(of: today)
        if !book.doneJobs.contains("indoors-\(crop)-\(year)") { book.doneJobs.append("indoors-\(crop)-\(year)") }
        award(8)
        return tray
    }

    func discardTray(_ id: String) { book.trays.removeAll { $0.id == id } }

    func harden(_ trayId: String) {
        guard let i = book.trays.firstIndex(where: { $0.id == trayId }) else { return }
        book.trays[i].hardenedDay = today
        markDone("harden-\(trayId)", points: 6)
    }

    func water(_ bedId: String) {
        guard let i = bedIndex(bedId) else { return }
        for k in 0..<book.beds[i].cells.count { book.beds[i].cells[k].wateredDay = today }
        markDone("water-\(bedId)-\(today)", points: 4)
    }

    func waterCell(_ bedId: String, _ cell: Int) {
        guard let i = bedIndex(bedId), cell < book.beds[i].cells.count else { return }
        book.beds[i].cells[cell].wateredDay = today
        if book.beds[i].cells.allSatisfy({ $0.wateredDay == today || $0.planting == nil }) {
            markDone("water-\(bedId)-\(today)", points: 4)
        }
    }

    func thin(_ bedId: String, _ cell: Int) {
        guard let i = bedIndex(bedId), cell < book.beds[i].cells.count,
              var p = book.beds[i].cells[cell].planting else { return }
        p.thinned = true
        p.seeds = Register.find(p.crop).perCell
        p.spacing = max(p.spacing, 80)
        let sowDay = p.sowDay
        book.beds[i].cells[cell].planting = p
        markDone("thin-\(bedId)-\(cell)-\(sowDay)", points: 8)
    }

    @discardableResult
    func harvest(_ bedId: String, _ cell: Int) -> LarderEntry? {
        guard let i = bedIndex(bedId), cell < book.beds[i].cells.count,
              let p = book.beds[i].cells[cell].planting else { return nil }
        let c = Register.find(p.crop)
        let inWindow = p.inWindow(on: today)
        let quality = Rotation.quality(inWindow: inWindow, rotation: p.rotation, companions: p.companions,
                                       antagonists: p.antagonists, spacing: p.spacing)
        let entry = LarderEntry(crop: p.crop, quality: quality, day: today, bed: book.beds[i].name,
                                season: book.seasonNumber, count: 1)
        var kept = entry
        if let k = book.larder.firstIndex(where: { $0.crop == p.crop }) {
            let old = book.larder[k]
            kept = quality > old.quality ? entry : old
            kept.count = old.count + 1
            book.larder[k] = kept
            award(quality > old.quality ? 14 + quality * 6 : 6)
        } else {
            book.larder.append(entry)
            award(12 + quality * 8)
        }
        book.beds[i].cells[cell].planting = nil
        book.harvestCount = (book.harvestCount ?? 0) + 1
        var seasons = book.harvestSeasons ?? []
        let s = Almanac.season(of: today)
        if !seasons.contains(s) { seasons.append(s) }
        book.harvestSeasons = seasons
        let sowDay = p.sowDay
        if !book.doneJobs.contains("harvest-\(bedId)-\(cell)-\(sowDay)") { book.doneJobs.append("harvest-\(bedId)-\(cell)-\(sowDay)") }
        recordFamily(bedId, c.botanical)
        earn("firstHarvest")
        if seasons.count >= 4 { earn("fourSeason") }
        if book.larder.count >= 20 { earn("larderTwenty") }
        return kept
    }

    private func recordFamily(_ bedId: String, _ family: String) {
        guard let i = bedIndex(bedId) else { return }
        var fams = book.beds[i].seasonFamilies ?? []
        if !fams.contains(family) { fams.append(family) }
        book.beds[i].seasonFamilies = fams
    }

    func clear(_ bedId: String, _ cell: Int) {
        guard let i = bedIndex(bedId), cell < book.beds[i].cells.count else { return }
        if let p = book.beds[i].cells[cell].planting {
            recordFamily(bedId, Register.find(p.crop).botanical)
            markDone("clear-\(bedId)-\(cell)-\(p.sowDay)", points: 5)
        }
        book.beds[i].cells[cell].planting = nil
        book.beds[i].cells[cell].stake = nil
    }

    func cover(_ bedId: String) {
        var days = book.coveredDays ?? []
        if !days.contains(today) { days.append(today) }
        if days.count > 60 { days.removeFirst(days.count - 60) }
        book.coveredDays = days
        markDone("cover-\(bedId)-\(today)", points: 8)
    }

    func completeSimple(_ job: Job) {
        switch job.kind {
        case .layout:
            markDone(job.id, points: job.points)
        case .sowIndoors:
            if let crop = job.crop { startTray(crop) }
            markDone(job.id, points: 0)
        case .harden:
            if let tray = job.tray { harden(tray) } else { markDone(job.id, points: job.points) }
        case .thin:
            if let bed = job.bed, let cell = job.cell { thin(bed, cell) } else { markDone(job.id, points: job.points) }
        case .water:
            if let bed = job.bed { water(bed) }
        case .clear:
            if let bed = job.bed, let cell = job.cell { clear(bed, cell) }
        case .cover:
            if let bed = job.bed { cover(bed) }
        case .closeSeason:
            closeSeason()
        default:
            break
        }
    }

    func closeSeason() {
        let year = Almanac.year(of: today)
        var harvests = 0, prize = 0, families: [String] = [], sowings = 0
        for entry in book.larder where entry.season == book.seasonNumber {
            harvests += entry.count
            if entry.quality == 2 { prize += 1 }
        }
        for i in 0..<book.beds.count {
            var fams = book.beds[i].familiesThisSeason
            for f in book.beds[i].seasonFamilies ?? [] where !fams.contains(f) { fams.append(f) }
            book.beds[i].history.append(fams)
            if book.beds[i].history.count > 8 { book.beds[i].history.removeFirst() }
            book.beds[i].seasonFamilies = []
            for f in fams where !families.contains(f) { families.append(f) }
            sowings += book.beds[i].cells.filter { $0.planting != nil }.count
            for k in 0..<book.beds[i].cells.count {
                book.beds[i].cells[k].planting = nil
                book.beds[i].cells[k].stake = nil
                book.beds[i].cells[k].wateredDay = nil
            }
            let closed = book.beds[i].history.filter { !$0.isEmpty }
            if closed.count >= 3 {
                let a = Set(closed[closed.count - 1]), b = Set(closed[closed.count - 2]), c = Set(closed[closed.count - 3])
                if a.isDisjoint(with: b) && b.isDisjoint(with: c) && a.isDisjoint(with: c) { earn("fullRotation") }
            }
        }
        let record = SeasonRecord(number: book.seasonNumber, year: year, closedDay: today, harvests: harvests,
                                  prize: prize, families: families, beds: book.beds.count, sowings: sowings)
        book.seasons.append(record)
        book.seasonNumber += 1
        book.seasonYear = year + 1
        book.trays.removeAll()
        markDone("close-\(year)", points: 20)
    }

    func solveNote(_ day: Int, firstTry: Bool) {
        guard !book.notesSolved.contains(day) else { return }
        book.notesSolved.append(day)
        if book.notesSolved.count > 400 { book.notesSolved.removeFirst(book.notesSolved.count - 400) }
        award(firstTry ? 10 : 4)
    }

    func noteSolved(_ day: Int) -> Bool { book.notesSolved.contains(day) }

    func markLesson(_ id: String) {
        var seen = book.readLessons ?? []
        if !seen.contains(id) { seen.append(id); award(3) }
        book.readLessons = seen
    }

    func markTerm(_ id: String) {
        var seen = book.readTerms ?? []
        if !seen.contains(id) { seen.append(id); award(1) }
        book.readTerms = seen
    }

    func recordExam(score: Int, total: Int) {
        book.examsTaken = (book.examsTaken ?? 0) + 1
        let pct = total > 0 ? score * 100 / total : 0
        if pct > (book.examBest ?? 0) { book.examBest = pct }
        award(4 + score)
        if pct >= 80 { earn("examined") }
    }

    func earn(_ badge: String) {
        var have = book.badges ?? []
        guard !have.contains(badge) else { return }
        have.append(badge)
        book.badges = have
        award(15)
    }

    func hasBadge(_ key: String) -> Bool { (book.badges ?? []).contains(key) }

    var larderPrize: Int { book.larder.filter { $0.quality == 2 }.count }
    var lessonsRead: Int { (book.readLessons ?? []).count }
    var termsRead: Int { (book.readTerms ?? []).count }
    var plantedCells: Int { book.beds.reduce(0) { $0 + $1.planted } }
    var stakedCells: Int { book.beds.reduce(0) { $0 + $1.staked } }

    func reset() {
        book = PlotBook()
        book.seenIntro = true
    }

    func entry(_ crop: String) -> LarderEntry? { book.larder.first { $0.crop == crop } }

    func remember(tab: Int) { if book.uiTab != tab { book.uiTab = tab } }
    func remember(bed: String?) { if book.uiBed != bed { book.uiBed = bed } }
    func remember(cell: Int?) { if book.uiCell != cell { book.uiCell = cell } }
    func remember(crop: String?) { if book.uiCrop != crop { book.uiCrop = crop } }
    func remember(section: Int) { if book.uiSection != section { book.uiSection = section } }
    func remember(lesson: String?) { if book.uiLesson != lesson { book.uiLesson = lesson } }
    func remember(scrub: Int?) { if book.uiScrub != scrub { book.uiScrub = scrub } }
}
