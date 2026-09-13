import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var garden: FrostGarden
    var onClose: () -> Void
    @State private var zone = 6
    @State private var dates = FrostDates.standard
    @State private var confirmReset = false

    var body: some View {
        VStack(spacing: 0) {
            SheetHead(title: "Settings", subtitle: "Frost dates, zone and the plot's memory", onClose: onClose)
            ScrollView {
                Column {
                    zoneCard
                    datesCard
                    aboutCard
                    resetCard
                }
                .padding(.horizontal, Loam.gutter)
                .padding(.bottom, 28)
            }
        }
        .background(Loam.page.ignoresSafeArea())
        .onAppear {
            zone = garden.dates.zone
            dates = garden.dates
        }
        .alert(isPresented: $confirmReset) {
            Alert(title: Text("Reset the plot?"),
                  message: Text("Every bed, tray, harvest, season and point is cleared. The frost dates are kept."),
                  primaryButton: .destructive(Text("Reset everything")) {
                    let kept = garden.dates
                    garden.reset()
                    garden.setFrost(kept)
                    Tap.hard()
                  },
                  secondaryButton: .cancel())
        }
    }

    private var zoneCard: some View {
        SheetCard {
            VStack(alignment: .leading, spacing: 10) {
                HeadRule(text: "USDA zone")
                HStack(spacing: 4) {
                    ForEach(3...10, id: \.self) { z in
                        Button(action: {
                            Tap.light()
                            withAnimation(.easeOut(duration: 0.18)) {
                                zone = z
                                dates = FrostDates.forZone(z)
                            }
                            garden.setFrost(dates)
                        }) {
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
                Text(FrostDates.forZone(zone).zoneNote).font(Loam.note(12.5)).foregroundColor(Loam.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var datesCard: some View {
        SheetCard {
            VStack(alignment: .leading, spacing: 12) {
                HeadRule(text: "Frost dates")
                if dates.frostFree {
                    Text("Zone 10 has no expected frost. The calendar anchors on January 15 and December 31 so that every window still has a place on the year.")
                        .font(Loam.body(13)).foregroundColor(Loam.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    DateStepper(title: "Last spring frost", month: $dates.lastMonth, day: $dates.lastDay, tone: Loam.frostDeep) {
                        garden.setFrost(dates)
                    }
                    DateStepper(title: "First fall frost", month: $dates.firstMonth, day: $dates.firstDay, tone: Loam.terracottaDeep) {
                        garden.setFrost(dates)
                    }
                    YearRuler(dates: dates, today: garden.today, marks: [])
                        .frame(height: 44)
                }
                Text("The dates default from the zone. Move them if you know your own garden runs earlier or later; a wall, a slope or a valley bottom can shift the frost by two weeks.")
                    .font(Loam.note(12)).foregroundColor(Loam.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var aboutCard: some View {
        SheetCard {
            VStack(alignment: .leading, spacing: 9) {
                HeadRule(text: "About Last Frost")
                Text("A vegetable garden planner that counts every sowing, transplant and harvest from your two frost dates. Sixty crops with real numbers, twenty-four troubles of the bed, thirty-six old sayings weighed, beds of square-foot cells that grow on the real calendar, seed trays under a lamp, jobs on the days they fall, a larder of what you pulled, and a book of seventeen lessons.")
                    .font(Loam.body(13)).foregroundColor(Loam.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Everything runs on the device. No account, no network, no notifications. The numbers are the usual seed-packet and extension-service figures for a temperate garden; your own garden will run a week or two either side of them.")
                    .font(Loam.note(12)).foregroundColor(Loam.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 9) {
                    CountTile(value: "\(Register.crops.count)", label: "crops")
                    CountTile(value: "\(Troubles.all.count)", label: "troubles")
                    CountTile(value: "\(Lessons.all.count)", label: "lessons")
                    CountTile(value: "\(Glossary.terms.count)", label: "terms")
                    CountTile(value: "1.0", label: "version")
                }
            }
        }
    }

    private var resetCard: some View {
        SheetCard {
            VStack(alignment: .leading, spacing: 9) {
                HeadRule(text: "Start over")
                Text("Clears the beds, the trays, the larder, the seasons and the points. The frost dates stay.")
                    .font(Loam.body(13)).foregroundColor(Loam.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                SowButton(title: "Reset the plot", tone: Loam.bad, filled: false) { confirmReset = true }
            }
        }
    }
}

struct DateStepper: View {
    var title: String
    @Binding var month: Int
    @Binding var day: Int
    var tone: Color
    var onChange: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(Loam.body(13)).foregroundColor(Loam.inkSoft)
                Spacer()
                Text(Almanac.monthDay(month, day)).font(Loam.title(16)).foregroundColor(tone)
            }
            HStack(spacing: 6) {
                stepButton("Month") { shift(month: -1) }
                stepButton("Month", forward: true) { shift(month: 1) }
                Spacer(minLength: 6)
                stepButton("Day") { shift(day: -1) }
                stepButton("Day", forward: true) { shift(day: 1) }
                stepButton("Week") { shift(day: -7) }
                stepButton("Week", forward: true) { shift(day: 7) }
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 6).fill(tone.opacity(0.07)))
    }

    private func stepButton(_ label: String, forward: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: { Tap.light(); action(); onChange() }) {
            HStack(spacing: 3) {
                if !forward { ChevGlyph(size: 11, color: Loam.inkSoft) }
                Text(label).font(Loam.body(11)).foregroundColor(Loam.inkSoft)
                if forward { ChevGlyph(size: 11, color: Loam.inkSoft, back: false) }
            }
            .padding(.horizontal, 7).padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 4).fill(Loam.ink.opacity(0.06)))
        }
        .buttonStyle(.plain)
    }

    private func shift(month dm: Int = 0, day dd: Int = 0) {
        var m = month + dm
        var d = day + dd
        if m < 1 { m = 12 }
        if m > 12 { m = 1 }
        let limit = Almanac.daysInMonth[m - 1]
        if d < 1 {
            m = m == 1 ? 12 : m - 1
            d = Almanac.daysInMonth[m - 1] + d
        } else if d > limit {
            d -= limit
            m = m == 12 ? 1 : m + 1
        }
        month = m
        day = max(1, min(Almanac.daysInMonth[m - 1], d))
    }
}
