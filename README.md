# ai-world

A portable collection of skills, agents, and reusable building blocks for
working with AI coding tools. Anything here is meant to be tool-agnostic
enough to move between projects, and between different AI tools (Claude
Code, other agent frameworks, etc.) with little or no adaptation.

## Structure

```
skills/
└── <skill-name>/
    └── <skill-name>.md   # the skill's instructions/prompt
```

Each skill lives in its own folder so it can grow (examples, templates,
per-tool notes) without cluttering the top level.

## Skills

| Skill | Description | Origin / compatible tools |
|-------|-------------|----------------------------|
| [session0](skills/session0/session0.md) | Runs a "Session 0" — a structured project-inception conversation (problem, users, vision, scope, glossary, phases) before any code is written. Produces a `SESSION0.md` document. | Written as a Claude Code slash command (`/session0`), but the instructions are plain prose and portable to any LLM-based agent as a system/instruction prompt. |

## Using a skill in Claude Code

Copy the skill's `.md` file into `~/.claude/commands/<name>.md` (or
`~/.claude/skills/`, depending on the skill format) to make it available as
a slash command in any project.

## Adding a new skill

1. Create `skills/<name>/`.
2. Add the skill file(s), keeping the origin tool's format as-is.
3. Add a row to the table above, noting what it does and which tools it's
   known to work with.
