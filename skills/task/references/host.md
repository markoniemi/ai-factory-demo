# The host, when requests are on

Read this when `create_pull_request` is on and a transition in
`skills/task/SKILL.md` sends you here. With requests off, nothing in this file
applies.

Read the host from `git remote get-url origin`. A `github.com` remote uses `gh`,
a GitLab remote uses `glab`; GitLab calls the request a merge request.

| Host | Open the request | Check it is merged |
| :- | :- | :- |
| GitHub | `gh pr create --fill --base main --head <branch>` | `gh pr view <branch> --json state,mergedAt` |
| GitLab | `glab mr create --fill --target-branch main --source-branch <branch>` | `glab mr view <branch> --output json` |

The tool missing, or not authenticated: report it and stay where you are. Never
fall back to a local merge to get around it.