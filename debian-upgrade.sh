#!/bin/bash

# Hinweis: Bitte führen Sie vor dem Upgrade ein vollständiges System-Backup durch!

# Skript-Optionen initialisieren
AUTO_REBOOT=false
ASSUME_YES=false
KEEP_FOREIGN_PACKAGES=false
KEEP_EXTERNAL_REPOS=false

# Umgebungsvariable für nicht-interaktiven Modus setzen
export DEBIAN_FRONTEND=noninteractive

usage() {
    echo "Verwendung: $0 [Optionen]"
    echo "Optionen:"
    echo "  --auto-reboot                Führt am Ende des Upgrades automatisch einen Neustart durch"
    echo "  --assume-yes, --non-interactive  Beantwortet alle Eingabeaufforderungen automatisch mit 'Ja'"
    echo "  --keep-foreign-packages      Behält Fremdpakete bei"
    echo "  --keep-external-repos        Behält externe Repositories bei"
    echo "  -h, --help                   Zeigt diese Hilfe an"
    exit 0
}

# Kommandozeilenoptionen verarbeiten
while [[ $# -gt 0 ]]; do
    case $1 in
        --auto-reboot)
            AUTO_REBOOT=true
            shift
            ;;
        --assume-yes|--non-interactive)
            ASSUME_YES=true
            shift
            ;;
        --keep-foreign-packages)
            KEEP_FOREIGN_PACKAGES=true
            shift
            ;;
        --keep-external-repos)
            KEEP_EXTERNAL_REPOS=true
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

# Funktion zur Fehlerprüfung nach Befehlen
run_command() {
    "$@"
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        log "Fehler: Befehl '$*' ist fehlgeschlagen (Exit-Code $EXIT_CODE)." >&2
        exit $EXIT_CODE
    fi
}

# Funktion für Logging mit Zeitstempel
log() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$message"
    echo "$message" >> "$LOGFILE"
}

# Lock-File einrichten, um Mehrfachausführung zu verhindern
LOCKFILE="/tmp/debian-upgrade.lock"
exec 200>"$LOCKFILE"

flock -n 200 || { log "Ein anderes Upgrade-Skript wird bereits ausgeführt."; exit 1; }

# Ziel-Debian-Version festlegen (kann angepasst werden)
TARGET_VERSION="bookworm"  # Beispiel: "bookworm" für Debian 12

