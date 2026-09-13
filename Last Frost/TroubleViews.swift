import SwiftUI

func kindTone(_ kind: TroubleKind) -> Color {
    switch kind {
    case .pest: return Loam.terracotta
    case .disease: return Loam.bad
    case .disorder: return Loam.frostDeep
    }
}

struct TroublesSection: View {
    @EnvironmentObject var garden: FrostGarden
    @State private var kind: Int = 0
    @State private var openTrouble: String? = nil

    private var list: [Trouble] {
        let month = Almanac.parts(of: garden.today).month
        switch kind {
        case 1: return Troubles.all.filter { $0.kind == .pest }
        case 2: return Troubles.all.filter { $0.kind == .disease }
        case 3: return Troubles.all.filter { $0.kind == .disorder }
        case 4: return Troubles.all.filter { $0.inSeason(month: month) }
        default: return Troubles.all
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            BandPicker(titles: ["All", "Pests", "Diseases", "Disorders", "This month"], index: $kind)
            SheetCard {
                VStack(alignment: .leading, spacing: 8) {
                    HeadRule(text: "The register of troubles", trailing: "\(Troubles.all.count)")
                    Text("Twenty-four things that go wrong in a vegetable bed, each drawn as you would find it: the holed leaf, the clubbed root, the sunken patch on the fruit. What it is, which crops it takes, when in the season, what to do and what would have prevented it. The plot puts one in a bed most days; the page tells you how to read it.")
                        .font(Loam.body(13)).foregroundColor(Loam.inkSoft).fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 9) {
                        CountTile(value: "\(Troubles.all.filter { $0.kind == .pest }.count)", label: "pests", tone: Loam.terracotta)
                        CountTile(value: "\(Troubles.all.filter { $0.kind == .disease }.count)", label: "diseases", tone: Loam.bad)
                        CountTile(value: "\(Troubles.all.filter { $0.kind == .disorder }.count)", label: "disorders", tone: Loam.frostDeep)
                        CountTile(value: "\((garden.book.troublesSeen ?? []).count)", label: "met", tone: Loam.leafDeep)
                    }
                }
            }
            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: Loam.isPad ? 3 : 2)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(list) { t in
                    Button(action: { Tap.light(); openTrouble = t.key }) {
                        TroubleCard(trouble: t, met: (garden.book.troublesSeen ?? []).contains(t.key))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .background(
            Group {
                ForEach(Troubles.all) { t in
                    NavigationLink(destination: TroubleDetailView(trouble: t).environmentObject(garden), tag: t.key, selection: $openTrouble) { EmptyView() }
                }
            }
            .hidden()
        )
    }
}

struct TroubleCard: View {
    var trouble: Trouble
    var met: Bool

    var body: some View {
        SheetCard(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                ThumbBox(name: trouble.plate, height: Loam.isPad ? 200 : 150, corner: 0, side: 320)
                VStack(alignment: .leading, spacing: 4) {
                    Text(trouble.name).font(Loam.title(15)).foregroundColor(Loam.ink).lineLimit(1).minimumScaleFactor(0.8)
                    Text("\(trouble.kind.name) · \(trouble.season)").font(Loam.body(11)).foregroundColor(Loam.inkFaint).lineLimit(1).minimumScaleFactor(0.8)
                    HStack(spacing: 5) {
                        Circle().fill(kindTone(trouble.kind)).frame(width: 6, height: 6)
                        Text(trouble.remedy.title).font(Loam.note(10.5)).foregroundColor(Loam.inkSoft).lineLimit(1)
                        Spacer()
                        if met { StampTag(text: "met", tone: Loam.good) }
                    }
                }
                .padding(10)
            }
        }
    }
}

struct TroubleDetailView: View {
    @EnvironmentObject var garden: FrostGarden
    var trouble: Trouble

