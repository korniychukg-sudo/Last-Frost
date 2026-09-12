import SwiftUI

struct TodayView: View {
    @EnvironmentObject var garden: FrostGarden
    @State private var now = Date()
    @State private var rainPhase: Double = 0
    @State private var openSettings = false
    @State private var openNote = false
    @State private var pendingJob: Job? = nil
    private let clock = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()

    private var hour: Double { Almanac.hourNow(now) }

    var body: some View {
        ScrollView {
            Column {
                sceneCard
                jobsCard
                noteCard
                standingCard
                frostCard
            }
            .padding(.horizontal, Loam.gutter)
            .padding(.bottom, 28)
        }
        .background(Loam.page.ignoresSafeArea())
        .navigationBarHidden(true)
        .onReceive(clock) { _ in
            now = Date()
            garden.refreshClock()
            rainPhase = (rainPhase + 0.018).truncatingRemainder(dividingBy: 1)
        }
        .sheet(isPresented: $openSettings) {
            SettingsView { openSettings = false }.environmentObject(garden)
        }
        .sheet(isPresented: $openNote) {
            NoteSheet(note: Notebook.note(for: garden.today, dates: garden.dates, rank: garden.rankIndex)) { openNote = false }
                .environmentObject(garden)
        }
        .alert(item: $pendingJob) { job in
            Alert(title: Text(job.title), message: Text(job.detail),
                  primaryButton: .default(Text(job.kind == .closeSeason ? "Close the season" : "Done")) {
                    Tap.firm()
                    garden.completeSimple(job)
                  },
                  secondaryButton: .cancel(Text("Not yet")))
        }
    }

    private var season: Int { Almanac.season(of: garden.today) }

    private var plateName: String {
        let s = ["wi", "sp", "su", "au"][season]
        let slot: Int
        switch Int(hour) {
        case 0..<5: slot = 6
        case 5..<8: slot = 0
        case 8..<11: slot = 1
        case 11..<14: slot = 2
        case 14..<17: slot = 3
        case 17..<20: slot = 4
        case 20..<23: slot = 5
        default: slot = 6
        }
        return "pl_\(s)\(slot)"
    }

