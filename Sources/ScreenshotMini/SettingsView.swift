import SwiftUI
import ServiceManagement

// MARK: - Screen position

enum ScreenPosition: String, CaseIterable {
    case bottomLeft = "bottomLeft"
    case bottomRight = "bottomRight"
    case topLeft = "topLeft"
    case topRight = "topRight"

    var label: String {
        let en = L10n.lang == "en"
        switch self {
        case .bottomLeft: return en ? "Bottom left" : "Bas gauche"
        case .bottomRight: return en ? "Bottom right" : "Bas droite"
        case .topLeft: return en ? "Top left" : "Haut gauche"
        case .topRight: return en ? "Top right" : "Haut droite"
        }
    }

    var icon: String {
        switch self {
        case .bottomLeft: "arrow.down.left"
        case .bottomRight: "arrow.down.right"
        case .topLeft: "arrow.up.left"
        case .topRight: "arrow.up.right"
        }
    }
}

// MARK: - Image format

enum ImageFormat: String, CaseIterable {
    case png, jpeg, tiff

    var label: String {
        switch self {
        case .png: "PNG"
        case .jpeg: "JPEG"
        case .tiff: "TIFF"
        }
    }

    var description: String {
        let en = L10n.lang == "en"
        switch self {
        case .png: return en ? "Lossless, transparent" : "Sans perte, transparent"
        case .jpeg: return en ? "Compressed, lighter" : "Compressé, plus léger"
        case .tiff: return en ? "Lossless, high quality" : "Sans perte, haute qualité"
        }
    }
}

// MARK: - Settings Tabs

enum SettingsTab: String, CaseIterable {
    case general, raccourcis, capture, sauvegarde

    var icon: String {
        switch self {
        case .general: "gearshape"
        case .raccourcis: "keyboard"
        case .capture: "camera.viewfinder"
        case .sauvegarde: "folder"
        }
    }

    var label: String {
        switch self {
        case .general: L10n.settingsGeneral
        case .raccourcis: L10n.shortcut
        case .capture: L10n.settingsCapture
        case .sauvegarde: L10n.settingsSave
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @State private var selectedTab: SettingsTab = .general
    @AppStorage("appLanguage") private var appLanguage = "fr"

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20))
                            Text(tab.label)
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .foregroundStyle(selectedTab == tab ? brandPurple : Color.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)

            Divider()
                .padding(.top, 4)

