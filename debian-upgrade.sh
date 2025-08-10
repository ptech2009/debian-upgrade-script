#!/bin/bash
# Debian Bookworm -> Trixie Upgrade Script (mit interaktiver Sprachauswahl & erweiterten Checks)
# Features:
# - Interaktive Sprachauswahl (Deutsch/Englisch) beim Start
# - Root-/Lock-/Logging + Logrotation
# - Netzwerk-/Platten-Checks
# - /etc-Tar-Backup + Paketliste (dpkg --get-selections)
# - APT-Quellen-Backup
# - Drittquellen robust deaktivieren (.list & .sources; TeamViewer/Brave/NordVPN usw.)
# - Bookworm zuerst auf aktuellen Stand
# - Quellen auf Trixie umstellen (.list & .sources/Suites)
# - Upgrade-Flow: apt upgrade --without-new-pkgs -> Simulation -> dist-upgrade
# - deb822-Modernisierung (apt modernize-sources)
# - Abschluss-Checks + Hinweise zum Re-Enable von Drittquellen
# - Flags: --auto-reboot --assume-yes/--non-interactive --keep-foreign-packages --keep-external-repos --reenable-thirdparty
# - ADAPTIV: /boot-Platzcheck + automatisches Purge alter Kernel (sicher) + Reinstall linux-image-amd64

set -Eeuo pipefail

# Hinweis: Bitte führen Sie vor dem Upgrade ein vollständiges System-Backup durch!

