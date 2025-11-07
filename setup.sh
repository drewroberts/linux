#!/bin/bash
# Omarchy/Hyprland System Bootstrapping Script

# Goal: Idempotently install applications, deploy web apps, and copy configurations
# from the current Git repository to the running Omarchy system.
# Prerequisites: Git and yay must be installed. The repository must be cloned to ~/Code/linux.

# --- 1. Environment & Setup Phase ---

# Define fixed repository path relative to the user's home directory (~/Code/linux)
REPO_PATH="$HOME/Code/linux"

# Define target directories using $HOME for portability
TARGET_ICON_DIR="$HOME/.local/share/applications/icons"
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

# Function to copy files from the repo to the target location, backing up any existing targets
create_copy() {
    local SOURCE=$1
    local TARGET=$2

    # If target exists and is identical, skip
    if [ -e "$TARGET" ]; then
        if command -v cmp >/dev/null 2>&1 && cmp -s "$SOURCE" "$TARGET"; then
            echo "Unchanged: $(basename "$SOURCE") already at $TARGET"
            return 0
        fi
        # Overwrite existing target (no backup as requested)
        cp -a "$SOURCE" "$TARGET"
        echo "Overwrote: $(basename "$SOURCE") -> $TARGET"
        return 0
    fi

    cp -a "$SOURCE" "$TARGET"
    echo "Copied: $(basename "$SOURCE") -> $TARGET"
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

# 2.1 Install Packages from pkglist.txt (assume file exists)
echo "Installing packages listed in pkglist.txt..."
# --needed prevents reinstallation; --noconfirm for automation
yay -S --needed --noconfirm - < "$REPO_PATH/pkglist.txt"

# 2.2 Remove Packages (Optional)
echo "Removing packages listed in rm-applications.txt..."
yay -Rns --noconfirm - < "$REPO_PATH/rm-applications.txt"


# --- 3. Web Application Deployment Phase ---

echo -e "\n--- Deploying Custom Web Applications and Icons ---"

# 3.1 Remove Unwanted Web App Desktop Files (using rm-webapps.txt)
echo "Removing unwanted web application desktop files..."
while IFS= read -r DESKTOP_FILE; do
    case "$DESKTOP_FILE" in
        ""|"#"*) continue ;;
    esac
    TARGET_FILE="$TARGET_APP_DIR/$DESKTOP_FILE"
    rm -f "$TARGET_FILE" && echo "Removed: $DESKTOP_FILE"
done < "$REPO_PATH/rm-webapps.txt"

# 3.2 Deploy Icons
echo "Copying icons to $TARGET_ICON_DIR..."
cp -f "$REPO_PATH/webapps/icons"/* "$TARGET_ICON_DIR/"

# 3.3 Deploy .desktop Files
echo "Copying .desktop files to $TARGET_APP_DIR..."
for desktop_file in "$REPO_PATH/webapps"/*.desktop; do
    filename=$(basename "$desktop_file")
    sed "s|\$HOME|$HOME|g" "$desktop_file" > "$TARGET_APP_DIR/$filename"
    echo "Processed: $filename (expanded \$HOME variables)"
done

# 3.4 Ensure Executability
chmod +x "$TARGET_APP_DIR"/*.desktop

# --- 4. Configuration Deployment Phase (Dotfiles) ---

echo -e "\n--- Copying configuration files ---"

# 4.1 Deploy Custom Hyprland Configs (copy and overwrite with backups)
create_copy "$REPO_PATH/config/hypr/autostart.conf" "$HOME/.config/hypr/autostart.conf"
create_copy "$REPO_PATH/config/hypr/bindings.conf" "$HOME/.config/hypr/bindings.conf"
create_copy "$REPO_PATH/config/hypr/hypridle.conf" "$HOME/.config/hypr/hypridle.conf"

# Deploy Custom ASCII Branding
# Target: ~/.config/omarchy/branding/
create_copy "$REPO_PATH/ascii/about.txt" "$OMARCHY_BRANDING_DIR/about.txt"
create_copy "$REPO_PATH/ascii/screensaver.txt" "$OMARCHY_BRANDING_DIR/screensaver.txt"

# --- 5. Completion ---

echo -e "\n--------------------------------------------------------"
echo "✨ SETUP COMPLETE! ✨"
echo "To ensure all new configurations (especially Hyprland) and"
echo "applications are loaded, please restart the machine."
echo "--------------------------------------------------------"
