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
`Tasks.md` entry, or the name of a task file. With no arguments, state the protocol
and list the tasks with their statuses, and ask which one to take.

## Starting from the task name

1. Find the task. Match `$ARGUMENTS` against the headings in `Tasks.md` and against
   the task file names, case-insensitively; a partial match is enough when it is
   unambiguous. Two candidates → ask which one.
2. No task file yet → create it as **Creating a task** below describes, then
   continue.
3. A task file exists → read its frontmatter, reconcile it with the entry's brackets
   (see **Backlog mirror**), and run the transition its `status` calls for in
   **Transitions**. Stop at the first step that is a human's.

## Task files

* A task is a file `docs/tasks/<slug>.md`, where `<slug>` is the slug of its
  backlog heading, derived as **Creating a task** below describes. The task files
  are every `*.md` in `docs/tasks/` except `README.md` and `Tasks.md`.
* A task file left over from the numbered scheme, such as
  `task-007-clean-tasks.md` with `id: task-007`, keeps its name and its id. Read it
  and work it as it stands; only new tasks are named by slug.
* Every task file starts with this frontmatter:

```yaml
---
id: short-description
status: draft | planning | planned | in_progress | in_review | changes_requested | approved | done
priority: high | medium | low
branch: task/short-description
---
```

* `branch:` is there when the task has a branch. With `create_branch` off (see
  **Configuration**) the task has none, and the key is left out.
* The task file is the source of truth for `status` and `priority`. The brackets in
  `Tasks.md` mirror it; keep them in step (see **Backlog mirror**).

## Selection

1. Scan the task files, as **Task files** above defines them.
2. Keep the tasks whose `status` matches the one you were asked to process.
3. Take `high` before `medium` before `low`; on a tie, the oldest file first.

## Creating a task

When the named task has no task file yet:

1. Derive the slug from the entry's heading: lower-case it, replace every run of
   characters outside `a-z0-9` with a single `-`, then strip any leading and
   trailing `-`. So `task id/name` gives `task-id-name`.
2. Check the slug. It must match `^[a-z0-9][a-z0-9-]*[a-z0-9]$`, be at most 60
   characters long, and belong to no existing task file. A slug that matches that
   pattern is always a legal git branch name, so nothing else has to be checked.
   When the check fails, do not invent a different slug: stop and ask the human to
   edit the heading.
3. Write `docs/tasks/<slug>.md` with `id: <slug>` and `branch: task/<slug>`, and
   take `status` and `priority` from the entry's brackets.
4. Copy the entry's explanation into the body as the task description. Do not write
   an implementation plan yet.
5. Add a link to the task file as the first line under the entry's heading:
   `plan: [<slug>.md](<slug>.md)`. Leave the brackets in place.

For *the next task* rather than a named one, use the `next-task` skill.

## Backlog mirror

The brackets in a `Tasks.md` entry always read `[<status>, <priority>]`, for the
whole life of the task. Keep the mirror in step, in both directions:

* You change a task file's `status` → update that entry's brackets in the same
  commit.
* A human changed the brackets → copy the new `status` and `priority` into the task
  file's frontmatter when you next pick the task up, and work from that.

## Configuration

Two keys decide what the transitions may do. Both are booleans.

| Key | Default | What it permits |
| :- | :- | :- |
| `create_branch` | `true` | A task may have its own branch. |
| `create_pull_request` | `false` | Reaching `in_review` opens a request on the host. |

Precedence for each key, highest first:

1. The YAML frontmatter at the very top of `docs/tasks/Tasks.md`:

   ```markdown
   ---
   create_branch: true
   create_pull_request: false
   ---
   ```

2. The value the human gave Claude Code for this plugin: `create_branch` is
   `${user_config.create_branch}` and `create_pull_request` is
   `${user_config.create_pull_request}`.
3. The defaults in the table above.

An unknown key in that frontmatter is ignored. A value that is neither `true` nor
`false` is not guessed at: stop and ask the human to fix it. A frontmatter block
that is not at the very top of `Tasks.md` is not configuration.

Each key is a **ceiling, not a default**. `create_branch: false` means no task
gets a branch, and nothing per task overrides that. `create_branch: true` only
permits a branch; which work uses one is this protocol's decision. The same
reading applies to `create_pull_request`.

`create_pull_request: true` together with `create_branch: false` is a
contradiction: there is no branch to open a request from. Report it and stop
rather than resolving it either way.

## The host, when requests are on

Read the host from `git remote get-url origin`. A `github.com` remote uses `gh`,
a GitLab remote uses `glab`; GitLab calls the request a merge request.

| Host | Open the request | Check it is merged |
| :- | :- | :- |
| GitHub | `gh pr create --fill --base main --head <branch>` | `gh pr view <branch> --json state,mergedAt` |
| GitLab | `glab mr create --fill --target-branch main --source-branch <branch>` | `glab mr view <branch> --output json` |

The tool missing, or not authenticated: report it and stay where you are. Never
fall back to a local merge to get around it.

## Transitions

**`draft` → `planning`** — human only. Do not set `planning` yourself.

**`planning` → `planned`** — append a `# Implementation Plan` section to the task
file: the steps, and any open question a human must answer. Set `planned` and stop;
a human verifies the plan.

**`planned` → `in_progress`** — set `in_progress` and commit it on `main`. With
`create_branch` on, create the branch named in `branch` and write the code **and
unit tests** on it. With `create_branch` off, leave `branch:` out of the task
file's frontmatter and commit the code and tests on `main`.

**`in_progress` → `in_review`** — the implementation is committed and ready to be
read. With `create_pull_request` off, nothing is pushed and nothing is opened: set
`in_review`, and the human reads the branch, or the commits on `main` when there
is no branch. With `create_pull_request` on, push the branch, open the request as
**The host** above describes, add its URL to the task file as a `pr:` line under
the frontmatter, and set `in_review`.

**`in_review` → `approved`** — human only. A human reads the branch diff, the
commits on `main` when there is no branch, or the open request on the host.
Accepted →
`approved`. Otherwise → `changes_requested`.

**`changes_requested` → `in_review`** — fix what the review asked for where the work
lives, the task branch or `main`, commit, and set `in_review`. An open request
picks the new commits up when the branch is pushed.

**`approved` → `done`** — how the work lands depends on what was permitted:

* No branch: there is nothing to merge. Set `done` and mirror it.
* A branch and no request: merge it into `main` (fast-forward), delete the branch,
  set `done`.
* A request: the host merges it, not you. Check that it is merged as **The host**
  above describes. Merged: delete the local branch and set `done`. Not merged yet:
  say so and stop, because merging it is the human's.

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