    var body: some View {
        let month = Almanac.parts(of: garden.today).month
        return ScrollView {
            Column {
                SheetCard(padding: 6) {
                    PlateBox(name: trouble.plate, height: Loam.isPad ? 560 : 420, fit: true)
                }
                .rising(0)
                SheetCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(trouble.name).font(Loam.title(24)).foregroundColor(Loam.ink)
                            Spacer()
                            SmallChip(text: trouble.kind.name, tone: kindTone(trouble.kind))
                        }
                        Text(trouble.kind.meaning).font(Loam.note(13)).foregroundColor(Loam.inkFaint).fixedSize(horizontal: false, vertical: true)
                        NoticeBar(text: trouble.inSeason(month: month) ? "In season now: \(trouble.season). Watch for \(trouble.symptomWords)." : "Out of season; it belongs to \(trouble.season).",
                                  tone: trouble.inSeason(month: month) ? Loam.warn : Loam.frostDeep)
                        MonthStrip(trouble: trouble, month: month)
                    }
                }
                .rising(1)
                SheetCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HeadRule(text: "What you see")
                        Text(trouble.signs).font(Loam.body(14)).foregroundColor(Loam.inkSoft).fixedSize(horizontal: false, vertical: true)
                        HeadRule(text: "What to do", trailing: trouble.remedy.title)
                        Text(trouble.action).font(Loam.body(14)).foregroundColor(Loam.inkSoft).fixedSize(horizontal: false, vertical: true)
                        HeadRule(text: "What prevents it")
                        Text(trouble.prevention).font(Loam.note(14)).foregroundColor(Loam.inkSoft).fixedSize(horizontal: false, vertical: true)
                    }
                }
                .rising(2)
                SheetCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HeadRule(text: "Crops it takes", trailing: "\(trouble.crops.count)")
                        FlowCrops(keys: trouble.crops).environmentObject(garden)
                    }
                }
                .rising(3)
                if (garden.book.troublesSeen ?? []).contains(trouble.key) {
                    SheetCard {
                        VStack(alignment: .leading, spacing: 6) {
                            HeadRule(text: "In your plot", trailing: "met")
                            Text("You have found this one in a bed and put it right. It stays in the register; it will come again in its season.")
                                .font(Loam.body(13)).foregroundColor(Loam.inkSoft).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .rising(4)
                }
            }
            .padding(.horizontal, Loam.gutter)
            .padding(.bottom, 28)
        }
        .background(Loam.page.ignoresSafeArea())
        .navigationBarTitle(Text(trouble.name), displayMode: .inline)
    }
}

struct MonthStrip: View {
    var trouble: Trouble
    var month: Int
    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...12, id: \.self) { m in
                let on = trouble.inSeason(month: m)
                VStack(spacing: 2) {
                    Rectangle().fill(on ? kindTone(trouble.kind) : Loam.ink.opacity(0.10)).frame(height: 6)
                    Text(String(Almanac.monthShort[m - 1].prefix(1))).font(Loam.body(8.5)).foregroundColor(m == month ? Loam.ink : Loam.inkFaint)
                }
                .overlay(m == month ? Rectangle().stroke(Loam.ink.opacity(0.5), lineWidth: 0.8).padding(-2) : nil)
            }
        }
    }
}

