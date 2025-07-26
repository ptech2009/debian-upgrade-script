Debian Upgrade Script Overview

This script automates the process of upgrading a Debian-based system. It provides comprehensive safety checks and interactive options to ensure a smooth and secure upgrade experience.

🚀 Features

    🛡 Safety: Prevents multiple executions by using a lock file.
    🔑 Root Privilege Check: Ensures the script is run with root privileges.
    🌐 Localization: Supports both English and German languages. Users can select their preferred language at the start.
    📡 Automatic Version Detection: Automatically detects the current Debian version.
    🎯 Automatic Target Version: If TARGET_VERSION is set to "auto" (default), the script determines the current Debian stable release.
    ✍️ Manual Target Version: Allows specifying a target Debian version by adjusting the TARGET_VERSION variable in the script.
    🌐 Connection Check: Verifies connectivity to Debian servers.
    🔧 Source Update: Updates package sources and backs up existing configurations.
    🗑 Foreign Package Detection: Identifies and offers to remove non-official Debian packages.
    🗄️ Pending Configuration Handling: Detects pending configuration changes and offers options to resolve them.
    💾 Disk Space Check: Verifies available disk space before upgrading.
    📋 Log Management: Implements log rotation to prevent the log file from growing indefinitely.
    🔍 Configuration Backup: Creates backups of existing configuration files and package sources.
    🛠 System Update: Updates the system to the latest packages of the current version.
    🔄 Interactive Decisions: Provides the user with control over critical steps during the upgrade.
    🔁 Automatic Reboot: Optionally reboots the system after the upgrade is complete.

🛠 Requirements

    Debian-based system
    Root privileges
    Active internet connection
    aptitude, lsb-release, curl or wget (will be installed automatically if not present)

🔧 Usage Command-Line Options

    --auto-reboot: Automatically reboots the system after the upgrade is complete.
    --assume-yes, --non-interactive: Automatically answers all prompts with 'Yes'.
    --keep-foreign-packages: Keeps foreign (non-official Debian) packages.
    --keep-external-repos: Keeps external repositories.
    -h, --help: Displays the help message with usage instructions.

💡 Examples

Upgrade with Automatic Reboot:

sudo ./debian-upgrade.sh --assume-yes --auto-reboot

Upgrade with Manual Control:

sudo ./debian-upgrade.sh

Upgrade without Removing Foreign Packages and Disabling External Repositories:

sudo ./debian-upgrade.sh --assume-yes --keep-foreign-packages --keep-external-repos

Note: The script now supports both English and German languages. At the start of the script, you will be prompted to select your preferred language.

📝 Manually Specify Target Version

By default, the script sets TARGET_VERSION to "auto" and upgrades to the current Debian stable release. To upgrade to a specific version, modify the following line in the script:

TARGET_VERSION="auto"  # Automatically use the latest stable release

Replace "auto" with the codename or version number of the desired Debian version.

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

Please note: Perform a complete system backup before the upgrade. Although the script contains numerous security measures, unexpected problems may occur in rare cases.


Beschreibung in Deutsch:

Debian Upgrade Skript Übersicht

Dieses Skript automatisiert den Prozess des Upgrades eines Debian-basierten Systems. Es bietet umfassende Sicherheitsprüfungen und interaktive Optionen, um ein reibungsloses und sicheres Upgrade zu gewährleisten.