# Skript-Optionen initialisieren
AUTO_REBOOT=false
ASSUME_YES=false
KEEP_FOREIGN_PACKAGES=false
KEEP_EXTERNAL_REPOS=false
REENABLE_THIRDPARTY=false

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
        1) LANGUAGE="en" ;;
        2) LANGUAGE="de" ;;
        *) echo "Invalid selection, defaulting to Deutsch."; LANGUAGE="de" ;;
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
        TEXT_REENABLE_THIRDPARTY="--reenable-thirdparty        Re-enable third-party repos after upgrade (test & revert if failing)"
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
        TEXT_TO="to"
        TEXT_CHECK_CONNECTION="Checking the reachability of Debian servers..."
        TEXT_SERVERS_REACHABLE="Debian servers are reachable."
        TEXT_INVALID_VERSION="Error: The Debian version '\$TARGET_VERSION' is not valid or not available."
        TEXT_VALID_VERSION="The Debian version '\$TARGET_VERSION' is valid."
        TEXT_VALIDATING_VERSION="Validating version"
        TEXT_BACKUP_SOURCES="Creating backup of sources.list files..."
        TEXT_BACKUP_COMPLETED="Backup completed and stored in:"
        TEXT_UPDATING_SYSTEM="Updating the current system and fixing possible package errors..."
        TEXT_UPDATING_SOURCES="Updating package sources to"
        TEXT_SOURCES_UPDATED="Package sources successfully updated to"
        TEXT_UPGRADE_SYSTEM="Starting system upgrade to Debian"
        TEXT_MINIMAL_UPGRADE="Performing minimal system upgrade..."
        TEXT_FULL_UPGRADE="Performing full system upgrade..."
        TEXT_UPGRADE_COMPLETE="Upgrade is complete. The system may need a reboot to apply all changes."
        TEXT_REBOOT_PROMPT="Do you want to reboot the system now? [y/N]: "
        TEXT_REBOOTING="Rebooting the system now..."
        TEXT_REBOOT_LATER="Please reboot the system manually to complete the upgrade."
        TEXT_LOG_ROTATION="Rotating log file..."
        TEXT_WARNING="Warning"
        TEXT_DISABLED="Disabled"
        TEXT_LOGFILE="Log file:"
        TEXT_DISABLING_THIRDPARTY="Disabling third-party sources (TeamViewer, Brave, NordVPN, …)…"
        TEXT_DISABLED_FILES_LIST="Disabled files list:"
        TEXT_DISABLED_LINES_LIST="Commented lines list:"
        TEXT_ETC_BACKUP_START="Creating /etc tar backup…"
        TEXT_ETC_BACKUP_DONE="Tar backup created:"
        TEXT_PKG_LIST_EXPORTED="Package list exported to:"
        TEXT_SWITCH_CODENAME="Switching APT sources to"
        TEXT_STEP1="1) Upgrading existing packages (without new ones)…"
        TEXT_STEP2="2) Simulating full-upgrade…"
        TEXT_SIMULATION_FAILED="Simulation reported issues. Please review the log."
        TEXT_STEP3="3) Performing full-upgrade…"
        TEXT_MODERNIZE="Modernizing APT sources to deb822 (apt modernize-sources)…"
        TEXT_MODERNIZE_WARN="apt modernize-sources reported warnings/errors."
        TEXT_VERSION_CHECKS="Upgrade finished. Version checks:"
        TEXT_DEBIAN_VERSION="/etc/debian_version:"
        TEXT_REENABLE_HINT="Hints to re-enable third-party sources:"
        TEXT_REENABLE_FILES_CMD="To restore disabled *files* (only if vendor supports Trixie), run:"
        TEXT_REENABLE_LINES_PATH="Commented *lines* require manual review (see):"
        TEXT_THEN_APT_UPDATE="Then run: apt-get update"
        TEXT_REENABLE_START="Re-enabling previously disabled third-party repositories…"
        TEXT_REENABLE_OK="Repository re-enabled successfully:"
        TEXT_REENABLE_FAIL="Repository failed on apt-get update, reverting:"
        TEXT_REENABLE_DONE="Re-enable process finished."
        # /boot Texte (EN)
        TEXT_BOOT_CHECK="Checking free space on /boot (adaptive threshold)…"
        TEXT_BOOT_FREE="Free on /boot (MB):"
        TEXT_BOOT_LOW="Not enough free space on /boot; purging old kernels…"
        TEXT_PURGE_OLD_KERNELS="Purging old kernels and headers…"
        TEXT_RUNNING_KERNEL="Running kernel:"
        TEXT_PURGING_PACKAGES="Purging packages:"
        TEXT_NO_OLD_KERNELS="No old kernels to purge."
        TEXT_STILL_NOT_ENOUGH="Still not enough free space on /boot. Please free space manually and rerun."
        TEXT_REINSTALL_META="Re-installing meta package: linux-image-amd64"
    else
        TEXT_USAGE="Verwendung: $0 [Optionen]"
        TEXT_OPTIONS="Optionen:"
        TEXT_AUTO_REBOOT="--auto-reboot                Führt am Ende des Upgrades automatisch einen Neustart durch"
        TEXT_ASSUME_YES="--assume-yes, --non-interactive  Beantwortet alle Eingabeaufforderungen automatisch mit 'Ja'"
        TEXT_KEEP_FOREIGN_PACKAGES="--keep-foreign-packages      Behält Fremdpakete bei"
        TEXT_KEEP_EXTERNAL_REPOS="--keep-external-repos        Behält externe Repositories bei"
        TEXT_REENABLE_THIRDPARTY="--reenable-thirdparty        Dritt-Repos nach dem Upgrade wieder aktivieren (testen & bei Fehler zurücksetzen)"
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
        TEXT_DISABLING_EXTERNAL="Deaktiviere Dritt-Quellen..."
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
        TEXT_TO="zu"
        TEXT_CHECK_CONNECTION="Überprüfe die Erreichbarkeit der Debian-Server..."
        TEXT_SERVERS_REACHABLE="Debian-Server sind erreichbar."
        TEXT_INVALID_VERSION="Fehler: Die Debian-Version '\$TARGET_VERSION' ist nicht gültig oder nicht verfügbar."
        TEXT_VALID_VERSION="Die Debian-Version '\$TARGET_VERSION' ist gültig."
        TEXT_VALIDATING_VERSION="Validiere Version"
        TEXT_BACKUP_SOURCES="Erstelle Backup der sources.list Dateien..."
        TEXT_BACKUP_COMPLETED="Backup abgeschlossen und gespeichert unter:"
        TEXT_UPDATING_SYSTEM="Aktualisiere das aktuelle System und behebe mögliche Paketfehler..."
        TEXT_UPDATING_SOURCES="Aktualisiere Paketquellen auf"
        TEXT_SOURCES_UPDATED="Paketquellen wurden erfolgreich geändert auf"
        TEXT_UPGRADE_SYSTEM="Starte Systemaktualisierung auf Debian"
        TEXT_MINIMAL_UPGRADE="Führe minimale Systemaktualisierung durch..."
        TEXT_FULL_UPGRADE="Führe vollständige Systemaktualisierung durch..."
        TEXT_UPGRADE_COMPLETE="Das Upgrade ist abgeschlossen. Das System muss ggf. neu gestartet werden, um alle Änderungen anzuwenden."
        TEXT_REBOOT_PROMPT="Möchten Sie das System jetzt neu starten? [j/N]: "
        TEXT_REBOOTING="System wird jetzt neu gestartet..."
        TEXT_REBOOT_LATER="Bitte starten Sie das System manuell neu, um das Upgrade abzuschließen."
        TEXT_LOG_ROTATION="Rotieren der Log-Datei..."
        TEXT_WARNING="Warnung"
        TEXT_DISABLED="Deaktiviert"
        TEXT_LOGFILE="Logdatei:"
        TEXT_DISABLING_THIRDPARTY="Deaktiviere Dritt-Quellen (TeamViewer, Brave, NordVPN, …)…"
        TEXT_DISABLED_FILES_LIST="Liste deaktivierter Dateien:"
        TEXT_DISABLED_LINES_LIST="Liste auskommentierter Zeilen:"
        TEXT_ETC_BACKUP_START="Sichere /etc als Tar-Archiv…"
        TEXT_ETC_BACKUP_DONE="Tar-Backup erstellt:"
        TEXT_PKG_LIST_EXPORTED="Paketliste exportiert nach:"
        TEXT_SWITCH_CODENAME="Stelle APT-Quellen um auf"
        TEXT_STEP1="1) Bestehende Pakete aktualisieren (ohne neue Pakete)…"
        TEXT_STEP2="2) Simulation des Full-Upgrades…"
        TEXT_SIMULATION_FAILED="Simulation meldete Probleme. Bitte Log prüfen."
        TEXT_STEP3="3) Full-Upgrade durchführen…"
        TEXT_MODERNIZE="Modernisiere APT-Quellen auf deb822 (apt modernize-sources)…"
        TEXT_MODERNIZE_WARN="apt modernize-sources meldete Warnungen/Fehler."
        TEXT_VERSION_CHECKS="Upgrade abgeschlossen. Versions-Checks:"
        TEXT_DEBIAN_VERSION="/etc/debian_version:"
        TEXT_REENABLE_HINT="Hinweise zum Wieder-Aktivieren von Drittquellen:"
        TEXT_REENABLE_FILES_CMD="Um deaktivierte *Dateien* zurückzuholen (nur wenn Anbieter Trixie unterstützt), ausführen:"
        TEXT_REENABLE_LINES_PATH="Auskommentierte *Zeilen* bitte manuell prüfen (siehe):"
        TEXT_THEN_APT_UPDATE="Danach: apt-get update"
        TEXT_REENABLE_START="Aktiviere zuvor deaktivierte Dritt-Repositories wieder…"
        TEXT_REENABLE_OK="Repository erfolgreich wieder aktiviert:"
        TEXT_REENABLE_FAIL="Repository verursacht Fehler bei apt-get update, wird zurückgesetzt:"
        TEXT_REENABLE_DONE="Re-Enable-Prozess abgeschlossen."
        # /boot Texte (DE)
        TEXT_BOOT_CHECK="Prüfe freien Platz auf /boot (adaptiver Schwellenwert)…"
        TEXT_BOOT_FREE="Frei auf /boot (MB):"
        TEXT_BOOT_LOW="Zu wenig Platz auf /boot; entferne alte Kernel…"
        TEXT_PURGE_OLD_KERNELS="Entferne alte Kernel und Header…"
        TEXT_RUNNING_KERNEL="Laufender Kernel:"
        TEXT_PURGING_PACKAGES="Entferne Pakete:"
        TEXT_NO_OLD_KERNELS="Keine alten Kernel zum Entfernen gefunden."
        TEXT_STILL_NOT_ENOUGH="Noch immer zu wenig Platz auf /boot. Bitte manuell Platz schaffen und erneut ausführen."
        TEXT_REINSTALL_META="[INFO] Installiere Meta-Paket erneut: linux-image-amd64"
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
    echo "  $TEXT_REENABLE_THIRDPARTY"
    echo "  $TEXT_HELP"
    exit 0
}

