# Session de dev — Screenshot Mini

## Etat actuel (21 mars 2026)

L'app fonctionne, est publiee sur GitHub avec release v1.0.0 et landing page.

### Ce qui marche bien

- **Capture** : fullscreen, zone, OCR — raccourcis globaux configurables
- **Preview flottante** : copy, edit, save, pin, drag & drop, swipe dismiss, tooltips, curseur arrow force
- **Editeur** : crop (avec undo), rectangle, cercle, ligne, fleche (4 styles + courbe Bezier), texte, dessin libre, flou — avec selection, deplacement, resize, rotation, undo/redo (⌘Z/⌘⇧Z), delete, fleches clavier, copy/paste (⌘C/⌘V), option-drag duplicate
- **Editeur UI** : dark mode, toolbar alignee avec traffic lights via NSToolbar unifiedCompact, raccourcis clavier (V/C/R/O/L/A/T/D/B/Esc), tooltips custom avec shortcuts, outil curseur par defaut
- **Zoom editeur** : pinch trackpad (MagnifyGesture), ⌘+ / ⌘- / ⌘0, ⌘+scroll to zoom, scroll pour panner quand zoom > 1, indicateur % cliquable dans la toolbar
- **Annotations** : color picker compact (cercle unique + popover preset + custom), slider epaisseur (triangle), fill modes (outline/semi/solid), 4 styles de fleche (outline/thin/filled/double), fleches courbees avec point de controle Bezier
- **Rotation** : handle `.rotating` positionne au-dessus du bounding box (suit la rotation), curseur fleche circulaire dessine en code (`rotateCursor`)
- **Outil Flou** : gaussian blur + pixelate via CIFilter, preview en temps reel, rayon et style configurables
- **Outil Texte** : mode background + plain, multiline (Shift+Enter), resize en direct, clic sur annotation selectionnee → re-edition inline, pas de duplication pendant l'edition
- **Fleches** : 4 styles (outline/thin/filled/double), courbes Bezier avec point de controle
- **Slider epaisseur** : forme triangle custom
- **Persistance couleur** : derniere couleur sauvegardee dans UserDefaults
- **Drag & drop depuis l'editeur** : DragMeButton dans la toolbar, fenetre se ferme apres le drop
- **Reglages** : 4 onglets (General, Raccourcis, Capture, Sauvegarde), bilingue FR/EN
- **Theme** : System / Light / Dark dans l'onglet General (`appTheme` UserDefaults), applique a l'app entiere
- **Export resolution** : Retina 2x / Standard 1x dans l'onglet Capture (`exportRetina` UserDefaults), respecte par save, copy et drag & drop
- **OCR** : Vision framework, langue configurable (FR/EN), toast avec apercu du texte
- **Son** de capture, format image configurable (PNG/JPEG/TIFF), multi-preview ou single
- **Toast** : capsule adaptative light/dark selon le theme, animation slide-down entree + fade-out, centree en haut d'ecran
- **Distribution** : DMG, landing page, guide install, licence MIT
- **Couleur brand** : violet #9F01A0 utilise dans settings, editeur et toasts

### Ce qui reste a faire / ameliorer

#### Editeur (priorite haute)
- [ ] **Sauvegarder les annotations** sans flatten (pouvoir re-editer apres save)
- [ ] **Double-clic** sur annotation pour re-editer ses proprietes (ou panneau lateral)
- [ ] **Curseurs resize specifiques** par handle (↔ ↕ ↗ etc.) — actuellement crosshair generique

#### Preview
- [ ] Le drag & drop image fonctionne mais le curseur ne change pas (limitation nonactivatingPanel)
- [ ] Les tooltips custom ont un delai de 1s — peut-etre reduire a 0.7s

#### General
- [ ] **Capture de fenetre** (screencapture -w)
- [ ] **Historique** des captures
- [ ] **Partage** bouton share dans l'editeur (actuellement placeholder)
- [ ] AppIcon.icns genere depuis le logo app avec fond violet (a refaire quand on a le fichier)

### Architecture des fichiers

27 fichiers dans 7 sous-repertoires :

