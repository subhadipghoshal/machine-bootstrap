# Portable MacBook Developer Setup: Implementation Plan

**Status:** Draft contract. An initial non-destructive bootstrap scaffold exists; the full plan and clean-machine acceptance gates are not implemented.
**Date:** 2026-08-30
**Scope:** Reproduce the developer environment on a fresh Apple Silicon MacBook using a public GitHub dotfiles repository, private project remotes, and LastPass. Personal media, general application data, and an exact machine clone are out of scope.

---

## 1. Decisions and success criteria

The following decisions are fixed for the first implementation:

| Decision                | Choice                                                                                          |
|-------------------------|-------------------------------------------------------------------------------------------------|
| Migration model         | Clean developer-environment rebuild, not Migration Assistant or an exact clone                  |
| Supported hardware      | Apple Silicon only                                                                              |
| Configuration authority | Public GitHub repository managed with chezmoi                                                   |
| Project authority       | Private Git remotes                                                                             |
| Secret authority        | LastPass only                                                                                   |
| Package behavior        | Functional equivalence with current compatible packages, not byte-for-byte package reproduction |
| Runtime behavior        | Pin versions required by projects; do not preserve every globally installed runtime             |
| Local state             | Restore only state explicitly classified as valuable                                            |

The setup is complete when a clean Apple Silicon Mac can retrieve a reviewed release, install the selected developer tools, apply portable configuration, authenticate through LastPass, clone a private project, and build representative projects. Running the process a second time must produce no unexplained changes.

## 2. Verified starting point

The implementation must account for these observed conditions:

- The current host runs macOS 26.6.2 on Apple Silicon.
- Chezmoi uses `$HOME/.local/share/chezmoi` with the public `subhadipghoshal/dotfiles` repository.
- The chezmoi worktree has dozens of modified and untracked paths. The exact count changed during inspection, so execution must begin with a fresh inventory.
- The public repository has no current Brewfile, bootstrap program, runtime manifest, or clean-machine acceptance test.
- The archived Brewfile under a reference dotfiles checkout is stale and must not be reused as the desired package list.
- Current shell configuration assumes `/opt/homebrew`, Cargo, Turso, Oh My Zsh, Powerlevel10k, and external shell plugins already exist.
- The current README applies chezmoi immediately, before those prerequisites are guaranteed.
- Several shell, editor, agent, and application settings contain absolute home paths or machine-specific state.
- An always-on agent helper can modify the chezmoi source during normal sessions, making the source nondeterministic.
- Homebrew contains 311 formulae, including 127 request-installed formulae, plus 23 casks. This is accumulated state, not a suitable allowlist.
- Node, Python, Ruby, Go, Java, and several agent tools have overlapping or shadowed installation channels.
- Some developer repositories contain dirty, unpushed, or local-only work.
- Atuin synchronization is disabled, so shell history is local-only.
- No Time Machine destination or other verified off-device backup currently protects local-only state.
- A sanitized audit reported that credentials from `~/.secrets/keys` entered local tool or session output. Values must be rotated before migration work proceeds.

## 3. Source-of-truth model

Each kind of state must have exactly one authority.

| Authority                              | Owns                                                                                                   | Must not own                                                                                |
|----------------------------------------|--------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------|
| Public dotfiles repository             | Bootstrap, Brewfiles, runtime policy, non-secret dotfiles, editor manifests, validation, documentation | Credentials, private repository names when sensitive, application auth databases, histories |
| Private project remotes                | Source, branches, tags, project lockfiles, project runtime declarations, LFS objects, submodules       | Global machine configuration                                                                |
| LastPass                               | Passwords, API keys, recovery codes, durable developer credentials                                     | Dotfiles, package manifests, project source                                                 |
| Per-device authentication              | SSH private keys, OAuth sessions, temporary credential caches                                          | Durable cross-device recovery data                                                          |
| Temporary encrypted migration snapshot | Unresolved repository bundles and explicitly selected local-only state                                 | Ongoing configuration authority                                                             |

GitHub is the rebuild source, not a complete backup. It stores pushed Git objects but cannot recover uncommitted files, ignored files, local databases, stashes not converted to refs, shell history, credentials, container volumes, or application state. A GitHub-only strategy becomes acceptable only after every valuable project and configuration change is pushed, every durable secret is in LastPass, and all remaining local state is explicitly disposable.

## 4. Planned repository additions

