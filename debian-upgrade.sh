#!/bin/bash
set -euo pipefail

# ========= Defaults / Flags =========
AUTO_REBOOT=false
ASSUME_YES=false
KEEP_FOREIGN_PACKAGES=false
KEEP_EXTERNAL_REPOS=false
PRESERVE_NETWORK=true
DO_XRDP_FIX=true
DRY_RUN=false

export DEBIAN_FRONTEND=noninteractive

LANGUAGE="de"

# ========= Language Select =========
select_language() {
  echo "Please select your language / Bitte wählen Sie Ihre Sprache:"
  echo "1) English"
  echo "2) Deutsch"
  read -p "Selection [1-2]: " LANG_CHOICE
  case "${LANG_CHOICE:-2}" in
    1) LANGUAGE="en" ;;
    *) LANGUAGE="de" ;;
  esac
}

set_language_strings() {
  if [ "$LANGUAGE" = "en" ]; then
    T_USAGE="Usage: $0 [options]"
    T_OPTIONS="Options:"
    T_AR="--auto-reboot                Automatically reboot after upgrade"
    T_AY="--assume-yes, --non-interactive  Automatically answer 'Yes' to prompts"
    T_KFP="--keep-foreign-packages      Keep foreign packages"
    T_KER="--keep-external-repos        Keep external repositories"
    T_NPN="--no-preserve-network        Do NOT preserve/restore network settings"
    T_SXF="--skip-xrdp-fix              Skip optional xrdp/KDE fix"
    T_DRY="--dry-run                    Do not modify system, only show actions"
    T_HELP="-h, --help                   Show this help"
    T_ERR="Error"
    T_START="Starting Debian upgrade script..."
    T_ALREADY="Another upgrade script is already running."
    T_ROOT="This script must be run as root."
    T_CHECK_FOREIGN="Checking for installed foreign packages..."
    T_FOREIGN_FOUND="Foreign packages found:"
    T_KEEPING_FOREIGN="Keeping foreign packages due to --keep-foreign-packages."
    T_REMOVE_FOREIGN_PROMPT="Remove foreign packages before the upgrade? [y/N]: "
    T_REMOVING_FOREIGN="Removing foreign packages..."
    T_NO_FOREIGN="No foreign packages found."
    T_CHECK_EXTERNAL="Checking for non-official Debian repositories..."
    T_EXTERNAL_FOUND="Non-official repositories found:"
    T_KEEPING_EXTERNAL="Keeping external repositories due to --keep-external-repos."
    T_DISABLE_EXTERNAL_PROMPT="Disable external repositories before the upgrade? [y/N]: "
    T_DISABLING_EXTERNAL="Disabling external repositories..."
    T_NO_EXTERNAL="No external repositories found."
    T_SPACE="Checking available disk space..."
    T_LOW_SPACE="Warning: Less than 5 GB of free space."
    T_SPACE_OK="Available space:"
    T_PENDING="Checking for pending configuration changes..."
    T_PENDING_FOUND="Pending configuration changes found:"
    T_RESOLVE_PENDING="Resolving pending configuration changes..."
    T_NO_PENDING="No pending configuration changes found."
    T_CUR_VER="Current Debian codename:"
    T_TGT_VER="Target Debian codename:"
    T_ALREADY_UPTODATE="System already at target version."
    T_UPGRADE="System will be upgraded from"
    T_TO="to"
    T_CONN="Checking reachability of Debian servers..."
    T_CONN_OK="Debian servers reachable."
    T_TGT_INVALID="The Debian version '$TARGET_VERSION' is not valid/available."
    T_TGT_VALID="Debian version '$TARGET_VERSION' seems valid."
    T_BKP_SOURCES="Backing up APT sources..."
    T_BKP_DONE="Backup completed at:"
    T_UPDATE_SYS="Updating current system and fixing package issues..."
    T_UPD_SOURCES="Updating package sources to"
    T_SOURCES_OK="Sources updated to"
    T_MIN_UPG="Performing minimal upgrade..."
    T_FULL_UPG="Performing full upgrade..."
    T_DONE="Upgrade complete. A reboot is required."
    T_PROMPT_REBOOT="Reboot now? [y/N]: "
    T_REBOOT="Rebooting..."
    T_REBOOT_LATER="Please reboot manually to finish."
    T_WARN="Warning"
    T_DISABLED="Disabled"
    T_NET_SNAPSHOT="Snapshotting current network state..."
    T_NET_WARN_STACK="Warning: Multiple network stacks detected. Ensure only one manages interfaces."
    T_NET_RESTORE="Restoring/ensuring network comes up after upgrade..."
    T_NET_UP="Brought interface up:"
    T_SSH_ENSURE="Ensuring OpenSSH server is installed/enabled..."
    T_XRDP_FIX="Applying optional xrdp/KDE fix..."
  else
    T_USAGE="Verwendung: $0 [Optionen]"
    T_OPTIONS="Optionen:"
    T_AR="--auto-reboot                Neustart nach dem Upgrade automatisch durchführen"
    T_AY="--assume-yes, --non-interactive  Alle Fragen automatisch mit 'Ja' beantworten"
    T_KFP="--keep-foreign-packages      Fremdpakete beibehalten"
    T_KER="--keep-external-repos        Externe Repositories beibehalten"
    T_NPN="--no-preserve-network        Netzwerk NICHT sichern/wiederherstellen"
    T_SXF="--skip-xrdp-fix              xrdp/KDE Fix überspringen"
    T_DRY="--dry-run                    NUR anzeigen, nichts ändern"
    T_HELP="-h, --help                   Hilfe anzeigen"
    T_ERR="Fehler"
    T_START="Starte Debian Upgrade Skript..."
    T_ALREADY="Ein anderes Upgrade-Skript läuft bereits."
    T_ROOT="Dieses Skript muss als root ausgeführt werden."
    T_CHECK_FOREIGN="Prüfe installierte Fremdpakete..."
    T_FOREIGN_FOUND="Fremdpakete gefunden:"
    T_KEEPING_FOREIGN="Fremdpakete werden beibehalten (--keep-foreign-packages)."
    T_REMOVE_FOREIGN_PROMPT="Fremdpakete vor dem Upgrade entfernen? [j/N]: "
    T_REMOVING_FOREIGN="Entferne Fremdpakete..."
    T_NO_FOREIGN="Keine Fremdpakete gefunden."
    T_CHECK_EXTERNAL="Prüfe nicht-offizielle Debian-Repositories..."
    T_EXTERNAL_FOUND="Nicht-offizielle Repositories gefunden:"
    T_KEEPING_EXTERNAL="Externe Repositories werden beibehalten (--keep-external-repos)."
    T_DISABLE_EXTERNAL_PROMPT="Externe Repositories vor dem Upgrade deaktivieren? [j/N]: "
    T_DISABLING_EXTERNAL="Deaktiviere externe Repositories..."
    T_NO_EXTERNAL="Keine externen Repositories gefunden."
    T_SPACE="Prüfe verfügbaren Speicherplatz..."
    T_LOW_SPACE="Warnung: Weniger als 5 GB frei."
    T_SPACE_OK="Freier Speicher:"
    T_PENDING="Prüfe ausstehende Konfigurationsänderungen..."
    T_PENDING_FOUND="Ausstehende Konfigurationsänderungen gefunden:"
    T_RESOLVE_PENDING="Wende ausstehende Konfigurationsänderungen an..."
    T_NO_PENDING="Keine ausstehenden Konfigurationsänderungen."
    T_CUR_VER="Aktueller Debian-Codename:"
    T_TGT_VER="Ziel-Codename:"
    T_ALREADY_UPTODATE="System bereits auf Zielversion."
    T_UPGRADE="Upgrade von"
    T_TO="nach"
    T_CONN="Prüfe Erreichbarkeit der Debian-Server..."
    T_CONN_OK="Debian-Server erreichbar."
    T_TGT_INVALID="Debian-Version '$TARGET_VERSION' ist ungültig/nicht verfügbar."
    T_TGT_VALID="Debian-Version '$TARGET_VERSION' ist gültig."
    T_BKP_SOURCES="Sichere APT-Quellen..."
    T_BKP_DONE="Backup abgelegt unter:"
    T_UPDATE_SYS="Aktualisiere System & behebe Paketfehler..."
    T_UPD_SOURCES="Setze Paketquellen auf"
    T_SOURCES_OK="Quellen aktualisiert auf"
    T_MIN_UPG="Führe Minimal-Upgrade durch..."
    T_FULL_UPG="Führe Voll-Upgrade durch..."
    T_DONE="Upgrade abgeschlossen. Neustart erforderlich."
    T_PROMPT_REBOOT="Jetzt neu starten? [j/N]: "
    T_REBOOT="Starte neu..."
    T_REBOOT_LATER="Bitte manuell neu starten."
    T_WARN="Warnung"
    T_DISABLED="Deaktiviert"
    T_NET_SNAPSHOT="Sichere aktuellen Netzwerkzustand..."
    T_NET_WARN_STACK="Warnung: Mehrere Netzwerk-Stacks erkannt. Sorge dafür, dass nur einer Interfaces verwaltet."
    T_NET_RESTORE="Stelle sicher, dass Netzwerk nach Upgrade wieder hochkommt..."
    T_NET_UP="Interface hochgefahren:"
    T_SSH_ENSURE="Stelle sicher, dass OpenSSH installiert/aktiv ist..."
    T_XRDP_FIX="Führe optionalen xrdp/KDE Fix aus..."
  fi
}

