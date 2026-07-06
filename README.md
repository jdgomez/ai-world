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

## Using a skill in Claude Code

Copy the skill's `.md` file into `~/.claude/commands/<name>.md` (or
`~/.claude/skills/`, depending on the skill format) to make it available as
a slash command in any project.

## Adding a new skill

1. Create `skills/<name>/`.
2. Add the skill file(s), keeping the origin tool's format as-is.
3. Add a row to the table above, noting what it does and which tools it's
   known to work with.
