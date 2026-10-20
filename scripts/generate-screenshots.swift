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
        textColor: "#0A1938",
        bgGradient: "radial-gradient(85% 75% at 50% 0%, #E6F1FE 0%, #C8E0FB 38%, #93BFF6 72%, #5D9DEE 100%)",
        glowTL: "rgba(134, 172, 211, 0.8)",
        glowBR: "rgba(1, 16, 133, 0.45)",
        shadowAmbient: "rgba(10, 50, 120, 0.38)",
        sourceImage: "docs/screenshots/tabs-and-split.png"
    ),
    ScreenshotConfig(
        filename: "02-hover-preview.png",
        headline: "Preview documents, code, and media<br>without opening them.",
        textColor: "#42141A",
        bgGradient: "radial-gradient(85% 75% at 50% 0%, #FFF0ED 0%, #FDD7D1 38%, #FCAFA5 72%, #F88A7D 100%)",
        glowTL: "rgba(253, 197, 198, 0.85)",
        glowBR: "rgba(245, 90, 85, 0.45)",
        shadowAmbient: "rgba(140, 30, 40, 0.35)",
        sourceImage: "docs/screenshots/hover-preview.png"
    ),
    ScreenshotConfig(
        filename: "03-subfolder-navigation.png",
        headline: "Fly through nested folders<br>at the speed of thought.",
        textColor: "#082C24",
        bgGradient: "radial-gradient(85% 75% at 50% 0%, #E8FAF6 0%, #C7F4EC 38%, #8EE5D8 72%, #4CCFBD 100%)",
        glowTL: "rgba(175, 245, 235, 0.85)",
        glowBR: "rgba(30, 180, 160, 0.45)",
        shadowAmbient: "rgba(15, 90, 80, 0.35)",
        sourceImage: "docs/screenshots/subfolder-menu.png"
    ),
    ScreenshotConfig(
        filename: "04-integrated-terminal.png",
        headline: "A built-in terminal synced right<br>to your active folder.",
        textColor: "#1F1142",
        bgGradient: "radial-gradient(85% 75% at 50% 0%, #F3EDFF 0%, #DFD3FE 38%, #BFA7FD 72%, #9570F8 100%)",
        glowTL: "rgba(220, 205, 255, 0.85)",
        glowBR: "rgba(125, 75, 230, 0.45)",
        shadowAmbient: "rgba(70, 30, 130, 0.38)",
        sourceImage: "docs/screenshots/terminal.png"
    ),
    ScreenshotConfig(
        filename: "05-native-mac-craft.png",
        headline: "Fast, lightweight, and completely<br>private on your Mac.",
        textColor: "#0E1B32",
        bgGradient: "radial-gradient(85% 75% at 50% 0%, #F0F4FA 0%, #DCE5F3 38%, #BDCEE5 72%, #8FAACC 100%)",
        glowTL: "rgba(210, 225, 245, 0.85)",
        glowBR: "rgba(50, 90, 160, 0.45)",
        shadowAmbient: "rgba(25, 55, 105, 0.35)",
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
