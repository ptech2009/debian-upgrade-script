# Debian Upgrade Script

## Overview
This script automates the process of upgrading a Debian-based system with extensive safety checks and interactive prompts to ensure a smooth and secure upgrade.

## Features
- Prevents multiple executions with a lock file.
- Ensures the script is run with root privileges.
- Automatically fetches the latest stable Debian version.
- Checks the connection to Debian servers.
- Detects and optionally removes foreign packages.
- Identifies and optionally disables PPA repositories.
- Verifies available disk space before starting the upgrade.
- Backs up configuration files and current package sources.
- Updates the system to the latest version.
- Cleans up the system post-upgrade.
- Reboots the system to apply the updates.

## Requirements
- Debian-based system.
- Root privileges.
- Active internet connection.

## Usage
1. Clone the repository:
   ```bash
   git clone https://github.com/ptech2009/debian-upgrade-script.git

Navigate to the script directory:
cd debian-upgrade-script

Make the script executable:
chmod +x debian-upgrade.sh

Run the script with root privileges:
sudo ./debian-upgrade.sh

Versioning

This project uses Semantic Versioning. For the available versions, see the tags on this repository.
Contributing

Feel free to submit issues and pull requests. Contributions are welcome.
License

This project is licensed under the MIT License. See the LICENSE file for details.
Contact

For any questions or suggestions, feel free to reach out via GitHub Issues or contact ptech09@schumacher.or.at
