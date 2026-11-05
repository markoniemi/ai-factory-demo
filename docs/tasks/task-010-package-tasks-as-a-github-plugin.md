---
id: task-010
status: done
priority: medium
branch: task/010-package-tasks-as-a-github-plugin
---

# package tasks as a github plugin

- instead of having readme/agents in docs/tasks this should be either plugin or a skill, so it could be reused in other repositories.
- decided in [task-009-tasks-as-plugin-vs-skill.md](task-009-tasks-as-plugin-vs-skill.md): a plugin in its own github repository, carrying the protocol, next-task and clean-tasks as skills.
- namespaced skills, /task:next-task, /task:clean-tasks, /task:task [name-of-task]
- delete `docs/tasks/AGENTS.md` once the plugin exists, with no stub. a project keeps `Tasks.md`, its task files and `README.md`.

# Implementation Plan

## What is being built

This repository — `github.com/markoniemi/task-plugin` — becomes the plugin and its
own marketplace at the same time. The plugin root is the repository root, so the
marketplace entry's source is `"./"`. `docs/tasks/` stays where it is: it is this
project's own backlog, and it is how the plugin gets dogfooded.

Target layout:

```
.claude-plugin/plugin.json        name: task, version, description, author
.claude-plugin/marketplace.json   name: task-plugin, one entry: task -> "./"
skills/task/SKILL.md              the protocol, and /task:task <name-of-task>
skills/next-task/SKILL.md         /task:next-task
skills/clean-tasks/SKILL.md       /task:clean-tasks
tests/Test-Plugin.ps1             the unit tests
README.md                         install and use the plugin (for humans)
docs/tasks/Tasks.md               this project's backlog (unchanged)
docs/tasks/README.md              trimmed: the rules now come from the plugin
docs/tasks/AGENTS.md              deleted
```

Verified against the current docs (Claude Code 2.1.318):

* A plugin skill is invoked as `/<plugin>:<skill>`, so the three skills give
  `/task:task`, `/task:next-task` and `/task:clean-tasks`. No `commands/` files are
  needed — the docs call `skills/` the preferred form for new plugins.
* A skill takes arguments through `$ARGUMENTS`, so `/task:task lightweight task`
  reaches the skill as text. `/task:next-task` takes none.
* `skills/` is the default scan location, so `plugin.json` needs no `skills` key.
* `.claude-plugin/marketplace.json` requires `name`, `owner.name` and `plugins`; an
  entry requires `name` and `source`, and `"./"` means the marketplace root.
* `claude plugin validate .` is the authoritative check and exits non-zero on error.

## Division of the rules between the three skills

`docs/tasks/AGENTS.md` is the source text. It is moved, not rewritten, except where
it names this repository:

* **`skills/task/SKILL.md`** — the whole protocol: task files and frontmatter,
  selection, backlog mirror, the transitions, and the shell notes. It is also the
  entry point for *start this named task*: with `$ARGUMENTS` it creates or picks up
  that backlog entry and runs it through the transitions; with no arguments it
  states the protocol and the current task list.
* **`skills/next-task/SKILL.md`** — *Creating a task from the backlog* plus the
  *next* rule (highest priority, then first in `Tasks.md`, skipping entries that
  already have a `plan:` line). It reads the protocol from the `task` skill rather
  than repeating it: `${CLAUDE_PLUGIN_ROOT}/skills/task/SKILL.md`.
* **`skills/clean-tasks/SKILL.md`** — the *Cleaning up* rule, including the
  "never on your own, never as part of reaching `done`" guard and the
  "write the rule down before deleting the plan" step. In a project with no
  `AGENTS.md`, the place a surviving rule goes is the project's own `README.md` or
  wherever that project keeps its instructions.

Each skill's `description` has to say *when* to use it, because that line is what
puts the skill in front of the agent on every turn. That is the whole gain the
decision record named: `AGENTS.md` was only read when someone thought to read it.

## Steps

1. Create the branch `task/010-package-tasks-as-a-github-plugin`.
2. Write `tests/Test-Plugin.ps1` first, red: it asserts the manifests, the three
   skills, the absence of `docs/tasks/AGENTS.md`, and a clean
   `claude plugin validate .`.
3. Write `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`.
4. Write the three `SKILL.md` files from `docs/tasks/AGENTS.md`.
5. Delete `docs/tasks/AGENTS.md`; trim `docs/tasks/README.md` so it points at the
   plugin's skills instead of at `AGENTS.md`.
6. Write the repository `README.md`: what the plugin is, `/plugin marketplace add
   markoniemi/task-plugin`, `/plugin install task@task-plugin`, the three commands,
   and what a using project keeps (`Tasks.md`, its task files, its own `README.md`).
7. Run the tests and `claude plugin validate .`; both must pass before `in_review`.

## Unit tests

`tests/Test-Plugin.ps1`, run as `powershell -File tests/Test-Plugin.ps1`. Plain
PowerShell with a pass/fail count and a non-zero exit code on failure — Pester is
not assumed to be installed. Cases:

1. `.claude-plugin/plugin.json` parses, `name` is `task`, and `version`,
   `description` and `author.name` are non-empty.
2. `.claude-plugin/marketplace.json` parses, `name` is `task-plugin`, `owner.name`
   is non-empty, and it holds exactly one entry, `task`, with source `"./"`.
3. For each of `task`, `next-task`, `clean-tasks`: `skills/<n>/SKILL.md` exists,
   starts with `---`, and its frontmatter `name` equals `<n>` with a non-empty
   `description`.
4. `skills/task/SKILL.md` mentions `$ARGUMENTS`, so the named-task form works.
5. The protocol survived the move: each status name and each transition heading
   from the old `AGENTS.md` appears in some `SKILL.md`.
6. `docs/tasks/AGENTS.md` does not exist, and no file under `docs/` points at it.
7. `claude plugin validate .` exits 0, when `claude` is on `PATH`; skipped with a
   printed note when it is not.

## Result

All seven steps are done on `task/010-package-tasks-as-a-github-plugin`.

* `tests/Test-Plugin.ps1`: **13 passed, 0 failed, 0 skipped**.
* `claude plugin validate . --strict`: **passed**. Its one warning is
  `ICON_MISSING`, which only matters for a submission to Anthropic's plugin
  directory, not for installing from this repository.
* `docs/tasks/AGENTS.md` moved to `skills/task/SKILL.md` — git records it as a
  rename, so the protocol's history follows it.

Two notes on what the plan did not foresee:

* The "nothing points at `AGENTS.md`" test had to be narrowed. Task files are
  records of work already done and mention the file as history, which is correct;
  the test now checks only the files a reader is sent to for the rules —
  `docs/tasks/README.md` and the `Tasks.md` preamble — and exempts the plugin's own
  `README.md`, which says there is no `AGENTS.md`.
* `skills/task/SKILL.md` adds one rule that was implicit before: a task that wrote
  no code reaches `done` without a branch to merge. Task-009 was the first such
  task.

## Open question for the human

Nothing blocks the work. One thing to check later, carried over from task-009: a
repository of your own is a third-party marketplace, and an employer can block
those through managed settings. If that happens at work, `--plugin-dir` against a
local clone still loads the plugin.