```
Sources/ScreenshotMini/
├── App/
│   ├── ScreenshotMiniApp.swift    # @main, AppDelegate, menu bar, routing des hotkeys
│   └── Constants.swift            # brandPurple (#9F01A0)
├── Editor/
│   ├── EditorWindow.swift         # NSWindow + NSToolbar unifiedCompact, traffic lights alignment
│   ├── EditorView.swift           # Canvas, toolbar SwiftUI, gestes (draw/move/resize/crop), undo, copy/paste, option-drag
│   ├── AnnotationToolbar.swift    # Floating toolbar : color picker, thickness slider, fill/arrow style, blur controls
│   ├── AnnotationView.swift       # Rendu Canvas : rect/circle/line/freehand, 4 styles fleche, Bezier
│   ├── AnnotationOverlays.swift   # HoverOverlay, SelectionOverlay, TextEditingOverlay, CropToolbar, CropMask
│   ├── ToolbarButton.swift        # ToolbarButton avec tooltip + shortcut
│   └── DragMeButton.swift         # Bouton drag & drop image depuis l'editeur
├── Models/
│   ├── AnnotationModel.swift      # Annotation struct, AnnotationShape, ArrowStyle, BlurStyle, ResizeHandle, hit test, resize, move, duplicate
│   ├── AnnotationHistory.swift    # AnnotationHistory (undo/redo stack)
│   └── ImageHelpers.swift         # flattenAnnotations, cropImage, saveImage
├── Services/
│   ├── HotkeyManager.swift        # Multi-hotkeys Carbon (fullscreen/area/OCR), HotkeySlot, UCKeyTranslate AZERTY
│   ├── ScreenCaptureService.swift  # screencapture CLI (fullscreen/area/OCR), post-capture actions, son
│   └── ToastManager.swift         # Toast flottant (succes OCR, copy, save)
├── Settings/
│   ├── SettingsView.swift         # Shell 4 onglets
│   ├── GeneralTab.swift           # Onglet General
│   ├── ShortcutsTab.swift         # Onglet Raccourcis
│   ├── CaptureTab.swift           # Onglet Capture
│   ├── SaveTab.swift              # Onglet Sauvegarde
│   ├── SettingsModels.swift       # Modeles partagés settings
│   └── LaunchAtLoginToggle.swift  # Toggle launch at login
├── Thumbnail/
│   ├── ThumbnailPanel.swift       # Coordinateur preview flottante, auto-dismiss, position
│   ├── ThumbnailNSPanel.swift     # NSPanel custom (drag source sendEvent)
│   ├── ThumbnailView.swift        # SwiftUI view de la preview
│   └── WindowDragHandle.swift     # Handle drag pour pin
└── Localization/
    └── Localization.swift         # L10n — strings FR/EN
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
- **Editeur toolbar** : NSToolbar unifiedCompact vide → decale les traffic lights vers le bas pour aligner avec la toolbar SwiftUI (hauteur 38pt). Padding gauche de 70pt dans la toolbar SwiftUI pour eviter le chevauchement.
- **Curseur preview** : `NSEvent.addGlobalMonitorForEvents(.mouseMoved)` force arrow car nonactivatingPanel
- **Curseur editeur** : `onContinuousHover` + `NSCursor` (fonctionne car NSWindow standard)
- **Raccourcis clavier** : `UCKeyTranslate` pour AZERTY, `keyEquivalent` natif dans le menu. Dans l'editeur, hidden Buttons avec `.keyboardShortcut` pour V/C/R/O/L/A/T/D/B/Esc + ⌘C/⌘V (copy/paste annotation).
- **Crop undo** : push dans `imageUndoStack: [(NSImage, [Annotation])]`. `history.undo()` prend priorite ; si vide, pop imageUndoStack.
- **Bezier fleche** : `controlPoint` optionnel dans `Annotation`. Drag du midpoint handle → update controlPoint. Rendu via `addQuadCurve`.
- **Fill mode** : `filled` + `solidFill` booleans → `FillMode` enum (.outline / .semiFilled / .solidFilled) dans l'UI.
- **Freehand** : draw via `CanvasInteraction.freehand([CGPoint])`, lisse avec quadCurve mid-points.
- **Blur tool** : CIFilter (CIGaussianBlur / CIPixellate) applique sur la region selectionnee de l'image source. Preview en temps reel via BlurRegionView.
- **Copy/paste** : ⌘C copie l'annotation selectionnee dans un clipboard interne, ⌘V colle avec offset +20,+20. Pastes successifs cascadent.
- **Option-drag duplicate** : maintenir Option pendant le drag duplique l'annotation au lieu de la deplacer (comme Figma). Utilise `NSEvent.modifierFlags.contains(.option)`.
- **Annotation.duplicate()** : methode qui cree une copie avec un nouvel UUID, optionnellement decalee.

### Repo GitHub

- URL : https://github.com/jeremy-prt/screenshot-mini
- Branche : main
- Remote : git@github.com-perso:jeremy-prt/screenshot-mini.git
- Release : v1.0.0 avec DMG
- Pages : https://jeremy-prt.github.io/screenshot-mini/
