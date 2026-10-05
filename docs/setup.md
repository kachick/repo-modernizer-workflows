# Setup and Configuration

This document explains how to set up, configure, and extend agentic workflows in this repository.

## Required Secrets and Variables

Configure these secrets and variables in GitHub (`Settings` -> `Secrets and variables` -> `Actions`):

| Secret / Variable   | Type               | Description                                                                           |
| ------------------- | ------------------ | ------------------------------------------------------------------------------------- |
| `GEMINI_API_KEY`    | Secret             | API key for the Google Gemini engine.                                                 |
| `APP_ID`            | Secret or Variable | GitHub App ID with `contents: write`, `pull-requests: write`, and `workflows: write`. |
| `APP_PRIVATE_KEY`   | Secret             | GitHub App Private Key.                                                               |
| `CACHIX_AUTH_TOKEN` | Secret             | Cachix authentication token for the `kachick-dotfiles` binary cache.                  |

## Custom Instructions & Skills

### Project Instructions (`AGENTS.md`)

Place an `AGENTS.md` file in the root of this repository. The `gh-aw` Gemini engine loads `AGENTS.md` as ambient project instructions for all agent runs.

### Using Skills

You can attach skills to workflows using the `skills:` frontmatter field:

```yaml
skills:
  # Local skill within this repository
  - .github/skills/my-nix-skill

  # Skill from another repository (pinned to a commit SHA)
  - skill: kachick/my-skills/repo-gardening@801dca688564c529fa84f247f64472520d9ebe28
    github-token: ${{ secrets.GH_TOKEN }}
```

## Workflow Updates & Auto-Merge Safety

To let the agent modernize `.github/workflows/` files (like CI and linters), set `allow-workflows: true`.

To prevent the agent from changing auto-merge or release automation, use `excluded-files`:

```yaml
safe-outputs:
  create-pull-request:
    allow-workflows: true
    excluded-files:
      - '**/*merge*.y?ml'
      - '**/*merge*.yaml'
```

Matching files are stripped before creating a pull request. The agent cannot modify them.

## Reference Repositories

The workflows compare target repositories against these reference repositories:

| Repository                                                                            | Role                    | Purpose & Handling                                                                                                            |
| ------------------------------------------------------------------------------------- | ----------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| [`kachick/anylang-template`](https://github.com/kachick/anylang-template)             | General baseline        | Baseline template for standard project configurations. Changes are backported here from active projects over time.            |
| [`kachick/dotfiles`](https://github.com/kachick/dotfiles)                             | Toolchain & environment | Personal environment setup. Continuously updated with the latest tool versions, Nix flakes, and runner tags (`ubuntu-26.04`). |
| [`kachick/selfup`](https://github.com/kachick/selfup)                                 | Go + Nix reference      | Reference base for Go and Nix toolchain setups.                                                                               |
| [`kachick/dprint-plugin-typstyle`](https://github.com/kachick/dprint-plugin-typstyle) | dprint plugin template  | Reference base for `dprint-plugin-*` repositories. Shared plugin improvements aggregate here over time.                       |
| [`kachick/wait-other-jobs`](https://github.com/kachick/wait-other-jobs)               | TypeScript reference    | A GitHub Action written in TypeScript. Reference base for TypeScript-specific setups and tooling.                             |

Detailed agent instructions for these repositories are kept in [`.github/workflows/shared/modernize-rules.md`](../.github/workflows/shared/modernize-rules.md).

## How to Add or Customize Workflows

1. Create or edit a markdown file in `.github/workflows/modernize-<category>.md`.
2. Import shared rules via `imports: [shared/modernize-rules.md]`.
3. List target repositories under `safe-outputs.create-pull-request.allowed-repos`.
4. Run `task compile` to generate the corresponding `.lock.yml`.
