---
id: task-004
status: in_review
priority: high
branch: task/004-reference-to-plan
pr_url: ""
---

# reference to plan

tasks.md now has [→ task-003-move-tasks-readme-to-agents.md] in task heading.
Reference to plan should be under header like plan: <link to file>. tasks.md heading
should contain state and priority, and ai should update it as necessary.

# Implementation Plan

## Shape of an entry

```markdown
### reference to plan [in_progress, high]

plan: [task-004-reference-to-plan.md](task-004-reference-to-plan.md)

<short explanation of what and why>
```

The brackets always hold `[<status>, <priority>]`, for the whole life of the task.
The `plan:` line appears when the task file is created and points at it.

## Who owns the status

The task file stays the source of truth; the brackets mirror it, and the mirror is
kept in sync in both directions:

* The AI changes a task's status → it updates the brackets in `Tasks.md` in the same
  commit.
* A human edits the brackets (to ask for planning, or to re-prioritise) → the AI
  copies the new value into the task file's frontmatter when it next picks the task
  up.

## Steps

1. Create branch `task/004-reference-to-plan` from `main`.
2. In `Tasks.md`, replace each `[→ task-NNN-....md]` pointer with
   `[<status>, <priority>]` read from the task file, and add a `plan:` line under the
   heading pointing at the task file.
3. In `AGENTS.md`, change the backlog rules: the brackets are never replaced; after
   creating the task file, add the `plan:` line; keep the brackets in step with the
   task file's status on every transition; read a human's bracket edit back into the
   frontmatter.
4. In `README.md`, show the entry format with the brackets and the `plan:` line, and
   say that the brackets stay and are kept up to date.
5. Verify: no `[→ ` pointer is left in `Tasks.md`, every entry with a `plan:` line
   has brackets matching its task file's frontmatter, and every linked file exists.
6. Unit tests: not applicable (documentation only).
