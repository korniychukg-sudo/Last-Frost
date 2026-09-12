import SwiftUI
import ImageIO

enum Plates {
    private static var cache: [String: UIImage] = [:]

    static func load(_ name: String) -> UIImage? {
        if let hit = cache[name] { return hit }
        guard let path = Bundle.main.path(forResource: name, ofType: "jpg", inDirectory: "Art"),
              let image = UIImage(contentsOfFile: path) else { return nil }
        if cache.count > 40 { cache.removeAll() }
        cache[name] = image
        return image
    }

    static func exists(_ name: String) -> Bool {
        Bundle.main.path(forResource: name, ofType: "jpg", inDirectory: "Art") != nil
    }

    private static var thumbs: [String: UIImage] = [:]

    static func thumb(_ name: String, side: CGFloat = 360) -> UIImage? {
        let key = name + "@\(Int(side))"
        if let hit = thumbs[key] { return hit }
        guard let path = Bundle.main.path(forResource: name, ofType: "jpg", inDirectory: "Art"),
              let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                        kCGImageSourceThumbnailMaxPixelSize: Int(side * UIScreen.main.scale),
                                        kCGImageSourceCreateThumbnailWithTransform: true]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        let image = UIImage(cgImage: cg)
        if thumbs.count > 160 { thumbs.removeAll() }
        thumbs[key] = image
        return image
    }
}

struct ThumbBox: View {
    let name: String
    var height: CGFloat
    var corner: CGFloat = 5
    var side: CGFloat = 360

    var body: some View {
        Color.clear
            .overlay(
                Group {
                    if let image = Plates.thumb(name, side: side) {
                        Image(uiImage: image).resizable().scaledToFill()
                    } else {
                        Loam.pageDeep
                    }
                }
            )
            .frame(height: height)
            .clipped()
            .cornerRadius(corner)
            .overlay(RoundedRectangle(cornerRadius: corner).stroke(Loam.ink.opacity(0.16), lineWidth: 0.8))
    }
}

struct PlateBox: View {
    let name: String
    var height: CGFloat
    var corner: CGFloat = 5
    var fit: Bool = false

    var body: some View {
        Color.clear
            .overlay(
                Group {
                    if let image = Plates.load(name) {
                        if fit {
                            Image(uiImage: image).resizable().scaledToFit()
                        } else {
                            Image(uiImage: image).resizable().scaledToFill()
                        }
                    } else {
                        Loam.pageDeep
                    }
                }
            )
            .frame(height: height)
            .clipped()
            .cornerRadius(corner)
            .overlay(
                RoundedRectangle(cornerRadius: corner)
                    .stroke(Loam.ink.opacity(0.16), lineWidth: 0.8)
            )
    }
}

struct SheetCard<Content: View>: View {
    var padding: CGFloat = 15
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(Loam.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 7)
                            .stroke(Loam.ink.opacity(0.13), lineWidth: 0.9)
                    )
                    .shadow(color: Loam.ink.opacity(0.07), radius: 5, x: 0, y: 3)
            )
    }
}

struct HeadRule: View {
    let text: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 9) {
            Text(text.uppercased())
                .font(Loam.title(11.5))
                .tracking(1.6)
                .foregroundColor(Loam.inkSoft)
                .fixedSize(horizontal: true, vertical: false)
            Rectangle()
                .fill(Loam.ink.opacity(0.17))
                .frame(height: 0.8)
            if let trailing = trailing {
                Text(trailing)
                    .font(Loam.body(11.5))
                    .foregroundColor(Loam.inkFaint)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
    }
}

struct SowButton: View {
    let title: String
    var tone: Color = Loam.ink
    var filled: Bool = true
    var enabled: Bool = true
    var action: () -> Void

    var body: some View {
        Button(action: { if enabled { Tap.light(); action() } }) {
            Text(title)
                .font(Loam.title(15))
                .foregroundColor(filled ? Loam.card : tone)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(filled ? tone : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(tone.opacity(filled ? 0 : 0.55), lineWidth: 1.1)
                        )
                )
                .opacity(enabled ? 1 : 0.42)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

struct MeterBar: View {
    var label: String
    var value: Double
    var tone: Color = Loam.leaf
    var caption: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label).font(Loam.body(12.5)).foregroundColor(Loam.inkSoft)
                Spacer()
                Text("\(Int(min(1, max(0, value)) * 100))")
                    .font(Loam.title(12.5)).foregroundColor(Loam.ink)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Loam.ink.opacity(0.10))
                    Capsule().fill(tone)
                        .frame(width: max(2, geo.size.width * CGFloat(min(1, max(0, value)))))
                }
            }
            .frame(height: 6)
            if let caption = caption {
                Text(caption).font(Loam.note(11)).foregroundColor(Loam.inkFaint)
            }
        }
    }
}