struct FlowCrops: View {
    @EnvironmentObject var garden: FrostGarden
    var keys: [String]
    var body: some View {
        let rows = stride(from: 0, to: keys.count, by: Loam.isPad ? 4 : 3).map { Array(keys[$0..<min(keys.count, $0 + (Loam.isPad ? 4 : 3))]) }
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { key in
                        let crop = Register.find(key)
                        NavigationLink(destination: CropDetailView(crop: crop).environmentObject(garden)) {
                            HStack(spacing: 6) {
                                PlantGlyph(crop: crop, stage: .mature, growth: 1, size: 26, detail: false)
                                Text(crop.name).font(Loam.body(12)).foregroundColor(Loam.ink).lineLimit(1).minimumScaleFactor(0.8)
                            }
                            .padding(.horizontal, 8).padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Loam.ink.opacity(0.05)))
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

struct SayingsSection: View {
    @EnvironmentObject var garden: FrostGarden
    @State private var open: String? = nil

    var body: some View {
        let thisMonth = Almanac.parts(of: garden.today).month
        return VStack(spacing: 12) {
            SheetCard {
                VStack(alignment: .leading, spacing: 8) {
                    HeadRule(text: "The year's sayings", trailing: "\(Sayings.all.count)")
                    Text("Thirty-six things the old gardeners said, three to a month, each weighed against the frost dates and the thermometer: some are true anywhere, some are true for one zone and a calendar for the rest, and some are simply poetry. Tap one to read the verdict.")
                        .font(Loam.body(13)).foregroundColor(Loam.inkSoft).fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 9) {
                        CountTile(value: "\((garden.book.sayingsRead ?? []).count)", label: "weighed", tone: Loam.leafDeep)
                        CountTile(value: "\(Sayings.all.filter { $0.verdict == .truth }.count)", label: "truths", tone: Loam.good)
                        CountTile(value: "\(Sayings.all.filter { $0.verdict == .half }.count)", label: "half-truths", tone: Loam.warn)
                        CountTile(value: "\(Sayings.all.filter { $0.verdict == .myth }.count)", label: "myths", tone: Loam.bad)
                    }
                }
            }
            ForEach(1...12, id: \.self) { m in
                let month = ((thisMonth - 1 + m - 1) % 12) + 1
                SheetCard(padding: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        ZStack(alignment: .bottomLeading) {
                            PlateBox(name: Sayings.plate(month), height: Loam.isPad ? 200 : 132, corner: 0)
                            Text(Almanac.monthNames[month - 1]).font(Loam.title(18)).foregroundColor(Loam.card)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Loam.ink.opacity(0.55))
                                .padding(10)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Sayings.forMonth(month)) { saying in
                                SayingRow(saying: saying, expanded: open == saying.id, read: garden.sayingRead(saying.id)) {
                                    Tap.light()
                                    withAnimation(.easeOut(duration: 0.2)) { open = open == saying.id ? nil : saying.id }
                                    garden.readSaying(saying.id)
                                }
                            }
                        }
                        .padding(12)
                    }
                }
            }
        }
    }
}

struct SayingRow: View {
    var saying: Saying
    var expanded: Bool
    var read: Bool
    var onTap: () -> Void

    var body: some View {
        let tone: Color = saying.verdict == .truth ? Loam.good : (saying.verdict == .half ? Loam.warn : Loam.bad)
        return Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 8) {
                    Text(saying.text).font(Loam.note(14)).foregroundColor(Loam.ink).fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 4)
                    if read || expanded {
                        StampTag(text: saying.verdict.name, tone: tone)
                    } else {
                        ChevGlyph(size: 12, color: Loam.inkFaint, back: false).padding(.top, 4)
                    }
                }
                if expanded {
                    Text(saying.note).font(Loam.body(12.5)).foregroundColor(Loam.inkSoft).fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                }
                Rectangle().fill(Loam.ink.opacity(0.07)).frame(height: 0.7)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

enum RemedyPhase { case identify, remedy, done }

struct TroubleSheet: View {
    @EnvironmentObject var garden: FrostGarden
    var event: TroubleEvent
    var bedName: String
    var onClose: () -> Void
    @State private var picked: String? = nil
    @State private var phase: RemedyPhase = .identify
    @State private var progress: Double = 0

