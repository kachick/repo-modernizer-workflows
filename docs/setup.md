# Setup and Configuration

This document explains how to set up, configure, and extend agentic workflows in this repository.

## Required Secrets and Variables

Configure these secrets and variables in GitHub (`Settings` -> `Secrets and variables` -> `Actions`):

| Secret / Variable                 | Type     | Description                                                                           |
| --------------------------------- | -------- | ------------------------------------------------------------------------------------- |
| `GEMINI_API_KEY`                  | Secret   | API key for the Google Gemini engine.                                                 |
| `REPO_MODERNIZER_APP_ID`          | Variable | GitHub App ID with `contents: write`, `pull-requests: write`, and `workflows: write`. |
| `REPO_MODERNIZER_APP_PRIVATE_KEY` | Secret   | GitHub App Private Key.                                                               |
| `CACHIX_AUTH_TOKEN`               | Secret   | Cachix authentication token for the `kachick-dotfiles` binary cache.                  |

## GitHub App Setup & Permissions

1. Create a dedicated GitHub App (e.g. `repo-modernizer`) with these repository permissions:
   - `Contents`: Read and write
   - `Pull requests`: Read and write
   - `Workflows`: Read and write
2. Install the GitHub App on your target repositories and configuration repositories (e.g. `llm-config` with read access).
   - Target repositories do not need secrets, variables, or workflow files. Everything runs centrally from this repository.
   - For least privilege, workflows scope minted App tokens to target repositories using `safe-outputs.github-app.repositories` and checkout `github-app.repositories`.
3. Configure `REPO_MODERNIZER_APP_ID` (Variable) and `REPO_MODERNIZER_APP_PRIVATE_KEY` (Secret) in this repository.

## Custom Instructions & Skills

### Remote Instructions & Skills (`llm-config`)

Workflows load ambient agent instructions (`AGENTS.md`) and custom skills from the private configuration repository `kachick/llm-config` on branch `main`:

```yaml
checkout:
  - path: .
  - repository: kachick/llm-config
    path: .llm-config
    ref: main
    sparse-checkout: |
      home/dot_gemini/AGENTS.md
      home/dot_gemini/config/skills/git-workflow
    github-app:
      app-id: ${{ vars.REPO_MODERNIZER_APP_ID }}
      private-key: ${{ secrets.REPO_MODERNIZER_APP_PRIVATE_KEY }}
      repositories:
        - llm-config
```

In `pre-agent-steps`, the files are copied into `.gemini/skills/git-workflow`, `.agents/skills/git-workflow`, and `~/.gemini/config/skills/git-workflow` before the AI agent runs.

Make sure the GitHub App is installed on `kachick/llm-config` with `Contents: Read` access.

## Workflow Updates & Auto-Merge Safety

To let the agent modernize `.github/workflows/` files (like CI and linters), set `allow-workflows: true`.

To prevent the agent from changing auto-merge or release automation, use `excluded-files`:

```yaml
safe-outputs:
  create-pull-request:
    allow-workflows: true
    excluded-files:
      - 'flake.lock'
      - '*merge*.y*ml'
```

Matching files are stripped before creating a pull request. The agent cannot modify them.

## How to Add or Customize Workflows

1. Create or edit a markdown file in `.github/workflows/modernize-<category>.md`.
2. Import shared rules via `imports: [shared/modernize-rules.md]`. See [`.github/workflows/shared/modernize-rules.md`](../.github/workflows/shared/modernize-rules.md) for reference repository roles and update guidelines.
3. List target repositories under `safe-outputs.create-pull-request.allowed-repos` and `safe-outputs.github-app.repositories`.
4. Run `task compile` to generate the corresponding `.lock.yml`.
