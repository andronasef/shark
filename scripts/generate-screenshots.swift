import Cocoa
import WebKit

struct ScreenshotConfig {
    let filename: String
    let headline: String
    let textColor: String
    let bgGradient: String
    let glowTL: String
    let glowBR: String
    let shadowAmbient: String
    let sourceImage: String
}

let configs: [ScreenshotConfig] = [
    ScreenshotConfig(
        filename: "01-tabs-and-split.png",
        headline: "Browse two folders side by side.<br>With infinite tabs.",
        textColor: "#0C4A6E",
        bgGradient: "radial-gradient(85% 75% at 50% 0%, #E0F2FE 0%, #BAE6FD 38%, #7DD3FC 72%, #38BDF8 100%)",
        glowTL: "rgba(56, 189, 248, 0.8)",
        glowBR: "rgba(2, 132, 199, 0.45)",
        shadowAmbient: "rgba(3, 105, 161, 0.38)",
        sourceImage: "docs/screenshots/tabs-and-split.png"
    ),
    ScreenshotConfig(
        filename: "02-hover-preview.png",
        headline: "Preview documents, code, and media<br>without opening them.",
        textColor: "#45131A",
        bgGradient: "radial-gradient(85% 75% at 50% 0%, #FFF1EE 0%, #FED7D0 38%, #FCAFA2 72%, #F88779 100%)",
        glowTL: "rgba(251, 146, 60, 0.8)",
        glowBR: "rgba(239, 68, 68, 0.45)",
        shadowAmbient: "rgba(153, 27, 27, 0.35)",
        sourceImage: "docs/screenshots/hover-preview.png"
    ),
    ScreenshotConfig(
        filename: "03-subfolder-navigation.png",
        headline: "Fly through nested folders<br>at the speed of thought.",
        textColor: "#1E1B4B",
        bgGradient: "radial-gradient(85% 75% at 50% 0%, #EEF2FF 0%, #DBE4FE 38%, #B2C5FD 72%, #819EFA 100%)",
        glowTL: "rgba(129, 140, 248, 0.8)",
        glowBR: "rgba(59, 130, 246, 0.45)",
        shadowAmbient: "rgba(30, 58, 138, 0.38)",
        sourceImage: "docs/screenshots/subfolder-menu.png"
    ),
    ScreenshotConfig(
        filename: "04-integrated-terminal.png",
        headline: "A built-in terminal synced right<br>to your active folder.",
        textColor: "#064E3B",
        bgGradient: "radial-gradient(85% 75% at 50% 0%, #ECFDF5 0%, #D1FAE5 38%, #A7F3D0 72%, #6EE7B7 100%)",
        glowTL: "rgba(52, 211, 153, 0.8)",
        glowBR: "rgba(16, 185, 129, 0.45)",
        shadowAmbient: "rgba(6, 78, 59, 0.35)",
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
        padding-top: 64px;
        font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro", "Helvetica Neue", sans-serif;
        -webkit-font-smoothing: antialiased;
        background: \(config.bgGradient);
      }
      .mesh-glow-tl {
        position: absolute;
        top: -120px;
        left: 5%;
        width: 750px;
        height: 600px;
        background: \(config.glowTL);
        filter: blur(85px);
        pointer-events: none;
      }
      .mesh-glow-br {
        position: absolute;
        bottom: -120px;
        right: 5%;
        width: 700px;
        height: 550px;
        background: \(config.glowBR);
        filter: blur(95px);
        pointer-events: none;
      }
      .headline {
        position: relative;
        z-index: 10;
        font-size: 56px;
        font-weight: 700;
        letter-spacing: -0.038em;
        line-height: 1.12;
        text-align: center;
        max-width: 980px;
        color: \(config.textColor);
        margin-bottom: 42px;
      }
      .window-stage {
        position: relative;
        z-index: 10;
        width: 1200px;
        height: 625px;
        border-radius: 18px;
        box-shadow: 
          0 45px 110px -20px \(config.shadowAmbient),
          0 25px 50px -15px rgba(0, 0, 0, 0.40),
          0 10px 20px -5px rgba(0, 0, 0, 0.20),
          0 0 0 1px rgba(255, 255, 255, 0.50),
          0 0 0 1.5px rgba(0, 0, 0, 0.12);
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
      <div class="mesh-glow-tl"></div>
      <div class="mesh-glow-br"></div>
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
                    print("ALL 4 SCREENSHOTS SUCCESSFULLY GENERATED!")
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