    private var trouble: Trouble { Troubles.find(event.trouble) }
    private var crop: Crop { Register.find(event.crop) }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                SheetHead(title: phase == .done ? "Put right" : (phase == .remedy ? trouble.remedy.title : "Name the trouble"),
                          subtitle: "\(bedName), square \(event.cell + 1): the \(crop.plural.lowercased())", onClose: onClose)
                ScrollView {
                    Column {
                        switch phase {
                        case .identify: identify
                        case .remedy: remedy
                        case .done: done
                        }
                    }
                    .padding(.horizontal, Loam.gutter)
                    .padding(.bottom, 24)
                }
            }
            .background(Loam.page.ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            if garden.troubleSolved(event.id) { phase = .done }
        }
    }

    private var identify: some View {
        VStack(spacing: 12) {
            SheetCard {
                VStack(alignment: .leading, spacing: 8) {
                    HeadRule(text: "What you see")
                    HStack(alignment: .top, spacing: 12) {
                        SymptomGlyph(crop: crop, symptom: trouble.symptom, size: 72)
                        Text("The \(crop.plural.lowercased()) show \(trouble.symptomWords). It is \(Almanac.monthNames[Almanac.parts(of: event.day).month - 1]). Which of these three is it?")
                            .font(Loam.body(13.5)).foregroundColor(Loam.inkSoft).fixedSize(horizontal: false, vertical: true)
                    }
                    if let p = picked, p != trouble.key {
                        NoticeBar(text: "Not \(Troubles.find(p).name.lowercased()): that shows as \(Troubles.find(p).symptomWords). Look again.", tone: Loam.warn)
                    }
                }
            }
            ForEach(event.candidates, id: \.self) { key in
                let t = Troubles.find(key)
                Button(action: { choose(key) }) {
                    SheetCard(padding: 0) {
                        HStack(spacing: 0) {
                            ThumbBox(name: t.plate, height: 96, corner: 0, side: 300).frame(width: 118)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(t.name).font(Loam.title(15)).foregroundColor(Loam.ink)
                                Text("\(t.kind.name) of \(t.cropNames)").font(Loam.body(11.5)).foregroundColor(Loam.inkFaint).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                                Text(t.season).font(Loam.note(11)).foregroundColor(Loam.inkFaint)
                            }
                            .padding(10)
                            Spacer(minLength: 0)
                            if picked == key { StampTag(text: key == trouble.key ? "yes" : "no", tone: key == trouble.key ? Loam.good : Loam.bad).padding(.trailing, 10) }
                        }
                    }
                }
                .buttonStyle(.plain)
                .opacity(picked != nil && picked != key && picked != trouble.key ? 0.6 : 1)
            }
        }
    }

    private func choose(_ key: String) {
        withAnimation(.easeOut(duration: 0.2)) { picked = key }
        if key == trouble.key {
            Tap.firm()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                withAnimation(.easeInOut(duration: 0.25)) { phase = .remedy }
            }
        } else {
            Tap.crisp()
            garden.missTrouble(event.id)
        }
    }

    private var remedy: some View {
        VStack(spacing: 12) {
            SheetCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(trouble.name).font(Loam.title(18)).foregroundColor(Loam.ink)
                        Spacer()
                        SmallChip(text: trouble.kind.name, tone: kindTone(trouble.kind))
                    }
                    Text(trouble.action).font(Loam.body(13)).foregroundColor(Loam.inkSoft).fixedSize(horizontal: false, vertical: true)
                    NoticeBar(text: trouble.remedy.instruction, tone: Loam.terracotta)
                }
            }
            SheetCard(padding: 8) {
                VStack(spacing: 8) {
                    RemedyStage(crop: crop, trouble: trouble, progress: $progress) {
                        Tap.hard()
                        garden.solveTrouble(event)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { phase = .done }
                    }
                    .frame(height: Loam.isPad ? 340 : 260)
                    MeterBar(label: trouble.remedy.title, value: progress, tone: Loam.terracotta)
                }
            }
        }
    }

    private var done: some View {
        VStack(spacing: 12) {
            SheetCard(padding: 6) {
                PlateBox(name: trouble.plate, height: Loam.isPad ? 400 : 300, fit: true)
            }
            SheetCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("\(trouble.name), put right").font(Loam.title(18)).foregroundColor(Loam.ink)
                        Spacer()
                        StampTag(text: garden.troubleMissed(event.id) ? "+6" : "+14", tone: Loam.terracotta)
                    }
                    HeadRule(text: "What prevents it")
                    Text(trouble.prevention).font(Loam.body(13.5)).foregroundColor(Loam.inkSoft).fixedSize(horizontal: false, vertical: true)
                    NavigationLink(destination: TroubleDetailView(trouble: trouble).environmentObject(garden)) {
                        HStack(spacing: 6) {
                            Text("The register page").font(Loam.title(12)).foregroundColor(Loam.terracotta)
                            ChevGlyph(size: 11, color: Loam.terracotta, back: false)
                        }
                    }
                    .buttonStyle(.plain)
                    SowButton(title: "Back to the bed", tone: Loam.leafDeep) { onClose() }
                }
            }
        }
    }
}

