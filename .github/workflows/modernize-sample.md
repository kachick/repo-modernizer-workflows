---
name: modernize-sample
on:
  schedule: daily
  workflow_dispatch:
imports:
  - shared/modernize-rules.md
engine:
  id: gemini
model: gemini-2.5-pro
runs-on: ubuntu-26.04
permissions:
  contents: read
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
safe-outputs:
  threat-detection: false
  github-app:
    app-id: ${{ vars.APP_ID || secrets.APP_ID }}
    private-key: ${{ secrets.APP_PRIVATE_KEY }}
  create-pull-request:
    allow-workflows: true
    excluded-files:
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
