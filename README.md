# Deathstart: System Specification and Configuration Snapshot

> Private workstation inventory captured on 2026-07-27 (America/Sao_Paulo).
>
> This is a descriptive snapshot, not a backup. Secrets and unique identifiers are intentionally omitted.

## Privacy boundary

The inventory excludes authentication tokens, password-manager data, SSH keys, browser profiles, cookies, shell histories, keyrings, API headers, environment secrets, machine/boot IDs, partition UUIDs, MAC/IP addresses, and raw credential-provider settings. GitHub authentication is recorded only as an authenticated account and protocol. Configuration backups and caches are counted only when useful and are not reproduced.

## Executive summary

| Area | Configuration |
|---|---|
| Host | `plazir27`, desktop, MSI MS-7E59 v2.0 |
| OS | Arch Linux, Omarchy `4.0.0.alpha` |
| Kernel | Linux `7.1.5-arch1-1` with LTS `6.18.40` also installed |
| CPU | AMD Ryzen 9 9950X, 16 cores / 32 threads, up to 5.756 GHz |
| GPU | NVIDIA GeForce RTX 5070, 12,227 MiB VRAM; integrated AMD Radeon Graphics |
| RAM | 30 GiB usable |
| Storage | 2 x WD_BLACK SN8100 1 TB NVMe; root/home on Btrfs |
| Display | LG UltraWide, 3440x1440 at 84.957 Hz, scale 1.0 |
| Desktop | Hyprland `0.56.0`, Wayland, Omarchy Matte Black theme |
| Shell | Bash `5.3.15`, Starship, fnm-managed Node.js |
| Editor | Neovim `0.12.4`, LazyVim v8 |
| Terminal | Alacritty `0.17.0`; Ghostty config also present; tmux `3.7_b` |
| Containers | Docker `29.6.2`, Compose `5.3.1`, overlayfs, systemd cgroups |
| Local AI | Ollama CUDA `0.32.4`, `gemma4-hvm:official-q4` (14 GB) |
| Package footprint | 1,066 pacman packages; 192 explicit; 2 foreign/AUR; no Flatpak apps |
| GitHub | Authenticated as `VeigaPunk` through `gh`, HTTPS Git transport |

## Hardware

### Platform and firmware

- Vendor/model: Micro-Star International, MS-7E59, hardware version 2.0.
- Firmware: American Megatrends UEFI 2.110, version 2.AC0, dated 2026-05-06.
- Boot loader: Limine 12.5.2 using a measured unified kernel image.
- TPM 2.0: supported.
- Secure Boot: disabled.
- Architecture: x86-64, little endian, 48-bit physical and virtual addressing.

### Processor

- AMD Ryzen 9 9950X, 1 socket, 16 cores, 32 threads.
- Frequency range observed: 624 MHz to 5.756 GHz; boost enabled.
- Cache: 768 KiB L1d, 512 KiB L1i, 16 MiB L2, 64 MiB L3.
- AMD-V virtualization enabled; AVX2 and AVX-512 families exposed.
- One NUMA node.

### Graphics and compute

- Discrete GPU: NVIDIA GeForce RTX 5070, 12,227 MiB VRAM, 250 W power limit.
- NVIDIA driver: `610.43.03`.
- CUDA toolkit: `13.3` (`nvcc` 13.3.73).
- Integrated GPU: AMD Granite Ridge Radeon Graphics.

### Memory and swap

- RAM: 30 GiB usable; 22 GiB available at capture time.
- Swap: 34 GiB total, including a 4 GiB zram device.
- `earlyoom` and `zram-generator` are installed.

### Storage and filesystems

- `nvme0n1`: WD_BLACK SN8100 1 TB.
  - 2 GiB FAT boot partition.
  - 929.5 GiB Btrfs partition mounted across `/`, `/home`, `/var/log`, and `/var/cache/pacman/pkg`.
- `nvme1n1`: WD_BLACK SN8100 1 TB, no mounted filesystem observed.
- Root filesystem usage at capture: 176 GiB of 930 GiB (19%).
- Snapper configuration: `root` for `/`; `snapper-cleanup.timer` enabled.

### Networking and peripherals

- Realtek RTL8126 5 GbE controller; Ethernet active at capture.
- Qualcomm WCN785x FastConnect 7800 Wi-Fi 7 adapter; Wi-Fi inactive at capture.
- Bluetooth enabled as a system service.
- ASMedia ASM4242 USB4 / Thunderbolt 3 host router.
- Display: LG UltraWide, 3440x1440 at 84.957 Hz.
- Input devices include HyperX Alloy Origins Core, Razer DeathAdder V2, and YubiKey OTP/FIDO/CCID.

