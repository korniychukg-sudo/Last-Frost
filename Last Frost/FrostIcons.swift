import SwiftUI

struct SunBedMark: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            var sun = Path()
            sun.addArc(center: CGPoint(x: w * 0.5, y: h * 0.50), radius: CGFloat(w * 0.20),
                       startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
            sun.closeSubpath()
            ctx.fill(sun, with: .color(color.opacity(0.85)))
            for k in 0..<5 {
                let a = Double.pi + Double(k) / 4 * Double.pi
                var ray = Path()
                ray.move(to: CGPoint(x: w * 0.5 + cos(a) * w * 0.27, y: h * 0.50 + sin(a) * w * 0.27))
                ray.addLine(to: CGPoint(x: w * 0.5 + cos(a) * w * 0.36, y: h * 0.50 + sin(a) * w * 0.36))
                ctx.stroke(ray, with: .color(color), style: StrokeStyle(lineWidth: w * 0.06, lineCap: .round))
            }
            ctx.fill(Path(CGRect(x: w * 0.08, y: h * 0.56, width: w * 0.84, height: h * 0.08)),
                     with: .color(color))
            ctx.fill(Path(roundedRect: CGRect(x: w * 0.12, y: h * 0.66, width: w * 0.76, height: h * 0.22),
                          cornerRadius: w * 0.03), with: .color(color.opacity(0.55)))
            var sprout = Path()
            sprout.move(to: CGPoint(x: w * 0.5, y: h * 0.86))
            sprout.addLine(to: CGPoint(x: w * 0.5, y: h * 0.68))
            ctx.stroke(sprout, with: .color(color), style: StrokeStyle(lineWidth: w * 0.05, lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

struct BedGridMark: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            let r = CGRect(x: w * 0.12, y: h * 0.16, width: w * 0.76, height: h * 0.68)
            ctx.fill(Path(roundedRect: r, cornerRadius: w * 0.04), with: .color(color.opacity(0.18)))
            ctx.stroke(Path(roundedRect: r, cornerRadius: w * 0.04), with: .color(color), lineWidth: w * 0.07)
            for k in 1..<3 {
                var v = Path()
                v.move(to: CGPoint(x: r.minX + r.width * CGFloat(k) / 3, y: r.minY))
                v.addLine(to: CGPoint(x: r.minX + r.width * CGFloat(k) / 3, y: r.maxY))
                ctx.stroke(v, with: .color(color), lineWidth: w * 0.045)
            }
            var hz = Path()
            hz.move(to: CGPoint(x: r.minX, y: r.midY))
            hz.addLine(to: CGPoint(x: r.maxX, y: r.midY))
            ctx.stroke(hz, with: .color(color), lineWidth: w * 0.045)
            for (i, j) in [(0, 0), (2, 1), (1, 1)] {
                let cx = r.minX + r.width * (CGFloat(i) + 0.5) / 3
                let cy = r.minY + r.height * (CGFloat(j) + 0.5) / 2
                ctx.fill(Path(ellipseIn: CGRect(x: cx - w * 0.055, y: cy - w * 0.055, width: w * 0.11, height: w * 0.11)),
                         with: .color(color.opacity(0.9)))
            }
        }
        .frame(width: size, height: size)
    }
}

struct PacketMark: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            var packet = Path()
            packet.move(to: CGPoint(x: w * 0.22, y: h * 0.12))
            packet.addLine(to: CGPoint(x: w * 0.78, y: h * 0.12))
            packet.addLine(to: CGPoint(x: w * 0.78, y: h * 0.88))
            packet.addLine(to: CGPoint(x: w * 0.22, y: h * 0.88))
            packet.closeSubpath()
            ctx.fill(packet, with: .color(color.opacity(0.16)))
            ctx.stroke(packet, with: .color(color), lineWidth: w * 0.07)
            var flap = Path()
            flap.move(to: CGPoint(x: w * 0.22, y: h * 0.24))
            flap.addLine(to: CGPoint(x: w * 0.78, y: h * 0.24))
            ctx.stroke(flap, with: .color(color), lineWidth: w * 0.045)
            var leaf = Path()
            leaf.move(to: CGPoint(x: w * 0.50, y: h * 0.76))
            leaf.addQuadCurve(to: CGPoint(x: w * 0.66, y: h * 0.42), control: CGPoint(x: w * 0.70, y: h * 0.66))
            leaf.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.76), control: CGPoint(x: w * 0.44, y: h * 0.50))
            ctx.fill(leaf, with: .color(color.opacity(0.85)))
            var leaf2 = Path()
            leaf2.move(to: CGPoint(x: w * 0.50, y: h * 0.76))
            leaf2.addQuadCurve(to: CGPoint(x: w * 0.34, y: h * 0.48), control: CGPoint(x: w * 0.30, y: h * 0.70))
            leaf2.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.76), control: CGPoint(x: w * 0.54, y: h * 0.56))
            ctx.fill(leaf2, with: .color(color.opacity(0.6)))
        }
        .frame(width: size, height: size)
    }
}

