# .agents

Source of truth for this repo's agent rules, skill and docs:

- `rules/` — rules that apply to every task, linked from `AGENTS.md`
- `skills/coa-development/` — the repository's development skill; `SKILL.md` routes to `references/`
- `docs/` — task-scoped agent docs; taxonomy and placement policy in `docs/README.md`
- `plans/` — per-task plans, specs and investigation notes, gitignored

Agent-specific files point here instead of restating it, so there is one copy to keep current.

## Required plugin

Development uses the [superpowers](https://github.com/obra/superpowers) process skills (brainstorming for
features, systematic debugging for issue fixing, verification before completion). `rules/workflow.md` says which
one applies and where this repository's rules override it.

## Hooking up your agent

- **Claude Code** — reads `CLAUDE.md`, which imports `AGENTS.md`; `AGENTS.md` imports `rules/*.md` with
  `@` references. Claude Code does not discover `.agents/skills/`, so `.claude/skills/coa-development/SKILL.md` is
  a real (not symlinked) stub that loads this skill. The checked-in `.claude/settings.json` enables superpowers
  from the official marketplace; after trusting the folder, install it once with
  `claude plugin install superpowers@claude-plugins-official --scope project`.
- **Codex** — reads `AGENTS.md` and discovers `.agents/skills/` natively. Install superpowers for Codex as its
  README describes.
- **GitHub Copilot** — reads `AGENTS.md` natively. Code review also reads
  `.github/copilot-instructions.md`; custom agent profiles live in `.github/agents/`.
- **Any other agent** — point it at `AGENTS.md` through its own entry file (`GEMINI.md`, `.cursorrules`, …) and
  have it read `.agents/rules/` before starting.

To add a rule file: create it in `rules/` and link it from the Rules section of `AGENTS.md` with an `@` reference.
Prefer extending the existing skill's `references/` over adding another skill; a new skill also needs a stub in
`.claude/skills/<name>/SKILL.md` with the same name and description.

The issue-batch scheduling, git safety and guide tooling parts of the skill are adapted from lostmind84's
[coa-server-guide](https://github.com/lostmind84/coa-server-guide).
