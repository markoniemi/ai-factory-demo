---
id: task-008
status: in_review
priority: medium
branch: task/008-superpowers-compatibility
---

# superpowers compatibility

- using superpowers plugin, which likes to write plans in some place, should tasks be compatible with superpowers plugin?

# Implementation Plan

## What superpowers actually does

Read from the installed plugin (`claude-plugins-official/superpowers`, versions
6.3.0, 6.4.1 and 7.0.0 cached; 7.0.0 is current):

| Skill | Artifact or action |
|-------|--------------------|
| `brainstorming` | a design document at `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`, committed |
| `writing-plans` | a plan at `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`, with checkbox steps, then asks the human to review it |
| `executing-plans` | works through the checkboxes, commits as the plan's commit steps say, then a whole-branch review |
| `finishing-a-development-branch` | runs the test suite, detects the environment, **presents merge options**, cleans up |
| `using-git-worktrees` | an isolated worktree per plan |

So superpowers and this protocol collide in four places:

1. **Where the plan lives.** Ours is a `# Implementation Plan` section inside the
   task file; superpowers writes a separate dated file under
   `docs/superpowers/plans/`.
2. **What tracks progress.** Ours is `status` in the task file's frontmatter,
   mirrored into the `Tasks.md` brackets; superpowers uses checkboxes in the plan.
3. **How work ends.** Ours is fixed: fast-forward into `main`, delete the branch,
   set `done`. `finishing-a-development-branch` instead offers the human a choice of
   endings, and starts by running a test suite this repository does not have.
4. **Branch vs worktree.** Ours names one branch in the frontmatter;
   `using-git-worktrees` wants an isolated worktree per plan.

## Cost of keeping both

Measured against the installed plugin:

* `using-superpowers` is injected at every session start by a plugin hook: ~800
  tokens, whether or not a skill is used.
* The 15 skill descriptions sit in the per-turn skill listing: ~630 tokens.
* A skill that fires costs 2k–20k; all 15 would be ~40k.

Over the sessions that built task-001 through task-007, no superpowers skill was
invoked once. Every task was documentation work from a specification the human had
already written, which is exactly what `writing-plans` would have produced.

The real cost is not the tokens. `using-superpowers` instructs the agent that if
there is any chance a skill applies it must be used, and that brainstorming precedes
creative work — a standing pull towards a second, parallel workflow.

## Decision (from human, 2026-11-04)

Switch off only the four skills that duplicate this protocol, in **user settings**
(`~/.claude/settings.json`), not in this repository:

```json
"skillOverrides": {
  "superpowers:writing-plans": "off",
  "superpowers:executing-plans": "off",
  "superpowers:finishing-a-development-branch": "off",
  "superpowers:using-git-worktrees": "off"
}
```

The ten judgment skills stay: `brainstorming`, `test-driven-development`,
`systematic-debugging`, `verification-before-completion`, the code-review pair,
`dispatching-parallel-agents`, `writing-skills`, `diagnosing-superpowers`.

With the collision removed at the source, `AGENTS.md` needs no superpowers section:
there is no competing plan location left to rule against. Nothing about the plugin
enters this repository, for the same reason the PowerShell settings stayed out —
it describes one machine, not this project.

Known limitation: `skillOverrides` governs the skill listing, so it does not stop
the SessionStart injection of `using-superpowers`. That ~800 tokens per session
remains until the plugin or its hooks are disabled.

## Steps

1. Add the `skillOverrides` block above to `~/.claude/settings.json`, merging with
   the keys already there.
2. Verify the file still parses and that `writing-plans`, `executing-plans`,
   `finishing-a-development-branch` and `using-git-worktrees` no longer appear in
   the available-skills list.
3. Change nothing in `docs/tasks/`: no `AGENTS.md` section, no `spec:` line, no
   change to the cleanup rule.
4. Unit tests: not applicable (configuration only).
