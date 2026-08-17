---
name: flutter-testing
description: How to write tests in this repo — the harness (flutter_test_config, PumpApp, in-memory stores), the two FakeAsync zone traps that make widget tests hang, mocktail vs MockClient, assertion style for sealed types, fixtures, and mutation verification. Load BEFORE writing or debugging any test.
---

# Testing

258 tests, `test/` mirrors `lib/` exactly (`lib/a/b/c.dart` → `test/a/b/c_test.dart`).
Stack: `flutter_test` + `bloc_test` + `mocktail`, plus `MockClient` from
`package:http/testing.dart` at the HTTP boundary.

## The two zone traps — read this before anything else

Both have the same shape: `setUp` runs **outside** the `testWidgets` `FakeAsync` zone and
**before** `testWidgets` installs its own error handler.

1. **Build the bloc inside the `testWidgets` body, never in a `setUp`.** Use
   `tester.buildBloc(...)` from `test/helpers/pump_app.dart`. In a `setUp` the bloc's internal
   microtasks stay bound to the real zone, `pump`/`pumpAndSettle` never drain them, the state
   stays on `CatsLoading` and `pumpAndSettle` fails with *timed out*.
2. **Call `ignoreOverflowErrors()` inside the `testWidgets` body, never in a `setUp`** —
   `testWidgets` replaces `FlutterError.onError` after the `setUp` callbacks run, so a
   `setUp` placement filters nothing.

## The harness

| File | What it gives you |
|---|---|
| `test/flutter_test_config.dart` | Runs once **per test file**, discovered automatically. Disables `google_fonts` runtime fetching and configures `ScreenUtil` (without it any `.w`/`.h` throws `LateInitializationError`). |
| `test/helpers/pump_app.dart` | `tester.buildBloc(useCase, {storage, fetchOnBuild})` (auto `addTearDown(bloc.close)`), `tester.pumpAppWith(widget, {bloc, imageUseCase, breedByIdUseCase})`, `tester.pumpRouter(...)` for navigation tests. Deliberately does **not** use `ScreenUtilInit`. |
| `test/helpers/mocks.dart` | `Mock*` (mocktail) for every boundary + hand-written `Fake*` use cases that record what was requested. |
| `test/helpers/in_memory_key_value_store.dart` | `InMemoryKeyValueStore` (for the local datasource) and `InMemoryStorage` (for a bloc constructor or `Injector.setup`, exposes `closed`). |
| `test/helpers/builders.dart` | `catBreedModel(...)` / entity builders with every field defaulted — override only what the test is about. |
| `test/helpers/fixture_reader.dart` | `fixture('breeds_3.json')` and `jsonResponse(body, [status])` — the latter sets `content-type: application/json; charset=utf-8`, **required** because `http.Response` defaults to latin1. |
| `test/helpers/ignore_overflow_errors.dart` | Opt-in silencing of `RenderFlex overflowed` only. |

## Which double at which seam

| Seam | Double | Why |
|---|---|---|
| HTTP | `MockClient` from `package:http/testing.dart` | Routes by URL, returns different bodies per endpoint, and lets you **count requests**. It also exercises the real `BaseClient.get → send` path. |
| Repository / datasource / use case | `mocktail` | |
| Widget under test needs a use case it does not exercise | hand-written `Fake*` from `mocks.dart` | Records calls, no `when` stubbing noise |
| Bloc, in a widget test **of that bloc's page** | the **real** bloc with a mocked use case | A `MockBloc` there would let a broken bloc pass |
| Bloc, in a widget test of something merely *reading* it | `MockLandingCatsBloc` (`bloc_test`'s `MockBloc`) | |
| Persistence | `InMemoryStorage` / `InMemoryKeyValueStore` | Never the real `HydratedStorage` — `path_provider` throws `MissingPluginException` under `flutter test` |

`MockClient` does **not** wrap what its handler throws. Throw `http.ClientException`, not
`SocketException`, because that is what the real client does on every platform.

## Assertion style

Sealed types have no `==` in the `CatsResult` case, and freezed-generated `==` everywhere
else.

```dart
// CatsResult — two steps, never a direct comparison
expect(result, isA<Ok<List<CatBreedEntity>>>());
expect((result as Ok<List<CatBreedEntity>>).value, equals(breeds));

// freezed states — concrete instances, they compare by value
blocTest<LandingCatsBloc, LandingCatsState>(
  'emits loading then loaded',
  build: () => LandingCatsBloc(getAllCatsUseCase: useCase, storage: InMemoryStorage()),
  act: (bloc) => bloc.add(const AllCatsEvent()),
  expect: () => [
    const CatsLoading(searchHistory: []),
    CatsLoaded(breeds: breeds, searchHistory: const []),
  ],
);
```

Prefer concrete states over matchers. If a test needs matchers to pass, the state modelling
is usually the thing to fix.

The bloc takes its `Storage` **through the constructor**; never set the process-wide
`HydratedBloc.storage`. `flutter_test_config.dart` runs once per *file* and hydrated_bloc keys
state by runtime type, so a global store would leak one test's search history into the next
and make assertions depend on execution order.

## Fixtures

`test/fixtures/breeds_full.json` is the **real** TheCatAPI payload captured 2026-08-10: 67
breeds, of which exactly 2 (`European Burmese`, `Malayan`) omit `reference_image_id`. The
trimmed variants are derived mechanically from it. Four are hand-written because the live API
never produces them: `weight: null`, null `imperial`/`metric`, an empty array, and an image
response with no `url` key. When you add a fixture, say in a comment which of the two it is.

## Mutation verification — the bar for "done"

A test that has never been seen failing proves nothing. For every behavioral fix and every
new guard:

1. Revert the fix (or flip the flag, or drop the annotation).
2. Run that test. **It must go red.**
3. Restore, confirm green.

State the count in the PR doc (`14/14`, `18/18`). This is also how the suite has caught tests
that proved less than their name — e.g. `images are NOT retried` stayed green after wrapping
the call in `withRetry`, because the method never throws, so the retry wrapper was a no-op.
If mutation shows a test is vacuous, **rename it to what it actually proves** and write the
distinction down.

## Coverage

```bash
fvm flutter test --coverage        # no lcov needed; flutter_tools bundles the coverage package
```

`--coverage` only instruments libraries the run actually loaded, so the number is "of reached
lines", not "of the project". Declaration-only files (constants, barrels, abstract classes)
are simply absent from `lcov.info`. Report it honestly. The awk one-liners are in
`/flutter-verify`.

## Checklist before calling a test suite done

- [ ] File path mirrors `lib/`
- [ ] Bloc built inside the `testWidgets` body
- [ ] Every `ScrollController`/`Bloc`/`GoRouter` the test owns has an `addTearDown`
- [ ] Failure paths covered per `CatsFailure` variant, not just the happy path
- [ ] Request **counts** asserted where caching or N+1 behavior matters
- [ ] Each new guard mutation-verified
- [ ] `fvm flutter analyze` clean, `fvm dart format .` no diff
