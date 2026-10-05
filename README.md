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

- **Centralized**: No workflow files, secrets, or variables are needed in target repositories. Only the GitHub App needs to be installed on target repositories (or account-wide).
- **Least-Privilege App Tokens**: GitHub App tokens are scoped strictly to the target repositories specified in each workflow.
- **Multiple Repositories in One Workflow**: A single workflow can check and modernize several sibling repositories (e.g., all my dprint plugins) using `allowed-repos`.
- **Token Efficient**:
  - Checks open pull requests to avoid opening duplicate PRs.
  - Pre-steps check recent commits before invoking the AI agent.
- **Feedback-Aware (Zero-Memory)**: Reads past closed pull requests in the target repository to avoid proposing changes that were previously rejected or abandoned.
- **Cross-Repository Pull Requests**: Emits pull requests to target repositories through GitHub App permissions and safe outputs.

## Documentation

- [Setup & Configuration](docs/setup.md): Required secrets, GitHub App, custom instructions (`AGENTS.md`), and skills.
- [Modernization Rules](.github/workflows/shared/modernize-rules.md): Reference repositories and update guardrails used by the agent.

## Commands

```bash
# Compile markdown workflows into GitHub Actions lock files
task compile

# Check and lint all files (dprint, typos, zizmor, compile check)
task lint
```