# Funktion zum Überprüfen der Erreichbarkeit der Debian-Server
check_connection() {
    if command -v curl &> /dev/null; then
        if ! curl -s --head http://deb.debian.org/ | grep "200 OK" > /dev/null; then
            log "Fehler: Debian-Server sind nicht erreichbar. Bitte prüfen Sie Ihre Netzwerkverbindung." >&2
            exit 1
        fi
    elif command -v wget &> /dev/null; then
        if ! wget -q --spider http://deb.debian.org/; then
            log "Fehler: Debian-Server sind nicht erreichbar. Bitte prüfen Sie Ihre Netzwerkverbindung." >&2
            exit 1
        fi
    else
        log "Fehler: Weder 'curl' noch 'wget' sind installiert. Installiere 'curl'..."
        run_command apt-get update -y
        run_command apt-get install -y curl
        if ! curl -s --head http://deb.debian.org/ | grep "200 OK" > /dev/null; then
            log "Fehler: Debian-Server sind nicht erreichbar. Bitte prüfen Sie Ihre Netzwerkverbindung." >&2
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

log "Starte Debian Upgrade Skript..."

# Überprüfung auf installierte Fremdpakete
log "Überprüfe auf installierte Fremdpakete..."
if ! command -v aptitude &> /dev/null; then
    run_command apt-get update -y
    run_command apt-get install -y aptitude
fi

FOREIGN_PACKAGES=$(aptitude search '~i!~ODebian' -F '%p')
if [ -n "$FOREIGN_PACKAGES" ]; then
    log "Es wurden Fremdpakete gefunden:"
    log "$FOREIGN_PACKAGES"
    if [ "$KEEP_FOREIGN_PACKAGES" = true ]; then
        log "Fremdpakete werden beibehalten aufgrund der Option --keep-foreign-packages."
    else
        if [ "$ASSUME_YES" = true ]; then
            REMOVE_FOREIGN="J"
        else
            echo -n "Möchten Sie die Fremdpakete vor dem Upgrade entfernen? [j/N]: " > /dev/tty
            read REMOVE_FOREIGN < /dev/tty
        fi
        if [[ "$REMOVE_FOREIGN" =~ ^[Jj]$ ]]; then
            log "Entferne Fremdpakete..."
            run_command apt-get remove --purge -y $FOREIGN_PACKAGES
        else
            log "Hinweis: Fremdpakete könnten das Upgrade beeinträchtigen."
        fi
    fi
else
    log "Keine Fremdpakete gefunden."
fi

# Überprüfung auf nicht offizielle Debian-Repositories
log "Überprüfe auf nicht offizielle Debian-Repositories..."
EXTERNAL_REPOS=$(grep -rE '^(deb|deb-src) ' /etc/apt/sources.list /etc/apt/sources.list.d/ | grep -vE 'debian\.org|security\.debian\.org|ftp\.debian\.org|deb\.debian\.org')
if [ -n "$EXTERNAL_REPOS" ]; then
    log "Es wurden nicht offizielle Debian-Repositories gefunden:"
    log "$EXTERNAL_REPOS"
    if [ "$KEEP_EXTERNAL_REPOS" = true ]; then
        log "Externe Repositories werden beibehalten aufgrund der Option --keep-external-repos."
    else
        if [ "$ASSUME_YES" = true ]; then
            DISABLE_EXTERNAL="J"
        else
            echo -n "Möchten Sie die externen Repositories vor dem Upgrade deaktivieren? [j/N]: " > /dev/tty
            read DISABLE_EXTERNAL < /dev/tty
        fi
        if [[ "$DISABLE_EXTERNAL" =~ ^[Jj]$ ]]; then
            log "Deaktiviere externe Repositories..."
            while IFS= read -r LINE; do
                FILE=$(echo "$LINE" | cut -d: -f1)
                if [ -f "$FILE" ]; then
                    mv "$FILE" "${FILE}.disabled"
                    log "Deaktiviert: $FILE"
                fi
            done <<< "$EXTERNAL_REPOS"
        else
            log "Hinweis: Externe Repositories könnten das Upgrade beeinträchtigen."
        fi
    fi
else
    log "Keine externen Repositories gefunden."
fi

# Überprüfung des verfügbaren Speicherplatzes
log "Überprüfe den verfügbaren Speicherplatz..."
FREE_SPACE=$(df --output=avail -BG / | tail -1 | tr -d 'G')
if [ "$FREE_SPACE" -lt 5 ]; then  # 5 GB
    log "Warnung: Weniger als 5 GB freier Speicherplatz verfügbar. Dies könnte das Upgrade behindern."
    exit 1
else
    log "Genügend Speicherplatz verfügbar: ${FREE_SPACE}G"
fi

# Überprüfung auf ausstehende Konfigurationsänderungen
log "Überprüfe auf ausstehende Konfigurationsänderungen..."
PENDING_CONFIGS=$(find /etc -name '*.dpkg-new' -o -name '*.ucf-dist')
if [ -n "$PENDING_CONFIGS" ]; then
    log "Es wurden ausstehende Konfigurationsänderungen gefunden:"
    log "$PENDING_CONFIGS"
    log "Hinweis: Ausstehende Konfigurationsänderungen könnten das Upgrade beeinflussen."
else
    log "Keine ausstehenden Konfigurationsänderungen gefunden."
fi

# Aktuelle Debian-Version automatisch erkennen
if ! command -v lsb_release &> /dev/null; then
    run_command apt-get update -y
    run_command apt-get install -y lsb-release
fi
CURRENT_VERSION=$(lsb_release -cs)
log "Aktuelle Debian-Version erkannt: $CURRENT_VERSION"

log "Ziel-Debian-Version: $TARGET_VERSION"

# Überprüfung, ob ein Upgrade erforderlich ist
if [ "$CURRENT_VERSION" == "$TARGET_VERSION" ]; then
    log "Das System ist bereits auf dem neuesten Stand."
    exit 0
fi

log "Das System wird von $CURRENT_VERSION auf $TARGET_VERSION aktualisiert."

# Verbindungstest zu den Debian-Servern
log "Überprüfe die Erreichbarkeit der Debian-Server..."
check_connection
log "Debian-Server sind erreichbar."

# Automatische Überprüfung der Paketquellen
log "Überprüfe, ob die Debian-Version '$TARGET_VERSION' verfügbar ist..."
if ! curl -sI "http://ftp.debian.org/debian/dists/$TARGET_VERSION/Release" | grep -q "200 OK"; then
    log "Fehler: Die Debian-Version '$TARGET_VERSION' ist nicht gültig oder nicht verfügbar." >&2
    exit 1
fi
log "Die Debian-Version '$TARGET_VERSION' ist gültig."

# Backup-Verzeichnis erstellen
BACKUP_DIR="/root/sources_backup_$(date +%Y%m%d%H%M%S)"
mkdir -p "$BACKUP_DIR"

log "Erstelle Backup der sources.list Dateien..."

# Backup der sources.list und zugehöriger Dateien
run_command cp -r /etc/apt/sources.list* "$BACKUP_DIR"

log "Backup abgeschlossen und gespeichert unter: $BACKUP_DIR"

# System auf den neuesten Stand bringen und Fehler beheben
log "Aktualisiere das aktuelle System und behebe mögliche Paketfehler..."
run_command apt-get update -y
run_command apt-get upgrade -y
run_command apt-get dist-upgrade -y
run_command apt-get --fix-broken install -y
run_command apt-get --purge autoremove -y
run_command apt-get autoclean -y

# Paketquellen auf die neue Version ändern
log "Aktualisiere Paketquellen auf '$TARGET_VERSION'..."

for FILE in /etc/apt/sources.list /etc/apt/sources.list.d/*.list; do
    if [ -f "$FILE" ]; then
        sed -i.bak -E "s/^(deb.* )(stable|testing|unstable|sid|$CURRENT_VERSION)( .*)/\1$TARGET_VERSION\3/" "$FILE"
        if [ $? -ne 0 ]; then
            log "Fehler beim Aktualisieren der Datei $FILE." >&2
            exit 1
        fi
    fi
done

log "Paketquellen wurden erfolgreich auf '$TARGET_VERSION' geändert."

# Systemaktualisierung auf die neue Debian-Version
log "Starte Systemaktualisierung auf Debian $TARGET_VERSION..."
run_command apt-get update -y

log "Führe minimale Systemaktualisierung durch..."
run_command apt-get upgrade -y

log "Führe vollständige Systemaktualisierung durch..."
run_command apt-get dist-upgrade -y

run_command apt-get --purge autoremove -y
run_command apt-get autoclean -y

# Letzter Neustart
log "Das Upgrade ist abgeschlossen. Das System muss neu gestartet werden, um alle Änderungen anzuwenden."
if [ "$AUTO_REBOOT" = true ]; then
    if [ "$ASSUME_YES" = true ]; then
        REBOOT_CONFIRM="J"
    else
        echo -n "Möchten Sie das System jetzt neu starten? [j/N]: " > /dev/tty
        read REBOOT_CONFIRM < /dev/tty
    fi
    if [[ "$REBOOT_CONFIRM" =~ ^[Jj]$ ]]; then
        log "System wird jetzt neu gestartet..."
        reboot
    else
        log "Bitte starten Sie das System manuell neu, um das Upgrade abzuschließen."
    fi
else
    log "Bitte starten Sie das System manuell neu, um das Upgrade abzuschließen."
fi
