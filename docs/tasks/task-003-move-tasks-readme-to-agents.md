---
id: task-003
status: in_progress
priority: medium
branch: task/003-move-tasks-readme-to-agents
pr_url: ""
---

# move tasks readme to agents

- should task readme be a separated readme for humans and agents.md for ai?

# Implementation Plan

## Recommendation

Yes, split it. The two audiences need different things:

* The **AI** reads the protocol on every run, so it must be short, imperative and
  unambiguous. Every word costs context.
* The **human** needs orientation: what this directory is, how to add a task, who
  does what. That text is noise for the AI.

Proposed layout:

| File | Audience | Contains |
|------|----------|----------|
| `AGENTS.md` (repo root) | AI | The protocol: frontmatter schema, selection rules, the state transitions and what the AI must do in each one. |
| `docs/tasks/README.md` | human | Short orientation: purpose of `docs/tasks/`, how to add a backlog entry, the pipeline diagram, link to `AGENTS.md`. |

`AGENTS.md` goes in the repo root because that is the conventional path agents load
automatically (Claude Code, Codex and others). It stays the single source of truth
for the rules; the README never repeats a rule, it links to it.

## Open questions (for human to verify)

- **Root `AGENTS.md` vs `docs/tasks/AGENTS.md`:** the plan assumes the repo root, so
  agents pick it up without being told. Confirm.
- **`CLAUDE.md`:** the repo has none. The plan assumes no `CLAUDE.md` is added and
  that `AGENTS.md` is the only instruction file. Confirm.
- **Duplication rule:** the plan assumes the README keeps the pipeline diagram
  (useful for a human, cheap to keep in sync). Say so if even that should live only
  in `AGENTS.md`.

## Steps

1. Create branch `task/003-move-tasks-readme-to-agents` from `main`.
2. Create `AGENTS.md` in the repo root, written for the AI, with these sections and
   nothing else:
   1. **Task files** — tasks live in `docs/tasks/` as `task-NNN-<slug>.md`;
      `README.md` and `Tasks.md` are not task files. The frontmatter schema
      (`id`, `status`, `priority`, `branch`, `pr_url`) copied from the current README.
   2. **Selection** — filter by target status, then `high` → `medium` → `low`, oldest
      file first on a tie.
   3. **Backlog** — how to turn a `Tasks.md` entry into a task file: id numbering,
      file name, slug, branch name, status and priority from the brackets, copy the
      explanation as the body, do not plan yet, then replace the brackets with the
      pointer `[→ task-NNN-<slug>.md]`.
   4. **Transitions** — one short block per transition, each saying who acts (human
      or AI) and what the AI writes. Keep the wording of the current README's
      numbered list, trimmed to imperatives.
3. Rewrite `docs/tasks/README.md` as the human-facing file: one paragraph on what the
   directory is, the entry format for `Tasks.md` with the example heading, the
   pipeline diagram, and a line pointing to `AGENTS.md` for the rules. Remove the
   frontmatter schema, the selection rules and the per-transition detail, which now
   live only in `AGENTS.md`.
4. Update references to the moved content: any link to `docs/tasks/README.md` that
   meant the protocol now points at `AGENTS.md` (check `docs/tasks/Tasks.md`,
   `docs/tasks/task-001-ai-blog-post.md`, `.gitlab-ci.yml`).
5. Verify: `grep -rn "Task Frontmatter\|Priority & Selection" docs AGENTS.md` shows
   each rule in exactly one file, and no link points at a heading that moved.
6. Unit tests: not applicable (documentation only).
7. Commit, push the branch, open a PR, set `pr_url`, set status to `in_review`.
