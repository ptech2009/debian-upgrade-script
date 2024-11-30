# Debian Upgrade Script

## Overview

This script automates the process of upgrading a Debian-based system. It provides comprehensive safety checks and interactive options to ensure a smooth and secure upgrade experience.

### 🚀 Features

- 🛡 **Safety:** Prevents multiple executions with a lock file.
- 🔑 **Root Privilege Check:** Ensures the script is run with root privileges.
- 📡 **Automatic Version Detection:** Automatically detects the current and latest stable Debian versions.
- ✍️ **Manual Target Version:** Allows specifying a target Debian version manually.
- 🌐 **Connection Check:** Verifies connectivity to Debian servers.
- 🔧 **Source Update:** Updates package sources while preserving custom configurations.
- 🗑 **Foreign Package Detection:** Identifies and offers to remove non-official Debian packages.
- 💾 **Disk Space Check:** Verifies available disk space before upgrading.
- 🔍 **Configuration Backup:** Backs up existing configuration files and package sources.
- 🛠 **System Update:** Updates the system to the latest packages of the current version.
- 🔄 **Interactive Decisions:** Provides the user with control over critical steps during the upgrade.
- 🔁 **Automatic Reboot:** Optionally reboots the system after the upgrade is complete.

## 🛠 Requirements

- Debian-based system
- Root privileges
- Active internet connection
- `aptitude`, `lsb-release`, `curl` or `wget` (will be installed automatically if not present)

## 🔧 Usage

### Command-Line Options

- `--auto-reboot`: Automatically reboots the system after the upgrade is complete.
- `-h`, `--help`: Displays the help message with usage instructions.

### Examples

**Upgrade with Automatic Reboot:**

```bash
sudo bash debian-upgrade.sh --auto-reboot

Upgrade with Manual Control:

sudo bash debian-upgrade.sh

Note: The script may require user input during execution to confirm decisions.

📝 Manually Specify Target Version

By default, the script upgrades to the latest stable Debian version. To specify a target version, modify the following line in the script:

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
