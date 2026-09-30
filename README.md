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

agents/
└── <agent-name>/
    └── <agent-name>.md   # the agent's frontmatter + system prompt

hooks/                    # hook scripts the agents reference
statusline/               # status line that feeds the usage guard
```

Each skill or agent lives in its own folder so it can grow (examples,
templates, per-tool notes) without cluttering the top level.

## Skills

### General

| Skill | Description | Origin / compatible tools |
|-------|-------------|----------------------------|
| [session0](skills/session0/session0.md) | Runs a "Session 0" — a structured project-inception conversation (problem, users, vision, scope, glossary, phases) before any code is written. Produces a `SESSION0.md` document. | Written as a Claude Code slash command (`/session0`), but the instructions are plain prose and portable to any LLM-based agent as a system/instruction prompt. |

### Design patterns (Gang of Four)

Each of these guides an agent to recognize when the pattern genuinely applies
(and when it's over-engineering), implement it correctly, self-verify with a
checklist, and flag honest trade-offs to the user. All are language-agnostic
and usable as a Claude Code slash command (`/<pattern-name>`) or as a
system/instruction prompt for any LLM-based agent. Based on the catalog at
[refactoring.guru/design-patterns](https://refactoring.guru/design-patterns/catalog).

**Creational**

| Skill | Description |
|-------|-------------|
| [factory-method](skills/factory-method/factory-method.md) | Defers instantiation of a product to a factory method that subclasses override, avoiding scattered `new`/type-switch logic. |
| [abstract-factory](skills/abstract-factory/abstract-factory.md) | Produces families of related products (composing multiple Factory Methods) while guaranteeing the family stays internally consistent. |
| [builder](skills/builder/builder.md) | Constructs complex objects step by step, replacing telescoping constructors with a fluent/director-driven assembly process. |
| [prototype](skills/prototype/prototype.md) | Creates new objects by cloning a pre-configured instance instead of re-running construction logic, respecting encapsulation. |
| [singleton](skills/singleton/singleton.md) | Ensures a class has exactly one instance behind a controlled access point — with explicit guidance on the global-state/testability trade-off. |

**Structural**

| Skill | Description |
|-------|-------------|
| [adapter](skills/adapter/adapter.md) | Wraps an incompatible interface so it matches what client code expects, without modifying either side. |
| [bridge](skills/bridge/bridge.md) | Splits a class hierarchy into abstraction and implementation so both can vary and be extended independently. |
| [composite](skills/composite/composite.md) | Composes objects into tree structures and lets client code treat individual objects and compositions uniformly. |
| [decorator](skills/decorator/decorator.md) | Attaches new responsibilities to an object dynamically by wrapping it, as a stackable alternative to subclassing. |
| [facade](skills/facade/facade.md) | Provides a simplified, unified interface to a complex subsystem for the common use cases. |
| [flyweight](skills/flyweight/flyweight.md) | Shares fine-grained objects efficiently by splitting intrinsic (shared) state from extrinsic (per-context) state. |
| [proxy](skills/proxy/proxy.md) | Controls access to an object (lazy loading, caching, access control, logging) behind an interface identical to the real subject. |

**Behavioral**

| Skill | Description |
|-------|-------------|
| [chain-of-responsibility](skills/chain-of-responsibility/chain-of-responsibility.md) | Passes a request along a chain of handlers until one of them handles it, decoupling sender from receiver. |
| [command](skills/command/command.md) | Encapsulates a request as an object, enabling queuing, logging, and undo/redo of the underlying action. |
| [iterator](skills/iterator/iterator.md) | Provides sequential access to a collection's elements without exposing its underlying representation. |
| [mediator](skills/mediator/mediator.md) | Centralizes complex communication between objects so they no longer reference each other directly. |
| [memento](skills/memento/memento.md) | Captures and restores an object's internal state (for undo) without violating its encapsulation. |
| [observer](skills/observer/observer.md) | Defines a one-to-many subscription so dependents are notified automatically when a subject changes. |
| [state](skills/state/state.md) | Lets an object alter its behavior when its internal state changes, with each state's transitions encapsulated in its own class. |
| [strategy](skills/strategy/strategy.md) | Extracts interchangeable algorithms into their own classes so they can be swapped independently of the client that uses them. |
| [template-method](skills/template-method/template-method.md) | Defines an algorithm's skeleton in a base class, letting subclasses override specific steps without changing its structure. |
| [visitor](skills/visitor/visitor.md) | Adds new operations to a stable class hierarchy without modifying it, via double dispatch through an `accept`/`Visitor` pair. |

## Agents

A three-role pipeline (Brain / Executor / Reviewer) for distributing work
across separate, independently-trackable agent sessions inside
[Herdr](https://herdr.dev) (a terminal multiplexer with built-in
coding-agent awareness) plus Claude Code. Each role runs as its **own
process in its own Herdr pane** rather than as a nested Claude Code
subagent - a subagent (Agent tool) runs invisibly inside its caller's
process, so Herdr can't see or manage it; giving each role its own pane
makes it a real, trackable agent with its own state
(`idle`/`working`/`blocked`/`done`).

It is hub-and-spoke: Brain is the only agent that talks to the user, plans,
and hands work to anyone. Executor and reviewer never talk to each other.

| Agent | Description | Origin / compatible tools |
|-------|-------------|----------------------------|
| [brain](agents/brain/brain.md) | Single orchestrator. Plans with the user up front (`session0`, `openspec-propose`), gives each change its own "flow" - a Herdr workspace on its own git worktree and branch - and dispatches the work itself: task to the executor, its committed result to a reviewer started on demand, findings back to the executor. Escalates human-judgment calls to the user. Several flows can run in parallel. | Claude Code custom subagent launched as its own top-level session via `claude --agent brain`, driving the `herdr` CLI. |
| [executor](agents/executor/executor.md) | Implements the concrete task Brain hands it, runs its own checks and installed skills (`simplify`, etc.), and commits on the flow's branch. Never pushes and does not drive review. | Same - `claude --agent executor`. |
| [reviewer](agents/reviewer/reviewer.md) | Validates committed work handed to it by Brain - drives whatever review gate/skills the project has configured (e.g. `no-mistakes`, `code-review`) and escalates human-judgment findings to Brain instead of deciding them itself. | Same - `claude --agent reviewer`. |

The mechanics (worktree-backed flows, the
`executor-<workspace_id>`/`reviewer-<workspace_id>` naming convention, the
one-background-command-per-handoff dispatch, completion lines) are
documented inline in each agent's own `.md`.

### Hooks the agents depend on

The agents reference two scripts from their frontmatter, under
`~/.claude/hooks/`. They are part of the pipeline, not optional extras.

| File | Hook | What it does |
|------|------|--------------|
| [hooks/flow-status.sh](hooks/flow-status.sh) | `Stop`, `StopFailure` (executor, reviewer) | Writes the turn's completion line to `~/.cache/agent-flow/<workspace_id>/<role>.status`, so Brain reads one small file instead of the worker's pane. A turn killed by an API error is recorded as `BLOCKED reason=<error type>`. |
| [hooks/usage-guard.py](hooks/usage-guard.py) | `PreToolUse` (all three) | Usage soft stop. At 85% of the account's usage quota it tells the agent once to wind down and save its state; at 95% it also denies tool calls that would start new work. Workers commit and report `BLOCKED reason=usage-limit`; Brain writes a checkpoint to `.claude/agent-flow/checkpoint.md` in the repo it runs in and resumes from it next session. Thresholds: `USAGE_SOFT_PCT` / `USAGE_HARD_PCT`. |

`usage-guard.py` reads `~/.cache/agent-flow/usage.json`. Claude Code hands
quota data (`rate_limits`) only to the status line command, never to hooks,
so the status line has to publish it: see `publishUsage` in
[statusline/statusline.js](statusline/statusline.js). Use that status line
as is, or copy that function into your own. Without it the guard does
nothing. `rate_limits` exists only on claude.ai Pro/Max subscriptions (or
behind a gateway with a spend limit).

### A note on hardcoded models

Each agent's frontmatter currently pins a Claude model tier - `opus` for
Brain, `sonnet` for Executor, `haiku` for Reviewer - chosen for how much
judgment that role's task needs: Brain plans and makes orchestration calls,
Executor implements well-specified tasks, Reviewer mostly drives an
external CLI/skill and relays its findings.

This is a known rough edge for a repo meant to be tool-agnostic: those tier
names, and the assumption that "a light/medium/heavy tier" maps cleanly
across providers, are Claude-specific. **If you're running these agents
with a different provider or CLI, don't copy the `model:` value as-is -
pick whatever tier your tool offers that's closest to the reasoning above
for that role's actual workload.** A proper fix (an installer that maps
role -> capability tier per target tool, instead of a hardcoded string) is
tracked for when this repo gets an installer; until then, this note is the
workaround.

## Using a skill in Claude Code

Copy the skill's `.md` file into `~/.claude/commands/<name>.md` (or
`~/.claude/skills/`, depending on the skill format) to make it available as
a slash command in any project.

## Using an agent in Claude Code

Copy the agent's `.md` file into `~/.claude/agents/<name>.md` **at user
level** (drop the `agents/<name>/` wrapper folder — Claude Code expects the
files flat in the target `agents/` directory), so it's available in every
project without a per-project copy step. Validate with `claude plugin
validate ~/.claude/agents`. A copy in a specific project's own
`.claude/agents/<name>.md` still works and takes precedence there, for when
you need to override a role for one project only - but the default is user
level. To use the full pipeline, install `brain`, `executor`, and
`reviewer` together - they're designed to work as a set, not standalone -
plus what they depend on:

```
cp agents/*/*.md ~/.claude/agents/
mkdir -p ~/.claude/hooks && cp hooks/* ~/.claude/hooks/ && chmod +x ~/.claude/hooks/*
cp statusline/statusline.js ~/.claude/statusline.js
```

and point `statusLine` in `~/.claude/settings.json` at it:

```json
"statusLine": { "type": "command", "command": "node ~/.claude/statusline.js" }
```

## Adding a new skill

1. Create `skills/<name>/`.
2. Add the skill file(s), keeping the origin tool's format as-is.
3. Add a row to the table above, noting what it does and which tools it's
   known to work with.

## Adding a new agent

1. Create `agents/<name>/`.
2. Add `<name>.md` with the agent's frontmatter + system prompt, written to
   be project-agnostic (no hardcoded project names, app details, or
   project-specific tooling — those belong in the target project's own
   `CLAUDE.md`, not in the portable agent definition).
3. Pick a `model:` tier that matches the role's actual judgment load, not
   just whichever another agent happens to use — see "A note on hardcoded
   models" above, including for non-Claude tools.
4. Add a row to the Agents table above.
