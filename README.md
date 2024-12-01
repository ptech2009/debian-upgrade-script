Debian Upgrade Script
Overview

This script automates the process of upgrading a Debian-based system. It provides comprehensive safety checks and interactive options to ensure a smooth and secure upgrade experience.
🚀 Features

    🛡 Safety: Prevents multiple executions by using a lock file.
    🔑 Root Privilege Check: Ensures the script is run with root privileges.
    📡 Automatic Version Detection: Automatically detects the current Debian version.
    ✍️ Manual Target Version: Allows specifying a target Debian version by adjusting the TARGET_VERSION variable in the script.
    🌐 Connection Check: Verifies connectivity to Debian servers.
    🔧 Source Update: Updates package sources and backs up existing configurations.
    🗑 Foreign Package Detection: Identifies and offers to remove non-official Debian packages.
    💾 Disk Space Check: Verifies available disk space before upgrading.
    🔍 Configuration Backup: Creates backups of existing configuration files and package sources.
    🛠 System Update: Updates the system to the latest packages of the current version.
    🔄 Interactive Decisions: Provides the user with control over critical steps during the upgrade.
    🔁 Automatic Reboot: Optionally reboots the system after the upgrade is complete.

🛠 Requirements

    Debian-based system
    Root privileges
    Active internet connection
    aptitude, lsb-release, curl or wget (will be installed automatically if not present)

🔧 Usage
Command-Line Options

    --auto-reboot: Automatically reboots the system after the upgrade is complete.
    --assume-yes, --non-interactive: Automatically answers all prompts with 'Yes'.
    --keep-foreign-packages: Keeps foreign (non-official Debian) packages.
    --keep-external-repos: Keeps external repositories.
    -h, --help: Displays the help message with usage instructions.

Examples

Upgrade with Automatic Reboot:

sudo ./debian-upgrade.sh --assume-yes --auto-reboot

Upgrade with Manual Control:

sudo ./debian-upgrade.sh

Upgrade without Removing Foreign Packages and Disabling External Repositories:

sudo ./debian-upgrade.sh --assume-yes --keep-foreign-packages --keep-external-repos

Note: The script may require user input during execution to confirm decisions unless the --assume-yes option is used.
📝 Manually Specify Target Version

By default, the target Debian version is set within the script. To change the target version, modify the following line in the script:

TARGET_VERSION="bookworm"  # Example for Debian 12

Replace "bookworm" with the codename or version number of the desired Debian version.

Caution: Manual changes to the script should be made carefully.
🖥 Installation

Download the Script: Clone the repository or download the script directly.

git clone https://github.com/ptech2009/debian-upgrade-script.git

Navigate to the Script Directory:

cd debian-upgrade-script

Make the Script Executable:

chmod +x debian-upgrade.sh

Run the Script:

sudo ./debian-upgrade.sh [options]

🔖 Versioning

This project follows Semantic Versioning. Check the repository's tags for available versions.
📄 License

This project is licensed under the MIT License. See the LICENSE file for details.
✉️ Contact

For any questions or suggestions, feel free to reach out via GitHub Issues or email: ptech09@schumacher.or.at.



Beschreibung in Deutsch: 

Debian Upgrade Skript
Übersicht

Dieses Skript automatisiert den Prozess des Upgrades eines Debian-basierten Systems. Es bietet umfassende Sicherheitsprüfungen und interaktive Optionen, um ein reibungsloses und sicheres Upgrade zu gewährleisten.
🚀 Funktionen

    🛡 Sicherheit: Verhindert Mehrfachausführungen durch Verwendung einer Lock-Datei.
    🔑 Root-Rechte Prüfung: Stellt sicher, dass das Skript mit Root-Rechten ausgeführt wird.
    📡 Automatische Versionserkennung: Erkennt automatisch die aktuelle Debian-Version.
    ✍️ Manuelle Zielversion: Ermöglicht das Festlegen einer Ziel-Debian-Version durch Anpassen der TARGET_VERSION-Variable im Skript.
    🌐 Verbindungsprüfung: Überprüft die Erreichbarkeit der Debian-Server.
    🔧 Quellenaktualisierung: Aktualisiert die Paketquellen und sichert bestehende Konfigurationen.
    🗑 Fremdpakete erkennen: Identifiziert und bietet an, nicht-offizielle Debian-Pakete zu entfernen.
    💾 Speicherplatzprüfung: Überprüft den verfügbaren Speicherplatz vor dem Upgrade.
    🔍 Konfigurations-Backup: Erstellt Backups der bestehenden Konfigurationsdateien und Paketquellen.
    🛠 Systemaktualisierung: Aktualisiert das System auf die neuesten Pakete der aktuellen Version.
    🔄 Interaktive Entscheidungen: Bietet dem Benutzer Kontrolle über kritische Schritte während des Upgrades.
    🔁 Automatischer Neustart: Option, das System nach Abschluss des Upgrades automatisch neu zu starten.

🛠 Anforderungen

    Debian-basiertes System
    Root-Rechte
    Aktive Internetverbindung
    aptitude, lsb-release, curl oder wget (werden automatisch installiert, falls nicht vorhanden)

🔧 Verwendung
Kommandozeilenoptionen

    --auto-reboot: Führt am Ende des Upgrades automatisch einen Neustart durch.
    --assume-yes, --non-interactive: Beantwortet alle Eingabeaufforderungen automatisch mit 'Ja'.
    --keep-foreign-packages: Behält Fremdpakete bei.
    --keep-external-repos: Behält externe Repositories bei.
    -h, --help: Zeigt die Hilfe mit Verwendungshinweisen an.

Beispiele

Upgrade mit automatischem Neustart:

sudo ./debian-upgrade.sh --assume-yes --auto-reboot

Upgrade mit manueller Kontrolle:

sudo ./debian-upgrade.sh

Upgrade ohne Entfernen von Fremdpaketen und Deaktivieren externer Repositories:

sudo ./debian-upgrade.sh --assume-yes --keep-foreign-packages --keep-external-repos

Hinweis: Das Skript kann während der Ausführung Benutzereingaben erfordern, um Entscheidungen zu bestätigen, es sei denn, die Option --assume-yes wird verwendet.
📝 Manuelles Festlegen der Zielversion

Standardmäßig ist die Ziel-Debian-Version im Skript festgelegt. Um die Zielversion zu ändern, passen Sie die folgende Zeile im Skript an:

TARGET_VERSION="bookworm"  # Beispiel für Debian 12

Ersetzen Sie "bookworm" durch den Codenamen oder die Versionsnummer der gewünschten Debian-Version.

Achtung: Manuelle Änderungen am Skript sollten sorgfältig vorgenommen werden.
🖥 Installation

Skript herunterladen: Laden Sie das Skript herunter oder klonen Sie das Repository.

git clone https://github.com/ptech2009/debian-upgrade-script.git

In das Skriptverzeichnis wechseln:

cd debian-upgrade-script

Skript ausführbar machen:

chmod +x debian-upgrade.sh

Skript ausführen:

sudo ./debian-upgrade.sh [Optionen]

🔖 Versionierung

Dieses Projekt folgt dem Semantic Versioning. Überprüfen Sie die Tags des Repositories für verfügbare Versionen.
📄 Lizenz

Dieses Projekt ist unter der MIT-Lizenz lizenziert. Siehe die Datei LICENSE für Details.
✉️ Kontakt

Bei Fragen oder Anregungen können Sie gerne über GitHub Issues oder per E-Mail Kontakt aufnehmen: ptech09@schumacher.or.at.
