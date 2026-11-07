---
id: task-plugin-vs-https-backlog-so
status: done
priority: high
---

# task plugin vs https://backlog.so/

- how does backlog.so work? is it free?
- does it overlap with task-plugin?
- should i rename task-plugin to backlog-plugin? then naming backlog items as task and feature and epic would be no problem.

# Implementation Plan

## What this decides

Two of the three bullets are research, answered below from the live sites on
2026-11-07. The third is a rename, and it is the only one that would change a
line of this repository. By default this task is a decision record that writes
its answers down and reaches `done` with no code; see open question 1.

## What backlog.so is

`backlog.so` is the site for `osmove/backlog`, at v0.5.1: **a task orchestrator
for AI coding agents**, not a task format.

* You put a task on a board. It splits the task into sub-tasks scoped to
  particular repositories and file paths, each with a risk level and
  dependencies.
* Each sub-task takes an **exclusive claim** on its paths and is dispatched to an
  agent in its own git worktree, on a branch `backlog/<task-id>`. Conflicting
  sub-tasks wait.
* Parallelism is capped by `max_agents` in `config.toml`. A scheduler recovers
  crashed runs; claims expire after 30 minutes unless heartbeats renew them.
* A pre-commit hook refuses commits not covered by a claim. Commits carry
  `Backlog-Run`, `Task` and `Subtask` trailers, and a run inspector links every
  change back to its task, claim and agent.
* Interfaces: a CLI (`npm i -g backlog`, headless, CI-capable, `backlog board`
  serves a local kanban), a desktop app for macOS/Linux/Windows, and
  `@osmove/backlog-sdk` over an OpenAPI 3.0.3 REST API.
* Drives Claude Code, Codex and arbitrary shell commands, provider per task.

**Is it free?** Yes, for what exists today. CLI, desktop and SDK are Apache-2.0,
"free forever", no seat or run caps, your own API keys, no telemetry, runs
offline. A hosted **Cloud** tier (Pro/Team/Enterprise: sync, SSO, hosted
executors) is "coming soon" with no prices published. One third-party listing
reports the repository licence as "other", so read `LICENSE` in the repository
before depending on Apache-2.0.

## The product that actually overlaps is a different one

Searching for this turned up **Backlog.md** (`MrLesk/Backlog.md`, MIT, ~7.3k
stars), which is not the site asked about but is far closer to this plugin than
`backlog.so` is:

* Every task is "a plain `.md` file in your repo", under `backlog/tasks`
  (`.backlog/` or a custom path via `backlog.config.yml`), ids like `TASK-1`.
* A `backlog` CLI, a kanban visualiser, `task archive` / `restore` / `delete`,
  and `--json` output with `task list --json --watch`.
* Claude Code integration by MCP: `claude mcp add backlog --scope user -- backlog
  mcp start`, workflow guides served at `backlog://workflow/...`. The repository
  ships `CLAUDE.md`, `AGENTS.md` and a `.claude` folder.
* Its recommended flow is **three human checkpoints - review the spec, review the
  plan, review the code** - and one task per context window, one task per PR.

That last line is this protocol's own design arrived at independently: this
plugin gates `draft` -> `planning` (the spec) and `in_review` -> `approved` (the
code), and holds at `planned` for the plan. Someone else reached the same three.

## Does it overlap?

| | this plugin | backlog.so | Backlog.md |
| :- | :- | :- | :- |
| where a task lives | `docs/tasks/<slug>.md` in the repo | a board; run state outside the repo | `backlog/tasks/*.md` in the repo |
| what you install | a Claude Code plugin, no runtime | Node global CLI + desktop app + scheduler | Node global CLI + MCP server |
| what it governs | one agent, one task, human gates | many agents at once: worktrees, file claims, retries | one task per context window |
| human gates | 2 (ask for a plan, approve the diff) | review after a run | 3 (spec, plan, code) |
| parallelism | none, by decision | the entire point | none |
| needs an account | no | no (cloud later) | no |

So: **`backlog.so` barely overlaps, and the part it does is the part this
repository already declined.** README `## Decisions` records "No subagent per
task" with its reasoning; `backlog.so` is that decision taken the other way, with
real machinery behind it (claims, worktrees, a pre-commit hook) that a plugin made
of prose cannot have. If parallel agents are ever wanted here, the honest move is
to use `backlog.so`, not to grow one.

**Backlog.md overlaps substantially** - markdown tasks in the repository, statuses,
a human-gated flow, Claude Code integration - and differs in being a Node binary
with a kanban UI and an MCP server, where this is prose a skill injects and
nothing to install.

## The name is already taken three times

"Backlog" names at least three shipped products: `backlog.so` (osmove),
Backlog.md (MrLesk), and Nulab's Backlog (the project-management SaaS, free tier
of one project, Starter listed at $35/mo). The npm name `backlog` is taken. A
rename to `backlog-plugin` would put this repository into that crowd and make it
harder to find, not easier.

## What the rename would actually buy