# ========= Args =========
while [[ $# -gt 0 ]]; do
  case "$1" in
    --auto-reboot) AUTO_REBOOT=true ;;
    --assume-yes|--non-interactive) ASSUME_YES=true ;;
    --keep-foreign-packages) KEEP_FOREIGN_PACKAGES=true ;;
    --keep-external-repos) KEEP_EXTERNAL_REPOS=true ;;
    --no-preserve-network) PRESERVE_NETWORK=false ;;
    --skip-xrdp-fix) DO_XRDP_FIX=false ;;
    --dry-run) DRY_RUN=true ;;
    -h|--help)
      select_language; set_language_strings
      echo "$T_USAGE"; echo "$T_OPTIONS"
      echo "  $T_AR"; echo "  $T_AY"; echo "  $T_KFP"; echo "  $T_KER"
      echo "  $T_NPN"; echo "  $T_SXF"; echo "  $T_DRY"; echo "  $T_HELP"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"; exit 1 ;;
  esac
  shift
done

select_language; set_language_strings

# ========= Root / Lock / Log =========
[ "$(id -u)" -eq 0 ] || { echo "$T_ROOT" >&2; exit 1; }

LOGFILE="/var/log/debian-upgrade.log"
mkdir -p "$(dirname "$LOGFILE")"
log(){ echo "[$(date '+%F %T')] $*" | tee -a "$LOGFILE"; }

