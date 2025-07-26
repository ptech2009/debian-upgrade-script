#!/bin/bash

# Hinweis: Bitte führen Sie vor dem Upgrade ein vollständiges System-Backup durch!

# Skript-Optionen initialisieren
AUTO_REBOOT=false
ASSUME_YES=false
KEEP_FOREIGN_PACKAGES=false
KEEP_EXTERNAL_REPOS=false

# Umgebungsvariable für nicht-interaktiven Modus setzen
export DEBIAN_FRONTEND=noninteractive

# Sprachunterstützung (Deutsch und Englisch)
LANGUAGE="de"

select_language() {
    echo "Please select your language / Bitte wählen Sie Ihre Sprache:"
    echo "1) English"
    echo "2) Deutsch"
    read -p "Selection [1-2]: " LANG_CHOICE

    case $LANG_CHOICE in
        1)
            LANGUAGE="en"
            ;;
        2)
            LANGUAGE="de"
            ;;
        *)
            echo "Invalid selection, defaulting to Deutsch."
            LANGUAGE="de"
            ;;
    esac
}

# Sprachabhängige Texte
set_language_strings() {
    if [ "$LANGUAGE" == "en" ]; then
        TEXT_USAGE="Usage: $0 [options]"
        TEXT_OPTIONS="Options:"
        TEXT_AUTO_REBOOT="--auto-reboot                Automatically reboot after upgrade"
        TEXT_ASSUME_YES="--assume-yes, --non-interactive  Automatically answer 'Yes' to prompts"
        TEXT_KEEP_FOREIGN_PACKAGES="--keep-foreign-packages      Keep foreign packages"
        TEXT_KEEP_EXTERNAL_REPOS="--keep-external-repos        Keep external repositories"
        TEXT_HELP="-h, --help                   Display this help message"
        TEXT_UNKNOWN_OPTION="Unknown option: "
        TEXT_ERROR="Error"
        TEXT_ALREADY_RUNNING="Another upgrade script is already running."
        TEXT_NOT_ROOT="This script must be run as root."
        TEXT_STARTING="Starting Debian upgrade script..."
        TEXT_CHECK_FOREIGN="Checking for installed foreign packages..."
        TEXT_FOREIGN_FOUND="Foreign packages found:"
        TEXT_KEEPING_FOREIGN="Keeping foreign packages due to --keep-foreign-packages option."
        TEXT_REMOVE_FOREIGN_PROMPT="Do you want to remove foreign packages before the upgrade? [y/N]: "
        TEXT_REMOVING_FOREIGN="Removing foreign packages..."
        TEXT_NO_FOREIGN="No foreign packages found."
        TEXT_CHECK_EXTERNAL="Checking for non-official Debian repositories..."
        TEXT_EXTERNAL_FOUND="Non-official repositories found:"
        TEXT_KEEPING_EXTERNAL="Keeping external repositories due to --keep-external-repos option."
        TEXT_DISABLE_EXTERNAL_PROMPT="Do you want to disable external repositories before the upgrade? [y/N]: "
        TEXT_DISABLING_EXTERNAL="Disabling external repositories..."
        TEXT_NO_EXTERNAL="No external repositories found."
        TEXT_CHECK_SPACE="Checking available disk space..."
        TEXT_LOW_SPACE="Warning: Less than 5 GB of free space available. This may hinder the upgrade."
        TEXT_SPACE_OK="Sufficient disk space available:"
        TEXT_CHECK_PENDING_CONFIGS="Checking for pending configuration changes..."
        TEXT_PENDING_CONFIGS_FOUND="Pending configuration changes found:"
        TEXT_HANDLE_PENDING_PROMPT="Do you want to resolve pending configuration changes now? [y/N]: "
        TEXT_RESOLVING_PENDING="Resolving pending configuration changes..."
        TEXT_NO_PENDING_CONFIGS="No pending configuration changes found."
        TEXT_CURRENT_VERSION="Current Debian version detected:"
        TEXT_TARGET_VERSION="Target Debian version:"
        TEXT_ALREADY_UP_TO_DATE="The system is already up-to-date."
        TEXT_UPGRADE_FROM_TO="The system will be upgraded from"
        TEXT_CHECK_CONNECTION="Checking the reachability of Debian servers..."
        TEXT_SERVERS_REACHABLE="Debian servers are reachable."
        TEXT_INVALID_VERSION="Error: The Debian version '$TARGET_VERSION' is not valid or not available."
        TEXT_VALID_VERSION="The Debian version '$TARGET_VERSION' is valid."
        TEXT_BACKUP_SOURCES="Creating backup of sources.list files..."
        TEXT_BACKUP_COMPLETED="Backup completed and stored in:"
        TEXT_UPDATING_SYSTEM="Updating the current system and fixing possible package errors..."
        TEXT_UPDATING_SOURCES="Updating package sources to"
        TEXT_SOURCES_UPDATED="Package sources successfully updated to"
        TEXT_UPGRADE_SYSTEM="Starting system upgrade to Debian"
        TEXT_MINIMAL_UPGRADE="Performing minimal system upgrade..."
        TEXT_FULL_UPGRADE="Performing full system upgrade..."
        TEXT_UPGRADE_COMPLETE="Upgrade is complete. The system needs to be rebooted to apply all changes."
        TEXT_REBOOT_PROMPT="Do you want to reboot the system now? [y/N]: "
        TEXT_REBOOTING="Rebooting the system now..."
        TEXT_REBOOT_LATER="Please reboot the system manually to complete the upgrade."
        TEXT_LOG_ROTATION="Rotating log file..."
    else
        TEXT_USAGE="Verwendung: $0 [Optionen]"
        TEXT_OPTIONS="Optionen:"
        TEXT_AUTO_REBOOT="--auto-reboot                Führt am Ende des Upgrades automatisch einen Neustart durch"
        TEXT_ASSUME_YES="--assume-yes, --non-interactive  Beantwortet alle Eingabeaufforderungen automatisch mit 'Ja'"
        TEXT_KEEP_FOREIGN_PACKAGES="--keep-foreign-packages      Behält Fremdpakete bei"
        TEXT_KEEP_EXTERNAL_REPOS="--keep-external-repos        Behält externe Repositories bei"
        TEXT_HELP="-h, --help                   Zeigt diese Hilfe an"
        TEXT_UNKNOWN_OPTION="Unbekannte Option: "
        TEXT_ERROR="Fehler"
        TEXT_ALREADY_RUNNING="Ein anderes Upgrade-Skript wird bereits ausgeführt."
        TEXT_NOT_ROOT="Dieses Skript muss als root ausgeführt werden."
        TEXT_STARTING="Starte Debian Upgrade Skript..."
        TEXT_CHECK_FOREIGN="Überprüfe auf installierte Fremdpakete..."
        TEXT_FOREIGN_FOUND="Es wurden Fremdpakete gefunden:"
        TEXT_KEEPING_FOREIGN="Fremdpakete werden beibehalten aufgrund der Option --keep-foreign-packages."
        TEXT_REMOVE_FOREIGN_PROMPT="Möchten Sie die Fremdpakete vor dem Upgrade entfernen? [j/N]: "
        TEXT_REMOVING_FOREIGN="Entferne Fremdpakete..."
        TEXT_NO_FOREIGN="Keine Fremdpakete gefunden."
        TEXT_CHECK_EXTERNAL="Überprüfe auf nicht offizielle Debian-Repositories..."
        TEXT_EXTERNAL_FOUND="Es wurden nicht offizielle Debian-Repositories gefunden:"
        TEXT_KEEPING_EXTERNAL="Externe Repositories werden beibehalten aufgrund der Option --keep-external-repos."
        TEXT_DISABLE_EXTERNAL_PROMPT="Möchten Sie die externen Repositories vor dem Upgrade deaktivieren? [j/N]: "
        TEXT_DISABLING_EXTERNAL="Deaktiviere externe Repositories..."
        TEXT_NO_EXTERNAL="Keine externen Repositories gefunden."
        TEXT_CHECK_SPACE="Überprüfe den verfügbaren Speicherplatz..."
        TEXT_LOW_SPACE="Warnung: Weniger als 5 GB freier Speicherplatz verfügbar. Dies könnte das Upgrade behindern."
        TEXT_SPACE_OK="Genügend Speicherplatz verfügbar:"
        TEXT_CHECK_PENDING_CONFIGS="Überprüfe auf ausstehende Konfigurationsänderungen..."
        TEXT_PENDING_CONFIGS_FOUND="Es wurden ausstehende Konfigurationsänderungen gefunden:"
        TEXT_HANDLE_PENDING_PROMPT="Möchten Sie die ausstehenden Konfigurationsänderungen jetzt bearbeiten? [j/N]: "
        TEXT_RESOLVING_PENDING="Bearbeite ausstehende Konfigurationsänderungen..."
        TEXT_NO_PENDING_CONFIGS="Keine ausstehenden Konfigurationsänderungen gefunden."
        TEXT_CURRENT_VERSION="Aktuelle Debian-Version erkannt:"
        TEXT_TARGET_VERSION="Ziel-Debian-Version:"
        TEXT_ALREADY_UP_TO_DATE="Das System ist bereits auf dem neuesten Stand."
        TEXT_UPGRADE_FROM_TO="Das System wird aktualisiert von"
        TEXT_CHECK_CONNECTION="Überprüfe die Erreichbarkeit der Debian-Server..."
        TEXT_SERVERS_REACHABLE="Debian-Server sind erreichbar."
        TEXT_INVALID_VERSION="Fehler: Die Debian-Version '$TARGET_VERSION' ist nicht gültig oder nicht verfügbar."
        TEXT_VALID_VERSION="Die Debian-Version '$TARGET_VERSION' ist gültig."
        TEXT_BACKUP_SOURCES="Erstelle Backup der sources.list Dateien..."
        TEXT_BACKUP_COMPLETED="Backup abgeschlossen und gespeichert unter:"
        TEXT_UPDATING_SYSTEM="Aktualisiere das aktuelle System und behebe mögliche Paketfehler..."
        TEXT_UPDATING_SOURCES="Aktualisiere Paketquellen auf"
        TEXT_SOURCES_UPDATED="Paketquellen wurden erfolgreich geändert auf"
        TEXT_UPGRADE_SYSTEM="Starte Systemaktualisierung auf Debian"
        TEXT_MINIMAL_UPGRADE="Führe minimale Systemaktualisierung durch..."
        TEXT_FULL_UPGRADE="Führe vollständige Systemaktualisierung durch..."
        TEXT_UPGRADE_COMPLETE="Das Upgrade ist abgeschlossen. Das System muss neu gestartet werden, um alle Änderungen anzuwenden."
        TEXT_REBOOT_PROMPT="Möchten Sie das System jetzt neu starten? [j/N]: "
        TEXT_REBOOTING="System wird jetzt neu gestartet..."
        TEXT_REBOOT_LATER="Bitte starten Sie das System manuell neu, um das Upgrade abzuschließen."
        TEXT_LOG_ROTATION="Rotieren der Log-Datei..."
    fi
}

