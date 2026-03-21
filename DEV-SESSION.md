# Session de dev — Screenshot Mini

## Etat actuel (21 mars 2025)

L'app fonctionne, est publiee sur GitHub avec release v1.0.0 et landing page.

### Ce qui marche bien

- **Capture** : fullscreen, zone, OCR — raccourcis globaux configurables
- **Preview flottante** : copy, edit, save, pin, drag & drop, swipe dismiss, tooltips, curseur arrow force
- **Editeur** : crop, rectangle, cercle, ligne, fleche — avec selection, deplacement, resize, undo/redo (⌘Z/⌘⇧Z), delete, fleches clavier, color picker, epaisseur, fill
- **Reglages** : 4 onglets (General, Raccourcis, Capture, Sauvegarde), bilingue FR/EN
- **OCR** : Vision framework, toast avec apercu du texte
- **Son** de capture, format image configurable, multi-preview ou single
- **Distribution** : DMG, landing page, guide install, licence MIT

### Ce qui reste a faire / ameliorer

#### Editeur (priorite haute)
- [ ] **Outil Texte** : cliquer pour placer du texte, editer inline, police/taille
- [ ] **Outil Dessin libre** (applepencil) : tracer a main levee
- [ ] **UI polish** : meilleurs handles de resize (plus gros, curseurs specifiques NW/NE/SW/SE), feedback visuel au hover des handles
- [ ] **Double-clic** sur annotation pour editer ses proprietes (ou panneau lateral)
- [ ] **Sauvegarder les annotations** sans flatten (pouvoir re-editer apres save)
- [ ] Curseur resize specifique par handle (↔ ↕ ↗ etc.)

#### Preview
- [ ] Le drag & drop image fonctionne mais le curseur ne change pas (limitation nonactivatingPanel)
- [ ] Les tooltips custom ont un delai de 1s — peut-etre reduire a 0.7s

#### General
- [ ] **Capture de fenetre** (screencapture -w)
- [ ] **Historique** des captures
- [ ] **Partage** bouton share dans l'editeur (actuellement placeholder)
- [ ] Build avec macOS 15 minimum (deja fait dans Package.swift)
- [ ] AppIcon.icns genere depuis le logo web (pas le logo app avec fond violet — a refaire quand on a le fichier)

### Architecture des fichiers

```
Sources/ScreenshotMini/
├── ScreenshotMiniApp.swift    # @main, AppDelegate, menu bar, routing des hotkeys
├── HotkeyManager.swift        # Multi-hotkeys Carbon (fullscreen/area/OCR), HotkeySlot, UCKeyTranslate AZERTY
├── ScreenCaptureService.swift  # screencapture CLI (fullscreen/area/OCR), post-capture actions, son
├── ThumbnailPanel.swift        # Preview flottante : ThumbnailNSPanel (drag source sendEvent), swipe, curseur global
├── EditorWindow.swift          # Fenetre d'edition : toolbar, canvas, gestes (draw/move/resize), flatten, crop
├── AnnotationModel.swift       # Modele annotation : shapes, hit test, resize, move, AnnotationHistory (undo/redo)
├── ToastManager.swift          # Toast flottant (succes OCR, copy, save)
├── SettingsView.swift          # 4 onglets, tous les reglages, hotkey row
├── Localization.swift          # L10n — strings FR/EN
Resources/
├── AppIcon.icns               # Icone app
├── menubar-icon.png           # Icone menu bar (template noir)
├── icon.png                   # Logo source
docs/                          # Landing page + guide install
```

### Points techniques importants

- **Code signing dev** : certificat "ScreenshotMini Dev" dans le Keychain pour que TCC persiste entre builds. `build-dmg.sh` re-signe en ad-hoc pour distribution.
- **Drag & drop preview** : gere au niveau `ThumbnailNSPanel.sendEvent` (pas de gesture recognizer) pour coexister avec les boutons SwiftUI
- **Editeur gestes** : `CanvasInteraction` enum avec priorite handles > move selected > move hit > draw new
- **Curseur preview** : `NSEvent.addGlobalMonitorForEvents(.mouseMoved)` force arrow car nonactivatingPanel
- **Curseur editeur** : `onContinuousHover` + `NSCursor` (fonctionne car NSWindow standard)
- **Raccourcis clavier** : `UCKeyTranslate` pour AZERTY, `keyEquivalent` natif dans le menu (limité pour touches mortes)

### Repo GitHub

- URL : https://github.com/jeremy-prt/screenshot-mini
- Branche : main
- Remote : git@github.com-perso:jeremy-prt/screenshot-mini.git
- Release : v1.0.0 avec DMG
- Pages : https://jeremy-prt.github.io/screenshot-mini/