Preserve the current chezmoi source layout. Do not introduce a source-root migration solely to organize bootstrap files. Add repository-only paths and exclude them from deployment through `.chezmoiignore`.

```text
software/
  homebrew/
    Brewfile.core
    Brewfile.languages
    Brewfile.cloud-containers
    Brewfile.ai
    Brewfile.gui-development
  runtimes/
    node.txt
    python-tools.txt
    go.txt
    rust.txt
    java.txt
    dotnet.txt
  editors/
    vscode-core.extensions
    vscode-language.extensions
    vscode-ai.extensions
  shell/
    plugins.lock
scripts/
  bootstrap
  doctor
  audit-repositories
  install-profile
  secret-run
tests/
  fixtures/
  bootstrap/
docs/
  restore.md
  secrets.md
  manual-permissions.md
  package-ownership.md
```

The exact filenames may change to match local conventions, but the ownership boundaries must remain. Bootstrap files must not be copied into `$HOME` merely because they live in the chezmoi source repository.

## 5. Implementation phases

### Phase 0: Contain credentials and freeze the source

**Purpose:** Remove immediate security risk and establish a stable baseline.

Implementation work:

1. Replace every credential currently stored in `~/.secrets/keys` with a new value created directly in LastPass.
2. Update each consumer without placing replacement values in shell history, process arguments, logs, or Git.
3. Revoke the old credentials and verify that they no longer work.
4. Scan the dotfiles repository, all refs and tags, relevant project repositories, and retained session artifacts without printing discovered values.
5. Remove the plaintext file and editor undo or session residue only after replacement credentials work.
6. Stop or redesign the helper that writes generated policy content into the chezmoi source during normal agent sessions.
7. Record fresh `git status`, `chezmoi status`, package inventories, runtime inventories, and application ownership before further changes.

Exit gate:

- Old credentials are revoked.
- Replacement credentials work through LastPass.
- No background process changes the chezmoi source during an observation window.
- The baseline inventory is stored without secret values.

### Phase 1: Preserve unique developer state

**Purpose:** Prevent scripts from giving a false sense of recoverability while unique work remains local.

Implementation work:

1. Implement a read-only repository audit covering normal repositories, nested repositories, bare repositories, and worktrees.
2. Report modifications, untracked and ignored files, stashes, local branches, upstream divergence, tags, submodules, LFS state, and missing remotes.
3. Classify every repository as pushed, needs preservation, local-only, or disposable.
4. Add private remotes for valuable local-only repositories.
5. Push required commits, branches, tags, LFS objects, and submodules.
6. Verify valuable repositories with separate test clones rather than relying only on successful push output.
7. Create a one-time encrypted off-device snapshot containing unresolved repository bundles, selected ignored files, the current chezmoi worktree, and optional Atuin history.
8. Exclude the exposed plaintext secret file and regenerable caches from the snapshot.
9. Test restoration of at least one repository bundle and one selected file.

Exit gate:

- Every valuable repository has a verified restoration path.
- Every unresolved local-only item exists in a tested encrypted snapshot.
- Loss of any excluded local state is explicitly accepted.

### Phase 2: Make the public dotfiles source portable

**Purpose:** Ensure that a public clone represents the intended live configuration without exposing host or secret state.

Implementation work:

1. Reconcile all modified and untracked chezmoi files into intentional commits or explicit exclusions.
2. Resolve live/source drift in `.gitconfig` and application-owned settings before any broad apply.
3. Replace embedded home directories with `$HOME`, chezmoi templates, or derived paths.
4. Keep Apple Silicon support explicit and fail clearly on unsupported architectures.
5. Derive the Homebrew prefix rather than repeating `/opt/homebrew` throughout configuration.
6. Remove global architecture flags that can affect unrelated builds.
7. Generate host-specific machine context locally rather than publishing host facts as portable policy.
8. Separate stable portable settings from generated application state, identity, authentication, and local histories.
9. Ensure agent harness adapters and skill links resolve without embedding source-machine paths.
10. Make optional shell integrations tolerate absent tools during bootstrap.
11. Document the staged chezmoi diff and verbose apply flow in the README.
12. Scan the complete public history, branches, tags, and generated artifacts before publishing the release.

Exit gate:

- A public clone contains every intended portable file.
- A differently named local user can render the source without references to the source machine's username or home directory.
- Starting agent harnesses does not dirty the source repository.
- Chezmoi preview contains no unexpected deletion of application-owned settings.
- Repository and history scans report no credential material.

