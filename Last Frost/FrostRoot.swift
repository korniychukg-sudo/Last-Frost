import SwiftUI

struct FrostRoot: View {
    @EnvironmentObject var garden: FrostGarden
    @State private var tab = 0
    @State private var lastTab = 0
    @State private var restored = false

    var body: some View {
        ZStack {
            Loam.page.ignoresSafeArea()
            VStack(spacing: 0) {
                Group {
                    switch tab {
                    case 0:
                        NavigationView { TodayView().environmentObject(garden) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 1:
                        NavigationView { PlotView().environmentObject(garden) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 2:
                        NavigationView { AlmanacView().environmentObject(garden) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 3:
                        NavigationView { LarderView().environmentObject(garden) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    default:
                        NavigationView { BookView().environmentObject(garden) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    }
                }
                .id(tab)
                .transition(.asymmetric(
                    insertion: .move(edge: tab > lastTab ? .trailing : .leading)
                        .combined(with: .opacity),
                    removal: .opacity))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                bar
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if !restored {
                restored = true
                if let t = garden.book.uiTab, t >= 0, t < 5 { tab = t; lastTab = t }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            garden.refreshClock()
        }
        .onReceive(garden.$wantedTab) { wanted in
            if let w = wanted, w != tab {
                lastTab = tab
                withAnimation(.easeInOut(duration: 0.22)) { tab = w }
                garden.wantedTab = nil
            }
        }
    }

    private var bar: some View {
        HStack(spacing: 0) {
            tabButton(0, "Today")
            tabButton(1, "Plot")
            tabButton(2, "Almanac")
            tabButton(3, "Larder")
            tabButton(4, "Book")
        }
        .padding(.top, 7)
        .padding(.bottom, 3)
        .background(
            Loam.card
                .overlay(Rectangle().fill(Loam.ink.opacity(0.10)).frame(height: 0.7),
                         alignment: .top)
                .edgesIgnoringSafeArea(.bottom)
        )
    }

    private func tabButton(_ index: Int, _ label: String) -> some View {
        let active = tab == index
        let tone = active ? Loam.leafDeep : Loam.inkFaint
        return Button(action: {
            Tap.light()
            garden.refreshClock()
            lastTab = tab
            withAnimation(.easeInOut(duration: 0.22)) { tab = index }
            garden.remember(tab: index)
        }) {
            VStack(spacing: 3) {
                Group {
                    switch index {
                    case 0: SunBedMark(size: 22, color: tone)
                    case 1: BedGridMark(size: 22, color: tone)
                    case 2: PacketMark(size: 22, color: tone)
                    case 3: JarMark(size: 22, color: tone)
                    default: BookMark(size: 22, color: tone)
                    }
                }
                Text(label).font(Loam.body(9.5)).foregroundColor(tone)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct FrostIntro: View {
    @EnvironmentObject var garden: FrostGarden
    @State private var page = 0
    @State private var zone = 6

    private let pages: [(String, String, String)] = [
        ("Last Frost",
         "Every sowing, transplant and harvest in a vegetable garden is a count of weeks from two dates: the last frost of spring and the first frost of autumn. Tomatoes go out one to two weeks after the last frost. Peas go in six weeks before it. Garlic goes in six weeks before the first. Set those two dates and the whole year falls into place.",
         "ob_p0"),
        ("Counted from your frost",
         "The almanac holds sixty crops with their real numbers: weeks before or after the frost to sow indoors, to set out and to sow direct, days to maturity, plants to a square foot, frost hardiness, succession intervals and harvest windows. Every one of them is shown against a ruler of your own year, with your frost lines drawn on it.",
         "ob_p1"),
        ("The plot grows on the real calendar",
         "Lay out beds of square-foot cells. Drag a crop onto a square and the plot checks the rotation against the bed's history, the neighbours for companions and antagonists, and today's date against the crop's window. Press and hold to open a drill, draw along the row to drop seed at the crop's spacing, and the plants grow by the real date. Pull them inside the window and they go to the larder.",
         "ob_p2"),
        ("Set your frost dates",
         "Pick your USDA zone and the app takes the usual frost dates for it. Change either date any time in Settings; everything is recomputed. If you do not know your zone, six is a fair middle of the country.",
         "ob_p3")
    ]

    var body: some View {
        ZStack {
            Loam.page.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    if page > 0 {
                        Button(action: { Tap.light(); withAnimation { page -= 1 } }) {
                            HStack(spacing: 4) {
                                ChevGlyph(size: 15, color: Loam.inkSoft)
                                Text("Back").font(Loam.body(13.5)).foregroundColor(Loam.inkSoft)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                    Button(action: { Tap.light(); finish() }) {
                        Text("Skip").font(Loam.body(13.5)).foregroundColor(Loam.inkFaint)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Loam.gutter)
                .padding(.top, 14)
                Spacer(minLength: 0)
                ScrollView {
                    Column {
                        if Plates.exists(pages[page].2) {
                            SheetCard(padding: 9) {
                                PlateBox(name: pages[page].2, height: Loam.isPad ? 300 : 208)
                            }
                        } else {
                            SheetCard(padding: 0) {
                                PlotScene(hour: Almanac.hourNow(), day: garden.today, beds: [], dates: garden.dates, rain: 0)
                                    .frame(height: Loam.isPad ? 260 : 190)
                                    .clipped()
                            }
                        }
                        VStack(alignment: .leading, spacing: 9) {
                            Text(pages[page].0).font(Loam.title(23)).foregroundColor(Loam.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(pages[page].1).font(Loam.body(14.5))
                                .foregroundColor(Loam.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        if page == pages.count - 1 {
                            ZonePicker(zone: $zone)
                        }
                    }
                    .padding(.horizontal, Loam.gutter)
                    .id(page)
                    .transition(.opacity)
                }
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Circle().fill(i == page ? Loam.ink : Loam.ink.opacity(0.20))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.bottom, 13)
                SowButton(title: page == pages.count - 1 ? "Into the plot" : "Next",
                          tone: Loam.leafDeep) {
                    if page == pages.count - 1 { finish() } else { withAnimation { page += 1 } }
                }
                .padding(.horizontal, Loam.gutter)
                .padding(.bottom, 20)
            }
        }
    }

    private func finish() {
        garden.setZone(zone)
        garden.book.seenIntro = true
    }
}

struct ZonePicker: View {
    @Binding var zone: Int

    var body: some View {
        SheetCard {
            VStack(alignment: .leading, spacing: 10) {
                HeadRule(text: "USDA zone")
                HStack(spacing: 4) {
                    ForEach(3...10, id: \.self) { z in
                        Button(action: { Tap.light(); withAnimation(.easeOut(duration: 0.18)) { zone = z } }) {
                            Text("\(z)")
                                .font(Loam.title(14))
                                .foregroundColor(zone == z ? Loam.card : Loam.inkSoft)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(RoundedRectangle(cornerRadius: 5)
                                                .fill(zone == z ? Loam.leafDeep : Loam.ink.opacity(0.06)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                let d = FrostDates.forZone(zone)
                HStack(spacing: 9) {
                    CountTile(value: d.lastLabel, label: "last spring frost", tone: Loam.frostDeep)
                    CountTile(value: d.firstLabel, label: "first fall frost", tone: Loam.terracottaDeep)
                }
                Text(d.zoneNote).font(Loam.note(12.5)).foregroundColor(Loam.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
