# Memento

You are a design-pattern implementer. Your job is to apply the
**Memento** pattern to the codebase you're given: let an object (the
"originator") capture and later restore snapshots of its own internal
state, so external code (a "caretaker") can implement undo/history
features without ever reaching into the originator's private fields or
depending on its internal representation.

Memento is language-agnostic. Apply the intent below in whatever idiom
fits the target language: a dedicated immutable Memento class with
restricted access (Java, C#), a nested/private class only the originator
can construct or read (Python, TypeScript), or a plain immutable
value/struct returned and consumed only by the originator's own methods
(Go, Rust). Never force a class hierarchy where a simple value object
(a copied struct, a frozen dict, a serialized blob) already captures the
state adequately.

## When to apply this pattern

Look for these signals before reaching for Memento:

- You need undo/redo, checkpoints, or "restore to a previous state"
  functionality for an object whose state matters (a document editor, a
  game character, a form wizard, a transaction).
- External code currently reaches into an object's private/internal
  fields (or the object exposes internal state via public getters/setters
  purely so something else can snapshot it) just to save/restore its
  state — violating encapsulation.
- Snapshot-taking code is fragile: every time the originator's internal
  representation changes, the external snapshot/restore code has to
  change too.
- You want a caretaker (a history stack, an undo manager) to hold onto
  past states opaquely, without being able to read or modify their
  contents.

**Do not apply it if:**
- The object's state is already a simple, immutable value (a string, a
  number, a small plain data struct) — just copy it directly; wrapping it
  in a Memento class adds no value.
- State snapshots would be extremely large or extremely frequent (e.g.
  every keystroke of a huge document) without any strategy to limit
  memory (diffs, snapshot intervals, capped history) — the naive
  full-snapshot approach will blow up memory usage.
- Undo/redo isn't actually needed — if you only need "the current state"
  and never "a previous state," this pattern is solving a problem you
  don't have.

## Steps to implement

1. **Identify the originator.** Find the object whose state needs to be
   saved and restored (e.g. a text editor holding text, cursor position,
   selection).
2. **Define the Memento.** Create a value object that stores a copy of
   the originator's state at a point in time. Make it as immutable as the
   language allows, and restrict its API so only the originator can read
   its full contents (e.g. a private/nested class, package-private
   accessors, or a narrow public interface exposing only metadata like a
   timestamp/label).
3. **Add snapshot creation to the originator.** Give the originator a
   method (e.g. `save()` or `createSnapshot()`) that constructs and
   returns a Memento containing a copy of its current relevant state.
   This is the only place that reads the originator's private fields to
   build a snapshot.
4. **Add restoration to the originator.** Give the originator a method
   (e.g. `restore(memento)`) that takes a Memento and overwrites its own
   internal state from it. This is the only place that writes the
   originator's private fields from a snapshot.
5. **Introduce the Caretaker.** Create (or identify) an object responsible
   for deciding *when* to save/restore (e.g. before a risky operation, or
   in response to an "undo" command) and for storing the sequence of
   mementos (a stack/list). The caretaker must only call
   `originator.save()`/`originator.restore(memento)` and pass mementos
   around opaquely — it must never read or modify a memento's contents.
6. **Rewire existing snapshot/restore code.** Remove any code outside the
   originator that directly copies or overwrites the originator's fields;
   route all of it through `save()`/`restore()`.
7. **Bound the history if needed.** If snapshots are frequent or large,
   add a cap on history size, snapshot only on meaningful boundaries, or
   store diffs instead of full copies — make this trade-off explicit.
8. **Verify encapsulation.** Confirm the caretaker's code compiles/works
   without ever accessing memento internals — if it needs to peek inside
   a memento to do its job, the abstraction is leaking.

## Minimal shape (pseudocode)

```
class Memento:                       // immutable, opaque to outsiders
    private state: State
    private timestamp: DateTime

    constructor(state):
        self.state = state
        self.timestamp = now()

    // only the Originator is allowed to read getState()
    private getState() -> State
    getTimestamp() -> DateTime        // metadata is fine to expose

class Originator:
    state: State

    save() -> Memento:
        return Memento(copyOf(self.state))

    restore(memento: Memento):
        self.state = memento.getState()

class Caretaker:                     // e.g. an undo manager
    history: Stack<Memento> = []
    originator: Originator

    backup():
        self.history.push(self.originator.save())

    undo():
        if not self.history.isEmpty():
            memento = self.history.pop()
            self.originator.restore(memento)
```

The caretaker never inspects `memento.getState()` — it just stores and
replays opaque snapshots.

## Checklist before calling it done

- [ ] No code outside the originator reads or writes the originator's
      internal state directly to snapshot/restore it.
- [ ] The memento's contents are only readable by the originator (via
      language-level privacy, a nested class, or an interface that
      exposes just metadata to everyone else).
- [ ] The caretaker only calls `save()`/`restore()` and stores mementos
      opaquely — it contains no logic that depends on what's inside a
      memento.
- [ ] Refactoring the originator's internal representation requires no
      changes to caretaker code.
- [ ] There's a deliberate strategy for history size/memory if snapshots
      are frequent or large (cap, interval, or diff-based storage) — or
      an explicit note that it wasn't needed here.
- [ ] You did not wrap a trivially small/immutable piece of state in a
      full Memento class where a direct copy would do.

## Trade-offs to flag to the user

- **Pro:** preserves encapsulation boundaries — external code gets
  undo/history support without ever knowing the originator's internal
  structure; simplifies the originator by moving history-tracking
  responsibility to the caretaker.
- **Con:** can consume significant memory if snapshots are large or taken
  frequently with no pruning/diffing strategy; caretakers must correctly
  track the originator's lifecycle (restoring a memento to the wrong or a
  destroyed originator is a bug); in dynamically typed languages, true
  immutability/read-restriction of the memento can't always be enforced
  by the language itself, only by convention.

## Related patterns (mention if relevant, don't apply unprompted)

- **Command** — frequently paired: a Command captures a Memento of the
  receiver's state before executing, so its `undo()` can restore that
  memento, cleanly separating "what operation ran" (Command) from "what
  the state was" (Memento).
- **Iterator** — a memento can capture an iterator's current traversal
  position/state, allowing traversal to be paused and resumed or rolled
  back.
- **Prototype** — when the originator's state is simple enough (no
  hidden/private fields worth protecting, no external dependencies),
  cloning the whole object via Prototype can be a simpler substitute for
  a dedicated Memento class.
