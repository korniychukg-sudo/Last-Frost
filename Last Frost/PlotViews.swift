import SwiftUI

struct PlotView: View {
    @EnvironmentObject var garden: FrostGarden
    @State private var openBed: String? = nil
    @State private var scrubDay: Int? = nil
    @State private var confirmRemove: Bed? = nil
    @State private var restored = false
    @State private var openShelf = false

    var body: some View {
        ScrollView {
            Column {
                header
                mapCard
                seasonCard
                bedsCard
                traysCard
            }
            .padding(.horizontal, Loam.gutter)
            .padding(.bottom, 28)
        }
        .background(Loam.page.ignoresSafeArea())
        .navigationBarHidden(true)
        .background(
            Group {
                ForEach(garden.book.beds) { bed in
                    NavigationLink(destination: BedView(bedId: bed.id).environmentObject(garden),
                                   tag: bed.id, selection: $openBed) { EmptyView() }
                }
                NavigationLink(destination: TrayShelfView().environmentObject(garden), isActive: $openShelf) { EmptyView() }
            }
            .hidden()
        )
        .onAppear {
            if !restored {
                restored = true
                if let s = garden.book.uiScrub, s != garden.today, abs(s - garden.today) < 400 { scrubDay = s }
                if let b = garden.book.uiBed, garden.bed(b) != nil, garden.wantedBed == nil { openBed = b }
            }
        }
        .onChange(of: openBed) { value in garden.remember(bed: value) }
        .onChange(of: scrubDay) { value in garden.remember(scrub: value) }
        .onReceive(garden.$wantedBed) { wanted in
            if let w = wanted, garden.bed(w) != nil {
                openBed = w
                garden.wantedBed = nil
            }
        }
        .alert(item: $confirmRemove) { bed in
            Alert(title: Text("Remove \(bed.name)?"),
                  message: Text("Its \(bed.planted) planted squares and its rotation history go with it."),
                  primaryButton: .destructive(Text("Remove")) { Tap.hard(); garden.removeBed(bed.id) },
                  secondaryButton: .cancel())
        }
    }

