# Task Protocol (for AI agents)

Rules for processing the tasks in this directory. This file is the single source of
truth for the rules; `README.md` only explains them to humans.

## Task files

* A task is a file `docs/tasks/task-NNN-<slug>.md`. `README.md`, `AGENTS.md` and
  `Tasks.md` are not task files.
* Every task file starts with this frontmatter:

```yaml
---
id: task-001
status: draft | planning | planned | in_progress | in_review | changes_requested | approved | done
priority: high | medium | low
branch: task/001-short-description
---
```

* The task file is the source of truth for `status` and `priority`. The brackets in
  `Tasks.md` mirror it; keep them in step (see **Backlog mirror**).

## Selection

1. Scan `docs/tasks/task-*.md`.
2. Keep the tasks whose `status` matches the one you were asked to process.
3. Take `high` before `medium` before `low`; on a tie, the oldest file first.

## Creating a task from the backlog

When asked to start a named task, or the next task, from `Tasks.md`:

1. *Next* = highest priority first; among equal priorities, the entry that appears
   first in `Tasks.md`. Skip entries that already have a `plan:` line.
2. `id` = next free number from the existing `task-NNN-*.md` files.
3. Write `docs/tasks/task-NNN-<slug>.md`, where `<slug>` is the entry title in
   lower case with `-` for spaces. Set `branch: task/NNN-<slug>`, take `status` and
   `priority` from the entry's brackets.
4. Copy the entry's explanation into the body as the task description. Do not write
   an implementation plan yet.
5. Add a link to the task file as the first line under the entry's heading:
   `plan: [task-NNN-<slug>.md](task-NNN-<slug>.md)`. Leave the brackets in place.

## Backlog mirror

The brackets in a `Tasks.md` entry always read `[<status>, <priority>]`, for the
whole life of the task. Keep the mirror in step, in both directions:

* You change a task file's `status` → update that entry's brackets in the same
  commit.
* A human changed the brackets → copy the new `status` and `priority` into the task
  file's frontmatter when you next pick the task up, and work from that.

## Transitions

**`draft` → `planning`** — human only. Do not set `planning` yourself.

**`planning` → `planned`** — append a `# Implementation Plan` section to the task
file: the steps, and any open question a human must answer. Set `planned` and stop;
a human verifies the plan.

**`planned` → `in_progress`** — set `in_progress` and commit it on `main`. Create
the branch named in `branch`. Write the code **and unit tests** and commit them on
that branch.

**`in_progress` → `in_review`** — the implementation is committed on the branch and
ready to be read. Set `in_review`. This project uses no pull requests.

**`in_review` → `approved`** — human only: a human reads the branch diff. Accepted →
`approved`. Otherwise → `changes_requested`.

**`changes_requested` → `in_review`** — fix what the review asked for on the task
branch, commit, set `in_review`.

**`approved` → `done`** — merge the branch into `main` (fast-forward), delete the
branch, set `done`.
