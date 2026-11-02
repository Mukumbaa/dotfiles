local home = os.getenv("HOME")
if not home then error("Environment variable $HOME was not found.") end

-- general position of dotfiles
local dotfiles_dir = home .. "/dotfiles"

local colors = {
  blue   = "\27[34m", green = "\27[32m",
  yellow = "\27[33m", red   = "\27[31m",
  reset  = "\27[0m",  bold  = "\27[1m"
}

local function print_step(msg)
  print("\n" .. colors.bold .. colors.blue .. "==> " .. colors.reset .. colors.bold .. msg .. colors.reset)
end
local function print_info(msg) print("  " .. colors.green .. "-> " .. colors.reset .. msg) end
local function print_warn(msg) print("  " .. colors.yellow .. "!! " .. colors.reset .. msg) end

local function run(cmd, can_fail)
  local success = os.execute(cmd)
  if not success and not can_fail then
    io.stderr:write(colors.red .. "Command execution failed: " .. cmd .. colors.reset .. "\n")
  end
  return success
end

-- profiles configuration
local profile_tags = {
  ["cli"]  = { base = true, dev = true },
  ["wsl"]  = { base = true, dev = true, wsl = true },
  ["vm"]   = { base = true, dev = true, gui_base = true },
  ["full"] = { base = true, dev = true, gui_base = true, hyprland = true }
}

-- default fallbak
local selected_profile = "full"
if arg and #arg > 0 then
  for _, a in ipairs(arg) do
    local flag_profile = a:match("^%-%-profile=(.+)$")
    if flag_profile then
      selected_profile = flag_profile:lower()
      break
    elseif not a:match("^%-") then
      selected_profile = a:lower()
      break
    end
  end
end

local active_tags = profile_tags[selected_profile]
if not active_tags then
  local valid_list = table.concat({"cli", "wsl", "vm", "full"}, ", ")
  error("Invalid profile: '" .. tostring(selected_profile) .. "'. Supported profiles are: " .. valid_list)
end

local function has_tag(item_tag)
  return active_tags[item_tag] == true
end


local all_dnf_packages = {
  -- Base / CLI
  { name = "stow",                  tag = "base" },
  { name = "btop",                  tag = "base" },
  { name = "fastfetch",             tag = "base" },
  { name = "lsd",                   tag = "base" },
  { name = "fd-find",               tag = "base" },
  { name = "bat",                   tag = "base" },
  { name = "trash-cli",             tag = "base" },
  { name = "binwalk",               tag = "base" },
  { name = "squashfs-tools",        tag = "base" },
  { name = "gh",                    tag = "base" },
  { name = "helix",                 tag = "base" },
  { name = "nvim",                  tag = "base" },
  -- Dev tools
  { name = "pipx",                  tag = "dev" },
  { name = "gcc",                   tag = "dev" },
  { name = "clangd",                tag = "dev" },
  { name = "golang",                tag = "dev" },
  { name = "rustup",                tag = "dev" },
  { name = "dbus-devel",            tag = "dev" },
  { name = "pkgconf-pkg-config",    tag = "dev" },
  -- GUI Base 
  { name = "alacritty",             tag = "gui_base" },
  { name = "kitty",                 tag = "gui_base" },
  { name = "google-chrome-stable",  tag = "gui_base" },
  { name = "brave-browser-nightly", tag = "gui_base" },
  { name = "gnome-tweaks",          tag = "gui_base" },
  { name = "gnome-themes-extra",    tag = "gui_base" },
  { name = "adw-gtk3-theme",        tag = "gui_base" },
  { name = "qalculate",             tag = "gui_base" },
  -- Hyprland / Physical desktop utilities
  { name = "hyprland",              tag = "hyprland" },
  { name = "hyprpaper",             tag = "hyprland" },
  { name = "hyprlock",              tag = "hyprland" },
  { name = "hyprland-guiutils",     tag = "hyprland" },
  { name = "wlogout",               tag = "hyprland" },
  { name = "waybar",                tag = "hyprland" },
  { name = "wiremix",               tag = "hyprland" },
  { name = "blueman",               tag = "hyprland" },
  { name = "NetworkManager-tui",    tag = "hyprland" },
  { name = "grim",                  tag = "hyprland" },
  { name = "slurp",                 tag = "hyprland" },
  { name = "wl-clipboard",          tag = "hyprland" },
}

local external_rpms = {
  { url = "https://github.com/Mukumbaa/Hyprland-RPM/raw/refs/heads/main/caskaydia-mono-nerd-fonts-3.3.0-1.202609232024_base.fc44.noarch.rpm", tag = "base" },
  { url = "https://github.com/Mukumbaa/Hyprland-RPM/raw/refs/heads/main/starship-1.26.0-1.202609242001_base.fc44.x86_64.rpm",                 tag = "base" },
  { url = "https://github.com/Mukumbaa/Hyprland-RPM/raw/refs/heads/main/yazi-26.9.1-1.202609241239_base.fc44.x86_64.rpm",                     tag = "base" },
  { url = "https://github.com/Mukumbaa/Hyprland-RPM/raw/refs/heads/main/superfile-1.6.0.rc1-1.202609251516_base.fc44.x86_64.rpm",             tag = "base" },
  { url = "https://github.com/Mukumbaa/Hyprland-RPM/raw/refs/heads/main/quickshell-0.3.1-1.202609251512_base.fc44.x86_64.rpm",                tag = "hyprland" },
}

