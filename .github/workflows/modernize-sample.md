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
      - '**/*merge*.y?ml'
      - '**/*merge*.yaml'
    allowed-repos:
      - 'kachick/dprint-plugin-kdl'
      - 'kachick/dprint-plugin-sh'
      - 'kachick/dprint-plugin-nix'
    max: 3
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

Reference repository: `kachick/dprint-plugins` (or template repository)

## Instructions

For each target repository listed above:

1. Inspect its configuration, CI workflows, and tool setups (such as Nix, Taskfile, and GitHub Actions).
2. Check open pull requests: if a pull request matching `[repo-modernizer] ` is already open, skip proposing new changes for that repository to prevent duplicates.
3. Check past closed pull requests: inspect PRs matching `[repo-modernizer] ` to avoid repeating previously closed or rejected changes.
4. If there are valuable updates from the reference repository, create a pull request targeting that repository (specify the `repo` field in `create_pull_request`).
5. If no updates are necessary for a repository, skip it.
