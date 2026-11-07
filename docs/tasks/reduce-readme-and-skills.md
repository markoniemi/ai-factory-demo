---
id: reduce-readme-and-skills
status: done
priority: low
kind: task
---

# reduce readme and skills

- has skill files or readme grown during edits? Is it possible to reduce text? Can the text be less verbose?

# Implementation Plan

## Has it grown? Yes, 2.75x

`skills/task/SKILL.md`, measured at every commit that touched it:

| Words | Commit |
| ----: | :- |
| 780 | `b5fa333` packaged the protocol as a plugin |
| 922 | `7ffe77f` slugs from headings |
| 1447 | `762c695` plugin config |
| 1459 | `8f0b8dc` `/task:init` |
| 1505 | `92d288d` the documentation rule |
| 1475 | `cbe0eec` folded that rule into the sentences |
| 1580 | `d802ba6` `## How to review` |
| 1543 | `a7a08c3` dropped the numbered scheme |
| **2148** | `5cb5769` kinds and the status deciding the plan |

Nine commits, two of which took anything out, and both of those removed under 40
words. The last one added 605 - **28% of the whole file in one task**.

Today:

| File | Words |
| :- | ----: |
| `skills/task/SKILL.md` | 2148 |
| `README.md` | 1154 |
| `docs/tasks/README.md` | 848 |
| `skills/init/templates/Tasks.md` | 379 |
| `skills/next-task/SKILL.md` | 346 |
| `skills/init/SKILL.md` | 271 |
| `skills/clean-tasks/SKILL.md` | 269 |
| `skills/init/templates/README.md` | 228 |

## Two different costs, and only one of them is per-turn

This is the distinction the whole task turns on:

* **`skills/task/SKILL.md` is read on every invocation.** Every word is paid
  again each time `/task:task` runs, and the other three skills open by telling
  the agent to read it, so they pay it too. 2148 words is the standing cost of the
  plugin.
* **The two `README.md` files are read by people, rarely.** Their cost is drift:
  four files now tell the configuration story, and nothing keeps them in step
  except `tests/Test-Plugin.ps1`.

So shrinking `SKILL.md` buys tokens, and de-duplicating the READMEs buys
correctness. Doing one does not do the other.

## What not to cut

The prose in this repository explains *why*, not only what: the ceiling reading of
the config keys, why a slug check is also a branch-name check, why `approved` is
the whole signal. Those sentences exist because the rule alone was
misapplied - that is the record of several tasks. **Cut duplication, not
explanation.** A shorter file that gets a rule wrong once has lost the trade.

## Where the words actually are

`skills/task/SKILL.md` by section:

| Words | Section |
| ----: | :- |
| 576 | `## Transitions` |
| 258 | `## Kinds` |
| 220 | `## Creating a task` |
| 218 | `## Configuration` |
| 182 | `## Task files` |
| 140 | frontmatter and preamble |
| 129 | `## Backlog mirror` |
| 113 | `## The host, when requests are on` |
| 104 | `## Starting from the task name` |
| 83 | `## Lazy branches` |
| 57 | `## Shell` |
| 41 | `## Selection` |
| 27 | `## Cleaning up` |

Five concrete reductions, with what each is worth:

1. **Move `## The host` out of the per-turn read (-113).** It only matters when
   `create_pull_request` is on, which is **off by default**. A skill may keep
   supporting files and read them when needed, so this becomes
   `skills/task/references/host.md`, named from the two transitions that use it.
   This is the one structural change here, and the one real risk: an agent that
   fails to open the file would silently skip opening a request. The guard is that
   both transitions name the file in the same sentence that tells them to open a
   request.
2. **`## Selection` looks dead (-41).** Nothing reaches it. `/task:task` works
   from a name, the no-argument case lists every task and asks, and `next-task`
   states its own selection rule. Confirm by reading those three paths, then
   delete it. Open question 2.
3. **`## Kinds` and `## Creating a task` say the prefix is stripped twice (-40).**
   `## Kinds` is the explanation; **Creating a task** should do no more than point
   at it.
4. **`approved` -> `done` now duplicates itself (-35).** Its first bullet says a
   branch that was never made has nothing to merge; its closing paragraph says the
   same for a decision record. One of them is mine, added this morning.
5. **`## Configuration` states the ceiling three times (-45)** - the table, then
   two paragraphs. One statement plus the contradiction case is enough.

That is about 275 words, 13%. Reaching 25% means a pass over `## Transitions`,
which is the only section big enough to matter and also the one where a wrong cut
is most expensive. Target: **1600 words**, no rule lost.

For the READMEs, the duplication is the configuration table, which appears in
`skills/task/SKILL.md`, `README.md`, `docs/tasks/README.md` and
`skills/init/templates/Tasks.md`. Each has a reason to exist, so the reduction is
to make three of them one line and a pointer, not to delete them.

## A budget, so this does not happen again

The reason the file reached 2148 words is that no step ever asked. Add a test that
caps it:

```powershell
Assert-True ($words -le 1800) "skills/task/SKILL.md is $words words, over its budget"
```

Raising the cap then has to happen in the same commit as the words, where a human
sees it in the diff. It does not stop growth; it stops *unnoticed* growth, which is
what happened here.

## Steps

