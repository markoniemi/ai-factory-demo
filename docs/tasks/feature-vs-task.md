---
id: feature-vs-task
status: in_progress
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

Third plan, and much smaller than the first two. The first put the kind in a
third bracket field; the second moved it into the heading on the human's
instruction. This one is the result of two further decisions the human made while
verifying it: **lazy branch creation**, and **the status decides whether a plan is
required**. Together they take almost everything out of the kind.

## Four questions, four owners

The earlier plans kept making the kind answer questions that belong elsewhere.
Each of these now has exactly one owner, and no two of them overlap:

| Question | Owner |
| :- | :- |
| What is the branch called? | the **kind**, from the heading prefix |
| Is a plan required? | the **status**: `planning` means write one |
| May there be a branch at all? | **configuration**: `create_branch` |
| Does the branch exist yet? | **lazy creation**: only once there is something to commit |

Everything below follows from that table.

## The kind names the branch, and nothing else

`### [<kind>: ]<title> [<status>, <priority>]`

```markdown
### feature: add a login page [draft, high]
### bug: duplicate invoice rows [draft, high]
### task: bump the plugin version [draft, low]
### bump the plugin version [draft, low]
```

The last two mean the same thing: **no prefix means `task`**.

* `<kind>` is `feature`, `bug` or `task`, matched case-insensitively, followed by
  a colon. `hotfix` is **not** a kind: it named urgency, and nothing in this
  protocol would treat it differently from `bug`.
* **The prefix is stripped before the slug is derived.** `### feature: add a login
  page` gives the slug `add-a-login-page`, the file
  `docs/tasks/add-a-login-page.md` and the branch `feature/add-a-login-page`.
  Without this rule the branch would read `feature/feature-add-a-login-page`.
* A word before a colon that is **not** one of the three kinds is part of the
  title. `### fix: parser crash` is a `task` titled `fix: parser crash`, slug
  `fix-parser-crash`. A colon in a title is ordinary English; the protocol neither
  guesses at a fourth kind nor stops to ask.
* `$ARGUMENTS` matches against the title with the prefix stripped **and** against
  the whole heading, so both `/task:task add a login page` and
  `/task:task feature: add a login page` find it.

| Kind | Branch |
| :- | :- |
| `feature` | `feature/<slug>` |
| `bug` | `bug/<slug>` |
| `task` | `task/<slug>` |

That is the whole of what the kind does. `task/<slug>`, which every branch is
called today, survives as one kind's name rather than the name for everything.

The task file's frontmatter gains `kind: feature | bug | task`, so the file still
says what it is after its backlog entry is cleaned away. No `kind:` key means
`task`, which is what makes every file written before this change keep working.

## The status decides whether a plan is required

The human's own question - "when status is planned and there is no plan?" - is the
answer:

* **`planning`** - a plan is required. Unchanged: write `# Implementation Plan`,
  set `planned`, stop for a human to verify it.
* **`planned` with no `# Implementation Plan` section** - no plan is required.
  Implement it.
* **`planned` with a plan** - the plan was verified. Implement it. Unchanged.

This works because `planned` means **cleared to implement** under both readings.
"Plan written and verified" and "no plan wanted" converge on the same next action,
so the double meaning costs nothing operationally. A human scanning the brackets
cannot tell the two apart, which is the only thing lost, and the next action is
the same either way.

It is also the more honest model. Whether work needs thinking about first is a
judgement about *that* work, not a property of its category: an obvious `feature`
exists, and so does a `task` that needs a design settled before anyone types.

Both `draft` -> `planning` and `draft` -> `planned` are **human only**. The AI
never sets `planned` except by writing a plan. That keeps the gate exactly where
it is today - the human says what happens next - and only adds a second thing they
may say.

One ladder, for every kind:

```
draft -> planning -> planned -> in_progress -> in_review -> approved -> done
      \_______________/^                        ^_____ changes_requested _____|
         plan skipped
```

**A human who rejects a plan sets `planning` again, or `draft` - never `planned`
with the plan section deleted.** That motion would read as "no plan wanted" and
the AI would start implementing. Worth one sentence in the protocol, because it is
the one way this scheme misfires.

## Lazy branch creation

Today `planned` -> `in_progress` creates the branch on entry. A task that turns
out to write no code - a decision record, and this repository has produced three -
gets an empty branch which is then deleted at `done`.

So: **create the branch when there is something to commit, not on entering
`in_progress`.** One sentence, and it removes the need for any kind meaning "needs
a plan but no branch".

