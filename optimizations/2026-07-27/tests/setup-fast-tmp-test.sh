#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
SCRIPT="$ROOT/scripts/setup-fast-tmp.sh"

expect_rejected() {
  local expected=$1
  shift
  local output status
  set +e
  output=$(bash "$SCRIPT" "$@" 2>&1)
  status=$?
  set -e
  [[ $status -ne 0 ]] || { echo "FAIL: unexpectedly accepted: $*" >&2; exit 1; }
  [[ "$output" == *"$expected"* ]] || {
    echo "FAIL: expected '$expected' for: $*" >&2
    echo "$output" >&2
    exit 1
  }
}

bash -n "$SCRIPT"
expect_rejected "missing required --disk"
expect_rejected "unknown option: --device" --device /dev/disk/by-id/example
expect_rejected "positional targets are forbidden" /dev/disk/by-id/example
expect_rejected "target must be under" --disk /dev/null
expect_rejected "wildcards are forbidden" --disk '/dev/disk/by-id/nvme-*'
expect_rejected "--disk provided more than once" --disk /dev/disk/by-id/a --disk /dev/disk/by-id/b

python - "$SCRIPT" <<'PY'
import pathlib
import re
import sys

text = pathlib.Path(sys.argv[1]).read_text()
assert not re.search(r"/dev/nvme\d+n\d+", text), "hard-coded kernel NVMe name"
assert "--disk /dev/disk/by-id/" in text, "missing explicit by-id interface"
assert text.index("target is a root backing disk") < text.index("sfdisk --wipe always")
assert text.index("target already has partitions") < text.index("sfdisk --wipe always")
assert text.index("wipefs --noheadings") < text.index("sfdisk --wipe always")
assert text.index('[[ "$CHECK_ONLY" == 1 ]]') < text.index("sfdisk --wipe always")
PY

echo "PASS: setup-fast-tmp static and negative safety checks"