# Kommandozeilenoptionen verarbeiten
while [[ $# -gt 0 ]]; do
    case $1 in
        --auto-reboot) AUTO_REBOOT=true; shift ;;
        --assume-yes|--non-interactive) ASSUME_YES=true; shift ;;
        --keep-foreign-packages) KEEP_FOREIGN_PACKAGES=true; shift ;;
        --keep-external-repos) KEEP_EXTERNAL_REPOS=true; shift ;;
        --reenable-thirdparty) REENABLE_THIRDPARTY=true; shift ;;
        -h|--help) usage ;;
        *) echo "$TEXT_UNKNOWN_OPTION$1"; usage ;;
    esac
done

# Sicherstellen, dass das Skript als root ausgeführt wird
if [ "$(id -u)" -ne 0 ]; then
    echo "$TEXT_NOT_ROOT" >&2
    exit 1
fi

# Logging & Pfade
TS="$(date +%F_%H%M%S)"
LOGDIR="/var/log/debian-upgrade"
LOGFILE="${LOGDIR}/${TS}_upgrade.log"
DISABLED_DIR="/etc/apt/thirdparty-disabled.d"
DISABLED_FILES_LIST="${LOGDIR}/disabled-thirdparty-files_${TS}.txt"   # .sources (Enabled:no) + verschobene *.disabled
DISABLED_LINES_LIST="${LOGDIR}/disabled-thirdparty-lines_${TS}.txt"   # auskommentierte Zeilen in *.list

