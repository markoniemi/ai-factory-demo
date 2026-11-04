# AI Task Factory

This directory holds the tasks processed by the automated AI developer engine. A
human writes down what should happen; the AI plans it, implements it and opens a
pull request; the human verifies the plan and merges.

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

The brackets hold the starting status and the priority. Then ask the AI to start
that task by name, or to take the next one. The AI creates the task file and turns
the brackets into a pointer to it, after which the task file owns the status.

## Pipeline

```
Tasks.md entry ──► draft ──► planning ──► planned ──► in_progress ──► in_review ──► approved ──► done
                                                                          │  ▲
                                                                          ▼  │
                                                                   changes_requested
```

A **human** moves `draft` → `planning`, verifies the plan at `planned`, and merges
at `approved`. The AI does the rest. See `AGENTS.md` for what it does in each step.