## Operating system and boot

- Arch Linux rolling release with standard `linux` and `linux-lts` kernels installed.
- Current kernel: `7.1.5-arch1-1`, PREEMPT_DYNAMIC.
- Boot entry: `Omarchy/linux`, Limine loader, systemd-stub 261.2.
- Locale: `en_US.UTF-8`.
- Console/X11 keymap baseline: Brazilian ABNT2; active Hyprland keymap is US.
- Time zone: `America/Sao_Paulo`; NTP synchronized; RTC uses UTC.
- Display manager: SDDM.
- Init/service manager: systemd.
- Networking: systemd-networkd + systemd-resolved + iwd.
- Firewall package and service: UFW installed and enabled. Runtime rule details were unavailable without privilege escalation.

## Desktop and user experience

### Omarchy / Hyprland

- Omarchy version: `4.0.0.alpha`.
- Hyprland version: `0.56.0`, Wayland session.
- Theme: Matte Black.
- Font: JetBrainsMono Nerd Font.
- User Hyprland configuration is Lua-based and imports Omarchy defaults, then overlays:
  - `~/.config/hypr/monitors.lua`
  - `~/.config/hypr/input.lua`
  - `~/.config/hypr/bindings.lua`
  - `~/.config/hypr/looknfeel.lua`
  - `~/.config/hypr/autostart.lua`
- Monitor policy currently declares automatic preferred mode and automatic compositor scale with `GDK_SCALE=2`; the active output resolves to scale 1.0.
- Input policy:
  - Caps Lock is Compose.
  - Repeat rate 40/s, delay 250 ms.
  - Num Lock enabled by default.
  - Touchpad clickfinger behavior enabled; scroll factor 0.4.
- Appearance overrides are presently comments, so Omarchy defaults supply gaps, borders, rounding, layout, and animations.
- `Agent Wall` windows float.
- Idle policy launches a screensaver at 150 seconds and locks at 152 seconds; wake restores the display.
- Night-light profile is identity/no tint at 07:00; automatic warm profile is not enabled.

### Primary bindings

| Binding | Action |
|---|---|
| Super+Return | Terminal |
| Super+Alt+Return | tmux terminal |
| Super+Shift+Return / Super+Shift+B | Browser |
| Super+Shift+F | Nautilus |
| Super+Shift+N | Editor |
| Super+Shift+D | Lazydocker |
| Super+Shift+G | Signal |
| Super+Shift+O | Obsidian |
| Super+Shift+W | Typora with Wayland IME |
| Super+Shift+/ | 1Password |

Web-app bindings are configured for ChatGPT, Grok, HEY Calendar/Mail, YouTube, WhatsApp, Google Messages/Photos/Maps, and X.

### Waybar

- Top layer, 130 px height, style hot reload enabled.
- Left: Omarchy menu, workspaces, custom UFO status strip.
- Right: horizontal/vertical clocks, weather, updates, voice typing, recording/idle/notification indicators, tray, Bluetooth, network, audio, CPU, and battery.
- Five persistent workspaces.
- Update check interval: 21,600 seconds.
- CPU refresh: 5 seconds; network refresh: 3 seconds.
- Battery warning/critical thresholds: 20% / 10%.
- Custom UFO strip script refreshes every 2 seconds.

### Terminals and tmux

- Alacritty:
  - Imports current Omarchy theme.
  - `TERM=xterm-256color`, OSC52 CopyPaste.
  - JetBrainsMono Nerd Font 13 pt; 14 px padding; no decorations.
  - Explicit CSI-u encodings for Shift+Enter and Alt+Shift+Enter.
- Ghostty:
  - Imports current Omarchy theme.
  - Same 13 pt font and 14 px padding; block non-blinking cursor.
  - epoll async backend for Hyprland performance.
  - CSI-u bindings aligned with Alacritty/tmux.
- tmux:
  - Primary prefix Ctrl+Space, fallback Ctrl+B.
  - Vi copy mode, mouse, RGB, OSC52 clipboard, extended keys, 50,000-line history.
  - Windows/panes start at index 1 and renumber automatically.
  - Alt+Enter/Alt+Shift+Enter split vertically/horizontally.
  - Alt+arrows navigate windows/sessions; Ctrl+Alt+arrows navigate panes.
  - Status bar at top using a blue/black theme.

