# AI Task Factory

This directory holds the tasks processed by the automated AI developer engine. A
human writes down what should happen; the AI plans it and implements it on a
branch; the human verifies the plan, reads the diff and merges.

* `Tasks.md` — the backlog: one heading per task idea.
* `task-NNN-*.md` — one file per task, with its status and its implementation plan.
* `AGENTS.md` — the rules the AI follows. **The rules live there, not here.**

## Adding a task

Add a heading plus a short explanation to `Tasks.md`:

```markdown
### move Tasks to docs/tasks [draft, high]

Move the task directory from `Tasks/` to `docs/tasks/` so all documentation
lives under `docs/`.
```

The brackets hold the status and the priority. Then ask the AI to start that task by
name, or to take the next one. The AI creates the task file, links it under the
heading, and keeps the brackets up to date from then on:

```markdown
### move Tasks to docs/tasks [done, high]

plan: [task-002-move-tasks-to-docs.md](task-002-move-tasks-to-docs.md)

Move the task directory from `Tasks/` to `docs/tasks/` so all documentation
lives under `docs/`.
```

Edit the brackets yourself to re-prioritise a task or to ask for planning; the AI
reads the change back into the task file.

## Pipeline

```
Tasks.md entry ──► draft ──► planning ──► planned ──► in_progress ──► in_review ──► approved ──► done
                                                                          │  ▲
                                                                          ▼  │
                                                                   changes_requested
```

A **human** moves `draft` → `planning`, verifies the plan at `planned`, reviews the
branch diff at `in_review`, and merges at `approved`. The AI does the rest. See
`AGENTS.md` for what it does in each step.
