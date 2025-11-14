#!/bin/bash
# Development Environment Bootstrapping Script

# Goal: Idempotently install development-specific applications on top of a
# baseline Omarchy system configured by the main setup.sh script.
# Prerequisites: The main setup.sh script must have been run successfully.

# --- 1. Prerequisite & Environment Check ---

# Define fixed repository path relative to the user's home directory (~/Code/linux)
REPO_PATH="$HOME/Code/linux"

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

# --- 3. Completion ---

echo -e "\n--------------------------------------------------------"
echo "✨ DEVELOPMENT SETUP COMPLETE! ✨"
echo "All development tools and packages are installed."
echo "--------------------------------------------------------"