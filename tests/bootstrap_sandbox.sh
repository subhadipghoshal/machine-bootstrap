#!/usr/bin/env bash
set -euo pipefail

root="$(CDPATH= cd -- "$(mktemp -d "${TMPDIR:-/tmp}/machine-bootstrap.XXXXXX")" && pwd)"
trap 'rm -rf "$root"' EXIT
state="$root/state"
test_home="$root/home"
script="$root/repo/scripts/bootstrap"
mkdir -p "$root/repo/scripts" "$root/repo/software/homebrew" "$test_home"
cp "$(dirname -- "$0")/../scripts/bootstrap" "$script"
cp "$(dirname -- "$0")/../software/homebrew/Brewfile.core" "$root/repo/software/homebrew/Brewfile.core"
chmod +x "$script"

first="$root/first.log"
second="$root/second.log"
HOME="$test_home" bash "$script" --sandbox --state "$state" --stop-after core-packages >"$first"
[[ -f "$state/phases/core-packages.done" ]] || { printf '%s\n' "sandbox did not record interruption point" >&2; exit 1; }
[[ ! -f "$state/phases/doctor.done" ]] || { printf '%s\n' "sandbox incorrectly completed after stop" >&2; exit 1; }
HOME="$test_home" bash "$script" --sandbox --state "$state" >>"$first"
grep -Fq -- "sandbox: git clone --filter=blob:none --branch main --single-branch https://github.com/subhadipghoshal/dotfiles.git" "$first" || { printf '%s\n' "sandbox did not retrieve main" >&2; exit 1; }
grep -Fq -- "INFO bootstrap: phase start: preflight" "$first" || { printf '%s\n' "sandbox did not log phase start" >&2; exit 1; }
grep -Fq -- "INFO bootstrap: phase complete: core-packages" "$first" || { printf '%s\n' "sandbox did not log phase completion" >&2; exit 1; }
grep -Fxq -- 'brew "atuin"' "$root/repo/software/homebrew/Brewfile.core" || { printf '%s\n' "core profile does not include Atuin" >&2; exit 1; }
grep -Fq -- "sandbox: chezmoi diff --source $state/source" "$first" || { printf '%s\n' "sandbox did not preview with chezmoi diff" >&2; exit 1; }
grep -Fq -- "sandbox: chezmoi apply --source $state/source -v" "$first" || { printf '%s\n' "sandbox did not apply verbosely" >&2; exit 1; }
core_line="$(grep -n -m1 -F -- "sandbox: brew bundle --file $root/repo/software/homebrew/Brewfile.core" "$first" | cut -d: -f1)"
preview_line="$(grep -n -m1 -F -- "sandbox: chezmoi diff --source $state/source" "$first" | cut -d: -f1)"
[[ "$core_line" -lt "$preview_line" ]] || { printf '%s\n' "sandbox preview ran before core packages" >&2; exit 1; }
grep -Fq -- "sandbox: brew bundle --file $root/repo/software/homebrew/Brewfile.agents" "$first" || { printf '%s\n' "sandbox did not install agent packages" >&2; exit 1; }
grep -Fq -- "sandbox: npm install --global @earendil-works/pi-coding-agent" "$first" || { printf '%s\n' "sandbox did not install Pi" >&2; exit 1; }
grep -Fq -- "sandbox: git clone --filter=blob:none --no-checkout https://github.com/ohmyzsh/ohmyzsh.git $test_home/.oh-my-zsh" "$first" || { printf '%s\n' "sandbox did not install Oh My Zsh" >&2; exit 1; }
grep -Fq -- "sandbox: git -C $test_home/.oh-my-zsh checkout --detach a5ecff7560b2e26f612032c632a12c75a3048bd0" "$first" || { printf '%s\n' "sandbox did not pin Oh My Zsh" >&2; exit 1; }
grep -Fq -- "sandbox: git clone --filter=blob:none --no-checkout https://github.com/romkatv/powerlevel10k.git $test_home/.oh-my-zsh/custom/themes/powerlevel10k" "$first" || { printf '%s\n' "sandbox did not install Powerlevel10k" >&2; exit 1; }
grep -Fq -- "sandbox: git clone --filter=blob:none --no-checkout https://github.com/wfxr/forgit.git $test_home/.oh-my-zsh/custom/plugins/forgit" "$first" || { printf '%s\n' "sandbox did not install forgit" >&2; exit 1; }
grep -Fq -- "sandbox: git clone --filter=blob:none --no-checkout https://github.com/Aloxaf/fzf-tab.git $test_home/.oh-my-zsh/custom/plugins/fzf-tab" "$first" || { printf '%s\n' "sandbox did not install fzf-tab" >&2; exit 1; }
grep -Fq -- "sandbox: git clone --filter=blob:none --no-checkout https://github.com/zsh-users/zsh-autosuggestions.git $test_home/.oh-my-zsh/custom/plugins/zsh-autosuggestions" "$first" || { printf '%s\n' "sandbox did not install zsh-autosuggestions" >&2; exit 1; }
grep -Fq -- "sandbox: git clone --filter=blob:none --no-checkout https://github.com/z-shell/F-Sy-H.git $test_home/.oh-my-zsh/custom/plugins/F-Sy-H" "$first" || { printf '%s\n' "sandbox did not install F-Sy-H" >&2; exit 1; }
conflict_home="$root/conflict-home"
conflict_state="$root/conflict-state"
mkdir -p "$conflict_home"
touch "$conflict_home/.oh-my-zsh"
if HOME="$conflict_home" bash "$script" --sandbox --state "$conflict_state" --stop-after oh-my-zsh >/dev/null 2>&1; then
  printf '%s\n' "sandbox overwrote an Oh My Zsh target conflict" >&2
  exit 1