`branch:` is written into the frontmatter when the task file is created, whenever
`create_branch` permits a branch. The key **names** the branch; it does not assert
that the branch exists yet. The protocol's current bullet says the opposite and has
to be rewritten. Rejected alternative: leave `branch:` out and derive
`<kind>/<id>` whenever it is needed. It is fully derivable, but humans read that
file, and a name written down is worth the redundancy.

## Naming a kind `task` costs something, deliberately

*task plugin vs backlog.so* settled on 2026-11-07 that the plugin keeps its name.
So `task` names three things: the plugin, the file in `docs/tasks/`, and this kind.
The human chose it knowing that.

The protocol pays for it in its own prose, by a rule it follows from here:

* **task file** stays the generic container, for every kind. It is a file; the
  phrase names a file.
* The kind is always written in backticks - a `task`, `kind: task` - never as the
  bare English word.

`README.md` currently says the collision would be "paid in the kind names
instead". That sentence becomes wrong when this is implemented, and correcting it
is part of the implementation, as `planned` -> `in_progress` requires.

## What this does to the backlog today

Nothing, which is the point. Both remaining drafts - *powerpoint presentation* and
*github build* - are `draft`, so neither moves until a human picks `planning` or
`planned` for it. There is no default-kind trap, because the kind no longer
decides anything about planning. The two task files in flight keep their slugs;
the prefix governs how a *new* entry is read.

## Steps

1. Write the tests first, red.
2. `skills/task/SKILL.md`:
   * **Creating a task** - parse the optional prefix, strip it before step 1's
     slug derivation, build `branch:` from the kind, write `kind:` into the
     frontmatter.
   * **Starting from the task name** - match with the prefix stripped as well as
     whole.
   * The frontmatter block - add `kind:`, say that its absence means `task`, and
     rewrite the `branch:` bullet so the key names the branch without asserting it
     exists.
   * A `## Kinds` section: the heading grammar and the branch table. Short, because
     that is all the kind does.
   * **Transitions** - `draft` gains the `planned` route, human only; `planned` ->
     `in_progress` reads the presence of a plan section and creates the branch
     lazily; and the sentence about how to reject a plan.
   * Adopt the writing rule above: the kind always in backticks.
3. `skills/next-task/SKILL.md`: read the prefix, carry the kind into the file it
   creates.
4. `skills/init/templates/Tasks.md`: document the heading grammar, the three kinds,
   the default, and that `planned` with no plan means "implement it".
5. `README.md`: the backlog-entry example gains a prefix; the statuses paragraph
   gains the plan-skipping route; the `## Decisions` sentence about paying the
   collision "in the kind names" is corrected.
6. `docs/tasks/README.md`: one paragraph for humans - how to ask for a plan and how
   to skip one.
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
4. `hotfix: something` is therefore a `task` titled `hotfix: something`, not a
   fourth kind - the test that keeps `hotfix` out.
5. Every existing task file still parses with no `kind:` key, and reads as `task`.
6. The protocol names all three kinds and what each one's branch is called.
7. Every `branch:` in a task file equals `<kind>/<id>`. This keeps the name
   derived rather than typed, and catches a hand-edited prefix.
8. `git check-ref-format refs/heads/<kind>/<slug>` passes for all three kinds -
   the slug rule already guarantees it; the test states it for the three words now
   in front of the slug.
9. The protocol states both `draft` routes and marks both human only.
10. The protocol says `planned` without a plan section means implement it, and
    says how to reject a plan.
11. The brackets are still parsed as exactly two fields, so the third-field idea
    cannot creep back in through a hand edit.
12. **No test asserts that a `planned` task has a plan section.** That invariant
    is deliberately gone; this is a note to whoever writes the tests, not a test.

## Answered by the human, 2026-11-07

1. **The entry link is renamed `file:`.** `plan: [<slug>.md](<slug>.md)` becomes
   `file: [<slug>.md](<slug>.md)`, because the link points at the task file and an
   entry may never have a plan. Every skill that writes, reads or deletes that
   line changes with it, and the two entries in this backlog are migrated.
2. **`planned` means implement.** A human who writes `planned` on a `feature:`
   entry with ten bullets of description gets code and no plan. The AI does not
   second-guess the waiver; doing so would reintroduce the kind-decides-planning
   rule this plan deleted.
3. **Human review is always needed.** No kind skips `in_review`, and every kind
   writes `## How to review` on the way there. It is the gate that reads the code.

No open questions remain.
