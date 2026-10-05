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
features:
  action-tag: '924af5fdc64061cfbf66fb584c8b07e2ac230c60' # v0.89.21
permissions:
  contents: read
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
safe-outputs:
  threat-detection: false
  github-app:
    app-id: ${{ vars.REPO_MODERNIZER_APP_ID }}
    private-key: ${{ secrets.REPO_MODERNIZER_APP_PRIVATE_KEY }}
    repositories:
      - dprint-plugin-kdl
      - dprint-plugin-sh
      - dprint-plugin-nix
  create-pull-request:
    allow-workflows: true
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

- `kachick/dprint-plugin-kdl`
- `kachick/dprint-plugin-sh`
- `kachick/dprint-plugin-nix`

## Reference Repositories

- **Primary reference**: `kachick/dprint-plugin-typstyle` (the template and aggregation base for dprint plugins)
- **General baseline**: `kachick/anylang-template` (general project setup and configurations)
- **Toolchain reference**: `kachick/dotfiles` (latest tool versions, Nix flakes, and runner tags)

## Instructions

For each target repository:

1. Inspect its configuration, CI workflows, and tool setups (such as Nix, Taskfile, and GitHub Actions).
2. Reconcile with the reference repositories following the modernization guidelines in shared rules.
