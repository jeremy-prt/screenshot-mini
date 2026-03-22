# Annotation Overflow — Problème à résoudre

## Contexte

L'éditeur d'Orby permet d'annoter des captures d'écran (rectangles, flèches, texte, etc.). Actuellement, les annotations sont **clippées aux bords de l'image** : si on déplace une annotation vers le haut ou la gauche de l'image, elle est coupée. Les handles de sélection (resize, rotation) sont aussi coupés quand l'annotation est près d'un bord.

## Comportement attendu (référence : Shottr)

Dans Shottr, quand on crée une annotation et qu'on la déplace **en dehors des limites de l'image** :

1. L'éditeur **étend automatiquement le canvas** autour de l'image
2. La zone ajoutée prend la **couleur dominante de l'image** (pas du blanc)
3. L'annotation et ses handles sont **entièrement visibles**, jamais coupés
4. Quand on sauvegarde/copie, l'image exportée **inclut le canvas étendu** avec les annotations qui dépassent
5. Le canvas grandit dynamiquement selon les annotations — il ne dépasse pas plus que nécessaire

## Architecture actuelle

### Fichiers concernés
- `Sources/Orby/Editor/EditorView.swift` — Canvas principal, zoom, gestures
- `Sources/Orby/Editor/AnnotationView.swift` — Rendu des annotations (Canvas SwiftUI)
- `Sources/Orby/Editor/SelectionOverlay.swift` — Handles de sélection et rotation (Canvas SwiftUI)
- `Sources/Orby/Models/AnnotationModel.swift` — Struct Annotation (coordonnées start/end)
- `Sources/Orby/Models/ImageHelpers.swift` — `flattenAnnotations()` pour l'export

### Comment le canvas fonctionne

```
GeometryReader { geo in
    let baseFit = min(geo.width / imgWidth, geo.height / imgHeight, 1.0)
    let baseDw = imgWidth * baseFit   // taille base du canvas (sans zoom)
    let baseDh = imgHeight * baseFit
    let dw = baseDw * zoomLevel       // taille rendue (avec zoom)
    let dh = baseDh * zoomLevel

    ZStack {
        // Background gradient (si activé)
        // Image (frame: dw x dh)
        // Annotations (frame: dw x dh) ← C'EST ICI LE PROBLÈME
        // SelectionOverlay (frame: dw x dh) ← AUSSI CLIPPÉ
    }
    .frame(width: dw, height: dh)
}
```

Les annotations sont stockées en **coordonnées base** (baseDw x baseDh) et rendues avec `* zoomLevel`. Tout est dans un Canvas SwiftUI qui a un frame fixe `dw x dh` — le Canvas ne dessine rien au-delà de son frame.

### Système de zoom (récemment refactoré)

Le zoom est maintenant **vectoriel** : au lieu de `.scaleEffect(zoomLevel)` (qui rasterise), le canvas est rendu à `baseDw * zoomLevel x baseDh * zoomLevel` avec les annotations multipliées par zoomLevel dans le Canvas. Résultat : annotations nettes à tout niveau de zoom.

### Export (`flattenAnnotations` dans ImageHelpers.swift)

```swift
let sx = imgSize.width / canvasSize.width
let sy = imgSize.height / canvasSize.height
// Puis chaque annotation.start/end est multipliée par sx/sy
```

`canvasSize` est `baseDw x baseDh` (sans zoom). L'export mappe les coordonnées canvas vers les pixels de l'image.

## Ce qu'il faut changer

### 1. Canvas dynamique qui s'étend

Quand une annotation dépasse les limites de l'image (start.x < 0, end.y < 0, etc.), le canvas doit s'agrandir pour l'inclure.

Calculer le **bounding box global** de toutes les annotations :
```
minX = min(0, min de tous les annotation.start.x, annotation.end.x)
minY = min(0, min de tous les annotation.start.y, annotation.end.y)
maxX = max(baseDw, max de tous les annotation.end.x, annotation.start.x)
maxY = max(baseDh, max de tous les annotation.end.y, annotation.start.y)
```

Le canvas effectif = `(maxX - minX) x (maxY - minY)` avec un offset pour les annotations en négatif.

### 2. Background étendu

La zone ajoutée autour de l'image doit avoir la **couleur dominante de l'image** (déjà implémenté dans `dominantBackgroundColor` / `extractDominantColor()`).

### 3. Export étendu

`flattenAnnotations` doit créer une image plus grande que l'originale si des annotations dépassent. L'image originale est placée au centre (ou à l'offset correct), les annotations sont dessinées sur l'ensemble.

### 4. Handles jamais coupés

Les SelectionOverlay et HoverOverlay doivent pouvoir dessiner au-delà des limites de l'image. Le Canvas frame doit inclure la marge pour les handles (le handle de rotation est à -25pt au-dessus de l'annotation).

## Approches possibles

### Approche A : Canvas oversize fixe
Ajouter un padding fixe (ex: 100pt) autour du canvas. L'image est centrée, les annotations peuvent déborder dans cette marge. Simple mais gaspille de l'espace.

### Approche B : Canvas dynamique (comme Shottr)
Calculer le bounding box de toutes les annotations et ajuster le canvas en temps réel. Plus complexe mais meilleur UX. L'offset de toutes les coordonnées doit être recalculé quand le canvas change.

### Approche C : Overlay séparé pour les handles
Séparer le rendu des annotations (Canvas) du rendu des handles (SwiftUI views positionnées en absolu). Les handles n'ont pas besoin d'être dans un Canvas, ce sont des petits rectangles/cercles SwiftUI positionnés via `.position()` dans un ZStack sans frame contraint.

## Notes techniques

- SwiftUI Canvas ne dessine rien au-delà de son frame — c'est la cause du clipping
- `.clipped()` est nécessaire sur le canvas principal pour ne pas passer par-dessus la toolbar
- Les coordonnées des annotations sont en espace "base" (baseDw x baseDh), actuellement 0..baseDw / 0..baseDh. Si le canvas s'étend, il faut supporter des coordonnées négatives
- L'export dans `flattenAnnotations` doit être adapté pour le canvas étendu
- Le background tool (`bgConfig`) interagit avec le canvas via `bgShrink` — à prendre en compte