### Shell and prompt

- Bash initializes fnm before the non-interactive guard so subprocesses inherit Node.
- Interactive shell sources Omarchy defaults.
- Godspeed execution markers are exported for agent/child-process inheritance.
- OpenCode is wrapped to prefer port 4096 only when free, falling back to an ephemeral port for concurrent instances.
- Grok CLI path and completion are installed.
- Starship prompt shows directory, Git branch/status, and command result; directory depth is truncated to two components.

## Developer environment

### Core tools

| Tool | Version / state |
|---|---|
| Bash | 5.3.15 |
| Git | 2.55.0 |
| GitHub CLI | 2.96.0 |
| OpenCode | 1.18.6 |
| Neovim | 0.12.4 |
| tmux | 3.7_b |
| Docker | 29.6.2 |
| Docker Buildx | 0.35.0 |
| Docker Compose | 5.3.1 |
| CMake | 4.4.0 |
| Make | 4.4.1 |
| GCC | 16.1.1 |
| Clang/LLVM | 22.1.8 |

### Language runtimes

| Runtime | Version / state |
|---|---|
| Node.js | 26.5.0, fnm default |
| npm | 11.17.0 |
| Bun | 1.3.14 |
| Deno | 2.9.4; V8 15.0.245.2; TypeScript 6.0.3 |
| Python | 3.14.6 |
| Ruby | 3.4.10; RubyGems 3.6.9 |
| Rust | rustc/cargo 1.97.1 |
| Go | Local standalone Go 1.23.12 (not on default `PATH`) |
| .NET | Host 10.0.10; Microsoft.NETCore.App 9.0.18; no SDK |
| Lua | System runtime installed via dependencies; LuaRocks 3.13.0 |
| CUDA | 13.3 |

No Java/JDK, PHP, Zig, uv, pipx, Kubernetes, Helm, Terraform, Ansible, Podman, or Flatpak application installation was detected on `PATH` during capture. Go 1.23.12 exists at `~/.local/go1.23.12` but is not exported on the default path.

### Global language/tool dependencies

- npm global:
  - `@colbymchenry/codegraph@1.5.0`
  - `npm@11.17.0`
  - `opencode-ai@1.18.6`
- Cargo-installed:
  - `bend-lang@0.2.38`
  - `cargo-insta@1.48.0`
  - `cargo-nextest@0.9.140`
  - `just@1.57.0`
- Bun has no global packages listed.
- Ruby has only the standard/default gem set.

### Git policy

- New repositories default to branch `master`.
- Pulls rebase instead of merge.
- Pushes automatically establish upstream tracking.
- Histogram diff algorithm, moved-line coloring, mnemonic prefixes.
- Verbose commits.
- Branches sort by recent commit; tags sort by version.
- `rerere` and automatic conflict-resolution updates enabled.
- Git aliases: `co`, `br`, `ci`, `st`.
- GitHub credentials are delegated to `gh`; no credential value is stored in this report.

### Neovim

- LazyVim version/install schema 8.
- Extra: `lazyvim.plugins.extras.editor.neo-tree`.
- Lockfile pins 51 plugins, including LazyVim, lazy.nvim, neo-tree, blink.cmp, conform, nvim-lspconfig, Mason, Treesitter, snacks, noice, trouble, which-key, gitsigns, and multiple theme packages.
- Theme packages include Aether, Ashen, Bamboo, Catppuccin, Ethereal, Everforest, Flexoki, Gruvbox, Hackerman, Kanagawa, Lumon, Matte Black, Miasma, Monokai Pro, Nightfox, Retro-82, Rose Pine, Tokyo Night, Vantablack, and White.

### OpenCode and agent stack

- Global schema: `https://opencode.ai/config.json`; automatic updates enabled.
- Global instruction file: `~/.config/opencode/AGENTS.md`.
- Plugins:
  - `oh-my-openagent@latest`
  - `opencode-kimi-full@1.4.0`
  - `@ex-machina/opencode-anthropic-auth`
