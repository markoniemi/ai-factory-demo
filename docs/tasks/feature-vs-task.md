---
id: feature-vs-task
status: planned
priority: high
---

# feature vs task

- how to create features and tasks from tasks.md? feature requires branch, possibly pr. task does not need plan and can be done directly on main.

Merged in from the *tasks branch name* entry, on the human's instruction
(2026-11-07), because it is the same decision seen from the branch side:

- git supports branches bug/feature/hotfix. how should tasks.md state what kind of branch is needed?
- also, branch is not always needed, how to tell ai not to use branch? when status is planned and there is no plan?

Added by the human on 2026-11-07, after the first plan:

- add task type to heading, ### feature: feature-name, or ### bug: bug-name, or ### task: task-name. Default to task. Branch name is taken from task type.

# Implementation Plan

Second plan. The first one put the kind in a third bracket field and rejected a
heading prefix; the human asked for the heading prefix, and that turns out to make
the whole design smaller. What follows replaces the first plan rather than
amending it.

## What this decides

Kinds of backlog entry, so small work stops paying for a plan it does not need,
and so a branch is named after what it is. Today every entry runs the same
eight-status ladder and every branch is called `task/<slug>`.

## The human's scheme, and why it is better than the first plan

The kind goes in the heading, before a colon:

```markdown
### feature: add a login page [draft, high]
### bug: duplicate invoice rows [draft, high]
### task: bump the plugin version [draft, low]
### bump the plugin version [draft, low]
```

The last two mean the same thing: **no prefix means `task`**.

The first plan rejected this, on the grounds that the heading is the slug, so
every file and branch name would carry the kind twice. That objection is real and
it is also cheap to fix - strip the prefix before deriving the slug - and the
prefix wins on three counts the first plan missed:

* The brackets stay `[<status>, <priority>]` for the whole life of a task, exactly
  as they read today. No third field, no new parse, no second thing to default.
* The kind is a property of *what the work is*, which is what the heading says.
  The brackets hold what changes over time. Putting a permanent fact in the
  mutable field was the wrong home.
* A human typing a new entry writes the kind as part of the sentence, not as a
  field they have to remember the position of.

## A kind is two facts, not four

The first plan built a table of four combinations from *needs a plan* and *needs a
branch*. The human's scheme collapses it, and the collapse is the real content of
this plan:

**Whether there is a branch at all is configuration, not kind.** `create_branch`
is already a ceiling that no task overrides. The kind never decides *whether*;
it only decides **whether a plan is required** and **what the branch is called**.

| Kind | Plan | Branch name |
| :- | :- | :- |
| `feature` | required | `feature/<slug>` |
| `bug` | required | `bug/<slug>` |
| `task` | skipped | `task/<slug>` |

Three kinds, two of which differ only in the word on the branch. `task/<slug>`
therefore survives: it stops being the name for everything and becomes the name
for one kind.

`hotfix` is dropped. It named urgency, and urgency is not something this protocol
represents anywhere - there is no rule a `hotfix` would make the AI follow that
`bug` does not. `chore`, proposed in the first plan, is simply what `task` is now
called, which is what the human asked for.

## Naming a kind `task` costs something, deliberately

*task plugin vs backlog.so* settled on 2026-11-07 that the plugin keeps its name.
So `task` now means three things: the plugin, the file in `docs/tasks/`, and this
kind. The human chose it knowing that.

The protocol pays for it in its own prose, by a rule it has to follow from here:

* **task file** stays the generic container, for every kind. It is a file; the
  phrase names a file.
* The kind is always written in backticks - a `task`, `kind: task` - never as the
  bare English word.

`README.md` currently says the collision would be "paid in the kind names
instead". That sentence becomes wrong when this is implemented, and fixing it is
part of the implementation, as `planned` -> `in_progress` requires.

## The heading grammar

`### [<kind>: ]<title> [<status>, <priority>]`

* `<kind>` is `feature`, `bug` or `task`, matched case-insensitively, followed by
  a colon. Absent → `task`.
* **The prefix is stripped before the slug is derived.** `### feature: add a login
  page` gives the slug `add-a-login-page`, the file `docs/tasks/add-a-login-page.md`
  and the branch `feature/add-a-login-page`. Without this rule the branch would
  read `feature/feature-add-a-login-page`.
* A word before a colon that is **not** one of the three kinds is part of the
  title. `### fix: parser crash` is a `task` titled `fix: parser crash`, slug
  `fix-parser-crash`. The protocol does not guess at a fourth kind, and it does
  not stop and ask either - a colon in a title is ordinary English.
* `$ARGUMENTS` matches against the title with the prefix stripped **and** against
  the whole heading, so both `/task:task add a login page` and
  `/task:task feature: add a login page` find it.

The task file's frontmatter gains `kind: feature | bug | task`, so the file still
says what it is after its backlog entry is cleaned away. A task file with no
`kind:` key is a `task`, which is what makes every file written before this change
keep working.

## What each kind permits

