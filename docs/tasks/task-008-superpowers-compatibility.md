---
id: task-008
status: planned
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

## Recommendation

Keep `docs/tasks/` as the single system of record, and treat superpowers as *how*
the work is thought through, not *where* it is written down. Superpowers' own
`using-superpowers` skill says project instructions take precedence over skills, so
this is a supported override rather than a fight with the plugin.

Concretely:

* The plan stays in the task file. When `writing-plans` runs, its output goes into
  the task file's `# Implementation Plan` section instead of
  `docs/superpowers/plans/`, and no file is created there.
* A design document from `brainstorming` is allowed, because it is a different
  artifact from a plan: it may be committed at `docs/superpowers/specs/...` and
  linked from the task file with a `spec:` line. It is deleted with the task when
  the task is cleaned.
* Checkboxes inside the plan are fine — they are detail within one step. `status`
  in the frontmatter remains the only thing that says where the task is.
* `finishing-a-development-branch` is **not** used: the `approved` → `done`
  transition in `AGENTS.md` already fixes the ending, and there is no test suite to
  gate it on.
* Worktrees stay optional. The frontmatter `branch` is the contract; whether that
  branch is checked out in place or in a worktree is the agent's business.

The process skills that cost nothing to keep — `brainstorming`,
`test-driven-development`, `systematic-debugging`,
`verification-before-completion` — stay available and are worth using inside the
`planning` and `in_progress` steps.

## Open questions (for human to verify)

- **Is superpowers assumed?** The plan writes the override as conditional ("if the
  superpowers skills are available"), so the protocol still reads correctly in a
  repository without the plugin. Confirm, or say superpowers is a prerequisite.
- **Brainstorming before `planning`:** the plan leaves it optional. Say so if
  `planning` should always start with `brainstorming` and a committed design doc,
  which adds a conversation round per task.
- **Depends on `lightweight task`:** a lightweight task has no plan and no branch,
  so none of this applies to it. That entry is still `planning`; if it lands first,
  step 2 below needs one extra sentence saying lightweight tasks skip the skills
  entirely.

## Steps

1. Create branch `task/008-superpowers-compatibility` from `main`.
2. Add a **Superpowers** section to `AGENTS.md`, after **Cleaning up**, stating the
   override: if the superpowers skills are available, use their thinking but keep
   the artifacts here — plan into the task file, never into
   `docs/superpowers/plans/`; `status` not checkboxes; do not use
   `finishing-a-development-branch`, because `approved` → `done` already says how
   work ends.
3. In the same section, allow an optional design document at
   `docs/superpowers/specs/...` linked by a `spec:` line in the task file.
4. Extend the **Cleaning up** rule: deleting a task also deletes any spec document
   its `spec:` line points at.
5. Add one line to `README.md` saying the protocol owns the plan and the status, and
   that superpowers skills are used inside the steps.
6. Verify: `AGENTS.md` names no superpowers path as a plan location;
   `grep -rn "superpowers" docs` shows mentions only in the new section, the
   cleanup rule and the README line; `docs/superpowers/` does not exist.
7. Unit tests: not applicable (documentation only).
