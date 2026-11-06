---
id: task-init
status: in_review
priority: high
---

# task init

- create a /task:init that creates Tasks.md with header.

# Implementation Plan

## What is being built

A fourth skill, `skills/init/SKILL.md`, invoked as `/task:init`. It sets up
`docs/tasks/` in a project that does not have it yet: the backlog file with its
header, and a short `README.md` for the humans who will read the directory.

Right now that setup is tribal knowledge. The plugin's own `README.md` shows a
backlog entry, but nothing produces the file: the first task in a new project
starts with the agent improvising a `Tasks.md`, and whatever it improvises is what
the project keeps. The header matters more than it looks - the configuration
frontmatter is in it, and a project whose `Tasks.md` has no frontmatter silently
runs on the user-level answers instead of its own.

## Templates, not prose

The two files are template files in the plugin, copied verbatim:

```
skills/init/SKILL.md
skills/init/templates/Tasks.md
skills/init/templates/README.md
```

The skill reads them from `${CLAUDE_PLUGIN_ROOT}/skills/init/templates/` and
writes them into the project. Templates rather than code blocks inside the skill,
for two reasons: the tests can assert the template is a valid backlog - the same
`Get-TaskConfig` and status checks the protocol's own files get - and a copied file
cannot be paraphrased by the agent that copies it.

`templates/Tasks.md` is this project's own `docs/tasks/Tasks.md` with the entries
taken out: the configuration frontmatter at both defaults, the "inbox for new
tasks" preamble, the entry format, the eight statuses, the three priorities, and an
empty `## Backlog` heading.

`templates/README.md` is short on purpose. It says what the directory is, that the
rules come from the plugin and not from the directory, how to add an entry, and
which commands to use. The pipeline diagram and the long explanation stay in the
plugin's `README.md`, which is one copy that stays current, instead of a copy per
project that goes stale.

## What the skill does

1. Read the configuration keys as the protocol's **Configuration** describes, so
   the frontmatter it writes states what this project will actually do.
2. `docs/tasks/Tasks.md` already exists: change nothing. Report what is there, and
   point out a missing configuration frontmatter as the one thing worth adding -
   adding it is the human's call, not the skill's.
3. Otherwise create `docs/tasks/`, copy the two templates in, and commit them.
4. Report the two paths, the configuration the frontmatter now states, and that the
   next step is a backlog entry plus `/task:task <heading>`.

It never writes a task file and never touches a project's existing `README.md`
anywhere else in the tree.

## Steps

1. No branch: `create_branch` is `false` in this project, so the work is committed
   on `main`.
2. Extend `tests/Test-Plugin.ps1` first, red - the cases below.
3. Write `skills/init/SKILL.md` and the two templates.
4. Add `init` to the skill list the tests iterate, so it gets the same frontmatter
   checks as the other three.
5. `README.md`: add `/task:init` to the commands table, and say it is the first
   thing to run in a new project. `.claude-plugin/marketplace.json`: its
   description names three skills; make it four.
6. `docs/tasks/README.md`: one line, that the directory was created by
   `/task:init`, so a reader knows where it came from.
7. Run `powershell -File tests/Test-Plugin.ps1` and
   `claude plugin validate . --strict`; both green before `in_review`.

## Unit tests

Added to `tests/Test-Plugin.ps1`:

1. **`init` is a skill like the others.** Added to `$skillNames`, so the existing
   frontmatter case covers its `name` and `description`.
2. **Both templates exist** at `skills/init/templates/Tasks.md` and
   `skills/init/templates/README.md`.
3. **The backlog template is a valid backlog.** Its frontmatter parses with
   `Get-TaskConfig`, `create_branch` is `true` and `create_pull_request` is
   `false`, it names all eight statuses and all three priorities, and it has a
   `## Backlog` heading with no entry under it.
4. **The template and this project agree.** Every status name, the priorities line
   and the `## Backlog` heading appear in both the template and this project's own
   `docs/tasks/Tasks.md`, so the two cannot drift apart unnoticed.
5. **The README template points away from itself.** It names the `task` plugin as
   where the rules live, mentions `/task:task` and `/task:next-task`, and does not
   mention `AGENTS.md`.
6. **The skill states the two guards.** `skills/init/SKILL.md` says it does not
   overwrite an existing `Tasks.md`, and that it writes no task file.
7. **The plugin advertises four skills.** `README.md`'s commands table lists
   `/task:init`, and the marketplace description no longer says three.

## Answers from the human (2026-11-06)

1. **Both files**: `/task:init` writes `docs/tasks/Tasks.md` and
   `docs/tasks/README.md`.
2. **Defaults**: the skill writes the two configuration keys at their defaults and
   says where to change them. It asks nothing.
3. **Fix the inconsistency here**: **Creating a task** step 3 gets the clause that
   makes `branch:` conditional on `create_branch`, in this task. An eighth test
   case covers it: the protocol must not tell the agent to write `branch:`
   unconditionally.

Nothing is open. The step list and the test list above stand, with that eighth
case added.
## Result

All seven steps are done on `main`, with no branch: this project's
`create_branch` is `false`, so this is the first task the protocol ran without
one.

* `tests/Test-Plugin.ps1`: **38 passed, 0 failed, 0 skipped** (was 30).
* `claude plugin validate . --strict`: **passed**.
* New files: `skills/init/SKILL.md`, `skills/init/templates/Tasks.md`,
  `skills/init/templates/README.md`. Changed: `skills/task/SKILL.md` (step 3's
  conditional `branch:`), `README.md` (the `/task:init` row),
  `.claude-plugin/marketplace.json` (four skills, not three),
  `docs/tasks/README.md` (where the directory comes from), and the tests.

Three notes on what the plan did not foresee:

* The backlog template carries two paragraphs the old header did not: what the
  two configuration keys mean, and that a heading becomes the file and branch
  name. Both are rules a human has to know before writing the first entry, and
  `Tasks.md` is the file they will actually have open.
* Two status descriptions had to lose the branch. `in_progress` said "on its
  branch" and `done` said "merged and branch deleted", which is wrong in a project
  configured the way this one now is; the template says "merged, or committed on
  `main` when the project uses no branches".
* The drift test compares the template against this project's own `Tasks.md` by
  shared tokens, not by diff. A diff would fail on the first line of prose either
  file improves, which would make the test a nuisance rather than a guard.