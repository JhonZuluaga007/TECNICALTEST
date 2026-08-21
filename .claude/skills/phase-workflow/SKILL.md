---
name: phase-workflow
description: How a roadmap phase is executed end to end in this repo — scoping so the diff stays attributable, branch and commit conventions, and the structure of docs/pr/phase-N-*.md including the mandatory "Honest notes" and "Deliberately not done" sections. Load BEFORE starting a roadmap phase or writing a PR description.
---

# Phase workflow

The roadmap lives in `README.md` → *Project status / Roadmap*. **Phases 0–9 are all merged and
the roadmap is complete.** This skill still applies to any future phase-shaped piece of work —
the scoping rule, the branch and commit conventions, and the PR-doc structure below are what
made each of the nine reviewable.

## The rule that shapes everything

**Each phase must be compilable, testable and reviewable on its own, and its diff must be
attributable.** That is why the SDK upgrade was a *pure* upgrade with zero refactors: so a
native toolchain failure could not be confused with a refactor of our own.

Consequences you must respect while working:

- Do not fix something a later phase owns, even when it is one line away. Add it to that
  phase's "Deliberately not done" table instead. (`CLAUDE.md` lists what is currently parked.)
- Do not fix a cosmetic issue in a file a later phase deletes — that is pure churn. The
  `"LigthGreen"` typos were deliberately left alone for this reason.
- If a change is unavoidable but out of scope, do it and **say so explicitly** in the PR doc.

## Sequence

1. **Plan.** Use the `flutter-architect` agent. Read the roadmap row and grep `README.md` for
   the phases that touched the same files. Name the risk the phase actually carries — every
   phase has one (Phase 3's was `searchHistory` having to survive every `emit`).
2. **Branch.** `feat/phase-N-<slug>` (or `test/`, `chore/`, `refactor/` when that fits better
   — the history has all four). Never work on `main`.
3. **Implement**, layer by layer, loading `/flutter-architecture`, `/flutter-codegen`,
   `/flutter-widgets` as they apply.
4. **Test** with `/flutter-testing`, including mutation verification of every behavioral
   change.
5. **Verify** with `/flutter-verify` (via the `flutter-verifier` agent).
6. **Review** the diff with the `flutter-reviewer` agent before writing the doc.
7. **Document**: `docs/pr/phase-N-<slug>.md` **and** a changelog section in `README.md`, plus
   the roadmap row flipped to ✅.
8. **Stop.** Do not commit, push or open a PR unless asked.

## Commits

Conventional prefix, imperative, one line, English, no body unless it earns one, **no
`Co-Authored-By` trailer**. The history so far:

```
chore: upgrade to Flutter 3.44.9 and remove dead code
test: add testability seams and regression suite
feat: model state and failures with Dart 3 sealed classes
feat: fix N+1, move models to freezed and take the API key out of the source
refactor: replace kiwi with get_it and injectable
feat: persist search history, cache breeds with a TTL and route by id
```

One commit per phase is the pattern. Generated files go in the same commit as their source.

## The PR doc

`docs/pr/phase-N-<slug>.md`, 100–300 lines, is the PR body. Structure, following the five
that exist:

```markdown
# Phase N — <title>

> Roadmap: `README.md` → "Project status / Roadmap". Phases 0-<N-1> are merged.

## What this changes
A "before → after" table. Then a metrics table: tests, coverage, reversions caught,
new/removed packages.

## <one section per real decision>
Not per file. Each one states the problem, the measurement, and the decision.

## Honest notes            <- MANDATORY
## Deliberately not done   <- MANDATORY, as a table with an owner phase per row
```

### Two conventions that make these docs worth reading

**Measure, do not assume.** Every quantitative claim in this repo is backed by a
measurement: *0/67 breeds have an `image` key*, *62 `.jpg` + 3 `.png`*, *`Text('Intelligence:',
fontSize: 20)` measures exactly 260 px under the test font*, *`/v1/breeds` answers 200
anonymously*. If you cannot measure it, do not claim it — write "unverified" instead.

**"Honest notes" records what was wrong.** This is the section that gives the rest of the doc
its credibility, and it is not optional. It has previously held:

- A claim in the plan that turned out to be false, with the correction (Phase 5: "flipping the
  repository to a factory would break the cache tests" — it did not, they never touch the
  container).
- A test that proved less than its name, found by mutation, renamed with the distinction
  written down (`images are NOT retried`).
- A number retracted mid-analysis (the 403s that looked like rate limiting and were a blocked
  user-agent).
- A correction to an **earlier phase's** changelog when a later measurement contradicted it
  (Phase 3's claim about the API key, corrected in Phase 4 — in place, marked as a correction,
  not quietly deleted).

If a phase produced no such finding, say so in one line. Do not invent one, and do not omit
the section.

## README changelog section

Mirrors the PR doc but shorter and past-tense, appended under `## Modernization changelog` in
phase order, opening with a **Result** line (`Result: 140 tests across 20 files, analyze
clean, 96.9% of reached lines covered, and one less dependency`). Flip the roadmap row to ✅
in the same edit — a merged phase still showing ⬜ is the one inconsistency reviewers notice
first.
