import SwiftUI

struct AlmanacView: View {
    @EnvironmentObject var garden: FrostGarden
    @State private var query = ""
    @State private var family: CropFamily? = nil
    @State private var mode = 0
    @State private var openCrop: String? = nil
    @State private var restored = false

    private var crops: [Crop] {
        Register.crops.filter { crop in
            if let f = family, crop.family != f { return false }
            if !query.isEmpty {
                let q = query.lowercased()
                if !(crop.name.lowercased().contains(q) || crop.latin.lowercased().contains(q) || crop.family.name.lowercased().contains(q)) { return false }
            }
            switch mode {
            case 1:
                let v = Planner.verdict(for: crop, on: garden.today, dates: garden.dates)
                return v.kind == .direct || v.kind == .fall || v.kind == .transplant || v.kind == .startIndoors
            case 2:
                return crop.fall != nil
            default:
                return true
            }
        }
    }

    var body: some View {
        ScrollView {
            Column {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Almanac").font(Loam.title(26)).foregroundColor(Loam.ink)
                    Text("Sixty crops, every window counted from your frost on \(garden.dates.lastLabel) and \(garden.dates.firstLabel).")
                        .font(Loam.note(13)).foregroundColor(Loam.inkFaint).fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                searchBar
                BandPicker(titles: ["All", "Sowable now", "Fall sowings"], index: $mode)
                familyStrip
                familiesCard
                grid
            }
            .padding(.horizontal, Loam.gutter)
            .padding(.bottom, 28)
        }
        .background(Loam.page.ignoresSafeArea())
        .navigationBarHidden(true)
        .background(
            Group {
                ForEach(Register.crops) { crop in
                    NavigationLink(destination: CropDetailView(crop: crop).environmentObject(garden), tag: crop.key, selection: $openCrop) { EmptyView() }
                }
            }
            .hidden()
        )
        .onAppear {
            if !restored {
                restored = true
                if let c = garden.book.uiCrop, Register.exists(c) { openCrop = c }
            }
        }
        .onChange(of: openCrop) { value in garden.remember(crop: value) }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            TextField("Search a crop or a family", text: $query)
                .font(Loam.body(15))
                .disableAutocorrection(true)
            if !query.isEmpty {
                Button(action: { Tap.light(); query = "" }) { CrossGlyph(size: 12, color: Loam.inkFaint) }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 6).fill(Loam.card).overlay(RoundedRectangle(cornerRadius: 6).stroke(Loam.ink.opacity(0.15))))
    }

    private var familyStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                familyChip(nil, "Every family")
                ForEach(CropFamily.allCases, id: \.self) { f in familyChip(f, f.name) }
            }
        }
    }

    private func familyChip(_ f: CropFamily?, _ label: String) -> some View {
        let active = family == f
        return Button(action: { Tap.light(); withAnimation(.easeOut(duration: 0.2)) { family = f } }) {
            Text(label).font(Loam.title(11)).foregroundColor(active ? Loam.card : Loam.inkSoft)
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Capsule().fill(active ? Loam.leafDeep : Loam.ink.opacity(0.06)))
        }
        .buttonStyle(.plain)
    }

    private var familiesCard: some View {
        Group {
            if let f = family {
                NavigationLink(destination: FamilyView(family: f).environmentObject(garden)) {
                    SheetCard(padding: 0) {
                        HStack(spacing: 0) {
                            ThumbBox(name: f.plate, height: 90, corner: 0).frame(width: 130)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("\(f.name) family").font(Loam.title(15)).foregroundColor(Loam.ink)
                                Text(f.signature).font(Loam.body(11.5)).foregroundColor(Loam.inkFaint).lineLimit(3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(10)
                            Spacer(minLength: 0)
                            ChevGlyph(size: 14, color: Loam.inkFaint, back: false).padding(.trailing, 10)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var grid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: Loam.isPad ? 3 : 2)
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(crops) { crop in
                Button(action: { Tap.light(); openCrop = crop.key }) {
                    CropCard(crop: crop)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct CropCard: View {
    @EnvironmentObject var garden: FrostGarden
    var crop: Crop

    var body: some View {
        let verdict = Planner.verdict(for: crop, on: garden.today, dates: garden.dates)
        let tone: Color
        switch verdict.kind {
        case .direct, .fall, .transplant: tone = Loam.good
        case .startIndoors: tone = Loam.warn
        default: tone = Loam.inkFaint
        }
        return SheetCard(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                ThumbBox(name: crop.plate, height: Loam.isPad ? 200 : 150, corner: 0, side: 320)
                VStack(alignment: .leading, spacing: 4) {
                    Text(crop.name).font(Loam.title(15)).foregroundColor(Loam.ink).lineLimit(1).minimumScaleFactor(0.8)
                    Text("\(crop.family.name) · \(crop.maturity.lowerBound) to \(crop.maturity.upperBound) days").font(Loam.body(11)).foregroundColor(Loam.inkFaint).lineLimit(1)
                    HStack(spacing: 5) {
                        Circle().fill(tone).frame(width: 6, height: 6)
                        Text(verdictShort(verdict)).font(Loam.note(10.5)).foregroundColor(Loam.inkSoft).lineLimit(1)
                    }
                    if let entry = garden.entry(crop.key) {
                        StampTag(text: entry.qualityWord, tone: entry.quality == 2 ? Loam.prize : Loam.good)
                    }
                }
                .padding(10)
            }
        }
    }

    private func verdictShort(_ v: SowVerdict) -> String {
        switch v.kind {
        case .direct: return "sow direct now"
        case .fall: return "fall sowing now"
        case .transplant: return "set out now"
        case .startIndoors: return "start indoors now"
        case .wait: return v.opens.map { "opens \(Almanac.label($0))" } ?? "waiting"
        case .tooLate: return "next season"
        case .resting: return "resting"
        }
    }
}

struct CropDetailView: View {
    @EnvironmentObject var garden: FrostGarden
    var crop: Crop
    @State private var started = false

    var body: some View {
        let fy = garden.frostYear
        let verdict = Planner.verdict(for: crop, on: garden.today, dates: garden.dates)
        return ScrollView {
            Column {
                SheetCard(padding: 6) {
                    PlateBox(name: crop.plate, height: Loam.isPad ? 560 : 420, fit: true)
                }
                .rising(0)
                SheetCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(crop.name).font(Loam.title(24)).foregroundColor(Loam.ink)
                            Spacer()
                            NavigationLink(destination: FamilyView(family: crop.family).environmentObject(garden)) {
                                SmallChip(text: crop.family.name, tone: Loam.leafDeep)
                            }
                            .buttonStyle(.plain)
                        }
                        Text(crop.latin).font(Loam.note(14)).foregroundColor(Loam.inkFaint)
                        NoticeBar(text: verdict.text, tone: verdictTone(verdict), action: offerTray(verdict) ? ("Start a tray", {
                            garden.startTray(crop.key); Tap.firm(); started = true
                        }) : nil)
                        if started || garden.book.trays.contains(where: { $0.crop == crop.key }) {
                            StampTag(text: "tray started", tone: Loam.good)
                        }
                    }
                }
                .rising(1)
                SheetCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HeadRule(text: "Your year", trailing: "\(fy.year)")
                        YearRuler(dates: garden.dates, today: garden.today, marks: marks(fy))
                            .frame(height: 44)
                        legend
                        if let first = Planner.firstHarvest(crop, fy) {
                            Text("First harvest from the earliest planting: \(first.label).").font(Loam.note(12.5)).foregroundColor(Loam.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .rising(2)
                SheetCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HeadRule(text: "The numbers")
                        if let i = crop.indoors { FactRow(label: "Indoors", value: Planner.weeksText(i, before: true) + " the last frost" + windowText(Planner.indoorsWindow(crop, fy))) }
                        if let t = crop.transplant { FactRow(label: "Set out", value: Planner.relativeText(t) + windowText(Planner.transplantWindow(crop, fy))) }
                        if let d = crop.direct { FactRow(label: "Direct", value: Planner.relativeText(d) + windowText(Planner.directWindow(crop, fy))) }
                        if let f = crop.fall { FactRow(label: "Fall sowing", value: Planner.weeksText(f, before: true) + " the first frost" + windowText(Planner.fallWindow(crop, fy))) }
                        FactRow(label: "Maturity", value: "\(crop.maturity.lowerBound) to \(crop.maturity.upperBound) days" + (crop.transplant != nil && crop.direct == nil ? " from transplanting" : " from sowing"))
                        FactRow(label: "Per square", value: "\(crop.perCell), \(crop.spacing) inches apart")
                        FactRow(label: "Hardiness", value: "\(crop.hardiness.name). \(crop.hardiness.meaning)")
                        if let s = crop.succession { FactRow(label: "Succession", value: "Every \(s) days" + (Planner.latestSuccession(crop, fy).map { "; last sowing \(Almanac.label($0))" } ?? "")) }
                        FactRow(label: "Window", value: "\(crop.window) days of harvest after maturity")
                        if crop.isPerennial { FactRow(label: "Perennial", value: "Holds its square for years; the plot treats it as permanent.") }
                    }
                }
                .rising(3)
                SheetCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HeadRule(text: "Neighbours")
                        Text("Companions").font(Loam.title(12)).foregroundColor(Loam.good)
                        neighbourRow(crop.companions)
                        Text("Antagonists").font(Loam.title(12)).foregroundColor(Loam.bad)
                        neighbourRow(crop.antagonists)
                    }
                }
                .rising(4)
                SheetCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HeadRule(text: "The crop")
                        Text(crop.note).font(Loam.body(14)).foregroundColor(Loam.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                        HeadRule(text: "How it goes wrong")
                        Text(crop.trouble).font(Loam.note(14)).foregroundColor(Loam.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .rising(5)
                if let entry = garden.entry(crop.key) {
                    SheetCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HeadRule(text: "In the larder", trailing: entry.qualityWord)
                            Text("Best pull \(Almanac.labelLong(entry.day)) from \(entry.bed), season \(entry.season); \(entry.count) \(entry.count == 1 ? "pull" : "pulls") in all.")
                                .font(Loam.body(13)).foregroundColor(Loam.inkSoft).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .rising(6)
                }
            }
            .padding(.horizontal, Loam.gutter)
            .padding(.bottom, 28)
        }
        .background(Loam.page.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarTitle(Text(crop.name), displayMode: .inline)
    }

    private func windowText(_ w: DayWindow?) -> String { w.map { " (\($0.label))" } ?? "" }

    private func verdictTone(_ v: SowVerdict) -> Color {
        switch v.kind {
        case .direct, .fall, .transplant: return Loam.good
        case .startIndoors: return Loam.warn
        case .wait: return Loam.frostDeep
        default: return Loam.inkFaint
        }
    }

    private func offerTray(_ v: SowVerdict) -> Bool {
        (v.kind == .startIndoors || (v.kind == .transplant && crop.indoors != nil)) && !garden.book.trays.contains(where: { $0.crop == crop.key })
    }

    private func marks(_ fy: FrostYear) -> [(DayWindow, Color, String)] {
        var out: [(DayWindow, Color, String)] = []
        if let i = Planner.indoorsWindow(crop, fy) { out.append((i, Loam.straw, "indoors")) }
        if let t = Planner.transplantWindow(crop, fy) { out.append((t, Loam.leaf, "set out")) }
        if let d = Planner.directWindow(crop, fy) { out.append((d, Loam.leafDeep, "direct")) }
        if let f = Planner.fallWindow(crop, fy) { out.append((f, Loam.terracotta, "fall")) }
        if let h = Planner.firstHarvest(crop, fy) { out.append((DayWindow(start: h.start, end: h.end + crop.window), Loam.prize, "harvest")) }
        return out
    }

    private var legend: some View {
        HStack(spacing: 10) {
            legendDot(Loam.straw, "indoors")
            legendDot(Loam.leaf, "set out")
            legendDot(Loam.leafDeep, "direct")
            legendDot(Loam.terracotta, "fall")
            legendDot(Loam.prize, "harvest")
        }
    }

    private func legendDot(_ c: Color, _ t: String) -> some View {
        HStack(spacing: 4) {
            Capsule().fill(c).frame(width: 12, height: 6)
            Text(t).font(Loam.body(10)).foregroundColor(Loam.inkFaint)
        }
    }

    private func neighbourRow(_ keys: [String]) -> some View {
        HStack(spacing: 8) {
            ForEach(keys, id: \.self) { key in
                let other = Register.find(key)
                NavigationLink(destination: CropDetailView(crop: other).environmentObject(garden)) {
                    HStack(spacing: 6) {
                        PlantGlyph(crop: other, stage: .mature, growth: 1, size: 28, detail: false)
                        Text(other.name).font(Loam.body(12)).foregroundColor(Loam.ink)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Loam.ink.opacity(0.05)))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct FamilyView: View {
    @EnvironmentObject var garden: FrostGarden
    var family: CropFamily

    var body: some View {
        ScrollView {
            Column {
                SheetCard(padding: 6) {
                    PlateBox(name: family.plate, height: Loam.isPad ? 420 : 250, fit: true)
                }
                .rising(0)
                SheetCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(family.name) family").font(Loam.title(22)).foregroundColor(Loam.ink)
                        Text(family.latin).font(Loam.note(13)).foregroundColor(Loam.inkFaint)
                        Text(family.signature).font(Loam.title(13.5)).foregroundColor(Loam.inkSoft).fixedSize(horizontal: false, vertical: true)
                        Text(family.lore).font(Loam.body(14)).foregroundColor(Loam.inkSoft).fixedSize(horizontal: false, vertical: true)
                    }
                }
                .rising(1)
                SheetCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HeadRule(text: "Members", trailing: "\(Register.members(of: family).count)")
                        ForEach(Register.members(of: family)) { crop in
                            NavigationLink(destination: CropDetailView(crop: crop).environmentObject(garden)) {
                                HStack(spacing: 12) {
                                    PlantGlyph(crop: crop, stage: .mature, growth: 1, size: 40)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(crop.name).font(Loam.title(14)).foregroundColor(Loam.ink)
                                        Text("\(crop.hardiness.name) · \(crop.maturity.lowerBound) to \(crop.maturity.upperBound) days · \(crop.perCell) per square").font(Loam.body(11.5)).foregroundColor(Loam.inkFaint)
                                    }
                                    Spacer()
                                    ChevGlyph(size: 13, color: Loam.inkFaint, back: false)
                                }
                                .padding(.vertical, 3)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .rising(2)
            }
            .padding(.horizontal, Loam.gutter)
            .padding(.bottom, 28)
        }
        .background(Loam.page.ignoresSafeArea())
        .navigationBarTitle(Text(family.name), displayMode: .inline)
    }
}
