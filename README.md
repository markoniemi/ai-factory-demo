# task — a Claude Code plugin

A backlog-to-branch task protocol. A human writes down what should happen; the agent
plans it, implements it on a branch with unit tests; the human verifies the plan,
reads the diff and merges.

This repository is both the plugin and its marketplace.

## Install

```
/plugin marketplace add markoniemi/task-plugin
/plugin install task@task-plugin
```

Installing at user scope makes it available in every project on the machine. During
development, `claude --plugin-dir <path-to-this-clone>` loads it straight from disk,
and `claude plugin validate .` checks the manifests.

## Commands

| Command | What it does |
| :- | :- |
| `/task:init` | Set `docs/tasks/` up in a project that has no backlog yet. Run it first; it changes nothing if the backlog is already there. |
| `/task:task [name-of-task]` | Start, continue or finish the named task. With no name, states the protocol and lists the tasks. |
| `/task:next-task` | Take the next open backlog entry: highest priority, then first in `Tasks.md`. |
| `/task:clean-tasks` | Delete the `done` tasks and their backlog entries, one commit each. Only when you ask. |

The protocol itself — the task file shape, the statuses and the transitions — is
`skills/task/SKILL.md`.

## What a project using the plugin keeps

```
docs/tasks/Tasks.md          the backlog: one heading per task idea
docs/tasks/<slug>.md         one file per task: frontmatter, description, plan
docs/tasks/README.md         the pipeline, explained for humans
```

No `AGENTS.md` and no stub: the rules come from the plugin.

A backlog entry is a heading plus a short explanation, with the status and the
priority in brackets:

```markdown
### move Tasks to docs/tasks [draft, high]

Move the task directory from `Tasks/` to `docs/tasks/` so all documentation
lives under `docs/`.
```

Statuses: `draft` → `planning` → `planned` → `in_progress` → `in_review` →
`approved` → `done`, with `changes_requested` back to `in_review`. A human moves
`draft` → `planning`, verifies the plan at `planned`, reviews the diff at
`in_review` and merges at `approved`; the agent does the rest. Priorities are
`high`, `medium` and `low`.

## Configuration

The plugin asks for two values when you enable it, and `/config` shows them:

| Key | Default | What it permits |
| :- | :- | :- |
| `create_branch` | `true` | A task may have its own branch. Off: every task is committed on `main`. |
| `create_pull_request` | `false` | Reaching `in_review` pushes the branch and opens a pull request on GitHub, or a merge request on GitLab. The host then does the merging. |

Those answers are per user, so a project states its own in YAML frontmatter at the
top of its `docs/tasks/Tasks.md`, which wins over them:

```markdown
---
create_branch: true
create_pull_request: false
---
```

Each key is a ceiling, not a default: `create_branch: false` means no task gets a
branch, and nothing per task overrides it. `create_pull_request: true` needs
`create_branch: true`, plus `gh` or `glab` authenticated for the `origin` remote;
the plugin picks the tool from that remote.

## Tests

```
powershell -File tests/Test-Plugin.ps1
```

Plain PowerShell, no Pester. It checks the two manifests, the three skills'
frontmatter, that the protocol's statuses and rules survived, that no `AGENTS.md` is
left behind, and that `claude plugin validate` passes.

## This repository's own backlog

`docs/tasks/` is this project's backlog, kept here on purpose: the plugin is
developed with itself.

## Licence

MIT.