local stow_configs = {
  { pkg = "bashrc",      target = home .. "/.bashrc",               tag = "base" },
  { pkg = "bash-config", target = home .. "/.config/bash-config",   tag = "base" },
  { pkg = "starship",    target = home .. "/.config/starship.toml", tag = "base" },
  { pkg = "fastfetch",   target = home .. "/.config/fastfetch",     tag = "base" },
  { pkg = "btop",        target = home .. "/.config/btop",          tag = "base" },
  { pkg = "helix",       target = home .. "/.config/helix",         tag = "base" },
  { pkg = "nvim",        target = home .. "/.config/nvim",          tag = "base" },
  { pkg = "scripts",     target = home .. "/.config/scripts",       tag = "base" },
  { pkg = "algo",        target = home .. "/.config/algo",          tag = "base" },
  { pkg = "yazi",        target = home .. "/.config/yazi",          tag = "base" },
  { pkg = "superfile",   target = home .. "/.config/superfile",     tag = "base" },

  { pkg = "alacritty",   target = home .. "/.config/alacritty",     tag = "gui_base" },
  { pkg = "kitty",       target = home .. "/.config/kitty",         tag = "gui_base" },

  { pkg = "hypr",        target = home .. "/.config/hypr",          tag = "hyprland" },
  { pkg = "waybar",      target = home .. "/.config/waybar",        tag = "hyprland" },
  { pkg = "wlogout",     target = home .. "/.config/wlogout",       tag = "hyprland" },
  { pkg = "kanshi",      target = home .. "/.config/kanshi",        tag = "hyprland" },
  { pkg = "quickshell",  target = home .. "/.config/quickshell",    tag = "hyprland" },
}

local go_packages = {
  "golang.org/x/tools/gopls@latest",
  "github.com/nametake/golangci-lint-langserver@latest",
  "github.com/golangci/golangci-lint/cmd/golangci-lint@latest",
  "golang.org/x/tools/cmd/goimports@latest",
  "github.com/go-delve/delve/cmd/dlv@latest"
}


print_step("Starting System Setup (Selected Profile: " .. selected_profile:upper() .. ")")

if has_tag("gui_base") or has_tag("hyprland") then
  print_step("Removing Bloatware (LibreOffice)")
  run("sudo dnf group remove -y libreoffice 2>/dev/null", true)
  run("sudo dnf remove -y 'libreoffice*' 2>/dev/null", true)
end

if has_tag("hyprland") then
  print_step("Enabling Hyprland COPR Repository")
  run("sudo dnf install -y dnf-plugins-core")
  run("sudo dnf copr enable -y lionheartp/Hyprland")
end

if has_tag("gui_base") then
  print_step("Enabling Brave Browser Nightly Repository")
  run("sudo dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-nightly.s3.brave.com/brave-browser-nightly.repo --overwrite", true)
end

local filtered_dnf = {}
for _, item in ipairs(all_dnf_packages) do
  if has_tag(item.tag) then
    table.insert(filtered_dnf, item.name)
  end
end

if #filtered_dnf > 0 then
  print_step(string.format("Installing DNF Packages (%d selected)", #filtered_dnf))
  run(string.format("sudo dnf install -y --skip-unavailable %s", table.concat(filtered_dnf, " ")))
end

local filtered_rpms = {}
for _, item in ipairs(external_rpms) do
  if has_tag(item.tag) then
    table.insert(filtered_rpms, item.url)
  end
end

if #filtered_rpms > 0 then
  print_step(string.format("Installing External RPMs (%d selected)", #filtered_rpms))
  run(string.format("sudo dnf install -y --skip-unavailable %s", table.concat(filtered_rpms, " ")))
end

if has_tag("dev") then
  print_step("Setting Up Development Environments")

  print_info("Ensuring pipx binary path")
  run("pipx ensurepath")

  print_info("Configuring Rustup and Cargo tools")
  run("rustup-init -y")
  local cargo_bin = home .. "/.cargo/bin/cargo"
  if run(string.format('[ -x "%s" ]', cargo_bin), true) then
    run(cargo_bin .. " install --git https://github.com/Myriad-Dreamin/tinymist --locked tinymist-cli")
  else
    print_warn("Cargo binary not found in ~/.cargo/bin. Skipping tinymist installation.")
  end

  print_info("Installing Go tools and language servers")
  local go_env = "export PATH=$PATH:" .. home .. "/go/bin; "
  for _, pkg in ipairs(go_packages) do
    run(go_env .. "go install " .. pkg)
  end
end

print_step("Deploying Dotfiles (Safe GNU Stow)")

local backup_dir = home .. "/.config/dotfiles_backup_" .. os.date("%Y%m%d_%H%M%S")
local backup_created = false

for _, conf in ipairs(stow_configs) do
  if has_tag(conf.tag) then
    local target = conf.target
    local pkg = conf.pkg

    local check_cmd = string.format('[ -e "%s" ] && [ ! -L "%s" ]', target, target)
    if run(check_cmd, true) then
      if not backup_created then
        run(string.format('mkdir -p "%s"', backup_dir))
        print_info("Created backup directory at: " .. backup_dir)
        backup_created = true
      end

      local rel_path = target:gsub("^" .. home .. "/", "")
      local dest = backup_dir .. "/" .. rel_path

      run(string.format('mkdir -p "$(dirname "%s")"', dest))
      run(string.format('mv "%s" "%s"', target, dest))
      print_warn("Backed up conflicting file: " .. target .. " -> " .. dest)
    end

    print_info("Stowing (" .. conf.tag .. "): " .. pkg)
    run(string.format('stow -d "%s" -t "%s" "%s"', dotfiles_dir, home, pkg))
  end
end

print_step("Setup completed successfully for profile: " .. selected_profile:upper() .. ". Please restart your session.")
