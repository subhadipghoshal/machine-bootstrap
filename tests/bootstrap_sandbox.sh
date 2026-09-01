#!/usr/bin/env bash
set -euo pipefail

root="$(CDPATH= cd -- "$(mktemp -d "${TMPDIR:-/tmp}/machine-bootstrap.XXXXXX")" && pwd)"
trap 'rm -rf "$root"' EXIT
state="$root/state"
test_home="$root/home"
script="$root/repo/scripts/bootstrap"
mkdir -p "$root/repo/scripts" "$test_home"
cp "$(dirname -- "$0")/../scripts/bootstrap" "$script"
chmod +x "$script"

first="$root/first.log"
second="$root/second.log"
HOME="$test_home" bash "$script" --sandbox --state "$state" --stop-after core-packages >"$first"
[[ -f "$state/phases/core-packages.done" ]] || { printf '%s\n' "sandbox did not record interruption point" >&2; exit 1; }
[[ ! -f "$state/phases/doctor.done" ]] || { printf '%s\n' "sandbox incorrectly completed after stop" >&2; exit 1; }
HOME="$test_home" bash "$script" --sandbox --state "$state" >>"$first"
grep -Fq -- "sandbox: git clone --filter=blob:none --branch main --single-branch https://github.com/subhadipghoshal/dotfiles.git" "$first" || { printf '%s\n' "sandbox did not retrieve main" >&2; exit 1; }
grep -Fq -- "sandbox: chezmoi diff --source $state/source" "$first" || { printf '%s\n' "sandbox did not preview with chezmoi diff" >&2; exit 1; }
grep -Fq -- "sandbox: chezmoi apply --source $state/source -v" "$first" || { printf '%s\n' "sandbox did not apply verbosely" >&2; exit 1; }
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
[[ "$(wc -l < "$second")" -eq 14 ]] || { printf '%s\n' "unexpected resume output" >&2; exit 1; }
printf '%s\n' "sandbox bootstrap: PASS"
