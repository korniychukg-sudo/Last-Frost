import SwiftUI

struct LarderView: View {
    @EnvironmentObject var garden: FrostGarden
    @State private var picked: Crop? = nil
    @State private var openSeason: SeasonRecord? = nil

    var body: some View {
        ScrollView {
            Column {
                header
                SheetCard(padding: 0) {
                    PlateBox(name: "sh_\(min(5, garden.book.larder.count / 8))", height: Loam.isPad ? 260 : 170, corner: 7)
                }
                .rising(0)
                countsCard
                ForEach(CropFamily.allCases, id: \.self) { family in
                    shelfCard(family)
                }
                seasonsCard
            }
            .padding(.horizontal, Loam.gutter)
            .padding(.bottom, 28)
        }
        .background(Loam.page.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(item: $picked) { crop in
            SlotSheet(crop: crop) { picked = nil }.environmentObject(garden)
        }
        .sheet(item: $openSeason) { record in
            SeasonSheet(record: record) { openSeason = nil }.environmentObject(garden)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Larder").font(Loam.title(26)).foregroundColor(Loam.ink)
            Text("One slot for every crop. A better pull replaces a poorer one; nothing is ever locked.")
                .font(Loam.note(13)).foregroundColor(Loam.inkFaint).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var countsCard: some View {
        SheetCard {
            HStack(spacing: 9) {
                CountTile(value: "\(garden.book.larder.count)/\(Register.crops.count)", label: "slots filled")
                CountTile(value: "\(garden.larderPrize)", label: "prize", tone: Loam.prize)
                CountTile(value: "\(garden.book.larder.filter { $0.quality == 1 }.count)", label: "good", tone: Loam.good)
                CountTile(value: "\(garden.book.harvestCount ?? 0)", label: "pulls in all", tone: Loam.terracotta)
            }
        }
        .rising(1)
    }

    private func shelfCard(_ family: CropFamily) -> some View {
        let members = Register.members(of: family)
        let filled = members.filter { garden.entry($0.key) != nil }.count
        return SheetCard(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(family.name).font(Loam.title(13)).foregroundColor(Loam.inkSoft)
                    Spacer()
                    Text("\(filled) of \(members.count)").font(Loam.body(11)).foregroundColor(Loam.inkFaint)
                }
                .padding(.horizontal, 12).padding(.top, 10)
                let perRow = Loam.isPad ? 6 : 4
                let rows = Int(ceil(Double(members.count) / Double(perRow)))
                ForEach(0..<rows, id: \.self) { r in
                    let slice = Array(members.dropFirst(r * perRow).prefix(perRow))
                    ShelfRow(crops: slice, perRow: perRow, entries: garden.book.larder) { crop in
                        Tap.light()
                        picked = crop
                    }
                    .frame(height: 132)
                }
                Spacer().frame(height: 8)
            }
        }
    }

    private var seasonsCard: some View {
        SheetCard {
            VStack(alignment: .leading, spacing: 10) {
                HeadRule(text: "Seasons", trailing: "season \(garden.book.seasonNumber) open")
                if garden.book.seasons.isEmpty {
                    Text("Each closed season becomes a page here: what was sown, what was pulled, what stood in every bed. The first page is written when you close the season after the first frost.")
                        .font(Loam.body(13)).foregroundColor(Loam.inkSoft).fixedSize(horizontal: false, vertical: true)
                }
                ForEach(garden.book.seasons.reversed()) { record in
                    Button(action: { Tap.light(); openSeason = record }) {
                        HStack(spacing: 12) {
                            ThumbBox(name: "se_\(Almanac.season(of: record.closedDay))", height: 54, corner: 4, side: 200).frame(width: 84)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Season \(record.number), \(record.year)").font(Loam.title(14)).foregroundColor(Loam.ink)
                                Text("\(record.sowings) sowings, \(record.harvests) pulls, \(record.prize) at prize, \(record.beds) beds")
                                    .font(Loam.body(12)).foregroundColor(Loam.inkFaint).fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                            ChevGlyph(size: 13, color: Loam.inkFaint, back: false)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .rising(2)
    }
}

struct ShelfRow: View {
    var crops: [Crop]
    var perRow: Int
    var entries: [LarderEntry]
    var onTap: (Crop) -> Void

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Canvas { ctx, size in
                    drawShelf(&ctx, size: size)
                }
                HStack(spacing: 0) {
                    ForEach(0..<perRow, id: \.self) { i in
                        if i < crops.count {
                            Button(action: { onTap(crops[i]) }) { Color.clear.contentShape(Rectangle()) }
                                .buttonStyle(.plain)
                        } else {
                            Color.clear
                        }
                    }
                }
            }
        }
    }

    private func drawShelf(_ ctx: inout GraphicsContext, size: CGSize) {
        let w = size.width, h = size.height
        let shelfY = h - 36
        ctx.fill(Path(CGRect(x: 0, y: shelfY, width: w, height: 12)), with: .color(Loam.soilLight))
        ctx.fill(Path(CGRect(x: 0, y: shelfY + 12, width: w, height: 4)), with: .color(Loam.soilDark))
        ctx.fill(Path(CGRect(x: 0, y: shelfY + 16, width: w, height: 6)), with: .color(Loam.ink.opacity(0.08)))
        for k in 0..<3 {
            let x = w * (0.15 + CGFloat(k) * 0.35)
            var bracket = Path()
            bracket.move(to: CGPoint(x: x, y: shelfY + 16))
            bracket.addLine(to: CGPoint(x: x - 8, y: shelfY + 22))
            ctx.stroke(bracket, with: .color(Loam.soilDark), lineWidth: 3)
        }
        let slotW = w / CGFloat(perRow)
        for (i, crop) in crops.enumerated() {
            let cx = slotW * (CGFloat(i) + 0.5)
            let entry = entries.first { $0.crop == crop.key }
            drawSlot(&ctx, crop: crop, entry: entry, cx: cx, baseY: shelfY, width: min(76, slotW - 10))
        }
    }

    private func drawSlot(_ ctx: inout GraphicsContext, crop: Crop, entry: LarderEntry?, cx: CGFloat, baseY: CGFloat, width: CGFloat) {
        let jarCrop = [PlantForm.fruitBush, .vine, .herb, .flower, .runner, .bush, .head, .leafy].contains(crop.form)
        let bodyH: CGFloat = 62
        let top = baseY - bodyH
        if let e = entry {
            let tones = PlantPalette.tones(for: crop)
            let fill = tones.fruit == .clear ? tones.leaf : tones.fruit
            if jarCrop {
                let jar = Path(roundedRect: CGRect(x: cx - width * 0.36, y: top + 8, width: width * 0.72, height: bodyH - 8), cornerRadius: 6)
                ctx.fill(jar, with: .color(fill.opacity(0.85)))
                var sub = ctx
                sub.opacity = 0.9
                var painter = PlantPainter(sub, crop: crop, stage: .mature, growth: 1, rect: CGRect(x: cx - width * 0.28, y: top + 14, width: width * 0.56, height: bodyH - 24), detail: false, seed: hashOf(crop.key))
                painter.draw()
                ctx.fill(Path(roundedRect: CGRect(x: cx - width * 0.36, y: top + 8, width: width * 0.72, height: bodyH - 8), cornerRadius: 6), with: .color(Loam.frost.opacity(0.18)))
                ctx.stroke(jar, with: .color(Loam.ink.opacity(0.7)), lineWidth: 1.2)
                ctx.fill(Path(roundedRect: CGRect(x: cx - width * 0.32, y: top + 1, width: width * 0.64, height: 10), cornerRadius: 3), with: .color(Loam.straw))
                ctx.stroke(Path(roundedRect: CGRect(x: cx - width * 0.32, y: top + 1, width: width * 0.64, height: 10), cornerRadius: 3), with: .color(Loam.ink.opacity(0.6)), lineWidth: 1)
                var glint = Path()
                glint.move(to: CGPoint(x: cx - width * 0.28, y: top + 16))
                glint.addLine(to: CGPoint(x: cx - width * 0.26, y: top + bodyH - 10))
                ctx.stroke(glint, with: .color(Color.white.opacity(0.55)), lineWidth: 2)
            } else {
                let crate = CGRect(x: cx - width * 0.42, y: top + 22, width: width * 0.84, height: bodyH - 22)
                ctx.fill(Path(crate), with: .color(Loam.soilLight))
                for k in 0..<3 {
                    let y = crate.minY + crate.height * CGFloat(k + 1) / 3.5
                    var slat = Path()
                    slat.move(to: CGPoint(x: crate.minX, y: y))
                    slat.addLine(to: CGPoint(x: crate.maxX, y: y))
                    ctx.stroke(slat, with: .color(Loam.soilDark.opacity(0.6)), lineWidth: 1)
                }
                ctx.stroke(Path(crate), with: .color(Loam.ink.opacity(0.7)), lineWidth: 1.2)
                for k in 0..<3 {
                    let px = cx + CGFloat(k - 1) * width * 0.22
                    let r = width * 0.11
                    ctx.fill(Path(ellipseIn: CGRect(x: px - r, y: crate.minY - r * 0.9, width: r * 2, height: r * 1.7)), with: .color(fill))
                    ctx.fill(Path(ellipseIn: CGRect(x: px - r * 0.5, y: crate.minY - r * 0.7, width: r * 0.5, height: r * 0.4)), with: .color(Color.white.opacity(0.3)))
                }
                var painter = PlantPainter(ctx, crop: crop, stage: .leaf, growth: 0.5, rect: CGRect(x: cx - width * 0.25, y: top - 8, width: width * 0.5, height: 34), detail: false, seed: hashOf(crop.key))
                painter.draw()
            }
            let ribbon: Color = e.quality == 2 ? Loam.prize : (e.quality == 1 ? Loam.good : Loam.inkFaint)
            ctx.fill(Path(ellipseIn: CGRect(x: cx + width * 0.24, y: top + 4, width: 12, height: 12)), with: .color(ribbon))
            ctx.stroke(Path(ellipseIn: CGRect(x: cx + width * 0.24, y: top + 4, width: 12, height: 12)), with: .color(Loam.card), lineWidth: 1.2)
            if e.count > 1 {
                ctx.draw(Text("\(e.count)").font(Loam.title(8)).foregroundColor(Loam.card), at: CGPoint(x: cx + width * 0.24 + 6, y: top + 10))
            }
        } else {
            let jar = Path(roundedRect: CGRect(x: cx - width * 0.32, y: top + 12, width: width * 0.64, height: bodyH - 12), cornerRadius: 6)
            ctx.stroke(jar, with: .color(Loam.ink.opacity(0.22)), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            var sub = ctx
            sub.opacity = 0.28
            var painter = PlantPainter(sub, crop: crop, stage: .mature, growth: 1, rect: CGRect(x: cx - width * 0.26, y: top + 16, width: width * 0.52, height: bodyH - 24), detail: false, seed: hashOf(crop.key))
            painter.draw()
        }
        ctx.draw(Text(crop.name).font(Loam.body(9.5)).foregroundColor(entry == nil ? Loam.inkFaint : Loam.ink), at: CGPoint(x: cx, y: baseY + 28))
    }
}

struct SlotSheet: View {
    @EnvironmentObject var garden: FrostGarden
    var crop: Crop
    var onClose: () -> Void

    var body: some View {
        let entry = garden.entry(crop.key)
        return VStack(spacing: 0) {
            SheetHead(title: crop.name, subtitle: entry.map { "\($0.qualityWord) · best pull \(Almanac.labelLong($0.day))" } ?? "Not yet on the shelves", onClose: onClose)
            ScrollView {
                Column {
                    SheetCard(padding: 6) {
                        PlateBox(name: crop.plate, height: Loam.isPad ? 520 : 380, fit: true)
                            .opacity(entry == nil ? 0.55 : 1)
                    }
                    if let e = entry {
                        SheetCard {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 9) {
                                    CountTile(value: e.qualityWord, label: "grade", tone: e.quality == 2 ? Loam.prize : Loam.good)
                                    CountTile(value: "\(e.count)", label: e.count == 1 ? "pull" : "pulls")
                                    CountTile(value: "\(e.season)", label: "season")
                                }
                                FactRow(label: "Pulled", value: Almanac.labelLong(e.day))
                                FactRow(label: "From", value: e.bed)
                                Text(gradeNote(e)).font(Loam.note(13)).foregroundColor(Loam.inkSoft).fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    } else {
                        SheetCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Grow it to fill the slot").font(Loam.title(15)).foregroundColor(Loam.ink)
                                Text(Planner.verdict(for: crop, on: garden.today, dates: garden.dates).text).font(Loam.body(13)).foregroundColor(Loam.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("Pull it inside its window of \(crop.window) days after maturity, with the rotation clear and a companion beside it, for the Prize grade.")
                                    .font(Loam.note(12.5)).foregroundColor(Loam.inkFaint).fixedSize(horizontal: false, vertical: true)
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

    private func gradeNote(_ e: LarderEntry) -> String {
        switch e.quality {
        case 2: return "Pulled inside the window with the rotation clear, a companion beside it and good spacing. Nothing to improve."
        case 1: return "A good pull. A Prize needs all four: the window, a clear rotation, a companion beside the square and the spacing right at sowing."
        default: return "A fair pull, outside the window or against the rotation. The slot upgrades the day a better pull of \(crop.plural.lowercased()) comes in."
        }
    }
}

struct SeasonSheet: View {
    @EnvironmentObject var garden: FrostGarden
    var record: SeasonRecord
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SheetHead(title: "Season \(record.number), \(record.year)", subtitle: "Closed \(Almanac.labelLong(record.closedDay))", onClose: onClose)
            ScrollView {
                Column {
                    SheetCard(padding: 6) {
                        PlateBox(name: "se_\(Almanac.season(of: record.closedDay))", height: Loam.isPad ? 360 : 220)
                    }
                    SheetCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 9) {
                                CountTile(value: "\(record.sowings)", label: "sowings")
                                CountTile(value: "\(record.harvests)", label: "pulls", tone: Loam.leafDeep)
                                CountTile(value: "\(record.prize)", label: "prize", tone: Loam.prize)
                                CountTile(value: "\(record.beds)", label: "beds")
                            }
                            HeadRule(text: "Families that stood")
                            if record.families.isEmpty {
                                Text("Nothing was grown this season.").font(Loam.body(13)).foregroundColor(Loam.inkSoft)
                            } else {
                                Text(record.families.map { familyShort($0) }.joined(separator: ", ")).font(Loam.body(13.5)).foregroundColor(Loam.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            HeadRule(text: "Pulled this season")
                            ForEach(garden.book.larder.filter { $0.season == record.number }) { e in
                                HStack(spacing: 10) {
                                    PlantGlyph(crop: Register.find(e.crop), stage: .mature, growth: 1, size: 30, detail: false)
                                    Text(Register.find(e.crop).name).font(Loam.body(13)).foregroundColor(Loam.ink)
                                    Spacer()
                                    StampTag(text: e.qualityWord, tone: e.quality == 2 ? Loam.prize : (e.quality == 1 ? Loam.good : Loam.inkFaint))
                                }
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
