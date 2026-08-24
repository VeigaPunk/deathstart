#!/usr/bin/env bash
# bak + PARTUUID resume SSoT + limine-update. Does not mkfs, --full-tmp, or omarchy refresh.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run with sudo"; exit 1; }

HERE=$(cd "$(dirname "$0")" && pwd)
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
# Live values from this box — not hardcoded identifiers.
root_part=$(findmnt -n -o SOURCE /)
root_part=${root_part%%\[*}
PARTUUID=$(lsblk -dnro PARTUUID -- "$root_part")
OFFSET=$(tr -d '[:space:]' < /sys/power/resume_offset)
[[ -n $PARTUUID && -n $OFFSET ]] || { echo "ABORT missing PARTUUID or resume_offset" >&2; exit 1; }
RESUME_LINE="KERNEL_CMDLINE[default]+=\" resume=PARTUUID=${PARTUUID} resume_offset=${OFFSET}\""
LIMINE=/etc/default/limine
DROP=/etc/limine-entry-tool.d/resume.conf
INTENDED_LIMINE="$HERE/etc/limine.intended"
INTENDED_DROP="$HERE/etc/resume.conf.intended"
PRE_CMDLINE=/tmp/m02-get-cmdline-pre.txt
POST_CMDLINE=/tmp/m02-get-cmdline.txt
FALLBACK=0

echo "STAMP=$STAMP"
CMDLINE_KNAME=
CMDLINE_PROFILE=

looks_like_cmdline() {
	grep -qE '(^|[[:space:]])root=' <<<"$1"
}

harvest_names() {
	local tree=$1
	# boot-menu labels plus known pkgbase / UKI names
	printf '%s\n' linux omarchy "$(uname -r)" Linux linux-lts
	if [[ -f $tree ]]; then
		sed -n 's/.*\b\(linux[-._a-zA-Z0-9]*\|omarchy[-._a-zA-Z0-9]*\)\b.*/\1/p' "$tree"
	fi
}

get_cmdline() {
	local kname profile out names profiles
	limine-entry-tool --tree > /tmp/m02-tree.txt 2>&1 || true
	mapfile -t names < <(harvest_names /tmp/m02-tree.txt | awk 'NF && !seen[$0]++')
	profiles=(default linux omarchy fallback)
	if [[ -n ${CMDLINE_KNAME:-} ]]; then
		if [[ -n ${CMDLINE_PROFILE:-} ]]; then
			out=$(limine-entry-tool --get-cmdline "$CMDLINE_KNAME" "$CMDLINE_PROFILE" 2>/tmp/m02-get-cmdline.err) || true
			if looks_like_cmdline "${out:-}"; then
				printf '%s\n' "$out"
				return 0
			fi
		fi
		out=$(limine-entry-tool --get-cmdline "$CMDLINE_KNAME" 2>/tmp/m02-get-cmdline.err) || true
		if looks_like_cmdline "${out:-}"; then
			printf '%s\n' "$out"
			return 0
		fi
	fi
	for kname in "${names[@]}"; do
		out=$(limine-entry-tool --get-cmdline "$kname" 2>/tmp/m02-get-cmdline.err) || true
		if looks_like_cmdline "${out:-}"; then
			CMDLINE_KNAME=$kname
			CMDLINE_PROFILE=
			echo "get-cmdline kname=$kname (one-arg)" >&2
			printf '%s\n' "$out"
			return 0
		fi
		for profile in "${profiles[@]}"; do
			out=$(limine-entry-tool --get-cmdline "$kname" "$profile" 2>/tmp/m02-get-cmdline.err) || true
			if looks_like_cmdline "${out:-}"; then
				CMDLINE_KNAME=$kname
				CMDLINE_PROFILE=$profile
				echo "get-cmdline kname=$kname profile=$profile" >&2
				printf '%s\n' "$out"
				return 0
			fi
		done
	done
	echo "get-cmdline produced no root= line; tree follows" >&2
	cat /tmp/m02-tree.txt >&2 || true
	cat /tmp/m02-get-cmdline.err >&2 || true
	ls -la /boot /boot/EFI /boot/EFI/Linux 2>&1 | head -80 >&2 || true
	return 1
}

cmdline_ok() {
	local f=$1
	grep -q "resume=PARTUUID=${PARTUUID}" "$f" || return 1
	grep -q "resume_offset=${OFFSET}" "$f" || return 1
	! grep -q 'resume=/dev/nvme' "$f"
}

if [[ ! -f "$INTENDED_LIMINE" || ! -f "$INTENDED_DROP" ]]; then
	echo "missing intended files under $HERE/etc" >&2
	exit 1
fi

if grep -q "resume=PARTUUID=${PARTUUID}" "$DROP" \
	&& ! grep -q 'resume=/dev/nvme' "$LIMINE" "$DROP" \
	&& grep -q 'SSoT: /etc/limine-entry-tool.d/resume.conf' "$LIMINE"; then
	echo "live files already PARTUUID; not taking a new bak"
	if ! cmp -s "$INTENDED_LIMINE" "$LIMINE" || ! cmp -s "$INTENDED_DROP" "$DROP"; then
		echo "re-sync to intended SSoT (drop extra fallback +=); keeping existing bak"
		install -o root -g root -m 644 "$INTENDED_DROP" "$DROP"
		install -o root -g root -m 644 "$INTENDED_LIMINE" "$LIMINE"
	fi
else
	cp -a "$LIMINE" "$LIMINE.bak.$STAMP"
	cp -a "$DROP" "$DROP.bak.$STAMP"
	install -o root -g root -m 644 "$INTENDED_DROP" "$DROP"
	install -o root -g root -m 644 "$INTENDED_LIMINE" "$LIMINE"
	grep -q "root=PARTUUID=${PARTUUID}" "$LIMINE" || {
		echo "root= PARTUUID line missing after install" >&2
		exit 1
	}
	grep -q 'resume=/dev/nvme' "$LIMINE" "$DROP" && {
		echo "kernel-name resume still present after install" >&2
		exit 1
	}
fi

GET_CMDLINE_WORKED=1
get_cmdline | tee "$PRE_CMDLINE" || GET_CMDLINE_WORKED=0
if [[ $GET_CMDLINE_WORKED -eq 1 ]] && ! cmdline_ok "$PRE_CMDLINE"; then
	echo "FALLBACK: PARTUUID missing or kernel-name resume still in --get-cmdline; += into $LIMINE"
	FALLBACK=1
	if ! grep -q "resume=PARTUUID=${PARTUUID}" "$LIMINE"; then
		printf '%s\n' "$RESUME_LINE" >>"$LIMINE"
	fi
	GET_CMDLINE_WORKED=1
	get_cmdline | tee "$PRE_CMDLINE" || GET_CMDLINE_WORKED=0
	if [[ $GET_CMDLINE_WORKED -eq 1 ]] && ! cmdline_ok "$PRE_CMDLINE"; then
		echo "FALLBACK --get-cmdline still missing PARTUUID or still has resume=/dev/nvme" >&2
		cat "$PRE_CMDLINE" >&2
		exit 1
	fi
fi
if [[ $GET_CMDLINE_WORKED -eq 0 ]]; then
	echo "GET_CMDLINE_UNAVAILABLE before regen; files are PARTUUID SSoT; continuing to limine-update"
fi

limine-update

GET_CMDLINE_WORKED=1
get_cmdline | tee "$POST_CMDLINE" || GET_CMDLINE_WORKED=0
if [[ $GET_CMDLINE_WORKED -eq 1 ]]; then
	cmdline_ok "$POST_CMDLINE" || {
		echo "post limine-update --get-cmdline failed PARTUUID gate" >&2
		cat "$POST_CMDLINE" >&2
		exit 1
	}
else
	echo "GET_CMDLINE_UNAVAILABLE after regen; grepping ESP"
	{
		echo '--- /boot/limine.conf resume ---'
		grep -n -E 'resume=|root=PARTUUID' /boot/limine.conf /boot/limine/limine.conf /boot/EFI/limine/limine.conf 2>/dev/null || true
		echo '--- UKI strings resume ---'
		find /boot /boot/EFI -name '*.efi' -o -name 'omarchy*' 2>/dev/null | head
		grep -a -o -E 'resume=[^ ]+|root=PARTUUID=[^ ]+|resume_offset=[0-9]+' /boot/EFI/Linux/* /boot/*.efi 2>/dev/null | sort -u || true
	} | tee /tmp/m02-esp-grep.txt
	grep -q "resume=PARTUUID=${PARTUUID}" /tmp/m02-esp-grep.txt || {
		echo "ESP grep missing resume=PARTUUID" >&2
		exit 1
	}
	grep -q "resume_offset=${OFFSET}" /tmp/m02-esp-grep.txt || {
		echo "ESP grep missing resume_offset" >&2
		exit 1
	}
	if grep -q 'resume=/dev/nvme' /tmp/m02-esp-grep.txt; then
		echo "ESP still has resume=/dev/nvme" >&2
		exit 1
	fi
fi

python3 -c "from pathlib import Path
limine=Path('/etc/default/limine').read_text(); drop=Path('/etc/limine-entry-tool.d/resume.conf').read_text(); blob=limine+'\n'+drop
assert 'resume=PARTUUID=${PARTUUID}' in drop
assert 'resume_offset=${OFFSET}' in drop
assert 'resume=/dev/nvme' not in blob
assert 'root=PARTUUID=${PARTUUID}' in limine
print('files_ok')" \
	|| {
		if [[ "$FALLBACK" -eq 1 ]]; then
			echo "files_ok skipped (FALLBACK both-files PARTUUID; count resume= != 1 is expected)"
			python3 -c "from pathlib import Path
limine=Path('/etc/default/limine').read_text(); drop=Path('/etc/limine-entry-tool.d/resume.conf').read_text(); blob=limine+'\n'+drop
assert 'resume=PARTUUID=${PARTUUID}' in drop
assert 'resume_offset=${OFFSET}' in drop
assert 'resume=/dev/nvme' not in blob
assert 'root=PARTUUID=${PARTUUID}' in limine
print('files_ok_fallback')"
		else
			exit 1
		fi
	}

echo M02_REWRITE_OK STAMP="$STAMP" FALLBACK="$FALLBACK"
