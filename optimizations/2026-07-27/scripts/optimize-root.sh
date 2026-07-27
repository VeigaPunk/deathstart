#!/usr/bin/env bash
# optimize-root.sh — root-level optimizations for plazir27 (2026-07-27)
# Generated after full-system audit. Every section is independent; comment out
# what you don't want. Run: sudo bash ~/optimize-root.sh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo"; exit 1; }

echo "== [1/8] TPM re-provision (fixes the 5 failed systemd TPM units) =="
# Root cause: fTPM state changed during the BIOS-tuning session; the SRK/NvPCR
# anchor keys under /var/lib/systemd no longer belong to this TPM
# ("TPM key integrity check failed"). Deleting the stale anchors lets systemd
# re-provision cleanly. Nothing consumes these PCRs today (no LUKS, SB off),
# so this is purely hygiene + keeps future TPM enrollment possible.
systemctl stop systemd-tpm2-setup-early systemd-tpm2-setup systemd-pcrproduct 2>/dev/null || true
rm -f /var/lib/systemd/tpm2-srk-public-key.pem /var/lib/systemd/tpm2-srk-public-key.tpm2b_public
rm -rf /var/lib/systemd/nvpcr
systemctl restart systemd-tpm2-setup-early systemd-tpm2-setup systemd-pcrproduct || true
systemctl reset-failed 'systemd-pcrlogin@*' 2>/dev/null || true  # re-runs at next login
systemctl --no-pager --failed | head -8

echo "== [2/8] zram: 4G -> 15G (ram/2) + zram-friendly VM sysctls =="
# 4G zram is undersized for 30G RAM + parallel agent workloads. The 30G
# hibernation swapfile stays at pri 0 (zram pri 100 always wins while awake).
cat > /etc/systemd/zram-generator.conf <<'EOF'
[zram0]
compression-algorithm = zstd
zram-size = ram / 2
EOF
cat > /etc/sysctl.d/99-zram-tuning.conf <<'EOF'
vm.swappiness = 100
vm.page-cluster = 0
EOF
sysctl -p /etc/sysctl.d/99-zram-tuning.conf
systemctl daemon-reload
echo "(zram resizes on next reboot)"

echo "== [3/8] makepkg: parallel builds (was effectively -j1/-j2 on a 32-thread 9950X) =="
cat > /etc/makepkg.conf.d/99-parallel.conf <<'EOF'
MAKEFLAGS="-j$(nproc)"
NINJAFLAGS="-j$(nproc)"
EOF

echo "== [4/8] fstab: relatime -> noatime on btrfs (fewer metadata writes, snapper-friendly) =="
cp -a /etc/fstab "/etc/fstab.bak.$(date +%s)"
sed -i 's/\brw,relatime,compress=zstd:3/rw,noatime,compress=zstd:3/g' /etc/fstab
grep btrfs /etc/fstab
systemctl daemon-reload
echo "(remounts on reboot; or: mount -o remount /  etc.)"

echo "== [5/8] pacman cache: install paccache timer + trim now (9.6G cached) =="
pacman -S --needed --noconfirm pacman-contrib
systemctl enable --now paccache.timer
paccache -rk2   # keep 2 versions
paccache -ruk0  # drop uninstalled packages

echo "== [6/8] resolved: disable LLMNR (MulticastDNS already off) =="
cat > /etc/systemd/resolved.conf.d/11-disable-llmnr.conf <<'EOF'
[Resolve]
LLMNR=no
EOF
systemctl restart systemd-resolved

echo "== [7/8] Limine: menu timeout -> 2s (keeps the LTS parachute reachable) =="
LIMINE_CONF=""
for f in /boot/limine.conf /boot/limine/limine.conf /boot/EFI/limine/limine.conf /boot/EFI/BOOT/limine.conf; do
  [[ -f $f ]] && LIMINE_CONF=$f && break
done
if [[ -n $LIMINE_CONF ]]; then
  cp -a "$LIMINE_CONF" "${LIMINE_CONF}.bak.$(date +%s)"
  if grep -qiE '^\s*timeout' "$LIMINE_CONF"; then
    sed -i -E 's/^(\s*[Tt]imeout:?\s*=?\s*)[0-9]+/\12/' "$LIMINE_CONF"
  else
    sed -i '1i timeout: 2' "$LIMINE_CONF"
  fi
  grep -iE 'timeout' "$LIMINE_CONF"
else
  echo "  !! limine.conf not found — check bootctl / ESP layout manually"
fi

echo "== [8/8] NVIDIA suspend/hibernate stack (needed before Phase-2 hibernate is useful) =="
# Without PreserveVideoMemoryAllocations + these services, resume-from-disk
# comes back with corrupted VRAM on Wayland. /var/tmp has 700G+ free for spill.
cat > /etc/modprobe.d/nvidia-power.conf <<'EOF'
options nvidia NVreg_PreserveVideoMemoryAllocations=1 NVreg_TemporaryFilePath=/var/tmp
EOF
systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service
systemctl enable --now nvidia-persistenced.service 2>/dev/null || true

echo
echo "== DONE. Reboot recommended (zram size, noatime, nvidia modprobe). =="
echo "Remaining manual steps (see report): LTS boot test -> phase-2 hibernate,"
echo "BIOS: MCR+PowerDown after stability week, BIOS 2.AC0 vs notes' 2.AC3."

# ---------------------------------------------------------------------------
# OPTIONAL (commented out — destructive/opinionated; uncomment deliberately)
# ---------------------------------------------------------------------------
# ## A) Put the idle 2nd SN8100 (nvme1n1, 1TB, EMPTY) to work as backup+scratch:
# parted -s /dev/nvme1n1 mklabel gpt mkpart primary 1MiB 100%
# mkfs.btrfs -L vault /dev/nvme1n1p1
# mkdir -p /mnt/vault && mount /dev/nvme1n1p1 /mnt/vault
# btrfs subvolume create /mnt/vault/@backup   # snapper send/receive target
# btrfs subvolume create /mnt/vault/@scratch  # builds, docker, HF cache
# echo "LABEL=vault /mnt/vault btrfs rw,noatime,compress=zstd:3,ssd,discard=async 0 0" >> /etc/fstab
# ## then: btrfs send of snapper snapshots (btrbk recommended: pacman -S btrbk)
#
# ## B) Reclaim 12.1G — unreferenced gpt-oss-20b HF download (verify you're done with it):
# # rm -rf /home/vhpnk/.cache/huggingface/hub/models--ggml-org--gpt-oss-20b-GGUF
