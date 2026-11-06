---
id: plugin-config
status: done
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

**Where one key's value comes from**: the `Tasks.md` frontmatter wins; with no
frontmatter key, the user's `/config` value; with neither, the built-in default
(`create_branch: true`, `create_pull_request: false` - what the protocol does
today). An unknown key in the frontmatter is ignored. A key whose value is neither
`true` nor `false` is not guessed at: the agent stops and asks, the same way a bad
heading does.

**What the resulting value means** (decided with the human, 2026-11-05): a key is
a ceiling, not a default. `create_branch: false` means no task gets a branch, and
that holds for whatever a later per-entry kind says: a feature in such a project
runs on `main` like everything else. `create_branch: true` means a branch is
allowed, and it is then the protocol - today always, later the entry's kind - that
decides which work uses one. The same reading applies to
`create_pull_request`.

Stating it as a ceiling is what keeps this task and *feature vs task*
independent: the two layers are an AND, so neither has to know the other's
precedence, and `create_branch` means the same thing before and after that task
lands.

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

* `in_progress` -> `in_review`: push the branch, open the request on the host, put
  its URL in the task file under a `pr:` line, and set `in_review`.
* `approved` -> `done`: the host does the merging, not the agent. Check that the
  request is merged, then delete the local branch and set `done`. If it is not
  merged, say so and stop - the human merges it.
* The host comes from `git remote get-url origin`, not from a config key: a
  `github.com` remote uses `gh`, a GitLab remote uses `glab`. Neither tool
  installed, or not authenticated: report it and stay at `in_progress`. Do not
  silently fall back to a local merge.

| Host | Open it | Check it is merged |
| :- | :- | :- |
| GitHub | `gh pr create --fill --base main --head <branch>` | `gh pr view <branch> --json state,mergedAt` |
| GitLab | `glab mr create --fill --target-branch main --source-branch <branch>` | `glab mr view <branch> --output json` |

The key stays `create_pull_request` for both. GitLab calls it a merge request, and
the protocol says so where it names the GitLab commands, but one key covers both
hosts: a project has one remote, and the question the key answers is the same.

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
5. **The pull-request path names both tools.** The protocol mentions `gh pr
   create` and `glab mr create`, says the host is read from the `origin` remote,
   and keeps the "not merged -> stop" rule, so the agent cannot invent its own
   request step on either host.
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

## Answers from the human (2026-11-05)

1. **Where the project's answer lives**: `Tasks.md` frontmatter, as planned. No
   separate config file.
2. **More keys**: no. `tasks_dir`, `branch_prefix` and `require_tests` stay out.
   The two keys the backlog entry named are the whole scope.
3. **Order against *feature vs task***: open, see below.
4. **GitLab**: yes. The pull-request path covers both hosts, as the table above
   describes.

## Answers from the human (2026-11-05)

1. **Where the project's answer lives**: `Tasks.md` frontmatter, as planned. No
   separate config file.
2. **More keys**: no. `tasks_dir`, `branch_prefix` and `require_tests` stay out.
   The two keys the backlog entry named are the whole scope.
3. **Order against *feature vs task***: this task first. A key is a ceiling, so
   `create_branch: false` takes the branch away from features too, and the two
   tasks AND together instead of competing. See **What the resulting value
   means** above; nothing in the transitions has to be rewritten when the kind
   arrives, only added to.
4. **GitLab**: yes. The pull-request path covers both hosts, as the table above
   describes.

## Unit test the ceiling adds

Test 8 in the list above becomes two cases:

* `create_pull_request: true` with `create_branch: false` is reported, not
  resolved.
* The protocol states the ceiling in so many words: that a `false` value is not
  overridable by anything per task, and that a `true` value only permits.

Nothing else in the plan changes.
## Result

All eight steps are done on `task/plugin-config`.

* `tests/Test-Plugin.ps1`: **30 passed, 0 failed, 0 skipped** (was 21).
* `claude plugin validate . --strict`: **passed**.
* `.claude-plugin/plugin.json` declares both options as booleans with their
  defaults; `skills/task/SKILL.md` gained a **Configuration** section and a
  **The host, when requests are on** section, and three transitions now branch on
  the two keys; `docs/tasks/Tasks.md` carries this project's own answers, so the
  mechanism is dogfooded.

Four notes on what the plan did not foresee:

* `branch:` had to become optional in the task file's frontmatter, not just in
  prose: with `create_branch` off there is no branch to name. The test that
  requires the key now reads the project's own config first and requires it only
  when branches are permitted, and the `check-ref-format` test skips a task file
  that has no `branch:`.
* Two more transitions needed a sentence. `in_review` -> `approved` said the human
  reads "the branch diff", which is wrong with no branch and with a request open;
  `changes_requested` -> `in_review` said to commit "on the task branch", which is
  wrong with no branch.
* The test helpers had to be hoisted. `Get-TaskConfig` is used by the task-file
  tests, which run before the configuration section, and PowerShell defines
  functions as it reads the file.
* One assertion matches `\s+` across words again, for the same reason as in
  task-011: the protocol's prose wraps at 80 characters, so a phrase a test looks
  for can break across two lines.

What was deliberately left alone: `clean-tasks` needs no configuration, and the
keys the human ruled out (`tasks_dir`, `branch_prefix`, `require_tests`) are not
there.