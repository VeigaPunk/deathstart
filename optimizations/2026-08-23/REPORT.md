# Optimization session — 2026-08-23

Overlay on the 2026-08-20 Omarchy **3.8.4** snapshot (`plazir27`). This directory is the NVMe / hibernate-resume / post-reboot catch-up drop. Privacy boundary of the repo applies: partition UUIDs redacted, no tokens, no SSH keys.

Live machine still has the 2026-08-20 user/root configs. This pass does **not** replace those files. It adds Limine resume-by-PARTUUID, a post-reboot `/scratch` unit, scoped passwordless sudo for that unit, and the M2_2 seat card.

## Hardware confirmed (delta)

| Item | State |
|---|---|
| Board | MSI MAG X870E TOMAHAWK WIFI (MS-7E59) v2.0 |
| BIOS | AMI 2.AC3 |
| Storage | 2× WD_BLACK SN8100 1 TB. OS is the original disk (kernel name **flipped** to `nvme1` after insert). Spare is M2_2 at Gen5 **x2** (USB4 live), btrfs `fastscratch` on `/scratch`. |
| Hibernate | Swapfile 30.3G on root btrfs. Live cmdline is `resume=PARTUUID=<redacted>` (not `/dev/nvme*`). |
| Kernel | `7.1.8-arch1-3` |
| Omarchy | `3.8.4` |

M2_2 vs USB4 (MSI spec): default with a drive in M2_2 is Gen5 **x2/x2** (USB4 stays up). Forcing M2_2 **x4** disables rear USB 40Gbps Type-C.

## Applied — Limine / resume

| Change | File | Result |
|---|---|---|
| Resume SSoT | `/etc/limine-entry-tool.d/resume.conf` | `resume=PARTUUID=<redacted> resume_offset=<redacted>` |
| Drop kernel-name resume | `/etc/default/limine` | last `resume=/dev/nvme0n1p2` `+=` line deleted; `root=` untouched |
| UKI regen | `limine-update` | `/boot/EFI/Linux/omarchy_linux.efi` + default `limine.conf` cmdline are PARTUUID. Snapshot #1 entry still has the old kernel-name resume (do not boot Snapshots for the insert). |
| Backups | `/etc/default/limine.bak.20260824T000257Z` and matching `resume.conf.bak.*` | rollback = copy back + `limine-update` |

Sanitized copies: `etc/limine.sanitized`, `etc/resume.conf.sanitized`. Host-local apply inputs (`etc/*.intended`) are gitignored.

## Applied — after-reboot catch-up

| Change | File | Result |
|---|---|---|
| Post-reboot script | `post-reboot-nvme.sh` | Root disk serial is **derived** at runtime. `--check` then provision **without** `--full-tmp`. Strips global `TMPDIR=/scratch/tmp`. Sets `XBRD_SPARK_ROOT=/scratch/xbrd-spark`. Skip if spare missing. Abort (no wipe) if spare is partitioned and not `fastscratch`. |
| systemd | `deathstart-nvme-post.service` | oneshot, enabled, `WantedBy=multi-user.target`, does not block boot |
| sudoers | `/etc/sudoers.d/deathstart-nvme` | NOPASSWD **only** the script + `systemctl start\|restart` of that unit. Not `ALL`. |
| BIOS card | `BIOS-SECOND-NVME.txt` | In-between: CSM/Fast Boot/RST off; M2_2 USB4 share; seat spare; boot normal UKI |

Live skip probe (no spare seated): `SKIP_NOT_INSERTED`, exit 0.

## Post-insert (same day, after M2_2 seat)

Insert + provision already ran this boot. Kernel names flipped; PARTUUID resume held. First `deathstart-nvme-post.service` attempt failed because `setup-fast-tmp.sh` lacked `+x`; a later `sudo -n` run formatted `fastscratch` and stamped `/var/lib/deathstart/nvme-post.done`.

Follow-up (no mkfs, no `--full-tmp`, no `@pkg` bind, no `CARGO_HOME` move):

| Change | Result |
|---|---|
| `/scratch` fstab | `nofail,x-systemd.device-timeout=8s` so boot does not stall if the spare is pulled |
| Unit | `After=home.mount`; skip path is idempotent; `reset-failed` on skip; live unit **active** |
| tmpfs | `/tmp` remains systemd `tmp.mount` (15.1G). Global `TMPDIR=/scratch/tmp` stays stripped |
| Spark I/O | `XBRD_SPARK_ROOT=/scratch/xbrd-spark` in `environment.d` + user systemd env. New spark files land on the spare NVMe. 43G leftover under `~/.local/share/xbrd-spark` **not** migrated |
| Consult quarantine | Deleted `~/.config/environment.d/99-durable-cache.conf` (`CARGO_HOME=/scratch/...` login landmine). `finish-durable-layout.sh` not executed |
| xask timeout | Host `XASK_TIMEOUT_SECS=0`; verify unit matches. Upstream: `xbrd-gdsp-fknpft` `00b5294`, `ds4cc-marketplace` `4c412fe` |

## Intentionally not done this pass

- `--full-tmp` (would mask `tmp.mount`)
- Pacman `@pkg` bind onto `/scratch`
- Relocating `CARGO_HOME` / `~/.cargo`
- Moving the 43G leftover `~/.local/share/xbrd-spark`
- BIOS M2_2 x4 (would kill rear USB4)
- Raising sekhmet 64 / io_uring
- `omarchy refresh` / `~/.local/share/omarchy/`
- Rewriting Snapper snapshot #1 cmdline
- Mixed RAM kit

## Verify (no secrets)

```
grep resume= /etc/limine-entry-tool.d/resume.conf   # PARTUUID, not /dev/nvme
grep resume= /etc/default/limine                    # none (SSoT comment only)
tr ' ' '\n' </proc/cmdline | grep resume            # PARTUUID
systemctl is-enabled deathstart-nvme-post.service   # enabled
systemctl is-active deathstart-nvme-post.service    # active (exited)
sudo -n /home/vgpnk/Projects/deathstart/optimizations/2026-08-23/post-reboot-nvme.sh
# → SKIP already done + /scratch mounted
findmnt -n /scratch /tmp
# /scratch = spare NVMe btrfs; /tmp = tmpfs
grep nofail /etc/fstab
test ! -f ~/.config/environment.d/99-durable-cache.conf
```
