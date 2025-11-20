# Arch Linux w/ Hyprland Setup

This repo includes my notes & details to configure new machines the way I like them. I'm trying not to create my own ISO & just use a script or manual edits for now..

## Omarchy

Omarchy gets me a solid foundation for what I want on top of Arch Linux with Hyprland. I'm currently using the Osaka Jade theme but also can quickly switch based on mood.

- [Omarchy Website](https://omarchy.org)
- [Omarchy Docs](https://learn.omacom.io/2/the-omarchy-manual)
- [Omarchy GitHub](https://github.com/basecamp/omarchy)
- [Omarchy ISO GitHub](https://github.com/omacom-io/omarchy-iso)

## Install My Setup

After the Omarchy ISO has been installed, open a terminal (`SUPER + ENTER`) and run the following commands to clone the repository to the opinionated /Code directory for all projects:

```bash
git clone https://github.com/drewroberts/linux ~/Code/linux
```

After the repo has been installed, run the setup script:

```bash
cd ~/Code/linux
bash setup.sh
```

This will install all base applications, including Visual Studio Code, and apply system configurations.

## Development Environment Setup

If you are setting up a development machine, run the `dev.sh` script **after** the main `setup.sh` script has completed. This will install all necessary development tools and languages.

From the `~/Code/linux` directory, run:

```bash
bash dev.sh
```

## Additional Apps

On all of my devices, I use the following:

### VS Code
- Install from AUR via yay or Omarchy menu

### Telegram
- Install from AUR via yay

## Web Apps

I find the following web apps helful. It is also good to just use keybindings to open the full browser to a specific page for others so I have the chromium navbar.

## Optional Apps

On my streaming devices, I use the following:

### GoXLR Linux

## Custom Keybindings

Files included in the /config directory to overwrite default Omarchy configs.

## Caps Lock Remap (Esc on Tap, Ctrl on Hold)

Running `setup.sh` now installs and configures [`keyd`](https://github.com/rvaiya/keyd) so Caps Lock behaves like the classic Vim-friendly overload: tapping sends `Esc`, while holding turns it into `Ctrl`. The remap is applied at the system level, so it works in Hyprland, terminals, TTYs, and GUI apps instantly. The script also enables the `keyd` service so the behavior persists across reboots.

VS Code sometimes ignores low-level remaps unless it listens to raw key codes. Add these entries to your `settings.json` to make sure the new Caps behavior is respected:

```json
{
	"keyboard.dispatch": "keyCode",
	"window.titleBarStyle": "custom"
}-----
```

After `keyd` is running and these settings saved, try this flow to verify:

1.  Open VS Code.
2.  **Tap CapsLock:** It should clear your selection or close a popup (Escape behavior).
3.  **Hold CapsLock + P:** It should open the File Search (Control behavior).


## Custom ASCII Art

Files included in the /ascii folder to replace the default omarchy ascii at in /.config/omarchy/branding on the linux computers.

To create new ascii art, use [this website](https://patorjk.com/software/taag/).
