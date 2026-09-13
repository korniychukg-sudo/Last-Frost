import SwiftUI

struct TrayDrag {
    var id: String
    var point: CGPoint
    var offset: CGSize
}

struct TrayLayout {
    var rects: [(String, CGRect)]
    var indoorWidth: CGFloat
    var stepRect: CGRect

    static func make(trays: [SeedTray], in size: CGSize) -> TrayLayout {
        let indoorW = size.width * 0.62
        let step = CGRect(x: indoorW + 8, y: size.height * 0.62, width: size.width - indoorW - 16, height: size.height * 0.3)
        var rects: [(String, CGRect)] = []
        let inside = trays.filter { !$0.hardening }
        let outside = trays.filter { $0.hardening }
        let perShelf = 3
        let trayW = min(90, (indoorW - 40) / CGFloat(perShelf) - 8)
        for (k, tray) in inside.prefix(6).enumerated() {
            let shelf = k / perShelf, col = k % perShelf
            let y = shelf == 0 ? size.height * 0.36 : size.height * 0.74
            let x = 26 + CGFloat(col) * (trayW + 8)
            rects.append((tray.id, CGRect(x: x, y: y - 26, width: trayW, height: 30)))
        }
        for (k, tray) in outside.prefix(3).enumerated() {
            let x = step.minX + 6 + CGFloat(k) * (min(trayW, (step.width - 12) / 3))
            rects.append((tray.id, CGRect(x: x, y: step.minY - 24, width: min(trayW, (step.width - 12) / 3) - 4, height: 30)))
        }
        return TrayLayout(rects: rects, indoorWidth: indoorW, stepRect: step)
    }
}

struct TrayShelfView: View {
    @EnvironmentObject var garden: FrostGarden
    @Environment(\.presentationMode) private var presentation
    @State private var selected: String? = nil
    @State private var drag: TrayDrag? = nil
    @State private var banner: String? = nil
    @State private var holdStart: Date? = nil
    @State private var holdProgress: Double = 0
    @State private var lifted = false
    @State private var carried: CGFloat = 0
    @State private var pickerOpen = false
    private let ticker = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    private var trays: [SeedTray] { garden.book.trays }

    private var stage: Int {
        if trays.contains(where: { $0.hardening }) { return 3 }
        if trays.contains(where: { $0.pricked }) { return 2 }
        if trays.contains(where: { $0.seedlingHeight(on: garden.today) >= 0.2 }) { return 1 }
        return 0
    }