- Inline/custom agent names: connector, critic, distiller, ds4cc, executor, labrat, mutation-tester, network-auditor, revenger, reviewer, scout, scribe, sentinel, simplifier.
- Custom commands: godspeed, wwkd, xbgst.
- oh-my-openagent profiles: atlas, explore, hephaestus, librarian, metis, momus, multimodal-looker, oracle, prometheus, sisyphus, sisyphus-junior.
- Categories: artistry, deep, quick, ultrabrain, unspecified-high/low, visual-engineering, writing.
- Team mode and tmux visualization are enabled.
- Local OpenCode package dependency: `@opencode-ai/plugin@1.18.5`.
- 16 Markdown agent definitions, 2 `~/.agents` skills, and 1 `~/.claude` skill were detected.
- Provider credentials, auth plugin internals, permission patterns, cache, node_modules, and backups are deliberately not reproduced.

### Local AI services

- `ollama-hvm.service`:
  - Flash attention enabled.
  - Q8_0 KV cache.
  - Two parallel requests, one loaded model maximum.
  - Restart on failure.
- Model: `gemma4-hvm:official-q4`, approximately 14 GB.
- `xbreed-hvm-proxy.service` depends on Ollama and bridges an OpenAI Responses API path to Bend/HVM4 and Ollama from `~/Projects/hvm-gemma4`.

### Active project dependency landscape

Eight top-level project directories were present: `agent-waybar`, `codex-titanium`, `hvm-gemma4`, `HVM4`, `hyperplan-pcbuild`, `snapshot-x`, `ufo-cli`, and `xbrd-tui`. The following declared dependency surfaces were verified:

- `codex-titanium`: private Codex maintenance monorepo requiring Node >=22 and pnpm >=10.33.0. Root tooling uses Prettier 3.5 and pins security/compatibility resolutions for MCP SDK, esbuild, Hono, Rollup, Handlebars, minimatch, micromatch, semver, and related transitive packages. The primary codebase is a large Rust workspace with its own Cargo/Bazel dependency graph.
- `snapshot-x`: React 19 + Vite 7 TypeScript application with:
  - UI: Radix UI primitives, Tailwind CSS 3, Framer Motion, GSAP, Recharts, Lucide, Embla, Sonner, Vaul.
  - State/forms/contracts: TanStack Query, React Hook Form, Zod 4, tRPC 11, SuperJSON.
  - Server/data: Hono, Drizzle ORM, MySQL2, AWS S3 SDK, JOSE, dotenv.
  - Tooling: TypeScript 5.9, ESLint 9, Prettier 3.7, Vitest 4, esbuild 0.27, Drizzle Kit.
- `ufo-cli`: Rust 2021 TUI using Ratatui 0.29, Crossterm 0.28, bundled SQLite via rusqlite 0.32, Serde, SHA-2, thiserror, libc, and tempfile for tests.
- `xbrd-tui`: Go 1.23 TUI using Bubble Tea 1.3, Lip Gloss 1.0, `x/sys`, OSC52, terminal/ANSI support, and Unicode width/segmentation libraries.

Lockfiles were present for the verified ecosystems: npm/package-lock, pnpm, Cargo, and Go sums. Source trees and lockfile bodies are intentionally not copied into this inventory; their manifests remain authoritative for exact project transitive dependencies.

### Extended agent ecosystem

- Claude configuration includes 15 custom agents, orchestration commands (`orch`, `wwkd`, `xbgst`, `xbreed` variants), and installed plugin families for DS4CC, xbreed/godspeed, custom agents, agent-wall, and godspeed-core.
- Global agent directives live in `~/AGENTS.md`, `~/.agents/AGENTS.md`, and tool-specific configuration roots.
- Conversation transcripts, prompt histories, model state, OAuth stores, telemetry tokens, and plugin caches are excluded.

## Services

### Enabled user services/sockets

- `elephant.service`
- `ollama-hvm.service`
- `omarchy-recover-internal-monitor.service`
- `swayosd-server.service`
- `wireplumber.service`
- `xbreed-hvm-proxy.service`
- `xdg-user-dirs.service`
- `gnome-keyring-daemon.socket`
- `p11-kit-server.socket`
- `pipewire.socket`
- `pipewire-pulse.socket`

### Enabled system services/sockets/timers

- Printing/discovery: CUPS, CUPS Browsed, Avahi.
- Connectivity: Bluetooth, iwd, systemd-networkd, systemd-resolved.
- Display/login: SDDM.
- Containers: Docker socket activation.
- Security/resource control: UFW, earlyoom package installed.
- Storage/boot: Limine snapshot sync, kernel module cleanup, Snapper cleanup timer.
- Audio stack: PipeWire 1.6.8, WirePlumber 0.5.15.
- Active maintenance timers observed: package-file index, man-db, Snapper cleanup, temp-file cleanup, shadow maintenance, Arch keyring sync.