🚀 Funktionen

    🛡 Sicherheit: Verhindert Mehrfachausführungen durch Verwendung einer Lock-Datei.
    🔑 Root-Rechte Prüfung: Stellt sicher, dass das Skript mit Root-Rechten ausgeführt wird.
    🌐 Lokalisierung: Unterstützt Deutsch und Englisch. Zu Beginn können Sie Ihre bevorzugte Sprache auswählen.
    📡 Automatische Versionserkennung: Erkennt automatisch die aktuelle Debian-Version.
    🎯 Automatische Zielversion: Bei "auto" (Standard) ermittelt das Skript automatisch die aktuelle Debian-Stable-Version.
    ✍️ Manuelle Zielversion: Ermöglicht das Festlegen einer Ziel-Debian-Version durch Anpassen der TARGET_VERSION-Variable im Skript.
    🌐 Verbindungsprüfung: Überprüft die Erreichbarkeit der Debian-Server.
    🔧 Quellenaktualisierung: Aktualisiert die Paketquellen und sichert bestehende Konfigurationen.
    🗑 Fremdpakete erkennen: Identifiziert und bietet an, nicht-offizielle Debian-Pakete zu entfernen.
    🗄️ Ausstehende Konfigurationsänderungen: Erkennt ausstehende Konfigurationsänderungen und bietet Optionen zu deren Behandlung.
    💾 Speicherplatzprüfung: Überprüft den verfügbaren Speicherplatz vor dem Upgrade.
    📋 Log-Verwaltung: Implementiert eine Logrotation, um das unkontrollierte Wachsen der Log-Datei zu verhindern.
    🔍 Konfigurations-Backup: Erstellt Backups der bestehenden Konfigurationsdateien und Paketquellen.
    🛠 Systemaktualisierung: Aktualisiert das System auf die neuesten Pakete der aktuellen Version.
    🔄 Interaktive Entscheidungen: Bietet dem Benutzer Kontrolle über kritische Schritte während des Upgrades.
    🔁 Automatischer Neustart: Option, das System nach Abschluss des Upgrades automatisch neu zu starten.

🛠 Anforderungen

    Debian-basiertes System
    Root-Rechte
    Aktive Internetverbindung
    aptitude, lsb-release, curl oder wget (werden automatisch installiert, falls nicht vorhanden)

🔧 Verwendung Kommandozeilenoptionen

    --auto-reboot: Führt am Ende des Upgrades automatisch einen Neustart durch.
    --assume-yes, --non-interactive: Beantwortet alle Eingabeaufforderungen automatisch mit 'Ja'.
    --keep-foreign-packages: Behält Fremdpakete bei.
    --keep-external-repos: Behält externe Repositories bei.
    -h, --help: Zeigt die Hilfe mit Verwendungshinweisen an.

💡 Beispiele

Upgrade mit automatischem Neustart:

sudo ./debian-upgrade.sh --assume-yes --auto-reboot

Upgrade mit manueller Kontrolle:

sudo ./debian-upgrade.sh

Upgrade ohne Entfernen von Fremdpaketen und Deaktivieren externer Repositories:

sudo ./debian-upgrade.sh --assume-yes --keep-foreign-packages --keep-external-repos

Hinweis: Das Skript unterstützt nun sowohl Deutsch als auch Englisch. Zu Beginn des Skripts werden Sie aufgefordert, Ihre bevorzugte Sprache auszuwählen.

📝 Manuelles Festlegen der Zielversion

Standardmäßig ist TARGET_VERSION auf "auto" gesetzt und das Skript aktualisiert auf die jeweils aktuelle Debian-Stable-Version. Um eine bestimmte Version zu wählen, ändern Sie folgende Zeile im Skript:

TARGET_VERSION="auto"  # Nutzt automatisch die aktuell stabile Version

Ersetzen Sie "auto" durch den Codenamen oder die Versionsnummer der gewünschten Debian-Version.

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

Dieses Projekt ist unter der MIT-Lizenz lizenziert. Siehe die LICENSE Datei für Details.

✉️ Kontakt

Bei Fragen oder Anregungen können Sie gerne über GitHub Issues oder per E-Mail Kontakt aufnehmen: ptech09@schumacher.or.at.

Bitte beachten Sie: Führen Sie vor dem Upgrade ein vollständiges System-Backup durch. Obwohl das Skript zahlreiche Sicherheitsmaßnahmen enthält, kann es in seltenen Fällen zu unerwarteten Problemen kommen.
