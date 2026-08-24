#!/usr/bin/env bash
# After-boot auto setup for the spare SN8100 (M2_2).
# Idempotent. Never --full-tmp. Never touches the OS SN8100 serial.
# Run as root (systemd) or: sudo /home/vgpnk/Projects/deathstart/optimizations/2026-08-23/post-reboot-nvme.sh
set -euo pipefail

SETUP=/home/vgpnk/Projects/deathstart/optimizations/2026-07-27/scripts/setup-fast-tmp.sh
MNT=/scratch
LOG=/var/log/deathstart-nvme-post.log
STAMP_FILE=/var/lib/deathstart/nvme-post.done
SPARK_ENV=/home/vgpnk/.config/environment.d/92-xbrd-spark-root.conf
TARGET_USER=vgpnk

root_src=$(findmnt -n -o SOURCE / 2>/dev/null || true)
root_src=${root_src%%\[*}
root_disk=$(lsblk -snrpo NAME,TYPE -- "$root_src" 2>/dev/null | awk '$2=="disk"{print $1; exit}')
[[ -n $root_disk ]] || { echo "ABORT cannot find root backing disk" >&2; exit 2; }
root_kname=$(lsblk -dnro KNAME -- "$root_disk")
root_ctrl=${root_kname%n*}
OS_SERIAL=$(tr -d '[:space:]' < "/sys/class/nvme/${root_ctrl}/serial")
OS_BYID=/dev/disk/by-id/nvme-WD_BLACK_SN8100_1000GB_${OS_SERIAL}

log() { echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) $*" | tee -a "$LOG"; }

if [[ $EUID -ne 0 ]]; then
	exec sudo -n "$0" "$@"
fi

mkdir -p /var/lib/deathstart "$(dirname "$LOG")"
touch "$LOG"
chmod 644 "$LOG" || true

log "start pid=$$"

if [[ -f $STAMP_FILE ]] && findmnt -n "$MNT" >/dev/null 2>&1; then
	log "SKIP already done ($(cat "$STAMP_FILE")) and $MNT mounted"
	exit 0
fi

command -v udevadm >/dev/null && udevadm settle --timeout=30 || true
sleep 2

if [[ ! -e $OS_BYID ]]; then
	log "ABORT OS by-id missing: $OS_BYID"
	exit 2
fi
OS_DISK=$(readlink -e -- "$OS_BYID")
log "OS disk $OS_BYID -> $OS_DISK serial=$OS_SERIAL"

mapfile -t SPARES < <(
	find /dev/disk/by-id -maxdepth 1 -type l -name 'nvme-WD_BLACK_SN8100_1000GB_*' \
		! -name '*-part*' ! -name '*_1' 2>/dev/null | sort
)

NEW=()
for p in "${SPARES[@]}"; do
	base=${p##*/}
	ser=${base#nvme-WD_BLACK_SN8100_1000GB_}
	if [[ $ser == "$OS_SERIAL" ]]; then
		continue
	fi
	NEW+=("$p")
done

n_nvme=$(find /sys/class/nvme -mindepth 1 -maxdepth 1 | wc -l)
log "nvme_class_count=$n_nvme spare_candidates=${#NEW[@]} ${NEW[*]:-none}"

if [[ ${#NEW[@]} -eq 0 ]]; then
	log "SKIP_NOT_INSERTED (no extra SN8100 by-id). Seat M2_2 and reboot."
	exit 0
fi
if [[ ${#NEW[@]} -ne 1 ]]; then
	log "ABORT more than one extra SN8100; will not guess. ${NEW[*]}"
	exit 2
fi

DISK_BY_ID=${NEW[0]}
DISK=$(readlink -e -- "$DISK_BY_ID") || {
	log "ABORT cannot resolve $DISK_BY_ID"
	exit 2
}
[[ $DISK == "$OS_DISK" ]] && {
	log "ABORT resolved spare equals OS disk"
	exit 2
}
log "spare $DISK_BY_ID -> $DISK"

if [[ ! -x $SETUP ]]; then
	log "ABORT missing $SETUP"
	exit 2
fi

CHECK_OUT=/var/lib/deathstart/last-check.txt
set +e
bash "$SETUP" --disk "$DISK_BY_ID" --check >"$CHECK_OUT" 2>&1
rc=$?
set -e
tee -a "$LOG" <"$CHECK_OUT"

if [[ $rc -eq 0 ]]; then
	log "check empty; provisioning WITHOUT --full-tmp"
	export SUDO_USER=$TARGET_USER
	bash "$SETUP" --disk "$DISK_BY_ID"
	rm -f /etc/profile.d/fast-tmp.sh
	rm -f /home/$TARGET_USER/.config/environment.d/99-fast-tmp.conf
	log "stripped global TMPDIR=/scratch/tmp (keep system tmpfs /tmp)"
else
	if grep -q 'already has partitions' "$CHECK_OUT"; then
		LABEL=$(lsblk -dnro LABEL "$DISK" 2>/dev/null || true)
		FSTYPE=$(lsblk -dnro FSTYPE "$DISK" 2>/dev/null || true)
		# partitioned whole-disk: look at first partition
		PART=$(lsblk -nrpo NAME,TYPE "$DISK" | awk '$2=="part"{print $1; exit}')
		if [[ -n ${PART:-} ]]; then
			LABEL=$(lsblk -dnro LABEL "$PART" 2>/dev/null || true)
			FSTYPE=$(lsblk -dnro FSTYPE "$PART" 2>/dev/null || true)
			UUID=$(blkid -s UUID -o value -- "$PART" || true)
		fi
		log "partitioned spare label=${LABEL:-none} fstype=${FSTYPE:-none} part=${PART:-none}"
		if [[ ${LABEL:-} == fastscratch && -n ${UUID:-} ]]; then
			log "already fastscratch; ensuring fstab+mount"
			mkdir -p "$MNT"
			grep -qF "UUID=$UUID $MNT " /etc/fstab || cat >>/etc/fstab <<EOF

# Fast scratch (post-reboot-nvme.sh)
UUID=$UUID $MNT btrfs compress=zstd:3,noatime 0 0
EOF
			findmnt -n "$MNT" >/dev/null 2>&1 || mount "$MNT"
		else
			log "ABORT spare has partitions but is not label=fastscratch; will not wipefs"
			exit 2
		fi
	else
		log "ABORT --check failed rc=$rc (not a partitions abort)"
		exit 2
	fi
fi

mkdir -p "$MNT/xbrd-spark" "$MNT/tmp"
chmod 1777 "$MNT/tmp" || true
chown -R "$TARGET_USER":"$TARGET_USER" "$MNT/xbrd-spark" || true

install -d -m 0755 -o "$TARGET_USER" -g "$TARGET_USER" "/home/$TARGET_USER/.config/environment.d"
cat >"$SPARK_ENV" <<'EOF'
XBRD_SPARK_ROOT=/scratch/xbrd-spark
EOF
chown "$TARGET_USER":"$TARGET_USER" "$SPARK_ENV"

date -u +%Y-%m-%dT%H:%M:%SZ >"$STAMP_FILE"
log "DONE $MNT mounted=$(findmnt -n -o SOURCE,FSTYPE,OPTIONS $MNT || echo none)"
log "XBRD_SPARK_ROOT=/scratch/xbrd-spark (user environment.d; re-login to pick up)"
exit 0
