Debian Upgrade Script
Overview

This script automates the process of upgrading a Debian-based system with extensive safety checks and interactive prompts to ensure a smooth and secure upgrade.
Features

    Prevents multiple executions with a lock file.
    Ensures the script is run with root privileges.
    Allows specifying a target Debian version (e.g., bookworm).
    Checks the connection to Debian servers.
    Automatically updates package sources to the specified Debian version.
    Detects and optionally removes foreign packages.
    Identifies and optionally disables non-official Debian repositories.
    Verifies available disk space before starting the upgrade.
    Detects pending configuration changes: Lists and addresses unresolved .dpkg-new or .ucf-dist files.
    Backs up configuration files and current package sources.
    Updates the system to the latest version of the specified Debian release.
    Repairs defective packages: Checks and repairs dependency issues or corrupted packages after the upgrade process.
    Cleans up the system post-upgrade: Removes unnecessary files and outdated packages.
    Optionally performs an automatic reboot after the upgrade is complete.

Requirements

    Debian-based system.
    Root privileges.
    Active internet connection.

Usage
Download the Script

Download or copy the script into a new file named debian-upgrade.sh.
Make the Script Executable

Grant executable permissions to the script:

chmod +x debian-upgrade.sh  

Run the Script

Execute the script with root privileges:

sudo ./debian-upgrade.sh [options]  

Options

    --auto-remove-foreign: Automatically removes foreign packages.
    --disable-external-repos: Automatically disables non-official repositories.
    --auto-reboot: Performs a system reboot after the upgrade.
    -h, --help: Displays the help menu with available options.

Versioning

This project uses Semantic Versioning. For available versions, see the tags on this repository.
Contributing

Feel free to submit issues and pull requests. Contributions are welcome.
Licence

This project is licensed under the MIT License. See the LICENSE file for details.
Contact

For any questions or suggestions, feel free to reach out via GitHub Issues or contact ptech09@schumacher.or.at.
