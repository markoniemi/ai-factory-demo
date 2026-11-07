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

### tasks branch name [draft, medium]

- git supports branches bug/feature/hotfix. how should tasks.md state what kind of branch is needed?
- also, branch is not always needed, how to tell ai not to use branch? when status is planned and there is no plan?

### package tasks as a github plugin [done, medium]

plan: [task-010-package-tasks-as-a-github-plugin.md](task-010-package-tasks-as-a-github-plugin.md)

- instead of having readme/agents in docs/tasks this should be either plugin or a skill, so it could be reused in other repositories.
- decided in [task-009-tasks-as-plugin-vs-skill.md](task-009-tasks-as-plugin-vs-skill.md): a plugin in its own github repository, carrying the protocol, next-task and clean-tasks as skills.
- namespaced skills, /task:next-task, /task:clean-tasks, /task:task [name-of-task]
- delete `docs/tasks/AGENTS.md` once the plugin exists, with no stub. a project keeps `Tasks.md`, its task files and `README.md`.

### feature vs task [planned, high]

plan: [feature-vs-task.md](feature-vs-task.md)

- how to create features and tasks from tasks.md? feature requires branch, possibly pr. task does not need plan and can be done directly on main.

### powerpoint presentation [draft, low]

- when tasks workflow and plugin/skill implementation, a powerpoint presentation would be nice

### task id/name [done, high]

plan: [task-011-task-id-name.md](task-011-task-id-name.md)

- the protocol states: "A task is a file `docs/tasks/task-NNN-<slug>.md"
- metadate states: id: task-001
- what if id was based on task heading, and human promises to make simple task headings
- should the be a check that heading task can be used as git branch name?

### use agents [done, high]

plan: [use-agents.md](use-agents.md)

- implementing tasks from tasks.md in same session is not perfect for token spending.
- is it possible to use agents or somehow clear session for each task automatically?

### plugin config [done, high]

plan: [plugin-config.md](plugin-config.md)

- add configuration to plugin
- user should be able to config task-plugin to fit project needs
- config items:
  - create branch: true/false
  - create pull-request: true/false

### task init [done, high]

plan: [task-init.md](task-init.md)

- create a /task:init that creates Tasks.md with header. 

### review instructions [done, medium]

plan: [review-instructions.md](review-instructions.md)

- when implementation is done, add a short instructions on how to demonstrate new feature in ui or how to review the changes.

### documentation [done, low]

plan: [documentation.md](documentation.md)

- when /task:clean-tasks is run, documentation should be checked that it is up-to-date.
- should task-plugin have documentation of it own? is readme enough?
- clean-tasks should check that readmes, agents.md, use cases and possible other documentation is up-to-date.

### github build [draft, low]

