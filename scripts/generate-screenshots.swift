import Cocoa
import WebKit

struct ScreenshotConfig {
    let filename: String
    let badge: String
    let badgeColor: String
    let headline: String
    let subheadline: String
    let glowColor: String
    let sourceImage: String
}

let configs: [ScreenshotConfig] = [
    ScreenshotConfig(
        filename: "01-tabs-and-split.png",
        badge: "Workspace Freedom",
        badgeColor: "#60a5fa",
        headline: "Two locations side by side. Infinite tabs.",
        subheadline: "Compare folders, drag files across workspaces, and restore your session whenever you return.",
        glowColor: "rgba(56, 138, 255, 0.22)",
        sourceImage: "docs/screenshots/tabs-and-split.png"
    ),
    ScreenshotConfig(
        filename: "02-hover-preview.png",
        badge: "Instant Previews",
        badgeColor: "#a78bfa",
        headline: "Preview anything without losing your place.",
        subheadline: "Inspect images, video, code, and documents with rich floating cards, metadata, and Quick Look.",
        glowColor: "rgba(167, 139, 250, 0.24)",
        sourceImage: "docs/screenshots/hover-preview.png"
    ),
    ScreenshotConfig(
        filename: "03-subfolder-navigation.png",
        badge: "Lightning Navigation",
        badgeColor: "#38bdf8",
        headline: "Traverse nested folders at the speed of thought.",
        subheadline: "Cascading popups let you dive straight into deep directories without opening cluttered windows.",
        glowColor: "rgba(56, 189, 248, 0.22)",
        sourceImage: "docs/screenshots/subfolder-menu.png"
    ),
    ScreenshotConfig(
        filename: "04-integrated-terminal.png",
        badge: "Developer Tools",
        badgeColor: "#34d399",
        headline: "An integrated terminal right where your files live.",
        subheadline: "Toggle an embedded zsh drawer with ⌘` automatically synced to your active directory.",
        glowColor: "rgba(52, 211, 153, 0.20)",
        sourceImage: "docs/screenshots/terminal.png"
    ),
    ScreenshotConfig(
        filename: "05-native-mac-craft.png",
        badge: "Native macOS Craft",
        badgeColor: "#38bdf8",
        headline: "Fast, sandboxed, and 100% private.",
        subheadline: "Pure Swift performance, familiar keyboard shortcuts, dark mode, and zero cloud tracking.",
        glowColor: "rgba(56, 189, 248, 0.20)",
        sourceImage: "docs/screenshots/tabs-and-split.png"
    )
]

func generateHTML(config: ScreenshotConfig, base64Image: String) -> String {
    return """
    <!DOCTYPE html>
    <html>
    <head>
    <meta charset="utf-8">
    <style>
      * { box-sizing: border-box; margin: 0; padding: 0; }
      body {
        width: 1440px;
        height: 900px;
        overflow: hidden;
        background: radial-gradient(120% 100% at 50% 0%, #151d2a 0%, #0c1017 50%, #06080d 100%);
        font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", "Helvetica Neue", sans-serif;
        color: #ffffff;
        display: flex;
        flex-direction: column;
        align-items: center;
        position: relative;
        padding-top: 50px;
        -webkit-font-smoothing: antialiased;
      }
      .ambient-glow {
        position: absolute;
        top: -120px;
        left: 50%;
        transform: translateX(-50%);
        width: 860px;
        height: 480px;
        background: radial-gradient(circle, \(config.glowColor) 0%, rgba(20, 30, 50, 0.05) 55%, transparent 75%);
        filter: blur(65px);
        pointer-events: none;
      }
      .badge {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        padding: 5px 15px;
        background: rgba(255, 255, 255, 0.05);
        border: 1px solid rgba(255, 255, 255, 0.12);
        border-radius: 999px;
        font-size: 11.5px;
        font-weight: 600;
        letter-spacing: 0.08em;
        text-transform: uppercase;
        color: \(config.badgeColor);
        margin-bottom: 12px;
        backdrop-filter: blur(14px);
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
      }
      .headline {
        font-size: 42px;
        font-weight: 700;
        letter-spacing: -0.03em;
        line-height: 1.12;
        text-align: center;
        max-width: 980px;
        background: linear-gradient(180deg, #ffffff 45%, #cbd5e1 100%);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        margin-bottom: 10px;
      }
      .subheadline {
        font-size: 16.5px;
        font-weight: 400;
        color: #94a3b8;
        text-align: center;
        max-width: 820px;
        line-height: 1.45;
        margin-bottom: 30px;
      }
      .window-stage {
        position: relative;
        width: 1200px;
        height: 615px;
        border-radius: 12px;
        box-shadow: 
          0 40px 90px -15px rgba(0, 0, 0, 0.9),
          0 18px 35px -10px rgba(0, 0, 0, 0.65),
          0 0 0 1px rgba(255, 255, 255, 0.12);
        overflow: hidden;
        background: #14181f;
      }
      .window-stage img {
        width: 100%;
        height: 100%;
        object-fit: cover;
        object-position: top center;
        display: block;
      }
    </style>
    </head>
    <body>
      <div class="ambient-glow"></div>
      <div class="badge">✦ \(config.badge)</div>
      <h1 class="headline">\(config.headline)</h1>
      <p class="subheadline">\(config.subheadline)</p>
      <div class="window-stage">
        <img src="\(base64Image)" />
      </div>
    </body>
    </html>
    """
}

let app = NSApplication.shared
let width: CGFloat = 1440
let height: CGFloat = 900
let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: width, height: height))

var currentIndex = 0

class RenderDelegate: NSObject, WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            webView.takeSnapshot(with: nil) { image, error in
                guard let image = image,
                      let tiff = image.tiffRepresentation,
                      let rep = NSBitmapImageRep(data: tiff),
                      let png = rep.representation(using: .png, properties: [:]) else {
                    print("Error snapshotting: \(String(describing: error))")
                    exit(1)
                }
                
                let currentConfig = configs[currentIndex]
                let distURL = URL(fileURLWithPath: "dist/screenshots/\(currentConfig.filename)")
                let docsURL = URL(fileURLWithPath: "docs/appstore-screenshots/\(currentConfig.filename)")
                
                try? png.write(to: distURL)
                try? png.write(to: docsURL)
                print("[\(currentIndex + 1)/\(configs.count)] Generated: \(currentConfig.filename) (\(rep.pixelsWide)x\(rep.pixelsHigh))")
                
                currentIndex += 1
                if currentIndex < configs.count {
                    renderNext()
                } else {
                    print("ALL SCREENSHOTS SUCCESSFULLY GENERATED!")
                    exit(0)
                }
            }
        }
    }
}

let delegate = RenderDelegate()
webView.navigationDelegate = delegate

func renderNext() {
    let config = configs[currentIndex]
    guard let shotData = try? Data(contentsOf: URL(fileURLWithPath: config.sourceImage)) else {
        print("Failed to read: \(config.sourceImage)")
        exit(1)
    }
    let base64 = "data:image/png;base64," + shotData.base64EncodedString()
    let html = generateHTML(config: config, base64Image: base64)
    webView.loadHTMLString(html, baseURL: nil)
}

renderNext()
app.run()
