import Cocoa
import WebKit

struct ScreenshotConfig {
    let filename: String
    let headline: String
    let glowColor1: String
    let glowColor2: String
    let shadowGlow: String
    let sourceImage: String
}

let configs: [ScreenshotConfig] = [
    ScreenshotConfig(
        filename: "01-tabs-and-split.png",
        headline: "Browse two folders side by side<br>with infinite tabs",
        glowColor1: "rgba(38, 140, 255, 0.40)",
        glowColor2: "rgba(14, 165, 233, 0.22)",
        shadowGlow: "rgba(14, 165, 233, 0.28)",
        sourceImage: "docs/screenshots/tabs-and-split.png"
    ),
    ScreenshotConfig(
        filename: "02-hover-preview.png",
        headline: "Preview documents, code, and media<br>without opening them",
        glowColor1: "rgba(251, 113, 133, 0.40)",
        glowColor2: "rgba(249, 115, 22, 0.22)",
        shadowGlow: "rgba(244, 63, 94, 0.28)",
        sourceImage: "docs/screenshots/hover-preview.png"
    ),
    ScreenshotConfig(
        filename: "03-subfolder-navigation.png",
        headline: "Fly through nested folders<br>at the speed of thought",
        glowColor1: "rgba(168, 85, 247, 0.40)",
        glowColor2: "rgba(99, 102, 241, 0.22)",
        shadowGlow: "rgba(147, 51, 234, 0.28)",
        sourceImage: "docs/screenshots/subfolder-menu.png"
    ),
    ScreenshotConfig(
        filename: "04-integrated-terminal.png",
        headline: "An integrated terminal<br>synced to your active folder",
        glowColor1: "rgba(16, 185, 129, 0.40)",
        glowColor2: "rgba(52, 211, 153, 0.22)",
        shadowGlow: "rgba(16, 185, 129, 0.28)",
        sourceImage: "docs/screenshots/terminal.png"
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
        position: relative;
        display: flex;
        flex-direction: column;
        align-items: center;
        padding-top: 68px;
        font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro", "Helvetica Neue", sans-serif;
        -webkit-font-smoothing: antialiased;
        background: #06080D;
      }
      .grid-pattern {
        position: absolute;
        inset: 0;
        background-image: 
          linear-gradient(to right, rgba(255, 255, 255, 0.02) 1px, transparent 1px),
          linear-gradient(to bottom, rgba(255, 255, 255, 0.02) 1px, transparent 1px);
        background-size: 48px 48px;
        mask-image: radial-gradient(ellipse 80% 60% at 50% 40%, black 20%, transparent 80%);
        pointer-events: none;
      }
      .aurora-glow {
        position: absolute;
        top: 140px;
        left: 50%;
        transform: translateX(-50%);
        width: 1150px;
        height: 520px;
        background: radial-gradient(ellipse at 50% 30%, \(config.glowColor1) 0%, \(config.glowColor2) 45%, transparent 75%);
        filter: blur(85px);
        pointer-events: none;
      }
      .headline {
        position: relative;
        z-index: 10;
        font-size: 50px;
        font-weight: 700;
        letter-spacing: -0.035em;
        line-height: 1.15;
        text-align: center;
        max-width: 960px;
        background: linear-gradient(180deg, #FFFFFF 20%, #CBD5E1 100%);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        margin-bottom: 46px;
        filter: drop-shadow(0 2px 20px rgba(255, 255, 255, 0.15));
      }
      .window-stage {
        position: relative;
        z-index: 10;
        width: 1200px;
        height: 620px;
        border-radius: 18px;
        box-shadow: 
          0 50px 140px -20px rgba(0, 0, 0, 0.95),
          0 30px 60px -15px \(config.shadowGlow),
          0 0 0 1px rgba(255, 255, 255, 0.18),
          0 1px 0 0 rgba(255, 255, 255, 0.35) inset;
        overflow: hidden;
        background: #0f141c;
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
      <div class="grid-pattern"></div>
      <div class="aurora-glow"></div>
      <h1 class="headline">\(config.headline)</h1>
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
                    print("ALL 4 OBSIDIAN SCREENSHOTS SUCCESSFULLY GENERATED!")
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
