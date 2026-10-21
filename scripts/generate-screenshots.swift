// Renders the App Store (2880x1800) and Product Hunt (2560x1440) slides from docs/screenshots/.
// Run from the repo root: swift scripts/generate-screenshots.swift
import Cocoa
import WebKit

struct Slide {
    let filename: String
    let headline: String
    let source: String
    // Wallpaper colours: deep base, then three light blooms.
    let base: String
    let blooms: [String]
}

struct Target {
    let width: Int
    let height: Int
    let headlineSize: Int
    let paddingTop: Int
    let gap: Int
    let windowWidth: Int
    let outputDirs: [String]
}

let slides = [
    Slide(filename: "01-tabs-and-split.png",
          headline: "Two folders.<br>One window.",
          source: "docs/screenshots/tabs-and-split.png",
          base: "#0A1A4A", blooms: ["#3B82F6", "#22D3EE", "#8B5CF6"]),
    Slide(filename: "02-hover-preview.png",
          headline: "Peek inside any file<br>without opening it",
          source: "docs/screenshots/hover-preview.png",
          base: "#3A0D2E", blooms: ["#F97316", "#F43F5E", "#FBBF24"]),
    Slide(filename: "03-list-view.png",
          headline: "Every file,<br>sized and sorted",
          source: "docs/screenshots/list-view.png",
          base: "#1E1046", blooms: ["#A855F7", "#6366F1", "#EC4899"]),
    Slide(filename: "04-integrated-terminal.png",
          headline: "A terminal that follows<br>your folder",
          source: "docs/screenshots/terminal.png",
          base: "#052E2B", blooms: ["#10B981", "#84CC16", "#06B6D4"]),
]

let targets = [
    Target(width: 1440, height: 900, headlineSize: 56, paddingTop: 64, gap: 40, windowWidth: 1200,
           outputDirs: ["docs/appstore-screenshots", "dist/screenshots"]),
    Target(width: 1280, height: 720, headlineSize: 46, paddingTop: 44, gap: 30, windowWidth: 980,
           outputDirs: ["docs/producthunt", "dist/producthunt"]),
]

func html(_ slide: Slide, _ target: Target, image: String) -> String {
    let b = slide.blooms
    return """
    <!DOCTYPE html><html><head><meta charset="utf-8"><style>
      * { box-sizing: border-box; margin: 0; padding: 0; }
      body {
        width: \(target.width)px; height: \(target.height)px; overflow: hidden;
        display: flex; flex-direction: column; align-items: center;
        padding-top: \(target.paddingTop)px;
        font-family: -apple-system, "SF Pro Display", sans-serif;
        -webkit-font-smoothing: antialiased;
        background:
          radial-gradient(ellipse 70% 55% at 12% 18%, \(b[0]) 0%, transparent 70%),
          radial-gradient(ellipse 60% 50% at 88% 30%, \(b[1]) 0%, transparent 70%),
          radial-gradient(ellipse 90% 60% at 50% 105%, \(b[2]) 0%, transparent 70%),
          \(slide.base);
      }
      /* A soft wave band, like the macOS wallpapers. */
      body::before {
        content: ""; position: absolute; inset: -20%;
        background: radial-gradient(ellipse 60% 22% at 50% 62%, rgba(255,255,255,0.16), transparent 70%);
        transform: rotate(-8deg); filter: blur(30px);
      }
      body::after {
        content: ""; position: absolute; inset: 0;
        background: linear-gradient(180deg, rgba(0,0,0,0.22), transparent 35%);
      }
      h1 {
        position: relative; z-index: 1;
        color: #fff; text-align: center;
        font-size: \(target.headlineSize)px; font-weight: 700;
        letter-spacing: -0.03em; line-height: 1.08;
        text-shadow: 0 2px 24px rgba(0,0,0,0.25);
        margin-bottom: \(target.gap)px;
      }
      img {
        position: relative; z-index: 1;
        width: \(target.windowWidth)px; display: block; border-radius: 12px;
        filter: drop-shadow(0 28px 50px rgba(0,0,0,0.5)) drop-shadow(0 0 1px rgba(0,0,0,0.6));
      }
    </style></head><body>
      <h1>\(slide.headline)</h1>
      <img src="\(image)">
    </body></html>
    """
}

final class Renderer: NSObject, WKNavigationDelegate {
    let jobs: [(Slide, Target)] = targets.flatMap { t in slides.map { ($0, t) } }
    var index = 0
    var webView: WKWebView!

    func start() { renderNext() }

    func renderNext() {
        guard index < jobs.count else { print("Done."); exit(0) }
        let (slide, target) = jobs[index]
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: target.width, height: target.height))
        webView.navigationDelegate = self
        guard let data = FileManager.default.contents(atPath: slide.source) else {
            print("Missing \(slide.source)"); exit(1)
        }
        webView.loadHTMLString(html(slide, target, image: "data:image/png;base64," + data.base64EncodedString()), baseURL: nil)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            webView.takeSnapshot(with: nil) { image, _ in
                guard let tiff = image?.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
                      let png = rep.representation(using: .png, properties: [:]) else {
                    print("Snapshot failed"); exit(1)
                }
                let (slide, target) = self.jobs[self.index]
                for dir in target.outputDirs {
                    try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
                    try? png.write(to: URL(fileURLWithPath: dir).appendingPathComponent(slide.filename))
                }
                print("\(target.outputDirs[0])/\(slide.filename) (\(rep.pixelsWide)x\(rep.pixelsHigh))")
                self.index += 1
                self.renderNext()
            }
        }
    }
}

let app = NSApplication.shared
let renderer = Renderer()
renderer.start()
app.run()
