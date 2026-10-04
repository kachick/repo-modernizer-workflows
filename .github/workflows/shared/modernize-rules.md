## Modernization Guidelines

When reconciling and modernizing target repository files against reference repositories, follow these rules:

### 1. Check Past Closed Pull Requests (Learn from Feedback)
- Search closed pull requests created by this workflow in the target repository (matching the `[repo-modernizer]` title prefix).
- Inspect whether any PRs were closed without merging (e.g., closed with reason `not_planned`, or with rejecting maintainer comments).
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
