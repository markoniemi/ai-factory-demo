---
id: task-006
status: in_review
priority: high
branch: task/006-powershell-setting
---

# powershell setting

- is there a claude setting that tells that we are in windows, and powershell should be used? to prevent misses with commands.

# Implementation Plan

## Answer

There is no setting that announces the platform: Claude Code already puts the
platform (`win32`) and the shell (PowerShell) into the session context. The misses
come from *tool choice* — the agent reaches for the Bash tool (Git Bash) and writes
bash-isms (`python`, `sed`, `&&`, heredocs) that behave differently or not at all.

`defaultShell: "powershell"` is not the fix either: it only changes what the input
box runs for `!` commands, not which tool the agent picks.

## Decision (from human, 2026-11-04)

Hard-deny the Bash tool in project settings, so nothing bash-shaped can slip
through:

```json
{
  "env": {
    "CLAUDE_CODE_USE_POWERSHELL_TOOL": "1"
  },
  "defaultShell": "powershell",
  "permissions": {
    "deny": ["Bash"]
  }
}
```

Cost accepted: PowerShell 5.1 has no `&&` / `||` (use `;` and `if ($?) { ... }`),
and heredocs become here-strings.

## Why the `env` block is required

The [tools reference](https://code.claude.com/docs/en/tools) warns that a Bash deny
rule also turns the PowerShell tool off, without a warning, and that *"a rule that
removes the whole Bash tool leaves Claude with no shell tool for the session"*.
`CLAUDE_CODE_USE_POWERSHELL_TOOL=1` is the documented way to keep PowerShell on
alongside the deny rule. `defaultShell: "powershell"` also requires the PowerShell
tool to be enabled, so without the `env` block it would do nothing either.

On Windows with Git Bash the tool is already on by default for claude.ai and Console
accounts; the `env` block makes it explicit, and keeps it on for Bedrock, Vertex and
Foundry sessions, where it is off unless set.

## Steps

1. Create branch `task/006-powershell-setting` from `main`.
2. Write `.claude/settings.json` with `defaultShell: "powershell"` and
   `permissions.deny: ["Bash"]`. Commit it — this is a team-wide project setting,
   not a personal override, so it does not belong in `settings.local.json`.
3. Add a short **Shell** section to `docs/tasks/AGENTS.md`: Windows, use the
   PowerShell tool, no `&&`, no `python` on PATH, here-strings instead of heredocs.
4. Verify: the settings file parses, and a Bash call is refused.
5. Unit tests: not applicable (configuration only).
