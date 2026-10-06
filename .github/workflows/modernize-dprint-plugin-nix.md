---
name: modernize-dprint-plugin-nix
on:
  workflow_dispatch:
imports:
  - shared/modernize-rules.md
engine:
  id: gemini
model: gemini-3.8-flash
tools:
  cache-memory:
    key: typstyle-ref-sync-nix
runs-on: ubuntu-26.04
permissions:
  contents: read
network:
  allowed:
    - defaults
checkout:
  - path: .
  - repository: kachick/llm-config
    path: .llm-config
    ref: main
    github-app:
      app-id: ${{ vars.REPO_MODERNIZER_APP_ID }}
      private-key: ${{ secrets.REPO_MODERNIZER_APP_PRIVATE_KEY }}
      repositories:
        - llm-config
  - repository: kachick/dprint-plugin-nix
    path: repos/dprint-plugin-nix
  - repository: kachick/dprint-plugin-typstyle
    path: refs/dprint-plugin-typstyle
    fetch-depth: 20
  - repository: kachick/anylang-template
    path: refs/anylang-template
    fetch-depth: 1
steps:
  - name: Check upstream changes and extract modified files
    id: check_upstream
    run: |
      mkdir -p /tmp/gh-aw/agent
      STATE_FILE="/tmp/gh-aw/cache-memory/last_typstyle_sha.txt"
      DIFF_SUMMARY="/tmp/gh-aw/agent/upstream-diff.txt"

      cd refs/dprint-plugin-typstyle
      CURRENT_SHA=$(git rev-parse HEAD)

      if [ -f "$STATE_FILE" ]; then
        PREV_SHA=$(cat "$STATE_FILE")
      else
        # Initial run: compare against up to 10 commits ago
        PREV_SHA=$(git rev-parse HEAD~10 2>/dev/null || git rev-list --max-parents=0 HEAD)
      fi

      echo "Current upstream SHA: $CURRENT_SHA"
      echo "Previous inspected SHA: $PREV_SHA"

      if [ "$CURRENT_SHA" = "$PREV_SHA" ]; then
        echo "No upstream changes detected."
        echo "NO_CHANGES" > "$DIFF_SUMMARY"
        echo "has_changes=false" >> "$GITHUB_OUTPUT"
      else
        echo "has_changes=true" >> "$GITHUB_OUTPUT"
        {
          echo "=== Upstream commits from $PREV_SHA to $CURRENT_SHA ==="
          git log --oneline "$PREV_SHA".."$CURRENT_SHA"
          echo ""
          echo "=== Modified files in upstream ==="
          git diff --name-only "$PREV_SHA".."$CURRENT_SHA"
        } > "$DIFF_SUMMARY"
        echo "$CURRENT_SHA" > "$STATE_FILE"
      fi

