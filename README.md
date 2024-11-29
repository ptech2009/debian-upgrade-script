Debian Upgrade Script Overview

This script automates the process of upgrading a Debian-based system. It provides comprehensive safety checks and automation options to ensure a smooth and secure upgrade experience.
🚀 Features

    🛡 Safety: Prevents multiple executions with a lock file.
    🔑 Root Check: Ensures the script is run with root privileges.
    📡 Automatic Version Detection: Automatically detects the latest stable Debian version.
    ✍️ Manual Target Version: Allows specifying a target Debian version manually.
    🌐 Connection Check: Verifies connection to Debian servers.
    🔧 Source Update: Updates package sources while preserving custom configurations.
    🗑 Foreign Package Removal: Detects and optionally removes non-official Debian packages.
    💾 Disk Space Check: Verifies available disk space before upgrading.
    🔍 Configuration Backup: Backs up existing configuration files and package sources.
    🛠 System Update: Updates the system to the latest packages of the current version.
    ⚙️ Repair Tools: Fixes defective packages and broken dependencies.
    🧹 Post-Upgrade Cleanup: Removes unnecessary packages and cache files.
    🔄 Automation: Provides options for fully automating the upgrade process.
    🔁 Automatic Reboot: Optionally reboots the system after the upgrade is complete.

🛠 Requirements

    Debian-based system
    Root privileges
    Active internet connection
    aptitude package (will be installed automatically if not present)

🔧 Usage
Command-Line Options

    --auto-remove-foreign: Automatically removes foreign (non-official) packages.
    --disable-external-repos: Automatically disables external repositories not part of official Debian.
    --auto-reboot: Reboots the system after the upgrade is complete.
    -h, --help: Displays the help message with usage instructions.

📖 Examples
Fully Automated Upgrade

    sudo bash debian-upgrade.sh --auto-remove-foreign --disable-external-repos --auto-reboot

Upgrade with Manual Control

    sudo bash debian-upgrade.sh

    Allows you to review and handle identified issues manually.

📝 Manually Specify Target Version

By default, the script upgrades to the latest stable Debian version. To specify a target version, modify the following line in the script:

    TARGET_VERSION=$(get_latest_debian_version)

Replace it with:

    TARGET_VERSION="bullseye"  # For Debian 11

⚠️ Note: Manual changes to the script should be made carefully.

🖥 Installation Steps

Download the Script
Visit the Releases page and download the latest version.

Extract the ZIP File
Unpack the ZIP file to your desired location.

Navigate to the Script Directory
Open a terminal and navigate to the extracted directory:

    cd path_to_extracted_folder/debian-upgrade-script

Make the Script Executable
Grant execution permissions to the script:

    chmod +x debian-upgrade.sh

Run the Script
Execute the script with root privileges:

    sudo ./debian-upgrade.sh [options]

🔖 Versioning

This project follows Semantic Versioning. Check the repository's tags for available versions.
📄 License

This project is licensed under the MIT License. See the LICENSE file for details.
✉️ Contact

For any questions or suggestions, feel free to reach out via GitHub Issues or email: ptech09@schumacher.or.at.