| | plan | branch | request | review |
| :- | :- | :- | :- | :- |
| `feature` | required, human verifies it | `feature/<slug>`, when `create_branch` permits | when `create_pull_request` permits | human only |
| `bug` | required, human verifies it | `bug/<slug>`, when `create_branch` permits | when `create_pull_request` permits | human only |
| `task` | skipped | `task/<slug>`, when `create_branch` permits | when `create_pull_request` permits | human only |

Status ladder:

* `feature` and `bug`: `draft` -> `planning` -> `planned` -> `in_progress` ->
  `in_review` -> (`changes_requested` -> `in_review`) -> `approved` -> `done`.
* `task`: `draft` -> `in_progress` -> `in_review` -> `approved` -> `done`.
  `planning` and `planned` are not reachable. The human's go-ahead moves it
  straight from `draft` to `in_progress`, so it still has exactly two human
  gates - start it, and approve it - just not a plan to verify in between.

Review is human-only for every kind, and every kind writes `## How to review` on
the way to `in_review`. Skipping that would skip the only gate that reads the
code.

## What this does to the backlog today

Two entries have no prefix, so both become `task`: *powerpoint presentation* and
*github build*. That means the next person to pick either up implements it with no
plan. If *powerpoint presentation* should get one, its heading needs
`feature: ` in front - and that is the default working exactly as intended, not a
migration problem.

The two task files in flight keep their slugs. The prefix governs how a *new*
entry is read, not a rename of what exists.

## Steps

1. Write the tests first, red.
2. `skills/task/SKILL.md`:
   * **Creating a task** - parse the optional prefix, strip it before step 1's
     slug derivation, build `branch:` from the kind, write `kind:` into the
     frontmatter.
   * **Starting from the task name** - match with the prefix stripped as well as
     whole.
   * The frontmatter block - add `kind:`, and say that its absence means `task`.
   * A `## Kinds` section holding the two tables and the two ladders.
   * Split the transitions that differ: `draft` (a `task` goes to `in_progress`,
     a `feature` or `bug` waits for `planning`), and the `planning` pair, which a
     `task` never reaches.
   * Adopt the writing rule above: the kind always in backticks.
3. `skills/next-task/SKILL.md`: read the prefix, carry the kind into the file it
   creates, and follow the ladder the kind implies.
4. `skills/init/templates/Tasks.md`: document the heading grammar, the three kinds
   and the default, next to the statuses it already lists.
5. `README.md`: the backlog-entry example gains a prefix; the statuses paragraph
   gains the short ladder; and the `## Decisions` sentence about paying the
   collision "in the kind names" is corrected.
6. `docs/tasks/README.md`: one paragraph on kinds for humans.
7. Tests green, then `claude plugin validate . --strict`.

## Unit tests

In `tests/Test-Plugin.ps1`:

1. A prefixed heading parses into kind and title; an unprefixed one yields kind
   `task` and the whole heading as the title.
2. The slug comes from the title with the prefix stripped - `feature: add a login
   page` gives `add-a-login-page`, and **not** `feature-add-a-login-page`. This is
   the test that stops the kind appearing twice in a branch name.
3. A colon after a word that is not a kind leaves the title intact:
   `fix: parser crash` is a `task` with slug `fix-parser-crash`.
4. Every existing task file still parses with no `kind:` key, and reads as `task`.
5. The protocol names all three kinds and states, for each, whether a plan is
   required and what its branch is called.
6. Every `branch:` in a task file starts with its own `kind:` followed by `/`.
   This keeps the prefix derived rather than typed.
7. `git check-ref-format refs/heads/<kind>/<slug>` passes for all three kinds -
   the slug rule already guarantees it; the test states it for the three words now
   in front of the slug.
8. The template `Tasks.md` documents the prefix, the three kinds and the default.
9. Every `Tasks.md` entry whose heading carries a prefix matches its task file's
   `kind:`, when the file exists - the mirror, in the same shape as the status
   mirror.
10. The brackets are still parsed as exactly two fields, so the third-field idea
    cannot creep back in through a hand edit.

## Open questions for the human

1. **Does a `task` get `task/<slug>` when `create_branch` is on?** The table above
   says yes, because your bullet says the branch name comes from the task type for
   all three, and `create_branch: false` is how branches are turned off. The
   alternative - a `task` is always committed on `main`, whatever the config says -
   makes the kind decide *whether*, which is the thing the collapse above got rid
   of. Recommend yes.
2. **The decision record has no kind.** *use agents* and *task plugin vs
   backlog.so* both needed a plan and wrote no code. Under this scheme that is a
   `feature` whose branch never gets created, which is fine and needs no rule.
   Confirm, or name a fourth kind.
3. **`hotfix` really dropped?** You named it in the merged bullet. Nothing in the
   protocol would treat it differently from `bug`.
4. **How a `task` leaves `draft`.** The ladder above has you say go, and it moves
   to `in_progress` with no plan. That is the same single gate `draft` ->
   `planning` is today. Confirm.
5. **Prefix the two existing drafts?** *powerpoint presentation* and *github build*
   are `task` by default and so will be built without a plan. Say if either should
   read `feature: `.