LOCKFILE="/var/run/debian-upgrade.lock"
if [ -f "$LOCKFILE" ] && kill -0 "$(cat "$LOCKFILE" 2>/dev/null)" 2>/dev/null; then
  log "$T_ALREADY"; exit 1
fi
echo $$ > "$LOCKFILE"
trap 'rm -f "$LOCKFILE"' EXIT

run(){
  if $DRY_RUN; then log "[DRY] $*"; return 0; fi
  "$@"
}

ask_yn(){
  local prompt="$1" default_no="${2:-true}"
  if $ASSUME_YES; then echo "y"; return; fi
  read -r -p "$prompt" ans || true
  if [[ "$ans" =~ ^[YyJj]$ ]]; then echo "y"; else echo "n"; fi
}

log "$T_START"

# ========= Network snapshot =========
NET_BKP_DIR="/root/upgrade-backup-$(date +%Y%m%d%H%M%S)"
run mkdir -p "$NET_BKP_DIR"
log "$T_NET_SNAPSHOT"

ACTIVE_IFACE="$(ip -o -4 route show to default 2>/dev/null | awk '{print $5}' || true)"
ACTIVE_IP="$(ip -o -4 addr show "$ACTIVE_IFACE" 2>/dev/null | awk '{print $4}' | head -n1 || true)"
run cp -a /etc/network/interfaces "$NET_BKP_DIR/interfaces.bak" 2>/dev/null || true
run cp -a /etc/network/interfaces.d "$NET_BKP_DIR/" 2>/dev/null || true
run cp -a /etc/resolv.conf "$NET_BKP_DIR/" 2>/dev/null || true

# Detect multiple stacks
STACKS=0
systemctl is-active --quiet systemd-networkd && STACKS=$((STACKS+1))
systemctl is-active --quiet NetworkManager && STACKS=$((STACKS+1))
[ -f /etc/network/interfaces ] && grep -q "iface" /etc/network/interfaces && STACKS=$((STACKS+1))
[ $STACKS -gt 1 ] && log "$T_NET_WARN_STACK"

