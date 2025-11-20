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

# Configure keyd so Caps Lock taps send Escape and holds send Control
configure_keyd() {
    echo -e "\n--- Configuring keyd for Caps Lock remap ---"

    if ! command -v keyd >/dev/null 2>&1; then
        echo "keyd not found. Attempting installation via yay..."
        if ! yay -S --needed --noconfirm keyd; then
            echo "WARNING: Failed to install keyd. Skipping remap configuration."
            return
        fi
    fi

    sudo mkdir -p /etc/keyd

    local KEYD_TEMP
    KEYD_TEMP=$(mktemp)
    cat <<'EOF' > "$KEYD_TEMP"
[ids]
*

[main]
# Maps capslock to escape when pressed and control when held.
capslock = overload(control, esc)
EOF

    if sudo test -f /etc/keyd/default.conf && sudo cmp -s "$KEYD_TEMP" /etc/keyd/default.conf; then
        echo "Skipped: /etc/keyd/default.conf (already configured)"
    else
        sudo cp "$KEYD_TEMP" /etc/keyd/default.conf
        echo "Configured: /etc/keyd/default.conf"
    fi
    rm -f "$KEYD_TEMP"

    if sudo systemctl enable keyd >/dev/null 2>&1; then
        echo "Enabled: keyd service"
    else
        echo "WARNING: Failed to enable keyd service"
    fi

    if sudo systemctl start keyd >/dev/null 2>&1; then
        echo "Started: keyd service"
    else
        echo "WARNING: Failed to start keyd service"
    fi
}

# Run the directory creation
create_dirs

# Initial Confirmation and Safety Check
echo "--------------------------------------------------------"
echo "Customizing Omarchy Arch Linux Setup"
echo "Repo Path: $REPO_PATH"
echo "--------------------------------------------------------"
read -r -p "Do you want to proceed with package installation and config deployment? (y/N): " response
if [[ "$response" != "y" && "$response" != "Y" ]]; then
    echo "Setup cancelled by user."
    exit 0
fi

# --- 2. System Package Management Phase ---

# 2.1 Install Packages from pkglist.txt
echo -e "\n--- Installing/Updating AUR & Arch Linux Packages ---"
echo "Installing applications..."
while IFS= read -r PACKAGE; do
    case "$PACKAGE" in
        ""|"#"*) continue ;;
    esac
    
    # Check if package is already installed
    WAS_INSTALLED=false
    if yay -Q "$PACKAGE" >/dev/null 2>&1; then
        WAS_INSTALLED=true
    fi
    
    # For already installed packages, check quietly first if they're up to date
    if [ "$WAS_INSTALLED" = true ]; then
        QUIET_CHECK=$(yay -S --needed --noconfirm "$PACKAGE" 2>&1)
        if echo "$QUIET_CHECK" | grep -qi "up to date.*skipping\|nothing to do\|there is nothing to do"; then
            VERSION=$(yay -Q "$PACKAGE" 2>/dev/null | cut -d' ' -f2)
            echo "Skipped: $PACKAGE (already updated) - $VERSION"
            continue
        fi
    fi
    
    # Run yay with real-time output for packages that need installation/update
    TEMP_OUTPUT=$(mktemp)
    echo "Installing $PACKAGE..."
    yay -S --needed --noconfirm "$PACKAGE" 2>&1 | tee "$TEMP_OUTPUT"
    YAY_EXIT_CODE=${PIPESTATUS[0]}
    rm -f "$TEMP_OUTPUT"
    
    if [ "$YAY_EXIT_CODE" -eq 0 ]; then
        VERSION=$(yay -Q "$PACKAGE" 2>/dev/null | cut -d' ' -f2)
        echo "Installed: $PACKAGE - $VERSION"
    else
        echo "Failed to install: $PACKAGE"
        echo "---"
    fi
done < "$REPO_PATH/setup/pkglist.txt"

# 2.2 Remove Packages (using rm-applications.txt)
echo -e "\n--- Removing Unwanted Applications ---"
while IFS= read -r PACKAGE; do
    case "$PACKAGE" in
        ""|"#"*) continue ;;
    esac
    if yay -Rns --noconfirm "$PACKAGE" 2>/dev/null; then
        echo "Removed: $PACKAGE"
    else
        echo "Skipped: $PACKAGE (not installed)"
    fi
done < "$REPO_PATH/setup/rm-applications.txt"


# --- 2.3 Keyboard Remapping (Caps Lock overload) ---

configure_keyd


# --- 3. Web Application Deployment Phase ---

echo -e "\n--- Updating Custom Web Apps ---"

# 3.1 Remove Unwanted Web App Desktop Files (using rm-webapps.txt)
echo "Removing unwanted omarchy web apps..."
while IFS= read -r DESKTOP_FILE; do
    case "$DESKTOP_FILE" in
        ""|"#"*) continue ;;
    esac
    TARGET_FILE="$TARGET_APP_DIR/$DESKTOP_FILE"
    if [ -f "$TARGET_FILE" ]; then
        rm -f "$TARGET_FILE" && echo "Removed: $DESKTOP_FILE"
    else
        echo "Skipped: $DESKTOP_FILE (not installed)"
    fi
done < "$REPO_PATH/setup/rm-webapps.txt"

# 3.2 Deploy Icons
echo "Copying icons to $TARGET_ICON_DIR..."
cp -f "$REPO_PATH/webapps/icons"/* "$TARGET_ICON_DIR/"

# 3.3 Deploy .desktop Files
echo "Installing web apps to $TARGET_APP_DIR..."
for desktop_file in "$REPO_PATH/webapps"/*.desktop; do
    filename=$(basename "$desktop_file")
    TARGET_DESKTOP="$TARGET_APP_DIR/$filename"
    
    # Create temporary file with expanded variables
    TEMP_FILE=$(mktemp)
    sed "s|\$HOME|$HOME|g" "$desktop_file" > "$TEMP_FILE"
    
    # Check if target exists and is identical
    if [ -f "$TARGET_DESKTOP" ] && command -v cmp >/dev/null 2>&1 && cmp -s "$TEMP_FILE" "$TARGET_DESKTOP"; then
        echo "Skipped: $filename (already installed)"
        rm -f "$TEMP_FILE"
    else
        mv "$TEMP_FILE" "$TARGET_DESKTOP"
        echo "Installed: $filename"
    fi
done

# 3.4 Ensure Executability
chmod +x "$TARGET_APP_DIR"/*.desktop

# --- 4. Configuration Deployment Phase (Dotfiles) ---

echo -e "\n--- Updating configuration files ---"

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
