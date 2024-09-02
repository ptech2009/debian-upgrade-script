#!/bin/bash

# Lock-File einrichten, um Mehrfachausführung zu verhindern
LOCKFILE="/tmp/debian-upgrade.lock"
exec 200>$LOCKFILE

flock -n 200 || exit 1

# Funktion zum Abrufen der neuesten Debian-Version
get_latest_debian_version() {
    # Abrufen der neuesten stabilen Version von der offiziellen Debian-Website
    LATEST_VERSION=$(curl -s http://ftp.debian.org/debian/dists/stable/Release | grep Codename | awk '{print $2}')
    echo $LATEST_VERSION
}

# Funktion zum Überprüfen der Erreichbarkeit der Debian-Server
check_connection() {
    if ! ping -c 1 deb.debian.org &> /dev/null; then
        echo "Fehler: Debian-Server sind nicht erreichbar. Bitte prüfen Sie Ihre Netzwerkverbindung." >&2
        exit 1
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
FOREIGN_PACKAGES=$(dpkg-query -W -f='${Package}\t${Status}\n' | grep -v "install ok installed")
if [ -n "$FOREIGN_PACKAGES" ]; then
    echo "Es wurden Fremdpakete gefunden:"
    echo "$FOREIGN_PACKAGES"
    read -p "Möchten Sie diese Pakete vor dem Upgrade entfernen? (j/n): " REMOVE_FOREIGN
    if [ "$REMOVE_FOREIGN" == "j" ]; then
        apt-get remove --purge -y $(echo "$FOREIGN_PACKAGES" | awk '{print $1}')
    else
        echo "Hinweis: Fremdpakete könnten das Upgrade beeinträchtigen."
    fi
else
    echo "Keine Fremdpakete gefunden."
fi

# Überprüfung auf PPA-Repositories und andere externe Quellen
echo "Überprüfe auf PPA-Repositories und andere externe Quellen..."
PPA_LIST=$(find /etc/apt/sources.list.d/ -name "*.list" | grep -i "ppa")
if [ -n "$PPA_LIST" ]; then
    echo "Es wurden PPA-Repositories gefunden:"
    echo "$PPA_LIST"
    read -p "Möchten Sie diese Repositories deaktivieren? (j/n): " DISABLE_PPA
    if [ "$DISABLE_PPA" == "j" ]; then
        for PPA in $PPA_LIST; do
            mv "$PPA" "${PPA}.disabled"
        done
        echo "PPA-Repositories wurden deaktiviert."
    else
        echo "Hinweis: PPA-Repositories könnten das Upgrade beeinträchtigen."
    fi
else
    echo "Keine PPA-Repositories gefunden."
fi

# Überprüfung des verfügbaren Speicherplatzes
echo "Überprüfe den verfügbaren Speicherplatz..."
FREE_SPACE=$(df -h / | grep '/' | awk '{print $4}')
if [ $(echo "$FREE_SPACE" | sed 's/G//') -lt 5 ]; then
    echo "Warnung: Weniger als 5 GB freier Speicherplatz verfügbar. Dies könnte das Upgrade behindern."
    exit 1
else
    echo "Genügend Speicherplatz verfügbar: $FREE_SPACE"
fi

# Überprüfung auf ausstehende Konfigurationsänderungen
echo "Überprüfe auf ausstehende Konfigurationsänderungen..."
PENDING_CONFIGS=$(find /etc -name '*.dpkg-new' -o -name '*.ucf-dist')
if [ -n "$PENDING_CONFIGS" ]; then
    echo "Es wurden ausstehende Konfigurationsänderungen gefunden:"
    echo "$PENDING_CONFIGS"
    read -p "Möchten Sie diese Änderungen jetzt überprüfen und anwenden? (j/n): " APPLY_CONFIG
    if [ "$APPLY_CONFIG" == "j" ]; then
        dpkg --configure -a
        ucf --purge
    else
        echo "Hinweis: Ausstehende Konfigurationsänderungen könnten das Upgrade beeinflussen."
    fi
else
    echo "Keine ausstehenden Konfigurationsänderungen gefunden."
fi

# Aktuelle Debian-Version automatisch erkennen
CURRENT_VERSION=$(lsb_release -cs)
echo "Aktuelle Debian-Version erkannt: $CURRENT_VERSION"

# Neueste Debian-Version automatisch abrufen
NEW_VERSION=$(get_latest_debian_version)
echo "Neueste Debian-Version erkannt: $NEW_VERSION"

# Überprüfung, ob ein Upgrade erforderlich ist
if [ "$CURRENT_VERSION" == "$NEW_VERSION" ]; then
    echo "Das System ist bereits auf dem neuesten Stand."
    exit 0
fi

echo "Das System wird von $CURRENT_VERSION auf $NEW_VERSION aktualisiert."

# Verbindungstest zu den Debian-Servern
echo "Überprüfe die Erreichbarkeit der Debian-Server..."
check_connection
echo "Debian-Server sind erreichbar."

# Automatische Überprüfung der Paketquellen
if ! curl -sI "http://ftp.debian.org/debian/dists/$NEW_VERSION/Release" | grep -q "200 OK"; then
    echo "Fehler: Die neue Debian-Version '$NEW_VERSION' ist nicht gültig oder nicht verfügbar." >&2
    exit 1
fi
echo "Die neue Debian-Version '$NEW_VERSION' ist gültig."

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
if [ $? -ne 0 ]; then
    echo "Fehler: apt-get update ist fehlgeschlagen." >&2
    exit 1
fi

apt-get full-upgrade -y
if [ $? -ne 0 ]; then
    echo "Fehler: apt-get full-upgrade ist fehlgeschlagen." >&2
    exit 1
fi

# Fehlerhafte Pakete reparieren
echo "Überprüfe und repariere eventuell beschädigte Pakete..."
apt --fix-broken install -y
if [ $? -ne 0 ]; then
    echo "Fehler: apt --fix-broken install ist fehlgeschlagen." >&2
    exit 1
fi

# Systembereinigung nach dem Upgrade
echo "Bereinigung des Systems nach dem Upgrade..."
apt-get --purge autoremove -y
if [ $? -ne 0 ]; then
    echo "Fehler: autoremove ist fehlgeschlagen." >&2
    exit 1
fi

apt-get autoclean -y
if [ $? -ne 0 ]; then
    echo "Fehler: autoclean ist fehlgeschlagen." >&2
    exit 1
fi

# System muss nach dem Upgrade neu gestartet werden
if [ ! -f "/var/run/reboot-required" ]; then
    echo "System wird für das Upgrade vorbereitet. Ein Neustart ist erforderlich."
    touch /tmp/upgrade-in-progress
    read -p "Das System wird jetzt neu gestartet. Nach dem Neustart bitte das Skript erneut ausführen. Fortfahren? (j/n): " REBOOT

    if [ "$REBOOT" == "j" ]; then
        reboot
    else
        echo "Bitte starten Sie das System manuell neu und führen Sie das Skript erneut aus, um das Upgrade fortzusetzen."
        exit 0
    fi
else
    echo "System wurde bereits neu gestartet, Upgrade wird fortgesetzt."
fi

# Paketquellen auf die neue Version ändern
echo "Paketquellen werden auf '$NEW_VERSION' aktualisiert..."
sed -i "s/$CURRENT_VERSION/$NEW_VERSION/g" /etc/apt/sources.list
sed -i "s/$CURRENT_VERSION/$NEW_VERSION/g" /etc/apt/sources.list.d/*.list

# Sicherstellen, dass die Debian-Repositories korrekt konfiguriert sind
cat <<EOF > /etc/apt/sources.list
deb http://deb.debian.org/debian/ $NEW_VERSION main contrib non-free non-free-firmware
deb http://deb.debian.org/debian/ $NEW_VERSION-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security $NEW_VERSION-security main contrib non-free non-free-firmware
EOF

echo "Paketquellen wurden erfolgreich auf '$NEW_VERSION' geändert."

# Systemaktualisierung auf die neue Debian-Version
echo "Starte Systemaktualisierung auf Debian $NEW_VERSION..."
apt-get update
if [ $? -ne 0 ]; then
    echo "Fehler: apt-get update ist fehlgeschlagen." >&2
    exit 1
fi

apt-get full-upgrade -y
if [ $? -ne 0 ]; then
    echo "Fehler: apt-get full-upgrade ist fehlgeschlagen." >&2
    exit 1
fi

# Systembereinigung nach dem Upgrade
echo "Bereinigung des Systems nach dem Upgrade..."
apt-get --purge autoremove -y
if [ $? -ne 0 ]; then
    echo "Fehler: autoremove ist fehlgeschlagen." >&2
    exit 1
fi

apt-get autoclean -y
if [ $? -ne 0 ]; then
    echo "Fehler: autoclean ist fehlgeschlagen." >&2
    exit 1
fi

# Letzter Neustart
echo "Das Upgrade ist abgeschlossen. Das System muss neu gestartet werden."
read -p "Jetzt neu starten? (j/n): " FINAL_REBOOT

if [ "$FINAL_REBOOT" == "j" ]; then
    reboot
else
    echo "Bitte starten Sie das System manuell neu, um das Upgrade abzuschließen."
fi

# Entfernen der temporären Datei nach erfolgreichem Neustart
if [ -f "/tmp/upgrade-in-progress" ]; then
    rm /tmp/upgrade-in-progress
fi

# Ausgabe der neuen Debian-Version
NEW_INSTALLED_VERSION=$(lsb_release -ds)
echo "Upgrade erfolgreich abgeschlossen! Das System läuft jetzt auf: $NEW_INSTALLED_VERSION"

# Ausgabe des Speicherorts der Backup-Dateien
echo "Die Backup-Dateien der Paketquellen befinden sich im Verzeichnis: $BACKUP_DIR"
echo "Es wird empfohlen, diese Dateien an einem sicheren Ort zu speichern."

# Ausgabe des Speicherorts der Logdatei
echo "Das Log des Upgrade-Prozesses wurde unter $LOGFILE gespeichert."
