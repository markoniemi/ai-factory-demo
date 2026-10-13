# AI Task Protocol

This directory contains tasks processed by the automated AI developer engine.

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

1. Scan all `.md` files in `tasks/`.
2. Filter tasks by target `status`.
3. Process tasks strictly by `priority`: `high` $\rightarrow$ `medium` $\rightarrow$ `low`.
   *(If priorities match, process the oldest file first).*

---

## Execution Pipeline

```
draft ──► planning ──► planned ──► in_progress ──► in_review ──► approved ──► done
                                                       │  ▲
                                                       ▼  │
                                                changes_requested
```

1. **`draft` → `planning`**
* **Human** flags the task to be planned by setting status to `planning`.

2. **`planning` → `planned`**
* AI generates the `# Implementation Plan` section at the bottom of the task file.
* When the plan is complete, AI sets status to `planned`.
* The task then waits for a **human** to verify the plan.

3. **`planned` → `in_progress`**
* Nightly runner picks the highest-priority `planned` task.
* Sets status to `in_progress` on main branch and pushes.
* Creates branch from frontmatter `branch` (e.g. `task/001-...`).
* Writes the code **and unit tests**, then pushes the branch.

4. **`in_progress` → `in_review`**
* AI opens a Pull Request, links `pr_url`, and sets status to `in_review`.
* A secondary review agent is assigned to run the CI check / Sonar analysis.

5. **`in_review` → `approved`**
* Secondary agent validates that CI tests pass and code quality meets standards.
* On success, sets status to `approved`.
* On failure (failing tests or Sonar findings), sets status to `changes_requested`.

6. **`changes_requested` → `in_review`**
* AI fixes the CI/CD test failures or Sonar findings on the PR branch.
* Pushes and sets status back to `in_review`.

7. **`approved` → `done`**
* **Human** approves the PR or merges it in the Git UI.
* AI cleans up the branch and updates status to `done`.
