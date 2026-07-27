# Optimization session — 2026-07-27

Full-system audit (3 parallel agents: board-topology scout, Hyprland/Omarchy audit,
agent-tooling/storage audit) followed by applied fixes. This directory snapshots the
changed files. Privacy boundary of this repo applies: UUIDs sanitized, no tokens.

## Applied — user level (verified live)

| Change | File | Result |
|---|---|---|
| waybar `custom/agent-wall` polled a 26MB binary every 12ms | `applied/waybar/config.jsonc` (`interval: 0.012 -> 2`) | waybar CPU 12% -> 0.2% |
| Gemma GGUF duplicated (ollama blob was a physical copy of the source gguf) | btrfs `cp --reflink=always` over the blob | 13.4G freed (186G -> 173G used); model + proxy services verified healthy |
| NVIDIA env vars lived in `envs.conf`, which the Lua config chain never loads (Omarchy-alpha conf->lua migration gap; upstream `nvidia.sh` writes `envs.lua` that nothing `require`s) | `applied/hypr/hyprland.lua` (`hl.env` NVD_BACKEND/LIBVA/__GLX_VENDOR) | takes effect at next session login |
| `GDK_SCALE=2` contradicted monitor scale 1.0 on 3440x1440 ultrawide | `applied/hypr/monitors.lua` (both scales = 1) | next login |
| Duplicate GitLab token stanza; duplicate `. ~/.local/bin/env` | `applied/.bashrc`, `applied/.bash_profile` | `bash -n` clean |
| Deleted: 10 stale `.bak` configs, dead `hyprland.conf` fallback stub (foreign kitty/dolphin binds), `envs.conf`, 174M heapsnapshots (`~/server.heapsnapshot`, `~/tui.heapsnapshot`), 751M `.grok` plugin `target/debug`, `~/.bashrc.bak.*` | — | ~1G freed + booby-trapped fallback removed |

## Applied — root level (`scripts/optimize-root.sh`, run via pkexec)

1. **TPM re-provision** — root cause: fTPM state changed during the BIOS-tuning
   session; stale SRK/NvPCR anchors ("TPM key integrity check failed").
   First pass insufficient: `/run/systemd/nvpcr/nvpcr-anchor.cred` +
   `/run/systemd/tpm2-srk-*` runtime copies also stale (`scripts/tpm-fix.sh`).
   After purging both persisted and runtime anchors: **all 5 failed units
   recovered, zero failed units system-wide.** No TPM clear needed.
2. **zram 4G -> 15G** (`ram / 2`) + `vm.swappiness=100`, `vm.page-cluster=0`
   (`etc/zram-generator.conf`, `etc/99-zram-tuning.conf`). Hibernation swapfile
   untouched at pri 0. zram resizes at next reboot.
3. **makepkg parallelism** — AUR builds were at default `-j2` on a 32-thread
   9950X (`etc/99-parallel.conf`: `-j$(nproc)`).
4. **btrfs `relatime` -> `noatime`** on all four mounts (`etc/fstab.sanitized`).
5. **pacman-contrib + `paccache.timer`** enabled; cache trimmed (cache was
   ~9.6G of mostly-current packages; timer keeps it bounded).
6. **LLMNR disabled** (`etc/11-disable-llmnr.conf`; MulticastDNS already off).
7. **Limine menu timeout -> 2s** (was implicit 5s default; loader phase was
   6.8s of every boot). Menu remains reachable for the LTS parachute entry.
8. **NVIDIA hibernate stack** — `NVreg_PreserveVideoMemoryAllocations=1` +
   `NVreg_TemporaryFilePath=/var/tmp` (`etc/nvidia-power.conf`);
   `nvidia-suspend/hibernate/resume` enabled; `nvidia-persistenced` enabled+active.
   Module option lands in initramfs at the next rebuild (deliberately not
   forcing `limine-mkinitcpio` per remediation HANDOFF constraint).

## Remaining queue (manual, ordered)

1. Boot LTS entry once -> `sudo bash ~/plazir27-remediation/fix-phase2-hibernate.sh --apply`
   (cmdline still carries fragile `resume=/dev/nvme0n1p2`).
2. BIOS: notes target 2.AC3, board runs 2.AC0 -> flash, apply MAXPERF profile, save USB
   profile. After stability week: Memory Context Restore + Power Down Enable
   (firmware boot phase is 42.5s, dominated by DDR5 retraining).
3. nvme1n1 (2nd SN8100 1TB) is empty; no second-copy backup exists. Optional section A
   of `optimize-root.sh` formats it as btrfs `@backup` (btrbk/snapper send target)
   + `@scratch`.
4. Optional reclaim: 12.1G unreferenced gpt-oss-20b HF cache (script section B),
   2G Trash, opencode.db VACUUM (needs opencode closed), 1.2G llama.cpp experiment
   build in Downloads.
5. Ollama: `OLLAMA_NUM_PARALLEL=2` doubles KV allocation while the proxy is a
   single lane -> drop-in `OLLAMA_NUM_PARALLEL=1`; measure offload split
   (`ollama ps`) before pinning `num_gpu` (14.4G model vs 12.2G VRAM).

## Spare-parts verdict (scout-verified against board manual)

- MAG X870E TOMAHAWK WIFI: PCI_E1 Gen5 x16 (CPU) has **no lane sharing** with
  anything. 4x M.2 (M2_1/M2_2 CPU Gen5, M2_3/M2_4 chipset Gen4) + second GPU in
  PCI_E3 (Gen4 x4 chipset) all coexist at full GPU bandwidth.
- SN750s -> M2_3/M2_4: full Gen3 x4 speed, zero impact.
- RX 6600 XT: Ollama cannot span one model across CUDA+Vulkan (verified in
  `server/sched.go` ByLibrary placement), but runs separate models per GPU —
  5070/CUDA main + 6600XT/Vulkan small agent model fits the swarm workflow.
  llama.cpp Vulkan `--split-mode layer` does mixed-vendor spanning (12+8GB
  holds the 14.4G model fully) — benchmark vs current CUDA+CPU-offload before
  committing. Idle cost ~3W. Sell only if unused after trial.

## Reported-only (deliberate non-actions)

130px waybar height (160 effective), `MINUS` key types ".", `F5` git-clones
a repo, tokens in `environment.d` propagate to every process, VRR off on a
160Hz FreeSync panel (`misc:vrr=2` candidate), idle 150s/152s is stock Omarchy.
Upstream bug to report: Omarchy `nvidia.sh` appends env to `~/.config/hypr/envs.lua`
which no code path loads.