            Group {
                switch selectedTab {
                case .general:
                    generalTab
                case .raccourcis:
                    raccourcisTab
                case .capture:
                    captureTab
                case .sauvegarde:
                    sauvegardeTab
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .id(appLanguage) // force refresh when language changes
        }
        .frame(width: 440)
        .fixedSize(horizontal: false, vertical: true)
        .tint(brandPurple)
        .onAppear {
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.last(where: { $0.isVisible && $0.canBecomeKey }) {
                    window.makeKeyAndOrderFront(nil)
                    window.orderFrontRegardless()
                }
            }
        }
    }

    // MARK: - Général

    @AppStorage("ocrLanguage") private var ocrLanguage = "fr"
    @AppStorage("showMenuBarIcon") private var showMenuBarIcon = true
    @AppStorage("playSound") private var playSound = true

    private var generalTab: some View {
        Form {
            Section(L10n.lang == "en" ? "Menu bar" : "Barre des menus") {
                Toggle(
                    L10n.lang == "en" ? "Show icon in menu bar" : "Afficher l'icône dans la barre des menus",
                    isOn: $showMenuBarIcon
                )
                if !showMenuBarIcon {
                    Text(L10n.lang == "en"
                         ? "Use your keyboard shortcuts to capture. Right-click the app in the Dock or relaunch to access settings."
                         : "Utilisez vos raccourcis clavier pour capturer. Clic droit sur l'app dans le Dock ou relancez pour accéder aux réglages.")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }

            Section(L10n.startup) {
                LaunchAtLoginToggle()
            }

            Section(L10n.lang == "en" ? "Sound" : "Son") {
                Toggle(
                    L10n.lang == "en" ? "Play sound on capture" : "Jouer un son à la capture",
                    isOn: $playSound
                )
            }

            Section(L10n.language) {
                Picker(L10n.interfaceLanguage, selection: $appLanguage) {
                    Text("French").tag("fr")
                    Text("English").tag("en")
                }
                .pickerStyle(.segmented)
            }

            Section(L10n.lang == "en" ? "Text recognition (OCR)" : "Reconnaissance de texte (OCR)") {
                Picker(L10n.lang == "en" ? "Language" : "Langue", selection: $ocrLanguage) {
                    Text("French").tag("fr")
                    Text("English").tag("en")
                }
                .pickerStyle(.segmented)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Raccourcis

    private var raccourcisTab: some View {
        Form {
            Section(L10n.lang == "en" ? "Capture" : "Capture") {
                HotkeySettingRow(slot: .fullscreen, label: L10n.lang == "en" ? "Full screen" : "Plein écran")
                HotkeySettingRow(slot: .area, label: L10n.lang == "en" ? "Area capture" : "Capture de zone")
                HotkeySettingRow(slot: .ocr, label: L10n.lang == "en" ? "Text capture" : "Capture texte")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Capture

    @AppStorage("previewPosition") private var position = "bottomLeft"
    @AppStorage("dismissDelay") private var dismissDelay = 5.0
    @AppStorage("closeAfterAction") private var closeAfterAction = true
    @AppStorage("multiPreview") private var multiPreview = true
    @AppStorage("afterCaptureShowPreview") private var afterCaptureShowPreview = true
    @AppStorage("afterCaptureCopyClipboard") private var afterCaptureCopyClipboard = true
    @AppStorage("afterCaptureSave") private var afterCaptureSave = false
    @AppStorage("afterCaptureOpenEditor") private var afterCaptureOpenEditor = false

    private var captureTab: some View {
        let en = L10n.lang == "en"
        return Form {
            // Actions after capture — first, because it determines what's shown below
            Section(en ? "After capture" : "Après la capture") {
                Toggle(en ? "Show preview" : "Afficher la preview", isOn: $afterCaptureShowPreview)
                Toggle(en ? "Copy to clipboard" : "Copier dans le presse-papier", isOn: $afterCaptureCopyClipboard)
                Toggle(en ? "Save to disk" : "Sauvegarder sur le disque", isOn: $afterCaptureSave)
                Toggle(en ? "Open editor" : "Ouvrir l'éditeur", isOn: $afterCaptureOpenEditor)

                Text(en
                     ? "Actions performed automatically after each capture"
                     : "Actions effectuées automatiquement après chaque capture")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if afterCaptureShowPreview {
                Section(en ? "Preview" : "Prévisualisation") {
                    // Position
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.previewPosition)
                            .font(.callout)
                        HStack(spacing: 8) {
                            ForEach(ScreenPosition.allCases, id: \.rawValue) { pos in
                                Button {
                                    position = pos.rawValue
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: pos.icon)
                                            .font(.system(size: 16))
                                        Text(pos.label)
                                            .font(.caption2)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(position == pos.rawValue ? brandPurple.opacity(0.15) : Color.clear)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(position == pos.rawValue ? brandPurple : Color.secondary.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(position == pos.rawValue ? .primary : .secondary)
                            }
                        }
                    }

                    // Stack
                    VStack(alignment: .leading, spacing: 2) {
                        Toggle(
                            en ? "Stack multiple previews" : "Empiler les prévisualisations",
                            isOn: $multiPreview
                        )
                        Text(en
                             ? "Multiple captures stack on screen. Otherwise, the previous one closes."
                             : "Les captures s'empilent à l'écran. Sinon, la précédente se ferme.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    // Auto-close delay
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(en ? "Auto-close delay" : "Fermeture automatique")
                            Spacer()
                            Text("\(Int(dismissDelay))s")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $dismissDelay, in: 3...60, step: 1)
                            .controlSize(.small)
                        Text(en
                             ? "Time before the preview disappears automatically"
                             : "Durée avant que la preview disparaisse automatiquement")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    // Close after action
                    VStack(alignment: .leading, spacing: 2) {
                        Toggle(L10n.closeAfterAction, isOn: $closeAfterAction)
                        Text(en
                             ? "Close the preview after clicking Copy or Save"
                             : "Ferme la preview après avoir cliqué Copy ou Save")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Sauvegarde

    @AppStorage("savePath") private var savePath = ""
    @AppStorage("imageFormat") private var imageFormat = "png"

    private var resolvedSavePath: String {
        savePath.isEmpty
            ? FileManager.default.homeDirectoryForCurrentUser.appending(path: "Desktop").path
            : savePath
    }

    private var sauvegardeTab: some View {
        Form {
            Section(L10n.imageFormat) {
                VStack(alignment: .leading, spacing: 8) {
                    Picker(L10n.format, selection: $imageFormat) {
                        ForEach(ImageFormat.allCases, id: \.rawValue) { fmt in
                            Text(fmt.label).tag(fmt.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)

                    if let fmt = ImageFormat(rawValue: imageFormat) {
                        Text(fmt.description)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section(L10n.destinationFolder) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "folder")
                                .foregroundStyle(.secondary)
                            Text(resolvedSavePath)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Spacer()
                        Button(L10n.choose) {
                            pickSaveFolder()
                        }
                        .controlSize(.small)
                    }
                    if !savePath.isEmpty {
                        Button(L10n.resetToDesktop) {
                            savePath = ""
                        }
                        .controlSize(.small)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    private func pickSaveFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = L10n.lang == "en" ? "Choose" : "Choisir"
        panel.message = L10n.chooseFolder

        if panel.runModal() == .OK, let url = panel.url {
            savePath = url.path
        }
    }
}

// MARK: - Hotkey

struct HotkeySettingRow: View {
    let slot: HotkeySlot
    let label: String
    @ObservedObject private var manager = HotkeyManager.shared

    private var isRecordingThis: Bool {
        manager.isRecording && manager.recordingSlot == slot
    }

    private var combo: HotkeyCombo? {
        manager.combo(for: slot)
    }

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            HStack(spacing: 8) {
                Button {
                    if isRecordingThis {
                        manager.stopRecording()
                    } else {
                        manager.startRecording(slot: slot)
                    }
                } label: {
                    Group {
                        if isRecordingThis {
                            Text(L10n.pressKey)
                                .foregroundStyle(.orange)
                        } else if let combo {
                            Text(combo.displayString)
                                .foregroundStyle(.primary)
                        } else {
                            Text(L10n.setKey)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.system(.callout, design: .rounded))
                    .frame(minWidth: 60)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(.quaternary, in: Capsule())
                }
                .buttonStyle(.plain)

                if combo != nil {
                    Button {
                        manager.clearHotkey(slot)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Launch at Login

struct LaunchAtLoginToggle: View {
    @StateObject private var model = LaunchAtLoginModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(L10n.launchAtLogin, isOn: Binding(
                get: { model.isEnabled },
                set: { model.setEnabled($0) }
            ))
            .disabled(!model.isSupported)

            if let message = model.message {
                Text(message)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

@MainActor
final class LaunchAtLoginModel: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var isSupported: Bool
    @Published private(set) var message: String?

    init() {
        let appURL = Bundle.main.bundleURL.resolvingSymlinksInPath().standardizedFileURL
        let appPath = appURL.path
        let appDirs = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            FileManager.default.homeDirectoryForCurrentUser.appending(path: "Applications", directoryHint: .isDirectory)
        ]
        isSupported = appDirs.contains { dir in
            let dirPath = dir.resolvingSymlinksInPath().standardizedFileURL.path
            return appPath == dirPath || appPath.hasPrefix(dirPath + "/")
        }

        guard isSupported else {
            message = L10n.installInApps
            return
        }
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) {
        guard isSupported else { return }
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            isEnabled = enabled
            message = nil
        } catch {
            isEnabled = SMAppService.mainApp.status == .enabled
            message = L10n.cannotModify
        }
    }
}
