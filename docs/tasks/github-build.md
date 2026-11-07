---
id: github-build
status: in_progress
priority: low
kind: task
---

# github build

The backlog entry carried no explanation - the heading was all there was - and a
human set it to `planned`, which waives the plan. So the description is the
heading, and what follows is the reading it was implemented under. Say so if it is
the wrong one; the work is one file.

## What this was taken to mean

A GitHub Actions workflow that runs this repository's own unit tests on every push
and pull request. The tests are Windows PowerShell, so the runner is Windows.

Deliberately **not** included, because each needs a decision no description asked
for:

* `claude plugin validate . --strict`. The suite already skips that case when the
  `claude` CLI is absent, and installing and authenticating the CLI on a runner is
  its own task.
* A release job - tagging, or bumping `version` in `.claude-plugin/plugin.json`.
* A second job on `pwsh` 7. The protocol and the suite target Windows PowerShell
  5.1 on purpose; adding 7 would be a portability decision, not a build.