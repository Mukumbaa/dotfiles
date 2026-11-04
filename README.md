## Installation

### Prerequisites
Make sure `git` and `lua` are installed on your system:

```bash
sudo dnf install -y git lua
```

### Quick Start
Clone the repository to your home directory and launch the setup script:

```bash
cd ~
git clone https://github.com/Mukumbaa/dotfiles.git
cd dotfiles
lua setup.lua
```

---

### Profiles & Usage

By default, running `lua setup.lua` installs the **`full`** profile (Hyprland, Quickshell, dev tools, and desktop applications). You can select a lighter profile depending on your environment:

| Profile | Aliases | Description |
| :--- | :--- | :--- |
| **`minimal`** | `cli`, `headless`, `core`, `wsl` | Base CLI utilities & development stack (Rust, Go, Neovim) |
| **`desktop`** | `vm` | Minimal + GUI essentials (Alacritty, browsers, GNOME themes) |
| **`full`** | *(default)* | Complete suite with Hyprland, Quickshell, audio/display tools |

#### Preview Changes (Dry-Run / Summary)
You can inspect exactly which packages, repositories, and dotfile symlinks will be configured without touching your system:

```bash
# General help
lua setup.lua --help

# Preview actions for a specific profile
lua setup.lua minimal --help
lua setup.lua full --summary
```

#### Run with a Specific Profile
```bash
lua setup.lua minimal
lua setup.lua desktop
lua setup.lua full
```
