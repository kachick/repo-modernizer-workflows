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

## Directory Structure

```text
.github/workflows/
├── shared/
│   └── modernize-rules.md     # Common instructions and guardrails
├── modernize-sample.md        # Source markdown workflow definition
└── modernize-sample.lock.yml  # Compiled GitHub Actions workflow
```

## Setup & Required Secrets

Configure these secrets in this repository (`Settings` -> `Secrets and variables` -> `Actions`):

| Secret / Variable | Description |
|---|---|
| `GEMINI_API_KEY` | API key for Google Gemini engine |
| `GH_AW_SAFE_OUTPUTS_TOKEN` / App Secrets | GitHub App Private Key or PAT with `contents: write` and `pull-requests: write` for target repositories |

## How to Add or Customize Workflows

1. Create or edit a markdown file in `.github/workflows/modernize-<category>.md`.
2. Import shared rules via `imports: [shared/modernize-rules.md]`.
3. List your target repositories under `safe-outputs.create-pull-request.allowed-repos` (or set `target-repo` for a single repository).
4. Run `task compile` to generate the corresponding `.lock.yml`.

## Commands

```bash
# Compile markdown workflows into GitHub Actions lock files
task compile

# Check workflow definitions without generating lock files
task check
```
