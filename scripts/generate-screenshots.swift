import Cocoa
import WebKit

struct ScreenshotConfig {
    let filename: String
    let headline: String
    let textColor: String
    let bgGradient: String
    let glowColor: String
    let shadowAmbient: String
    let sourceImage: String
}

let configs: [ScreenshotConfig] = [
    ScreenshotConfig(
        filename: "01-tabs-and-split.png",
        headline: "Browse two folders side by side<br>with infinite tabs",
        textColor: "#0F1D36",
        bgGradient: "radial-gradient(100% 85% at 50% -10%, #F6FAFF 0%, #E5F0FF 35%, #C7DDF8 70%, #9BC6F7 100%)",
        glowColor: "rgba(185, 218, 255, 0.65)",
        shadowAmbient: "rgba(12, 45, 95, 0.32)",
        sourceImage: "docs/screenshots/tabs-and-split.png"
    ),
    ScreenshotConfig(
        filename: "02-hover-preview.png",
        headline: "Preview documents, code, and media<br>without opening them",
        textColor: "#2E1418",
        bgGradient: "radial-gradient(100% 85% at 50% -10%, #FFF8F6 0%, #FEECE8 35%, #FED3C9 70%, #FBAFA3 100%)",
        glowColor: "rgba(254, 215, 205, 0.65)",
        shadowAmbient: "rgba(120, 30, 40, 0.30)",
        sourceImage: "docs/screenshots/hover-preview.png"
    ),
    ScreenshotConfig(
        filename: "03-subfolder-navigation.png",
        headline: "Fly through nested folders<br>at the speed of thought",
        textColor: "#141738",
        bgGradient: "radial-gradient(100% 85% at 50% -10%, #F7F9FF 0%, #ECEFFE 35%, #D4DCFC 70%, #ADC0F9 100%)",
        glowColor: "rgba(205, 215, 255, 0.65)",
        shadowAmbient: "rgba(25, 45, 115, 0.32)",
        sourceImage: "docs/screenshots/subfolder-menu.png"
    ),
    ScreenshotConfig(
        filename: "04-integrated-terminal.png",
        headline: "An integrated terminal<br>synced to your active folder",
        textColor: "#0D2B20",
        bgGradient: "radial-gradient(100% 85% at 50% -10%, #F4FBF7 0%, #E4F7ED 35%, #C2EEDB 70%, #94DFBE 100%)",
        glowColor: "rgba(185, 238, 215, 0.65)",
        shadowAmbient: "rgba(8, 65, 48, 0.30)",
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
        background: \(config.bgGradient);
      }
      .ambient-glow {
        position: absolute;
        top: -160px;
        left: 50%;
        transform: translateX(-50%);
        width: 1000px;
        height: 600px;
        background: radial-gradient(ellipse at center, \(config.glowColor) 0%, transparent 70%);
        filter: blur(100px);
        pointer-events: none;
      }
      .headline {
        position: relative;
        z-index: 10;
        font-size: 52px;
        font-weight: 650;
        letter-spacing: -0.028em;
        line-height: 1.2;
        text-align: center;
        max-width: 960px;
        color: \(config.textColor);
        margin-bottom: 46px;
        text-rendering: optimizeLegibility;
      }
      .window-stage {
        position: relative;
        z-index: 10;
        width: 1200px;
        height: 620px;
        border-radius: 18px;
        box-shadow: 
          0 45px 110px -20px \(config.shadowAmbient),
          0 20px 45px -12px rgba(0, 0, 0, 0.38),
          0 8px 18px -4px rgba(0, 0, 0, 0.20),
          0 0 0 1px rgba(255, 255, 255, 0.60),
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
      <div class="ambient-glow"></div>
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
