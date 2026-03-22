# Orby — Landing Page Specification

## Produit

Orby est une app macOS menu bar de capture d'écran. Alternative gratuite et open-source à CleanShot X. Légère, rapide, bilingue FR/EN.

**Couleur brand** : violet `#9F01A0` (brandPurple)
**Couleurs secondaires** : fond clair lavande `#f6e7fd`, textes sombres `#1a1a1a`
**Font** : Inter Variable (déjà installée)
**Cible** : développeurs, designers, créateurs de contenu sur macOS
**Prix** : Gratuit, open-source (MIT)
**Téléchargement** : DMG via GitHub Releases → `https://github.com/jeremy-prt/orby/releases`
**Repo** : `https://github.com/jeremy-prt/orby`

## Structure de la page

### 1. Header (sticky, glassmorphism)
- Navbar flottante avec fond blur (`backdrop-blur-xl`) + semi-transparent
- Logo Orby à gauche + nom "Orby"
- Liens : Features, Download, GitHub
- Bouton CTA "Download" (violet brand)
- Au scroll : le header se rétracte légèrement, ombre apparaît
- Responsive : hamburger menu sur mobile

### 2. Hero Section
- Titre principal : "Capture your screen, beautifully." / "Capturez votre écran, élégamment."
- Sous-titre : description courte du produit
- 2 boutons : "Download .DMG" (violet) + "View on GitHub" (outline)
- Badge "macOS 15+ • Free • Open Source"
- **Vidéo hero** : vidéo autoplay muette en loop montrant une capture rapide → preview → edit (format MP4, max 10s)
- La vidéo est dans un mockup macOS (cadre de fenêtre arrondi avec shadow)

### 3. Features Grid (3-4 colonnes)
Chaque feature = icône + titre + description courte
- Capture rapide (plein écran, zone, fenêtre)
- OCR intégré
- Preview flottante
- Éditeur complet
- Background tool
- Historique des captures
- Auto-update
- Bilingue FR/EN

### 4. Sections Features détaillées (avec vidéos)
3-4 sections alternées (texte à gauche / vidéo à droite, puis inversé) :

**Section A — Capture & Preview**
- Texte : "Capture in a flash. Full screen, area, or window — with a floating preview that lets you copy, edit, save, or drag & drop instantly."
- Vidéo : capture d'écran → preview flottante avec hover → copier

**Section B — Powerful Editor**
- Texte : "Annotate with precision. Arrows, text, blur, numbered steps, freehand draw — everything you need to communicate visually."
- Vidéo : ouverture éditeur → ajout rectangle + flèche + texte + numéro

**Section C — Beautiful Backgrounds**
- Texte : "Make your screenshots shine. Add gradient backgrounds, padding, rounded corners and shadows — like the pros."
- Vidéo : activation background → choix gradient → résultat

**Section D — Share Anywhere**
- Texte : "Share in one click. AirDrop, Messages, Mail, or save anywhere with ⌘S."
- Vidéo : bouton share → menu système → envoi

### 5. Section raccourcis clavier
Tableau visuel avec les raccourcis (style clavier, badges arrondis)

### 6. Download CTA
- Grand bloc centré avec le bouton de téléchargement
- Texte : "Ready to try Orby?"
- Bouton "Download for macOS" (gros, violet)
- Lien secondaire "View source on GitHub"
- Badge "Free forever • Open Source • No account needed"

### 7. Footer
- Logo + "Orby"
- Liens : GitHub, Releases, License (MIT)
- "Made by Jeremy Perret"
- Copyright 2025

## Vidéos / Animations

**Format recommandé : MP4 (pas de GIF)**
- Les GIF sont lourds et de mauvaise qualité
- Les MP4 avec `<video autoplay muted loop playsinline>` sont légers, nets, et se lancent automatiquement
- Pas besoin de YouTube — les vidéos sont hébergées directement dans le repo ou en assets GitHub Release
- Format : 1280x800 ou 1440x900, max 10s par vidéo, compressées H.264
- Poids cible : < 2 MB par vidéo

**Alternative temporaire** : si les vidéos ne sont pas prêtes, utiliser des screenshots statiques avec un overlay "play" ou des captures d'écran annotées.

## Style & Design

- **Glassmorphism** : header, certaines cards (backdrop-blur, bg opacity, border subtle)
- **Gradients subtils** : sections alternées avec fond légèrement dégradé
- **Ombres douces** : cards, vidéos mockups, boutons
- **Animations au scroll** : fade-in + slide-up des sections (CSS `@keyframes` ou IntersectionObserver)
- **Dark mode** : prévoir un toggle ou respecter `prefers-color-scheme`
- **Responsive** : mobile-first, grille adaptative
- **Pas de framework UI** : Tailwind suffit, pas besoin de component library

## Stack technique

- **Nuxt 4** (déjà setup)
- **Tailwind CSS v4** (déjà setup)
- **@fontsource-variable/inter** (déjà installé)
- **Nuxt Icon** (`@nuxt/icon`, déjà dans les modules) pour les icônes
- **Pas de CMS** : contenu hardcodé dans les composants Vue
- **Déploiement** : GitHub Pages via GitHub Actions (workflow à créer)

## Fichiers à créer

```
website/
├── app/
│   ├── app.vue                    # Layout principal
│   ├── pages/
│   │   └── index.vue              # Landing page
│   ├── components/
│   │   ├── Header.vue             # Navbar sticky glassmorphism
│   │   ├── Hero.vue               # Hero section avec vidéo
│   │   ├── FeaturesGrid.vue       # Grille features
│   │   ├── FeatureSection.vue     # Section feature avec vidéo (réutilisable)
│   │   ├── Shortcuts.vue          # Tableau raccourcis
│   │   ├── DownloadCTA.vue        # Bloc téléchargement
│   │   └── Footer.vue             # Footer
│   └── assets/
│       ├── css/main.css           # Tailwind + Inter (existe déjà)
│       └── videos/                # Vidéos MP4 des features
├── public/
│   ├── logo.png                   # Logo Orby
│   └── favicon.png                # Favicon
└── nuxt.config.ts                 # Config (existe déjà)
```

## Internationalisation

Pour l'instant : contenu en anglais uniquement sur la landing. Le toggle FR/EN peut être ajouté plus tard avec `@nuxtjs/i18n`.
