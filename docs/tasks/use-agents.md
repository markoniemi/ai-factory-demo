---
id: use-agents
status: done
priority: high
---

# use agents

- implementing tasks from tasks.md in same session is not perfect for token spending.
- is it possible to use agents or somehow clear session for each task automatically?

# Implementation Plan

## The second question first: no, a session cannot clear itself

Nothing in Claude Code lets a skill, a hook or a plugin clear the session it is
running in. `/clear` is the human's. The two things that do give a task a fresh
context are:

* a **subagent**, which has its own context window and returns only its final
  report to the thread that dispatched it;
* `claude -p` per task from a script outside Claude Code, which is a fresh process
  and so a fresh everything - and which cannot ask the human anything, so every
  human-only transition in this protocol would break.

So the answer to the entry is subagents, and the rest of this plan is about them.

## What the plugin can ship

Verified against the plugin docs (Claude Code 2.1.x):

* A plugin ships subagents as `.md` files under `agents/`. One file, one agent,
  named `<plugin>:<name>`, so this plugin would give `task:task-runner`, which a
  human can also call directly as `@agent-task:task-runner`.
* The frontmatter fields a plugin agent may set are `name`, `description`, `model`,
  `effort`, `maxTurns`, `autoCompactWindow`, `tools`, `disallowedTools`, `skills`,
  `memory`, `background`, `omitClaudeMd`, `isolation`, `color` and
  `experimental.cacheTtl`. `permissionMode`, `hooks` and `mcpServers` are ignored
  in a plugin agent.
* `skills:` is the field that matters here: the agent can be granted this plugin's
  `task` skill, so **the agent reads the protocol in its own context**, not in the
  main thread's.
* `agents/` is the default scan location, so `plugin.json` needs no `agents` key.
* The only accepted `isolation` value is `"worktree"`.

## The finding that decides the shape of this task

Shipping an agent does not on its own save the main thread anything.

`/task:task <name>` injects the whole of `skills/task/SKILL.md` into the main
thread *before* any delegation can happen. By the time the main thread could
dispatch an agent, it has already paid for the protocol. The agent would then read
it a second time, in its own window, and the total spend would go **up**.

The saving is only real if the protocol stops being in the thing the human invokes.
That means splitting `skills/task/SKILL.md` in two:

* a thin `skills/task/SKILL.md` - how to find the task, and the instruction to hand
  it to `task:task-runner`, naming which transitions the agent may run;
* the protocol body, moved to a file the agent loads: either its own skill, or a
  plain Markdown file the agent reads at `${CLAUDE_PLUGIN_ROOT}`.

That split has a cost, and it is the first open question: the `task` skill's
description currently offers the protocol itself - "or when you need the task
protocol itself" - and a human who runs `/task:task` with no arguments gets the
rules stated. A thin dispatcher cannot do that without loading what it was built
to avoid loading.

## What the agent may and may not do

The agent gets the mechanical stretch and none of the gates, because a subagent
cannot ask the human anything: it returns one report when it is finished.

| Transition | Who |
| :- | :- |
| `draft` -> `planning` | human, as now |
| `planning` -> `planned` | agent, perhaps - open question 5 |
| `planned` -> `in_progress` | agent |
| `in_progress` -> `in_review` | agent |
| `in_review` -> `approved` | human, as now |
| `changes_requested` -> `in_review` | agent |
| `approved` -> `done` | main thread; it is three lines and a merge |

The agent writes the task file, the code, the tests, the `## How to review`
section, and commits, exactly as the protocol says. Where the protocol says "stop
and ask the human", the agent stops and **reports** instead, and the main thread
asks.

## Two hard rules

**Serial, never parallel.** Two agents committing in one repository race, and with
`create_branch: false` they race on `main`. One task at a time.

**No `isolation: worktree` while `create_branch` is off.** A worktree cannot check
out `main` while the primary tree has it, and with branches off every commit
belongs on `main`. With `create_branch` on, a worktree per task is sound and keeps
the working tree clean - which makes this the third place where **Configuration**
decides what is permitted (open question 3).

## What this does and does not save

Stated honestly, because the entry is about token spending:

* It does **not** reduce total tokens. The agent reads the protocol and the task
  file in its own window; across main thread plus agent, the work costs more.
* It **does** stop the main thread growing. Today each task leaves its plan, its
  file reads, its test output and its diffs in the one context, so task five costs
  more than task one and eventually compacts. With an agent the main thread keeps
  only a report per task, so the per-task cost stays flat.
* The honest summary: this buys **many tasks per session**, not cheaper tasks.

## Steps