fi
before="$(find "$state" -type f -print | sort | xargs -I{} shasum -a 256 "{}")"
HOME="$test_home" bash "$script" --sandbox --state "$state" >"$second"
after="$(find "$state" -type f -print | sort | xargs -I{} shasum -a 256 "{}")"
[[ "$before" == "$after" ]] || { printf '%s\n' "sandbox is not idempotent" >&2; exit 1; }
grep -Fq -- "INFO bootstrap: phase skip: preflight" "$second" || { printf '%s\n' "sandbox did not log skipped phase" >&2; exit 1; }
grep -Fq -- "INFO bootstrap: phase complete: retrieve-source" "$second" || { printf '%s\n' "sandbox did not log refreshed phase" >&2; exit 1; }
grep -Fq -- "sandbox: git clone --filter=blob:none --branch main --single-branch https://github.com/subhadipghoshal/dotfiles.git" "$second" || { printf '%s\n' "sandbox did not refresh dotfiles source" >&2; exit 1; }
grep -Fq -- "sandbox: chezmoi apply --source $state/source -v" "$second" || { printf '%s\n' "sandbox did not reapply dotfiles source" >&2; exit 1; }
unexpected_state="$root/unexpected-state"
mkdir -p "$unexpected_state"
touch "$unexpected_state/source"
conflict_log="$root/conflict.log"
conflict_err="$root/conflict.err"
if HOME="$test_home" bash "$script" --sandbox --state "$unexpected_state" --stop-after retrieve-source >"$conflict_log" 2>"$conflict_err"; then
  printf '%s\n' "sandbox accepted an unexpected source path" >&2
  exit 1
fi
! grep -Fq -- 'ERROR bootstrap:' "$conflict_log" || { printf '%s\n' "source conflict wrote its error to stdout" >&2; exit 1; }
grep -Fxq -- 'ERROR bootstrap: refusing unexpected source path: '"$unexpected_state/source" "$conflict_err" || { printf '%s\n' "source conflict did not use structured stderr error" >&2; exit 1; }
symlink_state="$root/symlink-state"
mkdir -p "$symlink_state"
ln -s "$root" "$symlink_state/source"
if HOME="$test_home" bash "$script" --sandbox --state "$symlink_state" --stop-after retrieve-source >/dev/null 2>&1; then
  printf '%s\n' "sandbox accepted a symlinked source path" >&2
  exit 1
fi
wrong_remote_state="$root/wrong-remote-state"
mkdir -p "$wrong_remote_state/source"
git -C "$wrong_remote_state/source" init -q
git -C "$wrong_remote_state/source" remote add origin https://example.invalid/unexpected.git
if HOME="$test_home" bash "$script" --sandbox --state "$wrong_remote_state" --stop-after retrieve-source >/dev/null 2>&1; then
  printf '%s\n' "sandbox accepted an unexpected source remote" >&2
  exit 1
fi
dirty_state="$root/dirty-state"
mkdir -p "$dirty_state/source"
git -C "$dirty_state/source" init -q
git -C "$dirty_state/source" remote add origin https://github.com/subhadipghoshal/dotfiles.git
touch "$dirty_state/source/uncommitted"
if HOME="$test_home" bash "$script" --sandbox --state "$dirty_state" --stop-after retrieve-source >/dev/null 2>&1; then
  printf '%s\n' "sandbox accepted a dirty source repository" >&2
  exit 1
fi
printf '%s\n' "sandbox bootstrap: PASS"
