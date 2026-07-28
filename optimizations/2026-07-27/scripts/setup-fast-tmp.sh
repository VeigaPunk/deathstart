#!/usr/bin/env bash
# setup-fast-tmp.sh — provision an explicitly selected disk as fast scratch space
# Preflight only (safe, unprivileged):
#   bash setup-fast-tmp.sh --disk /dev/disk/by-id/<stable-whole-disk-id> --check
# Provision after reviewing preflight output:
#   sudo bash setup-fast-tmp.sh --disk /dev/disk/by-id/<stable-whole-disk-id>
set -euo pipefail

MNT=/scratch
FULL_TMP=0
CHECK_ONLY=0
DISK_BY_ID=""

usage() {
  cat <<'EOF'
Usage:
  setup-fast-tmp.sh --disk /dev/disk/by-id/<stable-whole-disk-id> [--full-tmp] [--check]

Arguments:
  --disk      Explicit path under /dev/disk/by-id (required; no positional form).
  --full-tmp  Configure /tmp to move onto the scratch subvolume after reboot.
  --check     Run every pre-mutation safety check, then exit without changing anything.
EOF
}

abort() {
  echo "ABORT: $*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --disk)
      [[ $# -ge 2 && -n "${2:-}" ]] || abort "--disk requires a /dev/disk/by-id path"
      [[ -z "$DISK_BY_ID" ]] || abort "--disk provided more than once"
      DISK_BY_ID=$2
      shift 2
      ;;
    --full-tmp)
      FULL_TMP=1
      shift
      ;;
    --check)
      CHECK_ONLY=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --*)
      abort "unknown option: $1"
      ;;
    *)
      abort "positional targets are forbidden; use --disk /dev/disk/by-id/<stable-whole-disk-id>"
      ;;
  esac
done

[[ -n "$DISK_BY_ID" ]] || abort "missing required --disk /dev/disk/by-id/<stable-whole-disk-id>"
[[ "$DISK_BY_ID" == /dev/disk/by-id/* ]] || abort "target must be under /dev/disk/by-id"
[[ "$DISK_BY_ID" != *'*'* && "$DISK_BY_ID" != *'?'* && "$DISK_BY_ID" != *'['* ]] || \
  abort "wildcards are forbidden in the by-id target"
[[ "${DISK_BY_ID#/dev/disk/by-id/}" != */* ]] || abort "target must be a direct child of /dev/disk/by-id"
[[ -L "$DISK_BY_ID" ]] || abort "target is not a /dev/disk/by-id symlink"

DISK=$(readlink -e -- "$DISK_BY_ID") || abort "target does not resolve"
[[ -b "$DISK" ]] || abort "target does not resolve to a block device"
[[ $(lsblk -dnro TYPE -- "$DISK") == disk ]] || abort "target must resolve to a whole disk"

