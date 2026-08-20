# Optimization session — 2026-08-20

Clean Omarchy **3.8.4** reinstall on `plazir27` after CMOS clear. Quattro (`4.0.0.alpha`) was unstable; 3.8.4 is the daily driver. This directory is the live config snapshot. Privacy boundary of the repo applies: UUIDs redacted, no tokens, no SSH keys, no browser profiles.

Configs are Hyprland **`.conf`**, not the Quattro Lua overlays in `optimizations/2026-07-27/applied/hypr/`. Do not copy those Lua files onto 3.8.4.

## Hardware confirmed

| Item | State |
|---|---|
| Board | MSI MAG X870E TOMAHAWK WIFI (MS-7E59) v2.0 |
| BIOS | AMI 2.AC3, 2026-06-25 |
| CPU | Ryzen 9 9950X 16C/32T |
| RAM | 2×16 GB Kingston `KF560C30-16` in A2+B2, **configured 6000 MT/s** |
| DMI voltage | reports 1.1 V (ignore; EXPO Profile 1 is 1.40 V in BIOS) |
| GPU | RTX 5070, driver 610.57.04, CUDA 13.3, 12227 MiB |
| Display | LG UltraWide `DP-1` 3440×1440 @ 100 Hz, scale 1.0, `GDK_SCALE=1` |
| Storage | 1× WD_BLACK SN8100 1 TB (second SN8100 removed — probe errors at boot) |
| Kernel | `7.1.8-arch1-3` |
| Omarchy | git tag v3.8.4 (version file still prints `3.8.3`) |

### BIOS (memory half only; rest stock)

- EXPO Profile 1 (DDR5-6000 CL30 1.40 V)
- FCLK 2000 MHz (not 2100)
- UCLK = MEMCLK (1:1)
- High-Efficiency Mode = Auto (not Tighter)
- Latency Killer = Enabled
- Memory Context Restore = Disabled
- Power Down Enable = Disabled

Leave MCR + Power Down off until a boring week. Do not apply the full `X870E_TOMAHAWK_MAX_PERF.txt` PBO profile until 3.8.4 itself stays boring.

## Applied — user level

| Change | File | Result |
|---|---|---|
| Ultrawide 1x @ 100 Hz | `applied/hypr/monitors.conf` | `GDK_SCALE=1`, `DP-1, 3440x1440@100, 0x0, 1`. Super+Space Walker was huge until session restart (`GDK_SCALE` is login-time). |
| Terminals 9pt → 13pt | alacritty / ghostty / kitty / foot | Same 13pt deathstart used on this panel at 1x. |
| Waybar readable | `applied/waybar/` | 16px font, 32px height (was 12px / 26px). |
| GTK / Walker | gsettings | Adwaita Sans/Mono 13 (not a file). |
| SwayOSD | `applied/swayosd/style.css` | 13pt. |
| Input | `applied/hypr/input.conf` | Stock Omarchy already matched: `kb_layout=br`, Caps=Compose, repeat 40/250. |
| NVIDIA env | `applied/hypr/envs.conf` | 3.8.4 loads `envs.conf` (Quattro Lua did not). `NVD_BACKEND=direct`, `LIBVA_DRIVER_NAME=nvidia`, `__GLX_VENDOR_LIBRARY_NAME=nvidia`. |
| Node | `applied/mise/config.toml` | mise `node 26.5.0`. Do **not** restore the old fnm `.bashrc` block. |
| GitHub | — | `gh` as `VeigaPunk` (HTTPS, keyring). SSH ed25519 `plazir27 3.8.4`. Keys are **not** in this repo. |

## Applied — root level

| Change | File | Result |
|---|---|---|
| Snapper `root` only | Limine `SNAPPER_CONFIG_NAME=root` | `/.snapshots` exists. Snapshot #1 labeled `3.8.3` (version-file quirk). `snapper-cleanup.timer` on. No `/home` snapshots. `limine-snapper-sync` uses the Snapper plugin (`inotify-tools` not installed). |
| makepkg 32 threads | `etc/99-parallel.conf` | `MAKEFLAGS`/`NINJAFLAGS=-j$(nproc)` |
| Btrfs `noatime` | `etc/fstab.sanitized` | `/` `/home` `/var/log` `/var/cache/pacman/pkg`. `/boot` vfat stays `relatime`. |
| paccache | — | `pacman-contrib` + `paccache.timer` (Mondays 00:00). |
| LLMNR off | `etc/11-disable-llmnr.conf` | Omarchy already had mDNS off. Optional LAN hygiene. |
| NVIDIA sleep | `etc/nvidia-power.conf` + units | `NVreg_PreserveVideoMemoryAllocations=1` → `/var/tmp`. persistenced + suspend/hibernate/resume enabled. **Module option needs a reboot** to attach (persistenced is already live). Do not drop `nvidia_drm modeset=1` in `nvidia.conf`. |
| zram `ram/2` | `etc/zram-generator.conf` + `etc/99-zram-tuning.conf` | zram **15.1G** zstd pri 100. Hibernate swapfile 30.3G pri 0 untouched. `vm.swappiness=100`, `vm.page-cluster=0`. |

## Intentionally not restored from 2026-07-27

- Quattro Hyprland Lua (`hyprland.lua`, `monitors.lua`, …)
- fnm `.bashrc` (3.8.4 uses mise)
- Godspeed / OpenCode / hvm-gemma4 exports
- Waybar `custom/agent-wall` (was a 12% CPU poll)
- Second SN8100 provisioning
- Full MAXPERF PBO / FCLK 2100 / High-Efficiency Tighter
- Hibernate `resume=` PARTUUID rewrite (cmdline still uses `/dev/nvme0n1p2`; fragile if you hibernate)
- Ollama / Gemma stack

## Verify (no secrets)

```
GDK_SCALE=1
hyprctl monitors → 3440x1440@100 scale 1
zramctl → 15.1G zstd [SWAP] pri 100
nvidia-smi Persistence Mode → Enabled
sudo snapper list-configs → root | /
```
