---
name: tdd
description: Rules of the test-driven loop (red -> green -> refactor, one behavior at a time) and what makes a test worth keeping - seams, anti-patterns, regression tests for bugs. The working reference of the tdd-executor, and the yardstick the tdd-reviewer holds tests to. Use when building a feature or fixing a bug test-first.
license: MIT
metadata:
  credits: "Adapted from ideas in mattpocock/skills (tdd; MIT) and citypaul/.dotfiles (planning)."
---

# Test-driven development

TDD here means building a slice of the plan one behavior at a time, each behavior pinned by a test that failed before the code existed. The goal is a codebase that can keep growing because many small, honest tests protect it. Every rule below applies on every cycle.

## What a good test is

- **It checks behavior through a public interface, not implementation details.** It reads like a specification ("an investigator with no clues cannot close a gate") and survives any refactor that keeps the behavior.
- **It lives at an agreed seam.** A seam is a public boundary where behavior can be observed without reaching inside: the plan lists them. Test at those seams only; a test at a new seam needs the owner's agreement through the plan first.
- **Its expected values come from an independent source of truth**: the rules, a worked example, the plan's acceptance criteria - never from computing the answer the way the code does.
- **It is small, fast and deterministic.** Randomness is seeded, time is injected, nothing depends on test order.
- **Its name states the behavior**, in the project's glossary vocabulary.

## Anti-patterns (the reviewer looks for these)

- **Implementation-coupled:** mocks internal collaborators, tests private functions, or verifies through a side channel (reading the database instead of using the interface). Tell: it breaks on a refactor that didn't change behavior. Mock only at system boundaries (network, clock, randomness, filesystem when it is not the subject).
- **Tautological:** the assertion recomputes the expected value the way the code does, or asserts a constant equals itself. It can never fail.
- **Horizontal:** writing all the tests of a slice first and then all the code. Bulk tests pin imagined behavior and freeze test structure before the design is understood. Work vertically instead: one test, the code for it, then the next test.
- **Weakened or silenced:** deleting, skipping or loosening an existing test, or regenerating golden/snapshot files, to make a change pass. Only allowed when the plan changed that behavior, and then said explicitly in the commit and the pull request.
- **Coverage theatre:** tests that execute code without asserting the behavior that matters.

## The loop

1. **Red.** Pick the next acceptance criterion (or the next smallest step towards it). Write one test for it at its seam. Run it and watch it fail **for the right reason** - an assertion about the missing behavior. In a compiled language, first add the minimal stub that lets the test compile, so it fails on behavior, not on a missing symbol.
2. **Green.** Write the least code that makes it pass. No speculative generality, no code for the next criterion.
3. **Refactor**, only with every test green: remove duplication, improve names, apply the project's readability rules. Behavior doesn't change, so no test changes - if one has to, it was implementation-coupled.
4. Run the whole suite. Repeat from 1 until every criterion of the slice has its test.

Commit at green points, small and often, following the project's commit convention - the history of the branch should show the slice growing test by test. Never rewrite history that was pushed.

## Kinds of work that change the loop

- **Bug fix:** first a test that reproduces the bug at the closest seam and fails, then the fix. The test stays as the regression guard.
- **Prefactor** (making the next change easy): starts and ends with every test green; no new failing test.
- **Refactor slice:** same - preservation, not new behavior. Never fabricate a failing test for it.
- **No-TDD slice** (pure configuration, docs): no test cycle, but the reason must be stated in the plan and the pull request.

## When the loop doesn't fit

If a criterion can't be tested at any agreed seam, or the test would need a seam the plan doesn't have, stop and report it instead of testing internals or skipping the test - that is a plan decision, not an implementation detail.
