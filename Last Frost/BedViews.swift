import SwiftUI

struct GridFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}

enum BedTool { case none, water }

enum PressMode { case undecided, drill, setOut, pull, water, pan }

struct PressState {
    var cell: Int
    var origin: CGPoint
    var start: Date
    var mode: PressMode = .undecided
    var seeds: [CGPoint] = []
    var travelled: CGFloat = 0
    var last: CGPoint
    var pull: CGFloat = 0
    var holdProgress: Double = 0
}

struct ChipDrag {
    var crop: String
    var tray: String?
    var point: CGPoint
}

struct BannerState: Equatable {
    var text: String
    var tone: Int
    var actionTitle: String?
    var actionCrop: String?
}

struct BedView: View {
    @EnvironmentObject var garden: FrostGarden
    let bedId: String
    @State private var selected: Int? = nil
    @State private var tool: BedTool = .none
    @State private var banner: BannerState? = nil
    @State private var drag: ChipDrag? = nil
    @State private var gridFrame: CGRect = .zero
    @State private var press: PressState? = nil
    @State private var holdTimer: Timer? = nil
    @State private var celebration: LarderEntry? = nil
    @State private var covering: Int? = nil
    @State private var renaming = false
    @State private var newName = ""
    @State private var showAll = false
    @State private var family: CropFamily? = nil
    @State private var confirmClear = false
    @State private var wateredFlash: Int? = nil
    @State private var tick = 0
    @State private var openTrouble = false
    private let clock = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    private var bed: Bed { garden.bed(bedId) ?? Bed.make("missing", name: "Bed") }

    private var troubleHere: TroubleEvent? {
        guard let ev = garden.troubleToday, ev.bedId == bedId, ev.cell < bed.cells.count, bed.cells[ev.cell].planting != nil else { return nil }
        return ev
    }

