import Foundation

/// Simple in-app localization based on UserDefaults "appLanguage" key
enum L10n {
    static var lang: String {
        UserDefaults.standard.string(forKey: "appLanguage") ?? "fr"
    }

    static func tr4(_ en: String, _ fr: String, _ es: String, _ de: String) -> String {
        switch lang {
        case "de": return de
        case "es": return es
        case "fr": return fr
        default: return en
        }
    }

    // MARK: - Preview tooltips
    static var tooltipCopy: String { tr4("Copy to clipboard", "Copier dans le presse-papier", "Copiar al portapapeles", "In die Zwischenablage kopieren") }
    static var tooltipSave: String { tr4("Save to disk", "Sauvegarder sur le disque", "Guardar en disco", "Auf der Festplatte speichern") }
    static var tooltipPin: String { tr4("Pin", "Épingler", "Fijar", "Anheften") }
    static var tooltipUnpin: String { tr4("Unpin", "Désépingler", "Desfijar", "Loslösen") }
    static var tooltipClose: String { tr4("Close", "Fermer", "Cerrar", "Schließen") }
    static var tooltipEdit: String { tr4("Annotate", "Annoter", "Anotar", "Kommentieren") }

    // MARK: - Menu
    static var menuCapture: String { tr4("Capture", "Capturer", "Capturar", "Aufnahme") }
    static var menuSettings: String { tr4("Settings", "Réglages", "Ajustes", "Einstellungen") }
    static var menuQuit: String { tr4("Quit", "Quitter", "Salir", "Beenden") }

    // MARK: - Settings
    static var settingsGeneral: String { tr4("General", "Général", "General", "Allgemein") }
    static var settingsCapture: String { tr4("Capture", "Capture", "Captura", "Aufnahme") }
    static var settingsSave: String { tr4("Save", "Sauvegarde", "Guardar", "Speichern") }

    static var shortcut: String { tr4("Shortcut", "Raccourci", "Atajo", "Tastaturkürzel") }
    static var screenshot: String { tr4("Screenshot", "Capture d'écran", "Captura de pantalla", "Screenshot") }
    static var startup: String { tr4("Startup", "Démarrage", "Inicio", "Start") }
    static var launchAtLogin: String { tr4("Launch at login", "Lancer au démarrage", "Iniciar al arrancar", "Beim Anmelden starten") }
    static var language: String { tr4("Language", "Langue", "Idioma", "Sprache") }
    static var interfaceLanguage: String { tr4("Interface language", "Langue de l'interface", "Idioma de la interfaz", "Oberflächensprache") }

    static var previewPosition: String { tr4("Preview position", "Position de la prévisualisation", "Posición de la vista previa", "Vorschauposition") }
    static var autoDismiss: String { tr4("Auto close", "Fermeture automatique", "Cierre automático", "Automatisch schließen") }
    static var delay: String { tr4("Delay", "Délai", "Retraso", "Verzögerung") }
    static var autoDismissDescription: String { tr4("Time before the preview disappears", "Durée avant que la prévisualisation disparaisse", "Tiempo antes de que desaparezca la vista previa", "Zeit vor dem Schließen der Vorschau") }
    static var afterAction: String { tr4("After action", "Après une action", "Después de una acción", "Nach einer Aktion") }
    static var closeAfterAction: String { tr4("Close after Copy / Save", "Fermer après Copy / Save", "Cerrar después de Copiar / Guardar", "Nach Kopieren/Speichern schließen") }
    static var closeAfterActionDescription: String { tr4("Automatically close the preview after copying or saving", "Ferme automatiquement la prévisualisation après avoir copié ou sauvegardé", "Cierra automáticamente la vista previa después de copiar o guardar", "Vorschau nach dem Kopieren oder Speichern automatisch schließen") }

    static var imageFormat: String { tr4("Image format", "Format d'image", "Formato de imagen", "Bildformat") }
    static var format: String { tr4("Format", "Format", "Formato", "Format") }
    static var destinationFolder: String { tr4("Destination folder", "Dossier de destination", "Carpeta de destino", "Zielordner") }
    static var choose: String { tr4("Choose...", "Choisir...", "Elegir...", "Auswählen...") }
    static var resetToDesktop: String { tr4("Reset to Desktop", "Remettre Bureau par défaut", "Restablecer a Escritorio", "Auf Desktop zurücksetzen") }
    static var chooseFolder: String { tr4("Choose save folder", "Choisir le dossier de sauvegarde des captures", "Elegir carpeta de guardado", "Speicherordner auswählen") }

    // MARK: - Editor toolbar
    static var editorCopy: String { tr4("Copy", "Copier", "Copiar", "Kopieren") }
    static var editorSave: String { tr4("Save", "Sauvegarder", "Guardar", "Speichern") }
    static var editorApply: String { tr4("Apply", "Appliquer", "Aplicar", "Anwenden") }

    static var pressKey: String { tr4("Press...", "Appuyez...", "Pulsa...", "Drücken...") }
    static var setKey: String { tr4("Set", "Définir", "Definir", "Festlegen") }
    static var installInApps: String { tr4("Install the app in /Applications to enable this option", "Installez l'app dans /Applications pour activer cette option", "Instala la app en /Applications para activar esta opción", "Installieren Sie die App in /Applications, um diese Option zu aktivieren") }
    static var cannotModify: String { tr4("Cannot modify setting", "Impossible de modifier le réglage", "No se puede modificar el ajuste", "Einstellung kann nicht geändert werden") }
}
