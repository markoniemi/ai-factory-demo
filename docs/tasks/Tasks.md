# Task Backlog

Inbox for new tasks. A human adds an entry; the AI turns it into a task file. See
`README.md` for how, and `AGENTS.md` for the rules.

Entry format — `### <short title> [<status>, <priority>]` plus a short explanation.
Once the AI has created the task file, it adds a `plan: <link>` line under the
heading and keeps the brackets up to date as the status changes. An entry is removed
when its task is cleaned, so this file shows open work only.

Statuses:

* `draft` — written down, not planned yet.
* `planning` — a human asked the AI to plan it.
* `planned` — plan written, waiting for a human to verify it.
* `in_progress` — the AI is implementing it on its branch.
* `in_review` — implementation ready on the branch, waiting for review.
* `changes_requested` — review asked for changes.
* `approved` — review passed, ready to merge.
* `done` — merged and branch deleted.

Priorities: `high` | `medium` | `low`.

---

## Backlog

### reference to plan [done, high]

plan: [task-004-reference-to-plan.md](task-004-reference-to-plan.md)

tasks.md now has [→ task-003-move-tasks-readme-to-agents.md] in task heading. Reference to plan should be under header like plan: <link to file>. tasks.md heading should contain state and priority, and ai should update it as necessary.

### remove ci and sonar [done, low]

plan: [task-005-remove-ci-and-sonar.md](task-005-remove-ci-and-sonar.md)

- readme states ci and sonar. in this case there is no ci, and review is done by human.

### powershell setting [done, high]

plan: [task-006-powershell-setting.md](task-006-powershell-setting.md)

- is there a claude setting that tells that we are in windows, and powershell should be used? to prevent misses with commands.

### clean tasks [in_progress, high]

plan: [task-007-clean-tasks.md](task-007-clean-tasks.md)

- this should be part of tasks workflow
- implemented plans are no longer needed
- corresponding headings/chapters in tasks.md can be removed
- update documentation and usecases before deleting

### tasks branch name [draft, medium]

- git supports branches bug/feature/hotfix. how should tasks.md state what kind of branch is needed?
- also, branch is not always needed, how to tell ai not to use branch? when status is planned and there is no plan?

### tasks as skill [draft, medium]

- instead of having readme/agents in docs/tasks this should be either plugin or a skill, so it could be reused in other repositories.

### tasks as plugin vs skill [draft, medium]

- Does plugin support commands like /next-task /clean-tasks if tasks is a plugin?
- can skill be reused, or is it necessary to create and publish a plugin?

### superpowers compatibility [draft, medium]

- using superpowers plugin, which likes to write plans in some place, should tasks be compatible with superpowers plugin?

### lightweight task [planning, high]

is there a way to state task as lightweight, which does not need plan or branch, can be committed to main.