## Explicit Arch package set

The following 192 explicitly installed packages define the reproducible system surface. Versions are capture-time versions.

```text
1password-beta 8.12.24_31.BETA-31.1
1password-cli 2.34.1-1
aether 4.27.2-1
alacritty 0.17.0-1
alsa-utils 1.2.16-1
amd-ucode 20260622-1
asdcontrol 1:0.6.0-1
base 3-3
base-devel 1-2
bash-completion 2.18.0-1
bat 0.26.1-2
bluetui 0.8.1-2
bolt 0.9.11-1
brave-bin 1:1.92.144-1
brightnessctl 0.5.1-3
btop 1.4.7-1
btrfs-progs 7.1-1
bun 1.3.14-1
chromium 150.0.7871.186-1
clang 22.1.8-1
claude-code 2.1.179-1
cliamp 1.57.1-1
cmake 4.4.0-2
cuda 13.3.1-1
cups 2:2.4.19-1
cups-browsed 2.1.1-1
cups-filters 2.0.1-2
cups-pdf 3.0.3-1
docker 1:29.6.2-1
docker-buildx 0.35.0-1
docker-compose 5.3.1-1
dosfstools 4.2-5
dotnet-runtime-9.0 9.0.18.sdk119-1
dua-cli 2.38.1-1
earlyoom 1.9.0-1
efibootmgr 18-4
evince 1:48.4-1
exfatprogs 1.4.2-1
expac 10-12
eza 0.23.5-2
fastfetch 2.66.0-1
fcitx5 5.1.21-1
fcitx5-gtk 5.1.7-1
fcitx5-qt 5.1.14-1
fd 10.4.2-2
ffmpegthumbnailer 2.3.0-1
fio 3.42-1
firefox 153.0-1
fnm 1.39.0-1
fontconfig 2:2.18.2-1
fzf 0.74.1-1
git 2.55.0-1
github-cli 2.96.0-1
gnome-calculator 50.0-1
gnome-disk-utility 46.1-2
gnome-keyring 1:50.0-1
gnome-themes-extra 1:3.28-1
gpu-screen-recorder 5.15.2-1
grim 1.5.0-2
gst-plugin-pipewire 1:1.6.8-1
gum 0.17.0-1
gvfs-mtp 1.60.1-1
gvfs-nfs 1.60.1-1
gvfs-smb 1.60.1-1
hypridle 0.1.8-1
hyprland 0.56.0-2
hyprland-guiutils 0.2.2-1
hyprland-preview-share-picker 0.2.1-1
hyprlock 0.9.6-1
hyprpicker 0.4.7-2
hyprsunset 0.4.0-3
imagemagick 7.1.2.27-1
impala 0.7.4-1
imv 5.0.1-2
inetutils 2.8-1
inotify-tools 4.25.9.0-1
inxi 3.3.41.1-1
iwd 3.12-1
jq 1.8.2-1
kdenlive 26.04.3-1
kernel-modules-hook 0.1.7-3
kvantum-qt5 1.1.8-1
lazydocker 0.25.2-1
lazygit 0.63.1-1
less 1:704-1
lib32-nvidia-utils 610.43.03-1
libpulse 17.0+r98+gb096704c0-1
libqalculate 5.12.0-1
libreoffice-fresh 26.2.5-1
libva-nvidia-driver 0.0.17-1
libyaml 0.2.5-3
limine 12.5.2-1
limine-mkinitcpio-hook 1.36.0-1
limine-snapper-sync 1.30.1-1
linux 7.1.5.arch1-1
linux-firmware 20260622-1
linux-headers 7.1.5.arch1-1
linux-lts 6.18.40-2
linux-lts-headers 6.18.40-2
llvm 22.1.8-2
localsend 1.17.0-3
luarocks 3.13.0-5
mako 1.11.0-1
man-db 2.13.1-2
mariadb-libs 12.3.2-3
mkinitcpio 41-4
mpv 1:0.41.0-3
mpv-mpris 1.2-1
nautilus 50.2.2-1
nautilus-python 4.1.0-3
neovim 0.12.4-1
ninja 1.13.2-3
noto-fonts 1:2026.07.01-1
noto-fonts-cjk 20240730-1
noto-fonts-emoji 1:2.051-1
nss-mdns 0.15.1-2
nvidia-open-dkms 610.43.03-4
nvidia-utils 610.43.03-4
obs-studio 32.1.2-7
obsidian 1.12.7-3
ollama-cuda 0.32.4-1
omarchy-keyring 20251027-1
omarchy-nvim 2026.7.23-1
omarchy-walker 1.0.0-2
pamixer 1.6-4
pinta 3.1.2-1
pipewire 1:1.6.8-1
pipewire-alsa 1:1.6.8-1
pipewire-jack 1:1.6.8-1
pipewire-pulse 1:1.6.8-1
playerctl 2.4.1-5
plocate 1.1.24-1
plymouth 26.134.222-2
polkit-gnome 0.105-12
postgresql-libs 18.4-2
power-profiles-daemon 0.30-1
python-gobject 3.56.3-1
python-poetry-core 2.4.1-1
python-terminaltexteffects 0.15.0-1
qemu-user-static-binfmt 11.0.2-4
qt5-wayland 5.15.19+kde+r55-1
quickshell 0.3.0-2
ripgrep 15.2.0-1
ruby 3.4.10-1
rust 1:1.97.1-1
satty 0.21.1-1
sddm 0.21.0-7
signal-desktop 8.20.0-1
slurp 1.5.0-2
smartmontools 7.5-1
snapper 0.13.1-2
socat 1.8.1.3-1
spotify 1:1.2.92.147-1
starship 1.26.0-1
sudo 1.9.17.p2-6
sushi 50.0-1
swaybg 1.2.2-1
swayosd 0.3.1-1
system-config-printer 1.5.18-6
tesseract 5.5.3-1
tesseract-data-eng 2:4.1.0-5
tldr 3.4.4-1
tmux 3.7_b-1
tobi-try 1.8.1-2
tree-sitter-cli 0.26.9-1
ttf-ia-writer 20181225-1
ttf-jetbrains-mono-nerd 3.4.0-2
typora 1.13.6-1
tzupdate 3.1.0-1
ufw 0.36.2-7
ufw-docker 251123-1
unzip 6.0-23
usage 3.5.5-1
uwsm 0.26.6-1
vulkan-radeon 1:26.1.5-1
waybar 0.15.0-2
whois 5.6.6-1
wireless-regdb 2026.05.30-1
wiremix 0.11.0-1
wireplumber 0.5.15-1
wl-clipboard 1:2.3.0-1
woff2-font-awesome 7.3.1-1
xdg-desktop-portal-gtk 1.15.3-1
xdg-desktop-portal-hyprland 1.4.0-1
xdg-terminal-exec 0.14.0-1
xmlstarlet 1.6.1-6
xournalpp 1.3.5-1
yaru-icon-theme 26.04.5.1ubuntu-1
yay 12.6.0-1
zen-browser-bin 1.21.9b-1
zoxide 0.10.0-1
zram-generator 1.2.1-1
```

