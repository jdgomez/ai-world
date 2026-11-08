---
name: tdd-plan
description: Plan a milestone of a test-driven project as vertical slices, together with the owner, and write it to the project's milestone plan file. The first plan of a project polishes the golden slice - the thinnest end-to-end path through every layer, with its test seams - that every later slice imitates. Use when planning the next milestone of a project that follows the TDD methodology (tdd-executor / tdd-reviewer). Planning only - never writes code.
license: MIT
metadata:
  credits: "Adapted from ideas in mattpocock/skills (to-tickets, tdd, grill-me; MIT) and citypaul/.dotfiles (planning)."
---

# TDD plan - vertical slices for one milestone

You turn one milestone of the project into a plan of **vertical slices** that the executor can build test-first, one slice per pull request. You plan together with the owner, one question at a time, until both of you trust the plan. Its output is a file in the repo, so the executor and the reviewer can act on it without anyone relaying context.

**Planning boundary:** you write the plan file - and, for the golden slice, the project's review skill (see below) - and nothing else. Do not edit code, tests, build files or configuration, even if the owner asks to "build" something - stop once the plan is approved and written.

## 1. Read the context first

Before asking anything, read what already answers questions:
- the product inception document (e.g. `SESSION0.md`): scope, glossary, phases and the milestone breakdown;
- the decision record (e.g. `docs/architecture.md`): project-wide decisions you must respect, not re-open;
- earlier plans in the plan directory, and the code that exists today;
- the project's `CLAUDE.md`, for where plans live and how they are landed.

Plans live where the project says. If it says nothing, use `docs/plans/<milestone>.md`. Use the project's glossary for every name in the plan.

## 2. Pick the mode

- **Golden slice** - the project has no production code yet, or no slice has been merged. This plan sets the patterns the whole project will copy.
- **Growth** - a golden slice is merged. Each slice adds one behavior on top of what exists.

### Golden slice: why it gets extra care

Agents imitate the code that already exists. Package layout, naming, the shape of a test, how an error travels from the core to the screen: whatever the golden slice does, every later slice will do too. So the first plan settles, explicitly and with the owner:
- **The thinnest end-to-end path** through every layer the product will have (e.g. UI -> API -> core logic -> persistence). Hardcoded or fake data is fine; reaching every layer is not optional.
- **The seams**: the public interfaces where tests observe behavior without reaching inside. For each one, a one-line note on what tests there catch and what they miss. No test is written at a seam that is not on this list.
- **The test levels and one reference style per level** (e.g. table-driven unit tests for rules, a scenario test, one end-to-end path), described in words - the executor writes the first real example, and the reviewer holds every later test to it.
- **The routine commands** that must work at the end of the slice (build, test, lint, run), and the CI check that runs them on every pull request.
- **The linters** that turn the project's mechanical rules into checks (e.g. doc comments on exported identifiers, magic numbers, complexity, duplication), so the reviewer's attention goes to what a machine can't check.
- **What the reviewer must check in this project** - see "The project review skill" below.

Keep the golden slice small. It proves the architecture and the test style; it does not deliver features.

### The project review skill

Every TDD project gets its own review skill, written with the owner while planning the golden slice: `.claude/skills/project-review/SKILL.md` in the repo, committed with the plan. The generic `tdd-reviewer` invokes it on every pull request; it is where this project's own review rules live - the ones its linters can't express. Build it from the decision record and the golden slice's choices, and keep every rule checkable on a diff: something the reviewer can point at, not a taste.

```markdown
---
name: project-review
description: <Project> review rules - what tdd-reviewer checks on every pull request of this project, beyond what its linters catch.
---

# <Project> review rules

Check the change against each rule. Report only what you can point at (file and line, which rule, why); zero findings is a valid result. A broken rule is blocking.

## Architecture
- <e.g. the rules engine imports no transport, file or database package (D10)>

## Code
- <e.g. a function implementing a game rule cites the rule it applies (D4)>

## Tests
- <e.g. every rule has table-driven unit tests; scenario tests replay a seed and an action log (D17)>

## Not rules here
- <things the owner explicitly does not want flagged, to keep the review quiet>
```