    private var sceneCard: some View {
        let weather = Weather.at(day: garden.today, dates: garden.dates)
        return SheetCard(padding: 0) {
            VStack(spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    PlotScene(hour: hour, day: garden.today, beds: garden.book.beds, dates: garden.dates,
                              rain: rainPhase, backdrop: Plates.exists(plateName) ? plateName : nil)
                        .frame(height: Loam.isPad ? 300 : 214)
                        .clipped()
                    HStack(spacing: 6) {
                        weatherGlyph(weather)
                        Text(weather.name).font(Loam.title(11)).foregroundColor(Loam.card)
                    }
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .background(Capsule().fill(Loam.ink.opacity(0.45)))
                    .padding(10)
                }
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(SkyLight.hourWords(hour, season: season)).font(Loam.title(15.5)).foregroundColor(Loam.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(Almanac.labelLong(garden.today)). \(seasonNote)")
                            .font(Loam.body(12)).foregroundColor(Loam.inkFaint)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    Button(action: { Tap.light(); openSettings = true }) {
                        GearGlyph(size: 20, color: Loam.inkSoft)
                            .padding(8)
                            .background(Circle().fill(Loam.ink.opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(13)
            }
        }
        .rising(0)
    }

    private func weatherGlyph(_ w: Weather) -> some View {
        Group {
            switch w {
            case .rain: DropGlyph(size: 13, color: Loam.card)
            case .frost: FrostGlyph(size: 13, color: Loam.card)
            case .cloud: Circle().fill(Loam.card.opacity(0.7)).frame(width: 10, height: 10)
            case .clear: Circle().fill(Loam.straw).frame(width: 10, height: 10)
            }
        }
    }

    private var seasonNote: String {
        let fy = garden.frostYear
        let today = garden.today
        if garden.dates.frostFree { return "A frost-free plot; the year runs from mid-January." }
        if today < fy.lastFrost {
            let d = fy.lastFrost - today
            return d == 1 ? "The last frost date is tomorrow." : "\(d) days to the last frost on \(Almanac.label(fy.lastFrost))."
        }
        if today <= fy.firstFrost {
            let d = fy.firstFrost - today
            return "\(d) frost-free days left before \(Almanac.label(fy.firstFrost))."
        }
        return "Past the first frost; the beds rest until \(Almanac.label(FrostYear(garden.dates, year: fy.year + 1).lastFrost))."
    }

    private var jobsCard: some View {
        let jobs = garden.jobs
        let open = jobs.filter { !garden.isDone($0) }
        let done = jobs.filter { garden.isDone($0) }
        return SheetCard {
            VStack(alignment: .leading, spacing: 11) {
                HStack {
                    HeadRule(text: "Today's jobs", trailing: open.isEmpty ? nil : "\(open.count) open")
                    if open.isEmpty && !done.isEmpty { StampTag(text: "all done", tone: Loam.good) }
                }
                if open.isEmpty && done.isEmpty {
                    Text("Nothing is due. The plan will put jobs here on the days they fall: sowing indoors, hardening off, direct sowing, thinning, watering and harvest, each counted from your frost dates.")
                        .font(Loam.body(13)).foregroundColor(Loam.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ForEach(open) { job in
                    JobRow(job: job, today: garden.today, done: false) { act(job) }
                }
                if !done.isEmpty {
                    ForEach(done.prefix(4)) { job in
                        JobRow(job: job, today: garden.today, done: true) { }
                    }
                }
            }
        }
        .rising(1)
    }

    private func act(_ job: Job) {
        if job.needsPlot {
            Tap.light()
            garden.wantedBed = job.bed
            garden.wantedTab = 1
            return
        }
        pendingJob = job
    }

    private var noteCard: some View {
        let note = Notebook.note(for: garden.today, dates: garden.dates, rank: garden.rankIndex)
        let solved = garden.noteSolved(garden.today)
        return SheetCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HeadRule(text: "Garden note of the day")
                    if solved { StampTag(text: "solved", tone: Loam.good) }
                }
                Text(note.kind.title).font(Loam.title(17)).foregroundColor(Loam.ink)
                Text(note.prompt).font(Loam.note(14)).foregroundColor(Loam.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 9) {
                    CountTile(value: "\(garden.liveStreak)", label: "day streak", tone: Loam.terracotta)
                    CountTile(value: "\(garden.book.bestStreak)", label: "best streak")
                    CountTile(value: "\(garden.book.notesSolved.count)", label: "notes solved", tone: Loam.leafDeep)
                }
                SowButton(title: solved ? "Read it again" : "Open the note", tone: solved ? Loam.inkSoft : Loam.leafDeep, filled: !solved) {
                    openNote = true
                }
            }
        }
        .rising(2)
    }

    private var standingCard: some View {
        let (name, note, points, ceiling) = garden.rank
        let progress = ceiling > points ? Double(points) / Double(max(1, ceiling)) : 1
        return SheetCard {
            VStack(alignment: .leading, spacing: 11) {
                HeadRule(text: "Standing on the allotment")
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(name).font(Loam.title(18)).foregroundColor(Loam.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(note).font(Loam.note(12)).foregroundColor(Loam.inkFaint)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    VStack(spacing: 1) {
                        Text("\(points)").font(Loam.title(22)).foregroundColor(Loam.terracotta)
                        Text("POINTS").font(Loam.body(8)).tracking(1).foregroundColor(Loam.inkFaint)
                    }
                }
                MeterBar(label: "Toward the next rank", value: progress, tone: Loam.terracotta,
                         caption: ceiling > points ? "\(ceiling - points) points to go" : "Head Gardener, and nothing above it")
                HStack(spacing: 9) {
                    CountTile(value: "\(garden.plantedCells)", label: "squares growing", tone: Loam.leafDeep)
                    CountTile(value: "\(garden.book.larder.count)", label: "in the larder")
                    CountTile(value: "\(garden.larderPrize)", label: "prize", tone: Loam.prize)
                }
                LadderStrip(index: garden.rankIndex)
                NoticeBar(text: "Rank locks nothing. Each step only brings harder notes and longer plans.", tone: Loam.frostDeep)
            }
        }
        .rising(3)
    }

    private var frostCard: some View {
        let fy = garden.frostYear
        return SheetCard {
            VStack(alignment: .leading, spacing: 10) {
                HeadRule(text: "Your frost dates", trailing: "zone \(garden.dates.zone)")
                HStack(spacing: 9) {
                    CountTile(value: garden.dates.lastLabel, label: "last spring frost", tone: Loam.frostDeep)
                    CountTile(value: garden.dates.firstLabel, label: "first fall frost", tone: Loam.terracottaDeep)
                    CountTile(value: garden.dates.frostFree ? "365" : "\(max(0, fy.firstFrost - fy.lastFrost))", label: "frost-free days")
                }
                YearRuler(dates: garden.dates, today: garden.today, marks: [])
                    .frame(height: 44)
                Text("Every window in the almanac is counted from these two dates. Change them in Settings and every crop is recomputed.")
                    .font(Loam.note(12)).foregroundColor(Loam.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .rising(4)
    }
}

struct JobRow: View {
    var job: Job
    var today: Int
    var done: Bool
    var action: () -> Void

    var body: some View {
        Button(action: { if !done { action() } }) {
            HStack(alignment: .top, spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5).stroke(done ? Loam.good : Loam.ink.opacity(0.35), lineWidth: 1.2)
                        .frame(width: 22, height: 22)
                    if done { TickGlyph(size: 16, color: Loam.good) }
                }
                .padding(.top, 1)
                VStack(alignment: .leading, spacing: 3) {
                    Text(job.title).font(Loam.title(14)).foregroundColor(done ? Loam.inkFaint : Loam.ink)
                        .strikethrough(done, color: Loam.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(job.detail).font(Loam.body(12)).foregroundColor(Loam.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 8) {
                        StampTag(text: Almanac.relative(job.due, to: today), tone: tagTone)
                        if job.needsPlot && !done {
                            Text("opens the plot").font(Loam.note(11)).foregroundColor(Loam.inkFaint)
                        }
                        Spacer()
                        Text("+\(job.points)").font(Loam.title(11)).foregroundColor(Loam.terracotta)
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4)
    }

    private var tagTone: Color {
        if done { return Loam.good }
        if job.due < today { return Loam.bad }
        if job.due == today { return Loam.warn }
        return Loam.frostDeep
    }
}

struct LadderStrip: View {
    var index: Int
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<Ladder.steps.count, id: \.self) { i in
                VStack(spacing: 3) {
                    Rectangle().fill(i <= index ? Loam.terracotta : Loam.ink.opacity(0.12)).frame(height: 4)
                    Text(Ladder.steps[i].1).font(Loam.body(8)).foregroundColor(i == index ? Loam.ink : Loam.inkFaint)
                        .lineLimit(1).minimumScaleFactor(0.6)
                }
            }
        }
    }
}

struct YearRuler: View {
    var dates: FrostDates
    var today: Int
    var marks: [(DayWindow, Color, String)]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let year = Almanac.year(of: today)
            let fy = FrostYear(dates, year: year)
            let start = fy.jan1
            let days = Almanac.daysInYear(year)
            let x = { (d: Int) -> CGFloat in CGFloat(max(0, min(days, d - start))) / CGFloat(days) * w }
            ZStack(alignment: .topLeading) {
                Rectangle().fill(Loam.ink.opacity(0.07)).frame(height: 14).offset(y: 12)
                if !dates.frostFree {
                    Rectangle().fill(Loam.frost.opacity(0.5)).frame(width: x(fy.lastFrost), height: 14).offset(y: 12)
                    Rectangle().fill(Loam.frost.opacity(0.5)).frame(width: max(0, w - x(fy.firstFrost)), height: 14).offset(x: x(fy.firstFrost), y: 12)
                    Rectangle().fill(Loam.frostDeep).frame(width: 1.5, height: 26).offset(x: x(fy.lastFrost), y: 6)
                    Rectangle().fill(Loam.terracottaDeep).frame(width: 1.5, height: 26).offset(x: x(fy.firstFrost), y: 6)
                }
                ForEach(Array(marks.enumerated()), id: \.offset) { _, mark in
                    Capsule().fill(mark.1)
                        .frame(width: max(3, x(mark.0.end) - x(mark.0.start)), height: 8)
                        .offset(x: x(mark.0.start), y: 15)
                }
                ForEach(0..<12, id: \.self) { m in
                    let d = Almanac.dayIndex(year: year, month: m + 1, day: 1)
                    Text(String(Almanac.monthShort[m].prefix(1)))
                        .font(Loam.body(8)).foregroundColor(Loam.inkFaint)
                        .position(x: x(d) + w / 24, y: 36)
                }
                Rectangle().fill(Loam.ink).frame(width: 1.5, height: 20).offset(x: x(today), y: 9)
                Circle().fill(Loam.ink).frame(width: 5, height: 5).offset(x: x(today) - 1.75, y: 5)
            }
        }
    }
}

struct NoteSheet: View {
    @EnvironmentObject var garden: FrostGarden
    var note: DailyNote
    var onClose: () -> Void
    @State private var picked: Int? = nil
    @State private var tries = 0

    var body: some View {
        VStack(spacing: 0) {
            SheetHead(title: note.kind.title, subtitle: Almanac.labelLong(note.day), onClose: onClose)
            ScrollView {
                Column {
                    SheetCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(note.prompt).font(Loam.title(17)).foregroundColor(Loam.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            ForEach(0..<note.options.count, id: \.self) { i in
                                Button(action: { choose(i) }) {
                                    HStack(alignment: .top, spacing: 10) {
                                        ZStack {
                                            Circle().stroke(tone(i), lineWidth: 1.3).frame(width: 22, height: 22)
                                            if picked == i { Circle().fill(tone(i)).frame(width: 12, height: 12) }
                                        }
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(note.options[i]).font(Loam.title(14)).foregroundColor(Loam.ink)
                                            if i < note.detail.count {
                                                Text(note.detail[i]).font(Loam.body(12)).foregroundColor(Loam.inkFaint)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                        }
                                        Spacer(minLength: 0)
                                    }
                                    .padding(10)
                                    .background(RoundedRectangle(cornerRadius: 6).fill(tone(i).opacity(picked == i ? 0.12 : 0.04)))
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .disabled(solved)
                            }
                            if solved {
                                NoticeBar(text: note.explanation, tone: Loam.good)
                            } else if let p = picked, p != note.answer {
                                NoticeBar(text: "Not that one. Think about which family or which hardiness is in play, and try again.", tone: Loam.warn)
                            }
                        }
                    }
                }
                .padding(.horizontal, Loam.gutter)
                .padding(.bottom, 24)
            }
        }
        .background(Loam.page.ignoresSafeArea())
    }

    private var solved: Bool { garden.noteSolved(note.day) || picked == note.answer }

    private func tone(_ i: Int) -> Color {
        if let p = picked, p == i { return p == note.answer ? Loam.good : Loam.bad }
        if garden.noteSolved(note.day) && i == note.answer { return Loam.good }
        return Loam.ink.opacity(0.5)
    }

    private func choose(_ i: Int) {
        guard !solved else { return }
        tries += 1
        withAnimation(.easeOut(duration: 0.2)) { picked = i }
        if i == note.answer {
            Tap.firm()
            garden.solveNote(note.day, firstTry: tries == 1)
        } else {
            Tap.crisp()
        }
    }
}