Foreign/AUR packages are `brave-bin` and `zen-browser-bin`; all other explicit packages resolve from configured pacman repositories.

## Configuration footprint

Non-backup, non-cache file counts observed in major user configuration areas:

| Area | Files |
|---|---:|
| Alacritty | 1 |
| btop | 1 |
| fastfetch | 1 |
| fish | 1 |
| Foot | 1 |
| Ghostty | 1 |
| Hyprland | 12 |
| Kitty | 1 |
| Lazygit | 1 |
| Neovim | 17 |
| Omarchy user overlays/themes/hooks | 39 |
| systemd user units | 8 |
| tmux | 1 |
| Walker | 1 |
| Waybar | 4 |
| WirePlumber | 1 |
| xbreed | 1 |

OpenCode's directory contains thousands of dependency/cache files; only declared packages, agent/config names, and behaviorally meaningful settings are summarized above.

## Reproduction notes

1. Install Arch Linux on UEFI hardware with Btrfs, Limine, both current and LTS kernels, NVIDIA open DKMS, AMD microcode, zram, Snapper, and the explicit package set.
2. Install Omarchy and select Matte Black with JetBrainsMono Nerd Font.
3. Restore only intentional user config from `~/.config`; do not copy keyrings, browser state, caches, or auth material.
4. Reinstall npm and Cargo globals listed above, then restore the Neovim lockfile if exact plugin revisions matter.
5. Configure and authenticate 1Password, GitHub CLI, browsers, OpenCode providers, and external services interactively on the destination machine.
6. Enable the listed user/system units after reviewing hardware-specific entries.

Because this document intentionally does not contain raw configuration files or secrets, it is safe as an inventory but cannot by itself reproduce credentials, browser sessions, device identities, or every application preference.