When a later decision changes what should be reviewed, update the skill in the same pull request as the decision.

## 3. Interview the owner

Walk the open decisions one at a time, the way a careful reviewer would: ask one question, give your recommended answer and why, wait for the reply, then follow whatever branch it opens. If the code or the documents can answer a question, look there instead of asking. Stop when every branch that affects the slices is resolved.

Typical branches: what the owner must be able to see or do at the end of the milestone; the edge cases that matter now and the ones that can wait; what is out of this milestone; the seams (golden) or which existing seams a new behavior goes through (growth); data the slices need and where it comes from; risks worth front-loading.

A decision that holds for the whole project belongs in the decision record, not in the plan - propose the entry and let the owner approve it.

## 4. Draft the slices

<vertical-slice-rules>
- Each slice cuts a narrow but complete path through every layer it touches - never one layer at a time ("database, then API, then UI" is the anti-pattern).
- Each slice is describable in one sentence: **actor, trigger, observable outcome**. If it needs more, split it.
- A finished slice is demoable or verifiable on its own, and leaves every test passing.
- Each slice fits one fresh executor session and one pull request the owner can read in one sitting.
- Order slices so blockers come first; declare each slice's blocking edges. Prefactoring that makes a slice easy comes before it.
- A wide mechanical refactor is the exception: sequence it as expand -> migrate in batches -> contract, each step green on its own.
</vertical-slice-rules>

**Acceptance criteria** are what the tests will prove, so they must be testable at a seam:
- written as observable behavior (`Given ... when ... then ...`), never as implementation steps;
- with concrete example values taken from an independent source of truth (the rules, a worked example, the owner) - never values the code would compute the same way;
- each one tied to the seam where it will be tested.

Not every slice changes behavior. Mark the class of each one: `behavior`, `prefactor` or `refactor` (start from passing tests, add no new failing ones), or `no-tdd` with the reason (pure configuration, docs). The reviewer checks that classification.

Do not write file paths, function signatures or code in the plan - they go stale and they are the executor's decisions. The one exception is a contract that the owner has decided on precisely (a data shape, a state machine); quote just the decision.

## 5. Quiz the owner on the breakdown

Present the slices as a numbered list - title, one-sentence story, blocked by - and ask:
- Does the granularity feel right (too coarse, too fine)?
- Is every blocking edge real?
- Should any slice be merged or split?
- Are the acceptance criteria the behavior you actually want?

Iterate until the owner approves. Then write the file.

## 6. Write the plan

Use this shape. Keep it short: the plan is read by the owner and by both agents on every slice.

```markdown
# <Milestone id>: <milestone name>

- **Status:** approved | in progress | done
- **Mode:** golden slice | growth
- **Goal:** <one sentence: what the owner can see or do when the milestone is done>

## Decisions for this milestone

<decisions that only hold for this milestone; link to the decision record for project-wide ones>

## Seams

| Seam | Tests here catch | Tests here miss |
|---|---|---|
| <public interface> | <...> | <...> |

<golden: the full list, plus the test levels and reference style per level. growth: only the seams this milestone uses or adds.>

## Slices

### S1: <title>

- **Story:** <actor> <trigger> -> <observable outcome>
- **Class:** behavior | prefactor | refactor | no-tdd (<reason>)
- **Blocked by:** none | S<n>
- **Acceptance criteria:**
  - [ ] <Given ... when ... then ...> (seam: <seam>)
  - [ ] ...

### S2: ...

## Out of this milestone

- <what was deliberately left out, so nobody builds it by accident>

## Open questions

- <anything that does not block the first slices; empty is fine>
```

The executor ticks a criterion's box when its test passes on the slice's branch. Nobody else edits the plan without the owner: a change of scope goes back to the owner, gets approved explicitly, and is written into the plan before more work is dispatched.

## 7. Hand it back

Land the plan the way the project says (e.g. committed directly to the main branch after the owner's approval), then report in a few lines: the mode, the slices in order with their blockers, and which slices can start right away.