pre-agent-steps:
  - name: Configure git bot identity for agent commits
    run: |
      git config --global user.name "repo-modernizer[bot]"
      git config --global user.email "337949002+repo-modernizer[bot]@users.noreply.github.com"
      git config --global diff.external ""

  - name: Setup Nix and Cachix
    uses: kachick/dotfiles/.github/actions/setup-nix@main
    with:
      cachix-auth-token: ${{ secrets.CACHIX_AUTH_TOKEN }}

  - name: Setup home-manager tools
    run: |
      mkdir -p ~/.local/state/nix/profiles
      nix run 'github:kachick/dotfiles#home-manager' -- switch -b backup --flake 'github:kachick/dotfiles#github-actions@ubuntu-26.04'
      echo "$HOME/.nix-profile/bin" >> "$GITHUB_PATH"

  - name: Install AGENTS.md and git-workflow skill from llm-config
    run: |
      mkdir -p .gemini/skills/git-workflow .agents/skills/git-workflow ~/.gemini/config/skills/git-workflow
      cp .llm-config/home/dot_gemini/AGENTS.md ./AGENTS.md
      cp .llm-config/home/dot_gemini/AGENTS.md ~/.gemini/AGENTS.md
      cp -r .llm-config/home/dot_gemini/config/skills/git-workflow/* .gemini/skills/git-workflow/
      cp -r .llm-config/home/dot_gemini/config/skills/git-workflow/* .agents/skills/git-workflow/
      cp -r .llm-config/home/dot_gemini/config/skills/git-workflow/* ~/.gemini/config/skills/git-workflow/
      rm -rf .llm-config

  - name: Configure Gemini CLI for proxy auth and disable telemetry
    run: |
      mkdir -p ~/.gemini .gemini
      cat <<'EOF' > .gemini/settings.json
      {
        "security": {
          "auth": {
            "useExternal": true
          }
        },
        "privacy": {
          "usageStatisticsEnabled": false
        },
        "telemetry": {
          "enabled": false
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
      - dprint-plugin-nix
  create-pull-request:
    allow-workflows: true
    fallback-as-issue: false
    github-token-for-extra-empty-commit: 'app'
    excluded-files:
      - 'flake.lock'
      - '*merge*.y*ml'
    allowed-repos:
      - 'kachick/dprint-plugin-nix'
    max: 5
    title-prefix: '[repo-modernizer] '
    branch-prefix: 'modernize/'
    draft: false
---

## Mission

Reconcile and modernize the target repository `kachick/dprint-plugin-nix` by comparing its setup with the reference repositories.

## Target Repository

- `kachick/dprint-plugin-nix` (checked out at `repos/dprint-plugin-nix`)

## Reference Repositories

- **Primary reference**: `kachick/dprint-plugin-typstyle` (checked out at `refs/dprint-plugin-typstyle`)
- **General baseline**: `kachick/anylang-template` (checked out at `refs/anylang-template`)
- **Toolchain reference**: `kachick/dotfiles` (latest tool versions, Nix flakes, and runner tags)

## Step 0: Check Upstream Diff Summary (CRITICAL)

Before doing any repository scans or diffs:

1. Read `/tmp/gh-aw/agent/upstream-diff.txt`.
2. **If it contains `NO_CHANGES`**:
   - There are no new commits in the reference repository since the previous run.
   - Immediately call the `noop` tool from safeoutputs:
     `noop: "No new upstream commits in reference repository since last run."`
   - Finish immediately. Do NOT run any file diffs or inspect directories.
3. **If changes are listed**:
   - Check `=== Upstream commits ===` first to find what changed (such as tool upgrades, CI workflows, or Nix setups).
   - Read upstream commit messages (such as `git show <commit>`) to understand why and how they changed.
   - Focus on one theme at a time (e.g. `ci`, `nix`, or `lint`). Only inspect and edit files needed for that theme.
   - Do NOT compare every listed file one by one across both repositories. That wastes context and time.
   - In `repos/dprint-plugin-nix/`, you can inspect and edit any files needed to keep the build and tests passing (such as `Cargo.toml` or Nix files), even if they are not in the upstream diff.

## Instructions

1. If upstream changes are relevant to `repos/dprint-plugin-nix`:
   - Follow the modernization guidelines in shared rules to determine necessary changes.
2. If changes are needed for a category:
   - Change directory into `repos/dprint-plugin-nix`.
   - Create a new branch named `modernize/<category>` (e.g. `git checkout -b modernize/ci`).
   - Apply the edits and verify them locally.
   - Commit the changes following the `git-workflow` skill standards (informative message, `Assisted-by: Antigravity:gemini-3.8-flash`, permalinks to reference commits).
   - Use the `create_pull_request` tool from safeoutputs:
     - `repo`: `kachick/dprint-plugin-nix`
     - `branch`: `modernize/<category>` (must match the local git branch name)
     - `title`: `[repo-modernizer] [<category>] <short description>`
     - `body`: Detailed description of the modernization and reference permalinks.
3. If no modernization is needed after reviewing the modified files:
   - Call `noop` from safeoutputs: `noop: "No modernization needed for dprint-plugin-nix from current upstream changes."`