mapfile -t DEVICE_NODES < <(lsblk -nrpo NAME -- "$DISK")
[[ ${#DEVICE_NODES[@]} -eq 1 && "${DEVICE_NODES[0]}" == "$DISK" ]] || \
  abort "target already has partitions or dependent block-device children"

if [[ -n $(wipefs --noheadings --output TYPE -- "$DISK" 2>/dev/null) ]]; then
  abort "target contains a filesystem, RAID, or partition-table signature"
fi
if lsblk -nrpo MOUNTPOINTS -- "$DISK" | tr -d '[:space:]' | grep -q .; then
  abort "target or one of its children is mounted"
fi

KNAME=$(lsblk -dnro KNAME -- "$DISK")
shopt -s nullglob
HOLDERS=("/sys/class/block/$KNAME/holders/"*)
shopt -u nullglob
[[ ${#HOLDERS[@]} -eq 0 ]] || abort "target has active device-mapper/RAID holders"

ROOT_SOURCE=$(findmnt -n -o SOURCE / 2>/dev/null || true)
ROOT_SOURCE=${ROOT_SOURCE%%\[*}
[[ "$ROOT_SOURCE" == /dev/* && -b "$ROOT_SOURCE" ]] || \
  abort "cannot unambiguously determine the root filesystem block source"
mapfile -t ROOT_DISKS < <(lsblk -snrpo NAME,TYPE -- "$ROOT_SOURCE" | while read -r node type; do
  [[ "$type" == disk ]] && printf '%s\n' "$node"
done)
[[ ${#ROOT_DISKS[@]} -gt 0 ]] || abort "cannot determine the root backing disk"
for root_disk in "${ROOT_DISKS[@]}"; do
  [[ "$DISK" != "$root_disk" ]] || abort "target is a root backing disk"
done

echo "==> Safety gate passed: $DISK_BY_ID -> $DISK"
lsblk -f -- "$DISK"
if [[ "$CHECK_ONLY" == 1 ]]; then
  echo "DONE (check mode). No destructive operations were executed."
  exit 0
fi

[[ $EUID -eq 0 ]] || abort "provisioning requires root; rerun the reviewed command with sudo"
TARGET_USER=${SUDO_USER:-root}
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
[[ -n "$TARGET_HOME" ]] || abort "cannot determine the invoking user's home directory"
TARGET_GROUP=$(id -gn "$TARGET_USER")

echo "==> 1. Partition (single GPT Linux partition)"
sfdisk --wipe always -- "$DISK" <<'EOF'
label: gpt
size=,type=linux
EOF
partprobe -- "$DISK"
udevadm settle
mapfile -t PARTITIONS < <(lsblk -nrpo NAME,TYPE -- "$DISK" | while read -r node type; do
  [[ "$type" == part ]] && printf '%s\n' "$node"
done)
[[ ${#PARTITIONS[@]} -eq 1 ]] || abort "expected exactly one partition after provisioning"
PART=${PARTITIONS[0]}

echo "==> 2. Format btrfs"
mkfs.btrfs -f -L fastscratch -- "$PART"

echo "==> 3. Mount at $MNT (zstd compression, noatime)"
mkdir -p "$MNT"
mount -o compress=zstd:3,noatime -- "$PART" "$MNT"

echo "==> 4. Persist in fstab"
UUID=$(blkid -s UUID -o value -- "$PART")
grep -qF "UUID=$UUID " /etc/fstab || cat >> /etc/fstab <<EOF

# Fast scratch (setup-fast-tmp.sh $(date +%F))
UUID=$UUID $MNT btrfs compress=zstd:3,noatime 0 0
EOF

echo "==> 5. Migrate existing heavy tmp consumers"
mkdir -p "$MNT/opencode" "$MNT/archive" "$MNT/tmp"
chmod 1777 "$MNT/tmp"
if [[ -d /tmp/opencode && ! -L /tmp/opencode ]]; then
  shopt -s nullglob dotglob
  OPENCODE_FILES=(/tmp/opencode/*)
  ((${#OPENCODE_FILES[@]} == 0)) || mv -- "${OPENCODE_FILES[@]}" "$MNT/opencode/"
  shopt -u nullglob dotglob
  rmdir /tmp/opencode
  ln -s "$MNT/opencode" /tmp/opencode
fi
if [[ -d "$TARGET_HOME/tmp-archive" ]]; then
  shopt -s nullglob dotglob
  ARCHIVE_FILES=("$TARGET_HOME/tmp-archive/"*)
  ((${#ARCHIVE_FILES[@]} == 0)) || mv -- "${ARCHIVE_FILES[@]}" "$MNT/archive/"
  shopt -u nullglob dotglob
  rmdir "$TARGET_HOME/tmp-archive"
fi

echo "==> 6. TMPDIR for future shells and systemd user sessions"
cat > /etc/profile.d/fast-tmp.sh <<'EOF'
export TMPDIR=/scratch/tmp
EOF
install -d -m 0755 -o "$TARGET_USER" -g "$TARGET_GROUP" "$TARGET_HOME/.config/environment.d"
cat > "$TARGET_HOME/.config/environment.d/99-fast-tmp.conf" <<'EOF'
TMPDIR=/scratch/tmp
EOF
chown "$TARGET_USER:$TARGET_GROUP" "$TARGET_HOME/.config/environment.d/99-fast-tmp.conf"

echo "==> 7. Housekeeping: auto-clean scratch files older than 7 days"
cat > /etc/tmpfiles.d/fast-scratch.conf <<EOF
d /scratch/tmp 1777 root root 7d
d /scratch/opencode 0755 $TARGET_USER $TARGET_GROUP 7d
EOF

if [[ "$FULL_TMP" == 1 ]]; then
  echo "==> 8. Configure the scratch disk for /tmp after reboot"
  btrfs subvolume create "$MNT/roottmp"
  grep -qF "UUID=$UUID /tmp " /etc/fstab || cat >> /etc/fstab <<EOF
UUID=$UUID /tmp btrfs compress=zstd:3,noatime,subvol=/roottmp 0 0
EOF
  systemctl mask tmp.mount
fi

echo "DONE. Verify with: df -h $MNT"
df -h "$MNT"