    var body: some View {
        ZStack {
            Loam.page.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        gridCard
                        if let b = banner { bannerView(b) }
                        infoPanel
                        historyCard
                    }
                    .padding(.horizontal, Loam.gutter)
                    .padding(.bottom, 12)
                }
                tray
            }
            if let d = drag {
                ChipGhost(crop: Register.find(d.crop), tray: d.tray != nil)
                    .position(d.point)
                    .allowsHitTesting(false)
            }
            if let entry = celebration {
                HarvestOverlay(entry: entry) { celebration = nil }
            }
        }
        .coordinateSpace(name: "bed")
        .navigationBarHidden(true)
        .onAppear {
            if let c = garden.book.uiCell, garden.book.uiBed == bedId, c < bed.cells.count { selected = c }
        }
        .onChange(of: selected) { value in garden.remember(cell: value) }
        .onReceive(clock) { _ in
            if press?.mode == .setOut { tick += 1 }
        }
        .sheet(isPresented: $renaming) {
            RenameSheet(name: $newName) { garden.renameBed(bedId, newName); renaming = false }
        }
        .sheet(isPresented: $openTrouble) {
            if let ev = troubleHere ?? garden.troubleToday {
                TroubleSheet(event: ev, bedName: bed.name) { openTrouble = false }.environmentObject(garden)
            }
        }
        .alert(isPresented: $confirmClear) {
            Alert(title: Text("Clear this square?"), message: Text("The plant is composted and the square returns to bare soil."),
                  primaryButton: .destructive(Text("Clear")) { if let s = selected { Tap.firm(); garden.clear(bedId, s) } },
                  secondaryButton: .cancel())
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Button(action: { Tap.light(); dismissToPlot() }) {
                HStack(spacing: 4) {
                    ChevGlyph(size: 15, color: Loam.inkSoft)
                    Text("Plot").font(Loam.body(14)).foregroundColor(Loam.inkSoft)
                }
            }
            .buttonStyle(.plain)
            Spacer()
            Button(action: { Tap.light(); newName = bed.name; renaming = true }) {
                HStack(spacing: 6) {
                    Text(bed.name).font(Loam.title(18)).foregroundColor(Loam.ink)
                    Text("rename").font(Loam.note(11)).foregroundColor(Loam.inkFaint)
                }
            }
            .buttonStyle(.plain)
            Spacer()
            Text("\(bed.cols) x \(bed.rows)").font(Loam.body(12)).foregroundColor(Loam.inkFaint)
        }
        .padding(.horizontal, Loam.gutter)
        .padding(.vertical, 10)
    }

    @Environment(\.presentationMode) private var presentation

    private func dismissToPlot() { presentation.wrappedValue.dismiss() }

    private var gridCard: some View {
        SheetCard(padding: 8) {
            VStack(spacing: 6) {
                GeometryReader { geo in
                    BedGridCanvas(bed: bed, day: garden.today, selected: selected, press: press, covering: covering, tool: tool, tick: tick,
                                  trouble: troubleHere, troubleSolved: troubleHere.map { garden.troubleSolved($0.id) } ?? false)
                        .background(GeometryReader { g in
                            Color.clear.preference(key: GridFrameKey.self, value: g.frame(in: .named("bed")))
                        })
                        .contentShape(Rectangle())
                        .highPriorityGesture(gridGesture(size: geo.size))
                }
                .frame(height: gridHeight)
                .onPreferenceChange(GridFrameKey.self) { gridFrame = $0 }
                Text(hint).font(Loam.note(11.5)).foregroundColor(Loam.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var gridHeight: CGFloat {
        let width = min(UIScreen.main.bounds.width - Loam.gutter * 2 - 16, 700)
        return width * CGFloat(bed.rows) / CGFloat(bed.cols)
    }

    private var hint: String {
        if let p = press {
            switch p.mode {
            case .drill: return "Drill open. Draw along the row; \(p.seeds.count) seeds dropped. Release to cover."
            case .setOut: return "Hold to set the plants out."
            case .pull: return "Pull steadily. The root gives when the pull is enough."
            case .water: return "Watering. Drag across every planted square."
            default: break
            }
        }
        if tool == .water { return "The can is in hand. Drag across the squares to water them." }
        if let ev = troubleHere, !garden.troubleSolved(ev.id), selected != ev.cell {
            return "Something is wrong in square \(ev.cell % bed.cols + 1), row \(ev.cell / bed.cols + 1). Tap it and name the trouble."
        }
        if let s = selected, s < bed.cells.count {
            let cell = bed.cells[s]
            if let p = cell.planting {
                let crop = Register.find(p.crop)
                if p.stage(on: garden.today) == .mature { return "\(crop.plural) are in their window. Pull upward on the square to harvest." }
                return "Tap another square, or use the panel below."
            }
            if cell.stake != nil { return "Press and hold the staked square to open the drill, then draw along the row." }
            return "Drag a crop from the tray onto this square to stake it."
        }
        return "Drag a crop from the tray onto a square. Press and hold a staked square to sow."
    }

    private func cellAt(_ point: CGPoint, size: CGSize) -> Int? {
        let cw = size.width / CGFloat(bed.cols), ch = size.height / CGFloat(bed.rows)
        let c = Int(point.x / cw), r = Int(point.y / ch)
        guard c >= 0, c < bed.cols, r >= 0, r < bed.rows else { return nil }
        return r * bed.cols + c
    }

    private func cellRect(_ index: Int, size: CGSize) -> CGRect {
        let cw = size.width / CGFloat(bed.cols), ch = size.height / CGFloat(bed.rows)
        return CGRect(x: CGFloat(index % bed.cols) * cw, y: CGFloat(index / bed.cols) * ch, width: cw, height: ch)
    }

    private func gridGesture(size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                if press == nil {
                    guard let cell = cellAt(value.startLocation, size: size) else { return }
                    press = PressState(cell: cell, origin: value.startLocation, start: Date(), last: value.startLocation)
                    holdTimer?.invalidate()
                    holdTimer = Timer.scheduledTimer(withTimeInterval: 0.42, repeats: false) { _ in decideHold(size: size) }
                    if tool == .water { press?.mode = .water; waterAt(value.location, size: size) }
                    return
                }
                guard var p = press else { return }
                let moved = hypot(value.location.x - p.origin.x, value.location.y - p.origin.y)
                switch p.mode {
                case .undecided:
                    if moved > 12 {
                        holdTimer?.invalidate()
                        if let planting = bed.cells[p.cell].planting, planting.stage(on: garden.today) == .mature {
                            p.mode = .pull
                            Tap.light()
                        } else {
                            p.mode = .pan
                        }
                    }
                case .drill:
                    let step = hypot(value.location.x - p.last.x, value.location.y - p.last.y)
                    p.travelled += step
                    p.last = value.location
                    let cell = cellRect(p.cell, size: size)
                    let spacingPts = cell.width * CGFloat(Register.find(bed.cells[p.cell].stake ?? "lettuce").spacing) / 12
                    let threshold = spacingPts * (CGFloat(p.seeds.count) + 0.5)
                    if p.travelled >= threshold {
                        let clamped = CGPoint(x: min(cell.maxX - 6, max(cell.minX + 6, value.location.x)),
                                              y: min(cell.maxY - 6, max(cell.minY + 6, value.location.y)))
                        p.seeds.append(clamped)
                        Tap.crisp()
                    }
                case .pull:
                    let dy = p.origin.y - value.location.y
                    p.pull = max(0, dy)
                    if p.pull > 110 {
                        press = nil
                        holdTimer?.invalidate()
                        harvest(p.cell)
                        return
                    }
                case .water:
                    waterAt(value.location, size: size)
                case .setOut:
                    p.holdProgress = min(1, Date().timeIntervalSince(p.start) / 1.1)
                    if p.holdProgress >= 1 {
                        press = nil
                        holdTimer?.invalidate()
                        setOut(p.cell)
                        return
                    }
                default:
                    break
                }
                press = p
            }
            .onEnded { value in
                holdTimer?.invalidate()
                guard let p = press else { return }
                press = nil
                switch p.mode {
                case .undecided, .pan:
                    if p.mode == .undecided { Tap.light() }
                    withAnimation(.easeOut(duration: 0.15)) { selected = p.cell }
                case .drill:
                    if !p.seeds.isEmpty, let stake = bed.cells[p.cell].stake {
                        commitSowing(p.cell, crop: stake, seeds: p.seeds.count)
                    } else {
                        banner = BannerState(text: "No seed was dropped. Open the drill again and draw along the row.", tone: 1, actionTitle: nil, actionCrop: nil)
                    }
                case .setOut:
                    let held = Date().timeIntervalSince(p.start)
                    if held >= 1.1 { setOut(p.cell) } else { banner = BannerState(text: "Hold a little longer to set the plants out.", tone: 1, actionTitle: nil, actionCrop: nil) }
                case .pull:
                    Tap.soft()
                case .water:
                    break
                }
            }
    }

    private func decideHold(size: CGSize) {
        guard var p = press, p.mode == .undecided else { return }
        let cell = bed.cells[p.cell]
        if let stake = cell.stake, cell.planting == nil {
            let crop = Register.find(stake)
            let verdict = Planner.verdict(for: crop, on: garden.today, dates: garden.dates)
            switch verdict.kind {
            case .direct, .fall:
                p.mode = .drill
                Tap.firm()
            case .transplant:
                if crop.indoors == nil || garden.book.trays.contains(where: { $0.crop == stake }) {
                    p.mode = .setOut
                    p.start = Date()
                    Tap.firm()
                } else {
                    p.mode = .pan
                    banner = BannerState(text: verdict.text + " Start a tray now and set the plants out from it.", tone: 1, actionTitle: "Start indoors", actionCrop: stake)
                }
            case .startIndoors:
                p.mode = .pan
                banner = BannerState(text: verdict.text, tone: 1, actionTitle: garden.book.trays.contains(where: { $0.crop == stake }) ? nil : "Start indoors", actionCrop: stake)
            default:
                p.mode = .pan
                banner = BannerState(text: verdict.text, tone: 2, actionTitle: nil, actionCrop: nil)
            }
        } else {
            p.mode = .pan
        }
        press = p
    }

    private func waterAt(_ point: CGPoint, size: CGSize) {
        guard let cell = cellAt(point, size: size) else { return }
        if bed.cells[cell].wateredDay != garden.today {
            garden.waterCell(bedId, cell)
            Tap.soft()
            wateredFlash = cell
        }
    }

    private func commitSowing(_ cell: Int, crop key: String, seeds: Int) {
        let crop = Register.find(key)
        let rotation = Rotation.check(crop, in: bed)
        let report = Rotation.neighbours(of: crop, at: cell, in: bed)
        garden.sow(bedId, cell, crop: key, seeds: seeds, transplant: false)
        Tap.hard()
        withAnimation(.easeOut(duration: 0.25)) { covering = cell }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { withAnimation { covering = nil } }
        let ideal = crop.perCell
        var text = "Sown: \(seeds) \(seeds == 1 ? "seed" : "seeds") of \(crop.name.lowercased()) in a square that takes \(ideal) at \(crop.spacing) inches."
        if seeds > ideal { text += " Too dense; a job to thin to \(ideal) will come up at sprouting." }
        else if seeds < ideal { text += " A little thin; the square will carry fewer plants." }
        else { text += " Spacing is exactly right." }
        text += " " + rotation.text + " " + report.text
        banner = BannerState(text: text, tone: seeds == ideal ? 0 : 1, actionTitle: nil, actionCrop: nil)
        selected = cell
    }

    private func setOut(_ cell: Int) {
        guard let stake = bed.cells[cell].stake else { return }
        let crop = Register.find(stake)
        let tray = garden.book.trays.first { $0.crop == stake }
        let rotation = Rotation.check(crop, in: bed)
        let report = Rotation.neighbours(of: crop, at: cell, in: bed)
        garden.sow(bedId, cell, crop: stake, seeds: crop.perCell, transplant: true, tray: tray?.id)
        Tap.hard()
        withAnimation(.easeOut(duration: 0.25)) { covering = cell }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { withAnimation { covering = nil } }
        banner = BannerState(text: "\(crop.plural) set out, \(crop.perCell) to the square. " + rotation.text + " " + report.text, tone: 0, actionTitle: nil, actionCrop: nil)
        selected = cell
    }

    private func harvest(_ cell: Int) {
        guard let entry = garden.harvest(bedId, cell) else { return }
        Tap.hard()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { celebration = entry }
        selected = nil
    }

    private func dropChip(_ d: ChipDrag) {
        guard gridFrame.width > 0, gridFrame.contains(d.point) else { return }
        let local = CGPoint(x: d.point.x - gridFrame.minX, y: d.point.y - gridFrame.minY)
        guard let cell = cellAt(local, size: gridFrame.size) else { return }
        let crop = Register.find(d.crop)
        if bed.cells[cell].planting != nil {
            banner = BannerState(text: "That square is growing \(Register.find(bed.cells[cell].planting?.crop ?? "").plural.lowercased()). Clear it first.", tone: 2, actionTitle: nil, actionCrop: nil)
            Tap.crisp()
            return
        }
        let rotation = Rotation.check(crop, in: bed)
        let report = Rotation.neighbours(of: crop, at: cell, in: bed)
        if let trayId = d.tray {
            let verdict = Planner.verdict(for: crop, on: garden.today, dates: garden.dates)
            if verdict.kind == .transplant || garden.frostYear.lastFrost <= garden.today {
                garden.sow(bedId, cell, crop: d.crop, seeds: crop.perCell, transplant: true, tray: trayId)
                Tap.hard()
                withAnimation(.easeOut(duration: 0.25)) { covering = cell }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { withAnimation { covering = nil } }
                banner = BannerState(text: "\(crop.plural) set out from the tray. " + rotation.text + " " + report.text, tone: rotation == .warn || rotation == .strong ? 1 : 0, actionTitle: nil, actionCrop: nil)
            } else {
                garden.stake(bedId, cell, d.crop)
                banner = BannerState(text: verdict.text + " The square is staked; the tray waits.", tone: 1, actionTitle: nil, actionCrop: nil)
                Tap.firm()
            }
            selected = cell
            return
        }
        garden.stake(bedId, cell, d.crop)
        Tap.firm()
        selected = cell
        let verdict = Planner.verdict(for: crop, on: garden.today, dates: garden.dates)
        var text = verdict.text
        if rotation != .clear { text += " " + rotation.text }
        if !report.companions.isEmpty || !report.antagonists.isEmpty { text += " " + report.text }
        var tone = 0
        switch verdict.kind {
        case .direct, .fall: tone = 0
        case .transplant: tone = crop.indoors == nil || garden.book.trays.contains(where: { $0.crop == d.crop }) ? 0 : 1
        case .startIndoors: tone = 1
        default: tone = 2
        }
        if rotation == .strong || !report.antagonists.isEmpty { tone = max(tone, 1) }
        let offerTray = (verdict.kind == .startIndoors || (verdict.kind == .transplant && crop.indoors != nil)) && !garden.book.trays.contains(where: { $0.crop == d.crop })
        banner = BannerState(text: text, tone: tone, actionTitle: offerTray ? "Start indoors" : nil, actionCrop: offerTray ? d.crop : nil)
    }

    private func bannerView(_ b: BannerState) -> some View {
        let tone: Color = b.tone == 0 ? Loam.good : (b.tone == 1 ? Loam.warn : Loam.bad)
        return NoticeBar(text: b.text, tone: tone, action: b.actionTitle.map { title in
            (title, {
                if let crop = b.actionCrop { garden.startTray(crop); Tap.firm() }
                banner = BannerState(text: "A tray of \(Register.find(b.actionCrop ?? "").plural.lowercased()) is started indoors. It appears in the tray row below; drag it onto the square when its window opens.", tone: 0, actionTitle: nil, actionCrop: nil)
            })
        })
        .transition(.opacity)
    }

    private var infoPanel: some View {
        Group {
            if let s = selected, s < bed.cells.count {
                let cell = bed.cells[s]
                SheetCard {
                    VStack(alignment: .leading, spacing: 9) {
                        HStack {
                            HeadRule(text: "Square \(s % bed.cols + 1), row \(s / bed.cols + 1)")
                            Button(action: { Tap.light(); withAnimation { selected = nil } }) { CrossGlyph(size: 12, color: Loam.inkFaint) }.buttonStyle(.plain)
                        }
                        if let ev = troubleHere, ev.cell == s {
                            troubleInfo(ev)
                        }
                        if let p = cell.planting {
                            plantingInfo(p, cell: s)
                        } else if let stake = cell.stake {
                            stakeInfo(Register.find(stake), cell: s)
                        } else {
                            Text("Bare soil. Drag a crop here from the tray.").font(Loam.body(13)).foregroundColor(Loam.inkSoft)
                            if cell.wateredDay == garden.today { StampTag(text: "watered today", tone: Loam.frostDeep) }
                        }
                    }
                }
            }
        }
    }

    private func troubleInfo(_ ev: TroubleEvent) -> some View {
        let solved = garden.troubleSolved(ev.id)
        let trouble = Troubles.find(ev.trouble)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                SymptomGlyph(crop: Register.find(ev.crop), symptom: trouble.symptom, size: 56)
                VStack(alignment: .leading, spacing: 3) {
                    Text(solved ? "\(trouble.name), put right" : "Trouble in this square").font(Loam.title(15)).foregroundColor(solved ? Loam.good : Loam.terracotta)
                    Text(solved ? "\(trouble.remedy.title) done today. Watch the neighbours; it comes back in its season."
                                : "The \(Register.find(ev.crop).plural.lowercased()) show \(trouble.symptomWords). Name it from three candidates, then do what the register says.")
                        .font(Loam.body(12.5)).foregroundColor(Loam.inkSoft).fixedSize(horizontal: false, vertical: true)
                }
            }
            if !solved {
                SowButton(title: "Name it", tone: Loam.terracotta) { openTrouble = true }
            }
            Rectangle().fill(Loam.ink.opacity(0.08)).frame(height: 0.7)
        }
    }

    private func plantingInfo(_ p: Planting, cell: Int) -> some View {
        let crop = Register.find(p.crop)
        let stage = p.stage(on: garden.today)
        let window = p.harvest(crop)
        return VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top, spacing: 12) {
                PlantGlyph(crop: crop, stage: stage == .bare ? .mature : stage, growth: p.growth(on: garden.today), size: 64)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Loam.soil.opacity(0.2)))
                VStack(alignment: .leading, spacing: 3) {
                    Text(crop.name).font(Loam.title(16)).foregroundColor(Loam.ink)
                    Text(stage == .mature ? "Ready since day \(crop.maturity.lowerBound); day \(max(0, garden.today - p.sowDay)) today. \(p.isTransplant ? "Set out" : "Sown") \(Almanac.label(p.sowDay))."
                            : "\(stage.name), day \(max(0, garden.today - p.sowDay)) of \(crop.maturity.lowerBound). \(p.isTransplant ? "Set out" : "Sown") \(Almanac.label(p.sowDay)).")
                        .font(Loam.body(12.5)).foregroundColor(Loam.inkSoft).fixedSize(horizontal: false, vertical: true)
                    Text(stage == .mature ? "In the window until \(Almanac.label(window.end))." : (garden.today < window.start ? "Harvest window \(window.label)." : "Window closed \(Almanac.label(window.end))."))
                        .font(Loam.note(12)).foregroundColor(Loam.inkFaint).fixedSize(horizontal: false, vertical: true)
                }
            }
            MeterBar(label: "Growth", value: p.growth(on: garden.today), tone: Loam.leaf)
            HStack(spacing: 6) {
                StampTag(text: RotationVerdict(rawValue: p.rotation) == .clear || RotationVerdict(rawValue: p.rotation) == .bonus ? "rotation clear" : "rotation repeat", tone: RotationVerdict(rawValue: p.rotation) == .clear || RotationVerdict(rawValue: p.rotation) == .bonus ? Loam.good : Loam.warn)
                if p.companions > 0 { StampTag(text: "\(p.companions) companion", tone: Loam.good) }
                if p.antagonists > 0 { StampTag(text: "\(p.antagonists) antagonist", tone: Loam.bad) }
                StampTag(text: "spacing \(p.spacing)", tone: p.spacing >= 70 ? Loam.good : Loam.warn)
            }
            HStack(spacing: 8) {
                if p.tooDense && !p.thinned {
                    SowButton(title: "Thin to \(crop.perCell)", tone: Loam.leafDeep, filled: false) { Tap.firm(); garden.thin(bedId, cell) }
                }
                if bed.cells[cell].wateredDay != garden.today {
                    SowButton(title: "Water", tone: Loam.frostDeep, filled: false) { Tap.soft(); garden.waterCell(bedId, cell) }
                }
                SowButton(title: stage == .spent ? "Clear the square" : "Clear", tone: Loam.bad, filled: false) { confirmClear = true }
            }
            if stage == .mature {
                NoticeBar(text: "Pull upward on the square, steadily, to harvest into the larder.", tone: Loam.prize)
            }
        }
    }

    private func stakeInfo(_ crop: Crop, cell: Int) -> some View {
        let verdict = Planner.verdict(for: crop, on: garden.today, dates: garden.dates)
        let rotation = Rotation.check(crop, in: bed)
        let report = Rotation.neighbours(of: crop, at: cell, in: bed)
        let hasTray = garden.book.trays.contains { $0.crop == crop.key }
        return VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top, spacing: 12) {
                PlantGlyph(crop: crop, stage: .mature, growth: 1, size: 64)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Loam.soil.opacity(0.2)))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Staked for \(crop.plural.lowercased())").font(Loam.title(16)).foregroundColor(Loam.ink)
                    Text(verdict.text).font(Loam.body(12.5)).foregroundColor(Loam.inkSoft).fixedSize(horizontal: false, vertical: true)
                    Text("\(crop.perCell) to the square at \(crop.spacing) inches; \(crop.maturity.lowerBound) to \(crop.maturity.upperBound) days.")
                        .font(Loam.note(12)).foregroundColor(Loam.inkFaint).fixedSize(horizontal: false, vertical: true)
                }
            }
            HStack(spacing: 6) {
                StampTag(text: rotation == .clear ? "rotation clear" : (rotation == .bonus ? "legume before" : "rotation repeat"), tone: rotation == .clear || rotation == .bonus ? Loam.good : Loam.warn)
                if !report.companions.isEmpty { StampTag(text: "companion beside", tone: Loam.good) }
                if !report.antagonists.isEmpty { StampTag(text: "antagonist beside", tone: Loam.bad) }
            }
            HStack(spacing: 8) {
                if (verdict.kind == .startIndoors || (verdict.kind == .transplant && crop.indoors != nil)) && !hasTray {
                    SowButton(title: "Start indoors", tone: Loam.leafDeep, filled: false) { Tap.firm(); garden.startTray(crop.key); banner = BannerState(text: "A tray of \(crop.plural.lowercased()) is started. Drag it from the tray row onto this square when the window opens.", tone: 0, actionTitle: nil, actionCrop: nil) }
                }
                SowButton(title: "Unstake", tone: Loam.inkSoft, filled: false) { Tap.light(); garden.unstake(bedId, cell); selected = nil }
            }
        }
    }

    private var historyCard: some View {
        SheetCard {
            VStack(alignment: .leading, spacing: 8) {
                HeadRule(text: "This bed's rotation")
                if bed.history.isEmpty && bed.familiesThisSeason.isEmpty {
                    Text("No seasons recorded yet. Close a season from the Today tab after the first frost and the families that stood here are kept for the rotation check.")
                        .font(Loam.body(12.5)).foregroundColor(Loam.inkSoft).fixedSize(horizontal: false, vertical: true)
                }
                ForEach(Array(bed.history.enumerated()), id: \.offset) { i, fams in
                    HStack(alignment: .top, spacing: 8) {
                        Text("Season \(garden.book.seasonNumber - bed.history.count + i)").font(Loam.title(12)).foregroundColor(Loam.inkFaint).frame(width: 80, alignment: .leading)
                        Text(fams.isEmpty ? "rested" : fams.map { familyShort($0) }.joined(separator: ", ")).font(Loam.body(12.5)).foregroundColor(Loam.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                if !bed.familiesThisSeason.isEmpty {
                    HStack(alignment: .top, spacing: 8) {
                        Text("This season").font(Loam.title(12)).foregroundColor(Loam.leafDeep).frame(width: 80, alignment: .leading)
                        Text(bed.familiesThisSeason.map { familyShort($0) }.joined(separator: ", ")).font(Loam.body(12.5)).foregroundColor(Loam.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var sowableCrops: [Crop] {
        Register.crops.filter { crop in
            if let f = family, crop.family != f { return false }
            if showAll { return true }
            let v = Planner.verdict(for: crop, on: garden.today, dates: garden.dates)
            switch v.kind {
            case .direct, .fall, .transplant, .startIndoors: return true
            default: return false
            }
        }
    }

    private var tray: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Text(showAll ? "All crops" : "Sowable now").font(Loam.title(12)).foregroundColor(Loam.inkSoft)
                Button(action: { Tap.light(); withAnimation { showAll.toggle() } }) {
                    Text(showAll ? "show sowable" : "show all").font(Loam.body(11)).foregroundColor(Loam.terracotta)
                }
                .buttonStyle(.plain)
                Spacer()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        familyChip(nil, "Any")
                        ForEach(CropFamily.allCases, id: \.self) { f in familyChip(f, f.name) }
                    }
                }
            }
            .padding(.horizontal, Loam.gutter)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button(action: { Tap.light(); withAnimation { tool = tool == .water ? .none : .water }; selected = nil }) {
                        VStack(spacing: 3) {
                            CanGlyph(size: 30, color: tool == .water ? Loam.card : Loam.frostDeep)
                            Text("Water").font(Loam.body(10)).foregroundColor(tool == .water ? Loam.card : Loam.inkSoft)
                        }
                        .frame(width: 62, height: 66)
                        .background(RoundedRectangle(cornerRadius: 7).fill(tool == .water ? Loam.frostDeep : Loam.frost.opacity(0.25)))
                    }
                    .buttonStyle(.plain)
                    ForEach(garden.book.trays) { t in
                        chip(Register.find(t.crop), tray: t.id)
                    }
                    ForEach(sowableCrops) { crop in
                        chip(crop, tray: nil)
                    }
                }
                .padding(.horizontal, Loam.gutter)
                .padding(.bottom, 8)
            }
        }
        .padding(.top, 8)
        .background(Loam.card.overlay(Rectangle().fill(Loam.ink.opacity(0.1)).frame(height: 0.7), alignment: .top))
    }

    private func familyChip(_ f: CropFamily?, _ label: String) -> some View {
        let active = family == f
        return Button(action: { Tap.light(); withAnimation { family = f } }) {
            Text(label).font(Loam.body(10.5)).foregroundColor(active ? Loam.card : Loam.inkSoft)
                .padding(.horizontal, 7).padding(.vertical, 4)
                .background(Capsule().fill(active ? Loam.ink : Loam.ink.opacity(0.06)))
        }
        .buttonStyle(.plain)
    }

    private func chip(_ crop: Crop, tray: String?) -> some View {
        let verdict = Planner.verdict(for: crop, on: garden.today, dates: garden.dates)
        let dotTone: Color
        switch verdict.kind {
        case .direct, .fall: dotTone = Loam.good
        case .transplant: dotTone = tray != nil || crop.indoors == nil ? Loam.good : Loam.warn
        case .startIndoors: dotTone = Loam.warn
        default: dotTone = Loam.bad
        }
        return VStack(spacing: 2) {
            PlantGlyph(crop: crop, stage: tray != nil ? .sprout : .mature, growth: 0.7, size: 38, detail: false)
            Text(crop.name).font(Loam.body(9.5)).foregroundColor(Loam.ink).lineLimit(1).minimumScaleFactor(0.7)
            HStack(spacing: 3) {
                Circle().fill(dotTone).frame(width: 5, height: 5)
                Text(tray != nil ? "tray" : "\(crop.perCell)/sq").font(Loam.body(8.5)).foregroundColor(Loam.inkFaint)
            }
        }
        .frame(width: 66, height: 66)
        .background(RoundedRectangle(cornerRadius: 7).fill(tray != nil ? Loam.leafPale.opacity(0.35) : Loam.ink.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Loam.ink.opacity(0.12), lineWidth: 0.8))
        .opacity(drag?.crop == crop.key && drag?.tray == tray ? 0.4 : 1)
        .gesture(
            LongPressGesture(minimumDuration: 0.12)
                .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named("bed")))
                .onChanged { value in
                    switch value {
                    case .second(true, let dragValue):
                        if let d = dragValue {
                            if drag == nil { Tap.light() }
                            drag = ChipDrag(crop: crop.key, tray: tray, point: d.location)
                        }
                    default:
                        break
                    }
                }
                .onEnded { value in
                    if case .second(true, let dragValue) = value, let d = dragValue {
                        dropChip(ChipDrag(crop: crop.key, tray: tray, point: d.location))
                    }
                    drag = nil
                }
        )
    }
}