mkdir -p "$LOGDIR"

log() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$message"
    echo "$message" >> "$LOGFILE"
}

rotate_log() {
    if [ -f "$LOGFILE" ]; then
        local LOG_SIZE
        LOG_SIZE=$(stat -c%s "$LOGFILE")
        local MAX_SIZE=$((10 * 1024 * 1024)) # 10 MB
        if [ $LOG_SIZE -ge $MAX_SIZE ]; then
            log "$TEXT_LOG_ROTATION"
            mv "$LOGFILE" "$LOGFILE.$(date '+%Y%m%d%H%M%S')"
            : > "$LOGFILE"
        fi
    fi
}

rotate_log
log "${TEXT_LOGFILE} $LOGFILE"

# Lock-File
LOCKFILE="/var/run/debian-upgrade.lock"
if [ -f "$LOCKFILE" ]; then
    LOCK_PID=$(cat "$LOCKFILE" 2>/dev/null || true)
    if [ -n "$LOCK_PID" ] && kill -0 "$LOCK_PID" 2>/dev/null; then
        log "$TEXT_ALREADY_RUNNING"
        exit 1
    else
        rm -f "$LOCKFILE"
    fi
fi
echo $$ > "$LOCKFILE"
trap 'rm -f "$LOCKFILE"; exit' INT TERM EXIT

run_command() {
    "$@"
    local EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        log "$TEXT_ERROR: Command '$*' failed (Exit Code $EXIT_CODE)." >&2
        exit $EXIT_CODE
    fi
}

# Ziel-Debian-Version
TARGET_VERSION="auto"

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

check_connection() {
    if command -v curl &> /dev/null; then
        if ! curl -s --head http://deb.debian.org/ | grep -q "200 OK"; then
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
        if ! curl -s --head http://deb.debian.org/ | grep -q "200 OK"; then
            log "$TEXT_ERROR: Debian servers are not reachable. Please check your network connection." >&2
            exit 1
        fi
    fi
}

DEBIAN_DOMAINS_REGEX='(^|//)(deb\.debian\.org|security\.debian\.org|ftp\.[^/]+\.debian\.org)(/|$)'
is_debian_url() { local url="$1"; [[ "$url" =~ $DEBIAN_DOMAINS_REGEX ]]; }

# /etc-Backup + Paketliste
backup_etc_and_pkglist() {
    local ETC_BACKUP_DIR="/home/etc-backup"
    mkdir -p "$ETC_BACKUP_DIR"
    log "$TEXT_ETC_BACKUP_START"
    local tarfile="${ETC_BACKUP_DIR}/etc-backup_$(date +%F).tar.gz"
    tar -cpzf "$tarfile" /etc
    log "$TEXT_ETC_BACKUP_DONE $tarfile"
    local PKG_LIST_FILE="${HOME}/package-selections-$(date +%Y%m%d).txt"
    dpkg --get-selections > "$PKG_LIST_FILE"
    log "$TEXT_PKG_LIST_EXPORTED $PKG_LIST_FILE"
}

