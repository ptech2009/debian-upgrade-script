# Debian Upgrade Script

This script automates the process of upgrading a Debian-based system. It provides comprehensive safety checks and interactive options to ensure a smooth and secure upgrade experience.

---

## 🚀 Features

- 🛡 **Safety**: Prevents multiple executions by using a lock file.  
- 🔑 **Root Privilege Check**: Ensures the script is run with root privileges.  
- 🌐 **Localization**: Supports both English and German languages.  
- 📡 **Automatic Version Detection**: Detects the current Debian version.  
- 🎯 **Automatic Target Version**: Upgrades to the current Debian stable release if `TARGET_VERSION="auto"`.  
- ✍️ **Manual Target Version**: Allows specifying a custom target Debian version.  
- 🌐 **Connection Check**: Verifies connectivity to Debian servers.  
- 🔧 **Source Update**: Updates package sources and backs up existing configurations.  
- 🗑 **Foreign Package Detection**: Detects and offers to remove non-official Debian packages.  
- 🗄️ **Pending Configuration Handling**: Detects pending configuration changes and offers to resolve them.  
- 💾 **Disk Space Check**: Verifies available disk space before upgrading.  
- 📋 **Log Management**: Includes log rotation to prevent uncontrolled log growth.  
- 🔍 **Configuration Backup**: Backs up APT sources and important configs.  
- 🛠 **System Update**: Updates the system to the latest packages before the full upgrade.  
- 🔄 **Interactive Decisions**: Lets the user control critical upgrade steps.  
- 🔁 **Automatic Reboot**: Can reboot automatically after the upgrade.  
- 🌐 **Network Preservation**: Snapshots and restores network configuration to prevent connectivity loss (`--no-preserve-network` to disable).  
- 🔒 **SSH Availability**: Ensures `openssh-server` is installed and enabled to keep remote access available.  
- 🖥 **Optional xrdp/KDE Fix**: Automatically repairs known xrdp/KDE login issues (`--skip-xrdp-fix` to disable).  
- 🧪 **Dry-Run Mode**: Simulates upgrade steps without making any changes (`--dry-run`).  

---

## 🛠 Requirements

- Debian-based system  
- Root privileges  
- Active internet connection  
- `aptitude`, `lsb-release`, `curl` or `wget` (installed automatically if missing)  

---

## 🔧 Command-Line Options

```
--auto-reboot            Automatically reboots after the upgrade is complete.
--assume-yes, --non-interactive   Automatically answer all prompts with 'Yes'.
--keep-foreign-packages  Keep foreign (non-official Debian) packages.
--keep-external-repos    Keep external repositories.
--no-preserve-network    Do not snapshot/restore network configuration.
--skip-xrdp-fix          Skip the optional xrdp/KDE repair.
--dry-run                Simulate steps without making changes.
-h, --help               Show usage.
```

---

## 💡 Examples

Upgrade with automatic reboot:
```bash
sudo ./debian-upgrade.sh --assume-yes --auto-reboot
```

Upgrade with manual control:
```bash
sudo ./debian-upgrade.sh
```

Keep external repositories and foreign packages:
```bash
sudo ./debian-upgrade.sh --assume-yes --keep-foreign-packages --keep-external-repos
```

Dry-run only (no changes):
```bash
sudo ./debian-upgrade.sh --dry-run
```

---

## 📝 Manual Target Version

By default:
```bash
TARGET_VERSION="auto"
```

This automatically upgrades to the latest stable release.  
To upgrade to a specific version, replace `"auto"` with the codename or version number, e.g. `bookworm`, `trixie`, `12`, `13`.  

⚠️ Use manual overrides with caution.  

---

## 🖥 Installation

Clone the repository:
```bash
git clone https://github.com/ptech2009/debian-upgrade-script.git
```

Enter the script directory:
```bash
cd debian-upgrade-script
```

Make the script executable:
```bash
chmod +x debian-upgrade.sh
```

Run the script:
```bash
sudo ./debian-upgrade.sh [options]
```

---

## 🔖 Versioning

This project follows **Semantic Versioning**.  
See [Releases](../../releases) for available versions.  

---

## 📄 License

This project is licensed under the MIT License.  
See the LICENSE file for details.  

---

## ✉️ Contact

For questions or suggestions, please open a GitHub Issue or email: **ptech09@schumacher.or.at**  

---

## ⚠️ Important

Always perform a **full system backup** before upgrading.  
Despite the script’s safety checks, unexpected issues can still occur in rare cases.