struct ChipGhost: View {
    var crop: Crop
    var tray: Bool
    var body: some View {
        VStack(spacing: 2) {
            PlantGlyph(crop: crop, stage: tray ? .sprout : .mature, growth: 0.7, size: 44, detail: true)
            Text(crop.name).font(Loam.title(10)).foregroundColor(Loam.ink)
        }
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 8).fill(Loam.card).shadow(color: Loam.ink.opacity(0.25), radius: 6, x: 0, y: 4))
        .offset(y: -44)
    }
}

struct BedGridCanvas: View {
    var bed: Bed
    var day: Int
    var selected: Int?
    var press: PressState?
    var covering: Int?
    var tool: BedTool
    var tick: Int
    var trouble: TroubleEvent? = nil
    var troubleSolved: Bool = false

    var body: some View {
        Canvas { ctx, size in
            let cw = size.width / CGFloat(bed.cols), ch = size.height / CGFloat(bed.rows)
            ctx.fill(Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 4), with: .color(Loam.soil))
            var grit = Furrow(hashOf(bed.id) ^ 0x99)
            for _ in 0..<Int(size.width * size.height / 70) {
                let x = CGFloat(grit.unit()) * size.width, y = CGFloat(grit.unit()) * size.height
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.6, height: 1.6)), with: .color(Color.black.opacity(0.14)))
            }
            for (i, cell) in bed.cells.enumerated() {
                let rect = CGRect(x: CGFloat(i % bed.cols) * cw, y: CGFloat(i / bed.cols) * ch, width: cw, height: ch)
                if cell.wateredDay == day {
                    ctx.fill(Path(rect), with: .color(Loam.soilDark.opacity(0.35)))
                }
                ctx.stroke(Path(rect), with: .color(Loam.strawPale.opacity(0.35)), lineWidth: 1)
                var lift: CGFloat = 0
                if let p = press, p.cell == i, p.mode == .pull {
                    lift = 30 * (1 - exp(-Double(p.pull) / 50))
                }
                if let planting = cell.planting {
                    let stage = planting.stage(on: day)
                    if stage == .mature {
                        ctx.fill(Path(roundedRect: rect.insetBy(dx: 3, dy: 3), cornerRadius: 4), with: .color(Loam.prize.opacity(0.18)))
                        ctx.stroke(Path(roundedRect: rect.insetBy(dx: 2, dy: 2), cornerRadius: 4), with: .color(Loam.prize.opacity(0.9)), lineWidth: 1.5)
                    }
                    if stage != .bare {
                        var painter = PlantPainter(ctx, crop: Register.find(planting.crop), stage: stage, growth: planting.growth(on: day),
                                                   rect: rect.insetBy(dx: cw * 0.08, dy: ch * 0.06).offsetBy(dx: 0, dy: -lift), detail: true,
                                                   seed: hashOf(bed.id + "\(i)"))
                        painter.draw()
                        if let ev = trouble, ev.cell == i, !troubleSolved {
                            var sym = SymptomPainter(ctx: ctx, symptom: Troubles.find(ev.trouble).symptom, rect: rect.insetBy(dx: cw * 0.08, dy: ch * 0.06).offsetBy(dx: 0, dy: -lift), time: 0.7, seed: hashOf(ev.trouble))
                            sym.draw()
                            ctx.stroke(Path(roundedRect: rect.insetBy(dx: 2, dy: 2), cornerRadius: 4), with: .color(Loam.terracotta.opacity(0.9)), style: StrokeStyle(lineWidth: 1.6, dash: [5, 4]))
                        }
                        if lift > 0 {
                            var roots = Path()
                            roots.move(to: CGPoint(x: rect.midX, y: rect.maxY - ch * 0.12 - lift))
                            roots.addLine(to: CGPoint(x: rect.midX - 6, y: rect.maxY - ch * 0.05))
                            roots.move(to: CGPoint(x: rect.midX, y: rect.maxY - ch * 0.12 - lift))
                            roots.addLine(to: CGPoint(x: rect.midX + 7, y: rect.maxY - ch * 0.04))
                            ctx.stroke(roots, with: .color(Loam.strawPale), lineWidth: 1.2)
                        }
                    }
                } else if let stake = cell.stake {
                    let crop = Register.find(stake)
                    var stakePath = Path()
                    stakePath.move(to: CGPoint(x: rect.minX + cw * 0.18, y: rect.maxY - ch * 0.12))
                    stakePath.addLine(to: CGPoint(x: rect.minX + cw * 0.18, y: rect.minY + ch * 0.16))
                    ctx.stroke(stakePath, with: .color(Loam.strawPale), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    ctx.fill(Path(roundedRect: CGRect(x: rect.minX + cw * 0.08, y: rect.minY + ch * 0.12, width: cw * 0.44, height: ch * 0.2), cornerRadius: 2), with: .color(Loam.strawPale))
                    let label = Text(crop.name).font(Loam.title(9)).foregroundColor(Loam.ink)
                    ctx.draw(label, in: CGRect(x: rect.minX + cw * 0.09, y: rect.minY + ch * 0.13, width: cw * 0.42, height: ch * 0.18))
                    var sub = ctx
                    sub.opacity = 0.35
                    var painter = PlantPainter(sub, crop: crop, stage: .leaf, growth: 0.5, rect: rect.insetBy(dx: cw * 0.2, dy: ch * 0.2).offsetBy(dx: cw * 0.1, dy: ch * 0.1), detail: false, seed: hashOf(stake))
                    painter.draw()
                }
                if let p = press, p.cell == i {
                    if p.mode == .drill {
                        var furrow = Path()
                        furrow.move(to: CGPoint(x: rect.minX + 6, y: rect.midY))
                        furrow.addLine(to: CGPoint(x: rect.maxX - 6, y: rect.midY))
                        ctx.stroke(furrow, with: .color(Loam.soilDark), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        ctx.stroke(Path(rect.insetBy(dx: 1, dy: 1)), with: .color(Loam.straw), lineWidth: 2)
                        for s in p.seeds {
                            ctx.fill(Path(ellipseIn: CGRect(x: s.x - 3, y: s.y - 2.2, width: 6, height: 4.4)), with: .color(Color(red: 0.86, green: 0.78, blue: 0.58)))
                            ctx.stroke(Path(ellipseIn: CGRect(x: s.x - 3, y: s.y - 2.2, width: 6, height: 4.4)), with: .color(Loam.ink.opacity(0.6)), lineWidth: 0.6)
                        }
                    } else if p.mode == .setOut {
                        let progress = min(1, Date().timeIntervalSince(p.start) / 1.1)
                        ctx.stroke(Path(rect.insetBy(dx: 1, dy: 1)), with: .color(Loam.straw), lineWidth: 2)
                        var arc = Path()
                        arc.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: min(cw, ch) * 0.3, startAngle: .degrees(-90), endAngle: .degrees(-90 + 360 * progress), clockwise: false)
                        ctx.stroke(arc, with: .color(Loam.leafPale), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    }
                }
                if covering == i {
                    ctx.fill(Path(rect), with: .color(Loam.soilLight.opacity(0.6)))
                }
                if selected == i {
                    ctx.stroke(Path(roundedRect: rect.insetBy(dx: 1.5, dy: 1.5), cornerRadius: 3), with: .color(Loam.card), lineWidth: 2)
                }
            }
            if tool == .water {
                ctx.stroke(Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 4), with: .color(Loam.frostDeep), lineWidth: 2)
            }
            ctx.stroke(Path(roundedRect: CGRect(origin: .zero, size: size).insetBy(dx: -3, dy: -3), cornerRadius: 5), with: .color(Loam.soilLight), lineWidth: 6)
            ctx.stroke(Path(roundedRect: CGRect(origin: .zero, size: size).insetBy(dx: -6, dy: -6), cornerRadius: 6), with: .color(Loam.ink.opacity(0.35)), lineWidth: 1)
        }
    }
}