### Phase 3: Curate software and runtime manifests

**Purpose:** Capture current intent instead of reproducing years of package accumulation.

Homebrew profiles:

| Profile              | Intended contents                                                                                                                                                          |
|----------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Core                 | Git, GitHub CLI, chezmoi, LastPass CLI, Ghostty, Neovim, tmux, GnuPG only while migration requires it, ripgrep, fd, fzf, bat, eza, jq, yq, direnv, zoxide, Meslo Nerd Font |
| Languages            | Selected runtime managers, compilers, build tools, package managers                                                                                                        |
| Cloud and containers | Docker or Podman, kubectl, Helm, k9s, cloud CLIs, Vault, related validators                                                                                                |
| AI                   | Selected agent CLIs and fast-moving third-party taps                                                                                                                       |
| GUI development      | VS Code, Zed or other explicitly selected developer applications                                                                                                           |

Implementation work:

1. Include direct desired packages only. Let Homebrew resolve transitive dependencies.
2. Assign one installation owner to every application and command.
3. Verify that a cask's application artifact exists instead of trusting its receipt alone.
4. Record direct-vendor applications that do not have an acceptable cask.
5. Keep primary tools in core and alternate terminals or editors in optional profiles.
6. Pin external shell plugin repositories to reviewed commits.
7. Curate editor extension lists instead of restoring every extension directory or cloud-sync remnant.
8. Keep Neovim and Vim lockfiles in the portable source after reconciling current live changes.
9. Derive runtime requirements from active project manifests.
10. Keep project-specific versions inside project repositories.
11. Defer removal of redundant managers until representative projects pass.

Initial runtime ownership policy:

| Runtime | Planned owner                                                                    |
|---------|----------------------------------------------------------------------------------|
| Python  | `uv` for Python installations and global tools                                   |
| Rust    | `rustup`                                                                         |
| Go      | `goenv` only if active projects require multiple versions                        |
| Java    | SDKMAN for project JDKs                                                          |
| .NET    | Homebrew                                                                         |
| Node    | Decide between Homebrew Node and active NVM after project requirement audit      |
| Ruby    | Remove rbenv from the desired setup unless an active project proves it is needed |

Exit gate:

- Every selected package has a profile and one owner.
- Every critical runtime version is justified by an active project or documented global need.
- `brew bundle check` succeeds for selected profiles.
- Critical commands resolve to the intended owner, architecture, and version.

### Phase 4: Build the staged bootstrap

**Purpose:** Provide a safe path from stock macOS to the managed developer environment.

Bootstrap sequence:

1. Verify supported macOS, `arm64`, available disk space, network access, administrator capability, and conflicting existing targets.
2. Detect Command Line Tools. If absent, request installation and stop with an explicit resume instruction.
3. Install or verify native Apple Silicon Homebrew.
4. Retrieve the latest dotfiles commit from the public repository's `main` branch anonymously over HTTPS.
5. Show the planned file changes with `chezmoi diff` without applying targets.
6. Install the core Homebrew profile.
7. Install the coding agents profile: Claude Code, OpenCode, Node, Antigravity, and Pi.
8. Install Oh My Zsh at a reviewed revision.
9. Install the reviewed Powerlevel10k theme and external plugins from pinned repositories.
10. Apply chezmoi with verbose output, including the managed OpenCode plugins.
11. Install selected language and optional profiles.
12. Install editor plugins and extensions from their manifests.
13. Run the read-only doctor and present remaining manual steps.

Bootstrap safety requirements:

- Do not execute a mutable dotfiles branch directly through a shell pipe.
- Do not run the general bootstrap as root.
- Scope privileged operations to the exact prerequisite that needs them.
- Stop on unsupported macOS major versions rather than guessing.
- Back up conflicting files before replacement.
- Refuse to overwrite dirty repositories, unexpected directories, or non-owned symlinks.
- Keep per-run state under a private mode-0700 directory.
- Verify actual state before trusting a completion marker.
- Do not uninstall packages or run Homebrew cleanup during normal convergence.
- Make interrupted phases safely resumable.
- Make the second successful run a no-op apart from read-only checks.

Exit gate:

- A clean Apple Silicon account completes the bootstrap without hidden prerequisites.
- Interrupting and rerunning each major phase is safe.
- A second complete run reports no unexplained changes.
- An unavailable network or rejected authentication produces a clear recovery instruction.

### Phase 5: Replace secret handling with LastPass

