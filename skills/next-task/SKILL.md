---
name: next-task
description: Use when asked to take, start or plan the next task from the backlog rather than a named one - "next task", "take the next one", "what should I work on". Picks the highest-priority open entry in docs/tasks/Tasks.md, creates its task file, and runs it through the task protocol.
---

# Next task

Read the protocol first: `${CLAUDE_PLUGIN_ROOT}/skills/task/SKILL.md`. It holds the
task file shape, the statuses, the backlog mirror and the transitions. This skill
only decides **which** task is next.

## Which task is next

1. Read `docs/tasks/Tasks.md`.
2. Skip every entry that already has a `plan:` line — that task exists as a file
   already, and belongs to the `task` skill, not to this one.
3. Among the rest, take `high` before `medium` before `low`. Among equal
   priorities, the entry that appears first in `Tasks.md`.
4. Nothing left → say so, and list the entries that already have task files with
   their statuses, so the human can pick one up instead.

## Then

1. Create the task file as **Creating a task** in the protocol describes: the slug
   of the entry's heading as both the file name and the `id`, `branch: task/<slug>`,
   `status` and `priority` from the entry's brackets, the entry's explanation as the
   body, and a `plan:` link added under the entry's heading. A heading that makes no
   usable slug is the human's to fix, so stop and ask.
2. Run the transition the entry's status calls for, and stop at the first step that
   is a human's — `draft` stays `draft` until a human asks for planning, and a plan
   you wrote waits at `planned` for a human to verify it.
3. Report what you created, what you did, and what the human has to do next.
