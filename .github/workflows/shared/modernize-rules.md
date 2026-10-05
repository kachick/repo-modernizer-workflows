## Modernization Guidelines

When reconciling and modernizing target repository files against reference repositories, follow these rules:

### 1. Split Pull Requests by Category (Work Unit)

- Do not combine all updates into one large pull request.
- Create separate pull requests for each category or unit of work. Common categories include:
  - `nix`: All Nix files (`*.nix` such as `package.nix`, `flake.nix`, modules) and Nix GitHub Actions.
  - `ci`: GitHub Actions runner versions (e.g. `ubuntu-26.04`), workflow steps, and test pipelines.
  - `lint`: Formatter and linter configurations (e.g. `Taskfile.yml`, `dprint`, `typos`).
- Keep diffs focused, small, and easy to review.
- Give each pull request a distinct branch name matching its category, such as `modernize/nix` or `modernize/ci`.
- If two updates modify the exact same file or depend on each other, keep them in the same pull request or wait for the first pull request to merge before opening the next.

### 2. Category-Scoped Pull Request Checks (Prevent Duplicates & Learn from Feedback)

- Format pull request titles with category tags: `[repo-modernizer] [<category>] <short description>` (for example, `[repo-modernizer] [nix] Update flake inputs`).
- **Open PRs**: Search open pull requests for the matching category tag (for example, `[repo-modernizer] [nix]`). If an open pull request already exists for that category, skip creating a new pull request for that category. Do not skip other unrelated categories.
- **Closed PRs**: Search closed pull requests for the matching category tag. Check whether maintainers closed any pull requests without merging (such as `not_planned` or with comments declining the change).
- **Never re-propose changes that maintainers previously rejected in that category.** Rejection in one category does not block other categories.

### 3. Focus on Environment, CI, and Tooling

- Focus on configuration files, CI workflows, build scripts, linters, formatters, and repository infrastructure.
- **Nix Modernization Scope**:
  - Review and modernize all Nix files (`*.nix`), including `package.nix`, `flake.nix`, and related expressions. Only `flake.lock` is excluded.
  - In `package.nix`, apply modern packaging patterns from reference repositories (for example, adding missing attributes like `__structuredAttrs = true;`, updating derivation hooks, or builder flags).
  - In `flake.nix`, modernize devShell tools, integration, and formatters (for example, switching from `nixfmt-tree` to `dprint-plugin-nix`).
  - Modernize Nix GitHub Actions workflows (e.g. `setup-nix` actions).
- **Do not update `flake.lock`**:
  - Routine `flake.lock` updates are handled automatically by scheduled workflows in each repository, and tool versions are managed by `selfup`.
  - Never open a pull request just to update `flake.lock` or bump tool versions.
- Accompany manifest changes with corresponding lockfile updates when necessary (e.g. updating `Cargo.lock` alongside `Cargo.toml`).
- **Do not modify application business logic or domain code.**
- **Do not modify auto-merge, release, or deployment workflows.**
- Only adopt improvements that make sense for the target repository's stack. Do not blindly copy incompatible settings.

### 4. Commit Messages and Reference Permalinks

In each commit made for a pull request, explain the change and record its origin:

- Include reference URLs under a `References:` section in the commit message:
  - **Specific commit**: When the change comes from a specific commit in a reference repository, include the commit permalink:
    `https://github.com/<owner>/<repo>/commit/<commit-sha>`
  - **Tree revision**: When it is difficult to isolate a single commit (such as adopting setup files from a reference repository), include the tree permalink of the revision at the time of reference:
    `https://github.com/<owner>/<repo>/tree/<commit-sha>`
  - **No bare hash values**: Never write bare commit hashes. Always use full GitHub permalinks so maintainers can click and trace the history easily.
- Also include these reference permalinks in the pull request description.

### 5. Verify and Keep Changes Minimal

- If there are no meaningful or necessary updates from the reference repository, do not create a pull request (emit `noop`).
- Keep diffs small, focused, and easy to review.

### 6. Reference Repositories and Their Roles

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
