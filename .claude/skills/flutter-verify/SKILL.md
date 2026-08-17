---
name: flutter-verify
description: The verification gate for this repo — the exact command order, how to read each failure mode, coverage one-liners and their honest caveat, and how to mutation-verify a test. Load BEFORE claiming any change is done, and whenever analyze/format/test output needs interpreting.
---

# Verification

Prefer running this through the **`flutter-verifier` agent** — it keeps hundreds of lines of
tool output out of the main context and reports only the verdict plus the failing excerpts.
Run it inline only when you are already debugging a specific failure.

## The gate, in this order

```bash
# 1. Only if a @freezed / @injectable / fromJson input changed
fvm dart run build_runner build --delete-conflicting-outputs

# 2. Formatting — must produce NO diff
fvm dart format .
git diff --stat

# 3. Static analysis — must report NO issues
fvm flutter analyze

# 4. The suite — 258 tests, all green
fvm flutter test

# 5. No generated file left behind
git diff --exit-code -- '*.freezed.dart' '*.g.dart' '*.config.dart'
```

Order matters: `dart format` before `analyze` (formatting can move a line an analyzer message
points at), codegen before both (analyzing against a stale `.freezed.dart` produces errors
that do not exist).

`fvm` is not optional. A bare `dart format` from a different SDK reformats files the pinned
`dart_style` would leave alone, and the diff becomes unreviewable.

## Reading the failure modes

| Output | What it actually means |
|---|---|
| `pumpAndSettle timed out` in a widget test | The bloc was built in a `setUp`, outside the `FakeAsync` zone. Move it into the `testWidgets` body via `tester.buildBloc`. See `/flutter-testing` |
| `LateInitializationError` on `.w` / `.h` | `ScreenUtil` not configured — the test bypassed `flutter_test_config.dart`, or a helper other than `pumpAppWith` was used |
| `MissingPluginException` | Something reached `path_provider`/a real plugin under `flutter test`. Use `InMemoryStorage` |
| `A RenderFlex overflowed` | Almost always the test-font metrics artifact, not a layout bug — every glyph is a full em square under `flutter test`. Opt in with `ignoreOverflowErrors()` **inside the test body**. Do not "fix" the layout to satisfy it |
| `non_exhaustive_switch` | A sealed variant was added. Handle it — never add `default:` |
| A registration is missing though it is in the source | Stale `injector.config.dart`. Regenerate |
| Version solving failed | Read the analyzer-pin note in `/flutter-codegen` before touching `pubspec.yaml` |
| Wall of `google_fonts` debugPrint | The test bypassed `flutter_test_config.dart` |

## Coverage

```bash
fvm flutter test --coverage        # flutter_tools bundles the coverage package; no lcov needed

# total
awk -F: '/^LF:/{f+=$2} /^LH:/{h+=$2} END{printf "%d/%d = %.1f%%\n", h, f, 100*h/f}' coverage/lcov.info

# per file, worst first
awk -F: '/^SF:/{f=$2} /^LF:/{lf=$2} /^LH:/{lh=$2} /^end_of_record/{printf "%6.1f%%  %s\n", (lf?100*lh/lf:0), f}' \
  coverage/lcov.info | sort -n
```

**State the caveat every time you quote the number.** `--coverage` only instruments libraries
the run actually loaded, so it is "of reached lines", not "of the project" — declaration-only
files (constants, barrels, abstract classes) are simply absent from `lcov.info`. Quoting it as
project coverage overstates it. There is no coverage gate yet; Phase 9 owns that.

Exclude generated files from any judgement about coverage: `*.freezed.dart` and `*.g.dart`
inflate both the numerator and the denominator and say nothing about the tests.

## Mutation verification

The bar for a behavioral change. For each fix or guard:

```bash
# 1. break it deliberately — revert the fix, flip the flag, drop the annotation
# 2. run only the test that should catch it
fvm flutter test --plain-name "the exact test name"
#    -> it MUST fail. If it passes, the test proves less than its name.
# 3. restore, re-run, confirm green
```

Report the ratio in the PR doc (`14/14`, `18/18`). If a test turns out to be vacuous, rename
it to what it actually proves and write down the distinction — this repo has three such
findings on record, and they are more valuable than the tests that passed.

Useful mutations for this codebase specifically:

| Mutation | Which test must go red |
|---|---|
| Drop `lazy: false` from the `BlocProvider` in `main.dart` | `app_test.dart` — the request must have happened while the splash is on screen |
| Make any graph **consumer** `@Singleton` | `injector_test.dart` — `the injected client reaches the datasource` |
| Drop `dispose:` from a module registration | Check by reading the generated config; the override path alone will not catch it |
| Remove `explicit_to_json` from `build.yaml` | `catbreed_model_test.dart` round-trip |
| Drop `searchHistory` from one `emit` branch | `landing_cats_bloc_test.dart` |

## What "done" means

- [ ] All five commands above pass
- [ ] Every behavioral change mutation-verified, with the ratio recorded
- [ ] No new `// ignore:` and no new `analysis_options` exclusion
- [ ] Comments explain *why*, and any decision that contradicts a previous phase is named in
      the PR doc's "Honest notes"
- [ ] Nothing committed unless the user asked for it
