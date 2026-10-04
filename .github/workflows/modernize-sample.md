---
name: modernize-sample
on:
  schedule: daily
  workflow_dispatch:
  # Skip early when a pull request from this workflow is already open
  skip-if-match: 'repo:kachick/sample-target is:pr is:open "[repo-modernizer] " in:title'
imports:
  - shared/modernize-rules.md
engine:
  id: gemini
  model: gemini-2.5-pro
permissions:
  contents: read
steps:
  - name: Check recent commits in reference repository
    env:
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    run: |
      COMMITS=$(gh api "repos/kachick/anylang-template/commits?since=$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)" --jq 'length' || echo "1")
      if [ "$COMMITS" = "0" ]; then
        echo "No recent commits in reference repository. Skipping agent execution."
        exit 0
      fi
safe-outputs:
  threat-detection: false
  create-pull-request:
    target-repo: "kachick/sample-target"
    title-prefix: "[repo-modernizer] "
    branch-prefix: "modernize/"
    draft: false
    allowed-files:
      - ".github/**"
      - "*.yml"
      - "*.yaml"
      - "*.toml"
      - "*.json*"
      - "Makefile"
      - "Taskfile*"
      - "flake.*"
---

## Mission

Reconcile and modernize the target repository (`kachick/sample-target`) by comparing its setup with the reference repository (`kachick/anylang-template`).

## Instructions

1. Inspect the latest CI, tooling, and workflow patterns in `kachick/anylang-template`.
2. Inspect the current files in `kachick/sample-target`.
3. Check past closed PRs in `kachick/sample-target` matching `[repo-modernizer] ` to avoid proposing rejected changes.
4. Prepare and submit a pull request if there are meaningful modernizations to apply.
5. If no updates are necessary, exit cleanly without making changes.