struct SymptomGlyph: View {
    var crop: Crop
    var symptom: Symptom
    var size: CGFloat
    var body: some View {
        Canvas { ctx, area in
            ctx.fill(Path(roundedRect: CGRect(origin: .zero, size: area), cornerRadius: 6), with: .color(Loam.soil.opacity(0.22)))
            let rect = CGRect(origin: .zero, size: area).insetBy(dx: area.width * 0.1, dy: area.height * 0.08)
            var painter = PlantPainter(ctx, crop: crop, stage: .leaf, growth: 0.6, rect: rect, detail: true, seed: hashOf(crop.key))
            painter.draw()
            var sym = SymptomPainter(ctx: ctx, symptom: symptom, rect: rect, time: 0.6, seed: hashOf(symptom.rawValue))
            sym.draw()
        }
        .frame(width: size, height: size)
    }
}

struct Pest: Identifiable {
    var id: Int
    var x: CGFloat
    var y: CGFloat
    var gone: Bool
}

struct RemedyStage: View {
    var crop: Crop
    var trouble: Trouble
    @Binding var progress: Double
    var onDone: () -> Void
    @State private var pests: [Pest] = []
    @State private var netX: CGFloat = 0
    @State private var holdStart: Date? = nil
    @State private var holdProgress: Double = 0
    @State private var scrubs: Int = 0
    @State private var lastDirection: Int = 0
    @State private var lastX: CGFloat = 0
    @State private var pull: CGFloat = 0
    @State private var finished = false
    private let ticker = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                Canvas { ctx, area in
                    drawStage(&ctx, size: area)
                }
                .contentShape(Rectangle())
                .gesture(stageGesture(size: size))
            }
            .onAppear { seedPests(size: size) }
            .onReceive(ticker) { _ in
                if let start = holdStart, trouble.remedy == .waterBase, !finished {
                    holdProgress = min(1, Date().timeIntervalSince(start) / 1.6)
                    progress = holdProgress
                    if holdProgress >= 1 { complete() }
                }
            }
        }
    }

    private func seedPests(size: CGSize) {
        guard pests.isEmpty else { return }
        var rng = Furrow(hashOf(trouble.key + crop.key))
        let n = max(3, trouble.count)
        pests = (0..<n).map { k in
            Pest(id: k, x: size.width * CGFloat(0.28 + rng.unit() * 0.44), y: size.height * CGFloat(0.18 + rng.unit() * 0.5), gone: false)
        }
    }

    private func complete() {
        guard !finished else { return }
        finished = true
        progress = 1
        holdStart = nil
        onDone()
    }

    private func stageGesture(size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard !finished else { return }
                switch trouble.remedy {
                case .pickOff:
                    break
                case .net:
                    netX = max(netX, value.location.x)
                    progress = Double(min(1, netX / (size.width * 0.86)))
                    if progress >= 1 { complete() }
                case .waterBase:
                    let base = CGPoint(x: size.width * 0.5, y: size.height * 0.78)
                    let near = hypot(value.location.x - base.x, value.location.y - base.y) < size.width * 0.22
                    if near {
                        if holdStart == nil { holdStart = Date(); Tap.soft() }
                    } else {
                        holdStart = nil
                        holdProgress = 0
                        progress = 0
                    }
                case .mulch:
                    let dx = value.location.x - lastX
                    if abs(dx) > 6 {
                        let dir = dx > 0 ? 1 : -1
                        if dir != lastDirection && lastDirection != 0 {
                            scrubs += 1
                            Tap.soft()
                            progress = min(1, Double(scrubs) / 7)
                            if scrubs >= 7 { complete() }
                        }
                        lastDirection = dir
                        lastX = value.location.x
                    }
                case .pull:
                    pull = max(0, value.startLocation.y - value.location.y)
                    progress = min(1, Double(pull / 120))
                    if pull >= 120 { complete() }
                }
            }
            .onEnded { value in
                guard !finished else { return }
                switch trouble.remedy {
                case .pickOff:
                    let moved = hypot(value.translation.width, value.translation.height)
                    guard moved < 14 else { return }
                    if let hit = pests.firstIndex(where: { !$0.gone && hypot($0.x - value.location.x, $0.y - value.location.y) < 26 }) {
                        pests[hit].gone = true
                        Tap.crisp()
                        let done = pests.filter { $0.gone }.count
                        progress = Double(done) / Double(max(1, pests.count))
                        if done == pests.count { complete() }
                    }
                case .waterBase:
                    holdStart = nil
                    if !finished { holdProgress = 0; progress = 0 }
                case .pull:
                    if !finished { withAnimation(.easeOut(duration: 0.2)) { pull = 0; progress = 0 } }
                default:
                    break
                }
            }
    }

    private func drawStage(_ ctx: inout GraphicsContext, size: CGSize) {
        let w = size.width, h = size.height
        ctx.fill(Path(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 6), with: .color(Loam.soil))
        var grit = Furrow(hashOf(crop.key) ^ 0x33)
        for _ in 0..<Int(w * h / 90) {
            let x = CGFloat(grit.unit()) * w, y = CGFloat(grit.unit()) * h
            ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.6, height: 1.6)), with: .color(Color.black.opacity(0.14)))
        }
        if trouble.remedy == .waterBase {
            let r = CGFloat(holdProgress) * w * 0.3
            if r > 0 {
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.5 - r, y: h * 0.8 - r * 0.45, width: r * 2, height: r * 0.9)), with: .color(Loam.soilDark.opacity(0.8)))
            }
        }
        if trouble.remedy == .mulch {
            let cover = CGFloat(progress)
            if cover > 0 {
                var straw = Furrow(0x57A)
                for _ in 0..<Int(180 * cover) {
                    let x = CGFloat(straw.unit()) * w, y = h * (0.62 + CGFloat(straw.unit()) * 0.34)
                    var line = Path()
                    line.move(to: CGPoint(x: x, y: y))
                    line.addLine(to: CGPoint(x: x + CGFloat(straw.unit() * 16 - 8), y: y + CGFloat(straw.unit() * 4 - 2)))
                    ctx.stroke(line, with: .color(Loam.straw.opacity(0.85)), lineWidth: 1.6)
                }
            }
        }
        let plantRect = CGRect(x: w * 0.22, y: h * 0.1 - pull, width: w * 0.56, height: h * 0.76)
        var painter = PlantPainter(ctx, crop: crop, stage: trouble.remedy == .pull && progress > 0.5 ? .spent : .leaf, growth: 0.7, rect: plantRect, detail: true, seed: hashOf(crop.key + "stage"))
        painter.draw()
        if progress < 1 || trouble.remedy == .pickOff {
            var sym = SymptomPainter(ctx: ctx, symptom: trouble.symptom, rect: plantRect, time: Date().timeIntervalSinceReferenceDate, seed: hashOf(trouble.key))
            if trouble.remedy != .pickOff || pests.contains(where: { !$0.gone }) { sym.draw() }
        }
        if pull > 0 {
            var roots = Path()
            for k in 0..<4 {
                let x0 = w * 0.5 + CGFloat(k - 2) * 10
                roots.move(to: CGPoint(x: x0, y: h * 0.86 - pull))
                roots.addLine(to: CGPoint(x: x0 + CGFloat(k - 2) * 8, y: h * 0.9))
            }
            ctx.stroke(roots, with: .color(Loam.strawPale), lineWidth: 1.4)
        }
        if trouble.remedy == .pickOff {
            for pest in pests where !pest.gone {
                drawPest(&ctx, at: CGPoint(x: pest.x, y: pest.y), size: 12)
            }
        }
        if trouble.remedy == .net {
            let x = min(w, netX)
            if x > 2 {
                var sub = ctx
                sub.clip(to: Path(CGRect(x: 0, y: 0, width: x, height: h)))
                sub.fill(Path(CGRect(x: 0, y: 0, width: x, height: h)), with: .color(Color.white.opacity(0.28)))
                var mesh = Path()
                var gx: CGFloat = 0
                while gx < w { mesh.move(to: CGPoint(x: gx, y: 0)); mesh.addLine(to: CGPoint(x: gx - 6, y: h)); gx += 9 }
                var gy: CGFloat = 0
                while gy < h { mesh.move(to: CGPoint(x: 0, y: gy)); mesh.addLine(to: CGPoint(x: w, y: gy + 1)); gy += 9 }
                sub.stroke(mesh, with: .color(Color.white.opacity(0.55)), lineWidth: 0.7)
                ctx.stroke(Path(CGRect(x: x - 1, y: 0, width: 2, height: h)), with: .color(Loam.card.opacity(0.9)), lineWidth: 2)
            }
        }
        if trouble.remedy == .waterBase, holdStart != nil {
            var drops = Furrow(UInt64(bitPattern: Int64(Date().timeIntervalSinceReferenceDate * 20)))
            for _ in 0..<10 {
                let x = w * 0.5 + CGFloat(drops.unit() - 0.5) * w * 0.2, y = h * (0.55 + CGFloat(drops.unit()) * 0.22)
                var d = Path()
                d.move(to: CGPoint(x: x, y: y))
                d.addLine(to: CGPoint(x: x - 2, y: y + 8))
                ctx.stroke(d, with: .color(Loam.frost.opacity(0.9)), lineWidth: 1.4)
            }
        }
        ctx.stroke(Path(roundedRect: CGRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1), cornerRadius: 6), with: .color(finished ? Loam.good : Loam.soilLight), lineWidth: 3)
    }

    private func drawPest(_ ctx: inout GraphicsContext, at c: CGPoint, size: CGFloat) {
        switch trouble.symptom {
        case .holes, .stripped:
            var body = Path()
            body.move(to: CGPoint(x: c.x - size, y: c.y))
            body.addQuadCurve(to: CGPoint(x: c.x + size, y: c.y - 2), control: CGPoint(x: c.x, y: c.y - size * 0.9))
            ctx.stroke(body, with: .color(Color(red: 0.42, green: 0.62, blue: 0.24)), style: StrokeStyle(lineWidth: size * 0.55, lineCap: .round))
            for k in 0..<5 {
                let x = c.x - size * 0.7 + CGFloat(k) * size * 0.35
                ctx.fill(Path(CGRect(x: x, y: c.y - size * 0.5, width: 1, height: size * 0.5)), with: .color(Color(red: 0.2, green: 0.32, blue: 0.12)))
            }
            ctx.fill(Path(ellipseIn: CGRect(x: c.x + size * 0.7, y: c.y - size * 0.4, width: size * 0.5, height: size * 0.5)), with: .color(Color(red: 0.2, green: 0.3, blue: 0.1)))
        case .curl, .pale, .spots:
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - size * 0.4, y: c.y - size * 0.3, width: size * 0.8, height: size * 0.6)), with: .color(Color(red: 0.16, green: 0.24, blue: 0.10)))
            for k in 0..<3 {
                var leg = Path()
                leg.move(to: CGPoint(x: c.x, y: c.y))
                leg.addLine(to: CGPoint(x: c.x + CGFloat(k - 1) * size * 0.35, y: c.y + size * 0.55))
                ctx.stroke(leg, with: .color(Color(red: 0.16, green: 0.24, blue: 0.10)), lineWidth: 1)
            }
        case .wilt, .tunnel:
            var g = Path()
            g.addArc(center: c, radius: size * 0.6, startAngle: .degrees(20), endAngle: .degrees(300), clockwise: false)
            ctx.stroke(g, with: .color(Color(red: 0.86, green: 0.74, blue: 0.52)), style: StrokeStyle(lineWidth: size * 0.42, lineCap: .round))
            ctx.fill(Path(ellipseIn: CGRect(x: c.x + size * 0.3, y: c.y - size * 0.75, width: size * 0.4, height: size * 0.4)), with: .color(Color(red: 0.4, green: 0.25, blue: 0.1)))
        default:
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - size * 0.5, y: c.y - size * 0.5, width: size, height: size)), with: .color(Color(red: 0.55, green: 0.32, blue: 0.14)))
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - size * 0.3, y: c.y - size * 0.32, width: size * 0.3, height: size * 0.25)), with: .color(Color.white.opacity(0.5)))
        }
        ctx.stroke(Path(ellipseIn: CGRect(x: c.x - size * 1.3, y: c.y - size * 1.3, width: size * 2.6, height: size * 2.6)), with: .color(Loam.card.opacity(0.35)), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
    }
}
