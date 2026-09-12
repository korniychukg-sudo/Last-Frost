import SwiftUI

struct BookView: View {
    @EnvironmentObject var garden: FrostGarden
    @State private var section = 0
    @State private var openExam = false
    @State private var openTerm: Term? = nil
    @State private var openLesson: String? = nil
    @State private var restored = false

    var body: some View {
        ScrollView {
            Column {
                VStack(alignment: .leading, spacing: 4) {
                    Text("The Book").font(Loam.title(26)).foregroundColor(Loam.ink)
                    Text("Thirteen lessons, a glossary, an examination and the badges.")
                        .font(Loam.note(13)).foregroundColor(Loam.inkFaint)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
                BandPicker(titles: ["Lessons", "Glossary", "Examination", "Badges"], index: $section)
                switch section {
                case 0: lessons
                case 1: glossary
                case 2: exam
                default: badges
                }
            }
            .padding(.horizontal, Loam.gutter)
            .padding(.bottom, 28)
        }
        .background(Loam.page.ignoresSafeArea())
        .navigationBarHidden(true)
        .background(
            Group {
                ForEach(Array(Lessons.all.enumerated()), id: \.element.key) { i, lesson in
                    NavigationLink(destination: LessonView(lesson: lesson, index: i).environmentObject(garden), tag: lesson.key, selection: $openLesson) { EmptyView() }
                }
            }
            .hidden()
        )
        .onAppear {
            if !restored {
                restored = true
                if let s = garden.book.uiSection, s >= 0, s < 4 { section = s }
                if let l = garden.book.uiLesson, Lessons.all.contains(where: { $0.key == l }) { openLesson = l }
            }
        }
        .onChange(of: section) { value in garden.remember(section: value) }
        .onChange(of: openLesson) { value in garden.remember(lesson: value) }
        .fullScreenCover(isPresented: $openExam) {
            ExamView { openExam = false }.environmentObject(garden)
        }
        .sheet(item: $openTerm) { term in
            TermSheet(term: term) { openTerm = nil }.environmentObject(garden)
        }
    }

    private var lessons: some View {
        VStack(spacing: 12) {
            ForEach(Array(Lessons.all.enumerated()), id: \.element.key) { i, lesson in
                Button(action: { Tap.light(); openLesson = lesson.key }) {
                    SheetCard(padding: 0) {
                        HStack(spacing: 0) {
                            ThumbBox(name: lesson.plate, height: 96, corner: 0, side: 300).frame(width: 128)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("\(i + 1). \(lesson.title)").font(Loam.title(14.5)).foregroundColor(Loam.ink)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: 4)
                                    if (garden.book.readLessons ?? []).contains(lesson.key) { TickGlyph(size: 14, color: Loam.good) }
                                }
                                Text(lesson.subtitle).font(Loam.note(12)).foregroundColor(Loam.inkFaint)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("\(lesson.text.split(separator: " ").count) words").font(Loam.body(10.5)).foregroundColor(Loam.inkFaint)
                            }
                            .padding(10)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .buttonStyle(.plain)
                .rising(min(i, 6))
            }
        }
    }

    private var glossary: some View {
        SheetCard {
            VStack(alignment: .leading, spacing: 4) {
                HeadRule(text: "Forty-five terms", trailing: "\(garden.termsRead) read")
                ForEach(Glossary.terms) { term in
                    Button(action: { Tap.light(); openTerm = term }) {
                        HStack(alignment: .top, spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(term.term).font(Loam.title(14)).foregroundColor(Loam.ink)
                                Text(term.means).font(Loam.body(12)).foregroundColor(Loam.inkFaint).lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 4)
                            if (garden.book.readTerms ?? []).contains(term.term) { TickGlyph(size: 13, color: Loam.good).padding(.top, 3) }
                        }
                        .padding(.vertical, 6)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Rectangle().fill(Loam.ink.opacity(0.07)).frame(height: 0.7)
                }
            }
        }
    }

    private var exam: some View {
        VStack(spacing: 12) {
            SheetCard {
                VStack(alignment: .leading, spacing: 10) {
                    HeadRule(text: "The examination")
                    Text("Thirty questions drawn from the register and the lessons: which crop goes in first, how many to a square, which family, when to sow relative to the frost, how many days to maturity. The questions about dates use your own frost dates.")
                        .font(Loam.body(13.5)).foregroundColor(Loam.inkSoft).fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 9) {
                        CountTile(value: "\(garden.book.examBest ?? 0)", label: "best score", tone: Loam.prize)
                        CountTile(value: "\(garden.book.examsTaken ?? 0)", label: "sittings")
                        CountTile(value: "80", label: "to pass")
                    }
                    SowButton(title: (garden.book.examsTaken ?? 0) == 0 ? "Sit the examination" : "Sit it again", tone: Loam.leafDeep) { openExam = true }
                }
            }
            .rising(0)
            if (garden.book.examBest ?? 0) >= 80 {
                CertificateView(score: garden.book.examBest ?? 0, name: garden.rank.0).rising(1)
            }
            SheetCard {
                VStack(alignment: .leading, spacing: 9) {
                    HeadRule(text: "The paper asks things like")
                    ForEach(Examiner.paper(seed: Almanac.seed(garden.today) ^ 0x51, count: 4, dates: garden.dates)) { q in
                        HStack(alignment: .top, spacing: 8) {
                            Circle().fill(Loam.terracotta).frame(width: 5, height: 5).padding(.top, 7)
                            Text(q.prompt).font(Loam.body(13.5)).foregroundColor(Loam.inkSoft).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Text("A fresh paper of thirty is drawn for every sitting; the lessons cover every question asked.")
                        .font(Loam.note(12)).foregroundColor(Loam.inkFaint).fixedSize(horizontal: false, vertical: true)
                }
            }
            .rising(2)
        }
    }

    private var badges: some View {
        VStack(spacing: 12) {
            SheetCard {
                VStack(alignment: .leading, spacing: 10) {
                    HeadRule(text: "Badges", trailing: "\((garden.book.badges ?? []).count) of \(Badge.all.count)")
                    ForEach(Badge.all) { badge in
                        let earned = garden.hasBadge(badge.key)
                        HStack(spacing: 12) {
                            BadgeMark(key: badge.key, earned: earned, size: 46)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(badge.name).font(Loam.title(14)).foregroundColor(earned ? Loam.ink : Loam.inkFaint)
                                Text(badge.text).font(Loam.body(12)).foregroundColor(Loam.inkFaint).fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                            if earned { StampTag(text: "earned", tone: Loam.prize) }
                        }
                        .padding(.vertical, 3)
                    }
                }
            }
            .rising(0)
            SheetCard {
                VStack(alignment: .leading, spacing: 8) {
                    HeadRule(text: "The ladder")
                    ForEach(0..<Ladder.steps.count, id: \.self) { i in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(Ladder.steps[i].0)").font(Loam.title(12)).foregroundColor(Loam.terracotta).frame(width: 44, alignment: .trailing)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(Ladder.steps[i].1).font(Loam.title(13.5)).foregroundColor(i <= garden.rankIndex ? Loam.ink : Loam.inkFaint)
                                Text(Ladder.steps[i].2).font(Loam.body(11.5)).foregroundColor(Loam.inkFaint).fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
            .rising(1)
        }
    }
}

struct BadgeMark: View {
    var key: String
    var earned: Bool
    var size: CGFloat
    var body: some View {
        let tone = earned ? Loam.prize : Loam.inkFaint.opacity(0.5)
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(tone.opacity(0.12))
            RoundedRectangle(cornerRadius: 8).stroke(tone, lineWidth: 1.2)
            Group {
                switch key {
                case "firstSowing": SeedGlyph(size: size * 0.5, color: tone)
                case "firstHarvest": ForkGlyph(size: size * 0.55, color: tone)
                case "fullRotation": BedGridMark(size: size * 0.6, color: tone)
                case "fourSeason": SunBedMark(size: size * 0.6, color: tone)
                case "examined": BookMark(size: size * 0.55, color: tone)
                default: JarMark(size: size * 0.6, color: tone)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

struct LessonView: View {
    @EnvironmentObject var garden: FrostGarden
    var lesson: Lesson
    var index: Int

    var body: some View {
        ScrollView {
            Column {
                SheetCard(padding: 6) {
                    PlateBox(name: lesson.plate, height: Loam.isPad ? 420 : 250, fit: true)
                }
                .rising(0)
                SheetCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Lesson \(index + 1)").font(Loam.body(11)).tracking(1.5).foregroundColor(Loam.inkFaint)
                        Text(lesson.title).font(Loam.title(22)).foregroundColor(Loam.ink)
                        Text(lesson.subtitle).font(Loam.note(14)).foregroundColor(Loam.inkSoft)
                        ForEach(Array(lesson.text.components(separatedBy: "\n\n").enumerated()), id: \.offset) { _, para in
                            Text(para).font(Loam.body(15)).foregroundColor(Loam.inkSoft).lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .rising(1)
                if index + 1 < Lessons.all.count {
                    NavigationLink(destination: LessonView(lesson: Lessons.all[index + 1], index: index + 1).environmentObject(garden)) {
                        SheetCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Next").font(Loam.body(11)).foregroundColor(Loam.inkFaint)
                                    Text(Lessons.all[index + 1].title).font(Loam.title(14)).foregroundColor(Loam.ink)
                                }
                                Spacer()
                                ChevGlyph(size: 14, color: Loam.inkFaint, back: false)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Loam.gutter)
            .padding(.bottom, 28)
        }
        .background(Loam.page.ignoresSafeArea())
        .navigationBarTitle(Text(lesson.title), displayMode: .inline)
        .onAppear { garden.markLesson(lesson.key) }
    }
}

struct TermSheet: View {
    @EnvironmentObject var garden: FrostGarden
    var term: Term
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SheetHead(title: term.term, subtitle: "Glossary", onClose: onClose)
            ScrollView {
                Column {
                    SheetCard {
                        Text(term.means).font(Loam.body(15)).foregroundColor(Loam.inkSoft).lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    let related = Register.crops.filter { term.means.lowercased().contains($0.name.lowercased()) || term.term.lowercased().contains($0.name.lowercased()) }.prefix(6)
                    if !related.isEmpty {
                        SheetCard {
                            VStack(alignment: .leading, spacing: 8) {
                                HeadRule(text: "Crops named here")
                                ForEach(Array(related)) { crop in
                                    HStack(spacing: 10) {
                                        PlantGlyph(crop: crop, stage: .mature, growth: 1, size: 34, detail: false)
                                        Text(crop.name).font(Loam.body(13.5)).foregroundColor(Loam.ink)
                                        Spacer()
                                        Text(crop.family.name).font(Loam.note(12)).foregroundColor(Loam.inkFaint)
                                    }
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
        .onAppear { garden.markTerm(term.term) }
    }
}

struct ExamView: View {
    @EnvironmentObject var garden: FrostGarden
    var onClose: () -> Void
    @State private var paper: [ExamQuestion] = []
    @State private var index = 0
    @State private var picked: Int? = nil
    @State private var score = 0
    @State private var finished = false
    @State private var recorded = false

    var body: some View {
        ZStack {
            Loam.page.ignoresSafeArea()
            VStack(spacing: 0) {
                SheetHead(title: finished ? "Result" : "Question \(index + 1) of \(paper.count)", subtitle: finished ? nil : "\(score) right so far", onClose: onClose)
                if paper.isEmpty {
                    Spacer()
                } else if finished {
                    result
                } else {
                    question
                }
            }
        }
        .onAppear {
            if paper.isEmpty {
                paper = Examiner.paper(seed: Almanac.seed(garden.today) ^ UInt64(bitPattern: Int64((garden.book.examsTaken ?? 0) + 1)), count: 30, dates: garden.dates)
            }
        }
    }

    private var question: some View {
        let q = paper[index]
        return ScrollView {
            Column {
                MeterBar(label: "Progress", value: Double(index) / Double(max(1, paper.count)), tone: Loam.leaf)
                SheetCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(q.prompt).font(Loam.title(18)).foregroundColor(Loam.ink).fixedSize(horizontal: false, vertical: true)
                        ForEach(0..<q.options.count, id: \.self) { i in
                            Button(action: { choose(i) }) {
                                HStack(alignment: .top, spacing: 10) {
                                    ZStack {
                                        Circle().stroke(optionTone(i), lineWidth: 1.3).frame(width: 22, height: 22)
                                        if picked == i { Circle().fill(optionTone(i)).frame(width: 12, height: 12) }
                                    }
                                    Text(q.options[i]).font(Loam.body(14.5)).foregroundColor(Loam.ink).fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: 0)
                                }
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: 6).fill(optionTone(i).opacity(picked == i ? 0.12 : 0.04)))
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .disabled(picked != nil)
                        }
                        if let p = picked {
                            NoticeBar(text: q.explanation, tone: p == q.answer ? Loam.good : Loam.warn)
                            SowButton(title: index + 1 < paper.count ? "Next question" : "See the result", tone: Loam.leafDeep) { advance() }
                        }
                    }
                }
            }
            .padding(.horizontal, Loam.gutter)
            .padding(.bottom, 24)
        }
    }

    private func optionTone(_ i: Int) -> Color {
        guard let p = picked else { return Loam.ink.opacity(0.5) }
        if i == paper[index].answer { return Loam.good }
        if i == p { return Loam.bad }
        return Loam.ink.opacity(0.3)
    }

    private func choose(_ i: Int) {
        guard picked == nil else { return }
        withAnimation(.easeOut(duration: 0.2)) { picked = i }
        if i == paper[index].answer { score += 1; Tap.firm() } else { Tap.crisp() }
    }

    private func advance() {
        Tap.light()
        if index + 1 < paper.count {
            withAnimation(.easeOut(duration: 0.2)) { index += 1; picked = nil }
        } else {
            withAnimation { finished = true }
            if !recorded {
                recorded = true
                garden.recordExam(score: score, total: paper.count)
            }
        }
    }

    private var result: some View {
        let pct = score * 100 / max(1, paper.count)
        return ScrollView {
            Column {
                SheetCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(pct >= 80 ? "Passed" : "Not yet").font(Loam.title(24)).foregroundColor(pct >= 80 ? Loam.good : Loam.ink)
                        Text("\(score) of \(paper.count) right, \(pct) percent. \(pct >= 80 ? "The certificate is yours." : "Eighty percent passes; the lessons cover every question asked.")")
                            .font(Loam.body(14)).foregroundColor(Loam.inkSoft).fixedSize(horizontal: false, vertical: true)
                        MeterBar(label: "Score", value: Double(pct) / 100, tone: pct >= 80 ? Loam.good : Loam.warn)
                        SowButton(title: "Close the paper", tone: Loam.leafDeep) { onClose() }
                    }
                }
                if pct >= 80 {
                    CertificateView(score: pct, name: garden.rank.0)
                }
            }
            .padding(.horizontal, Loam.gutter)
            .padding(.bottom, 24)
        }
    }
}

struct CertificateView: View {
    var score: Int
    var name: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6).fill(Loam.card)
            RoundedRectangle(cornerRadius: 6).stroke(Loam.prize, lineWidth: 2).padding(6)
            RoundedRectangle(cornerRadius: 4).stroke(Loam.ink.opacity(0.4), lineWidth: 0.8).padding(11)
            VStack(spacing: 8) {
                Text("LAST FROST").font(Loam.title(11)).tracking(3).foregroundColor(Loam.inkFaint)
                Text("Certificate of Examination").font(Loam.title(20)).foregroundColor(Loam.ink)
                Rectangle().fill(Loam.prize).frame(width: 60, height: 1.5)
                Text("awarded to a").font(Loam.note(13)).foregroundColor(Loam.inkSoft)
                Text(name).font(Loam.title(18)).foregroundColor(Loam.terracotta)
                Text("who answered \(score) percent of the paper on frost dates, spacing, families and sowing times.")
                    .font(Loam.body(12.5)).foregroundColor(Loam.inkSoft).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 12) {
                    SproutGlyph(size: 26, color: Loam.leafDeep)
                    StarGlyph(size: 22, color: Loam.prize)
                    SproutGlyph(size: 26, color: Loam.leafDeep)
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity)
    }
}
