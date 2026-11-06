---
id: review-instructions
status: planned
priority: medium
---

# review instructions

- when implementation is done, add a short instructions on how to demonstrate new feature in ui or how to review the changes.

# Implementation Plan

## What is being built

At `in_progress` -> `in_review`, the task file gains a short, fixed-heading section
telling whoever reviews it how to see the change for themselves. Today the handover
is a commit range and a `## Result` prose section; the reviewer works out how to
exercise the change on their own.

## Where it goes and what it is called

A `## How to review` section, appended to the task file by the
`in_progress` -> `in_review` transition, below `## Result` (open question 1 on the
heading). The task file, not the commit message: a commit message is written once
per commit and cannot be corrected, while this is one statement about the finished
whole.

## Three shapes, because not every change has a UI

The entry names a UI demo first, but most changes do not have a screen, and this
plugin's own tasks have no runtime at all. Forcing a demo on them produces
invented steps, which is worse than none. So the section takes whichever shape
fits, and the protocol names all three:

| The change | What the section holds |
| :- | :- |
| A user interface | How to start the app, how to reach the screen, what to look at, what it did before |
| A command, a library, an API | The exact command or call, and the output to expect |
| No runtime surface - a protocol, a rule, a document | What to read and in what order, plus the command that proves it, usually the test run |

The third row is the one this repository lives in, and it is the row that keeps the
section honest rather than ceremonial.

## The part that makes it worth having

Whatever in the section can be run, **gets run before `in_review` is set**, and its
real output goes in. A review instruction that was never executed is a guess
presented as a fact, and the reviewer finds out only after following it.

What cannot be run - clicking through a UI - is written as steps, and the section
says plainly that they were written, not walked.

## Keeping it short

The entry asks for *short*. The protocol caps it: a handful of steps, no restating
the plan, no restating the `## Result`. If the change needs more than that to
demonstrate, that is a finding about the change, worth saying out loud instead of
documenting around.

## Steps

1. Write the tests first, red.
2. `skills/task/SKILL.md`, `in_progress` -> `in_review`: require the section, name
   its heading, give the three shapes, require the runnable parts to have been run,
   and cap the length. Both halves of the transition - requests on and off - since
   the section is not about the host.
3. `skills/task/SKILL.md`, `in_review` -> `approved`: the human follows that section
   rather than working the change out from the diff.
4. `docs/tasks/README.md`: one line, so a human reviewing knows where to look.
5. Tests green, then `claude plugin validate . --strict`.

## Unit tests

In `tests/Test-Plugin.ps1`:

1. The `in_progress` -> `in_review` transition names the section heading exactly as
   the heading tests will look for it, and names all three shapes.
2. The transition requires the runnable parts to have been run - the protocol must
   not let an unexecuted instruction through.
3. The transition states the cap.
4. The `in_review` -> `approved` transition points the human at the section.
5. Any task file that has a `## How to review` section has something under it: a
   heading with nothing beneath it is the failure mode this rule invites.

Test 5 is the only one that looks at task files rather than at prose, and it is
deliberately weak - it cannot judge whether instructions are *good*, only that
they exist. The strong check is step 2's "it was run".

## What is not done

Existing task files are not backfilled. The seven `done` tasks and the two
`planned` ones describe work whose review is over or has not started; writing
review instructions for them now would be fiction (open question 3).

The section is also **not** documentation in the sense the `documentation` task
settled: it describes how to review one change once, so it is spent when the review
is over and goes with the task file when `clean-tasks` deletes it. Nothing has to
survive (open question 5).

## Open questions for the human

1. Heading: `## How to review`, or `## Demo`, or `## How to try it`? The tests and
   the protocol have to agree on one literal string.
2. With `create_pull_request` on, should the section also become the request's
   description? `gh pr create --fill` takes the body from the commits, so this would
   mean `--body-file` and a change to **The host** table. Against: the request then
   carries a copy that drifts from the task file.
3. Backfill the existing task files, or leave them? Recommendation: leave them.
4. Is "the runnable parts were actually run" a hard requirement for reaching
   `in_review`, or a should? Recommendation: hard, because it is the only part of
   this that cannot be faked by writing plausible prose.
5. Does anything in the section survive `clean-tasks`? Recommendation: no.

## Relation to other backlog entries

`feature vs task` [planned, high] proposes a `chore` kind that may skip review
entirely. If it does, a chore writes no review instructions either, and whichever
task is implemented second has to say so.