    var body: some View {
        ZStack {
            Loam.page.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                ScrollView(showsIndicators: false) {
                    Column {
                        SheetCard(padding: 6) {
                            PlateBox(name: "ty_\(stage)", height: Loam.isPad ? 300 : 200)
                        }
                        .rising(0)
                        shelfCard.rising(1)
                        if let b = banner { NoticeBar(text: b, tone: Loam.good).transition(.opacity) }
                        if let id = selected, let tray = trays.first(where: { $0.id == id }) {
                            trayPanel(tray)
                        }
                        listCard.rising(2)
                        startCard.rising(3)
                    }
                    .padding(.horizontal, Loam.gutter)
                    .padding(.bottom, 28)
                }
            }
        }
        .navigationBarHidden(true)
        .onReceive(ticker) { _ in
            if let start = holdStart, !lifted {
                holdProgress = min(1, Date().timeIntervalSince(start) / 1.1)
                if holdProgress >= 1 { lifted = true; Tap.firm() }
            }
        }
        .sheet(isPresented: $pickerOpen) {
            TrayPickerSheet { pickerOpen = false }.environmentObject(garden)
        }
        .onAppear {
            if selected == nil { selected = trays.first?.id }
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Button(action: { Tap.light(); presentation.wrappedValue.dismiss() }) {
                HStack(spacing: 4) {
                    ChevGlyph(size: 15, color: Loam.inkSoft)
                    Text("Plot").font(Loam.body(14)).foregroundColor(Loam.inkSoft)
                }
            }
            .buttonStyle(.plain)
            Spacer()
            Text("Under the lamp").font(Loam.title(18)).foregroundColor(Loam.ink)
            Spacer()
            Text("\(trays.count) \(trays.count == 1 ? "tray" : "trays")").font(Loam.body(12)).foregroundColor(Loam.inkFaint)
        }
        .padding(.horizontal, Loam.gutter)
        .padding(.vertical, 10)
    }

    private var shelfCard: some View {
        SheetCard(padding: 0) {
            VStack(spacing: 0) {
                GeometryReader { geo in
                    let layout = TrayLayout.make(trays: trays, in: geo.size)
                    ZStack {
                        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
                            Canvas { ctx, size in
                                drawShelf(&ctx, size: size, layout: layout, time: timeline.date.timeIntervalSinceReferenceDate)
                            }
                        }
                        .contentShape(Rectangle())
                        .gesture(shelfGesture(layout: layout, size: geo.size))
                    }
                }
                .frame(height: Loam.isPad ? 360 : 290)
                .clipped()
                HStack {
                    Text(trays.isEmpty ? "No trays yet. Start one below, or stake a tomato in a bed and take the offer when it comes."
                            : "Tap a tray to open it. Drag a tray across to the doorstep to harden it off; drag it back to bring it in.")
                        .font(Loam.body(12)).foregroundColor(Loam.inkFaint).fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(12)
            }
        }
    }

    private func shelfGesture(layout: TrayLayout, size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                if drag == nil {
                    guard let hit = layout.rects.first(where: { $0.1.insetBy(dx: -8, dy: -16).contains(value.startLocation) }) else { return }
                    drag = TrayDrag(id: hit.0, point: value.location, offset: CGSize(width: value.startLocation.x - hit.1.midX, height: value.startLocation.y - hit.1.midY))
                    if hypot(value.translation.width, value.translation.height) > 8 { Tap.light() }
                } else {
                    drag?.point = value.location
                }
            }
            .onEnded { value in
                defer { drag = nil }
                guard let dr = drag else { return }
                let moved = hypot(value.translation.width, value.translation.height)
                if moved < 10 {
                    Tap.light()
                    withAnimation(.easeOut(duration: 0.2)) { selected = dr.id }
                    return
                }
                let tray = trays.first { $0.id == dr.id }
                let outdoors = value.location.x > layout.indoorWidth
                if outdoors, let t = tray, !t.hardening {
                    garden.harden(t.id)
                    Tap.hard()
                    withAnimation { banner = "\(Register.find(t.crop).plural) are out on the step. Seven days of daytime air; the plan brings them in at night." }
                } else if !outdoors, let t = tray, t.hardening {
                    garden.unharden(t.id)
                    Tap.firm()
                    withAnimation { banner = "\(Register.find(t.crop).plural) are back under the lamp." }
                }
                selected = dr.id
            }
    }

    private func drawShelf(_ ctx: inout GraphicsContext, size: CGSize, layout: TrayLayout, time: Double) {
        let w = size.width, h = size.height
        let iw = layout.indoorWidth
        ctx.fill(Path(CGRect(x: 0, y: 0, width: iw, height: h)), with: .color(Color(red: 0.90, green: 0.87, blue: 0.80)))
        var grain = Furrow(0x77A)
        for k in 0..<6 {
            let x = iw * CGFloat(k) / 6 + CGFloat(grain.unit()) * 10
            var line = Path()
            line.move(to: CGPoint(x: x, y: 0))
            line.addLine(to: CGPoint(x: x + 2, y: h))
            ctx.stroke(line, with: .color(Loam.woodDark.opacity(0.08)), lineWidth: 2)
        }
        let win = CGRect(x: 14, y: 14, width: iw * 0.42, height: h * 0.34)
        let sky = SkyLight.at(Almanac.hourNow())
        ctx.fill(Path(win), with: .linearGradient(Gradient(colors: [sky.top, sky.horizon]), startPoint: CGPoint(x: win.midX, y: win.minY), endPoint: CGPoint(x: win.midX, y: win.maxY)))
        ctx.stroke(Path(win), with: .color(Loam.card), lineWidth: 6)
        ctx.stroke(Path(win), with: .color(Loam.ink.opacity(0.6)), lineWidth: 1.2)
        var bars = Path()
        bars.move(to: CGPoint(x: win.midX, y: win.minY)); bars.addLine(to: CGPoint(x: win.midX, y: win.maxY))
        bars.move(to: CGPoint(x: win.minX, y: win.midY)); bars.addLine(to: CGPoint(x: win.maxX, y: win.midY))
        ctx.stroke(bars, with: .color(Loam.card), lineWidth: 4)
        for shelf in 0..<2 {
            let y = shelf == 0 ? h * 0.36 : h * 0.74
            let lampY = y - 78
            let flick = 0.9 + 0.1 * sin(time * 17 + Double(shelf)) * sin(time * 3.1)
            ctx.fill(Path(CGRect(x: 20, y: lampY + 8, width: iw - 40, height: 70)),
                     with: .linearGradient(Gradient(colors: [Color(red: 0.96, green: 0.62, blue: 0.86).opacity(0.36 * flick), Color.clear]), startPoint: CGPoint(x: 0, y: lampY + 8), endPoint: CGPoint(x: 0, y: lampY + 78)))
            ctx.fill(Path(roundedRect: CGRect(x: 24, y: lampY, width: iw - 48, height: 9), cornerRadius: 3), with: .color(Loam.ink.opacity(0.75)))
            ctx.fill(Path(CGRect(x: 30, y: lampY + 6, width: iw - 60, height: 3)), with: .color(Color(red: 1.0, green: 0.82, blue: 0.95).opacity(0.9 * flick)))
            var wires = Path()
            for wx in [iw * 0.25, iw * 0.75] {
                wires.move(to: CGPoint(x: wx, y: lampY))
                wires.addLine(to: CGPoint(x: wx, y: shelf == 0 ? 0 : y - 110))
            }
            ctx.stroke(wires, with: .color(Loam.ink.opacity(0.6)), lineWidth: 1.2)
            ctx.fill(Path(CGRect(x: 12, y: y, width: iw - 24, height: 10)), with: .color(Loam.soilLight))
            ctx.fill(Path(CGRect(x: 12, y: y + 10, width: iw - 24, height: 4)), with: .color(Loam.soilDark))
            ctx.fill(Path(CGRect(x: 12, y: y + 14, width: iw - 24, height: 8)), with: .color(Loam.ink.opacity(0.08)))
        }
        let outdoor = CGRect(x: iw, y: 0, width: w - iw, height: h)
        ctx.fill(Path(outdoor), with: .linearGradient(Gradient(colors: [sky.top, sky.horizon]), startPoint: CGPoint(x: outdoor.midX, y: 0), endPoint: CGPoint(x: outdoor.midX, y: h * 0.6)))
        ctx.fill(Path(CGRect(x: iw, y: h * 0.5, width: w - iw, height: h * 0.5)), with: .color(Color.blend(Color(red: 0.08, green: 0.09, blue: 0.14), Color(red: 0.50, green: 0.60, blue: 0.34), 0.25 + sky.light * 0.75)))
        let step = layout.stepRect
        ctx.fill(Path(step), with: .color(Color(red: 0.72, green: 0.70, blue: 0.64)))
        ctx.fill(Path(CGRect(x: step.minX, y: step.maxY - 8, width: step.width, height: 8)), with: .color(Color(red: 0.50, green: 0.48, blue: 0.42)))
        ctx.stroke(Path(step), with: .color(Loam.ink.opacity(0.5)), lineWidth: 1)
        ctx.fill(Path(CGRect(x: iw - 3, y: 0, width: 6, height: h)), with: .color(Loam.woodDark))
        ctx.draw(Text("the doorstep").font(Loam.note(10)).foregroundColor(Loam.ink.opacity(0.7)), at: CGPoint(x: step.midX, y: step.minY + step.height * 0.55))
        if trays.contains(where: { $0.hardening }) == false {
            ctx.draw(Text("drag a tray here").font(Loam.note(9.5)).foregroundColor(Loam.ink.opacity(0.5)), at: CGPoint(x: step.midX, y: step.minY - 12))
        }
        for (id, rect) in layout.rects {
            guard let tray = trays.first(where: { $0.id == id }) else { continue }
            var r = rect
            var alpha = 1.0
            if let d = drag, d.id == id {
                r = CGRect(x: d.point.x - d.offset.width - rect.width / 2, y: d.point.y - d.offset.height - rect.height / 2 - 12, width: rect.width, height: rect.height)
                alpha = 0.92
            }
            var sub = ctx
            sub.opacity = alpha
            drawTray(&sub, tray: tray, rect: r, selected: selected == id, time: time)
        }
    }

    private func drawTray(_ ctx: inout GraphicsContext, tray: SeedTray, rect: CGRect, selected: Bool, time: Double) {
        let crop = Register.find(tray.crop)
        let growth = tray.seedlingHeight(on: garden.today)
        ctx.fill(Path(CGRect(x: rect.minX + 4, y: rect.maxY + 2, width: rect.width - 4, height: 5)), with: .color(Color.black.opacity(0.18)))
        ctx.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(Color(red: 0.26, green: 0.26, blue: 0.28)))
        ctx.fill(Path(CGRect(x: rect.minX + 3, y: rect.minY + 3, width: rect.width - 6, height: rect.height * 0.45)), with: .color(Loam.soilDark))
        let cells = tray.pricked ? 4 : 7
        let cw = (rect.width - 6) / CGFloat(cells)
        for k in 0..<cells {
            let cx = rect.minX + 3 + cw * (CGFloat(k) + 0.5)
            if tray.pricked {
                ctx.stroke(Path(CGRect(x: rect.minX + 3 + cw * CGFloat(k), y: rect.minY + 3, width: cw, height: rect.height * 0.45)), with: .color(Loam.ink.opacity(0.35)), lineWidth: 0.7)
            }
            let hgt = CGFloat(growth) * (tray.pricked ? 34 : 24) + 3
            let sway = CGFloat(sin(time * 1.4 + Double(k) * 0.8)) * 1.2
            var stem = Path()
            stem.move(to: CGPoint(x: cx, y: rect.minY + 6))
            stem.addQuadCurve(to: CGPoint(x: cx + sway, y: rect.minY + 6 - hgt), control: CGPoint(x: cx + sway * 0.5, y: rect.minY + 6 - hgt * 0.5))
            ctx.stroke(stem, with: .color(PlantPalette.leafPale), lineWidth: 1.4)
            if growth > 0.12 {
                let tip = CGPoint(x: cx + sway, y: rect.minY + 6 - hgt)
                let s = 2.4 + CGFloat(growth) * 3
                ctx.fill(Path(ellipseIn: CGRect(x: tip.x - s * 1.6, y: tip.y - s * 0.5, width: s * 1.5, height: s)), with: .color(PlantPalette.tones(for: crop).leaf))
                ctx.fill(Path(ellipseIn: CGRect(x: tip.x + s * 0.1, y: tip.y - s * 0.5, width: s * 1.5, height: s)), with: .color(PlantPalette.tones(for: crop).leaf))
                if growth > 0.5 {
                    ctx.fill(Path(ellipseIn: CGRect(x: tip.x - s * 0.5, y: tip.y - s * 1.6, width: s, height: s * 1.3)), with: .color(PlantPalette.tones(for: crop).leafDeep))
                }
            }
        }
        ctx.fill(Path(CGRect(x: rect.minX + 5, y: rect.minY - 10, width: 4, height: 16)), with: .color(Loam.card))
        ctx.stroke(Path(CGRect(x: rect.minX + 5, y: rect.minY - 10, width: 4, height: 16)), with: .color(Loam.ink.opacity(0.5)), lineWidth: 0.6)
        ctx.draw(Text(crop.name).font(Loam.body(8)).foregroundColor(Loam.ink), at: CGPoint(x: rect.midX, y: rect.maxY + 12))
        if tray.hardening {
            ctx.draw(Text("day \(tray.hardenDaysDone(on: garden.today)) of 7").font(Loam.note(7.5)).foregroundColor(Loam.ink.opacity(0.8)), at: CGPoint(x: rect.midX, y: rect.maxY + 22))
        }
        if selected {
            ctx.stroke(Path(roundedRect: rect.insetBy(dx: -3, dy: -3), cornerRadius: 3), with: .color(Loam.terracotta), lineWidth: 1.5)
        }
    }

    private func trayPanel(_ tray: SeedTray) -> some View {
        let crop = Register.find(tray.crop)
        let fy = garden.frostYear
        let window = Planner.transplantWindow(crop, fy)
        let verdict = Planner.verdict(for: crop, on: garden.today, dates: garden.dates)
        let canOut = verdict.kind == .transplant || verdict.kind == .direct || verdict.kind == .fall
        return SheetCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    HeadRule(text: crop.plural)
                    Button(action: { Tap.light(); withAnimation { selected = nil } }) { CrossGlyph(size: 12, color: Loam.inkFaint) }.buttonStyle(.plain)
                }
                HStack(alignment: .top, spacing: 12) {
                    PlantGlyph(crop: crop, stage: tray.seedlingHeight(on: garden.today) < 0.35 ? .sprout : .leaf, growth: tray.seedlingHeight(on: garden.today), size: 60)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Loam.soil.opacity(0.18)))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(stateText(tray)).font(Loam.body(13)).foregroundColor(Loam.inkSoft).fixedSize(horizontal: false, vertical: true)
                        if let w = window {
                            StampTag(text: canOut ? "can go out" : (garden.today < w.start ? "out \(Almanac.relative(w.start, to: garden.today))" : "past the window"), tone: canOut ? Loam.good : Loam.frostDeep)
                        }
                    }
                }
                MeterBar(label: "Seedling growth", value: tray.seedlingHeight(on: garden.today), tone: Loam.leaf,
                         caption: tray.pricked ? "Pricked out into cells on \(Almanac.label(tray.prickedDay ?? garden.today))." : (tray.canPrick(on: garden.today) ? "First true leaves are showing; prick them out below." : "Wait for the first true leaf before pricking out."))
                if tray.canPrick(on: garden.today) {
                    VStack(alignment: .leading, spacing: 6) {
                        NoticeBar(text: "Pricking out: press and hold a seedling until it lifts, then drag it right into the cell tray. Hold by the leaf, never the stem.", tone: Loam.terracotta)
                        PrickOutStage(crop: crop, holdProgress: holdProgress, lifted: lifted, carried: carried)
                            .frame(height: 120)
                            .gesture(prickGesture(tray))
                    }
                }
                HStack(spacing: 8) {
                    if tray.hardening {
                        SowButton(title: "Bring it in", tone: Loam.frostDeep, filled: false) { garden.unharden(tray.id); Tap.firm() }
                    } else {
                        SowButton(title: "Harden off", tone: Loam.leafDeep, filled: false) { garden.harden(tray.id); Tap.firm(); withAnimation { banner = "\(crop.plural) are out on the step for the day." } }
                    }
                    SowButton(title: "Discard", tone: Loam.bad, filled: false) { Tap.light(); garden.discardTray(tray.id); selected = nil }
                }
                if canOut {
                    Text("The window is open: go to the bed and drag the \(crop.name.lowercased()) tray chip onto a staked square to set them out.")
                        .font(Loam.note(12)).foregroundColor(Loam.inkFaint).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func prickGesture(_ tray: SeedTray) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if holdStart == nil { holdStart = Date(); holdProgress = 0; lifted = false; carried = 0 }
                if lifted { carried = max(0, value.translation.width) }
            }
            .onEnded { value in
                let ok = lifted && value.translation.width > 90
                holdStart = nil
                if ok {
                    garden.prickOut(tray.id)
                    Tap.hard()
                    withAnimation { banner = "\(Register.find(tray.crop).plural) pricked out, one to a cell. They grow faster with their own root run." }
                } else if lifted {
                    Tap.crisp()
                }
                withAnimation(.easeOut(duration: 0.2)) { lifted = false; holdProgress = 0; carried = 0 }
            }
    }

    private func stateText(_ tray: SeedTray) -> String {
        let crop = Register.find(tray.crop)
        var parts = ["Sown \(Almanac.label(tray.sowDay)), day \(max(0, garden.today - tray.sowDay))"]
        if tray.pricked { parts.append("pricked out") }
        if tray.hardening { parts.append("hardening off, day \(tray.hardenDaysDone(on: garden.today)) of 7") }
        if let i = crop.indoors { parts.append("indoors \(Planner.weeksText(i, before: true)) the last frost") }
        return parts.joined(separator: "; ") + "."
    }

    private var listCard: some View {
        SheetCard {
            VStack(alignment: .leading, spacing: 10) {
                HeadRule(text: "On the shelves", trailing: trays.isEmpty ? nil : "\(trays.filter { $0.hardening }.count) on the step")
                if trays.isEmpty {
                    Text("Crops that start indoors live here from sowing to setting out: sown, sprouted, pricked out into cells, hardened off on the step, and then out to a square in the plot.")
                        .font(Loam.body(13)).foregroundColor(Loam.inkSoft).fixedSize(horizontal: false, vertical: true)
                }
                ForEach(trays) { tray in
                    Button(action: { Tap.light(); withAnimation { selected = tray.id } }) {
                        HStack(spacing: 12) {
                            PlantGlyph(crop: Register.find(tray.crop), stage: tray.seedlingHeight(on: garden.today) < 0.35 ? .sprout : .leaf, growth: tray.seedlingHeight(on: garden.today), size: 40)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Loam.soil.opacity(0.18)))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(Register.find(tray.crop).plural).font(Loam.title(14)).foregroundColor(Loam.ink)
                                Text(tray.hardening ? "on the doorstep, day \(tray.hardenDaysDone(on: garden.today)) of 7" : (tray.pricked ? "in cells under the lamp" : "in the seed tray, day \(max(0, garden.today - tray.sowDay))"))
                                    .font(Loam.body(12)).foregroundColor(Loam.inkFaint)
                            }
                            Spacer()
                            if selected == tray.id { StampTag(text: "open", tone: Loam.terracotta) }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var startCard: some View {
        SheetCard {
            VStack(alignment: .leading, spacing: 10) {
                HeadRule(text: "Start a tray")
                Text("Any crop with an indoor start can be sown into a tray now. The plan will tell you when it is time to harden off and set out, counted from your frost dates.")
                    .font(Loam.body(13)).foregroundColor(Loam.inkSoft).fixedSize(horizontal: false, vertical: true)
                SowButton(title: "Choose a crop to sow indoors", tone: Loam.leafDeep) { pickerOpen = true }
            }
        }
    }
}

struct PrickOutStage: View {
    var crop: Crop
    var holdProgress: Double
    var lifted: Bool
    var carried: CGFloat

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            ctx.fill(Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 6), with: .color(Loam.page))
            let trayRect = CGRect(x: 12, y: h * 0.45, width: w * 0.38, height: h * 0.4)
            ctx.fill(Path(roundedRect: trayRect, cornerRadius: 3), with: .color(Color(red: 0.26, green: 0.26, blue: 0.28)))
            ctx.fill(Path(trayRect.insetBy(dx: 4, dy: 4)), with: .color(Loam.soilDark))
            let cellRect = CGRect(x: w * 0.56, y: h * 0.45, width: w * 0.4, height: h * 0.4)
            ctx.fill(Path(roundedRect: cellRect, cornerRadius: 3), with: .color(Color(red: 0.26, green: 0.26, blue: 0.28)))
            for k in 0..<4 {
                let cw = (cellRect.width - 8) / 4
                let cr = CGRect(x: cellRect.minX + 4 + cw * CGFloat(k), y: cellRect.minY + 4, width: cw, height: cellRect.height - 8)
                ctx.fill(Path(cr.insetBy(dx: 1, dy: 1)), with: .color(Loam.soilDark))
                ctx.stroke(Path(cr), with: .color(Loam.ink.opacity(0.4)), lineWidth: 0.8)
            }
            for k in 0..<6 where k != 2 {
                let x = trayRect.minX + 10 + CGFloat(k) * (trayRect.width - 20) / 5
                var stem = Path()
                stem.move(to: CGPoint(x: x, y: trayRect.minY + 4))
                stem.addLine(to: CGPoint(x: x, y: trayRect.minY - 18))
                ctx.stroke(stem, with: .color(PlantPalette.leafPale), lineWidth: 1.4)
                ctx.fill(Path(ellipseIn: CGRect(x: x - 6, y: trayRect.minY - 22, width: 5, height: 3.5)), with: .color(PlantPalette.tones(for: crop).leaf))
                ctx.fill(Path(ellipseIn: CGRect(x: x + 1, y: trayRect.minY - 22, width: 5, height: 3.5)), with: .color(PlantPalette.tones(for: crop).leaf))
            }
            let baseX = trayRect.minX + 10 + 2 * (trayRect.width - 20) / 5
            let liftY = CGFloat(holdProgress) * 26
            let px = baseX + carried, py = trayRect.minY + 4 - liftY
            if !lifted {
                var ring = Path()
                ring.addArc(center: CGPoint(x: baseX, y: trayRect.minY - 14), radius: 16, startAngle: .degrees(-90), endAngle: .degrees(-90 + 360 * holdProgress), clockwise: false)
                ctx.stroke(ring, with: .color(Loam.terracotta), style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
            var stem = Path()
            stem.move(to: CGPoint(x: px, y: py))
            stem.addLine(to: CGPoint(x: px, y: py - 22))
            ctx.stroke(stem, with: .color(PlantPalette.leafPale), lineWidth: 1.8)
            ctx.fill(Path(ellipseIn: CGRect(x: px - 8, y: py - 27, width: 7, height: 5)), with: .color(PlantPalette.tones(for: crop).leaf))
            ctx.fill(Path(ellipseIn: CGRect(x: px + 1, y: py - 27, width: 7, height: 5)), with: .color(PlantPalette.tones(for: crop).leaf))
            ctx.fill(Path(ellipseIn: CGRect(x: px - 3, y: py - 34, width: 6, height: 7)), with: .color(PlantPalette.tones(for: crop).leafDeep))
            if lifted {
                var roots = Path()
                for k in 0..<3 {
                    roots.move(to: CGPoint(x: px, y: py))
                    roots.addLine(to: CGPoint(x: px + CGFloat(k - 1) * 4, y: py + 9))
                }
                ctx.stroke(roots, with: .color(Loam.strawPale), lineWidth: 1)
            }
            ctx.draw(Text(lifted ? "drag right into a cell" : "hold to lift").font(Loam.note(10)).foregroundColor(Loam.inkFaint), at: CGPoint(x: w * 0.5, y: h * 0.18))
            var arrow = Path()
            arrow.move(to: CGPoint(x: w * 0.52, y: h * 0.62)); arrow.addLine(to: CGPoint(x: w * 0.55, y: h * 0.62))
            ctx.stroke(arrow, with: .color(Loam.inkFaint), lineWidth: 1)
        }
    }
}

struct TrayPickerSheet: View {
    @EnvironmentObject var garden: FrostGarden
    var onClose: () -> Void
    @State private var query = ""

    private var crops: [Crop] {
        Register.crops.filter { crop in crop.indoors != nil && !garden.book.trays.contains(where: { t in t.crop == crop.key }) }
            .filter { query.isEmpty || $0.name.lowercased().contains(query.lowercased()) }
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetHead(title: "Sow indoors", subtitle: "Crops with an indoor start", onClose: onClose)
            ScrollView {
                Column {
                    HStack(spacing: 8) {
                        TextField("Search a crop", text: $query).font(Loam.body(15)).disableAutocorrection(true)
                        if !query.isEmpty {
                            Button(action: { Tap.light(); query = "" }) { CrossGlyph(size: 12, color: Loam.inkFaint) }.buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Loam.card).overlay(RoundedRectangle(cornerRadius: 6).stroke(Loam.ink.opacity(0.15))))
                    SheetCard {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(crops) { crop in
                                let v = Planner.verdict(for: crop, on: garden.today, dates: garden.dates)
                                Button(action: {
                                    Tap.firm()
                                    garden.startTray(crop.key)
                                    onClose()
                                }) {
                                    HStack(spacing: 12) {
                                        PlantGlyph(crop: crop, stage: .sprout, growth: 0.5, size: 36)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(crop.plural).font(Loam.title(14)).foregroundColor(Loam.ink)
                                            Text(v.kind == .startIndoors ? "In the indoor window now" : (v.kind == .transplant ? "Planting-out window is open; a tray now is a late start" : "Outside the window; it will wait under the lamp"))
                                                .font(Loam.body(11.5)).foregroundColor(Loam.inkFaint).fixedSize(horizontal: false, vertical: true)
                                        }
                                        Spacer()
                                        Circle().fill(v.kind == .startIndoors ? Loam.good : (v.kind == .transplant ? Loam.warn : Loam.inkFaint)).frame(width: 7, height: 7)
                                    }
                                    .padding(.vertical, 4)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                Rectangle().fill(Loam.ink.opacity(0.07)).frame(height: 0.7)
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
}