1. Write the budget test, red at 2148 words.
2. Reductions 2 to 5 above, in `skills/task/SKILL.md`. Run the suite after each
   one: these are the edits most likely to trip a test that reads the prose, and
   several of those tests exist.
3. Reduction 1: create `skills/task/references/host.md`, cut `## The host`, and
   name the file in both transitions that need it.
4. A pass over `## Transitions` for duplication only.
5. Set the cap to the number reached, rounded down to the next hundred.
6. `README.md` and `docs/tasks/README.md`: collapse the repeated configuration
   table to a pointer, leaving one authoritative copy in each audience's file.
7. Suite green, `claude plugin validate . --strict`, and re-measure every file in
   the table above so the result is checkable.

## Unit tests

1. The budget: `skills/task/SKILL.md` is at or under its cap.
2. Every status name, every transition heading and every config key still appears
   in the protocol after the cuts - the existing cases already assert most of this,
   and they are the safety net for step 2.
3. The request path's commands - `gh pr create`, `gh pr view`, `glab mr create`,
   `glab mr view` - are found in the skill **or** in a file it names. The existing
   case looks only in `SKILL.md` and must be widened, or moving the section would
   look like deleting it.
4. Both transitions that need the host file name it, so the agent is told where to
   look at the moment it needs to look.
5. No section heading that the other three skills reference by name disappears:
   they point at **Creating a task**, **Configuration** and **Transitions**.

## Open questions for the human

1. **Is the per-turn token cost the point, or readability?** The plan assumes
   tokens for `SKILL.md` and drift for the READMEs. If what prompted this was
   reading the files rather than paying for them, the order of the steps should
   flip.
2. **Delete `## Selection`?** It reads as dead. Deleting prose that turns out to
   be load-bearing is the expensive mistake here, so this is worth a yes.
3. **Move the request path out of the protocol?** It is the biggest single saving
   and the only change that could make the agent do less rather than say less.
   Recommend yes, with both transitions naming the file.
4. **A word budget at all, and at what number?** 1800 is a guess that leaves room;
   1600 would bite immediately.
5. **How hard to push on the READMEs?** Their explanatory prose is deliberate -
   `## Decisions` in the root `README.md` is three paragraphs of reasoning that
   exists because the conclusions alone were not enough. Recommend leaving the
   reasoning and cutting only what another file already says.

Answered on 2026-11-07: the human asked for **reductions 1 to 5**, which settles
open questions 2 and 3 yes. Questions 1, 4 and 5 are untouched, so the word budget
(step 5) and the README pass (step 6) are **not done**.

## Result

`skills/task/SKILL.md`: **2148 -> 1955 words**, commit `f22db14`.

| Was | Now | Reduction |
| ----: | ----: | :- |
| 113 | 0 | 1. the request path moved to `skills/task/references/host.md` |
| 41 | 0 | 2. `## Selection` deleted |
| 258 | 253 | 3. the prefix rule explained once, in `## Kinds` |
| 576 | 558 | 4. `approved` -> `done` lost its self-repeating paragraph |
| 218 | 212 | 5. the ceiling stated once instead of three times |

Both transitions that need the host file name it by path and say to read it now.
`## Creating a task` renumbered 1-5, its first two steps merged.

Tests 59 -> 61. The existing case for the request path searched `SKILL.md` only, so
moving the section would have read as deleting it; it now searches the referenced
file as well. Two cases added: both transitions must name `references/host.md` and
the section must not reappear in the protocol, and every heading referred to by
name from this or another skill must still exist.

**The estimate was wrong, and in the honest direction: 275 words predicted, 193
delivered.** The two call sites each gained an explicit `${CLAUDE_PLUGIN_ROOT}`
path and an instruction to read the file, which bought back about 25 words. That
was the right trade - a pointer the agent might not follow is the whole risk of
reduction 1 - but it should have been in the estimate.

The plan's 1600-word target is not reached and was never in this scope: it needs
the `## Transitions` pass, which is step 4 of **Steps** rather than one of the five
reductions. `## Transitions` is still 558 words, more than a quarter of the file.

## How to review

1. `powershell -File tests/Test-Plugin.ps1` - expect `passed 61, failed 0,
   skipped 0`. `claude plugin validate . --strict` passes.
2. `git show f22db14 -- skills/task/SKILL.md` is a 69-line-deletion diff against
   47 insertions. Read it as five independent cuts; none of them depends on
   another.
3. The one worth real attention is reduction 1. Read the `in_progress` ->
   `in_review` and `approved` -> `done` transitions and ask whether an agent
   reading them would open
   `${CLAUDE_PLUGIN_ROOT}/skills/task/references/host.md`. If the answer is
   "probably", that is not good enough and this is a `changes_requested`: the
   saving is 113 words and the failure mode is silently not opening a pull
   request.
4. Re-measure, rather than trusting the numbers above:
   `$t = [IO.File]::ReadAllText("skills/task/SKILL.md"); ($t -split '\s+' | ? { $_ }).Count`
5. **Not exercised:** no request was opened, because `create_pull_request` is
   `false` here and this repository has no configured host flow. Reduction 1 is
   therefore tested by reading, not by running - the two new cases assert that the
   file exists and is named, not that an agent obeys the pointer.