# Sprache auswählen
select_language
set_language_strings

usage() {
    echo "$TEXT_USAGE"
    echo "$TEXT_OPTIONS"
    echo "  $TEXT_AUTO_REBOOT"
    echo "  $TEXT_ASSUME_YES"
    echo "  $TEXT_KEEP_FOREIGN_PACKAGES"
    echo "  $TEXT_KEEP_EXTERNAL_REPOS"
    echo "  $TEXT_HELP"
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
            echo "$TEXT_UNKNOWN_OPTION$1"
            usage
            ;;
    esac
done

# Funktion zur Fehlerprüfung nach Befehlen
run_command() {
    "$@"
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        log "$TEXT_ERROR: Command '$*' failed (Exit Code $EXIT_CODE)." >&2
        exit $EXIT_CODE
    fi
}

# Funktion für Logging mit Zeitstempel
log() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$message"
    echo "$message" >> "$LOGFILE"
}

# Logrotation implementieren
rotate_log() {
    if [ -f "$LOGFILE" ]; then
        local LOG_SIZE=$(stat -c%s "$LOGFILE")
        local MAX_SIZE=$((10 * 1024 * 1024)) # 10 MB
        if [ $LOG_SIZE -ge $MAX_SIZE ]; then
            log "$TEXT_LOG_ROTATION"
            mv "$LOGFILE" "$LOGFILE.$(date '+%Y%m%d%H%M%S')"
            touch "$LOGFILE"
        fi
    fi
}