1. Write the tests first, red.
2. Split `skills/task/SKILL.md` into the thin dispatcher and the protocol body,
   however open question 1 is settled.
3. Write `agents/task-runner.md`: `skills:` granting the protocol, no `model` so it
   inherits, a `description` that says it is dispatched by the task skills rather
   than chosen on its own, and a body stating the four transitions it may run and
   that it reports instead of asking.
4. `skills/next-task/SKILL.md`: dispatch the same agent once it has chosen the
   entry.
5. The serial rule and the worktree rule into the protocol body.
6. `README.md` and `docs/tasks/README.md`: that the work runs in a subagent, and
   that the human still sees only reports and gates.
7. Tests green, then `claude plugin validate . --strict`.

## Unit tests

In `tests/Test-Plugin.ps1`:

1. `agents/task-runner.md` exists, parses, and its frontmatter sets only fields a
   plugin agent supports - the ignored ones (`permissionMode`, `hooks`,
   `mcpServers`) must not be there, since they would silently do nothing.
2. Its frontmatter grants the protocol through `skills:`, which is the whole point
   of the design.
3. It does not set `isolation` to anything but `worktree`, and the protocol states
   the `create_branch: false` exclusion.
4. The agent body names the transitions it may run, and names `in_review` ->
   `approved` as not its own.
5. The thin `skills/task/SKILL.md` is actually thin: an upper bound on its length,
   so the split cannot quietly grow back into a second copy of the protocol.
6. The protocol body is in exactly one file - the eight status names and the
   transition headings appear in one place, which is the same guard the
   `documentation` task argued for and did not build.
7. `claude plugin validate . --strict` still passes with an `agents/` directory
   present.

## Open questions for the human

1. **The split.** Thin dispatcher plus protocol body, which is the only way the
   main thread saves anything - or keep `skills/task/SKILL.md` whole, ship the
   agent anyway, and accept that the saving is small and the total spend rises?
   This decides whether the task is worth doing at all. If the split is rejected, I
   would rather close this task as "not worth it" than ship an agent that costs
   more.
2. **On by default?** A third configuration key, `use_agents`, defaulting to off,
   or always delegate when the agent is available? A third key widens
   **Configuration** from the pair the `plugin-config` task settled.
3. **`isolation: worktree`** when `create_branch` is on: use it, or keep every task
   in the primary working tree? A worktree keeps your tree clean while the agent
   works; it also means the files you have open are not the files being changed.
4. **Model.** Omit `model` so the agent inherits the session's, or pin a cheaper one
   for the mechanical transitions? Pinning cheap is tempting and the planning
   transition is the judgement-heavy part, which argues against it.
5. **Does the agent plan?** `planning` -> `planned` ends in open questions for the
   human, and an agent cannot ask them - it would write them into the task file and
   report. That is close to what already happens, so it probably works; it does
   mean the plan is written by something you cannot interrupt mid-way.

## Relation to other backlog entries

`feature vs task` [planned, high] would give the agent a second axis: a `chore`
skips planning entirely, which is exactly the shape of work worth delegating. If
both are implemented, whichever is second decides whether a chore is delegated
whole, gates and all.
## Decision from the human (2026-11-07)

> so lets not do agents, close the task

Closed without implementation. Open question 1 was the load-bearing one - whether
to split `skills/task/SKILL.md` into a thin dispatcher and a separate protocol body
- and the answer is no, so there is nothing left worth building. An agent without
that split reads the protocol a second time in its own window while the main thread
has already paid for it, which raises the total spend to fix a problem about spend.
Questions 2 through 5 only existed inside the design that was declined.

## Result

No code. No `agents/` directory, no third configuration key, no change to any
skill, and the protocol is untouched - tasks keep running in the session that asks
for them.

What the task produced is the two findings above the open questions, and they are
the reason to keep this file until someone deliberately discards it:

* A session cannot clear itself. No skill, hook or plugin can clear the context it
  runs in, so "clear the session per task" is not available at any price. The
  alternatives are a subagent or `claude -p` from outside Claude Code, and the
  second cannot ask a human anything, which this protocol needs at four points.
* Delegating does not reduce total tokens. It stops the main thread growing, which
  buys more tasks per session rather than cheaper tasks. Anyone reopening this
  should start from that distinction, because the entry asked about spending and
  the honest answer is that delegation does not lower it.

Neither finding is a rule, so neither belongs in the protocol, and under the
`documentation` task's decision nothing had to be written anywhere else. That does
mean `clean-tasks` deleting this file is the point where the reasoning is lost -
worth a moment's thought then, not a copy of it somewhere now.