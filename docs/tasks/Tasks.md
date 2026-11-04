# Task Backlog

Inbox for new tasks. A human adds an entry; the AI turns it into a task file. See
`README.md` for how, and `AGENTS.md` for the rules.

Entry format — `### <short title> [<status>, <priority>]` plus a short explanation.
Once the AI has created the task file, it adds a `plan: <link>` line under the
heading and keeps the brackets up to date as the status changes.

Statuses:

* `draft` — written down, not planned yet.
* `planning` — a human asked the AI to plan it.
* `planned` — plan written, waiting for a human to verify it.
* `in_progress` — the AI is implementing it on its branch.
* `in_review` — pull request open, under review.
* `changes_requested` — review found failures or findings to fix.
* `approved` — review passed, waiting for a human to merge.
* `done` — merged and branch deleted.

Priorities: `high` | `medium` | `low`.

---

## Backlog

### move Tasks to docs/tasks [done, high]

plan: [task-002-move-tasks-to-docs.md](task-002-move-tasks-to-docs.md)

Move the task directory from `Tasks/` to `docs/tasks/` so all documentation lives
under `docs/`. Update every reference to the old path (`Tasks/README.md`,
`Tasks/Tasks.md`, `.gitlab-ci.yml`, any runner scripts) and keep the git history of
the moved files by using `git mv`.

### move tasks readme to agents [done, medium]

plan: [task-003-move-tasks-readme-to-agents.md](task-003-move-tasks-readme-to-agents.md)

- should task readme be a separated readme for humans and agents.md for ai?

### reference to plan [in_review, high]

plan: [task-004-reference-to-plan.md](task-004-reference-to-plan.md)

tasks.md now has [→ task-003-move-tasks-readme-to-agents.md] in task heading. Reference to plan should be under header like plan: <link to file>. tasks.md heading should contain state and priority, and ai should update it as necessary.

### remove ci and sonar [draft, low]

- readme states ci and sonar. in this case there is no ci, and review is done by human.

### tasks branch name [draft, low]

- git supports branches bug/feature/hotfix. how should tasks.md state what kind of branch is needed?
- also, branch is not always needed, how to tell ai not to use branch? when status is planned and there is no plan?

### tasks as skill [draft, high]

- instead of having readme/agents in docs/tasks 

### superpowers compatibility [draft, high]

- using superpowers plugin, which likes to write plans in some place, should tasks be compatible with superpowers plugin?

### tasks as plugin vs skill

- Does plugin support commands like /next-task /clean-tasks if tasks is a plugin?