# ========= Ensure SSH =========
log "$T_SSH_ENSURE"
run apt-get update -y
run apt-get install -y openssh-server
run systemctl enable --now ssh

# ========= Foreign packages =========
log "$T_CHECK_FOREIGN"
run apt-get install -y aptitude
FOREIGN="$(aptitude search '~i!~ODebian' -F '%p' || true)"
if [ -n "$FOREIGN" ]; then
  log "$T_FOREIGN_FOUND"; log "$FOREIGN"
  if ! $KEEP_FOREIGN_PACKAGES; then
    if [ "$(ask_yn "$T_REMOVE_FOREIGN_PROMPT")" = "y" ]; then
      log "$T_REMOVING_FOREIGN"
      run apt-get remove --purge -y $FOREIGN
    else
      log "$T_WARN: foreign packages may impact the upgrade."
    fi
  else
    log "$T_KEEPING_FOREIGN"
  fi
else
  log "$T_NO_FOREIGN"
fi

# ========= External repos =========
log "$T_CHECK_EXTERNAL"
EXT_REPOS=$(grep -rE '^(deb|deb-src) ' /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null | \
  grep -vE 'debian\.org|security\.debian\.org|ftp\.debian\.org|deb\.debian\.org' || true)
if [ -n "$EXT_REPOS" ]; then
  log "$T_EXTERNAL_FOUND"; log "$EXT_REPOS"
  if ! $KEEP_EXTERNAL_REPOS; then
    if [ "$(ask_yn "$T_DISABLE_EXTERNAL_PROMPT")" = "y" ]; then
      log "$T_DISABLING_EXTERNAL"
      while IFS= read -r line; do
        f="${line%%:*}"
        [ -f "$f" ] && run mv "$f" "${f}.disabled"
        log "$T_DISABLED: $f"
      done <<< "$EXT_REPOS"
    else
      log "$T_WARN: external repos kept."
    fi
  else
    log "$T_KEEPING_EXTERNAL"
  fi
else
  log "$T_NO_EXTERNAL"
fi

# ========= Space check =========
log "$T_SPACE"
FREE_GB=$(df --output=avail -BG / | tail -1 | tr -d 'G')
if [ "${FREE_GB:-0}" -lt 5 ]; then log "$T_LOW_SPACE"; exit 1; fi
log "$T_SPACE_OK ${FREE_GB}G"

# ========= Pending configs =========
log "$T_PENDING"
PENDING=$(find /etc -name '*.dpkg-new' -o -name '*.ucf-dist' 2>/dev/null || true)
if [ -n "$PENDING" ]; then
  log "$T_PENDING_FOUND"; log "$PENDING"
  if [ "$(ask_yn "$T_RESOLVE_PENDING [y/N]: ")" = "y" ] || $ASSUME_YES; then
    for f in $PENDING; do
      base="${f%.dpkg-new}"; base="${base%.ucf-dist}"
      run mv "$f" "$base"
      log "Updated: $base"
    done
  fi
else
  log "$T_NO_PENDING"
fi

# ========= Determine versions =========
if ! command -v lsb_release >/dev/null 2>&1; then run apt-get install -y lsb-release; fi
CUR=$(lsb_release -cs || echo "")
TARGET="auto"

