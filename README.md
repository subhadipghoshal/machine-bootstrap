# Machine Bootstrap

This repository is the source for a clean Apple Silicon macOS developer-environment rebuild. It is not a machine clone and does not migrate personal application data.

## Status

The bootstrap is intentionally conservative and still requires the Phase 0 credential-containment and source-freeze gate in `PLAN.md`. Do not point it at this host as a test target. The repository currently has no CI or package-manager lockfile.

## Safe Verification

Run the host-independent sandbox test:

```sh
bash tests/bootstrap_sandbox.sh
```

This uses a temporary directory and `--sandbox`; it does not invoke macOS, Homebrew, chezmoi, network access, or credentials.

Validate shell syntax without executing the bootstrap:

```sh
bash -n scripts/bootstrap scripts/doctor tests/bootstrap_sandbox.sh
```

## Bootstrap Modes

The script defaults to a non-mutating plan and retrieves the latest commit from the dotfiles repository's `main` branch:

```sh
bash scripts/bootstrap
bash scripts/bootstrap --sandbox --state /tmp/bootstrap-state
```

`--execute` is intentionally explicit. It must be run only on a clean, supported Apple Silicon macOS account after the Phase 0 and relevant `PLAN.md` exit gates pass:

```sh
bash scripts/bootstrap --execute
```

After core packages, the `agents` phase installs Claude Code, OpenCode, Antigravity, Node, and Pi. It then installs Oh My Zsh and its reviewed Powerlevel10k theme plus external plugins from pinned HTTPS Git repositories. The OpenCode plugin files under `dot_config/opencode/plugins/` are part of the chezmoi source, checked during execution, previewed by `chezmoi diff`, and applied by `chezmoi apply -v`.

Pinned custom repositories:

| Component           | Repository                      | Reviewed commit                            |
|---------------------|---------------------------------|--------------------------------------------|
| Oh My Zsh           | `ohmyzsh/ohmyzsh`               | `a5ecff7560b2e26f612032c632a12c75a3048bd0` |
| Powerlevel10k       | `romkatv/powerlevel10k`         | `3308262dfbd743b6e1d3956a2b5572f7a049d692` |
| forgit              | `wfxr/forgit`                   | `3fe2a163343270b1b0e631bf35c12a7d98093464` |
| fzf-tab             | `Aloxaf/fzf-tab`                | `24105b15714bfec37989ed5c5b6e60f572253019` |
| zsh-autosuggestions | `zsh-users/zsh-autosuggestions` | `85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5` |
| F-Sy-H              | `z-shell/F-Sy-H`                | `9a279bb574a4de3b37cc9b9e33712f88ef52079d` |

State is kept under a private mode-0700 directory and phase completion is recorded atomically. Interrupted runs resume from the last completed phase. Normal convergence never uninstalls packages or runs Homebrew cleanup.

## Layout

- `software/homebrew/` contains direct package profiles, not an inventory of accumulated machine state.
- `scripts/bootstrap` owns staged, resumable setup.
- `scripts/doctor` is read-only and reports completed phases plus manual permission work.
- `tests/` contains host-independent behavior checks.
- `PLAN.md` is the implementation contract and records security gates, ownership, rollback, and acceptance requirements.

Bootstrap-only paths are excluded from chezmoi deployment by `.chezmoiignore`.
