---
id: github-build
status: done
priority: low
kind: task
---

# github build

The backlog entry carried no explanation - the heading was all there was - and a
human set it to `planned`, which waives the plan. So the description is the
heading, and what follows is the reading it was implemented under. Say so if it is
the wrong one; the work is one file.

The backlog entry gained a description after this file was created, once the work
was already written: *"does it make sense to have github build? Can tests run in
github, there are no api tokens if tests require ai."* It is recorded here because
the mirror carries `status`, `priority` and `kind`, not the description. Both
questions are answered by what was built: the tests do run on a runner, and they
need no API token, because nothing in the suite calls a model - the one case that
wants the `claude` CLI skips itself when the CLI is absent.

## What this was taken to mean

A GitHub Actions workflow that runs this repository's own unit tests on every push
and pull request. The tests are Windows PowerShell, so the runner is Windows.

Deliberately **not** included, because each needs a decision no description asked
for:

* `claude plugin validate . --strict`. The suite already skips that case when the
  `claude` CLI is absent, and installing and authenticating the CLI on a runner is
  its own task.
* A release job - tagging, or bumping `version` in `.claude-plugin/plugin.json`.
* A second job on `pwsh` 7. The protocol and the suite target Windows PowerShell
  5.1 on purpose; adding 7 would be a portability decision, not a build.

## Result

`.github/workflows/build.yml`, commit `695685a`. One job, `windows-latest`,
`actions/checkout@v4`, then the command the README documents, run through `shell:
cmd` so the interpreter is Windows PowerShell 5.1 rather than the runner's default
`pwsh` 7. The script exits non-zero on any failure, which fails the step.

Four tests, 55 -> 59. One of them first forbade the string `claude` anywhere in the
workflow and was tripped by its own explanatory comment; it now drops comment lines
and asserts that no *step* invokes the CLI, which is the rule it meant.

`README.md` gained a paragraph under `## Tests`.

## How to review

1. Read `.github/workflows/build.yml`. It is 24 lines, and the comment in it is
   the argument for `shell: cmd` over the default shell.
2. `powershell -NoProfile -ExecutionPolicy Bypass -File tests/Test-Plugin.ps1` -
   the exact line the workflow runs. Expect `passed 59, failed 0, skipped 0` and
   exit code 0. On a runner it is `skipped 1`, because `claude` is absent there and
   that case skips itself.
3. `git show 695685a -- tests/Test-Plugin.ps1` for the four new cases, the last of
   which is the one that needed loosening.
4. **The workflow has never run.** Nothing was pushed, so GitHub has not parsed
   this YAML or executed the job; `windows-latest` having `powershell.exe` on
   `PATH` and `git` available are assumptions, not observations. The first push is
   the real test, and a failure there is a `changes_requested`, not a surprise.