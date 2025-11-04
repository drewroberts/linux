# Arch Linux w/ Hyprland Setup

This repo includes my notes & details to configure new machines the way I like them. I'm trying not to create my own ISO & just use a script or manual edits for now..

## Omarchy

Omarchy gets me a solid foundation for what I want. I'm currently using the Osaka Jade theme but also can quickly switch based on mood.

- [Omarchy Website](https://omarchy.org)
- [Omarchy Docs](https://learn.omacom.io/2/the-omarchy-manual)
- [Omarchy GitHub](https://github.com/basecamp/omarchy)
- [Omarchy ISO GitHub](https://github.com/omacom-io/omarchy-iso)

## Install My Setup

After Omarchy ISO has been installed hit `SUPER ALT + SPACE` to launch Omarchy Menu and do the following:

- Install -> Development -> JavaScript -> Node
- Install -> Development -> PHP -> Laravel
- Install -> Development -> Go
- Install -> Editor -> VS Code

Afterwards, hit `SUPER + ENTER` to open defaul terminal of Alacritty & run these commands:

```bash
mkdir Code
cd Code
code .
```

Open the VS Code terminal to run the following:

```bash
git clone https://github.com/drewroberts/linux
```

This will have you sign in & verify GitHub for use on the machine not only in VS Code but in any terminal.

Afterwards, run the setup script in this repo with this command:

```bash
bash setup.sh
```

## Additional Apps

On all of my devices, I use the following:

### VS Code
- Easiest to install via menu

### Telegram
- Install from AUR via yay

## Web Apps

I find the following web apps helful. It is also good to just use keybindings to open the full browser to a specific page for others so I have the chromium navbar.

## Optional Apps

On my streaming devices, I use the following:

### GoXLR Linux

## Custom Keybindings

Files included in the /config directory to overwrite default Omarchy configs.

## Custom ASCII Art

Files included in the /ascii folder to replace the default omarchy ascii at in /.config/omarchy/branding on the linux computers.

To create new ascii art, use [this website](https://patorjk.com/software/taag/).
