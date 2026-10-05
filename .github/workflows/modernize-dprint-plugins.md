---
name: modernize-dprint-plugins
on:
  schedule: daily
  workflow_dispatch:
imports:
  - shared/modernize-rules.md
engine:
  id: gemini
model: gemini-3.8-flash
runs-on: ubuntu-26.04
permissions:
  contents: read
network:
  allowed:
    - defaults
    - play.googleapis.com
checkout:
  - path: .
  - repository: kachick/llm-config
    path: .llm-config
    ref: main
    sparse-checkout: |
      home/dot_gemini/AGENTS.md
      home/dot_gemini/config/skills
    github-app:
      app-id: ${{ vars.REPO_MODERNIZER_APP_ID }}
      private-key: ${{ secrets.REPO_MODERNIZER_APP_PRIVATE_KEY }}
      repositories:
        - llm-config
  - repository: kachick/dprint-plugin-kdl
    path: repos/dprint-plugin-kdl
  - repository: kachick/dprint-plugin-sh
    path: repos/dprint-plugin-sh
  - repository: kachick/dprint-plugin-nix
    path: repos/dprint-plugin-nix
  - repository: kachick/dprint-plugin-typstyle
    path: refs/dprint-plugin-typstyle
  - repository: kachick/anylang-template
    path: refs/anylang-template
steps:
  - name: Check whether modernization is needed
    id: check_upstream
    env:
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    run: |
      # Check reference repository or conditions before doing heavy tool setup
      # Set needed=true to proceed with Nix and home-manager installation
      echo "needed=true" >> "$GITHUB_OUTPUT"

pre-agent-steps:
  - name: Setup Nix and Cachix
    if: steps.check_upstream.outputs.needed == 'true'
    uses: kachick/dotfiles/.github/actions/setup-nix@main
    with:
      cachix-auth-token: ${{ secrets.CACHIX_AUTH_TOKEN }}

  - name: Setup home-manager tools
    if: steps.check_upstream.outputs.needed == 'true'
    run: |
      mkdir -p ~/.local/state/nix/profiles
      nix run 'github:kachick/dotfiles#home-manager' -- switch -b backup --flake 'github:kachick/dotfiles#github-actions@ubuntu-26.04'
      echo "$HOME/.nix-profile/bin" >> "$GITHUB_PATH"

  - name: Install AGENTS.md and skills from llm-config
    if: steps.check_upstream.outputs.needed == 'true'
    run: |
      mkdir -p .gemini/skills .agents/skills ~/.gemini/config/skills
      cp .llm-config/home/dot_gemini/AGENTS.md ./AGENTS.md
      cp .llm-config/home/dot_gemini/AGENTS.md ~/.gemini/AGENTS.md
      cp -r .llm-config/home/dot_gemini/config/skills/* .gemini/skills/
      cp -r .llm-config/home/dot_gemini/config/skills/* .agents/skills/
      cp -r .llm-config/home/dot_gemini/config/skills/* ~/.gemini/config/skills/

  - name: Configure Gemini CLI for proxy auth
    if: steps.check_upstream.outputs.needed == 'true'
    run: |
      mkdir -p ~/.gemini .gemini
      cat <<'EOF' > .gemini/settings.json
      {
        "security": {
          "auth": {
            "useExternal": true
          }
        }
      }
      EOF
      cp .gemini/settings.json ~/.gemini/settings.json
safe-outputs:
  threat-detection: false
  report-incomplete: false
  report-failure-as-issue: false
  report-failed-jobs: false
  github-app:
    app-id: ${{ vars.REPO_MODERNIZER_APP_ID }}
    private-key: ${{ secrets.REPO_MODERNIZER_APP_PRIVATE_KEY }}
    repositories:
      - repo-modernizer-workflows
      - dprint-plugin-kdl
      - dprint-plugin-sh
      - dprint-plugin-nix
  create-pull-request:
    allow-workflows: true
    fallback-as-issue: false
    github-token-for-extra-empty-commit: 'app'
    excluded-files:
      - 'flake.lock'
      - '*merge*.y*ml'
    allowed-repos:
      - 'kachick/dprint-plugin-kdl'
      - 'kachick/dprint-plugin-sh'
      - 'kachick/dprint-plugin-nix'
    max: 10
    title-prefix: '[repo-modernizer] '
    branch-prefix: 'modernize/'
    draft: false
---

## Mission

Reconcile and modernize the target repositories by comparing their setups with the reference repository.

## Target Repositories

- `kachick/dprint-plugin-kdl` (checked out at `repos/dprint-plugin-kdl`)
- `kachick/dprint-plugin-sh` (checked out at `repos/dprint-plugin-sh`)
- `kachick/dprint-plugin-nix` (checked out at `repos/dprint-plugin-nix`)

## Reference Repositories

- **Primary reference**: `kachick/dprint-plugin-typstyle` (checked out at `refs/dprint-plugin-typstyle`, the template and aggregation base for dprint plugins)
- **General baseline**: `kachick/anylang-template` (checked out at `refs/anylang-template`, general project setup and configurations)
- **Toolchain reference**: `kachick/dotfiles` (latest tool versions, Nix flakes, and runner tags)

## Instructions

For each target repository in `repos/<repo-name>`:

1. Inspect its configuration, CI workflows, and tool setups (such as Nix, Taskfile, and GitHub Actions) by comparing with the reference repositories in `refs/`.
2. Follow the modernization guidelines in shared rules to determine necessary changes.
3. If changes are needed for a category:
   - Change directory into the target repository `repos/<repo-name>`.
   - Create a new branch named `modernize/<category>` (e.g. `git checkout -b modernize/ci`).
   - Apply the edits and verify them locally.
   - Commit the changes with an informative commit message and permalinks to references.
   - Use the `create_pull_request` tool from safeoutputs:
     - `repo`: `kachick/<repo-name>`
     - `branch`: `modernize/<category>` (must match the local git branch name)
     - `title`: `[repo-modernizer] [<category>] <short description>`
     - `body`: Detailed description of the modernization and reference permalinks.
