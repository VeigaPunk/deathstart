#!/usr/bin/env bash
# After deathstart-nvme-post.service: capture host probes and hand them to
# xask K2.7 Coding Highspeed (OAuth kimi-code/kimi-for-coding-highspeed).
# Thinking ON. No effort tier on this model.
set -euo pipefail

export HOME=/home/vgpnk
export USER=vgpnk
export PATH="/home/vgpnk/.local/bin:/home/vgpnk/.local/share/fnm/aliases/default/bin:/home/vgpnk/.local/share/mise/installs/node/latest/bin:/usr/local/bin:/usr/bin"
export XASK_TIMEOUT_SECS=0

DIR=/home/vgpnk/Projects/deathstart/optimizations/2026-08-23
OUT="$DIR/last-verify.txt"
XASK_OUT="$DIR/last-verify-xask.txt"
mkdir -p "$DIR"

{
	echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) deathstart nvme verify ==="
	echo "--- systemctl status deathstart-nvme-post.service ---"
	systemctl status deathstart-nvme-post.service --no-pager -l || true
	echo
	echo "--- ls /sys/class/nvme ---"
	ls -l /sys/class/nvme || true
	echo
	echo "--- findmnt /scratch ---"
	findmnt /scratch || echo "(not mounted)"
	echo
	echo "--- resume= from /proc/cmdline ---"
	tr ' ' '\n' </proc/cmdline | grep resume || echo "(no resume= in cmdline)"
	echo
	echo "--- by-id SN8100 ---"
	ls -l /dev/disk/by-id 2>/dev/null | grep SN8100 || true
} | tee "$OUT"

PROMPT=$(cat <<EOF
You are the post-reboot NVMe executor on plazir27. Thinking ON. This model has no effort tier.

Probe output:

$(cat "$OUT")

Decide GO or NO-GO.
GO if: two NVMe class nodes or a second SN8100 by-id, /scratch mounted, and resume= is PARTUUID not /dev/nvme*.
NO-GO if spare missing (SKIP_NOT_INSERTED), resume still /dev/nvme, /scratch absent after a second disk appeared, or the unit failed.

If NO-GO and the spare is present, name the exact next command (sudo -n $DIR/post-reboot-nvme.sh or stop). Do not mkfs by hand. Do not --full-tmp. Do not omarchy refresh.
EOF
)

xask --gs --provider moonshot --model-id kimi-for-coding-highspeed -- "$PROMPT" | tee "$XASK_OUT"
exit 0
