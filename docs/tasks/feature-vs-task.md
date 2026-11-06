---
id: feature-vs-task
status: planned
priority: high
---

# feature vs task

- how to create features and tasks from tasks.md? feature requires branch, possibly pr. task does not need plan and can be done directly on main.

# Implementation Plan

## What this decides

Two kinds of backlog entry, so small work stops paying for a plan, a branch and a
review it does not need. Today every entry runs the same eight-status ladder and
gets a branch whenever `create_branch` permits one.

## The vocabulary collision

The plugin is called `task`, its files are task files, and `/task:task` starts one.
If "task" also names the *small* kind, every existing rule becomes ambiguous:
"the task file" would no longer tell you which kind it holds.

Proposal: **task file** stays the generic container, and the two kinds are
`feature` and `chore`. The human's wording in the entry ("feature ... task") is
kept in meaning, not in spelling. Open question 1.

## Where the kind is written

The brackets gain an optional third field:

```markdown
### add a login page [draft, high, feature]
### bump the plugin version [draft, low, chore]
### fix a typo in the readme [draft, low]
```

The task file's frontmatter gains `kind: feature | chore`, mirrored like `status`
and `priority`.

Reasons: the brackets are already the human's input surface and already mirror the
task file, so no new syntax and no new mirror direction. Rejected alternative: a
heading prefix (`feature: add a login page`), because the heading is the slug, and
every file and branch name would carry the kind.

An entry with two fields gets the default kind (open question 2). A third field
that is neither kind is not guessed at: stop and ask, as with a bad config value.

## What each kind permits

| | `feature` | `chore` |
| :- | :- | :- |
| Plan | required; `planning` -> `planned`, a human verifies it | skipped |
| Branch | wanted, when `create_branch` permits | none; commits on `main` |
| Request | when `create_pull_request` permits | never |
| Review | `in_review` -> `approved`, human only | open question 3 |

Status ladder:

* `feature`: `draft` -> `planning` -> `planned` -> `in_progress` -> `in_review` ->
  (`changes_requested` -> `in_review`) -> `approved` -> `done`.
* `chore`: `draft` -> `in_progress` -> `in_review` -> `approved` -> `done`.
  `planning` and `planned` are not reachable; asking for them on a chore is a
  question for the human, not a status to set.

Configuration keeps its meaning from `plugin-config.md`: each key is a **ceiling**,
and the two layers AND together. `create_branch: false` means a `feature` gets no
branch either - the human settled that when `plugin-config` was planned. The kind
only ever asks for less than the ceiling, never more.

`create_pull_request: true` with a `chore` is not the contradiction the protocol
already reports; it simply never opens a request, because there is no branch to
open one from.

## Steps

1. Write the tests first, red.
2. `skills/task/SKILL.md`: add `kind:` to the frontmatter block and a `## Kinds`
   section holding the table and the two ladders. Change **Creating a task** to
   read the third bracket field, and split the three transitions that differ
   (`draft`, `planned` -> `in_progress`, and the `planning` pair).
3. `skills/next-task/SKILL.md`: carry the kind into the file it creates, and name
   the ladder the kind implies.
4. `skills/init/templates/Tasks.md`: document the third bracket field, the two
   kinds and the default, next to the statuses it already lists.
5. `README.md` and `docs/tasks/README.md`: one paragraph each.
6. Tests green, then `claude plugin validate . --strict`.

## Unit tests

In `tests/Test-Plugin.ps1`, extending the bracket helpers already there:

1. A three-field bracket parses into status, priority and kind; a two-field bracket
   parses and yields the default kind.
2. A third field that is not a known kind makes the parser throw, so the protocol's
   "stop and ask" has something to stand on.
3. Every existing task file still parses with no `kind:` key - the numbered files
   and the slug-named ones alike are grandfathered.
4. The protocol names both kinds, and states for each whether a plan is required.
5. The template `Tasks.md` documents the third field and the default.
6. Every `Tasks.md` entry whose brackets name a kind matches its task file's
   `kind:`, when the file exists - the mirror, tested in the same shape as the
   status mirror.

## Relation to other backlog entries

* `tasks branch name` [draft, medium] overlaps this directly: it asks how the
  backlog says which *git* branch type is wanted, and a `feature` kind answers
  most of it (`feature/<slug>` instead of `task/<slug>`). Open question 4.
* `review instructions` [planning, medium] adds a step to `in_review`, which is
  exactly the step open question 3 is about. Whichever lands second has to read
  the first.

## Open questions for the human

1. Names. `feature` and `chore`, or `feature` and `task` with the collision
   accepted, or something else?
2. The default kind for a two-field bracket. `chore` is the cheap default and
   makes existing short entries behave as the human already expects; `feature` is
   the safe default and never skips a plan without being told to.
3. Does a `chore` stop at `in_review` for a human, or reach `done` as soon as it is
   committed and its tests pass? Skipping review is what makes a chore cheap; it
   also removes the only gate.
4. Fold `tasks branch name` into this task, or leave it as its own entry and let it
   decide branch prefixes once the kinds exist?