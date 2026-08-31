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

The script defaults to a non-mutating plan. A reviewed immutable 40-character commit ID is mandatory outside sandbox mode:

```sh
bash scripts/bootstrap --ref REVIEWED_COMMIT_ID
bash scripts/bootstrap --sandbox --state /tmp/bootstrap-state --ref REVIEWED_COMMIT_ID
```

`--execute` is intentionally explicit. It must be run only on a clean, supported Apple Silicon macOS account after the Phase 0 and relevant `PLAN.md` exit gates pass:

```sh
bash scripts/bootstrap --execute --ref REVIEWED_COMMIT_ID
```

State is kept under a private mode-0700 directory and phase completion is recorded atomically. Interrupted runs resume from the last completed phase. Normal convergence never uninstalls packages or runs Homebrew cleanup.

## Layout

- `software/homebrew/` contains direct package profiles, not an inventory of accumulated machine state.
- `scripts/bootstrap` owns staged, resumable setup.
- `scripts/doctor` is read-only and reports completed phases plus manual permission work.
- `tests/` contains host-independent behavior checks.
- `PLAN.md` is the implementation contract and records security gates, ownership, rollback, and acceptance requirements.

Bootstrap-only paths are excluded from chezmoi deployment by `.chezmoiignore`.