struct JarMark: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            ctx.fill(Path(roundedRect: CGRect(x: w * 0.30, y: h * 0.10, width: w * 0.40, height: h * 0.12),
                          cornerRadius: w * 0.03), with: .color(color))
            var jar = Path()
            jar.move(to: CGPoint(x: w * 0.30, y: h * 0.24))
            jar.addLine(to: CGPoint(x: w * 0.70, y: h * 0.24))
            jar.addQuadCurve(to: CGPoint(x: w * 0.78, y: h * 0.36), control: CGPoint(x: w * 0.78, y: h * 0.26))
            jar.addLine(to: CGPoint(x: w * 0.78, y: h * 0.82))
            jar.addQuadCurve(to: CGPoint(x: w * 0.70, y: h * 0.90), control: CGPoint(x: w * 0.78, y: h * 0.90))
            jar.addLine(to: CGPoint(x: w * 0.30, y: h * 0.90))
            jar.addQuadCurve(to: CGPoint(x: w * 0.22, y: h * 0.82), control: CGPoint(x: w * 0.22, y: h * 0.90))
            jar.addLine(to: CGPoint(x: w * 0.22, y: h * 0.36))
            jar.addQuadCurve(to: CGPoint(x: w * 0.30, y: h * 0.24), control: CGPoint(x: w * 0.22, y: h * 0.26))
            jar.closeSubpath()
            ctx.fill(jar, with: .color(color.opacity(0.18)))
            ctx.stroke(jar, with: .color(color), lineWidth: w * 0.065)
            ctx.fill(Path(CGRect(x: w * 0.26, y: h * 0.52, width: w * 0.48, height: h * 0.34)),
                     with: .color(color.opacity(0.55)))
        }
        .frame(width: size, height: size)
    }
}

struct BookMark: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            ctx.stroke(Path(CGRect(x: w * 0.18, y: h * 0.16, width: w * 0.64, height: h * 0.68)),
                       with: .color(color), lineWidth: w * 0.070)
            ctx.fill(Path(CGRect(x: w * 0.14, y: h * 0.16, width: w * 0.07, height: h * 0.68)),
                     with: .color(color))
            for k in 0..<3 {
                let y = h * (0.34 + Double(k) * 0.16)
                ctx.fill(Path(CGRect(x: w * 0.30, y: y, width: w * 0.40, height: h * 0.055)),
                         with: .color(color.opacity(0.66)))
            }
            ctx.fill(Path(CGRect(x: w * 0.62, y: h * 0.16, width: w * 0.09, height: h * 0.30)),
                     with: .color(color.opacity(0.85)))
        }
        .frame(width: size, height: size)
    }
}

