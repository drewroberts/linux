# Omarchy Modification Plan

## Overview

### **Goal**

Create a portable, idempotent Bash script (`setup.sh`) to synchronize application installations, web application desktop entries, and configuration files (dotfiles) from this Git repository to an Arch/Hyprland system running Omarchy. The script is designed to be runnable **multiple times** without error, ensuring the target system always reflects the state of the repository.

### **Pre-Requisite**

* The system must have **Omarchy** installed.
* The script assumes the repository is cloned to the specific path: **`$HOME/Code/linux`**.
* **`yay`** (or another AUR helper) is assumed to be installed and available for package management.

### **Repository Structure**

| Path | Purpose | Type |
| :--- | :--- | :--- |
| `setup.sh` | The main execution script. | File |
| `pkglist.txt` | List of packages for `yay -S`. | File |
| `rmlist.txt` | *(Optional)* List of packages to remove via `yay -Rns`. | File |
| **`rm-webapps.txt`** | **List of specific `.desktop` filenames (e.g., `Slack-omarchy.desktop`) to be removed from `$HOME/.local/share/applications/`.** | **File** |
| `webapps/` | Directory containing custom portable `.desktop` files. | Directory |
| `icons/` | Directory containing web app icon image files (e.g., `.png`, `.svg`). | Directory |
| `configs/` | Directory containing application configurations (dotfiles). | Directory |

---

## 1. Environment & Setup Phase ⚙️

| Step | Action | Command/Logic | Rationale |
| :--- | :--- | :--- | :--- |
| **1.1** | Define Repository Path | `REPO_PATH="$HOME/Code/linux"` | Ensures portability by referencing the path relative to **`$HOME`**. |
| **1.2** | Define Target Directories | `TARGET_ICON_DIR="$HOME/.local/share/icons/"`<br>`TARGET_APP_DIR="$HOME/.local/share/applications/"` | Uses standard Freedesktop paths for local user files. |
| **1.3** | Create Target Directories | `mkdir -p` commands for all target paths (`.local/share/`, `.config/hypr`, etc.). | **Idempotent:** Ensures necessary paths exist before deployment. |
| **1.4** | Symlink Function | Define the `create_symlink` function using `ln -sf SOURCE TARGET`. | Centralized logic for idempotent, forced symbolic link creation, essential for updates. |

---

## 2. System Package Management Phase 📦

This phase uses `yay` to ensure the package list is synchronized.

| Step | Action | Command/Logic | Rationale |
| :--- | :--- | :--- | :--- |
| **2.1** | Install Packages | `yay -S --needed --noconfirm - < pkglist.txt` | `--needed` ensures fast execution by only installing what's missing. |
| **2.2** | Remove Packages | `yay -Rns --noconfirm - < rmlist.txt` (if `rmlist.txt` exists) | Cleanly uninstalls unwanted packages. |

---

## 3. Web Application Deployment Phase 🌐

This phase manages custom web application icons and `.desktop` entries, and safely removes unwanted existing web app entries.

| Step | Action | Command/Logic | Rationale |
| :--- | :--- | :--- | :--- |
| **3.1** | **Remove Unwanted Apps** | **Read `rm-webapps.txt` and use a loop to safely remove each listed `.desktop` file from `$TARGET_APP_DIR`.** | **Safe, non-aggressive removal of specific web app launchers.** |
| **3.2** | Deploy Icons | `cp -f $REPO_PATH/icons/* "$TARGET_ICON_DIR"` | Copies custom icons to a discoverable location. |
| **3.3** | Deploy `.desktop` Files | `cp -f $REPO_PATH/webapps/*.desktop "$TARGET_APP_DIR"` | Puts the launchers where the desktop environment looks for them. |
| **3.4** | Set Executability | `chmod +x "$TARGET_APP_DIR"/*.desktop` | Required by the desktop environment to treat them as launchers. |

> **Requirement Check:** All deployed `.desktop` files **must** use the **`$HOME`** variable in the `Icon=` field for portability (e.g., `Icon=$HOME/.local/share/icons/GitHub.png`).

---

## 4. Configuration Deployment Phase (Dotfiles) 🔗

This is the core synchronization step, utilizing symbolic links for maintainability. 

| Step | Action | Target Location | Command Example |
| :--- | :--- | :--- | :--- |
| **4.1** | Hyprland Config | `~/.config/hypr/hyprland.conf` | `create_symlink ...hyprland.conf` |
| **4.2** | Waybar Configs | `~/.config/waybar/config` & `style.css` | `create_symlink ...waybar/config` |
| **4.3** | Alacritty Config | `~/.config/alacritty/alacritty.yml` | `create_symlink ...alacritty.yml` |
| **4.4** | Other Dotfiles | Repeat for all managed configs (e.g., `foot`, `nvim`, `tmux`). | Use the `create_symlink` function for every file. |

---

## 5. Completion ✨

The script concludes with a notification that the process is complete and advises the user to **logout and log back in (or reboot)** to ensure the Hyprland session picks up all new configurations and installed applications.