**Purpose:** Keep durable credentials out of files, Git, and parallel secret stores.

Implementation work:

1. Install the supported LastPass CLI through the core package profile.
2. Require interactive login and MFA. Never automate the master password.
3. Define stable logical names and fields for developer credentials without storing their values in the public repository.
4. Implement `secret-run` to retrieve only the credentials required by one child process.
5. Disable command tracing around retrieval and never print secret values in diagnostics.
6. Avoid persistent shell-wide exports and shell-startup secret loading.
7. Prefer stdin, process-scoped environment, or native credential agents.
8. For tools that require a file, create a private local file atomically with mode 0600 and treat it as a regenerable cache.
9. Reauthenticate OAuth-based tools instead of copying token databases.
10. Generate new per-device SSH keys and register only their public keys.
11. Migrate Git signing to a per-device signing key rather than restoring the current machine's private signing configuration.
12. Remove pass, GPG secret-store integration, and legacy plaintext handling only after all consumers work through LastPass.

LastPass remains the sole operational secret authority, but it cannot contain the only means of recovering itself. Keep the master credential recovery method, MFA recovery codes, and at least one independent authentication factor offline. This is break-glass recovery, not a second password manager.

Exit gate:

- Every durable developer secret has an identified LastPass owner and consumer.
- No active secret is read from `~/.secrets`, pass, shell startup, or the public repository.
- Diagnostics and failed retrieval paths reveal no secret values.
- New SSH access, Git signing, and one API-key consumer work on the clean machine.

### Phase 6: Handle macOS and application boundaries

**Purpose:** Automate only stable developer behavior and leave security-sensitive approvals to macOS.

Implementation work:

1. Keep macOS defaults to a small, tested allowlist relevant to development.
2. Record each managed preference's domain, key, type, desired value, supported macOS version, prior value, and refresh requirement.
3. Avoid importing whole preference domains or editing live preference plists directly.
4. Treat Accessibility, Input Monitoring, Full Disk Access, Screen Recording, system extensions, and login items as manual approvals.
5. Provide a functional test beside every manual permission step.
6. Let Hermes, OpenClaw, Watchman, and similar tools recreate their generated LaunchAgents through their owning installers.
7. Keep the custom download router outside the developer profile unless separately requested. Its personal routing rules must not enter the public repository.
8. Do not copy TCC databases, login-item databases, cookies, browser sessions, or application authentication state.

Exit gate:

- Automated defaults verify after application.
- Manual permission documentation identifies the exact app, permission, reason, and behavior test.
- No generated LaunchAgent or security database is treated as portable source.

### Phase 7: Prove fresh-machine behavior

**Purpose:** Validate the user journey rather than merely checking individual scripts.

Primary end-to-end scenario:

1. Start with a clean Apple Silicon macOS user whose username differs from the source Mac.
2. Retrieve a reviewed public release without GitHub authentication.
3. Complete bootstrap prerequisites and core installation.
4. Authenticate to LastPass interactively.
5. Apply portable configuration.
6. Generate and register a new SSH key.
7. Clone one private project.
8. Build or test representative projects for each retained runtime family.
9. Open Ghostty, start tmux, launch Neovim, and verify shell completion, clipboard, font, and editor integration.
10. Run the full bootstrap again and observe no unexplained changes.

Failure and recovery scenarios:

- Command Line Tools installation requires a pause and resume.
- Homebrew download is interrupted.
- GitHub is temporarily unavailable.
- LastPass login is rejected or MFA is unavailable.
- A target dotfile already exists as a regular file.
- A project directory exists with a different remote.
- An optional runtime or application is unavailable.
- The bootstrap is terminated during each major phase.
- A supported command resolves to the wrong architecture or installation owner.
- Manual macOS permission is denied.

Required verification:

- Shell syntax and static checks for all scripts.
- Template rendering for a differently named ARM64 user.
- Secret scanning of the working tree and complete Git history.
- `brew bundle check` for every selected profile.
- `chezmoi diff` and `chezmoi status` after application.
- Login, non-login, interactive, non-interactive, nested, tmux, and agent-mode zsh startup without stderr.
- Executable path, architecture, and version checks for critical tools.
- Representative project builds at real process and filesystem boundaries.
- A second-run idempotence test.
- A restore test for one prior dotfiles release and one repository bundle.

Exit gate:

- All primary and relevant failure scenarios pass on a clean Apple Silicon environment.
- Remaining manual steps are visible and accurately reported as incomplete.
- The old Mac is not required for normal authentication or project restoration.

