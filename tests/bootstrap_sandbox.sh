#!/usr/bin/env bash
set -euo pipefail

root="$(mktemp -d "${TMPDIR:-/tmp}/machine-bootstrap.XXXXXX")"
trap 'rm -rf "$root"' EXIT
state="$root/state"
script="$root/repo/scripts/bootstrap"
mkdir -p "$root/repo/scripts"
cp "$(dirname -- "$0")/../scripts/bootstrap" "$script"
chmod +x "$script"

first="$root/first.log"
second="$root/second.log"
bash "$script" --sandbox --state "$state" --ref reviewed-tag --stop-after core-packages >"$first"
[[ -f "$state/phases/core-packages.done" ]] || { printf '%s\n' "sandbox did not record interruption point" >&2; exit 1; }
[[ ! -f "$state/phases/doctor.done" ]] || { printf '%s\n' "sandbox incorrectly completed after stop" >&2; exit 1; }
bash "$script" --sandbox --state "$state" --ref reviewed-tag >>"$first"
before="$(find "$state" -type f -print | sort | xargs -I{} shasum -a 256 "{}")"
bash "$script" --sandbox --state "$state" --ref reviewed-tag >"$second"
after="$(find "$state" -type f -print | sort | xargs -I{} shasum -a 256 "{}")"
[[ "$before" == "$after" ]] || { printf '%s\n' "sandbox is not idempotent" >&2; exit 1; }
[[ "$(wc -l < "$second")" -eq 11 ]] || { printf '%s\n' "unexpected resume output" >&2; exit 1; }
printf '%s\n' "sandbox bootstrap: PASS"
