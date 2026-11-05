---
name: task
description: Use when asked to start, continue or finish a named task from the backlog, or when you need the task protocol itself - the status names, the task file shape, the backlog mirror and the transitions. Invoked as /task:task [name-of-task]. The task name is whatever the backlog entry's heading says.
argument-hint: "[name-of-task]"
---

# Task Protocol

The rules for processing tasks in a project's task directory, normally
`docs/tasks/`. This file is the single source of truth for the rules. A project's
own `README.md` explains them to humans; it does not restate them.

ARGUMENTS: `$ARGUMENTS` is the name of the task to work on — the heading of a
`Tasks.md` entry, or a `task-NNN-<slug>` id. With no arguments, state the protocol
and list the tasks with their statuses, and ask which one to take.

## Starting from the task name

1. Find the task. Match `$ARGUMENTS` against the headings in `Tasks.md` and against
   the `task-*.md` file names, case-insensitively; a partial match is enough when it
   is unambiguous. Two candidates → ask which one.
2. No task file yet → create it as **Creating a task** below describes, then
   continue.
3. A task file exists → read its frontmatter, reconcile it with the entry's brackets
   (see **Backlog mirror**), and run the transition its `status` calls for in
   **Transitions**. Stop at the first step that is a human's.

## Task files

* A task is a file `docs/tasks/task-NNN-<slug>.md`. `README.md` and `Tasks.md` are
  not task files.
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

## Creating a task

When the named task has no task file yet:

1. `id` = next free number from the existing `task-NNN-*.md` files.
2. Write `docs/tasks/task-NNN-<slug>.md`, where `<slug>` is the entry title in lower
   case with `-` for spaces. Set `branch: task/NNN-<slug>`, take `status` and
   `priority` from the entry's brackets.
3. Copy the entry's explanation into the body as the task description. Do not write
   an implementation plan yet.
4. Add a link to the task file as the first line under the entry's heading:
   `plan: [task-NNN-<slug>.md](task-NNN-<slug>.md)`. Leave the brackets in place.

For *the next task* rather than a named one, use the `next-task` skill.

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
ready to be read. Set `in_review`. This protocol uses no pull requests.

**`in_review` → `approved`** — human only: a human reads the branch diff. Accepted →
`approved`. Otherwise → `changes_requested`.

**`changes_requested` → `in_review`** — fix what the review asked for on the task
branch, commit, set `in_review`.

**`approved` → `done`** — merge the branch into `main` (fast-forward), delete the
branch, set `done`.

A task that wrote no code — a decision record, say — reaches `done` without a branch
to merge: set the status and mirror it.

## Cleaning up

Deleting finished tasks is the `clean-tasks` skill, and it happens only when a human
asks for it — never as part of reaching `done`.

## Shell

On Windows, use the PowerShell tool rather than Bash.

* No `&&` or `||` in PowerShell 5.1: use `;`, and `if ($?) { ... }` to run a command
  only when the previous one succeeded.
* `python` may not be on `PATH`.
* Here-strings (`@'...'@`), not heredocs. The closing `'@` must start at column 0.
