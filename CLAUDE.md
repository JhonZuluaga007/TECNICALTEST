# CLAUDE.md

Catbreeds — a Flutter app over [TheCatAPI](https://thecatapi.com), clean architecture per
feature, under a **phased modernization** (Phases 0–6 merged, 7–9 pending). Every phase is
compilable, testable and reviewable on its own.

`README.md` is the 700-line historical record: the roadmap, and a changelog per phase
explaining *why* each decision was made — including the claims that turned out to be wrong.
**Do not read it whole.** Grep it (`grep -n "Phase 4" README.md`) when you need the rationale
behind something you are about to change.

---

## Non-negotiables

1. **Every Dart/Flutter command goes through `fvm`.** The SDK is pinned to **3.44.9** in
   `.fvm/fvm_config.json`; a bare `flutter`/`dart` runs whatever is on `$PATH` and will
   silently produce a different `pubspec.lock`, a different `dart format` result and a
   different analyzer. A PreToolUse hook blocks unprefixed commands.
2. **English only** — doc comments, inline comments, test names, fixture literals, commit
   messages, config comments. The repo was normalized in Phase 2; do not reintroduce Spanish.
3. **Never `git commit`, `git push` or open a PR unless explicitly asked.** Approving a plan
   that mentions committing is not authorization to commit.
4. **Generated files are committed** (`*.freezed.dart`, `*.g.dart`, `injector.config.dart`).
   A fresh clone must build without running the generator. Touch a `@freezed`/`@injectable`
   class → run `build_runner` → commit both files together.
5. **`lib/` never imports `dart:io`.** The app builds for web. Transport failures are
   classified from `http.ClientException`, never `SocketException` (see `retry.dart` and the
   Phase 3 changelog).
6. **Comments explain *why*, never *what*.** This codebase's comments are load-bearing
   documentation of decisions and traps. Match that register; do not add `// increment i`
   noise, and do not delete an existing rationale comment because the code "reads fine".

---

## Commands

| | |
|---|---|
| Install deps | `fvm flutter pub get` |
| Analyze | `fvm flutter analyze` — must report **no issues** |
| Format | `fvm dart format .` — must produce **no diff** |
| Test | `fvm flutter test` — **258 tests**, all green |
| One subtree | `fvm flutter test test/features/landing_cats/data` |
| One case | `fvm flutter test --plain-name "exactly 1 request"` |
| Codegen | `fvm dart run build_runner build --delete-conflicting-outputs` |
| Coverage | `fvm flutter test --coverage` (see `/flutter-verify` for the awk one-liners) |
| Run | `fvm flutter run -d macos` (resizable window — best for breakpoints) |
| API key (optional) | `cp env/example.json env/dev.json` → `fvm flutter run --dart-define-from-file=env/dev.json` |

The app works with **no** API key: `/v1/breeds` and `/v1/images/{id}` both answer 200
anonymously. A missing key is never the cause of an error screen.

---

## Architecture

```
lib/
├── core/
│   ├── common_widgets/     # Reusable widgets (card, text, network image)
│   ├── config/             # endpoints · theme · responsive
│   ├── errors/             # sealed class CatsFailure (freezed)
│   ├── injector/           # get_it + injectable — the ONLY file in lib/ importing get_it
│   ├── storage/            # KeyValueStore interface + hydrated_bloc impl
│   └── utils/              # CatsResult (Ok/Err), withRetry
├── features/<feature>/
│   ├── data/               # datasource (remote + local) · models (freezed/json) · repository impl
│   ├── domain/             # entities · repository contract · use_cases
│   └── presentation/       # bloc · pages · widgets
└── routers/                # go_router, declarative nested routes
```

**Dependency direction is one-way: `presentation → domain ← data`.**

- `domain/` imports nothing from `data/` or `presentation/`, and no third-party package
  except `injectable` and `freezed_annotation`.
- `data/` must never import `package:hydrated_bloc` (it re-exports `package:bloc`) — that is
  the whole reason `core/storage/KeyValueStore` exists.
- `presentation/` never touches a repository or a datasource; it goes through a use case.
- Nothing outside `core/injector/` and `main.dart` calls `Injector.resolve`. Blocs and
  widgets receive their dependencies through the constructor or the widget tree.

### The load-bearing types

| Type | Where | Rule |
|---|---|---|
| `sealed class CatsResult<T>` = `Ok` \| `Err` | `core/utils/` | The only success/failure channel. **No `Either`.** It defines no `==` on purpose — assert on the variant, then on the contents. |
| `sealed class CatsFailure` | `core/errors/` | `network` · `timeout` · `server(statusCode)` · `unexpectedResponse` · `notFound(id)` · `unknown`. Adding a variant intentionally breaks every `switch` — fix each one, never add a `default`/`_`. |
| `sealed class LandingCatsState` | `landing_cats/presentation/bloc/` | `initial` · `loading` · `loaded` · `stale` · `error`. `searchHistory` lives on **every** variant and must be carried through **every** `emit` — dropping it in one branch wipes the feature silently. |
| `BreedsSnapshot` = `FreshBreeds` \| `StaleBreeds` | `landing_cats/domain/entities/` | An `Ok(StaleBreeds)` carries a failure: the call produced usable data, the failure describes its *freshness*. |

`equatable` is gone (Phase 4). Value equality comes from freezed. Never add it back.

The repository is a **total function**: it catches everything and always returns a
`CatsResult`. Nothing above `data/` should ever see a raw exception.

---

## Definition of done

Nothing is finished until all four pass, in this order:

```bash
fvm dart run build_runner build --delete-conflicting-outputs   # only if codegen inputs changed
fvm dart format .                                              # no diff
fvm flutter analyze                                            # no issues
fvm flutter test                                               # all green
git diff --exit-code -- '*.freezed.dart' '*.g.dart' '*.config.dart'   # no stale generated file
```

Use the **`flutter-verifier` agent** to run this — it isolates hundreds of lines of tool
output and reports back only the verdict and the failing excerpts.

A behavioral fix is not done until its test has been **verified by reverting the fix** and
confirming the test goes red. This repo's suite is evidence, not decoration: Phase 2 verified
14/14 fixes that way, Phase 6 verified 18/18.

---

## Conventions

- **Branches:** `feat/phase-N-<slug>`, `test/...`, `chore/...`, `refactor/...`.
- **Commits:** conventional prefix, imperative, one line, English, **no `Co-Authored-By`
  trailer**.
- **Phase docs:** each phase ships `docs/pr/phase-N-<slug>.md` (the PR body) plus a changelog
  section in `README.md`. Both include an **"Honest notes"** section recording claims that
  turned out to be wrong and tests that proved less than their name. That section is a
  requirement, not a flourish.
- **Test files mirror `lib/` exactly.** `lib/a/b/c.dart` → `test/a/b/c_test.dart`.

---

## Skills and agents

Load the skill *before* starting the matching work — each one carries the traps that are not
visible in the code.

| Skill | Use when |
|---|---|
| `/flutter-architecture` | Adding a feature, use case, state variant, DI registration, or moving code between layers |
| `/flutter-testing` | Writing or fixing any test. Contains the two `FakeAsync` zone traps that cost hours |
| `/flutter-codegen` | Touching a `@freezed`, `@injectable` or `@JsonSerializable` class |
| `/flutter-widgets` | Presentation-layer work: dispose ownership, `const`, rebuild scope, images |
| `/flutter-verify` | Running the gate, reading coverage, mutation-verifying a test |
| `/phase-workflow` | Executing a roadmap phase end to end, writing the PR doc |

| Agent | Use for |
|---|---|
| `flutter-verifier` | Running analyze/format/test/codegen. **Always prefer this over running them inline** |
| `flutter-architect` | Read-only planning before a non-trivial change |
| `flutter-test-author` | Writing a test suite for new code, including mutation verification |
| `flutter-reviewer` | Reviewing a diff against this file's invariants before a PR |

### Context budget

- Never `cat` a whole file to "have a look". Grep for the symbol, then `Read` with
  `offset`/`limit`.
- `README.md` (700 lines), `pubspec.yaml` and the generated `*.freezed.dart` files are large
  and mostly rationale or boilerplate — grep them, do not read them.
- Delegate anything that means sweeping many files to the `Explore` agent, and anything that
  means running verbose commands to `flutter-verifier`. Keep the conclusion, not the dump.
- The **Dart MCP server** (`.mcp.json`) runs on the pinned SDK. Prefer `analyze_files` over
  `fvm flutter analyze` — it returns a structured result instead of console text and reuses
  the warm analysis server — and `lsp` for hover, references and symbol lookup instead of
  grepping for a definition. It exposes **no test runner**: the suite goes through the
  `flutter-verifier` agent (measured, see `.claude/README.md`).

---

## Known state (do not "fix" these as drive-by work)

Each belongs to a pending phase; touching it early makes a diff unreviewable.

| Thing | Owner |
|---|---|
| Hardcoded strings, no `ThemeData`/dark mode/l10n, `google_fonts` at runtime, `"LigthGreen"`/`"LigthGrey"` typos in `AppCatsColor` | Phase 7 |
| `flutter_screenutil` and `ScreenUtil.init` inside `build`; `ignoreOverflowErrors()` in tests (a test-font metrics artifact, **not** a layout bug) | Phase 8 |
| `analysis_options.yaml` is a bare `include:`; no CI; no coverage gate; no stale-codegen check in CI | Phase 9 |
