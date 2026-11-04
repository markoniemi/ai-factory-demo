# Task Backlog

Inbox for new tasks. A **human** adds an entry here; the AI turns an entry into a
task file in `docs/tasks/` on request. See `docs/tasks/README.md` for the full protocol.

## Entry format

```markdown
### <short title> [<status>, <priority>]

<short explanation: what and why, a few sentences or bullets>
```

* `status` — usually `draft` (see the status list in `docs/tasks/README.md`).
* `priority` — `high` | `medium` | `low`.
* Once the AI has created the task file, the brackets are replaced by a pointer:
  `### <short title> [→ task-002-short-title.md]`. After that the task file is the
  only place where status and priority live; this file is not updated again.

---

## Backlog

### move Tasks to docs/tasks [→ task-002-move-tasks-to-docs.md]

Move the task directory from `Tasks/` to `docs/tasks/` so all documentation lives
under `docs/`. Update every reference to the old path (`Tasks/README.md`,
`Tasks/Tasks.md`, `.gitlab-ci.yml`, any runner scripts) and keep the git history of
the moved files by using `git mv`.
