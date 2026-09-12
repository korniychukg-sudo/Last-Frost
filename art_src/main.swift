import Foundation
import CoreGraphics
import ImageIO

let args = CommandLine.arguments
let outDir = args.count > 1 ? args[1] : "Art"
let job = args.count > 2 ? args[2] : "all"
let extra = args.count > 3 ? args[3] : ""

try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

func wants(_ name: String) -> Bool { job == "all" || job == name }

let started = Date()
var made = 0

func note(_ text: String) {
    let elapsed = Int(Date().timeIntervalSince(started))
    print("[\(elapsed)s] \(text)")
}

func loadImage(_ path: String) -> CGImage? {
    guard let src = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(src, 0, nil)
}

func contactSheet(names: [String], labels: [String], columns: Int, tile: Double, aspect: Double, out: String, file: String) {
    let previous = sheetScale
    sheetScale = 1.0
    let rows = Int(ceil(Double(names.count) / Double(columns)))
    let tileH = tile * aspect
    let sheet = Leaf(Int(Double(columns) * (tile + 10) + 10), Int(Double(rows) * (tileH + 34) + 10))
    sheet.fillAll(Hue(r: 0.25, g: 0.25, b: 0.25))
    sheet.flipDown()
    for (k, name) in names.enumerated() {
        let col = k % columns, row = k / columns
        let x = 10 + Double(col) * (tile + 10), y = 10 + Double(row) * (tileH + 34)
        if let img = loadImage(outDir + "/" + name + ".jpg") {
            sheet.ctx.saveGState()
            sheet.ctx.translateBy(x: CGFloat(x), y: CGFloat(y + tileH))
            sheet.ctx.scaleBy(x: 1, y: -1)
            sheet.ctx.draw(img, in: CGRect(x: 0, y: 0, width: tile, height: tileH))
            sheet.ctx.restoreGState()
        }
        letter(sheet, labels[k], at: x + tile / 2, y + tileH + 22, size: 16, colour: Hue(r: 1, g: 1, b: 1), face: "Baskerville", align: .centre)
    }
    sheet.writeJPG(out, file, quality: 0.8)
    sheetScale = previous
}

if job == "icon" {
    drawIcon(outDir)
    note("icon written to \(outDir)")
    exit(0)
}

if job == "probe" {
    let prefix = extra.isEmpty ? "cr_" : extra
    let contactDir = args.count > 4 ? args[4] : outDir
    let files = ((try? FileManager.default.contentsOfDirectory(atPath: outDir)) ?? []).filter { $0.hasPrefix(prefix) && $0.hasSuffix(".jpg") }.sorted()
    let names = files.map { String($0.dropLast(4)) }
    let portrait = prefix == "cr_"
    contactSheet(names: names, labels: names, columns: portrait ? 4 : 3, tile: portrait ? 420 : 520, aspect: portrait ? 1.333 : 0.75, out: contactDir, file: "contact_probe_" + prefix.replacingOccurrences(of: "_", with: ""))
    note("probe sheet written")
    exit(0)
}

if job == "contact" {
    let contactDir = extra.isEmpty ? outDir : extra
    let crops = Register.crops
    contactSheet(names: Array(crops.prefix(30)).map { $0.plate }, labels: Array(crops.prefix(30)).map { $0.name }, columns: 6, tile: 300, aspect: 1.333, out: contactDir, file: "contact_crops1")
    contactSheet(names: Array(crops.suffix(30)).map { $0.plate }, labels: Array(crops.suffix(30)).map { $0.name }, columns: 6, tile: 300, aspect: 1.333, out: contactDir, file: "contact_crops2")
    contactSheet(names: CropFamily.allCases.map { $0.plate }, labels: CropFamily.allCases.map { $0.name }, columns: 4, tile: 360, aspect: 0.75, out: contactDir, file: "contact_families")
    contactSheet(names: lessonKeys.map { "ls_" + $0 }, labels: lessonKeys, columns: 4, tile: 360, aspect: 0.75, out: contactDir, file: "contact_lessons")
    var sceneNames: [String] = []
    var sceneLabels: [String] = []
    for s in ["wi", "sp", "su", "au"] { for h in 0..<7 { sceneNames.append("pl_\(s)\(h)"); sceneLabels.append("\(s) \(h)") } }
    contactSheet(names: sceneNames, labels: sceneLabels, columns: 7, tile: 260, aspect: 0.6, out: contactDir, file: "contact_scenes")
    var misc: [String] = []
    var miscLabels: [String] = []
    for k in 0..<4 { misc.append("se_\(k)"); miscLabels.append("season \(k)") }
    for k in 0..<4 { misc.append("ob_p\(k)"); miscLabels.append("onboard \(k)") }
    for k in 0..<6 { misc.append("sh_\(k)"); miscLabels.append("shelf \(k)") }
    contactSheet(names: misc, labels: miscLabels, columns: 4, tile: 360, aspect: 0.75, out: contactDir, file: "contact_misc")
    note("contact sheets written to \(contactDir)")
    exit(0)
}

sheetScale = 1.42

if wants("crops") {
    let only = extra
    for crop in Register.crops where only.isEmpty || only.split(separator: ",").map(String.init).contains(crop.key) {
        drawCropPlate(crop, dir: outDir)
        made += 1
    }
    note("crops: \(made)")
}

if wants("families") {
    for family in CropFamily.allCases {
        drawFamilyPlate(family, dir: outDir)
        made += 1
    }
    note("families done: \(made)")
}

if wants("lessons") {
    for (i, key) in lessonKeys.enumerated() {
        drawLessonPlate(i, key, dir: outDir)
        made += 1
    }
    note("lessons done: \(made)")
}

if wants("scenes") {
    for s in 0..<4 {
        for h in 0..<7 {
            drawScenePlate(season: s, slot: h, dir: outDir)
            made += 1
        }
    }
    note("scenes done: \(made)")
}

if wants("misc") {
    for s in 0..<4 {
        drawSeasonPlate(s, dir: outDir)
        made += 1
    }
    for k in 0..<4 {
        drawOnboardPlate(k, dir: outDir)
        made += 1
    }
    for k in 0..<6 {
        drawShelfPlate(k, dir: outDir)
        made += 1
    }
    note("misc done: \(made)")
}

note("wrote \(made) plates into \(outDir)")