# Lock-File einrichten, um Mehrfachausführung zu verhindern
LOCKFILE="/tmp/debian-upgrade.lock"
exec 200>"$LOCKFILE"

flock -n 200 || { log "$TEXT_ALREADY_RUNNING"; exit 1; }

# Ziel-Debian-Version festlegen
# "auto" bewirkt, dass immer die aktuelle Stable-Version ermittelt wird
TARGET_VERSION="auto"

# Aktuelle Stable-Version von den Debian-Servern ermitteln
detect_stable_version() {
    local release_data
    if command -v curl &> /dev/null; then
        release_data=$(curl -fsSL http://ftp.debian.org/debian/dists/stable/Release)
    elif command -v wget &> /dev/null; then
        release_data=$(wget -qO- http://ftp.debian.org/debian/dists/stable/Release)
    else
        run_command apt-get update -y
        run_command apt-get install -y curl
        release_data=$(curl -fsSL http://ftp.debian.org/debian/dists/stable/Release)
    fi
    echo "$release_data" | grep -m1 '^Codename:' | awk '{print $2}'
}

# Funktion zum Überprüfen der Erreichbarkeit der Debian-Server
check_connection() {
    if command -v curl &> /dev/null; then
        if ! curl -s --head http://deb.debian.org/ | grep "200 OK" > /dev/null; then
            log "$TEXT_ERROR: Debian servers are not reachable. Please check your network connection." >&2
            exit 1
        fi
    elif command -v wget &> /dev/null; then
        if ! wget -q --spider http://deb.debian.org/; then
            log "$TEXT_ERROR: Debian servers are not reachable. Please check your network connection." >&2
            exit 1
        fi
    else
        log "$TEXT_ERROR: Neither 'curl' nor 'wget' is installed. Installing 'curl'..."
        run_command apt-get update -y
        run_command apt-get install -y curl
        if ! curl -s --head http://deb.debian.org/ | grep "200 OK" > /dev/null; then
            log "$TEXT_ERROR: Debian servers are not reachable. Please check your network connection." >&2
            exit 1
        fi
    fi
}

# Sicherstellen, dass das Skript als root ausgeführt wird
if [ "$(id -u)" -ne 0 ]; then
    echo "$TEXT_NOT_ROOT" >&2
    exit 1
fi

# Logging einrichten
LOGFILE="/var/log/debian-upgrade.log"
LOGDIR=$(dirname "$LOGFILE")
mkdir -p "$LOGDIR"  # Log-Verzeichnis erstellen, falls nicht vorhanden
rotate_log  # Logrotation prüfen

log "$TEXT_STARTING"

# Überprüfung auf installierte Fremdpakete
log "$TEXT_CHECK_FOREIGN"
if ! command -v aptitude &> /dev/null; then
    run_command apt-get update -y
    run_command apt-get install -y aptitude
fi

FOREIGN_PACKAGES=$(aptitude search '~i!~ODebian' -F '%p')
if [ -n "$FOREIGN_PACKAGES" ]; then
    log "$TEXT_FOREIGN_FOUND"
    log "$FOREIGN_PACKAGES"
    if [ "$KEEP_FOREIGN_PACKAGES" = true ]; then
        log "$TEXT_KEEPING_FOREIGN"
    else
        if [ "$ASSUME_YES" = true ]; then
            REMOVE_FOREIGN="y"
        else
            echo -n "$TEXT_REMOVE_FOREIGN_PROMPT" > /dev/tty
            read REMOVE_FOREIGN < /dev/tty
        fi
        if [[ "$REMOVE_FOREIGN" =~ ^[YyJj]$ ]]; then
            log "$TEXT_REMOVING_FOREIGN"
            run_command apt-get remove --purge -y $FOREIGN_PACKAGES
        else
            log "$TEXT_WARNING: Foreign packages may affect the upgrade."
        fi
    fi
else
    log "$TEXT_NO_FOREIGN"
fi

# Überprüfung auf nicht offizielle Debian-Repositories
log "$TEXT_CHECK_EXTERNAL"
EXTERNAL_REPOS=$(grep -rE '^(deb|deb-src) ' /etc/apt/sources.list /etc/apt/sources.list.d/ | grep -vE 'debian\.org|security\.debian\.org|ftp\.debian\.org|deb\.debian\.org')
if [ -n "$EXTERNAL_REPOS" ]; then
    log "$TEXT_EXTERNAL_FOUND"
    log "$EXTERNAL_REPOS"
    if [ "$KEEP_EXTERNAL_REPOS" = true ]; then
        log "$TEXT_KEEPING_EXTERNAL"
    else
        if [ "$ASSUME_YES" = true ]; then
            DISABLE_EXTERNAL="y"
        else
            echo -n "$TEXT_DISABLE_EXTERNAL_PROMPT" > /dev/tty
            read DISABLE_EXTERNAL < /dev/tty
        fi
        if [[ "$DISABLE_EXTERNAL" =~ ^[YyJj]$ ]]; then
            log "$TEXT_DISABLING_EXTERNAL"
            while IFS= read -r LINE; do
                FILE=$(echo "$LINE" | cut -d: -f1)
                if [ -f "$FILE" ]; then
                    mv "$FILE" "${FILE}.disabled"
                    log "$TEXT_DISABLED: $FILE"
                fi
            done <<< "$EXTERNAL_REPOS"
        else
            log "$TEXT_WARNING: External repositories may affect the upgrade."
        fi
    fi
else
    log "$TEXT_NO_EXTERNAL"
fi

# Überprüfung des verfügbaren Speicherplatzes
log "$TEXT_CHECK_SPACE"
FREE_SPACE=$(df --output=avail -BG / | tail -1 | tr -d 'G')
if [ "$FREE_SPACE" -lt 5 ]; then  # 5 GB
    log "$TEXT_LOW_SPACE"
    exit 1
else
    log "$TEXT_SPACE_OK ${FREE_SPACE}G"
fi

# Überprüfung auf ausstehende Konfigurationsänderungen
log "$TEXT_CHECK_PENDING_CONFIGS"
PENDING_CONFIGS=$(find /etc -name '*.dpkg-new' -o -name '*.ucf-dist')
if [ -n "$PENDING_CONFIGS" ]; then
    log "$TEXT_PENDING_CONFIGS_FOUND"
    log "$PENDING_CONFIGS"
    if [ "$ASSUME_YES" = true ]; then
        HANDLE_PENDING="y"
    else
        echo -n "$TEXT_HANDLE_PENDING_PROMPT" > /dev/tty
        read HANDLE_PENDING < /dev/tty
    fi
    if [[ "$HANDLE_PENDING" =~ ^[YyJj]$ ]]; then
        log "$TEXT_RESOLVING_PENDING"
        for CONFIG_FILE in $PENDING_CONFIGS; do
            ORIGINAL_FILE="${CONFIG_FILE%.dpkg-new}"
            if [ -f "$ORIGINAL_FILE" ]; then
                mv "$CONFIG_FILE" "$ORIGINAL_FILE"
                log "Updated configuration: $ORIGINAL_FILE"
            else
                mv "$CONFIG_FILE" "$ORIGINAL_FILE"
                log "Added new configuration: $ORIGINAL_FILE"
            fi
        done
    else
        log "$TEXT_WARNING: Pending configuration changes may affect the upgrade."
    fi
else
    log "$TEXT_NO_PENDING_CONFIGS"
fi

# Aktuelle Debian-Version automatisch erkennen
if ! command -v lsb_release &> /dev/null; then
    run_command apt-get update -y
    run_command apt-get install -y lsb-release
fi
CURRENT_VERSION=$(lsb_release -cs)
if [ "$TARGET_VERSION" = "auto" ]; then
    TARGET_VERSION=$(detect_stable_version)
fi
log "$TEXT_CURRENT_VERSION $CURRENT_VERSION"
log "$TEXT_TARGET_VERSION $TARGET_VERSION"

# Überprüfung, ob ein Upgrade erforderlich ist
if [ "$CURRENT_VERSION" == "$TARGET_VERSION" ]; then
    log "$TEXT_ALREADY_UP_TO_DATE"
    exit 0
fi

log "$TEXT_UPGRADE_FROM_TO $CURRENT_VERSION $TEXT_TO $TARGET_VERSION."

# Verbindungstest zu den Debian-Servern
log "$TEXT_CHECK_CONNECTION"
check_connection
log "$TEXT_SERVERS_REACHABLE"

# Automatische Überprüfung der Paketquellen
log "$TEXT_VALIDATING_VERSION '$TARGET_VERSION'..."
if ! curl -sI "http://ftp.debian.org/debian/dists/$TARGET_VERSION/Release" | grep -q "200 OK"; then
    log "$TEXT_INVALID_VERSION" >&2
    exit 1
fi
log "$TEXT_VALID_VERSION"

# Backup-Verzeichnis erstellen
BACKUP_DIR="/root/sources_backup_$(date +%Y%m%d%H%M%S)"
mkdir -p "$BACKUP_DIR"

log "$TEXT_BACKUP_SOURCES"

# Backup der sources.list und zugehöriger Dateien
run_command cp -r /etc/apt/sources.list* "$BACKUP_DIR"

log "$TEXT_BACKUP_COMPLETED $BACKUP_DIR"

# System auf den neuesten Stand bringen und Fehler beheben
log "$TEXT_UPDATING_SYSTEM"
run_command apt-get update -y
run_command apt-get upgrade -y
run_command apt-get dist-upgrade -y
run_command apt-get --fix-broken install -y
run_command apt-get --purge autoremove -y
run_command apt-get autoclean -y

# Paketquellen auf die neue Version ändern
log "$TEXT_UPDATING_SOURCES '$TARGET_VERSION'..."

for FILE in /etc/apt/sources.list /etc/apt/sources.list.d/*.list; do
    if [ -f "$FILE" ]; then
        sed -i.bak -E "s/^(deb.* )(stable|testing|unstable|sid|$CURRENT_VERSION)( .*)/\1$TARGET_VERSION\3/" "$FILE"
        if [ $? -ne 0 ]; then
            log "$TEXT_ERROR beim Aktualisieren der Datei $FILE." >&2
            exit 1
        fi
    fi
done

log "$TEXT_SOURCES_UPDATED '$TARGET_VERSION'."

# Systemaktualisierung auf die neue Debian-Version
log "$TEXT_UPGRADE_SYSTEM $TARGET_VERSION..."
run_command apt-get update -y

log "$TEXT_MINIMAL_UPGRADE"
run_command apt-get upgrade -y

log "$TEXT_FULL_UPGRADE"
run_command apt-get dist-upgrade -y

run_command apt-get --purge autoremove -y
run_command apt-get autoclean -y

# Letzter Neustart
log "$TEXT_UPGRADE_COMPLETE"
if [ "$AUTO_REBOOT" = true ]; then
    if [ "$ASSUME_YES" = true ]; then
        REBOOT_CONFIRM="y"
    else
        echo -n "$TEXT_REBOOT_PROMPT" > /dev/tty
        read REBOOT_CONFIRM < /dev/tty
    fi
    if [[ "$REBOOT_CONFIRM" =~ ^[YyJj]$ ]]; then
        log "$TEXT_REBOOTING"
        reboot
    else
        log "$TEXT_REBOOT_LATER"
    fi
else
    log "$TEXT_REBOOT_LATER"
fi
