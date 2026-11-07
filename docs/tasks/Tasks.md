---
create_branch: false
create_pull_request: false
---

# Task Backlog

Inbox for new tasks. A human adds an entry; the AI turns it into a task file. See
`README.md` for how. The rules come from the `task` plugin, not from this
directory.

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


### feature vs task [planned, high]

plan: [feature-vs-task.md](feature-vs-task.md)

- how to create features and tasks from tasks.md? feature requires branch, possibly pr. task does not need plan and can be done directly on main.
- merged in from *tasks branch name*: how should tasks.md state what kind of branch is needed (bug/feature/hotfix), and how is the AI told not to use a branch at all?
- add task type to heading, ### feature: feature-name, or ### bug: bug-name, or ### task: task-name. Default to task. Branch name is taken from task type.

### powerpoint presentation [draft, low]

- when tasks workflow and plugin/skill implementation, a powerpoint presentation would be nice

### github build [draft, low]

### task plugin vs https://backlog.so/ [done, high]

plan: [task-plugin-vs-https-backlog-so.md](task-plugin-vs-https-backlog-so.md)

- how does backlog.so work? is it free?
- does it overlap with task-plugin?
- should i rename task-plugin to backlog-plugin? then naming backlog items as task and feature and epic would be no problem.