The bullet's reason is the real argument, and it is not about branding: it is
`feature-vs-task.md` **open question 2**. Today the plugin is called `task`, its
files are task files, and `/task:task` starts one - so if `task` also names the
*small kind* of work, "the task file" stops saying which kind it holds. That
collision is the only reason the small kind is currently proposed as `chore`
rather than `task`.

Rename the plugin and the collision goes: items are *backlog items*, and
`task`, `feature` and `epic` are free as kind names, which is exactly what the
bullet says.

So the two entries are coupled: this one's answer decides that one's open
question 2.

## What the rename would cost

* `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`.
* The skill directory `skills/task/` and the name `task` in its frontmatter -
  `/task:task` becomes `/backlog:task`.
* The absolute path `skills/task/SKILL.md` that `clean-tasks` and `next-task`
  both read the protocol from.
* `README.md`: the command table and both install lines
  (`markoniemi/task-plugin`).
* `tests/Test-Plugin.ps1`: the manifest and frontmatter assertions.
* The GitHub repository name, which is the marketplace address. **Every existing
  install breaks**, and `/plugin marketplace add markoniemi/task-plugin` stops
  resolving. There is one installed copy today, so the cost is small now and grows.
* Open question 3: whether `docs/tasks/` becomes `docs/backlog/`, which would
  also break every project that has already run `/task:init`.

## "epic" is not just a name

The bullet lists `task`, `feature` and `epic`. The first two are
`feature-vs-task.md`'s kinds. **`epic` is new**: an epic is a parent of other
items, and this protocol has no parent/child relation anywhere - no `parent:`
key, no roll-up status, no rule for what a parent's status means when its
children disagree. Freeing the word does not build the feature. Open question 4.

## A side effect of the heading

The heading contains a URL, so the slug rule produced
`task-plugin-vs-https-backlog-so` - `https` and all. The slug passes every check
the protocol makes (pattern, length, uniqueness, legal branch name), so the
protocol gave no reason to stop and ask. Rename the heading if you want a tidier
file name; nothing is broken either way.

## Steps

1. A human answers open question 1.
2. **If a decision record** (the default): add the findings worth keeping to
   `README.md` `## Decisions` - that `backlog.so` is the declined-subagent
   decision taken the other way and is where parallel agents should come from if
   ever wanted, and that Backlog.md reached the same three human checkpoints
   independently. Then `in_review` -> `approved` -> `done`, no branch, no code, as
   the protocol's last paragraph of **`approved` -> `done`** allows.
3. **If the rename ships**, it is its own backlog entry, not this one: it touches
   both manifests, every skill, the repository name and every installed copy.
   This task then records only the decision and the name chosen.
4. Either way, answer `feature-vs-task.md` open question 2 from the result, since
   it is waiting on it.

## Unit tests

None, if this stays a decision record: nothing in the plugin changes, and a test
asserting that `README.md` mentions a competitor would test prose, not behaviour.

If the rename ships, in its own entry, the tests are: the two manifests agree on
the new plugin name; no file outside `docs/tasks/` still says `task-plugin`; and
every skill's cross-reference path to the protocol resolves to a file that exists.
The last one is worth having whatever happens - it is absent today, and a rename
is exactly what would break it.

## Relation to other backlog entries

`feature-vs-task.md` (`planned`, high) is blocked-ish on this: its open question
2 is the naming collision this task can dissolve. Working them in the other order
means picking `chore`, then renaming, then wishing the small kind were `task`.

## Open questions for the human

1. **Decision record, or does this task carry the rename out?** The research is
   done either way. Keeping it a record is cheap and keeps the rename auditable as
   its own change.
2. **Rename to what?** `backlog` is crowded (three products, npm taken). Options:
   keep `task`; `backlog` and accept the crowd; or a word nobody else uses, which
   gets the vocabulary *and* a searchable name - the plugin's distinctive feature
   is the human gate, not the backlog.
3. **Does `docs/tasks/` move too?** Renaming the plugin does not require it.
   Moving it breaks every project that already ran `/task:init`.
4. **Is `epic` in scope?** It needs a parent/child relation the protocol does not
   have. If yes it is a third entry, not a name.
5. **Order against `feature-vs-task`.** Answer this first and that task's open
   question 2 answers itself; answer that one first and the names may be rewritten
   twice.
6. **Should anything be taken from Backlog.md** - an MCP server instead of an
   injected skill, `--json` output, the archive step - or is "nothing to install"
   the whole point of this plugin?

## Result

The human answered on 2026-11-07: **keep the name `task-plugin`, close the task.**
That is open question 1 as a decision record and open question 2 as "keep `task`",
and it makes 3, 4 and 5 moot - nothing moves, `epic` is not in scope, and there is
no ordering problem left. Open question 6 was not answered and is not open work:
nothing here waits on it.

No code changed. What survives this file:

* `README.md` `## Decisions` gained **Keeps the name `task`** with the reasoning,
  a pointer from **No subagent per task** to `backlog.so` as that decision taken
  the other way, and the note that Backlog.md reached the same three human
  checkpoints independently.
* `feature-vs-task.md` open question 2 records that the escape route is closed.

There was nothing to review, so this went from `planned` to `done` without a
`## How to review` section: the decision was the human's own, and the status
reaching `done` records it.