struct NoticeBar: View {
    var text: String
    var tone: Color = Loam.warn
    var action: (String, () -> Void)? = nil

    var body: some View {
        HStack(spacing: 11) {
            Rectangle().fill(tone).frame(width: 3)
            Text(text)
                .font(Loam.body(12.5))
                .foregroundColor(Loam.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
            if let action = action {
                Button(action: { Tap.light(); action.1() }) {
                    Text(action.0)
                        .font(Loam.title(11.5))
                        .foregroundColor(tone)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .overlay(RoundedRectangle(cornerRadius: 4)
                                    .stroke(tone.opacity(0.6), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 6).fill(tone.opacity(0.09)))
    }
}

struct SheetHead: View {
    var title: String
    var subtitle: String? = nil
    var onClose: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(Loam.title(19)).foregroundColor(Loam.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle = subtitle {
                    Text(subtitle).font(Loam.note(12.5)).foregroundColor(Loam.inkFaint)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 10)
            Button(action: { Tap.light(); onClose() }) {
                CrossGlyph(size: 16, color: Loam.inkSoft)
                    .padding(9)
                    .background(Circle().fill(Loam.ink.opacity(0.07)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Loam.gutter)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }
}

struct CountTile: View {
    var value: String
    var label: String
    var tone: Color = Loam.ink

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(Loam.title(17))
                .foregroundColor(tone)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label.uppercased())
                .font(Loam.body(8.5))
                .tracking(1.0)
                .foregroundColor(Loam.inkFaint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: 6).fill(Loam.ink.opacity(0.045)))
    }
}

struct StampTag: View {
    var text: String
    var tone: Color
    var body: some View {
        Text(text.uppercased())
            .font(Loam.title(9.5))
            .tracking(1.3)
            .foregroundColor(tone)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(tone.opacity(0.7), lineWidth: 1))
    }
}

struct Column<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            VStack(spacing: 15) { content() }
                .frame(maxWidth: Loam.isPad ? 700 : .infinity)
            Spacer(minLength: 0)
        }
    }
}

struct BandPicker: View {
    var titles: [String]
    @Binding var index: Int
    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(titles.enumerated()), id: \.offset) { i, title in
                Button(action: { Tap.light(); withAnimation(.easeOut(duration: 0.2)) { index = i } }) {
                    Text(title)
                        .font(Loam.title(11))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .foregroundColor(index == i ? Loam.card : Loam.inkSoft)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 5)
                                        .fill(index == i ? Loam.ink : Loam.ink.opacity(0.06)))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct NoteLine: View {
    var text: String
    var size: CGFloat = 14
    var body: some View {
        Text(text)
            .font(Loam.note(size))
            .foregroundColor(Loam.ink)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.leading)
    }
}

struct FactRow: View {
    var label: String
    var value: String
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label.uppercased())
                .font(Loam.body(9.5)).tracking(1.1)
                .foregroundColor(Loam.inkFaint)
                .frame(width: 96, alignment: .leading)
            Text(value).font(Loam.body(13.5)).foregroundColor(Loam.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}

struct SmallChip: View {
    var text: String
    var tone: Color
    var body: some View {
        Text(text)
            .font(Loam.body(11.5))
            .foregroundColor(tone)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(tone.opacity(0.12)))
    }
}

struct CloseBar: View {
    var title: String
    var onClose: () -> Void
    var body: some View {
        HStack {
            Text(title).font(Loam.title(17)).foregroundColor(Loam.ink)
            Spacer()
            Button(action: { Tap.light(); onClose() }) {
                CrossGlyph(size: 15, color: Loam.inkSoft)
                    .padding(8)
                    .background(Circle().fill(Loam.ink.opacity(0.07)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Loam.gutter)
        .padding(.vertical, 12)
    }
}
