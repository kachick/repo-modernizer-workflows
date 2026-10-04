# repo-modernizer-workflows

Centralized repository for GitHub Agentic Workflows ([gh-aw](https://github.com/github/gh-aw)) that modernize and reconcile repository configurations.

## Overview

This repository runs daily workflows using Google Gemini to keep target repositories up to date with reference patterns (such as CI workflows, linters, and tool configurations).

Key features:

- **Centralized**: No extra workflow files or settings are needed in target repositories.
- **Token Efficient**:
  - `skip-if-match` skips agent execution when a pull request is already open.
  - Deterministic pre-steps check recent commits via GitHub API before starting the AI agent.
- **Feedback-Aware (Zero-Memory)**: Learns from closed pull requests in target repositories to avoid proposing previously rejected changes.
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

## How to Add a New Workflow

1. Create a new markdown file in `.github/workflows/modernize-<repo-name>.md`.
2. Import the shared rules via `imports: [shared/modernize-rules.md]`.
3. Set your target repository in `safe-outputs.create-pull-request.target-repo` and `skip-if-match`.
4. Run `task compile` (or `gh-aw compile`) to generate the corresponding `.lock.yml`.

## Commands

```bash
# Compile markdown workflows into GitHub Actions lock files
make compile  # or: gh-aw compile

# Check workflow definitions without generating lock files
make check    # or: gh-aw compile --strict --no-emit
```
