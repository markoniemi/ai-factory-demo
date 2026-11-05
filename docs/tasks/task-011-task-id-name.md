---
id: task-011
status: approved
priority: high
branch: task/011-task-id-name
---

# task id/name

- the protocol states: "A task is a file `docs/tasks/task-NNN-<slug>.md"
- metadate states: id: task-001
- what if id was based on task heading, and human promises to make simple task headings
- should the be a check that heading task can be used as git branch name?

# Implementation Plan

## What changes

The running number goes away. A task's identity becomes the slug of its backlog
heading, and that one slug is the `id`, the file name and the branch name:

| | now | after |
|---|---|---|
| file | `docs/tasks/task-010-package-tasks-as-a-github-plugin.md` | `docs/tasks/package-tasks-as-a-github-plugin.md` |
| `id:` | `task-010` | `package-tasks-as-a-github-plugin` |
| `branch:` | `task/010-package-tasks-as-a-github-plugin` | `task/package-tasks-as-a-github-plugin` |

What this buys: the heading, the file name, the `id` and the branch are the same
string, so nothing has to be looked up or kept in step. The agent no longer has to
scan for the next free number - a step that needs the whole directory listed and
that two parallel sessions get wrong in the same way, both claiming `task-011`.

What it costs: the directory no longer sorts chronologically, and a renamed heading
is a renamed task. Both are addressed below.

## Slug rule

The slug is derived from the heading, not invented:

1. Lower-case the heading.
2. Replace every run of characters outside `a-z0-9` with a single `-`.
3. Strip leading and trailing `-`.

So `task id/name` becomes `task-id-name`, `feature vs task` becomes
`feature-vs-task`.

The result has to satisfy all of:

* matches `^[a-z0-9][a-z0-9-]*[a-z0-9]$` - so at least two characters, and no
  leading or trailing `-`;
* at most 60 characters;
* no other task file already uses it.

If the heading fails the rule - it is empty of letters and digits, it collides, or
it is too long - the agent does not improvise a different slug. It stops and asks
the human to edit the heading. That is the "human promises to make simple headings"
half of the bargain, enforced at the one moment where it is cheap to fix.

## Is a separate git check needed?

No, and it is worth writing down why, because the entry asks for one.