detect_stable(){ curl -fsSL http://ftp.debian.org/debian/dists/stable/Release | awk '/^Codename:/{print $2}'; }
if [ "$TARGET" = "auto" ]; then TARGET="$(detect_stable)"; fi

log "$T_CUR_VER $CUR"
log "$T_TGT_VER $TARGET"

if [ "$CUR" = "$TARGET" ]; then log "$T_ALREADY_UPTODATE"; exit 0; fi
log "$T_UPGRADE $CUR $T_TO $TARGET."

# ========= Connectivity =========
log "$T_CONN"
if ! curl -sI http://deb.debian.org/ | grep -q "200 OK"; then
  log "$T_ERR: deb.debian.org not reachable"; exit 1
fi
log "$T_CONN_OK"

# ========= Validate target =========
if ! curl -sI "http://ftp.debian.org/debian/dists/$TARGET/Release" | grep -q "200 OK"; then
  log "$T_TGT_INVALID"; exit 1
fi
log "$T_TGT_VALID"

# ========= Backups =========
run mkdir -p "$NET_BKP_DIR/apt"
log "$T_BKP_SOURCES"
run cp -a /etc/apt/sources.list* "$NET_BKP_DIR/apt/" 2>/dev/null || true
run cp -a /etc/apt/sources.list.d "$NET_BKP_DIR/apt/" 2>/dev/null || true
log "$T_BKP_DONE $NET_BKP_DIR"

# ========= Pre update fix =========
log "$T_UPDATE_SYS"
run apt-get update -y
run apt-get -o Dpkg::Options::="--force-confold" upgrade -y
run apt-get dist-upgrade -y || true
run apt-get --fix-broken install -y
run apt-get --purge autoremove -y
run apt-get autoclean -y

# ========= Switch sources (only current codename) =========
log "$T_UPD_SOURCES '$TARGET'..."
for f in /etc/apt/sources.list /etc/apt/sources.list.d/*.list; do
  [ -f "$f" ] || continue
  run cp -a "$f" "$f.bak.$(date +%s)"
  # Replace exact codename or 'stable' pointing to old codename
  run sed -i -E "s/(^deb(\-src)?[[:space:]].*[[:space:]])$CUR([[:space:]].*)/\1$TARGET\3/g" "$f"
  # Also normalize 'stable' if esoteric mixes exist
  run sed -i -E "s/(^deb(\-src)?[[:space:]].*[[:space:]])stable([[:space:]].*)/\1$TARGET\3/g" "$f"
done
log "$T_SOURCES_OK '$TARGET'."

# ========= Upgrade =========
run apt-get update -y

log "$T_MIN_UPG"
run apt-get -o Dpkg::Options::="--force-confold" upgrade -y

log "$T_FULL_UPG"
run apt-get -o Dpkg::Options::="--force-confold" dist-upgrade -y

run apt-get --purge autoremove -y
run apt-get autoclean -y

# ========= Optional xrdp/KDE fix =========
if $DO_XRDP_FIX; then
  log "$T_XRDP_FIX"
  run apt-get install -y xrdp xorg dbus-x11 x11-xserver-utils || true
  # try to detect KDE
  if dpkg -l | grep -q plasma-desktop; then
    # Set KDE X11 session for xrdp
    if [ -n "${SUDO_USER:-}" ]; then HOME_DIR="$(getent passwd "$SUDO_USER" | cut -d: -f6)"; else HOME_DIR="/root"; fi
    run bash -c "echo 'startplasma-x11' > '$HOME_DIR/.xsession'"
    [ -n "${SUDO_USER:-}" ] && run chown "$SUDO_USER":"$SUDO_USER" "$HOME_DIR/.xsession" || true
  fi
  run adduser "${SUDO_USER:-$(whoami)}" ssl-cert || true
  run systemctl enable --now xrdp || true
fi

# ========= Network restore/ensure =========
if $PRESERVE_NETWORK; then
  log "$T_NET_RESTORE"
  # If active iface is empty or DOWN, try to bring the previous one back
  IFACE_NOW="$(ip -o -4 route show to default 2>/dev/null | awk '{print $5}' || true)"
  if [ -z "$IFACE_NOW" ] && [ -n "$ACTIVE_IFACE" ]; then
    run ip link set "$ACTIVE_IFACE" up || true
    # try DHCP first
    if command -v dhclient >/dev/null 2>&1; then run dhclient "$ACTIVE_IFACE" || true; fi
    log "$T_NET_UP $ACTIVE_IFACE"
  fi
  # If we had a static interfaces file before and it vanished, restore it
  if [ -f "$NET_BKP_DIR/interfaces.bak" ] && [ ! -f /etc/network/interfaces ]; then
    run cp -a "$NET_BKP_DIR/interfaces.bak" /etc/network/interfaces
    run systemctl restart networking || true
  fi
fi

# ========= Finish / Reboot =========
log "$T_DONE"
if $AUTO_REBOOT; then
  log "$T_REBOOT"; $DRY_RUN || reboot
else
  if [ "$(ask_yn "$T_PROMPT_REBOOT")" = "y" ]; then
    log "$T_REBOOT"; $DRY_RUN || reboot
  else
    log "$T_REBOOT_LATER"
  fi
fi