    private var viewDay: Int { scrubDay ?? garden.today }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("The Plot").font(Loam.title(26)).foregroundColor(Loam.ink)
                Text(scrubDay == nil ? "As it stands on \(Almanac.labelLong(garden.today))" : "Scrubbed to \(Almanac.labelLong(viewDay))")
                    .font(Loam.note(13)).foregroundColor(Loam.inkFaint)
            }
            Spacer()
            HStack(spacing: 8) {
                CountTile(value: "\(garden.book.beds.count)", label: "beds")
                CountTile(value: "\(garden.plantedCells)", label: "growing", tone: Loam.leafDeep)
            }
            .frame(width: 130)
        }
        .padding(.top, 8)
    }

    private var mapCard: some View {
        SheetCard(padding: 0) {
            VStack(spacing: 0) {
                PlotMapView(beds: garden.book.beds, day: viewDay, dates: garden.dates, projected: scrubDay != nil,
                            trouble: garden.troubleToday.flatMap { garden.troubleSolved($0.id) ? nil : $0 }) { bedId in
                    Tap.light()
                    openBed = bedId
                }
                .frame(height: mapHeight)
                .clipped()
                HStack {
                    Text(garden.book.beds.isEmpty ? "No beds yet. Add one below and drag a crop onto a square."
                            : "Tap a bed to open it. \(garden.stakedCells) squares staked, \(garden.plantedCells) growing.")
                        .font(Loam.body(12)).foregroundColor(Loam.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(12)
            }
        }
        .rising(0)
    }

    private var mapHeight: CGFloat {
        let n = garden.book.beds.count
        let rows = max(1, Int(ceil(Double(n) / Double(Loam.isPad ? 3 : 2))))
        return CGFloat(60 + rows * (Loam.isPad ? 150 : 118))
    }

    private var seasonCard: some View {
        SheetCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HeadRule(text: "The year at a scrub")
                    if scrubDay != nil {
                        Button(action: { Tap.light(); withAnimation(.easeOut(duration: 0.2)) { scrubDay = nil } }) {
                            Text("Back to today").font(Loam.title(11)).foregroundColor(Loam.terracotta)
                        }
                        .buttonStyle(.plain)
                    }
                }
                SeasonSlider(day: Binding(get: { viewDay }, set: { scrubDay = $0 == garden.today ? nil : $0 }),
                             today: garden.today, dates: garden.dates)
                    .frame(height: 70)
                Text(scrubText)
                    .font(Loam.note(12.5)).foregroundColor(Loam.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .rising(1)
    }

    private var scrubText: String {
        let d = viewDay
        let fy = garden.frostYear
        let weather = Weather.at(day: d, dates: garden.dates)
        var growing = 0, ready = 0, projected = 0
        for bed in garden.book.beds {
            for cell in bed.cells {
                if let p = cell.planting {
                    let s = p.stage(on: d)
                    if s == .mature { ready += 1 } else if s != .bare && s != .spent { growing += 1 }
                } else if scrubDay != nil, let stake = cell.stake, let proj = Projection.planting(for: Register.find(stake), dates: garden.dates, year: Almanac.year(of: d)) {
                    if proj.stage(on: d) != .bare { projected += 1 }
                }
            }
        }
        if scrubDay == nil {
            return "Drag the knob to see the beds on any day of the year. Staked squares are projected forward to their sowing window."
        }
        let frost = garden.dates.frostFree ? "" : (d < fy.lastFrost ? " Before the last frost." : (d > fy.firstFrost ? " After the first frost." : ""))
        return "\(Almanac.labelLong(d)): \(growing) growing, \(ready) in their harvest window, \(projected) projected from stakes. \(weather.name).\(frost)"
    }

    private var bedsCard: some View {
        SheetCard {
            VStack(alignment: .leading, spacing: 10) {
                HeadRule(text: "Beds", trailing: "\(garden.book.beds.count) of 12")
                if garden.book.beds.isEmpty {
                    Text("A bed is a grid of square-foot cells. The default is four by two; add up to twelve.")
                        .font(Loam.body(13)).foregroundColor(Loam.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ForEach(garden.book.beds) { bed in
                    Button(action: { Tap.light(); openBed = bed.id }) {
                        HStack(spacing: 12) {
                            BedThumb(bed: bed, day: viewDay).frame(width: 84, height: 44)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(bed.name).font(Loam.title(15)).foregroundColor(Loam.ink)
                                Text(bedSummary(bed)).font(Loam.body(12)).foregroundColor(Loam.inkFaint)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 4)
                            ChevGlyph(size: 14, color: Loam.inkFaint, back: false)
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(action: { confirmRemove = bed }) { Text("Remove \(bed.name)") }
                    }
                }
                HStack(spacing: 8) {
                    SowButton(title: "Add a bed", tone: Loam.leafDeep, filled: false, enabled: garden.book.beds.count < 12) {
                        if let bed = garden.addBed() { Tap.firm(); openBed = bed.id }
                    }
                    if let last = garden.book.beds.last {
                        SowButton(title: "Remove last", tone: Loam.bad, filled: false) { confirmRemove = last }
                    }
                }
            }
        }
        .rising(2)
    }

    private func bedSummary(_ bed: Bed) -> String {
        var parts: [String] = []
        if bed.planted > 0 { parts.append("\(bed.planted) growing") }
        if bed.staked > 0 { parts.append("\(bed.staked) staked") }
        let ready = bed.cells.filter { $0.planting?.stage(on: viewDay) == .mature }.count
        if ready > 0 { parts.append("\(ready) ready to pull") }
        if parts.isEmpty { parts.append("\(bed.cols) by \(bed.rows), empty") }
        if let last = bed.history.last, !last.isEmpty {
            parts.append("last season: " + last.map { familyShort($0) }.joined(separator: ", "))
        }
        return parts.joined(separator: " · ")
    }

    private var traysCard: some View {
        SheetCard {
            VStack(alignment: .leading, spacing: 10) {
                HeadRule(text: "Seed trays under the lamp", trailing: garden.book.trays.isEmpty ? nil : "\(garden.book.trays.count)")
                Button(action: { Tap.light(); openShelf = true }) {
                    SheetCard(padding: 0) {
                        HStack(spacing: 0) {
                            ThumbBox(name: "ty_\(trayStage)", height: 84, corner: 0, side: 320).frame(width: 128)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Open the shelf").font(Loam.title(14)).foregroundColor(Loam.ink)
                                Text(garden.book.trays.isEmpty ? "A windowsill and two shelves under a grow lamp: sow, prick out, and harden off on the step."
                                        : "\(garden.book.trays.count) \(garden.book.trays.count == 1 ? "tray" : "trays") growing by the real date; \(garden.book.trays.filter { $0.hardening }.count) on the doorstep.")
                                    .font(Loam.body(11.5)).foregroundColor(Loam.inkFaint).fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(10)
                            Spacer(minLength: 0)
                            ChevGlyph(size: 14, color: Loam.inkFaint, back: false).padding(.trailing, 10)
                        }
                    }
                }
                .buttonStyle(.plain)
                if garden.book.trays.isEmpty {
                    Text("Crops that start indoors live here until their window opens. Stake a tomato in a bed and the plan will offer to start a tray when the time comes, or sow one on the shelf.")
                        .font(Loam.body(13)).foregroundColor(Loam.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ForEach(garden.book.trays) { tray in
                    TrayRow(tray: tray).environmentObject(garden)
                }
            }
        }
        .rising(3)
    }
}

extension PlotView {
    var trayStage: Int {
        let trays = garden.book.trays
        if trays.contains(where: { $0.hardening }) { return 3 }
        if trays.contains(where: { $0.pricked }) { return 2 }
        if trays.contains(where: { $0.seedlingHeight(on: garden.today) >= 0.2 }) { return 1 }
        return 0
    }
}

func familyShort(_ botanical: String) -> String {
    for f in CropFamily.allCases where f.latin == botanical { return f.name }
    return botanical
}

struct TrayRow: View {
    @EnvironmentObject var garden: FrostGarden
    var tray: SeedTray

    var body: some View {
        let crop = Register.find(tray.crop)
        let fy = garden.frostYear
        let window = Planner.transplantWindow(crop, fy)
        let verdict = Planner.verdict(for: crop, on: garden.today, dates: garden.dates)
        let open = verdict.kind == .transplant || verdict.kind == .direct || verdict.kind == .fall
        return HStack(spacing: 12) {
            PlantGlyph(crop: crop, stage: tray.hardenedDay == nil ? .sprout : .leaf, growth: 0.6, size: 44)
                .background(RoundedRectangle(cornerRadius: 6).fill(Loam.soil.opacity(0.18)))
            VStack(alignment: .leading, spacing: 3) {
                Text(crop.plural).font(Loam.title(15)).foregroundColor(Loam.ink)
                Text("Sown \(Almanac.label(tray.sowDay))" + (tray.hardenedDay != nil ? ", hardened off" : "") + (window.map { "; out \($0.label)" } ?? ""))
                    .font(Loam.body(12)).foregroundColor(Loam.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
                if let w = window {
                    StampTag(text: open ? "can go out" : (garden.today < w.start ? "opens \(Almanac.relative(w.start, to: garden.today))" : "past the window"),
                             tone: open ? Loam.good : Loam.frostDeep)
                }
            }
            Spacer(minLength: 4)
            Button(action: { Tap.light(); garden.discardTray(tray.id) }) {
                CrossGlyph(size: 13, color: Loam.inkFaint).padding(7).background(Circle().fill(Loam.ink.opacity(0.06)))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

enum Projection {
    static func planting(for crop: Crop, dates: FrostDates, year: Int) -> Planting? {
        let fy = FrostYear(dates, year: year)
        if let d = Planner.directWindow(crop, fy) {
            return Planting(crop: crop.key, sowDay: d.start, method: 0, seeds: crop.perCell, spacing: 100, thinned: true, rotation: 0, companions: 0, antagonists: 0, watered: nil)
        }
        if let t = Planner.transplantWindow(crop, fy) {
            return Planting(crop: crop.key, sowDay: t.start, method: 1, seeds: crop.perCell, spacing: 100, thinned: true, rotation: 0, companions: 0, antagonists: 0, watered: nil)
        }
        if let f = Planner.fallWindow(crop, fy) {
            return Planting(crop: crop.key, sowDay: f.start, method: 0, seeds: crop.perCell, spacing: 100, thinned: true, rotation: 0, companions: 0, antagonists: 0, watered: nil)
        }
        return nil
    }
}

struct PlotLayout {
    var rects: [(String, CGRect)]

    static func make(beds: [Bed], in size: CGSize) -> PlotLayout {
        let cols = Loam.isPad ? 3 : 2
        let inset: CGFloat = 16
        let gap: CGFloat = 14
        let usable = size.width - inset * 2 - CGFloat(gap) * CGFloat(cols - 1)
        let bw = usable / CGFloat(cols)
        let bh: CGFloat = Loam.isPad ? 112 : 88
        var rects: [(String, CGRect)] = []
        for (k, bed) in beds.enumerated() {
            let c = k % cols, r = k / cols
            let x = inset + CGFloat(c) * (bw + gap)
            let y = 26 + CGFloat(r) * (bh + 30)
            let ratio = CGFloat(bed.cols) / CGFloat(bed.rows)
            let w = min(bw, bh * ratio)
            rects.append((bed.id, CGRect(x: x + (bw - w) / 2, y: y, width: w, height: bh)))
        }
        return PlotLayout(rects: rects)
    }
}

struct PlotMapView: View {
    var beds: [Bed]
    var day: Int
    var dates: FrostDates
    var projected: Bool
    var trouble: TroubleEvent? = nil
    var onTap: (String) -> Void

    var body: some View {
        GeometryReader { geo in
            let layout = PlotLayout.make(beds: beds, in: geo.size)
            ZStack {
                Canvas { ctx, size in
                    drawPlot(&ctx, size: size, layout: layout)
                }
                ForEach(layout.rects, id: \.0) { item in
                    Button(action: { onTap(item.0) }) {
                        Color.clear.contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .frame(width: item.1.width + 8, height: item.1.height + 8)
                    .position(x: item.1.midX, y: item.1.midY)
                }
            }
        }
    }

    private func drawPlot(_ ctx: inout GraphicsContext, size: CGSize, layout: PlotLayout) {
        let w = size.width, h = size.height
        let season = Almanac.season(of: day)
        let ground: Color
        switch season {
        case 1: ground = Color(red: 0.62, green: 0.68, blue: 0.46)
        case 2: ground = Color(red: 0.56, green: 0.64, blue: 0.40)
        case 3: ground = Color(red: 0.70, green: 0.63, blue: 0.44)
        default: ground = Color(red: 0.72, green: 0.70, blue: 0.62)
        }
        ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(ground))
        var rng = Furrow(0x77)
        for _ in 0..<Int(w * h / 260) {
            let x = CGFloat(rng.unit()) * w, y = CGFloat(rng.unit()) * h
            ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.6, height: 1.6)), with: .color(Loam.strawPale.opacity(0.5)))
        }
        for _ in 0..<Int(w * h / 900) {
            let x = CGFloat(rng.unit()) * w, y = CGFloat(rng.unit()) * h
            var blade = Path()
            blade.move(to: CGPoint(x: x, y: y))
            blade.addLine(to: CGPoint(x: x + CGFloat(rng.unit() - 0.5) * 3, y: y - 3 - CGFloat(rng.unit()) * 3))
            ctx.stroke(blade, with: .color(Loam.leafDeep.opacity(season == 0 ? 0.15 : 0.35)), lineWidth: 0.8)
        }
        let hedge = Path(roundedRect: CGRect(x: 4, y: 4, width: w - 8, height: h - 8), cornerRadius: 8)
        ctx.stroke(hedge, with: .color(Loam.leafDeep.opacity(season == 0 ? 0.35 : 0.6)), lineWidth: 5)
        ctx.stroke(hedge, with: .color(Loam.ink.opacity(0.25)), lineWidth: 1)
        let bay = CGRect(x: w - 42, y: h - 30, width: 30, height: 20)
        ctx.fill(Path(bay), with: .color(Loam.soilDark))
        ctx.stroke(Path(bay), with: .color(Loam.soilLight), lineWidth: 2)
        ctx.fill(Path(ellipseIn: CGRect(x: bay.minX + 4, y: bay.minY - 5, width: 22, height: 12)), with: .color(Loam.soil))
        let deep = FrostYear(dates, year: Almanac.year(of: day))
        let frosty = !dates.frostFree && (day < deep.lastFrost - 21 || day > deep.firstFrost + 21)
        for (bedId, rect) in layout.rects {
            guard let bed = beds.first(where: { $0.id == bedId }) else { continue }
            ctx.fill(Path(roundedRect: rect.insetBy(dx: -4, dy: -4), cornerRadius: 3), with: .color(Loam.soilLight))
            ctx.fill(Path(rect), with: .color(Loam.soil))
            var grit = Furrow(hashOf(bedId))
            for _ in 0..<Int(rect.width * rect.height / 40) {
                let x = rect.minX + CGFloat(grit.unit()) * rect.width, y = rect.minY + CGFloat(grit.unit()) * rect.height
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.4, height: 1.4)), with: .color(Color.black.opacity(0.16)))
            }
            if frosty {
                for _ in 0..<Int(rect.width * rect.height / 30) {
                    let x = rect.minX + CGFloat(grit.unit()) * rect.width, y = rect.minY + CGFloat(grit.unit()) * rect.height
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)), with: .color(Color.white.opacity(0.6)))
                }
            }
            let cw = rect.width / CGFloat(bed.cols), ch = rect.height / CGFloat(bed.rows)
            for c in 1..<bed.cols {
                var line = Path()
                line.move(to: CGPoint(x: rect.minX + CGFloat(c) * cw, y: rect.minY))
                line.addLine(to: CGPoint(x: rect.minX + CGFloat(c) * cw, y: rect.maxY))
                ctx.stroke(line, with: .color(Loam.strawPale.opacity(0.35)), lineWidth: 0.8)
            }
            for r in 1..<bed.rows {
                var line = Path()
                line.move(to: CGPoint(x: rect.minX, y: rect.minY + CGFloat(r) * ch))
                line.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + CGFloat(r) * ch))
                ctx.stroke(line, with: .color(Loam.strawPale.opacity(0.35)), lineWidth: 0.8)
            }
            for (i, cell) in bed.cells.enumerated() {
                let c = i % bed.cols, r = i / bed.cols
                let cr = CGRect(x: rect.minX + CGFloat(c) * cw, y: rect.minY + CGFloat(r) * ch, width: cw, height: ch)
                var planting = cell.planting
                var ghost = false
                if planting == nil, projected, let stake = cell.stake {
                    planting = Projection.planting(for: Register.find(stake), dates: dates, year: Almanac.year(of: day))
                    ghost = true
                }
                if let p = planting {
                    let stage = p.stage(on: day)
                    if stage == .bare && cell.planting == nil && !ghost { continue }
                    if stage == .bare { continue }
                    var sub = ctx
                    if ghost { sub.opacity = 0.55 }
                    var painter = PlantPainter(sub, crop: Register.find(p.crop), stage: stage, growth: p.growth(on: day),
                                               rect: cr.insetBy(dx: cw * 0.08, dy: ch * 0.06), detail: false, seed: hashOf(bedId + "\(i)"))
                    painter.draw()
                    if stage == .mature && !ghost {
                        ctx.stroke(Path(roundedRect: cr.insetBy(dx: 1, dy: 1), cornerRadius: 2), with: .color(Loam.prize.opacity(0.8)), lineWidth: 1.2)
                    }
                    if let ev = trouble, ev.bedId == bedId, ev.cell == i, !projected {
                        var sym = SymptomPainter(ctx: ctx, symptom: Troubles.find(ev.trouble).symptom, rect: cr.insetBy(dx: cw * 0.08, dy: ch * 0.06), time: 0.7, seed: hashOf(ev.trouble))
                        sym.draw()
                        ctx.stroke(Path(roundedRect: cr.insetBy(dx: 1, dy: 1), cornerRadius: 2), with: .color(Loam.terracotta.opacity(0.9)), style: StrokeStyle(lineWidth: 1.2, dash: [3, 3]))
                    }
                } else if cell.stake != nil {
                    var stake = Path()
                    stake.move(to: CGPoint(x: cr.midX, y: cr.maxY - ch * 0.2))
                    stake.addLine(to: CGPoint(x: cr.midX, y: cr.minY + ch * 0.25))
                    ctx.stroke(stake, with: .color(Loam.strawPale), style: StrokeStyle(lineWidth: max(1.5, cw * 0.08), lineCap: .round))
                    ctx.fill(Path(CGRect(x: cr.midX - cw * 0.16, y: cr.minY + ch * 0.22, width: cw * 0.32, height: ch * 0.18)), with: .color(Loam.strawPale))
                }
            }
            let growing = bed.cells.contains { cell in
                if let p = cell.planting { return p.stage(on: day) != .bare }
                if projected, let stake = cell.stake, let proj = Projection.planting(for: Register.find(stake), dates: dates, year: Almanac.year(of: day)) { return proj.stage(on: day) != .bare }
                return false
            }
            if projected && !growing && !dates.frostFree && day > deep.firstFrost + 14 {
                var tufts = Furrow(hashOf(bedId) ^ 0x2C)
                for _ in 0..<Int(rect.width * rect.height / 18) {
                    let x = rect.minX + 2 + CGFloat(tufts.unit()) * (rect.width - 4)
                    let y = rect.minY + 3 + CGFloat(tufts.unit()) * (rect.height - 4)
                    var blade = Path()
                    blade.move(to: CGPoint(x: x, y: y))
                    blade.addLine(to: CGPoint(x: x + CGFloat(tufts.unit() - 0.5) * 2, y: y - 3 - CGFloat(tufts.unit()) * 3))
                    ctx.stroke(blade, with: .color(Loam.leafPale.opacity(0.85)), lineWidth: 0.9)
                }
                ctx.draw(Text("cover crop").font(Loam.note(8)).foregroundColor(Loam.card), at: CGPoint(x: rect.midX, y: rect.midY))
            }
            ctx.stroke(Path(roundedRect: rect.insetBy(dx: -4, dy: -4), cornerRadius: 3), with: .color(Loam.ink.opacity(0.45)), lineWidth: 1)
            let label = Text(bed.name).font(Loam.title(10)).foregroundColor(Loam.ink)
            ctx.draw(label, at: CGPoint(x: rect.midX, y: rect.maxY + 12))
        }
    }
}