struct HarvestOverlay: View {
    var entry: LarderEntry
    var onClose: () -> Void

    var body: some View {
        let crop = Register.find(entry.crop)
        let tone: Color = entry.quality == 2 ? Loam.prize : (entry.quality == 1 ? Loam.good : Loam.inkSoft)
        return ZStack {
            Loam.ink.opacity(0.55).ignoresSafeArea().onTapGesture { onClose() }
            VStack(spacing: 12) {
                HStack {
                    Spacer()
                    Button(action: { Tap.light(); onClose() }) { CrossGlyph(size: 14, color: Loam.inkSoft).padding(8).background(Circle().fill(Loam.ink.opacity(0.07))) }.buttonStyle(.plain)
                }
                PlateBox(name: crop.plate, height: Loam.isPad ? 300 : 220, fit: true)
                Text("\(crop.plural) to the larder").font(Loam.title(20)).foregroundColor(Loam.ink)
                StampTag(text: entry.qualityWord, tone: tone)
                Text(qualityText).font(Loam.body(13)).foregroundColor(Loam.inkSoft).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                SowButton(title: "Into the larder", tone: Loam.leafDeep) { onClose() }
            }
            .padding(18)
            .frame(maxWidth: 420)
            .background(RoundedRectangle(cornerRadius: 10).fill(Loam.card))
            .padding(Loam.gutter)
        }
    }

    private var qualityText: String {
        switch entry.quality {
        case 2: return "Pulled inside the window, rotation clear, a companion beside it and the spacing right. The best grade there is."
        case 1: return "A good pull. One of the window, the rotation, the neighbours or the spacing was off; the almanac page says which."
        default: return "Fair. Pulled outside the window or grown against the rotation; still food, but the larder keeps a better attempt if one comes."
        }
    }
}

struct RenameSheet: View {
    @Binding var name: String
    var onDone: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            SheetHead(title: "Rename the bed", subtitle: "Up to 18 characters", onClose: onDone)
            VStack(spacing: 14) {
                TextField("Bed name", text: $name)
                    .font(Loam.body(17))
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Loam.card).overlay(RoundedRectangle(cornerRadius: 6).stroke(Loam.ink.opacity(0.2))))
                SowButton(title: "Keep the name", tone: Loam.leafDeep) { onDone() }
            }
            .padding(.horizontal, Loam.gutter)
            Spacer()
        }
        .background(Loam.page.ignoresSafeArea())
    }
}
