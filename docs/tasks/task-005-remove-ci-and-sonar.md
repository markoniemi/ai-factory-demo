---
id: task-005
status: done
priority: low
branch: task/005-remove-ci-and-sonar
---

# remove ci and sonar

- readme states ci and sonar. in this case there is no ci, and review is done by human.

# Implementation Plan

## Decisions (from human, 2026-11-04)

- **No pull requests in this project.** The AI works on the task branch and the
  human reads the branch diff.
- **`in_progress` → `in_review` happens when the implementation is ready**, not when
  a PR is opened.
- There is no CI and no Sonar, and no secondary review agent: the human reviews.

## Steps

1. Create branch `task/005-remove-ci-and-sonar` from `main`.
2. In `AGENTS.md`:
   * Drop `pr_url` from the frontmatter schema.
   * `in_progress` → `in_review`: set `in_review` once the implementation is
     committed on the branch. No pull request, no `pr_url`.
   * `in_review` → `approved` / `changes_requested`: the **human** reads the branch
     diff. Remove the review agent, the CI check and the Sonar analysis.
   * `approved` → `done`: merge the branch into `main`, delete the branch, set
     `done`.
3. Remove `pr_url` from the frontmatter of the existing task files.
4. In `README.md`, drop the pull request from the opening paragraph and say that the
   human reviews the branch diff.
5. In `Tasks.md`, reword the `in_review` and `approved` status lines so they do not
   mention a pull request.
6. Verify: `grep -rin "pull request\|pr_url\|sonar\|\bci\b" docs` returns nothing
   outside task descriptions and plans.
7. Unit tests: not applicable (documentation only).