struct CrossGlyph: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            var p = Path()
            p.move(to: CGPoint(x: w * 0.24, y: h * 0.24))
            p.addLine(to: CGPoint(x: w * 0.76, y: h * 0.76))
            p.move(to: CGPoint(x: w * 0.76, y: h * 0.24))
            p.addLine(to: CGPoint(x: w * 0.24, y: h * 0.76))
            ctx.stroke(p, with: .color(color),
                       style: StrokeStyle(lineWidth: w * 0.12, lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

struct ChevGlyph: View {
    var size: CGFloat
    var color: Color
    var back: Bool = true
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            var p = Path()
            if back {
                p.move(to: CGPoint(x: w * 0.64, y: h * 0.20))
                p.addLine(to: CGPoint(x: w * 0.34, y: h * 0.50))
                p.addLine(to: CGPoint(x: w * 0.64, y: h * 0.80))
            } else {
                p.move(to: CGPoint(x: w * 0.36, y: h * 0.20))
                p.addLine(to: CGPoint(x: w * 0.66, y: h * 0.50))
                p.addLine(to: CGPoint(x: w * 0.36, y: h * 0.80))
            }
            ctx.stroke(p, with: .color(color),
                       style: StrokeStyle(lineWidth: w * 0.13, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

struct TickGlyph: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            var p = Path()
            p.move(to: CGPoint(x: w * 0.20, y: h * 0.52))
            p.addLine(to: CGPoint(x: w * 0.42, y: h * 0.74))
            p.addLine(to: CGPoint(x: w * 0.80, y: h * 0.26))
            ctx.stroke(p, with: .color(color),
                       style: StrokeStyle(lineWidth: w * 0.13, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

struct PlusGlyph: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            var p = Path()
            p.move(to: CGPoint(x: w * 0.50, y: h * 0.20))
            p.addLine(to: CGPoint(x: w * 0.50, y: h * 0.80))
            p.move(to: CGPoint(x: w * 0.20, y: h * 0.50))
            p.addLine(to: CGPoint(x: w * 0.80, y: h * 0.50))
            ctx.stroke(p, with: .color(color),
                       style: StrokeStyle(lineWidth: w * 0.12, lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

struct GearGlyph: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            let c = CGPoint(x: w * 0.5, y: h * 0.5)
            for k in 0..<8 {
                let a = Double(k) / 8 * 2 * Double.pi
                var tooth = Path()
                tooth.move(to: c)
                tooth.addLine(to: CGPoint(x: c.x + cos(a) * w * 0.42, y: c.y + sin(a) * w * 0.42))
                ctx.stroke(tooth, with: .color(color), style: StrokeStyle(lineWidth: w * 0.11, lineCap: .round))
            }
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - w * 0.26, y: c.y - w * 0.26, width: w * 0.52, height: w * 0.52)),
                     with: .color(color))
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - w * 0.11, y: c.y - w * 0.11, width: w * 0.22, height: w * 0.22)),
                     with: .color(Loam.card))
        }
        .frame(width: size, height: size)
    }
}

struct DropGlyph: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            var p = Path()
            p.move(to: CGPoint(x: w * 0.50, y: h * 0.12))
            p.addQuadCurve(to: CGPoint(x: w * 0.78, y: h * 0.60), control: CGPoint(x: w * 0.76, y: h * 0.34))
            p.addArc(center: CGPoint(x: w * 0.50, y: h * 0.60), radius: CGFloat(w * 0.28),
                     startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
            p.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.12), control: CGPoint(x: w * 0.24, y: h * 0.34))
            ctx.fill(p, with: .color(color))
        }
        .frame(width: size, height: size)
    }
}

struct SproutGlyph: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            var stem = Path()
            stem.move(to: CGPoint(x: w * 0.5, y: h * 0.90))
            stem.addQuadCurve(to: CGPoint(x: w * 0.52, y: h * 0.40), control: CGPoint(x: w * 0.44, y: h * 0.66))
            ctx.stroke(stem, with: .color(color), style: StrokeStyle(lineWidth: w * 0.07, lineCap: .round))
            var l1 = Path()
            l1.move(to: CGPoint(x: w * 0.52, y: h * 0.42))
            l1.addQuadCurve(to: CGPoint(x: w * 0.84, y: h * 0.26), control: CGPoint(x: w * 0.80, y: h * 0.50))
            l1.addQuadCurve(to: CGPoint(x: w * 0.52, y: h * 0.42), control: CGPoint(x: w * 0.60, y: h * 0.20))
            ctx.fill(l1, with: .color(color))
            var l2 = Path()
            l2.move(to: CGPoint(x: w * 0.50, y: h * 0.44))
            l2.addQuadCurve(to: CGPoint(x: w * 0.16, y: h * 0.30), control: CGPoint(x: w * 0.20, y: h * 0.54))
            l2.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.44), control: CGPoint(x: w * 0.40, y: h * 0.22))
            ctx.fill(l2, with: .color(color.opacity(0.8)))
        }
        .frame(width: size, height: size)
    }
}

