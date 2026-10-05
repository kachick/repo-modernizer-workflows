# repo-modernizer-workflows

Centralized repository for GitHub Agentic Workflows ([gh-aw](https://github.com/github/gh-aw)) that modernize and reconcile repository configurations.

## Motivation

This is a very personal project. I maintain multiple repositories across different languages like Rust, Go, and others. While each repository solves a different problem, their tooling and environment setup (such as Nix, CI workflows, linters, and Taskfile) often share common patterns.

Keeping these repositories up to date is hard:

- **Template decay**: Updating my template repository does not help existing projects. I must still update each project by hand.
- **Maintenance toil**: Manually copying files and updating configs takes time and causes mistakes. When this toil piles up, I lose the energy to build small, fun tools to make my life easier.
- **Scattered repositories**: Some tools require separate repositories by design. For example, [dprint](https://dprint.dev/) plugins must each be created and released in their own repository rather than a single monorepo. While their inner logic differs, their outer setup (CI, build, linting) is almost identical. As I create more plugins, syncing them by hand becomes painful.

This repository automates that upkeep. It acts as a single central hub that checks reference setups and sends pull requests to keep my target repositories fresh.

## Features

- **Centralized**: No extra workflow files or settings are needed in target repositories.
- **Multiple Repositories in One Workflow**: A single workflow can check and modernize several sibling repositories (e.g., all my dprint plugins) using `allowed-repos`.
- **Token Efficient**:
  - Checks open pull requests to avoid opening duplicate PRs.
  - Pre-steps check recent commits before invoking the AI agent.
- **Feedback-Aware (Zero-Memory)**: Reads past closed pull requests in the target repository to avoid proposing changes that were previously rejected or abandoned.
- **Cross-Repository Pull Requests**: Emits pull requests to target repositories through GitHub App permissions and safe outputs.

## Reference Repositories

The workflows compare target repositories against these reference repositories based on their roles:

| Repository                                                                            | Role                    | Purpose & Handling                                                                                                            |
| ------------------------------------------------------------------------------------- | ----------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| [`kachick/anylang-template`](https://github.com/kachick/anylang-template)             | General baseline        | Baseline template for standard project configurations. Changes are backported here from active projects over time.            |
| [`kachick/dotfiles`](https://github.com/kachick/dotfiles)                             | Toolchain & environment | Personal environment setup. Continuously updated with the latest tool versions, Nix flakes, and runner tags (`ubuntu-26.04`). |
| [`kachick/selfup`](https://github.com/kachick/selfup)                                 | Go + Nix reference      | Reference base for Go and Nix toolchain setups.                                                                               |
| [`kachick/dprint-plugin-typstyle`](https://github.com/kachick/dprint-plugin-typstyle) | dprint plugin template  | Reference base for `dprint-plugin-*` repositories. Shared plugin improvements aggregate here over time.                       |

## Directory Structure

```text
.github/workflows/
├── shared/
│   └── modernize-rules.md     # Common instructions and guardrails
├── modernize-sample.md        # Source markdown workflow definition
└── modernize-sample.lock.yml  # Compiled GitHub Actions workflow
```

## Setup & Required Secrets

Configure these secrets and variables in this repository (`Settings` -> `Secrets and variables` -> `Actions`):

| Secret / Variable | Type               | Description                                                                                      |
| ----------------- | ------------------ | ------------------------------------------------------------------------------------------------ |
| `GEMINI_API_KEY`  | Secret             | API key for Google Gemini engine                                                                 |
| `APP_ID`          | Secret or Variable | GitHub App ID / Client ID with `contents: write`, `pull-requests: write`, and `workflows: write` |
| `APP_PRIVATE_KEY` | Secret             | GitHub App Private Key                                                                           |

## Custom Instructions & Skills

### Project Instructions (`AGENTS.md`)

Place an `AGENTS.md` file in the root of this repository. The `gh-aw` Gemini engine automatically loads `AGENTS.md` as ambient project instructions for all agent runs. No special workflow configuration is needed.

### Using Skills

You can attach skills to workflows using the `skills:` frontmatter field:

```yaml
skills:
  # Local skill within this repository
  - .github/skills/my-nix-skill

  # Skill from another repository (pinned to a 40-character commit SHA)
  # For private repositories, pass a GitHub App or token with read permissions
  - skill: kachick/my-skills/repo-gardening@801dca688564c529fa84f247f64472520d9ebe28
    github-token: ${{ secrets.GH_TOKEN }}
```

## Workflow Updates & Auto-Merge Safety

To let the agent modernize `.github/workflows/` files (like CI and linters), set `allow-workflows: true`.

To prevent the agent from tampering with auto-merge or release automation, use `excluded-files` with glob patterns:

```yaml
safe-outputs:
  create-pull-request:
    allow-workflows: true
    excluded-files:
      # Strictly exclude any workflow files matching merge patterns
      - '**/*merge*.y?ml'
      - '**/*merge*.yaml'
```

Matching files are stripped at git patch creation time. The agent cannot modify them.

## How to Add or Customize Workflows

1. Create or edit a markdown file in `.github/workflows/modernize-<category>.md`.
2. Import shared rules via `imports: [shared/modernize-rules.md]`.
3. List target repositories under `safe-outputs.create-pull-request.allowed-repos`.
4. Run `task compile` to generate the corresponding `.lock.yml`.

## Commands

```bash
# Compile markdown workflows into GitHub Actions lock files
task compile

# Check workflow definitions without generating lock files
task check
```
