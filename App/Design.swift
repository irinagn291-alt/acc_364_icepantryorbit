import SwiftUI

enum Paper {
    static let page = Color(red: 0.982, green: 0.966, blue: 0.907)
    static let ink = Color(red: 0.095, green: 0.178, blue: 0.12)
    static let grove = Color(red: 0.12, green: 0.258, blue: 0.18)
    static let moss = Color(red: 0.28, green: 0.37, blue: 0.24)
    static let line = Color(red: 0.81, green: 0.81, blue: 0.71)
    static let sheet = Color(red: 0.945, green: 0.927, blue: 0.852)
    static let berry = Color(red: 0.60, green: 0.20, blue: 0.092)
    static let apricot = Color(red: 0.99, green: 0.70, blue: 0.36)
}

struct Kicker: View {
    var text: String
    init(_ text: String) { self.text = text }
    var body: some View { Text(text.uppercased()).font(.system(.caption2, design: .monospaced).weight(.bold)).tracking(1.5) }
}

struct PantryPrint: View {
    var body: some View {
        Canvas { raw, size in
            var c = raw
            c.scaleBy(x: size.width/160, y: size.height/180)
            let leaf = Color(red: 0.65, green: 0.72, blue: 0.43)
            let mint = Color(red: 0.81, green: 0.84, blue: 0.6)
            func oval(_ rect: CGRect, _ color: Color) { c.fill(Path(ellipseIn: rect), with: .color(color)) }
            func stroke(_ points: [CGPoint], _ color: Color, _ width: CGFloat) {
                var p = Path(); p.addLines(points); c.stroke(p, with: .color(color), lineWidth: width)
            }
            func blade(_ root: CGPoint, _ tip: CGPoint, _ a: CGPoint, _ b: CGPoint, _ color: Color) {
                var p = Path()
                p.move(to: root); p.addQuadCurve(to: tip, control: a); p.addQuadCurve(to: root, control: b)
                c.fill(p, with: .color(color))
            }
            // Linocut sprigs behind a ribbed preserve jar.
            stroke([.init(x: 99,y: 140),.init(x: 118,y: 74),.init(x: 137,y: 14)], mint, 2)
            for i in 0..<5 {
                let x = CGFloat(112+i*5), y = CGFloat(99-i*16)
                blade(.init(x:x,y:y), .init(x:x-19,y:y-29), .init(x:x-17,y:y-1), .init(x:x-2,y:y-22), leaf)
                blade(.init(x:x+2,y:y-4), .init(x:x+24,y:y-23), .init(x:x+7,y:y-23), .init(x:x+21,y:y-8), mint)
            }
            oval(CGRect(x:8,y:153,width:141,height:7), .black.opacity(0.17))
            var jar = Path()
            jar.move(to: .init(x:41,y:74)); jar.addLine(to:.init(x:86,y:74))
            jar.addQuadCurve(to:.init(x:94,y:92), control:.init(x:87,y:84))
            jar.addLine(to:.init(x:94,y:145)); jar.addQuadCurve(to:.init(x:84,y:153), control:.init(x:94,y:153))
            jar.addLine(to:.init(x:39,y:153)); jar.addQuadCurve(to:.init(x:32,y:145), control:.init(x:32,y:153))
            jar.addLine(to:.init(x:32,y:92)); jar.addQuadCurve(to:.init(x:41,y:74), control:.init(x:40,y:82))
            c.fill(jar, with:.color(Paper.apricot))
            c.fill(Path(roundedRect:CGRect(x:38,y:66,width:52,height:11),cornerRadius:3), with:.color(mint))
            for x in stride(from:42,through:86,by:5) { stroke([.init(x:x,y:68),.init(x:x,y:75)], Paper.grove.opacity(0.6), 1) }
            c.fill(Path(roundedRect:CGRect(x:36,y:98,width:55,height:40),cornerRadius:2), with:.color(Paper.page))
            oval(CGRect(x:50,y:104,width:25,height:25), Paper.berry)
            stroke([.init(x:62,y:109),.init(x:67,y:102),.init(x:72,y:102)], Paper.grove, 2)
            stroke([.init(x:39,y:86),.init(x:38,y:94)], Paper.page, 1.5)
            for x in stride(from:40,through:85,by:6) { stroke([.init(x:x,y:145),.init(x:x+2,y:142)], Paper.berry, 1) }
            blade(.init(x:15,y:150),.init(x:7,y:117),.init(x:0,y:133),.init(x:20,y:128),leaf)
            blade(.init(x:16,y:150),.init(x:28,y:120),.init(x:31,y:140),.init(x:15,y:132),mint)
        }.accessibilityHidden(true)
    }
}

struct LedgerHeader: View {
    var title: String
    var index: String
    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                HStack(spacing: 5) { Image(systemName: "leaf.fill"); Kicker("IcePantryOrbit") }
                Spacer()
                Kicker("Folio " + index)
            }.foregroundStyle(Paper.moss)
            Rectangle().fill(Paper.ink).frame(height: 1)
            Text(title).font(.system(.largeTitle, design: .serif).weight(.semibold))
        }
    }
}

struct SectionTitle: View {
    var title: String
    var detail: String
    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            Text(title).font(.system(.title2, design: .serif).weight(.semibold))
            Spacer()
            Kicker(detail).foregroundStyle(Paper.moss)
        }
    }
}

struct PaperEmpty: View {
    var symbol: String
    var title: String
    var detail: String
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol).font(.title2).foregroundStyle(Paper.moss).frame(width: 35)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(Paper.moss)
            }
            Spacer(minLength: 0)
        }.padding(16).background(Paper.sheet, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct JournalButton: ButtonStyle {
    var bodyColor: Color = Paper.grove
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).frame(maxWidth: .infinity).padding(.vertical,14)
            .foregroundStyle(.white).background(bodyColor, in: RoundedRectangle(cornerRadius: 12))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}
