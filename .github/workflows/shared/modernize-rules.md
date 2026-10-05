## Modernization Guidelines

When reconciling and modernizing target repository files against reference repositories, follow these rules:

### 1. Check Open and Closed Pull Requests (Prevent Duplicates & Learn from Feedback)

- **Open PRs**: If a pull request created by this workflow (matching the `[repo-modernizer]` title prefix) is already open in the target repository, skip creating new pull requests for that repository to prevent duplicates.
- **Closed PRs**: Search closed pull requests matching `[repo-modernizer]`. Inspect whether any PRs were closed without merging (e.g., closed with reason `not_planned`, or with rejecting maintainer comments).
- **Never propose changes that were previously rejected or abandoned.** Respect past maintainer decisions.

### 2. Focus on Environment, CI, and Tooling

- Focus on configuration files, CI workflows, build scripts, linters, formatters, and repository infrastructure.
- Accompany manifest changes with corresponding lockfile updates when necessary (e.g. updating `Cargo.lock` alongside `Cargo.toml`, or `flake.lock` alongside `flake.nix`).
- **Do not modify application business logic or domain code.**
- **Do not modify auto-merge, release, or deployment workflows.**
- Only adopt improvements that make sense for the target repository's stack. Do not blindly copy incompatible settings.

### 3. Verify and Keep Changes Minimal

- If there are no meaningful or necessary updates from the reference repository, do not create a pull request (emit `noop`).
- Keep diffs small, focused, and easy to review.
- Clearly describe the purpose of each change in the pull request body, including links to the reference commit or repository.

### 4. Reference Repositories and Their Roles

When inspecting reference repositories, treat each one according to its purpose:

- **`kachick/anylang-template`**:
  - The baseline template for all projects.
  - Contains standard configuration, linting, CI, and setup patterns.
  - Note: Changes are backported here from other active projects over time. Other repositories may sometimes be ahead of this template, so do not downgrade newer settings found in target repositories.

- **`kachick/dotfiles`**:
  - Personal environment setup repository.
  - While its use case is personal setup, it is continuously updated and has the freshest versions (Nix flakes, runner tags like `ubuntu-26.04`, CI actions, and toolchains).
  - Use this to check the latest versions and recommended environment patterns.

- **`kachick/selfup`**:
  - The reference base for `Go + Nix` setups.
  - Not very actively developed, but useful as a baseline pattern for Go and Nix toolchain integration.

- **`kachick/dprint-plugin-typstyle`**:
  - The reference template specifically for `dprint-plugin-*` repositories.
  - Other dprint plugins aggregate their shared setups here over time.
  - Use this as the primary reference when modernizing any dprint plugin.

- **`kachick/wait-other-jobs`**:
  - A GitHub Action written in TypeScript.
  - While it is a GitHub Action rather than typical frontend or backend code, TypeScript-specific tooling and setup patterns are usually kept here.
  - Use this as the reference base for TypeScript configurations.