# APT-Quellen sichern
backup_apt_sources() {
    local BACKUP_DIR="/root/sources_backup_$(date +%Y%m%d%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    log "$TEXT_BACKUP_SOURCES"
    cp -r /etc/apt/sources.list* "$BACKUP_DIR" 2>/dev/null || true
    [ -d /etc/apt/sources.list.d ] && cp -r /etc/apt/sources.list.d "$BACKUP_DIR" 2>/dev/null || true
    log "$TEXT_BACKUP_COMPLETED $BACKUP_DIR"
}

# --- ADAPTIVER Platzcheck /boot ---
check_boot_space() {
    # Bedarf: Größe des aktuellen initrd + 80 MB Puffer, mindestens 180 MB
    local cur_initrd="/boot/initrd.img-$(uname -r)"
    local cur_mb=0
    if [ -f "$cur_initrd" ]; then
        cur_mb=$(du -m "$cur_initrd" | awk '{print $1}')
    fi
    local need_mb=$(( cur_mb + 80 ))
    [ "$need_mb" -lt 180 ] && need_mb=180

    log "$TEXT_BOOT_CHECK"
    if mountpoint -q /boot; then
        local avail_mb
        avail_mb=$(df -Pm /boot | awk 'NR==2{print $4}')
        log "$TEXT_BOOT_FREE ${avail_mb:-0}"
        if [ "${avail_mb:-0}" -lt "$need_mb" ]; then
            log "$TEXT_BOOT_LOW"
            purge_old_kernels || true
            ensure_linux_image_meta || true
            avail_mb=$(df -Pm /boot | awk 'NR==2{print $4}')
            log "$TEXT_BOOT_FREE ${avail_mb:-0}"
            if [ "${avail_mb:-0}" -lt "$need_mb" ]; then
                log "$TEXT_STILL_NOT_ENOUGH (need ~${need_mb} MB)"
                exit 1
            fi
        fi
    fi
}

