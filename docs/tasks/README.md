# AI Task Protocol

This directory contains tasks processed by the automated AI developer engine.

---

## Task Backlog (`Tasks.md`)

`docs/tasks/Tasks.md` is the inbox for new tasks.

1. A **human** adds an entry as a heading plus a short explanation:

```markdown
### move Tasks to docs/tasks [draft, high]

<short explanation of what and why>
```

2. The human then asks the AI either for a **named** task
   (e.g. "start the *move Tasks to docs/tasks* task") or for the **next** task.
   *Next* = highest `priority` first, and among equal priorities the entry that
   appears first in `Tasks.md`, skipping entries that already point to a file.

3. The AI creates the task file from that entry:
   * `id` = next free number from the existing `task-NNN-*.md` files.
   * File name `task-NNN-<slug-of-title>.md`, `branch: task/NNN-<slug>`.
   * `status` and `priority` are taken from the brackets, `pr_url` is empty.
   * The explanation is copied into the body as the task description; the AI does
     **not** write the implementation plan yet (that is the `planning` step).

4. The AI replaces the brackets in `Tasks.md` with a pointer to the new file:
   `### move Tasks to docs/tasks [→ task-002-move-tasks-to-docs.md]`.
   From then on the task file is the only source of truth for status and priority.

---

## Task Frontmatter Schema

Each `.md` task file MUST include this YAML frontmatter:

```yaml
---
id: task-001
status: draft | planning | planned | in_progress | in_review | changes_requested | approved | done
priority: high | medium | low
branch: task/001-short-description
pr_url: ""
---

```

---

## Priority & Selection Rules

1. Scan all `task-*.md` files in `docs/tasks/` (`README.md` and `Tasks.md` are not task files).
2. Filter tasks by target `status`.
3. Process tasks strictly by `priority`: `high` $\rightarrow$ `medium` $\rightarrow$ `low`.
   *(If priorities match, process the oldest file first).*

---

## Execution Pipeline

```
Tasks.md entry ──► draft ──► planning ──► planned ──► in_progress ──► in_review ──► approved ──► done
                                                                          │  ▲
                                                                          ▼  │
                                                                   changes_requested
```

1. **`Tasks.md` entry → `draft`**
* **Human** asks the AI to start a named task, or the next task, from `Tasks.md`.
* AI creates the task file and points the backlog entry at it (see **Task Backlog** above).

2. **`draft` → `planning`**
* **Human** flags the task to be planned by setting status to `planning`.

3. **`planning` → `planned`**
* AI generates the `# Implementation Plan` section at the bottom of the task file.
* When the plan is complete, AI sets status to `planned`.
* The task then waits for a **human** to verify the plan.

4. **`planned` → `in_progress`**
* Nightly runner picks the highest-priority `planned` task.
* Sets status to `in_progress` on main branch and pushes.
* Creates branch from frontmatter `branch` (e.g. `task/001-...`).
* Writes the code **and unit tests**, then pushes the branch.

5. **`in_progress` → `in_review`**
* AI opens a Pull Request, links `pr_url`, and sets status to `in_review`.
* A secondary review agent is assigned to run the CI check / Sonar analysis.

6. **`in_review` → `approved`**
* Secondary agent validates that CI tests pass and code quality meets standards.
* On success, sets status to `approved`.
* On failure (failing tests or Sonar findings), sets status to `changes_requested`.

7. **`changes_requested` → `in_review`**
* AI fixes the CI/CD test failures or Sonar findings on the PR branch.
* Pushes and sets status back to `in_review`.

8. **`approved` → `done`**
* **Human** approves the PR or merges it in the Git UI.
* AI cleans up the branch and updates status to `done`.
