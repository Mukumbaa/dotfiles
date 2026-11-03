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

-- Profiles configuration
local profile_tags = {
  ["minimal"] = { base = true, dev = true },
  ["desktop"] = { base = true, dev = true, gui_base = true }, -- (ex "vm")
  ["full"]    = { base = true, dev = true, gui_base = true, hyprland = true }
}

-- Aliases to make CLI input seamless
local profile_aliases = {
  ["cli"]      = "minimal",
  ["headless"] = "minimal",
  ["core"]     = "minimal",
  ["vm"]       = "desktop",
}

-- Default fallback
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

-- Resolve alias if present
if profile_aliases[selected_profile] then
  selected_profile = profile_aliases[selected_profile]
end

local active_tags = profile_tags[selected_profile]
if not active_tags then
  local valid_list = table.concat({"minimal", "desktop", "full"}, ", ")
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

local MANIFEST_URL = "https://raw.githubusercontent.com/Mukumbaa/Hyprland-RPM/main/packages.json"
local BASE_RPM_URL = "https://github.com/Mukumbaa/Hyprland-RPM/raw/refs/heads/main/"

local custom_packages = {
  { name = "caskaydia-mono-nerd-fonts", tag = "base" },
  { name = "starship",                 tag = "base" },
  { name = "yazi",                     tag = "base" },
  { name = "superfile",                tag = "base" },
  { name = "quickshell",               tag = "hyprland" },
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

local function load_remote_manifest(url)
  local handle = io.popen("curl -sL --fail '" .. url .. "'")
  if not handle then return nil end
  local content = handle:read("*a")
  handle:close()

  if not content or content == "" then return nil end

  -- Semplice parser JSON per mappe chiave:valore stringa
  local manifest = {}
  for key, value in content:gmatch('"([^"]+)"%s*:%s*"([^"]+)"') do
    manifest[key] = value
  end
  return manifest
end

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


print_step("Fetching Manifest for Custom Built RPMs")
local manifest = load_remote_manifest(MANIFEST_URL)

if not manifest then
  print_warn("Failed to retrieve packages.json from GitHub. Skipping custom RPMs.")
else
  local rpms_to_install = {}

  for _, pkg in ipairs(custom_packages) do
    if has_tag(pkg.tag) then
      local rpm_filename = manifest[pkg.name]
      if rpm_filename then
        print_info(string.format("Resolved %s -> %s", pkg.name, rpm_filename))
        table.insert(rpms_to_install, BASE_RPM_URL .. rpm_filename)
      else
        print_warn(string.format("Package '%s' not listed in packages.json", pkg.name))
      end
    end
  end

  if #rpms_to_install > 0 then
    print_step(string.format("Installing Custom RPMs (%d packages)", #rpms_to_install))
    local cmd = string.format("sudo dnf install -y --skip-unavailable %s", table.concat(rpms_to_install, " "))
    run(cmd)
  end
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