struct BedThumb: View {
    var bed: Bed
    var day: Int
    var troubleCell: Int? = nil
    var symptom: Symptom? = nil
    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 3), with: .color(Loam.soil))
            let cw = size.width / CGFloat(bed.cols), ch = size.height / CGFloat(bed.rows)
            for (i, cell) in bed.cells.enumerated() {
                let c = i % bed.cols, r = i / bed.cols
                let cr = CGRect(x: CGFloat(c) * cw, y: CGFloat(r) * ch, width: cw, height: ch)
                if let p = cell.planting {
                    let stage = p.stage(on: day)
                    if stage == .bare { continue }
                    var painter = PlantPainter(ctx, crop: Register.find(p.crop), stage: stage, growth: p.growth(on: day),
                                               rect: cr.insetBy(dx: 1, dy: 1), detail: false, seed: hashOf(bed.id + "\(i)"))
                    painter.draw()
                    if troubleCell == i, let sym = symptom {
                        var painterS = SymptomPainter(ctx: ctx, symptom: sym, rect: cr.insetBy(dx: 1, dy: 1), time: 0.7, seed: hashOf(sym.rawValue))
                        painterS.draw()
                        ctx.stroke(Path(cr.insetBy(dx: 0.5, dy: 0.5)), with: .color(Loam.terracotta), lineWidth: 1.2)
                    }
                } else if cell.stake != nil {
                    ctx.fill(Path(CGRect(x: cr.midX - 1, y: cr.minY + 3, width: 2, height: ch - 6)), with: .color(Loam.strawPale))
                }
            }
            ctx.stroke(Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 3), with: .color(Loam.soilLight), lineWidth: 2)
        }
    }
}

