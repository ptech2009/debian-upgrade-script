#!/bin/bash

# Hinweis: Bitte führen Sie vor dem Upgrade ein vollständiges System-Backup durch!

# Skript-Optionen initialisieren
AUTO_REBOOT=false

usage() {
    echo "Verwendung: $0 [Optionen]"
    echo "Optionen:"
    echo "  --auto-reboot            Führt am Ende des Upgrades automatisch einen Neustart durch"
    echo "  -h, --help               Zeigt diese Hilfe an"
    exit 0
}

# Kommandozeilenoptionen verarbeiten
while [[ $# -gt 0 ]]; do
    case $1 in
        --auto-reboot)
            AUTO_REBOOT=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unbekannte Option: $1"
            usage
            ;;
    esac
done

# Lock-File einrichten, um Mehrfachausführung zu verhindern
LOCKFILE="/tmp/debian-upgrade.lock"
exec 200>"$LOCKFILE"

flock -n 200 || exit 1

# Ziel-Debian-Version festlegen (kann angepasst werden)
TARGET_VERSION="bookworm"  # Beispiel: "bookworm" für Debian 12

# Funktion zum Überprüfen der Erreichbarkeit der Debian-Server
check_connection() {
    if command -v curl &> /dev/null; then
        if ! curl -s --head http://deb.debian.org/ | grep "200 OK" > /dev/null; then
            echo "Fehler: Debian-Server sind nicht erreichbar. Bitte prüfen Sie Ihre Netzwerkverbindung." >&2
            exit 1
        fi
    elif command -v wget &> /dev/null; then
        if ! wget -q --spider http://deb.debian.org/; then
            echo "Fehler: Debian-Server sind nicht erreichbar. Bitte prüfen Sie Ihre Netzwerkverbindung." >&2
            exit 1
        fi
    else
        echo "Fehler: Weder 'curl' noch 'wget' sind installiert. Installiere 'curl'..."
        apt-get update
        apt-get install -y curl
        if ! curl -s --head http://deb.debian.org/ | grep "200 OK" > /dev/null; then
            echo "Fehler: Debian-Server sind nicht erreichbar. Bitte prüfen Sie Ihre Netzwerkverbindung." >&2
            exit 1
        fi
    fi
}

# Sicherstellen, dass das Skript als root ausgeführt wird
if [ "$(id -u)" -ne 0 ]; then
    echo "Dieses Skript muss als root ausgeführt werden." >&2
    exit 1
fi

# Logging einrichten
LOGFILE="/var/log/debian-upgrade.log"
LOGDIR=$(dirname "$LOGFILE")
mkdir -p "$LOGDIR"  # Log-Verzeichnis erstellen, falls nicht vorhanden
exec > >(tee -a "$LOGFILE") 2>&1  # Alles in die Konsole und ins Logfile schreiben

echo "Starte Debian Upgrade Skript..."

# Überprüfung auf installierte Fremdpakete
echo "Überprüfe auf installierte Fremdpakete..."
if ! command -v aptitude &> /dev/null; then
    apt-get update
    apt-get install -y aptitude
fi

FOREIGN_PACKAGES=$(aptitude search '~i!~ODebian' -F '%p')
if [ -n "$FOREIGN_PACKAGES" ]; then
    echo "Es wurden Fremdpakete gefunden:"
    echo "$FOREIGN_PACKAGES"
    read -p "Möchten Sie die Fremdpakete vor dem Upgrade entfernen? [j/N]: " REMOVE_FOREIGN
    if [[ "$REMOVE_FOREIGN" =~ ^[Jj]$ ]]; then
        echo "Entferne Fremdpakete..."
        apt-get remove --purge -y $FOREIGN_PACKAGES
    else
        echo "Hinweis: Fremdpakete könnten das Upgrade beeinträchtigen."
    fi
else
    echo "Keine Fremdpakete gefunden."
fi

# Überprüfung auf nicht offizielle Debian-Repositories
echo "Überprüfe auf nicht offizielle Debian-Repositories..."
EXTERNAL_REPOS=$(grep -rE '^(deb|deb-src) ' /etc/apt/sources.list /etc/apt/sources.list.d/ | grep -vE 'debian\.org|security\.debian\.org|ftp\.debian\.org|deb\.debian\.org')
if [ -n "$EXTERNAL_REPOS" ]; then
    echo "Es wurden nicht offizielle Debian-Repositories gefunden:"
    echo "$EXTERNAL_REPOS"
    read -p "Möchten Sie die externen Repositories vor dem Upgrade deaktivieren? [j/N]: " DISABLE_EXTERNAL
    if [[ "$DISABLE_EXTERNAL" =~ ^[Jj]$ ]]; then
        echo "Deaktiviere externe Repositories..."
        for FILE in $(echo "$EXTERNAL_REPOS" | cut -d: -f1 | sort | uniq); do
            mv "$FILE" "${FILE}.disabled"
        done
    else
        echo "Hinweis: Externe Repositories könnten das Upgrade beeinträchtigen."
    fi
else
    echo "Keine externen Repositories gefunden."
fi

# Überprüfung des verfügbaren Speicherplatzes
echo "Überprüfe den verfügbaren Speicherplatz..."
FREE_SPACE=$(df --output=avail -BG / | tail -1 | tr -d 'G')
if [ "$FREE_SPACE" -lt 5 ]; then  # 5 GB
    echo "Warnung: Weniger als 5 GB freier Speicherplatz verfügbar. Dies könnte das Upgrade behindern."
    exit 1
else
    echo "Genügend Speicherplatz verfügbar: ${FREE_SPACE}G"
fi

# Überprüfung auf ausstehende Konfigurationsänderungen
echo "Überprüfe auf ausstehende Konfigurationsänderungen..."
PENDING_CONFIGS=$(find /etc -name '*.dpkg-new' -o -name '*.ucf-dist')
if [ -n "$PENDING_CONFIGS" ]; then
    echo "Es wurden ausstehende Konfigurationsänderungen gefunden:"
    echo "$PENDING_CONFIGS"
    echo "Hinweis: Ausstehende Konfigurationsänderungen könnten das Upgrade beeinflussen."
else
    echo "Keine ausstehenden Konfigurationsänderungen gefunden."
fi

# Aktuelle Debian-Version automatisch erkennen
if ! command -v lsb_release &> /dev/null; then
    apt-get update
    apt-get install -y lsb-release
fi
CURRENT_VERSION=$(lsb_release -cs)
echo "Aktuelle Debian-Version erkannt: $CURRENT_VERSION"

echo "Ziel-Debian-Version: $TARGET_VERSION"

# Überprüfung, ob ein Upgrade erforderlich ist
if [ "$CURRENT_VERSION" == "$TARGET_VERSION" ]; then
    echo "Das System ist bereits auf dem neuesten Stand."
    exit 0
fi

echo "Das System wird von $CURRENT_VERSION auf $TARGET_VERSION aktualisiert."

# Verbindungstest zu den Debian-Servern
echo "Überprüfe die Erreichbarkeit der Debian-Server..."
check_connection
echo "Debian-Server sind erreichbar."

# Automatische Überprüfung der Paketquellen
echo "Überprüfe, ob die Debian-Version '$TARGET_VERSION' verfügbar ist..."
if ! curl -sI "http://ftp.debian.org/debian/dists/$TARGET_VERSION/Release" | grep -q "200 OK"; then
    echo "Fehler: Die Debian-Version '$TARGET_VERSION' ist nicht gültig oder nicht verfügbar." >&2
    exit 1
fi
echo "Die Debian-Version '$TARGET_VERSION' ist gültig."

# Backup-Verzeichnis erstellen
BACKUP_DIR="/root/sources_backup_$(date +%Y%m%d%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Erstelle Backup der sources.list Dateien..."

# Backup der sources.list und zugehöriger Dateien
cp -r /etc/apt/sources.list* "$BACKUP_DIR"

echo "Backup abgeschlossen und gespeichert unter: $BACKUP_DIR"

# System auf den neuesten Stand bringen und Fehler beheben
echo "Aktualisiere das aktuelle System und behebe mögliche Paketfehler..."
apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y
apt-get --fix-broken install -y
apt-get --purge autoremove -y
apt-get autoclean -y

# Paketquellen auf die neue Version ändern
echo "Aktualisiere Paketquellen auf '$TARGET_VERSION'..."

for FILE in /etc/apt/sources.list /etc/apt/sources.list.d/*.list; do
    if [ -f "$FILE" ]; then
        sed -i.bak -E "s/^(deb.* )(stable|testing|unstable|sid|$CURRENT_VERSION)( .*)/\1$TARGET_VERSION\3/" "$FILE"
    fi
done

echo "Paketquellen wurden erfolgreich auf '$TARGET_VERSION' geändert."

# Systemaktualisierung auf die neue Debian-Version
echo "Starte Systemaktualisierung auf Debian $TARGET_VERSION..."
apt-get update

echo "Führe minimale Systemaktualisierung durch..."
apt-get upgrade -y

echo "Führe vollständige Systemaktualisierung durch..."
apt-get dist-upgrade -y

apt-get --purge autoremove -y
apt-get autoclean -y

# Letzter Neustart
echo "Das Upgrade ist abgeschlossen. Das System muss neu gestartet werden, um alle Änderungen anzuwenden."
if [ "$AUTO_REBOOT" = true ]; then
    read -p "Möchten Sie das System jetzt neu starten? [j/N]: " REBOOT_CONFIRM
    if [[ "$REBOOT_CONFIRM" =~ ^[Jj]$ ]]; then
        echo "System wird jetzt neu gestartet..."
        reboot
    else
        echo "Bitte starten Sie das System manuell neu, um das Upgrade abzuschließen."
    fi
else
    echo "Bitte starten Sie das System manuell neu, um das Upgrade abzuschließen."
fi