# --- Alte Kernel entfernen (sicher) ---
purge_old_kernels() {
    log "$TEXT_PURGE_OLD_KERNELS"
    local running
    running="$(uname -r)"
    log "$TEXT_RUNNING_KERNEL $running"

    local imgs to_purge=()
    imgs=$(dpkg -l 'linux-image-*' | awk '/^ii/ {print $2}' | grep -v -- "-dbg" || true)

    for pkg in $imgs; do
        if [[ "$pkg" =~ ^linux-image-[0-9] ]] && [[ "$pkg" != "linux-image-$running" ]]; then
            to_purge+=("$pkg")
        fi
    done

    local hdrs
    hdrs=$(dpkg -l 'linux-headers-*' | awk '/^ii/ {print $2}' || true)
    for pkg in $hdrs; do
        if [[ "$pkg" =~ ^linux-headers-[0-9] ]] && [[ "$pkg" != *"$running"* ]]; then
            to_purge+=("$pkg")
        fi
    done

    if [ ${#to_purge[@]} -gt 0 ]; then
        log "$TEXT_PURGING_PACKAGES ${to_purge[*]}"
        apt-get purge -y "${to_purge[@]}" || true
        apt-get autoremove --purge -y || true
        update-grub || true
    else
        log "$TEXT_NO_OLD_KERNELS"
    fi
}

# --- Sicherstellen: Meta-Paket linux-image-amd64 ist installiert ---
ensure_linux_image_meta() {
    if ! dpkg -l linux-image-amd64 2>/dev/null | awk '/^ii/ {ok=1} END{exit !ok}'; then
        log "$TEXT_REINSTALL_META"
        apt-get update -y || true
        apt-get install -y linux-image-amd64 || true
    fi
}

# *.list: Drittzeilen auskommentieren
comment_thirdparty_lines_in_list() {
    local file="$1"
    local tmp; tmp="$(mktemp)"
    local changed=0
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*deb && ! "$line" =~ ^[[:space:]]*# ]]; then
            uri=$(awk '
              {
                skip=0;
                for(i=2;i<=NF;i++){
                  if($i ~ /^\[/){skip=1; continue}
                  if(skip && $i ~ /\]$/){skip=0; continue}
                  if(!skip){print $i; exit}
                }
              }' <<< "$line" | head -n1)
            if [[ -n "$uri" ]] && ! is_debian_url "$uri"; then
                echo "# DISABLED_BY_UPGRADE $(date +%F) $line" >>"$tmp"
                echo "$file|$line" >>"$DISABLED_LINES_LIST"
                changed=1
                continue
            fi
        fi
        echo "$line" >>"$tmp"
    done < "$file"

    if [[ "$changed" -eq 1 ]]; then
        cp -a "$file" "${file}.bak.$(date +%F_%H%M%S)"
        mv "$tmp" "$file"
    else
        rm -f "$tmp"
    fi
}

# *.sources: Drittquellen per Enabled: no deaktivieren
disable_in_sources_file() {
    local file="$1"
    local uris
    uris=$(grep -E '^URIs:' "$file" | sed 's/^URIs:[[:space:]]*//' || true)
    [[ -n "$uris" ]] || return 0
    local third=0
    for u in $uris; do
        if ! is_debian_url "$u"; then third=1; fi
    done
    if [[ "$third" -eq 1 ]]; then
        cp -a "$file" "${file}.bak.$(date +%F_%H%M%S)"
        if grep -qE '^Enabled:' "$file"; then
            sed -i -E 's/^Enabled:.*$/Enabled: no/' "$file"
        else
            printf "\nEnabled: no\n" >> "$file"
        fi
        echo "$file" >>"$DISABLED_FILES_LIST"
    fi
}

# Drittquellen deaktivieren (robust)
disable_thirdparty_sources() {
    log "$TEXT_DISABLING_THIRDPARTY"
    mkdir -p "$DISABLED_DIR"
    : > "$DISABLED_FILES_LIST"
    : > "$DISABLED_LINES_LIST"

    [ -f /etc/apt/sources.list ] && comment_thirdparty_lines_in_list /etc/apt/sources.list

    if [[ -d /etc/apt/sources.list.d ]]; then
        shopt -s nullglob
        for f in /etc/apt/sources.list.d/*.list; do
            comment_thirdparty_lines_in_list "$f"
        done
        for f in /etc/apt/sources.list.d/*.sources; do
            disable_in_sources_file "$f"
        done
        shopt -u nullglob
    fi

    # offensichtliche Dritt-Dateien hart verschieben
    for name in teamviewer brave nordvpn; do
        for f in /etc/apt/sources.list.d/*"$name"*.list /etc/apt/sources.list.d/*"$name"*.sources; do
            [[ -e "$f" ]] || continue
            local base; base="$(basename "$f")"
            mv -f "$f" "${DISABLED_DIR}/${base}.disabled}"
            echo "${DISABLED_DIR}/${base}.disabled" >>"$DISABLED_FILES_LIST"
            log "$TEXT_DISABLED: $f -> ${DISABLED_DIR}/${base}.disabled"
        done
    done

    if [[ -s "$DISABLED_FILES_LIST" ]]; then log "$TEXT_DISABLED_FILES_LIST $DISABLED_FILES_LIST"; fi
    if [[ -s "$DISABLED_LINES_LIST" ]]; then log "$TEXT_DISABLED_LINES_LIST $DISABLED_LINES_LIST"; fi
}

# Codenamen in Quellen umstellen (.list & .sources)
switch_codename_in_sources() {
    local current="$1"
    local target="$2"
    log "$TEXT_SWITCH_CODENAME '$target' (current: '${current:-unknown}')…"

    if [[ -f /etc/apt/sources.list ]]; then
        cp -a /etc/apt/sources.list "/etc/apt/sources.list.codename.bak.$(date +%F_%H%M%S)"
        sed -i -E "s/\b${current}\b/${target}/g; s/\bstable\b/${target}/g; s/\btesting\b/${target}/g" /etc/apt/sources.list
    fi

    shopt -s nullglob
    for f in /etc/apt/sources.list.d/*.list; do
        cp -a "$f" "${f}.codename.bak.$(date +%F_%H%M%S)"
        sed -i -E "s/\b${current}\b/${target}/g; s/\bstable\b/${target}/g; s/\btesting\b/${target}/g" "$f"
    done

    for f in /etc/apt/sources.list.d/*.sources; do
        cp -a "$f" "${f}.codename.bak.$(date +%F_%H%M%S)"
        awk -v cur="$current" -v tgt="$target" '
          BEGIN{IGNORECASE=1}
          /^Suites:/ {
            gsub(/\bstable\b/, tgt)
            gsub(/\btesting\b/, tgt)
            if (cur != "") { gsub("\\b" cur "\\b", tgt) }
            print; next
          }
          {print}
        ' "$f" > "${f}.tmp.$$" && mv "${f}.tmp.$$" "$f"
    done
    shopt -u nullglob
}

# Drittquellen wieder aktivieren (optional)
reenable_thirdparty_sources() {
    if [[ ! -s "$DISABLED_FILES_LIST" && ! -s "$DISABLED_LINES_LIST" ]]; then
        log "$TEXT_REENABLE_DONE"
        return 0
    fi

    log "$TEXT_REENABLE_START"
    if [[ -s "$DISABLED_FILES_LIST" ]]; then
        while IFS= read -r entry; do
            [[ -n "$entry" ]] || continue
            # Fall A: verschobene Datei (*.disabled im DISABLED_DIR)
            if [[ "$entry" == "$DISABLED_DIR/"*".disabled" && -f "$entry" ]]; then
                base="$(basename "$entry" ".disabled")"
                dest="/etc/apt/sources.list.d/$base"
                mv "$entry" "$dest" || { log "$TEXT_REENABLE_FAIL $entry (move failed)"; continue; }
                if apt-get update -y -o Acquire::Retries=1 >/dev/null 2>&1; then
                    log "$TEXT_REENABLE_OK $dest"
                else
                    mv "$dest" "$entry" || true
                    log "$TEXT_REENABLE_FAIL $dest"
                fi
            # Fall B: .sources mit Enabled: no (Originalpfad)
            elif [[ -f "$entry" && "$entry" == *.sources ]]; then
                cp -a "$entry" "${entry}.reenable.bak.$(date +%F_%H%M%S)"
                if grep -qE '^Enabled:' "$entry"; then
                    sed -i -E 's/^Enabled:.*$/Enabled: yes/' "$entry"
                else
                    printf "\nEnabled: yes\n" >> "$entry"
                fi
                if apt-get update -y -o Acquire::Retries=1 >/dev/null 2>&1; then
                    log "$TEXT_REENABLE_OK $entry"
                else
                    sed -i -E 's/^Enabled:.*$/Enabled: no/' "$entry"
                    log "$TEXT_REENABLE_FAIL $entry"
                fi
            fi
        done < "$DISABLED_FILES_LIST"
    fi
    log "$TEXT_REENABLE_DONE"
}

# === Start ===
log "$TEXT_STARTING"

# Fremdpakete prüfen
log "$TEXT_CHECK_FOREIGN"
if ! command -v aptitude &> /dev/null; then
    run_command apt-get update -y
    run_command apt-get install -y aptitude
fi
FOREIGN_PACKAGES=$(aptitude search '~i!~ODebian' -F '%p' || true)
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

# Externe Repos prüfen/deaktivieren (robust), aber nur wenn nicht behalten
log "$TEXT_CHECK_EXTERNAL"
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
        disable_thirdparty_sources
    else
        log "$TEXT_WARNING: External repositories may affect the upgrade."
    fi
fi

# Speicherplatz auf / prüfen
log "$TEXT_CHECK_SPACE"
FREE_SPACE=$(df --output=avail -BG / | tail -1 | tr -d 'G')
if [ "${FREE_SPACE:-0}" -lt 5 ]; then
    log "$TEXT_LOW_SPACE"
    exit 1
else
    log "$TEXT_SPACE_OK ${FREE_SPACE}G"
fi

# /boot Platzcheck (adaptiv) – frühzeitig
check_boot_space

# Ausstehende Konfigs prüfen
log "$TEXT_CHECK_PENDING_CONFIGS"
PENDING_CONFIGS=$(find /etc -name '*.dpkg-new' -o -name '*.ucf-dist' 2>/dev/null || true)
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
            ORIGINAL_FILE="${ORIGINAL_FILE%.ucf-dist}"
            mv "$CONFIG_FILE" "$ORIGINAL_FILE"
            log "Updated configuration: $ORIGINAL_FILE"
        done
    else
        log "$TEXT_WARNING: Pending configuration changes may affect the upgrade."
    fi
else
    log "$TEXT_NO_PENDING_CONFIGS"
fi

# Aktuelle/Target-Version ermitteln
if ! command -v lsb_release &> /dev/null; then
    run_command apt-get update -y
    run_command apt-get install -y lsb-release
fi
CURRENT_VERSION=$(lsb_release -cs || echo "")
if [ "$TARGET_VERSION" = "auto" ]; then
    TARGET_VERSION=$(detect_stable_version)
fi
log "$TEXT_CURRENT_VERSION $CURRENT_VERSION"
log "$TEXT_TARGET_VERSION $TARGET_VERSION"

if [ "$CURRENT_VERSION" == "$TARGET_VERSION" ]; then
    log "$TEXT_ALREADY_UP_TO_DATE"
    exit 0
fi

log "$TEXT_UPGRADE_FROM_TO $CURRENT_VERSION $TEXT_TO $TARGET_VERSION."

# Netzwerk / Debian-Server
log "$TEXT_CHECK_CONNECTION"
check_connection
log "$TEXT_SERVERS_REACHABLE"

# Version valide?
log "$TEXT_VALIDATING_VERSION '$TARGET_VERSION'..."
if ! curl -sI "http://ftp.debian.org/debian/dists/$TARGET_VERSION/Release" | grep -q "200 OK"; then
    log "$TEXT_INVALID_VERSION" >&2
    exit 1
fi
log "$TEXT_VALID_VERSION"

# Backups
backup_etc_and_pkglist
backup_apt_sources

# Vorbereitendes Update auf der aktuellen Version
check_boot_space
log "$TEXT_UPDATING_SYSTEM"
run_command apt-get update -y
run_command apt-get full-upgrade -y || true
run_command apt-get --fix-broken install -y || true
run_command apt-get --purge autoremove -y || true
run_command apt-get autoclean -y || true

# Quellen auf TARGET umstellen (.list & .sources)
switch_codename_in_sources "${CURRENT_VERSION:-bookworm}" "$TARGET_VERSION"

# Upgrade-Sequenz wie im Artikel:
check_boot_space
run_command apt-get update -y

# 1) Bestand aktualisieren (ohne neue Pakete) – mit 'apt'
log "$TEXT_STEP1"
run_command apt -y upgrade --without-new-pkgs

# 2) Simulation
log "$TEXT_STEP2"
if ! apt-get -s dist-upgrade; then
    log "$TEXT_SIMULATION_FAILED"
    exit 1
fi

# 3) Full-Upgrade
check_boot_space
log "$TEXT_STEP3"
run_command apt-get dist-upgrade -y

# Aufräumen
run_command apt-get --purge autoremove -y
run_command apt-get autoclean -y

# deb822 modernisieren
log "$TEXT_MODERNIZE"
if command -v apt >/dev/null 2>&1; then
    apt modernize-sources || log "$TEXT_MODERNIZE_WARN"
fi

# Drittquellen wieder aktivieren & testen (optional)
if [ "$REENABLE_THIRDPARTY" = true ]; then
    reenable_thirdparty_sources
fi

# Abschluss-Checks
log "$TEXT_VERSION_CHECKS"
if [[ -r /etc/debian_version ]]; then
    log "  $TEXT_DEBIAN_VERSION $(cat /etc/debian_version)"
fi
if command -v lsb_release >/dev/null 2>&1; then
    lsb_release -a || true
else
    cat /etc/os-release || true
fi

# Hinweise zu manuellem Re-Enable auskommentierter Zeilen
echo
log "$TEXT_REENABLE_HINT"
if [[ -s "$DISABLED_FILES_LIST" ]]; then
    echo "  $TEXT_REENABLE_FILES_CMD"
    echo "    while read -r f; do b=\$(basename \"\$f\" \".disabled\"); mv \"\$f\" \"/etc/apt/sources.list.d/\$b\"; done < \"$DISABLED_FILES_LIST\""
fi
if [[ -s "$DISABLED_LINES_LIST" ]]; then
    echo "  $TEXT_REENABLE_LINES_PATH $DISABLED_LINES_LIST"
fi
echo "  $TEXT_THEN_APT_UPDATE"
echo

# Neustart
log "$TEXT_UPGRADE_COMPLETE"
if [ "$AUTO_REBOOT" = true ]; then
    log "$TEXT_REBOOTING"
    reboot
else
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
fi
