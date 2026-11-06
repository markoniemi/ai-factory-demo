---
id: documentation
status: done
priority: low
---

# documentation

- when /task:clean-tasks is run, documentation should be checked that it is up-to-date.
- should task-plugin have documentation of it own? is readme enough?
- clean-tasks should check that readmes, agents.md, use cases and possible other documentation is up-to-date.

# Implementation Plan

## Two separate questions

The entry holds one change and one decision, and they pull in opposite directions:

* **The change**: `clean-tasks` should check that documentation is up to date, not
  only that the deleted task's own rules survived.
* **The decision**: whether this plugin should grow documentation of its own
  beyond `README.md`.

The more documentation exists, the more there is to drift, and the drift is what
`clean-tasks` would then have to police. So the decision is answered first.

## Does the plugin need its own documentation? No.

Recommendation, for the human to accept or reject (open question 1).

`skills/task/SKILL.md` already says it is the single source of truth and that a
project's `README.md` explains the rules without restating them. A separate
documentation tree would be a second place to say the same things, and nothing
would keep the two in step. The current split is already the right one:

| File | Reader | Holds |
| :- | :- | :- |
| `README.md` | a human installing the plugin | install, the four commands, the two config keys |
| `skills/*/SKILL.md` | the agent | the rules themselves |
| `skills/init/templates/*` | a project the plugin is dropped into | the starting backlog and its README |
| `docs/tasks/*.md` | whoever asks why | this project's own task records |

So: no `docs/` tree for the plugin, no manual, no changelog beyond git. What the
plan adds instead is a **test** that `README.md` and the skills cannot drift apart
silently - a guard is worth more than a page asking people to remember.

## What "up to date" can mean for a check

"Check all documentation is up to date" cannot be verified by an agent in general;
it is a reading task with no fixed end. What can be pinned down is narrower, and
that is what `clean-tasks` gets - two checks instead of today's one:

1. **Survival** (already in the skill): every rule, decision or constraint the
   deleted task established is written down somewhere that outlives the task file.
2. **Accuracy** (new): the documentation that describes *what the deleted task
   changed* still describes it correctly. Scoped to what changed, not to the whole
   doc set - otherwise every clean re-reads every file (open question 2).

Which files count as documentation in a using project is discovered, not assumed:
every `README.md`, `AGENTS.md` and `CLAUDE.md` in the repository, plus anything
under a `docs/` directory that is not a task file. The skill names the rule, so a
project that keeps use cases under `docs/` is covered without the skill listing
file names it cannot know (open question 3).

Drift that is found is **not** fixed in the deletion commit. `clean-tasks` makes
one commit per task on purpose; a documentation fix is separate work and gets its
own commit before the deletions, or is reported and left to the human
(open question 4).

## Steps

1. Write the tests first, red.
2. `skills/clean-tasks/SKILL.md`: split step 1 into **survival** and **accuracy**,
   state the discovery rule for what counts as documentation, state that the
   accuracy check is scoped to what the deleted task changed, and say where a fix
   goes. Extend the closing report line to name both checks.
3. `README.md`: a short **Documentation** section - what this file holds, what the
   skills hold, and that the skills are the source of truth. Three sentences, so a
   contributor knows which file to change and does not add a third place.
4. `docs/tasks/README.md` and `skills/init/templates/README.md`: one line each
   pointing at the same split. No restating of rules.
5. Tests green, then `claude plugin validate . --strict`.

## Unit tests

In `tests/Test-Plugin.ps1`:

1. `README.md`'s command table names every skill in `skills/`, and names no skill
   that does not exist - the drift guard that replaces a documentation page.
2. `README.md` names both configuration keys, and no key that is not in
   `plugin.json`'s `userConfig`.
3. `skills/clean-tasks/SKILL.md` names both checks, and still carries the
   "never on your own, never as part of reaching `done`" guard.
4. No file outside `skills/` restates a status list or a transition - the test
   looks for more than one file holding all eight status names, which is how a
   second source of truth would announce itself. `skills/init/templates/Tasks.md`
   is exempt: a project's backlog lists its statuses for the human on purpose.
5. Every relative link in every `*.md` resolves to a file that exists. Cheap, and
   it catches exactly the breakage `clean-tasks` causes when it deletes a task file
   something still points at.

Test 5 is worth having regardless of the rest of this task.

## Open questions for the human

1. No documentation of its own - `README.md` plus the skills, with tests guarding
   the overlap. Accept?
2. Scope of the accuracy check: only the documentation touching what the deleted
   tasks changed, or the whole documentation set on every clean? The second is
   thorough and gets expensive fast.
3. Discovery rule for what counts as documentation: the `README.md` / `AGENTS.md` /
   `CLAUDE.md` / `docs/**` rule above, or a key in `Tasks.md` frontmatter where a
   project lists its own documentation files? The frontmatter today holds only
   booleans, so a list would widen **Configuration** in the protocol.
4. When `clean-tasks` finds stale documentation: fix it in its own commit before
   the deletions, or report it and stop so the human decides? Fixing it quietly
   means a clean-up commit can change what the project claims to do.

## Relation to other backlog entries

* `review instructions` [planning, medium] adds demonstration instructions at
  `in_review`. Those are documentation too, and whichever task lands second should
  decide whether they are part of the set checked here.
* `feature vs task` [planned, high] adds a `kind:` field, which the protocol, the
  README and the template `Tasks.md` all have to describe. Test 1 and test 4 above
  would catch it if one of the three were forgotten.
## Decision from the human (2026-11-06)

The plan's main change is **rejected**, and the rejection is the useful part of
this task.

> if task was planned an implemented correctly, then documentation was updated as
> well. Cleaning tasks should not be responsible for updating docs.

So documentation belongs to the task that changed the behaviour, written while the
change is being written. `clean-tasks` gets no new check, and the four open
questions above fall away with it: questions 2, 3 and 4 only existed to scope an
audit that is not happening. Question 1 is answered by the recommendation it
contained - the plugin keeps no documentation of its own.

That rule was not written down anywhere. `planned` -> `in_progress` said the
implementation is the code **and unit tests**, and said nothing about the
documentation, so "it was already updated" was a habit rather than a rule, and
`clean-tasks` looked like the only place the gap could be caught.

## Result

Two sentences of prose and one test.

* `skills/task/SKILL.md`, `planned` -> `in_progress`: the transition already said
  the implementation is the code **and unit tests**, so the documentation the
  change makes wrong joins that list, in both the branch and the no-branch
  sentence, plus one short sentence that no later step audits it. It was a
  four-line paragraph first; the human asked whether a clause in the existing
  sentences would do, and it does. This file is read every turn, so prose that
  earns nothing is a cost.
* `skills/clean-tasks/SKILL.md`, step 1: keeping the documentation correct is not
  that skill's job. Its check stays what it was - that a rule is not lost together
  with the file holding it - and the sentence stops the question being reopened.
* `tests/Test-Plugin.ps1`: one case asserting both, so the rule cannot be edited
  back out silently. **39 passed, 0 failed, 0 skipped**;
  `claude plugin validate . --strict` passes.

Not done, deliberately: the plan's five test cases. Four of them existed to guard
an audit that was rejected. The fifth - every relative link in every `*.md`
resolves to a file that exists - is worth having on its own, and it has nothing to
do with documentation drift; it belongs in its own backlog entry, since
`clean-tasks` deleting a file something still points at is the breakage it catches.

The ladder was cut short at the human's word ("Set the task to done?"):
`in_review` and `approved` were skipped, so these three commits were never read by
anyone before reaching `done`.