struct FrostGlyph: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            let c = CGPoint(x: w * 0.5, y: h * 0.5)
            for k in 0..<6 {
                let a = Double(k) / 6 * 2 * Double.pi
                var arm = Path()
                arm.move(to: c)
                let tip = CGPoint(x: c.x + cos(a) * w * 0.40, y: c.y + sin(a) * w * 0.40)
                arm.addLine(to: tip)
                let mid = CGPoint(x: c.x + cos(a) * w * 0.26, y: c.y + sin(a) * w * 0.26)
                arm.move(to: mid)
                arm.addLine(to: CGPoint(x: mid.x + cos(a + 0.6) * w * 0.12, y: mid.y + sin(a + 0.6) * w * 0.12))
                arm.move(to: mid)
                arm.addLine(to: CGPoint(x: mid.x + cos(a - 0.6) * w * 0.12, y: mid.y + sin(a - 0.6) * w * 0.12))
                ctx.stroke(arm, with: .color(color), style: StrokeStyle(lineWidth: w * 0.07, lineCap: .round))
            }
        }
        .frame(width: size, height: size)
    }
}

struct CanGlyph: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            let bodyRect = CGRect(x: w * 0.26, y: h * 0.38, width: w * 0.42, height: h * 0.46)
            ctx.fill(Path(roundedRect: bodyRect, cornerRadius: w * 0.04), with: .color(color))
            var spout = Path()
            spout.move(to: CGPoint(x: w * 0.30, y: h * 0.52))
            spout.addLine(to: CGPoint(x: w * 0.08, y: h * 0.26))
            ctx.stroke(spout, with: .color(color), style: StrokeStyle(lineWidth: w * 0.09, lineCap: .round))
            var handle = Path()
            handle.addArc(center: CGPoint(x: w * 0.70, y: h * 0.50), radius: CGFloat(w * 0.16),
                          startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
            ctx.stroke(handle, with: .color(color), style: StrokeStyle(lineWidth: w * 0.07, lineCap: .round))
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.02, y: h * 0.18, width: w * 0.14, height: h * 0.10)),
                     with: .color(color))
            for k in 0..<3 {
                let x = w * (0.02 + Double(k) * 0.06)
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: h * (0.06 - Double(k) * 0.01), width: w * 0.04, height: h * 0.06)),
                         with: .color(color.opacity(0.7)))
            }
        }
        .frame(width: size, height: size)
    }
}

struct SeedGlyph: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            var seed = Path()
            seed.move(to: CGPoint(x: w * 0.50, y: h * 0.14))
            seed.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.86), control: CGPoint(x: w * 0.92, y: h * 0.50))
            seed.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.14), control: CGPoint(x: w * 0.08, y: h * 0.50))
            ctx.fill(seed, with: .color(color))
            var line = Path()
            line.move(to: CGPoint(x: w * 0.50, y: h * 0.22))
            line.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.78), control: CGPoint(x: w * 0.38, y: h * 0.50))
            ctx.stroke(line, with: .color(Loam.card.opacity(0.7)), lineWidth: w * 0.05)
        }
        .frame(width: size, height: size)
    }
}

struct ForkGlyph: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            var handle = Path()
            handle.move(to: CGPoint(x: w * 0.50, y: h * 0.08))
            handle.addLine(to: CGPoint(x: w * 0.50, y: h * 0.56))
            ctx.stroke(handle, with: .color(color), style: StrokeStyle(lineWidth: w * 0.09, lineCap: .round))
            ctx.fill(Path(roundedRect: CGRect(x: w * 0.24, y: h * 0.52, width: w * 0.52, height: h * 0.12), cornerRadius: w * 0.03),
                     with: .color(color))
            for k in 0..<4 {
                let x = w * (0.28 + Double(k) * 0.147)
                var tine = Path()
                tine.move(to: CGPoint(x: x, y: h * 0.62))
                tine.addLine(to: CGPoint(x: x, y: h * 0.92))
                ctx.stroke(tine, with: .color(color), style: StrokeStyle(lineWidth: w * 0.06, lineCap: .round))
            }
        }
        .frame(width: size, height: size)
    }
}

struct StarGlyph: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            var p = Path()
            for k in 0..<10 {
                let a = -Double.pi / 2 + Double(k) / 10 * 2 * Double.pi
                let r = k % 2 == 0 ? w * 0.44 : w * 0.19
                let q = CGPoint(x: w * 0.5 + cos(a) * r, y: h * 0.5 + sin(a) * r)
                if k == 0 { p.move(to: q) } else { p.addLine(to: q) }
            }
            p.closeSubpath()
            ctx.fill(p, with: .color(color))
        }
        .frame(width: size, height: size)
    }
}