struct SeasonSlider: View {
    @Binding var day: Int
    var today: Int
    var dates: FrostDates

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let year = Almanac.year(of: today)
            let fy = FrostYear(dates, year: year)
            let start = fy.jan1
            let days = Almanac.daysInYear(year)
            let x = { (d: Int) -> CGFloat in CGFloat(max(0, min(days - 1, d - start))) / CGFloat(days - 1) * (w - 24) + 12 }
            ZStack(alignment: .topLeading) {
                Capsule().fill(Loam.ink.opacity(0.08)).frame(height: 10).offset(y: 22)
                if !dates.frostFree {
                    Capsule().fill(Loam.frost.opacity(0.55)).frame(width: max(2, x(fy.lastFrost) - 12), height: 10).offset(x: 12, y: 22)
                    Capsule().fill(Loam.frost.opacity(0.55)).frame(width: max(2, w - 12 - x(fy.firstFrost)), height: 10).offset(x: x(fy.firstFrost), y: 22)
                }
                ForEach(0..<12, id: \.self) { m in
                    let d = Almanac.dayIndex(year: year, month: m + 1, day: 1)
                    Rectangle().fill(Loam.ink.opacity(0.25)).frame(width: 1, height: 6).offset(x: x(d), y: 34)
                    Text(String(Almanac.monthShort[m].prefix(1))).font(Loam.body(9)).foregroundColor(Loam.inkFaint)
                        .position(x: x(d) + (w - 24) / 24, y: 52)
                }
                Rectangle().fill(Loam.terracotta.opacity(0.7)).frame(width: 1.5, height: 22).offset(x: x(today), y: 16)
                ZStack {
                    Circle().fill(Loam.card).frame(width: 30, height: 30)
                        .overlay(Circle().stroke(Loam.ink.opacity(0.5), lineWidth: 1.2))
                        .shadow(color: Loam.ink.opacity(0.2), radius: 3, x: 0, y: 2)
                    Text(Almanac.label(day)).font(Loam.title(8)).foregroundColor(Loam.ink)
                        .lineLimit(1).minimumScaleFactor(0.7).frame(width: 28)
                }
                .position(x: x(day), y: 27)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let t = max(0, min(1, (value.location.x - 12) / (w - 24)))
                        let d = start + Int((t * CGFloat(days - 1)).rounded())
                        if d != day {
                            day = d
                            if d % 7 == 0 { Tap.soft() }
                        }
                    }
            )
        }
    }
}
