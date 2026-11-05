# AI Task Factory

This directory holds the tasks processed by the automated AI developer engine. A
human writes down what should happen; the AI plans it and implements it on a
branch; the human verifies the plan, reads the diff and merges.

* `Tasks.md` — the backlog: one heading per task idea.
* `<slug>.md` — one file per task, with its status and its implementation plan.

The rules the AI follows are not in this directory: they come from the `task`
plugin, as its `task` skill. **The rules live there, not here.** See the
repository's top-level `README.md` for installing the plugin.

## Adding a task

Add a heading plus a short explanation to `Tasks.md`:

```markdown
### move Tasks to docs/tasks [draft, high]

Move the task directory from `Tasks/` to `docs/tasks/` so all documentation
lives under `docs/`.
```

The heading becomes the task file's name: lower-cased, with `-` for every run of
anything else, so `move Tasks to docs/tasks` becomes `move-tasks-to-docs-tasks.md`.
Keep headings short and plain; the AI stops and asks you to edit one it cannot turn
into a file name.

The brackets hold the status and the priority. Then ask the AI to start that task by
name — `/task:task move Tasks to docs/tasks` — or to take the next one —
`/task:next-task`. The AI creates the task file, links it under the heading, and
keeps the brackets up to date from then on:

```markdown
### move Tasks to docs/tasks [done, high]

plan: [move-tasks-to-docs-tasks.md](move-tasks-to-docs-tasks.md)

Move the task directory from `Tasks/` to `docs/tasks/` so all documentation
lives under `docs/`.
```

Edit the brackets yourself to re-prioritise a task or to ask for planning; the AI
reads the change back into the task file.

## Configuration

The top of `Tasks.md` carries this project's answers, as YAML frontmatter:

```markdown
---
create_branch: true
create_pull_request: false
---
```

| Key | Default | What it permits |
| :- | :- | :- |
| `create_branch` | `true` | A task may have its own branch. Off: everything is committed on `main`. |
| `create_pull_request` | `false` | Reaching `in_review` opens a pull request on GitHub, or a merge request on GitLab, instead of leaving the branch to be read locally. On: the host does the merging, and the AI only checks that it happened. |

Each key is a ceiling rather than a default: `create_branch: false` takes the
branch away from every task, whatever else is written down. Omit a key and the
value falls back to your own answer in `/config`, then to the default above. The
AI reads these keys itself; edit them and the next task follows them.

`create_pull_request: true` needs `create_branch: true`, and it needs `gh` or
`glab` on `PATH` and authenticated for the `origin` remote.

## Pipeline

```
Tasks.md entry ──► draft ──► planning ──► planned ──► in_progress ──► in_review ──► approved ──► done
                                                                          │  ▲
                                                                          ▼  │
                                                                   changes_requested
```

A **human** moves `draft` → `planning`, verifies the plan at `planned`, reviews the
branch diff at `in_review`, and merges at `approved`. The AI does the rest. The
plugin's `task` skill is what it does in each step.

Run `/task:clean-tasks` when `done` tasks pile up: it deletes each finished task
file and its backlog entry, having first checked that whatever the task established
is written down in the plugin's skills or here. The plans stay in git history.
