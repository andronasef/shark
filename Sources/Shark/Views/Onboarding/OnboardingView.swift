import AppKit
import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    @State private var service = DefaultFolderAppService.shared

    private let titles = [L10n.text("Welcome to Shark"), L10n.text("Your everyday tools, closer"), L10n.text("Make Shark feel at home")]
    private let subtitles = [
        "A familiar Mac file manager with more room to work.",
        "Keep your folders together and move through your work.",
        "Choose what works for you. Both options are optional."
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath))
                    .resizable()
                    .frame(width: 72, height: 72)
                    .accessibilityHidden(true)
                Text(titles[step])
                    .font(.system(size: 26, weight: .bold))
                    .accessibilityAddTraits(.isHeader)
                Text(L10n.text(subtitles[step]))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 28)
            .padding(.horizontal, 32)

            ScrollView {
                Group {
                    switch step {
                    case 0: welcome
                    case 1: features
                    default: setup
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(32)
            }
            .frame(maxHeight: .infinity)

            Divider()
            HStack(spacing: 12) {
                if step > 0 {
                    Button(L10n.text("Back")) { step -= 1 }
                        .disabled(service.isChanging)
                }
                Text(L10n.format("Step %d of 3", step + 1))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(L10n.format("Welcome, step %d of 3", step + 1))
                Spacer()
                if step < 2 {
                    Button(L10n.text("Skip Setup")) { dismiss() }
                        .keyboardShortcut(.cancelAction)
                }
                Button(step == 2 ? L10n.text("Start Using Shark") : L10n.text("Continue")) {
                    if step == 2 { dismiss() } else { step += 1 }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(service.isChanging)
            }
            .padding(20)
        }
        .frame(width: 580, height: 560)
        .interactiveDismissDisabled(service.isChanging)
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(L10n.text("Your files. A clearer workspace."))
                .font(.title3.weight(.semibold))
            Text(L10n.text("Shark brings folder tabs, side-by-side browsing, quick previews, and a built-in terminal to a native Mac window."))
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            Text(L10n.text("Browse local folders and mounted drives, organize files, and pick up where you left off. Your tabs and layout are remembered."))
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: 16) {
            feature("Folder tabs", symbol: "rectangle.on.rectangle", shortcut: "⌘T",
                    detail: "Keep several locations open in one window.")
            feature("Side-by-side folders", symbol: "rectangle.split.2x1", shortcut: "F3",
                    detail: "Browse two locations and drag files between them.")
            feature("Quick Look", symbol: "eye", shortcut: "Space",
                    detail: "Preview a selected file without opening its app.")
            feature("Built-in terminal", symbol: "terminal", shortcut: "⌃`",
                    detail: "Work in a shell right beneath your files.")
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.text("See everything Shark can do in Help → All Features."))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Link(L10n.text("View All Features"), destination: AppLinks.features)
                    .font(.callout)
            }
        }
    }

    private func feature(_ title: String, symbol: String, shortcut: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: symbol)
                .font(.system(size: 22))
                .foregroundStyle(.secondary)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(L10n.text(title)).font(.headline)
                    Spacer()
                    Text(L10n.text(shortcut)).font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Text(L10n.text(detail)).font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var setup: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text("Default folder app")).font(.headline)
                DefaultFolderAppControls()
            }
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.text("Full Disk Access")).font(.headline)
                FullDiskAccessControls()
            }
            Text(L10n.text("Change these later in Settings. Revisit this welcome from the Help menu."))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
