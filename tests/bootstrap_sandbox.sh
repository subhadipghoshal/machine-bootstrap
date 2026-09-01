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
bash "$script" --sandbox --state "$state" --stop-after core-packages >"$first"
[[ -f "$state/phases/core-packages.done" ]] || { printf '%s\n' "sandbox did not record interruption point" >&2; exit 1; }
[[ ! -f "$state/phases/doctor.done" ]] || { printf '%s\n' "sandbox incorrectly completed after stop" >&2; exit 1; }
bash "$script" --sandbox --state "$state" >>"$first"
grep -Fq -- "sandbox: git clone --filter=blob:none --branch main --single-branch https://github.com/subhadipghoshal/dotfiles.git" "$first" || { printf '%s\n' "sandbox did not retrieve main" >&2; exit 1; }
grep -Fq -- "sandbox: chezmoi diff --source $state/source" "$first" || { printf '%s\n' "sandbox did not preview with chezmoi diff" >&2; exit 1; }
grep -Fq -- "sandbox: chezmoi apply --source $state/source -v" "$first" || { printf '%s\n' "sandbox did not apply verbosely" >&2; exit 1; }
before="$(find "$state" -type f -print | sort | xargs -I{} shasum -a 256 "{}")"
bash "$script" --sandbox --state "$state" >"$second"
after="$(find "$state" -type f -print | sort | xargs -I{} shasum -a 256 "{}")"
[[ "$before" == "$after" ]] || { printf '%s\n' "sandbox is not idempotent" >&2; exit 1; }
[[ "$(wc -l < "$second")" -eq 11 ]] || { printf '%s\n' "unexpected resume output" >&2; exit 1; }
printf '%s\n' "sandbox bootstrap: PASS"
