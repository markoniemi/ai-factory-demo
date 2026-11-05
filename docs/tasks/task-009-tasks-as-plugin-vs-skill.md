---
id: task-009
status: in_review
priority: medium
branch: task/009-tasks-as-plugin-vs-skill
---

# tasks as plugin vs skill

- Does plugin support commands like /next-task /clean-tasks if tasks is a plugin?
- can skill be reused, or is it necessary to create and publish a plugin?

# Implementation Plan

## The two questions, answered

From the [plugins overview](https://code.claude.com/docs/en/plugins):

**Does a plugin give slash commands?** Yes. A plugin's skill "runs as
`/my-plugin:review`" — so a `tasks` plugin holding `next-task` and `clean-tasks`
skills gives `/tasks:next-task` and `/tasks:clean-tasks`. The names are namespaced
by the plugin; you do not get a bare `/next-task` from a plugin.

**Is a plugin necessary for reuse?** No. "Skills, subagents, hooks, and MCP servers
all work on their own, without a plugin. A skill you save in `~/.claude/skills/`
[…] is available in every project on your machine." A bare `~/.claude/skills/tasks/`
is invocable as `/tasks`, and a custom command file in `~/.claude/commands/` gives a
bare `/next-task`. Nothing has to be published.

A plugin is for when you want "several skills, subagents, hooks, or MCP servers
packaged as one unit […] to give your own setup to teammates, install it in many
projects, or publish versioned releases." Publishing is not a separate step: a
marketplace is just a repository with `.claude-plugin/marketplace.json`, and during
development `--plugin-dir` loads a plugin straight from a folder.

So neither answer forces the other: reuse is free with a skill, and the only thing
a plugin adds is packaging, versioning, distribution, and namespaced commands.

## Recommendation

Build it as a **plugin directory from the start**, and use it locally. The files are
the same either way, so this costs nothing now and avoids a rewrite later:

```
tasks-plugin/
  .claude-plugin/plugin.json      name: tasks, version
  skills/next-task/SKILL.md       pick and start the next backlog task
  skills/clean-tasks/SKILL.md     the Cleaning up rule
  skills/tasks/SKILL.md           the protocol itself (today's AGENTS.md)
```

Reasons it wins over a bare skill here:

* The backlog already asks for several components — `next-task`, `clean-tasks`, and
  the protocol — which is the case the docs name for a plugin.
* `tasks branch name` and `lightweight task` will likely want a hook that checks a
  `Tasks.md` entry or a branch name. Hooks are a plugin component; bolting them onto
  a loose skill means settings edits on every machine.
* This machine already installs a personal plugin from a GitHub repository
  (`caveman` via `extraKnownMarketplaces`), so the distribution path is proven and
  costs one `marketplace.json`.

What it costs: an enabled plugin is in every session, and each invocable skill's
name and description sit in context every turn. Three small skills is a few hundred
tokens — the same bill `docs/tasks/AGENTS.md` avoids today only because nothing
loads it automatically.

That last point is the real gain, and worth stating plainly: `docs/tasks/AGENTS.md`
is only read when someone thinks to read it. A skill with a good description is
offered to the agent by name on every turn, so "next task" finds the rules instead
of relying on the agent having read the repository.

## Relationship to the other entry

`tasks as skill` asks the same question from the other side. This task decides
**which packaging**; that one is the **implementation** once the decision is made.
It should be re-worded to "package tasks as a plugin" and kept, not deleted.

## Decision (from human, 2026-11-05)

**A plugin**, published as its own GitHub repository, so it can be installed into a
work project.

This settles it, because a bare skill has no install path from GitHub: you would
clone the repository and copy files into `~/.claude/skills/` on every machine, with
no version and no update command. A plugin repository that also carries
`.claude-plugin/marketplace.json` is installed once per machine and updates from its
marketplace:

```
/plugin marketplace add <owner>/<repo>
/plugin install tasks@<repo>        # user scope: every project on that machine
```

That is the same mechanism this machine already uses for the `caveman` plugin
through `extraKnownMarketplaces`.

A plugin is also how skills are published in the first place: the unit a marketplace
lists is a plugin, and a plugin whose only components are skills is a normal and
expected shape.

### Caveat for the work project

A repository of your own is a **third-party** marketplace. An employer can restrict
or block those through managed settings (`strictKnownMarketplaces`,
`allowedMarketplaces`, `blockedMarketplaces`) or stop plugin installs entirely.
Check that policy before depending on it at work. If marketplaces are blocked,
`--plugin-dir` against a local clone still loads the plugin, at the cost of manual
updates.

### What this means for a project using the plugin

- **`docs/tasks/AGENTS.md` is deleted once the plugin exists**, with no stub left
  behind. The rules live in the plugin's `tasks` skill; a project keeps only
  `Tasks.md`, its task files, and `README.md` for the humans.
- **Namespaced commands are accepted**: `/tasks:next-task` and
  `/tasks:clean-tasks`. The plugin needs no command files, only skills.

Both are the implementation task's work, not this one's.

## Steps

1. ~~Record the decision in this file once the questions above are answered.~~ Done.
2. ~~Re-word the `tasks as skill` entry to name the chosen packaging, so the two
   entries stop describing the same work.~~ Done: it now reads
   *package tasks as a github plugin*.
3. Hand the implementation to that entry: this task is a decision record and
   changes no rules on its own.
4. Unit tests: not applicable (decision only).
