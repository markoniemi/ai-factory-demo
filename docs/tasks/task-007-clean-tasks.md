---
id: task-007
status: in_review
priority: high
branch: task/007-clean-tasks
---

# clean tasks

- this should be part of tasks workflow
- implemented plans are no longer needed
- corresponding headings/chapters in tasks.md can be removed
- update documentation and usecases before deleting

# Implementation Plan

## What cleaning means

A finished task leaves three things behind: the task file with its plan, the
`Tasks.md` entry, and whatever the task taught us. Only the third is worth keeping,
and it belongs in `AGENTS.md` or `README.md`, not in a plan nobody reads again.

So cleaning a `done` task is: fold anything still true into the documentation, then
delete the task file and its `Tasks.md` entry. Git history keeps the plan, so
deleting is not losing it — `git log --diff-filter=D -- docs/tasks/` finds it again.

## The rule to add

A new step at the end of the pipeline, after `done`:

> **Cleaning up a `done` task** — before deleting anything, check that every rule,
> decision or constraint the task established is written in `AGENTS.md` or
> `README.md`. Then delete the task file and remove the entry from `Tasks.md`.
> Nothing about a `done` task survives in `docs/tasks/` except what it changed.

Cleaning runs on request (`clean tasks`), not automatically at `done`: a plan is
sometimes still useful for a few days after merging, and deleting it in the same
commit that finishes the task makes that commit hard to read.

## Decisions I am proposing

- **Delete, do not archive.** No `docs/tasks/archive/`. An archive is a second place
  to look that nobody maintains, and git already is the archive.
- **No changelog file.** `git log --oneline -- docs/tasks/` already lists every task
  by its commit subjects.
- **Clean every `done` task at once** when asked, oldest first, in one commit per
  task so each deletion is reviewable on its own.

## Decisions (verified by human, 2026-11-04)

- **Trigger:** on request only, not part of `approved` → `done`.
- **task-001:** delete it with the rest, even though the blog post it describes was
  never written in this repository.
- **Entry removal:** remove the whole `Tasks.md` entry. It is in git history.

## Steps

1. Create branch `task/007-clean-tasks` from `main`.
2. Add a **Cleaning up** section to `AGENTS.md`, after the transitions: the rule
   above, plus the order — documentation check first, then delete the task file,
   then remove the `Tasks.md` entry, one commit per task.
3. Mention it in one line in `README.md`, next to the pipeline: a `done` task is
   cleaned away on request, and what it changed lives in `AGENTS.md`.
4. Note in `Tasks.md`'s intro that entries are removed once their task is cleaned,
   so the backlog only ever shows open work.
5. Then run the rule once, as its own commits: for each `done` task (001 through
   006, oldest first), check its content is reflected in the documentation, delete
   the task file, and remove its entry.
6. Verify: `docs/tasks/` holds only `README.md`, `AGENTS.md`, `Tasks.md` and the
   task files of open tasks; no `plan:` line in `Tasks.md` points at a missing file;
   `git log --diff-filter=D -- docs/tasks/` lists the deleted plans.
7. Unit tests: not applicable (documentation only).
