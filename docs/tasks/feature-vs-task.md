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

# Implementation Plan

## What this decides

Two kinds of backlog entry, so small work stops paying for a plan, a branch and a
review it does not need. Today every entry runs the same eight-status ladder and
gets a branch whenever `create_branch` permits one.

## What the merge changes

Folding *tasks branch name* in answers that entry's second bullet twice over, and
both answers already exist:

* *How do I tell the AI not to use a branch?* Project-wide, that is
  `create_branch: false` in `Tasks.md` frontmatter, settled by the *plugin config*
  task. Per task, it is the `chore` kind below. Nothing new is needed.
* *When status is planned and there is no plan?* Read as "work with no plan should
  not get a branch", that is exactly `chore`.

What the merge genuinely adds is the first bullet: the branch *name*. And asking
it exposes that `feature` and `chore` are not two points on a scale. They are two
independent booleans the kind happens to pair up.

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

## A kind is a named pair of two booleans

*Does this need a plan?* and *does this need a branch?* are independent, and the
original two-kind proposal only named the diagonal. All four combinations occur,
and this repository has run three of them:

| Needs a plan | Needs a branch | What it is | Name |
| :- | :- | :- | :- |
| yes | yes | ordinary feature work | `feature` |
| yes | no | a decision record; *use agents* and *tasks as plugin vs skill* were both this | open question 5 |
| no | yes | an urgent fix, no time to plan, still isolated | `hotfix` |
| no | no | a version bump, a typo | `chore` |

`bug`, which the merged entry names, is `feature`'s pair of answers with a
different word on the branch - so it is a naming question, not a behaviour one.

## The branch name follows from the kind

The branch prefix is the kind, not a separate field:

```
feature/add-a-login-page
hotfix/token-expiry-off-by-one
bug/duplicate-invoice-rows
```

`task/<slug>` goes away. No existing branch is affected - every branch this
repository ever made is merged and deleted, so the rename costs nothing now and
will cost real work later.

This is why the prefix should not be a fourth bracket field: a kind that needed a
plan, needed a branch, and then separately named that branch `chore/` would be
three facts a human has to keep consistent for no gain. One word in the brackets
decides all three.

## What each kind permits

| | plan | branch | request | review |
| :- | :- | :- | :- | :- |
| `feature` | required, human verifies it | `feature/<slug>`, when `create_branch` permits | when `create_pull_request` permits | human only |
| `bug` | required, human verifies it | `bug/<slug>`, when `create_branch` permits | when `create_pull_request` permits | human only |
| `hotfix` | skipped | `hotfix/<slug>`, when `create_branch` permits | when `create_pull_request` permits | human only |
| `chore` | skipped | none; commits on `main` | never | open question 3 |

Status ladder:

* With a plan: `draft` -> `planning` -> `planned` -> `in_progress` -> `in_review` ->
  (`changes_requested` -> `in_review`) -> `approved` -> `done`.
* Without: `draft` -> `in_progress` -> `in_review` -> `approved` -> `done`.
  `planning` and `planned` are not reachable; asking for them is a question for the
  human, not a status to set.

Configuration keeps the meaning the *plugin config* task gave it: each key is a **ceiling**,
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
   read the third bracket field and to build `branch:` from the kind rather than
   from `task/`, and split the transitions that differ (`draft`, `planned` ->
   `in_progress`, and the `planning` pair).
3. `skills/next-task/SKILL.md`: carry the kind into the file it creates, and name
   the ladder the kind implies.
4. `skills/init/templates/Tasks.md`: document the third bracket field, the kinds
   and the default, next to the statuses it already lists.
5. `README.md` and `docs/tasks/README.md`: one paragraph each, including the branch
   prefixes, since `task/<slug>` is documented in both.
6. Tests green, then `claude plugin validate . --strict`.

## Unit tests

In `tests/Test-Plugin.ps1`, extending the bracket helpers already there:

1. A three-field bracket parses into status, priority and kind; a two-field bracket
   parses and yields the default kind.
2. A third field that is not a known kind makes the parser throw, so the protocol's
   "stop and ask" has something to stand on.
3. Every existing task file still parses with no `kind:` key, so a task written
   before this change keeps working.
4. The protocol names every kind, and states for each whether a plan is required
   and what its branch is called.
5. The template `Tasks.md` documents the third field and the default.
6. Every `Tasks.md` entry whose brackets name a kind matches its task file's
   `kind:`, when the file exists - the mirror, tested in the same shape as the
   status mirror.
7. Every `branch:` in a task file starts with its own `kind:` followed by `/`, and
   no task file uses `task/`. This is the test that keeps the prefix derived rather
   than typed.
8. `git check-ref-format refs/heads/<branch>` still passes for every new prefix -
   the slug rule already guarantees it, and the test states it for the four words
   now in front of the slug.

## Relation to other backlog entries

*tasks branch name* is no longer a separate entry: it was merged into this one, so
its old open question 4 is answered and gone.

`review instructions` is `done`, and its `## How to review` section is written at
`in_progress` -> `in_review`. A `chore` that skips review entirely (open question
3) writes no such section, and the protocol has to say so.

## Open questions for the human

1. **How many kinds?** Four (`feature`, `bug`, `hotfix`, `chore`) answers the
   merged entry in full and matches the branch types git users expect. Two
   (`feature`, `chore`) is the smaller protocol, and a `bug` is then a `feature`
   whose branch says `feature/`. More kinds cost nothing to implement and
   everything to remember.
2. **Names.** `chore` for the no-plan-no-branch kind - or `task`, accepting that
   "the task file" then stops saying which kind it holds. The plugin itself is
   called `task`, which is what makes that word expensive here. The way out is
   closed: *task plugin vs backlog.so* settled on 2026-11-07 that the plugin keeps
   its name, so naming a kind `task` now pays that ambiguity for good.
3. **The plan-but-no-branch kind.** *use agents* and *tasks as plugin vs skill*
   were both exactly this: a plan, a decision, no code. Does it get a name of its
   own - `decision`, `research`, `spike` - or does a `feature` that turns out to
   write no code just not create its branch?
4. **The default kind** for a two-field bracket. `chore` is cheap and matches how
   your short entries read; `feature` is safe and never skips a plan unasked.
   Every entry in the backlog today has two fields, so this decides what they are.
5. **Does a `chore` stop at `in_review`?** Skipping review is what makes it cheap,
   and it is also the only gate. It would also skip `## How to review`.
6. **Drop `task/` entirely?** The prefixes above replace it. Nothing is lost now,
   because no branch survives - but if you ever want one prefix for everything,
   say so before this is implemented rather than after.