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

## Round 2 — validation & benchmarks (same day, later session)

**All root-script items verified live:** zram 15.4G zstd pri-100 ✓, swappiness
100 / page-cluster 0 ✓, noatime+compress+discard=async on all btrfs mounts ✓
(fstrim.timer disabled is correct with discard=async), makepkg -j32 ✓, LLMNR
off ✓, paccache.timer ✓, TPM units clean (0 failed) ✓, nvidia
suspend/hibernate/resume + persistenced enabled, PreserveVideoMemoryAllocations
set ✓. BIOS confirmed **2.AC3** (matches MAXPERF notes — version worry closed).

**Phase-1 parachute gate: PASSED.** journalctl boots -1/-3 ran 6.18.40-2-lts.
Phase-2 hibernate fix is unblocked (the resume configuration still used an
unstable kernel device name this boot; do NOT hibernate until phase-2 --apply).

| Test | Result | Verdict |
|---|---|---|
| All-core sha256 (openssl -multi 32) | 62.9 GB/s, ~5.10 GHz all-core | PBO healthy |
| Tctl under all-core load | 95.0°C (rides PBO ceiling) | expected; cooling is the limiter |
| Cooldown after burn | 60°C within ~1 min | fine |
| 1T pinned boost | 5.53–5.87 GHz observed | +200 offset active |
| fio seqread 1M QD8 (btrfs file) | 7.2 GB/s | SN8100 healthy through FS |
| fio randread 4k QD32 1 job / 8 jobs | 29.4k / 128k IOPS | per-thread btrfs O_DIRECT overhead, not drive |
| fio randwrite 4k QD32 | 67.8k IOPS (278 MB/s) | btrfs CoW path, normal |
| NVMe temps under IO | 25–30°C | excellent |
| LAN / Quad9 RTT | 1.2 ms / 11.1 ms, 2.5GbE | healthy |
| GPU idle | 23W P3 34°C, driver 610.43.03 open | healthy |
| Boot | fw 44.1s + loader 3.8s + kernel 5.3s + user 3.8s | fw = memory training (MCR off by design until ~Aug 2) |

**Open queue (root, in order):**
1. `sudo bash ~/plazir27-remediation/fix-phase2-hibernate.sh --apply` (gate passed)
2. `sudo paccache -rk2 && sudo paccache -ruk0` (cache 9.6G)
3. `sudo pacman -Syu` (25 pending)
4. ~Aug 2 if stable: BIOS → Memory Context Restore + Power Down Enable (kills ~30s of the 44s firmware time)
5. Optional: 12G `~/.cache/huggingface/hub/models--ggml-org--gpt-oss-20b-GGUF` still present — delete when confirmed done
6. Optional: provision empty 2nd SN8100 (optional section A of optimize-root.sh)

## Round 2 — execution (pkexec batch, 09:31)

1. **Phase-2 hibernate fix APPLIED.** Stable partition identity and resume offset
   in limine drop-in; no /dev/ path survives; UKIs rebuilt twice (script + pacman
   hook) with the fix baked in. Undo pair: `/root/plazir27-backup-2026-07-27/`.
2. Snapper pre-update snapshot created.
3. paccache: zero prune candidates — 10G cache is legitimately 2 versions/pkg
   (rollback policy). `-rk1` would halve it if space ever matters.
4. **25/25 packages upgraded** (no kernel bump; running 7.1.5 still matches
   installed). Limine redeployed, walker/elephant restarted, 0 failed units.
5. /boot 48% used, both UKIs present.

**Pending user actions:** reboot → run the 4 hibernate checks → `systemctl
hibernate` test. Then ~Aug 2: BIOS MCR + Power Down. Optional: 12G HF cache
delete, 2nd SN8100 provisioning.

### Round 2 publication safety gate

`scripts/setup-fast-tmp.sh` now accepts only an explicit
`--disk /dev/disk/by-id/<stable-whole-disk-id>` target. Before `sfdisk`, it
rejects wildcard or indirect paths, non-disks, existing children/signatures,
mounts, active holders, and every discovered root backing disk. `--check` exits
after the complete preflight gate, and `tests/setup-fast-tmp-test.sh` verifies
argument failures plus static mutation ordering without sudo or block writes.
Raw kernel NVMe names were also removed from the optional root-script example.