### Phase 8: Cut over and clean up

**Purpose:** Remove obsolete state only after the replacement is proven.

Implementation work:

1. Tag the tested dotfiles release and record the supported macOS version.
2. Retain the prior known-good tag and package inventory for rollback.
3. Use the new Mac for representative work before decommissioning the old one.
4. Remove redundant runtime managers and stale packages in separate reviewed changes.
5. Re-run command ownership and representative build checks after cleanup.
6. Revoke old-device SSH keys, sessions, OAuth grants, and linked-device registrations.
7. Retain the encrypted migration snapshot until the agreed verification period ends.
8. Erase the old Mac only after every acceptance gate passes.

Exit gate:

- The new Mac is the active development machine.
- Old-device credentials and sessions are revoked.
- Cleanup did not change project behavior.
- Rollback artifacts remain readable for the retention period.

## 6. Rollback model

Rollback must be designed before implementation begins.

| Surface               | Rollback method                                                                                                |
|-----------------------|----------------------------------------------------------------------------------------------------------------|
| Dotfiles              | Check out the prior reviewed tag, preview chezmoi changes, then apply targeted files                           |
| Existing target files | Restore private per-run backups with original type, mode, ownership, and symlink target                        |
| Homebrew packages     | Reinstall from the pre-migration inventory; do not promise exact historical bottles unless separately archived |
| Runtimes              | Reinstall versions from project manifests and retained runtime inventory                                       |
| Projects              | Restore from verified private remotes or encrypted repository bundles                                          |
| macOS preferences     | Restore only if the current value still equals the value installed by the bootstrap                            |
| LaunchAgents          | Unload only the exact managed label, restore prior files, validate, and reload only if previously active       |
| Secrets               | Revoke the replacement only after the prior or next credential is confirmed usable                             |

Package removal, credential revocation, and old-Mac erasure must never be automatic rollback steps.

## 7. Release and maintenance policy

1. Bootstrap from the latest commit on the dotfiles repository's `main` branch.
2. Protect the GitHub account with strong MFA and retain independent account recovery material.
3. Keep the public repository anonymous-cloneable so initial setup does not depend on SSH credentials.
4. Test each supported macOS major release before claiming support.
5. Warn and stop on an untested future macOS major release unless the user explicitly overrides the check.
6. Review the Brewfile and runtime manifests periodically instead of generating them blindly from installed state.
7. Run the doctor after package, shell, runtime, or macOS upgrades.
8. Re-run clean-machine acceptance after significant bootstrap or shell changes.
9. Keep external shell and editor plugin revisions reviewed and reproducible.
10. Treat application sync services as convenience layers, not configuration authorities.

## 8. Final acceptance checklist

- [ ] Every credential formerly in `~/.secrets/keys` is replaced and revoked.
- [ ] Every valuable repository has a verified private remote or encrypted bundle.
- [ ] The public dotfiles working tree is clean and pushed.
- [ ] Public source and history scans contain no credentials.
- [ ] No portable file embeds the source username or source home directory.
- [ ] Every selected package and runtime has one declared owner.
- [ ] Bootstrap succeeds from a clean Apple Silicon account.
- [ ] LastPass retrieval works without persistent shell exports or leaked output.
- [ ] Fresh SSH access and Git signing work.
- [ ] Representative projects build on the new machine.
- [ ] Ghostty, tmux, Neovim, shell completion, clipboard, and fonts work together.
- [ ] Manual macOS permission checks pass.
- [ ] A second bootstrap run is idempotent.
- [ ] One interrupted-run scenario resumes successfully per major phase.
- [ ] Dotfiles and one project have passed a restoration test.
- [ ] The old Mac remains available until all previous checks pass.

## 9. Implementation order

Implementation should proceed through small, reviewable changes in this order:

1. Credential containment and source freeze.
2. Repository audit and temporary migration snapshot.
3. Chezmoi portability and deterministic-source fixes.
4. Core package manifest and ownership ledger.
5. Runtime and editor manifests.
6. Bootstrap preflight and foundation stages.
7. Targeted chezmoi apply stages.
8. LastPass command-boundary integration.
9. Doctor and behavior-first acceptance suite.
10. Clean-machine validation and tagged release.
11. Optional profiles and non-destructive cleanup.

No phase may begin destructive cleanup until its replacement behavior has passed the corresponding exit gate.
