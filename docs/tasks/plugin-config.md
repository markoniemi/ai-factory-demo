---
id: plugin-config
status: planned
priority: high
branch: task/plugin-config
---

# plugin config

- add configuration to plugin
- user should be able to config task-plugin to fit project needs
- config items:
  - create branch: true/false
  - create pull-request: true/false

# Implementation Plan

## What Claude Code gives us, and what it does not

Checked against the plugin manifest reference and the settings reference
(2026-11-05):

* `plugin.json` has a `userConfig` block. Each option is `{ type, title,
  description }` plus optional `required`, `default`, `options`, `multiple`,
  `sensitive`, `min`/`max`. `type` may be `boolean`.
* Claude Code prompts for those values when the plugin is enabled, and each
  non-sensitive option also appears as a row in `/config`.
* A saved value substitutes into **skill content** as `${user_config.KEY}`, which
  is exactly what a protocol written in Markdown needs.
* The answers are stored in `pluginConfigs`, and that setting is read from the
  **user** settings file and from **managed** settings. It is not read from
  `.claude/settings.json` or `.claude/settings.local.json`.

That last point decides the design. `userConfig` is per user and per machine, so
on its own it cannot "fit project needs": one human with two repositories would
get one answer for both, and a colleague cloning the project would get none.

## The design: two layers, project wins

**Layer 1, the project.** A YAML frontmatter block at the top of
`docs/tasks/Tasks.md`:

```markdown
---
create_branch: true
create_pull_request: false
---

# Task Backlog
```

Why there and not in a new file: `Tasks.md` is the one file every skill already
reads on every invocation, so the config costs no extra read; it is the file the
human already edits to drive the protocol; and it is committed, so the project's
answer travels with the project and is the same for everyone who clones it.

**Layer 2, the user.** `userConfig` in `plugin.json` declares the same two keys
with defaults, so `/config` shows them and a project that says nothing still has
an answer. The skill reads them as `${user_config.create_branch}` and
`${user_config.create_pull_request}`.

**Precedence**, stated once in the protocol: the `Tasks.md` frontmatter wins; with
no frontmatter key, the user's `/config` value; with neither, the built-in default
(`create_branch: true`, `create_pull_request: false` - what the protocol does
today). An unknown key in the frontmatter is ignored. A key whose value is neither
`true` nor `false` is not guessed at: the agent stops and asks, the same way a bad
heading does.

## What the two keys change

`create_branch: false`

* `planned` -> `in_progress`: set the status on `main` and commit there. No branch
  is created, and the implementation commits land on `main`.
* `in_progress` -> `in_review`: unchanged, except there is no branch to read. The
  human reads the commits on `main`.
* `approved` -> `done`: nothing to merge or delete. Set `done` and mirror it, which
  is the path the protocol already has for a task that wrote no code.
* The task file's `branch:` frontmatter is omitted when no branch will exist.

`create_pull_request: true` (requires `create_branch: true`; the two set the other
way round is a contradiction the agent reports instead of resolving)

* `in_progress` -> `in_review`: push the branch and open a pull request with
  `gh pr create --fill --base main --head <branch>`, then put its URL in the task
  file under a `pr:` line and set `in_review`.
* `approved` -> `done`: the host does the merging, not the agent. Check that the
  pull request is merged (`gh pr view --json state,mergedAt`), then delete the
  local branch and set `done`. If it is not merged, say so and stop - the human
  merges it.
* `gh` missing or unauthenticated: report it and stay at `in_progress`. Do not
  silently fall back to a local merge.

The sentence "This protocol uses no pull requests" comes out of the protocol and
becomes "pull requests are off by default; `create_pull_request` turns them on".

## Steps

1. Create the branch `task/plugin-config`.
2. Extend `tests/Test-Plugin.ps1` first, red - the cases below.
3. `.claude-plugin/plugin.json`: add the `userConfig` block with `create_branch`
   (boolean, default `true`) and `create_pull_request` (boolean, default `false`),
   each with `title` and `description`.
