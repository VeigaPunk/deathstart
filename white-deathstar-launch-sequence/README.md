# White Deathstar Launch Sequence

Fresh machine to the verified `plazir27` performance profile.

This runbook treats [`deathstart@62935bf`](https://github.com/VeigaPunk/deathstart/tree/62935bf79afd1f8a1f7e83259c6c94cfdb1b9bc0) as a specification and source of truth, not as a restore image. The base inventory is in [`README.md`](../README.md); later facts in the [July 27 optimization report](../optimizations/2026-07-27/REPORT.md) take precedence.

## What this can and cannot reproduce

The intended result is the same hardware behavior, package capability, desktop feel, and verified tuning—not a bit-for-bit historical Arch image.

- The snapshot says Omarchy `4.0.0.alpha`, but does not pin its upstream commit or ISO. Its two stored Lua files also require four missing Lua modules.
- The current supported release is [Omarchy 3.8.4](https://github.com/basecamp/omarchy/releases/tag/v3.8.4). Omarchy 4/Quattro is still a development beta and replaces Waybar and the stable `.conf` overlay model.
- The package inventory captured 192 explicit packages, then the optimization session installed `pacman-contrib` and upgraded 25 packages without recording the resulting versions.
- UUIDs, resume offsets, firewall rules, secrets, credentials, browser state, custom service bodies, and most dotfiles were intentionally excluded.

For those reasons this sequence starts on stable Omarchy 3.8.4 and translates the verified intent. Do not switch to Quattro until the stable acceptance gate at the end passes and a fresh snapshot exists.

## Target profile

| Axis | Target |
|---|---|
| Host | `plazir27` |
| Board | MSI MAG X870E TOMAHAWK WIFI / MS-7E59 v2.0 |
| Firmware | BIOS 2.AC3 was the final verified state |
| CPU | Ryzen 9 9950X, 16C/32T |
| Memory | KF560C30 2×16 GB, DDR5-6000 CL30 profile |
| GPU | RTX 5070 12 GB, NVIDIA open kernel modules |
| Storage | 2× WD_BLACK SN8100 1 TB; system disk Btrfs; second disk intentionally empty |
| Display | LG UltraWide, 3440×1440, scale 1 |
| Desktop | Hyprland/Wayland, Matte Black, JetBrainsMono Nerd Font |
| Boot | Limine, current + LTS kernels, Snapper |
| Memory pressure | zram = RAM/2, zstd, swappiness 100 |
| Locale | `en_US.UTF-8`, `America/Sao_Paulo`, RTC UTC |

## Phase 0 — protect the machine

The Omarchy installer wipes the selected disk. Both installed NVMe devices have the same model and capacity, and `/dev/nvme0n1` numbering is not a stable identity.

1. Back up anything valuable.
2. If the second SN8100 contains data now, disconnect it during installation.
3. Use a wired or 2.4 GHz keyboard; Bluetooth cannot unlock LUKS before boot.
4. Identify disks by **serial**, never by the current `nvme0n1` name:

```bash
lsblk -d -o NAME,PATH,SIZE,MODEL,SERIAL,WWN
```

Write down the serial of the intended system disk. The final source-of-truth state left the other SN8100 empty and unmounted. Do not run `setup-fast-tmp.sh` if parity with the snapshot is the goal.

## Phase 1 — firmware baseline

Official board support: [MSI MAG X870E TOMAHAWK WIFI](https://www.msi.com/Motherboard/MAG-X870E-TOMAHAWK-WIFI/support).

The final verified firmware was 2.AC3. Do not downgrade a newer firmware merely to match the label. After any flash, re-enter settings manually; MSI OC profiles are firmware-version-specific.

Before installing:

- UEFI mode; CSM disabled.
- Secure Boot disabled. Disable firmware TPM temporarily too if the Omarchy installer blocks on it.
- Re-Size BAR and Above 4G Decoding enabled.
- Integrated graphics disabled only if the monitor is connected to the RTX 5070 and no iGPU workload is needed.
- Keep the high-performance profile below for after the OS is proven stable.

## Phase 2 — install stable Omarchy

Use the official [Omarchy install guide](https://learn.omacom.io/2/the-omarchy-manual/50/getting-started).

Download: [omarchy-3.8.4.iso](https://iso.omarchy.org/omarchy-3.8.4.iso)

Published SHA-256:

```text
7bc1dc7d98f3d088e57dc06581a494ea441fb15f3edd191360fd1696931bd895
```

Verify the downloaded image:

```bash
echo '7bc1dc7d98f3d088e57dc06581a494ea441fb15f3edd191360fd1696931bd895  omarchy-3.8.4.iso' | sha256sum -c -
```

Flash it with Caligula on Linux or balenaEtcher on macOS/Windows. Boot the USB and select the intended disk by the serial recorded in Phase 0.

Installer choices:

- Hostname: `plazir27`
- Full-disk LUKS encryption: enabled
- Filesystem: Btrfs/default Omarchy layout
- Timezone: `America/Sao_Paulo`
- Locale: `en_US.UTF-8`
- Use the default stable channel

After first login, update through Omarchy so migrations and packages move together:

```bash
omarchy update
sudo reboot
```

Do not use `pacman -Syu` or `yay -Syu` for routine full-system updates. See the official [update-channel guidance](https://learn.omacom.io/2/the-omarchy-manual/68/updates).

## Phase 3 — first-boot hardware gate

Paste this before applying any tuning:

```bash
set -euo pipefail

echo '== CPU =='
lscpu | grep -E 'Model name|Socket|Core|Thread'

echo '== GPU/driver =='
lspci -nnk | grep -A3 -E 'VGA|3D'
nvidia-smi

echo '== disks: compare SERIAL with Phase 0 =='
lsblk -d -o NAME,PATH,SIZE,MODEL,SERIAL,WWN

echo '== filesystem =='
findmnt -t btrfs -o TARGET,SOURCE,FSTYPE,OPTIONS

echo '== display =='
hyprctl monitors all

echo '== failed units =='
systemctl --failed --no-pager
```

Stop here if the CPU is not a Ryzen 9 9950X, the discrete GPU is not an RTX 5070, the root disk serial is wrong, `nvidia-smi` fails, or systemd has unexplained failed units.

Omarchy's RTX 5070 path already installs `nvidia-open-dkms`, `nvidia-utils`, `lib32-nvidia-utils`, `libva-nvidia-driver`, early KMS, and the NVIDIA environment. Do not install a second NVIDIA stack.

## Phase 4 — source snapshot and package surface

Authenticate GitHub interactively; never paste a token into shell history:

```bash
omarchy pkg add github-cli
gh auth login
gh auth setup-git
mkdir -p "$HOME/src"
cd "$HOME/src"
gh repo clone VeigaPunk/deathstart
cd deathstart
git checkout --detach 62935bf79afd1f8a1f7e83259c6c94cfdb1b9bc0
```

Install the captured **names at current compatible versions** after `omarchy update`. Omarchy 3.8.4 supports `omarchy pkg add` for repositories and `omarchy pkg aur add` for AUR packages.

```bash
repo_packages=(
  1password-beta 1password-cli aether alacritty alsa-utils amd-ucode asdcontrol
  base base-devel bash-completion bat bluetui bolt brightnessctl btop btrfs-progs
  bun chromium clang claude-code cliamp cmake cuda cups cups-browsed cups-filters
  cups-pdf docker docker-buildx docker-compose dosfstools dotnet-runtime-9.0 dua-cli
  earlyoom efibootmgr evince exfatprogs expac eza fastfetch fcitx5 fcitx5-gtk
  fcitx5-qt fd ffmpegthumbnailer fio firefox fnm fontconfig fzf git github-cli
  gnome-calculator gnome-disk-utility gnome-keyring gnome-themes-extra
  gpu-screen-recorder grim gst-plugin-pipewire gum gvfs-mtp gvfs-nfs gvfs-smb
  hypridle hyprland hyprland-guiutils hyprland-preview-share-picker hyprlock
  hyprpicker hyprsunset imagemagick impala imv inetutils inotify-tools inxi iwd jq
  kdenlive kernel-modules-hook kvantum-qt5 lazydocker lazygit less
  lib32-nvidia-utils libpulse libqalculate libreoffice-fresh libva-nvidia-driver
  libyaml limine limine-mkinitcpio-hook limine-snapper-sync linux linux-firmware
  linux-headers linux-lts linux-lts-headers llvm localsend luarocks mako man-db
  mariadb-libs mkinitcpio mpv mpv-mpris nautilus nautilus-python neovim ninja
  noto-fonts noto-fonts-cjk noto-fonts-emoji nss-mdns nvidia-open-dkms nvidia-utils
  obs-studio obsidian ollama-cuda omarchy-keyring omarchy-nvim omarchy-walker
  pacman-contrib pamixer pinta pipewire pipewire-alsa pipewire-jack pipewire-pulse
  playerctl plocate plymouth polkit-gnome postgresql-libs power-profiles-daemon
  python-gobject python-poetry-core python-terminaltexteffects qemu-user-static-binfmt
  qt5-wayland quickshell ripgrep ruby rust satty sddm signal-desktop slurp
  smartmontools snapper socat spotify starship sudo sushi swaybg swayosd
  system-config-printer tesseract tesseract-data-eng tldr tmux tobi-try
  tree-sitter-cli ttf-ia-writer ttf-jetbrains-mono-nerd typora tzupdate ufw
  ufw-docker unzip usage uwsm vulkan-radeon waybar whois wireless-regdb wiremix
  wireplumber wl-clipboard woff2-font-awesome xdg-desktop-portal-gtk
  xdg-desktop-portal-hyprland xdg-terminal-exec xmlstarlet xournalpp
  yaru-icon-theme yay zoxide zram-generator
)

omarchy pkg add "${repo_packages[@]}"
omarchy pkg aur add brave-bin zen-browser-bin
```

If a package has been renamed or removed, leave it out and record the substitution. Do not downgrade the system or fetch a stale package archive to force an old version.

## Phase 5 — verified system tuning

These are the reusable settings proven in the later optimization report. They do not replay the historical TPM repair, cache deletion, hibernate resume values, or disk provisioning.

### zram and VM pressure

```bash
sudo install -d /etc/systemd /etc/sysctl.d

sudo tee /etc/systemd/zram-generator.conf >/dev/null <<'EOF'
[zram0]
compression-algorithm = zstd
zram-size = ram / 2
EOF

sudo tee /etc/sysctl.d/99-zram-tuning.conf >/dev/null <<'EOF'
vm.swappiness = 100
vm.page-cluster = 0
EOF

sudo sysctl --system
```

The zram resize takes effect after reboot.

### parallel native builds

```bash
sudo install -d /etc/makepkg.conf.d
sudo tee /etc/makepkg.conf.d/99-parallel.conf >/dev/null <<'EOF'
MAKEFLAGS="-j$(nproc)"
NINJAFLAGS="-j$(nproc)"
EOF
```

This evaluates to 32 jobs on the 9950X. Watch RAM and temperature during large builds.

### disable LLMNR

```bash
sudo install -d /etc/systemd/resolved.conf.d
sudo tee /etc/systemd/resolved.conf.d/11-disable-llmnr.conf >/dev/null <<'EOF'
[Resolve]
LLMNR=no
EOF
sudo systemctl restart systemd-resolved
```

### package cache policy

```bash
sudo systemctl enable --now paccache.timer
```

Do not run the old immediate cache-pruning commands on a fresh install; there is nothing useful to reclaim yet.

### Btrfs intent

The target layout is `/`, `/home`, `/var/log`, and `/var/cache/pacman/pkg` on Btrfs subvolumes with zstd compression and `noatime`. Never copy `fstab.sanitized`: its UUIDs are redacted.

Inspect the installer-generated file:

```bash
findmnt -t btrfs -o TARGET,SOURCE,FSTYPE,OPTIONS
sudoedit /etc/fstab
```

For the four Btrfs lines, preserve the generated UUID, encryption mapping, and `subvol=` value. Add `noatime` only if absent. Modern Btrfs already defaults to async discard and space-cache v2 on supported kernels; do not cargo-cult obsolete option spellings.

### hibernation

Use Omarchy's current `Setup > System Sleep > Enable Hibernation` flow. It must generate a new swapfile, filesystem UUID, and Btrfs resume offset. The historical values are deliberately absent and must never be copied.

Boot the LTS kernel once before the first hibernate test.

### NVIDIA power handling

Inspect current driver behavior first:

```bash
grep -E 'PreserveVideoMemory|TemporaryFilePath|UseKernelSuspendNotifiers' \
  /proc/driver/nvidia/params 2>/dev/null || true
systemctl is-enabled nvidia-suspend.service nvidia-hibernate.service \
  nvidia-resume.service 2>/dev/null || true
```

The snapshot's explicit `NVreg_PreserveVideoMemoryAllocations=1` workaround is driver-version-sensitive. Current open modules can preserve memory through suspend notifiers. Do not copy the old modprobe file unless current NVIDIA documentation and the runtime parameters show it is still required.

## Phase 6 — desktop profile

Omarchy-owned defaults live under `~/.local/share/omarchy`; never edit them. User overlays belong in `~/.config` per the official [dotfiles guide](https://learn.omacom.io/2/the-omarchy-manual/65/dotfiles).

### theme and font

```bash
omarchy theme set 'Matte Black'
omarchy font set 'JetBrainsMono Nerd Font'
```

### 3440×1440 scale 1

Back up the generated monitor config, then replace only this user overlay:

```bash
mkdir -p "$HOME/.local/state/white-deathstar/backups" "$HOME/.config/hypr"
cp -a "$HOME/.config/hypr/monitors.conf" \
  "$HOME/.local/state/white-deathstar/backups/monitors.conf.$(date +%s)" 2>/dev/null || true

tee "$HOME/.config/hypr/monitors.conf" >/dev/null <<'EOF'
env = GDK_SCALE,1
monitor=,preferred,auto,1
EOF

hyprctl reload
```

Quit and relaunch GUI applications after changing `GDK_SCALE`.

Verify that Omarchy's NVIDIA environment is present; add only missing lines to the stable `.conf` overlay:

```bash
mkdir -p "$HOME/.config/hypr"
touch "$HOME/.config/hypr/envs.conf"
for line in \
  'env = NVD_BACKEND,direct' \
  'env = LIBVA_DRIVER_NAME,nvidia' \
  'env = __GLX_VENDOR_LIBRARY_NAME,nvidia'
do
  grep -Fqx "$line" "$HOME/.config/hypr/envs.conf" || printf '%s\n' "$line" >> "$HOME/.config/hypr/envs.conf"
done
hyprctl reload
```

Do not copy the snapshot's Lua files into stable 3.8.4.

### Waybar / agent wall

The stored Waybar config proves that polling a 26 MB status binary every 12 ms consumed about 12% CPU; a 2-second interval reduced it to about 0.2%. If `custom/agent-wall` exists, set only its `interval` to `2`. Avoid replacing the whole current Waybar config because only one of the snapshot's four Waybar files was preserved.

Install the current wall binary:

```bash
mkdir -p "$HOME/Projects"
cd "$HOME/Projects"
gh repo clone VeigaPunk/plazir18
cd plazir18
cargo build --release --locked
install -Dm755 target/release/agent-wall "$HOME/.local/bin/plazir18"
ln -sfn "$HOME/.local/bin/plazir18" "$HOME/.local/bin/agent-wall"
```

Then edit `~/.config/waybar/config.jsonc` through `Setup > Configs > Waybar` and use:

```jsonc
"custom/agent-wall": {
  "format": "{}",
  "exec": "$HOME/.local/bin/agent-wall --status-pango",
  "return-type": "json",
  "interval": 2,
  "escape": false,
  "tooltip": true
}
```

### shell-safe personal layer

Do not replace `.bashrc` wholesale; the stored copy references missing projects and private token files. Add a separate sourced fragment:

```bash
mkdir -p "$HOME/.config/bash"
tee "$HOME/.config/bash/white-deathstar.sh" >/dev/null <<'EOF'
export GODSPEED=1
export GODSPEED_MODE=always
export GODSPEED_DELEGATE_SUFFIX=' | godspeed'
export GODSPEED_EXECUTOR_SUFFIX=' | godspeed-impl'

if command -v fnm >/dev/null 2>&1; then
  if [[ $- == *i* ]] || [[ ! -x "${FNM_MULTISHELL_PATH:-/nonexistent}/bin/node" ]]; then
    eval "$(fnm env --use-on-cd --shell bash)"
  fi
fi
EOF

grep -Fqx 'source "$HOME/.config/bash/white-deathstar.sh"' "$HOME/.bashrc" || \
  printf '\nsource "$HOME/.config/bash/white-deathstar.sh"\n' >> "$HOME/.bashrc"

bash -n "$HOME/.bashrc"
```

## Phase 7 — runtimes and globals

The capability target was Node 26.5.0, npm 11.17.0, Bun 1.3.14, Deno 2.9.4, Python 3.14.6, Ruby 3.4.10, Rust 1.97.1, and CUDA 13.3. Use current Omarchy development installers or Mise, then pin only where a project requires it.

```bash
mise use -g node@26.5.0
npm install -g npm@11.17.0 @colbymchenry/codegraph@1.5.0 opencode-ai@1.18.6

cargo install --locked bend-lang --version 0.2.38
cargo install --locked cargo-insta --version 1.48.0
cargo install --locked cargo-nextest --version 0.9.140
cargo install --locked just --version 1.57.0
```

Authenticate 1Password, GitHub CLI, browsers, OpenCode providers, and external services interactively. Never copy tokens, keyrings, browser profiles, OAuth stores, or credential-provider internals from another system.

The custom `ollama-hvm.service`, `xbreed-hvm-proxy.service`, `omarchy-recover-internal-monitor.service`, and their unit bodies were not preserved. Do not create placeholder units merely to make service names match.

## Phase 8 — high-performance BIOS profile

Apply only on the same MS-7E59 board with adequate cooling. The recorded all-core load rode the 95°C PBO ceiling; cooling was the limiter.

Enter BIOS with `Delete`, then Advanced Mode (`F7`):

### Memory

- A-XMP/EXPO: Profile 1, DDR5-6000 CL30 1.40 V
- FCLK: 2100 MHz; revert to 2000 if unstable
- UCLK DIV1: UCLK = MEMCLK (1:1)
- High-Efficiency Mode: Tighter
- Latency Killer: enabled
- Memory Context Restore: disabled during the stability week
- Power Down Enable: disabled during the stability week

The first EXPO boot can remain black for 1–3 minutes while memory trains. Do not interrupt it.

### CPU/PBO

- Precision Boost Overdrive: Advanced
- PBO limits: Motherboard
- Scalar: 10X
- Boost clock override: +200 MHz
- Curve Optimizer: all cores, negative 15
- Platform thermal limit: 95°C
- SMT, Global C-States, CPPC, and CPPC Preferred Cores: enabled

### Platform

- Re-Size BAR: enabled
- Above 4G Decoding: enabled
- CSM: disabled
- ErP: disabled
- Spread Spectrum: disabled
- VSOC must remain at or below 1.30 V; EXPO auto around 1.20 V was expected
- CPU/pump floor 40%, 100% by 80°C; case fans track CPU temperature

Save a new USB OC profile only after a stable reboot. Enable Memory Context Restore and Power Down together only after at least a week of clean stress, sleep, and cold-boot results.

Validate:

```bash
sudo dmidecode -t memory | grep -E 'Configured Memory Speed|Configured Clock Speed'
sensors | grep -E 'Tctl|Tdie'
stress-ng --cpu 32 --timeout 10m --metrics
```

## Phase 9 — services

Enable only units whose packages are installed and whose role is still wanted:

```bash
sudo systemctl enable --now bluetooth.service cups.service ufw.service
sudo systemctl enable docker.socket
sudo systemctl enable snapper-cleanup.timer

systemctl --user enable --now wireplumber.service pipewire.socket pipewire-pulse.socket
```

Omarchy manages networking, display/login, and audio defaults; do not replace them with the snapshot's historical service topology when current Omarchy differs.

## Final acceptance gate

Reboot, then paste:

```bash
set -euo pipefail

echo '== identity =='
hostnamectl

echo '== kernels and boot =='
uname -r
pacman -Q linux linux-lts linux-headers linux-lts-headers

echo '== GPU =='
nvidia-smi

echo '== zram =='
zramctl
swapon --show
sysctl vm.swappiness vm.page-cluster

echo '== filesystems =='
findmnt -t btrfs -o TARGET,SOURCE,FSTYPE,OPTIONS

echo '== desktop =='
hyprctl version
hyprctl monitors all
omarchy version
omarchy theme list | grep -i 'matte black' || true

echo '== services =='
systemctl --failed --no-pager
systemctl is-enabled paccache.timer snapper-cleanup.timer docker.socket ufw.service

echo '== toolchain =='
bash --version | head -1
git --version
node --version
npm --version
rustc --version
cargo --version
nvim --version | head -1
tmux -V

echo '== package drift =='
pacman -Qqe | sort > "$HOME/.local/state/white-deathstar/pacman-explicit.current.txt"
wc -l "$HOME/.local/state/white-deathstar/pacman-explicit.current.txt"
```

Acceptance criteria:

- Zero unexplained failed systemd units.
- RTX 5070 visible through `nvidia-smi` on the open driver path.
- LG 3440×1440 output at scale 1.
- zram approximately 15.4 GiB, zstd, higher priority than disk swap.
- Btrfs compression present; `noatime` on the intended subvolumes.
- Current and LTS kernels both bootable.
- Matte Black and JetBrainsMono Nerd Font active.
- Second SN8100 still empty/unmounted unless a later, separately reviewed storage plan authorizes its use.
- No TPM-anchor deletion, firmware clear, copied resume UUID/offset, copied credentials, or forced historical package downgrades.

Once this gate passes, create a new Snapper snapshot and record a fresh `pacman -Qqe`, `pacman -Q`, enabled-unit list, Omarchy revision/channel, dotfile tree, and project-head inventory. That new capture becomes the next source of truth.
