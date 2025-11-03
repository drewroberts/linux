#!/bin/bash
# Omarchy/Hyprland System Bootstrapping Script
# Author: Gemini
# Goal: Idempotently install applications, deploy web apps, and symlink configurations
# from the current Git repository to the running Omarchy system.
# Prerequisites: Git and yay must be installed. The repository must be cloned to ~/Code/linux.

# --- 1. Environment & Setup Phase ---

# Define fixed repository path relative to the user's home directory (~/Code/linux)
REPO_PATH="$HOME/Code/linux"

# Define target directories using $HOME for portability
TARGET_ICON_DIR="$HOME/.local/share/icons"
TARGET_APP_DIR="$HOME/.local/share/applications"
OMARCHY_BRANDING_DIR="$HOME/.config/omarchy/branding"

# Function to safely create all required configuration directories
create_dirs() {
    echo "Ensuring target directories exist..."
    mkdir -p "$TARGET_ICON_DIR"
    mkdir -p "$TARGET_APP_DIR"
    mkdir -p "$HOME/.config/hypr"
    mkdir -p "$HOME/.config/waybar"
    mkdir -p "$HOME/.config/alacritty"
    mkdir -p "$OMARCHY_BRANDING_DIR"
    # Add any other required .config directories here (e.g., foot, sway, nvim)
}

# Function to create an idempotent symbolic link (ln -sf)
create_symlink() {
    local SOURCE=$1
    local TARGET=$2

    # Check if source file exists in the repo
    if [ ! -e "$SOURCE" ]; then
        echo "WARNING: Source file not found: $SOURCE"
        return 1
    fi

    # Handle case where the target is a directory (we link into it) vs. a file
    if [ -d "$TARGET" ] && [ ! -d "$SOURCE" ]; then
        TARGET="$TARGET/$(basename "$SOURCE")"
    fi

    # Create the symbolic link: -f (force/overwrite), -s (symbolic)
    ln -sf "$SOURCE" "$TARGET"
    echo "Linked: $(basename "$SOURCE") -> $TARGET"
}

# Run the directory creation
create_dirs

# Initial Confirmation and Safety Check
echo "--------------------------------------------------------"
echo "Starting Omarchy System Setup (Idempotent execution)."
echo "Repo Path: $REPO_PATH"
echo "--------------------------------------------------------"
read -r -p "Do you want to proceed with package installation and config deployment? (y/N): " response
if [[ "$response" != "y" && "$response" != "Y" ]]; then
    echo "Setup cancelled by user."
    exit 0
fi

# --- 2. System Package Management Phase ---

echo -e "\n--- Installing/Updating AUR and Repository Packages ---"

# 2.1 Install Packages from pkglist.txt
if [ -f "$REPO_PATH/pkglist.txt" ]; then
    echo "Installing packages listed in pkglist.txt..."
    # --needed prevents reinstallation; --noconfirm for automation
    yay -S --needed --noconfirm - < "$REPO_PATH/pkglist.txt"
else
    echo "WARNING: pkglist.txt not found at $REPO_PATH/pkglist.txt. Skipping package installation."
fi

# 2.2 Remove Packages (Optional)
if [ -f "$REPO_PATH/rmlist.txt" ]; then
    echo "Removing packages listed in rmlist.txt..."
    yay -Rns --noconfirm - < "$REPO_PATH/rmlist.txt"
fi


# --- 3. Web Application Deployment Phase ---

echo -e "\n--- Deploying Custom Web Applications and Icons ---"

# 3.1 Remove Unwanted Web App Desktop Files (using rm-webapps.txt)
if [ -f "$REPO_PATH/rm-webapps.txt" ]; then
    echo "Removing unwanted web application desktop files..."
    while IFS= read -r DESKTOP_FILE; do
        if [ ! -z "$DESKTOP_FILE" ] && [ "${DESKTOP_FILE:0:1}" != "#" ]; then
            TARGET_FILE="$TARGET_APP_DIR/$DESKTOP_FILE"
            if [ -f "$TARGET_FILE" ]; then
                rm -f "$TARGET_FILE"
                echo "Removed: $DESKTOP_FILE"
            fi
        fi
    done < "$REPO_PATH/rm-webapps.txt"
fi

# 3.2 Deploy Icons
if [ -d "$REPO_PATH/icons" ]; then
    echo "Copying icons to $TARGET_ICON_DIR..."
    # -f ensures overwrite if file exists
    cp -f "$REPO_PATH/icons"/* "$TARGET_ICON_DIR"
else
    echo "WARNING: icons directory not found. Skipping icon deployment."
fi

# 3.3 Deploy .desktop Files
if [ -d "$REPO_PATH/webapps" ]; then
    echo "Copying .desktop files to $TARGET_APP_DIR..."
    cp -f "$REPO_PATH/webapps"/*.desktop "$TARGET_APP_DIR"

    # 3.4 Ensure Executability
    chmod +x "$TARGET_APP_DIR"/*.desktop
else
    echo "WARNING: webapps directory not found. Skipping web app deployment."
fi

# --- 4. Configuration Deployment Phase (Dotfiles) ---

echo -e "\n--- Creating Symbolic Links for Configurations ---"

# 4.1 Deploy Hyprland
create_symlink "$REPO_PATH/config/hypr/hyprland.conf" "$HOME/.config/hypr/hyprland.conf"

# 4.2 Deploy Waybar
create_symlink "$REPO_PATH/config/waybar/config" "$HOME/.config/waybar/config"
create_symlink "$REPO_PATH/config/waybar/style.css" "$HOME/.config/waybar/style.css"

# 4.3 Deploy Alacritty
create_symlink "$REPO_PATH/config/alacritty/alacritty.yml" "$HOME/.config/alacritty/alacritty.yml"

# 4.4 Deploy Omarchy ASCII Branding
# Target: ~/.config/omarchy/branding/
if [ -d "$REPO_PATH/ascii" ]; then
    create_symlink "$REPO_PATH/ascii/about.txt" "$OMARCHY_BRANDING_DIR/about.txt"
    create_symlink "$REPO_PATH/ascii/screensaver.txt" "$OMARCHY_BRANDING_DIR/screensaver.txt"
else
    echo "WARNING: ascii directory not found. Skipping ASCII deployment."
fi

# Add more symlinks for other configs here (e.g., foot, sway, nvim)

# --- 5. Completion ---

echo -e "\n--------------------------------------------------------"
echo "✨ SETUP COMPLETE! ✨"
echo "To ensure all new configurations (especially Hyprland) and"
echo "applications are loaded, please logout and log back in (or reboot)."
echo "--------------------------------------------------------"