`git check-ref-format` rejects a ref that contains a space, any of `~ ^ : ? * [ \`,
an ASCII control character, `..`, `@{`, a leading or trailing `/` or `.`, a trailing
`.lock`, or that is exactly `@`. A string matching `^[a-z0-9][a-z0-9-]*[a-z0-9]$`
can contain none of them, so a slug that passes the rule above is always a valid
branch name under `task/`. The slug rule *is* the check.

What remains worth checking is that the rule was actually applied, and that is a
test, not a runtime step: for every task file, assert that `id` equals the file's
base name, that it matches the pattern, and that
`git check-ref-format refs/heads/<branch>` exits 0. That catches a hand-edited
frontmatter, which is the realistic failure, rather than re-deriving what the regex
already guarantees.

## Existing tasks

The four task files in this repository keep their names. Renaming them would rewrite
`plan:` links, the cross-reference in the task-010 entry, and the branch names
recorded in files whose branches are already merged and deleted - churn in records
of finished work. They are all `done`, so `/task:clean-tasks` removes them in time
and the old form disappears on its own.

The protocol therefore **reads** both forms and **writes** only the new one:

* Finding a task by name matches the heading slug first, then any task file name,
  case-insensitively.
* Scanning for task files can no longer glob `task-*.md`. It becomes: every `*.md`
  under `docs/tasks/` except `README.md` and `Tasks.md`.

That last point is the one real loss of the numbered scheme - `task-` was a marker
that said "this is a task file". The exclusion list replaces it, and the protocol
already carried that same sentence for `README.md` and `Tasks.md`.

## Ordering

`id` stops encoding age. Where order matters it is already available: the backlog
lists entries in order, `Selection` breaks priority ties with the oldest file first,
and `git log --diff-filter=A -- docs/tasks/` gives the true creation order. No
`created:` field is added; it would be a second thing to keep honest.

## Steps

1. Create the branch `task/011-task-id-name`.
2. Extend `tests/Test-Plugin.ps1` first, red - the cases listed below.
3. `skills/task/SKILL.md`: rewrite the `ARGUMENTS` line, **Task files** (file shape,
   frontmatter example, `id`), **Selection** step 1 (the new scan), **Creating a
   task** steps 1-2 and 4 (the slug rule, the stop-and-ask on a bad heading, the
   `plan:` link), and **Starting from the task name** step 1 (match the heading slug
   as well).
4. `skills/next-task/SKILL.md`: step 1 names the slug instead of `task-NNN` and
   `task/NNN-<slug>`.
5. `docs/tasks/README.md`: the `task-NNN-*.md` bullet and the worked example.
6. `README.md`: the `docs/tasks/task-NNN-*.md` line in the layout block.
7. Run `powershell -File tests/Test-Plugin.ps1` and `claude plugin validate .`; both
   green before `in_review`.

## Unit tests

Added to `tests/Test-Plugin.ps1`:

1. **The protocol states the slug rule.** `skills/task/SKILL.md` contains the regex
   `^[a-z0-9][a-z0-9-]*[a-z0-9]$` and the words that tell the agent to stop and ask
   when a heading fails it.
2. **No numbered form is prescribed any more.** Neither `SKILL.md` offers
   `task-NNN`, `task/NNN-` or "next free number". Replaces the current
   `'task-NNN-'` assertion in the *task file shape* case, which this task inverts.
3. **The scan rule is stated.** `skills/task/SKILL.md` says that the task files are
   every `*.md` under `docs/tasks/` except `README.md` and `Tasks.md`.
4. **Every task file in this repository is self-consistent.** For each task file:
   frontmatter has `id`, `status`, `priority`, `branch`; `status` is one of the eight
   names; `priority` is one of the three; and `id` is either the legacy `task-NNN`
   plus a file name starting with that id, or equal to the file's base name and
   matching the slug pattern.
5. **Every `branch:` is a legal git branch name.** `git check-ref-format
   refs/heads/<branch>` exits 0, for every task file. Skipped with a printed note if
   `git` is not on `PATH`.
6. **Slug derivation is exercised directly.** A `Get-TaskSlug` helper in the test
   file implements the three derivation steps, and a table drives it:
   `task id/name` to `task-id-name`, `feature vs task` to `feature-vs-task`,
   `  Spaces  and--dashes ` to `spaces-and-dashes`, `C# & .NET` to `c-net`,
   `???` rejected, `a` rejected. The helper is the executable statement of the
   rule; the prose in `SKILL.md` is what the agent reads.

Test 6 duplicates the rule in two places on purpose - prose for the agent, code for
CI. If that pair ever disagrees, the test file is wrong and the skill is right.

## Open questions for the human

1. **Prefix.** The table above drops `task-` from the file name entirely
   (`feature-vs-task.md`). Keeping a prefix would give `task-feature-vs-task.md`,
   which stutters, but makes a task file recognisable by name outside its directory.
   The plan assumes no prefix.
2. **Rename of a heading.** If you edit a heading after the task file exists, the
   slug no longer matches. The plan treats the file as authoritative and leaves it
   alone - the `plan:` link still resolves, so nothing breaks, and the agent finds
   the task by file name. The alternative is to rename file, `id` and branch on the
   spot, which rewrites history mid-task. Say if you want the rename instead.
3. **Interaction with *feature vs task*.** That entry (`planning`, high) may remove
   the branch for a plain task altogether. If a task can live without a branch, the
   `branch:` frontmatter becomes optional and test 5 applies only when it is
   present. Nothing here blocks that; it is listed so the two plans do not surprise
   each other.
## Result

All seven steps are done on `task/011-task-id-name`.

* `tests/Test-Plugin.ps1`: **21 passed, 0 failed, 0 skipped** (was 13).
* `claude plugin validate . --strict`: **passed**, with the same lone
  `ICON_MISSING` warning as before, which only matters for a submission to
  Anthropic's plugin directory.
* The slug rule is now stated in `skills/task/SKILL.md` and executed by
  `Get-TaskSlug` / `Test-TaskSlug` in the test file. Both agree on the six cases
  the plan listed.

Three notes on what the plan did not foresee:

* This task file itself keeps the numbered name. It was created under the old rule
  before the new one existed, so it is grandfathered along with tasks 007 to 010,
  and the legacy branch of the test covers it. The first task named by slug will be
  the next one created.
* The protocol can no longer spell the legacy form as `task-NNN`, because a test
  forbids that string in both skills. It names a concrete example instead,
  `task-007-clean-tasks.md`.
* One assertion had to match across whitespace. The protocol's prose wraps at 80
  characters, so a phrase a test looks for can break across two lines; matching
  `\s+` between the words keeps the test from dictating where the prose wraps.