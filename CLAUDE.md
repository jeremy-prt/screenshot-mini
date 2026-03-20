# Screenshot Mini

App macOS menu bar de capture d'ecran, inspiree de CleanShot X en plus simple.

## Stack

- **Swift 6.2** / **SwiftUI** / **macOS 15+** (Sequoia)
- **Swift Package Manager** (pas de projet Xcode)
- App menu bar (`NSStatusItem`) sans fenetre principale (`LSUIElement = true`)
- Hotkey global via **Carbon** (`RegisterEventHotKey`) — supporte multi-raccourcis
- Capture via `/usr/sbin/screencapture -x` (CLI systeme)
- OCR via **Vision** framework (`VNRecognizeTextRequest`) — natif, pas de dependance
- Build dev : `bash build-app.sh` → compile, signe avec certificat dev, met a jour `/Applications/`
- Build distribution : `bash build-dmg.sh` → compile, re-signe en ad-hoc, cree le `.dmg`

## Architecture

```
Sources/ScreenshotMini/
├── ScreenshotMiniApp.swift   # @main + AppDelegate (menu bar, status item, context menu)
├── HotkeyManager.swift       # Multi-hotkeys (fullscreen, area, OCR), Carbon API, HotkeySlot
├── ScreenCaptureService.swift # Capture fullscreen/area/OCR, post-capture actions configurables
├── ThumbnailPanel.swift       # NSPanel flottant + ThumbnailNSPanel (drag source via sendEvent)
├── EditorWindow.swift         # Fenetre d'edition (toolbar, canvas, drag me, save/copy)
├── ToastManager.swift         # Toast de succes flottant (OCR, save, copy)
├── SettingsView.swift         # Reglages : 4 onglets (General, Raccourcis, Capture, Sauvegarde)
├── Localization.swift         # L10n — localisation FR/EN in-app via UserDefaults
Resources/
├── AppIcon.icns              # Icone app (logo violet)
├── menubar-icon.png          # Icone menu bar (template, noir sur transparent)
├── icon.png                  # Logo source
docs/
├── index.html                # Landing page bilingue
├── setup.html                # Guide d'installation
├── screenshot.jpeg           # Capture d'ecran pour landing
├── logo.png                  # Logo web (sans fond)
├── favicon.png               # Favicon
├── open-anyway.webp          # Screenshot "Open Anyway" pour setup guide
```

## Fonctionnalites

- **Capture plein ecran** — raccourci global configurable
- **Capture de zone** — selection a la souris, raccourci global
- **OCR (capture texte)** — selection zone → Vision reconnaît le texte → copie clipboard + toast
- **Preview flottante** apres capture :
  - Hover = blur + glass + boutons (Copy, Edit, Save, Pin, Close)
  - Drag & drop image vers Finder/navigateur (via ThumbnailNSPanel.sendEvent)
  - Swipe trackpad pour fermer (scroll monitor)
  - Pin = deplace via handle 3 dots, decalage visuel du stack
  - Multi-captures empilables ou mode single (configurable)
  - Auto-dismiss configurable (3-60s), pause au hover
  - Position configurable (4 coins)
  - Tooltips custom avec delai 1s
  - Curseur force arrow via global mouse monitor (empeche cursor bleed-through)
- **Editeur** — fenetre d'edition avec toolbar (outils placeholder), drag me, copy, save
- **Son** de capture (optionnel, son systeme macOS natif)
- **Actions post-capture** configurables : afficher preview, copier clipboard, sauvegarder, ouvrir editeur
- **Format d'image** : PNG, JPEG, TIFF (configurable)
- **Bilingue** FR/EN — interface, tooltips, menu, reglages
- **Menu bar** — icone custom template, masquable (auto-ouvre settings si masquee)

## Build & Dev

```bash
cd /Users/jeremy/Documents/code/2025/projets_pro/ScreenshotMini
bash build-app.sh   # compile + signe certificat dev + update /Applications + relance
bash build-dmg.sh   # compile + re-signe ad-hoc + cree .dmg pour distribution
```

## Code signing

**Dev (build-app.sh)** :
- Signe avec le certificat local **"ScreenshotMini Dev"** (racine auto-signee, Keychain session)
- Signature stable entre les builds → permissions TCC (Screen Recording) persistent
- Ne PAS revenir a `-s -` (ad-hoc) pour le dev sinon TCC redemande a chaque rebuild

**Distribution (build-dmg.sh)** :
- Re-signe en ad-hoc (`-s -`) apres le build
- Les utilisateurs n'ont pas le certificat dev → ad-hoc suffit
- Ils devront faire "Open Anyway" dans System Settings + autoriser Screen Recording une fois

## Points importants

- On utilise `screencapture` CLI et PAS ScreenCaptureKit pour eviter les popups de permission
- `waitUntilExit()` du Process est dans un `DispatchQueue.global` pour ne pas bloquer le main thread
- Les settings utilisent `@AppStorage` / `UserDefaults`
- Le drag & drop image est gere au niveau `ThumbnailNSPanel.sendEvent` (pas de gesture recognizer, pas de NSViewRepresentable) pour coexister avec les boutons SwiftUI
- Le swipe dismiss utilise `NSEvent.addLocalMonitorForEvents(.scrollWheel)`
- Le curseur arrow est force via `NSEvent.addGlobalMonitorForEvents(.mouseMoved)`
- Les raccourcis clavier utilisent `UCKeyTranslate` pour supporter AZERTY et autres layouts
- L'icone menu bar est un PNG template (`isTemplate = true`) → macOS adapte la couleur au theme

## TODO

- [ ] Outils d'annotation dans l'editeur (rectangle, cercle, fleche, texte, dessin)
- [ ] Crop dans l'editeur
- [ ] Historique des captures
- [ ] Capture de fenetre specifique