4. `skills/task/SKILL.md`: add a **Configuration** section (the two keys, the two
   layers, the precedence, the stop-and-ask on a bad value) and rewrite the three
   affected transitions to branch on the two keys.
5. `skills/next-task/SKILL.md`: one line, that the protocol's configuration
   decides whether a branch is created. `clean-tasks` needs no change.
6. `docs/tasks/README.md`: the frontmatter block, what each key does, and that the
   AI reads it. `README.md`: a Configuration section with the same table, since
   that is what a human installing the plugin reads first.
7. Add the frontmatter block to this project's own `docs/tasks/Tasks.md`, with both
   keys at their defaults, so the plugin is dogfooded and the shape is exercised.
8. Run `powershell -File tests/Test-Plugin.ps1` and
   `claude plugin validate . --strict`; both green before `in_review`.

## Unit tests

Added to `tests/Test-Plugin.ps1`:

1. **The manifest declares both options.** `userConfig.create_branch` and
   `userConfig.create_pull_request` exist, `type` is `boolean`, `default` is `true`
   and `false` respectively, and each has a non-empty `title` and `description`.
2. **No unknown key inside a `userConfig` option**, since Claude Code treats those
   objects as strict and the plugin would fail to load. The test asserts each
   option's keys are a subset of the documented set.
3. **The protocol states the keys, the layers and the precedence.**
   `skills/task/SKILL.md` names `create_branch`, `create_pull_request`,
   `Tasks.md` frontmatter, `${user_config.`, and the word `precedence`.
4. **The protocol still covers the default path.** With `create_branch` on, the
   transitions must still say to create the branch named in `branch:`; the test
   asserts the branch-creating sentence survives the rewrite.
5. **The pull-request path names its tool.** The protocol mentions `gh pr create`
   and the "not merged -> stop" rule, so the agent cannot invent its own PR step.
6. **Config parsing, driven by a table.** A `Get-TaskConfig` helper in the test
   file reads YAML frontmatter from a `Tasks.md` text and merges it over the
   defaults. Cases: no frontmatter -> both defaults; `create_branch: false` ->
   false, other key still default; unknown key -> ignored, no error;
   `create_branch: yes` -> rejected as not a boolean; frontmatter not at the very
   top of the file -> ignored, defaults used.
7. **This project's own `Tasks.md` parses.** Its frontmatter is read by the same
   helper and both keys come out boolean.
8. **The contradiction is called out.** The protocol says that
   `create_pull_request: true` with `create_branch: false` is reported, not
   resolved.

## Open questions for the human

1. **Where the project's answer lives.** The plan puts it in `Tasks.md`
   frontmatter. The alternative is a separate `docs/tasks/task.config.json`:
   easier to validate, one more file to read and to explain. Frontmatter is the
   recommendation; say if you would rather have the file.
2. **More keys.** Two others are cheap once the mechanism exists and would remove
   hardcoded assumptions from the protocol: `tasks_dir` (default `docs/tasks`) and
   `branch_prefix` (default `task/`). A third, `require_tests` (default `true`),
   would let a docs-only project stop the protocol from demanding unit tests. None
   is in the plan's scope; say which you want and they go in the same pass.
3. **Overlap with *feature vs task*.** That entry (`planning`, high) wants a
   per-entry choice of branch or no branch. This task gives the project-wide
   default; that one would give the per-task override, reading as
   `[<status>, <priority>]` plus a kind. The two fit together, but the order
   matters: this one first, then that one as an override on top. Confirm that
   order, or say if *feature vs task* should come first instead.
4. **Pull requests and the remote.** `gh pr create` needs a GitHub remote and an
   authenticated `gh`. This repository has one; a project using the plugin may
   not, which is why the default is `false`. If you want GitLab too (this
   repository has `.gitlab-ci.yml`), the PR path needs a `glab` branch as well -
   out of scope unless you say otherwise.