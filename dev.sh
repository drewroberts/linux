#!/bin/bash
# Development Environment Bootstrapping Script

# Goal: Idempotently install development-specific applications on top of a
# baseline Omarchy system configured by the main setup.sh script.
# Prerequisites: The main setup.sh script must have been run successfully.

# --- 1. Environment & Setup Phase ---

# Define fixed repository path relative to the user's home directory (~/Code/linux)
REPO_PATH="$HOME/Code/linux"

# Define target directories using $HOME for portability
DEVSQL_DIR="$HOME/Containers/devsql"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"

# Function to safely create all required directories
create_dirs() {
    echo "Ensuring target directories exist..."
    mkdir -p "$DEVSQL_DIR"
    mkdir -p "$SYSTEMD_USER_DIR"
    mkdir -p "$HOME/.config/hypr"
}

# Function to copy files from the repo to the target location, overwriting if changed
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

# Check if a key package from setup.sh is installed.
# We use beekeeper-studio-bin as an indicator that setup.sh has been run.
if ! yay -Q "beekeeper-studio-bin" >/dev/null 2>&1; then
    echo "--------------------------------------------------------"
    echo "ERROR: Prerequisite 'beekeeper-studio-bin' not found."
    echo "Please run the main setup.sh script first before running this script."
    echo "--------------------------------------------------------"
    exit 1
fi

# Initial Confirmation and Safety Check
echo "--------------------------------------------------------"
echo "Setting Up Development Environment"
echo "Repo Path: $REPO_PATH"
echo "--------------------------------------------------------"
read -r -p "Do you want to proceed with development package installation? (y/N): " response
if [[ "$response" != "y" && "$response" != "Y" ]]; then
    echo "Setup cancelled by user."
    exit 0
fi

# --- 2. System Package Management Phase ---

# Install Packages from dev/pkglist.txt
echo -e "\n--- Installing/Updating Development Packages ---"
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
    
    if [ $YAY_EXIT_CODE -eq 0 ]; then
        VERSION=$(yay -Q "$PACKAGE" 2>/dev/null | cut -d' ' -f2)
        echo "Installed: $PACKAGE - $VERSION"
    else
        echo "Failed to install: $PACKAGE"
        echo "$YAY_OUTPUT"
        echo "---"
    fi
done < "$REPO_PATH/dev/pkglist.txt"

# --- 3. Development SQL Container Setup ---

echo -e "\n--- Setting Up Development SQL Container ---"

# Define source and target paths
COMPOSE_SOURCE="$REPO_PATH/dev/devsql/podman-compose.yml"
COMPOSE_DEST="$DEVSQL_DIR/podman-compose.yml"
SERVICE_FILE="$SYSTEMD_USER_DIR/container-devsql.service"
OLD_SERVICE_FILE="$SYSTEMD_USER_DIR/container-global_mysql_server.service"

# 3.1 Clean up old service if it exists
if [ -f "$OLD_SERVICE_FILE" ]; then
    echo "Removing old MySQL service..."
    systemctl --user disable container-global_mysql_server.service 2>/dev/null || true
    systemctl --user stop container-global_mysql_server.service 2>/dev/null || true
    rm -f "$OLD_SERVICE_FILE"
    echo "Removed: container-global_mysql_server.service"
fi

# 3.2 Deploy podman-compose.yml
COMPOSE_CHANGED=false
if [ ! -f "$COMPOSE_DEST" ] || ! cmp -s "$COMPOSE_SOURCE" "$COMPOSE_DEST"; then
    create_copy "$COMPOSE_SOURCE" "$COMPOSE_DEST"
    COMPOSE_CHANGED=true
fi

# 3.3 Start the container with podman-compose
echo "Starting devsql container..."
(cd "$DEVSQL_DIR" && podman-compose up -d)

# 3.4 Generate systemd service file
if [ ! -f "$SERVICE_FILE" ] || [ "$COMPOSE_CHANGED" = true ]; then
    echo "Generating systemd service file..."
    (cd "$DEVSQL_DIR" && podman generate systemd --name devsql --files --new)
    if [ -f "$DEVSQL_DIR/container-devsql.service" ]; then
        mv "$DEVSQL_DIR/container-devsql.service" "$SERVICE_FILE"
        echo "Generated: container-devsql.service"
    fi
else
    echo "Skipped: systemd service file (already exists)"
fi

# 3.5 Enable the systemd service
systemctl --user daemon-reload
systemctl --user enable container-devsql.service 2>/dev/null
echo "Enabled: container-devsql.service"


# --- 4. Configuration Deployment Phase (Dotfiles) ---

echo -e "\n--- Updating Configuration Files ---"

# 4.1 Deploy Custom Hyprland Autostart Config
create_copy "$REPO_PATH/dev/config/hypr/autostart.conf" "$HOME/.config/hypr/autostart.conf"

# --- 5. Completion ---

echo -e "\n--------------------------------------------------------"
echo "✨ DEVELOPMENT SETUP COMPLETE! ✨"
echo "All development tools and packages are installed."
echo "--------------------------------------------------------"