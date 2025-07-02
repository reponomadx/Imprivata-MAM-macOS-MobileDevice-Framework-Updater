<img src="reponomadx-logo.jpg" alt="reponomadx" width="420"/>

# Imprivata MAM macOS MobileDevice Framework Updater

[![Platform](https://img.shields.io/badge/platform-macOS-blue)](https://github.com/reponomadx)
[![Language](https://img.shields.io/badge/language-Bash-lightgrey)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Maintained](https://img.shields.io/badge/maintained-yes-brightgreen)](https://github.com/reponomadx)

---

A Bash-based tool to automate the remote deployment of Apple’s `MobileDevice framework` to managed macOS devices that are running the Imprivata GroundControl Launchpad Application.

This script handles file transfer, installation, cleanup, and relaunch of the Imprivata GroundControl Launchpad application across multiple macOS endpoints.

---

## 📌 Prerequisites

Before using this tool, ensure the following:

- ✅ **Admin Elevation Required**:  
  The local user account (`YOUR_SERVICE_ACCOUNT`) must have elevated admin rights.  
  See this project for automated admin elevation via Workspace ONE:  
  👉 [macos-elevated-admin-ws1](https://github.com/reponomadx/macos-elevated-admin-ws1)

- ✅ **Remote Login (SSH) Enabled**:  
  On all target Macs, **System Preferences > Sharing > Remote Login** must be enabled.

- ✅ **File Sharing Directory Exists**:  
  The `~/Downloads` path (or equivalent) on the remote account must be writable.

- ✅ **Same Local Account Exists**:  
  All remote Macs must have the same user account name and password (`YOUR_SERVICE_ACCOUNT` in this example).

- ✅ **`sshpass` Installed**:  
  The script relies on [`sshpass`](https://linux.die.net/man/1/sshpass) for non-interactive SSH sessions.

---

## 📂 Script Files

- `MobileDevice.pkg`  
  The framework update package from Apple. Reference Imprivata Article Number: 000021638 ([About MobileDevice](https://community.imprivata.com/s/article/About-MobileDevice)).

- `devicelist.txt`  
  A plain-text file with one hostname or IP per line.

- `mobiledevice_updater.sh`  
  The deployment script (this repo's main tool).

---

## 🚀 Usage

1. **Update Paths and Credentials**

   Edit the variables at the top of the script:

   ```bash
   PKG_PATH="/path/to/MobileDevice.pkg"
   HOSTS_FILE="/path/to/devicelist.txt"
   SSH_USER="your_local_admin"
   SSH_PASS="your_password"
   ```

2. **Run the Script**

   ```bash
   chmod +x mobiledevice_updater.sh
   ./mobiledevice_updater.sh
   ```

3. **Deployment Summary**

   After execution, the script will print a full summary:
   - ✅ Successful installs
   - ❌ Failed installs
   - ⚠️ Skipped/invalid hosts

---

## 🛠️ What It Does

- Validates input files and credentials
- Connects to each host using `sshpass`
- Transfers the `.pkg` file to each Mac’s `~/Downloads`
- Installs the `.pkg` silently with `sudo`
- Removes the `.pkg` from remote host after install
- Restarts the **GroundControl Launchpad** app

---

## 🔐 Security Notes

- All SSH communication is password-based using `sshpass`. Ensure you understand the risks of storing plaintext credentials in scripts.
- The script should be stored in a secure, access-controlled location — especially if credentials are embedded directly.
- For better security, it is recommended to integrate `sshpass` with the macOS Keychain or another secure credential store to retrieve passwords at runtime rather than hardcoding them.
- This tool is intended for **internal enterprise environments** with tightly controlled network access and auditing in place.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 🤝 Acknowledgments

Built and maintained by **Brian Irish** to support seamless management of Apple device frameworks in enterprise environments using Imprivata MAM and Workspace ONE.

---
