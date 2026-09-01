# Repository Instructions

## Current State

- `PLAN.md` remains the implementation contract; it is still a draft and the bootstrap is only an initial scaffold, not a completed clean-machine system.
- `scripts/bootstrap`, `scripts/doctor`, `tests/bootstrap_sandbox.sh`, and Homebrew profile manifests now exist. There are still no CI workflows, formatter, linter, or package lockfile; do not report unimplemented plan checks as runnable.
- Treat the fixed decisions, phase order, safety requirements, and exit gates in `PLAN.md` as the implementation contract. Update that document when an accepted implementation changes the contract.

## Scope And Ownership

- Support only clean developer-environment rebuilds on Apple Silicon macOS. Do not add Migration Assistant, exact-clone, Intel Mac, or personal-data migration behavior.
- Preserve the chezmoi source layout. Planned bootstrap-only paths such as `software/`, `scripts/`, `tests/`, and `docs/` must be excluded from deployment through `.chezmoiignore`, not copied into `$HOME`.
- Keep one authority per state type: public dotfiles for portable non-secret configuration, private project remotes for project source, LastPass for durable secrets, and per-device stores for SSH keys and authentication sessions.
- Project runtime versions belong in project repositories. Machine manifests should contain only justified global tools and ownership policy.

## Required Sequence

- Do not start normal bootstrap implementation until Phase 0 credential containment and source-freeze gates are satisfied. `PLAN.md` records that values from `~/.secrets/keys` reached local output; never read or print that file, and never place replacement values in Git, logs, process arguments, or shell history.
- Implement phases in the order listed in `PLAN.md`. Never add destructive cleanup, package removal, credential revocation, or old-machine erasure before replacement behavior passes its corresponding exit gate.
- Bootstrap order matters: preflight, Command Line Tools, native Homebrew, latest-main anonymous source retrieval, change preview, core packages, apply prerequisites, verbose chezmoi apply, optional profiles, then the read-only doctor.
- Bootstrap from the latest commit on `main`, retrieved over HTTPS and never piped directly into a shell.

## Behavioral Constraints

- Bootstrap must refuse unsupported architecture or untested future macOS major versions, must not run as root, and must scope privileged operations to the exact prerequisite requiring them.
- Before replacing targets, back up conflicts and refuse dirty repositories, unexpected directories, and non-owned symlinks. Never uninstall packages or run Homebrew cleanup during normal convergence.
- Keep run state private with mode `0700`; any generated credential file must be atomic, regenerable, and mode `0600`.
- Every phase must be safely resumable. A second successful bootstrap run must make no unexplained changes.
- Derive the Homebrew prefix and home directory. Portable output must not embed the source username or assume an architecture-specific Homebrew path.
- Optional shell integrations must tolerate absent tools during staged setup. Agent sessions must not modify the chezmoi source as a side effect of startup.

## Verification Contract

- Add behavior-first coverage for clean-machine setup, interrupted phase recovery, target conflicts, unavailable network/authentication, wrong tool ownership or architecture, and second-run idempotence.
- Validate shell syntax, templates for a differently named ARM64 user, complete-tree and Git-history secret scans, each Brewfile profile, `chezmoi diff`/`chezmoi status`, shell startup modes, critical executable ownership, representative project builds, and restore behavior.
- Treat macOS security approvals as documented manual steps with observable behavior checks; never copy TCC databases, login-item databases, sessions, cookies, or generated LaunchAgents.
- When executable tooling is added, record exact setup and focused verification commands here rather than making agents infer them from prose.
