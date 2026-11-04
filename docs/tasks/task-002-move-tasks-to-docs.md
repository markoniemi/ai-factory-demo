---
id: task-002
status: done
priority: high
branch: task/002-move-tasks-to-docs
---

# move Tasks to docs/tasks

Move the task directory from `Tasks/` to `docs/tasks/` so all documentation lives
under `docs/`. Update every reference to the old path (`Tasks/README.md`,
`Tasks/Tasks.md`, `.gitlab-ci.yml`, any runner scripts) and keep the git history of
the moved files by using `git mv`.
