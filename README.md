# Catbreeds

A cat breeds app built on [TheCatAPI](https://thecatapi.com) with Flutter and clean architecture.

Three screens: **Splash** → **Landing** (breed list) → **Detail** (breed profile).

---

## Project status

This repository is under **active modernization**: it started on Flutter 3.16.7 and is being brought to **Flutter 3.44.9** in independent phases, each one compilable, testable and reviewable on its own.

> **A note on the target version:** the original request was "Flutter 3.40", but **3.40 never shipped as stable** — it only existed as `3.40.0-0.1.pre` and `3.40.0-0.2.pre` on the beta channel in Dec 2025. The stable line went `3.38.10` → `3.41.0` (Feb 2026) → `3.44.9` (Aug 2026). The target is **3.44.9 stable**.

### Roadmap

| # | Phase | Status |
|---|---|---|
| 0 | Hygiene, baseline and `.gitignore` | ✅ Done |
| 1 | Toolchain 3.44.9 with fvm (no refactors) | ✅ Done |
| 2 | Testability seams + regression suite + bug fixes | ✅ Done |
| 3 | Dart 3: sealed classes + pattern matching | ⬜ Pending |
| 4 | Data layer: freezed, immutable entity, N+1, secrets | ⬜ Pending |
| 5 | DI: kiwi → get_it + injectable | ⬜ Pending |
| 6 | Persistence: hydrated_bloc + TTL cache | ⬜ Pending |
| 7 | Design system: Material 3 ThemeData, tokens, dark mode, l10n | ⬜ Pending |
| 8 | Real adaptive layout (drop `flutter_screenutil`) | ⬜ Pending |
| 9 | Dedupe, reusable components, CI and coverage | ⬜ Pending |

The order is not arbitrary. The SDK upgrade goes first because the other way around is **impossible**: `freezed 3.x`, `injectable 3.x` and `flutter_lints 6` require Dart ≥3.8, and `hydrated_bloc 11` requires `bloc ^9`, while Flutter 3.16.7 ships Dart 3.2 — `pub get` simply fails. Tests land in Phase 2 rather than at the end, because Phases 3-8 are precisely the ones that change behavior silently, and doing them without a regression net would be guesswork.

---

## Architecture

Clean architecture per feature, with the three layers kept separate:

```
lib/
├── core/                      # Cross-cutting: shared widgets, helpers, DI, theme
│   ├── common_widgets/        # Reusable components
│   ├── config/                # Helpers, endpoints, responsive, theme
│   ├── injector/              # Dependency injection (kiwi → get_it in Phase 5)
│   └── utils/                 # Pure helpers (bounded-concurrency map)
├── features/
│   ├── splash/
│   ├── landing_cats/
│   │   ├── data/              # datasource · models · repository (impl)
│   │   ├── domain/            # entities · repository (contract) · use_cases
│   │   └── presentation/      # bloc · pages · widgets
│   └── detail_cat/
└── routers/                   # go_router
```

- **State:** BLoC (`flutter_bloc`), with the use case injected through the constructor
- **Navigation:** `go_router`, declarative nested routes
- **Errors:** `Either<Failure, Success>` (`either_dart`)
- **DI:** `kiwi`, hand-written registrations (migrates to `get_it` + `injectable` in Phase 5)
- **Tests:** `flutter_test` + `bloc_test` + `mocktail`, plus `MockClient` from `package:http/testing.dart` at the HTTP boundary

---

## Requirements

| | Version |
|---|---|
| Flutter | **3.44.9** (stable) |
| Dart | **3.12.2** |
| JDK (Android only) | **17** or **21** — LTS |
| Xcode (iOS/macOS only) | 26.x |
| Supported platforms | Android · iOS · macOS · Web |

The Flutter version is managed with **[fvm](https://fvm.app)**, not with the global Flutter install. The SDK is pinned in `.fvm/fvm_config.json`.

```bash
# Install fvm if you do not have it
brew tap leoafarias/fvm && brew install fvm

# Install and activate the version pinned by the project
fvm install
fvm flutter --version    # should report 3.44.9
```

**Important:** always use the `fvm` prefix, so commands run against the pinned version and not against whatever Flutter is on your `PATH`:

```bash
fvm flutter pub get
fvm flutter run
fvm flutter test
fvm flutter analyze
fvm dart format .
```

> There is no codegen step: `build_runner` was removed in Phase 2 (see the changelog). It returns in Phase 3/4 with `freezed`.

### JDK for Android

AGP 8.x requires JDK 17+. If your default `java -version` is neither 17 nor 21, point at it explicitly:

```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
fvm flutter build apk --debug
```

---

## Running

```bash
fvm flutter pub get

fvm flutter run                 # default device/simulator
fvm flutter run -d macos        # resizable window: useful for testing breakpoints
fvm flutter run -d chrome
```

---

## Testing

```bash
fvm flutter test                                    # whole suite
fvm flutter test test/features/landing_cats/data    # one subtree
fvm flutter test --plain-name "66 requests"         # one case
fvm flutter test --reporter expanded                # when triaging
```

**Coverage** (no `lcov` needed: `flutter test --coverage` bundles the `coverage` package inside `flutter_tools`):

```bash
fvm flutter test --coverage

# total
awk -F: '/^LF:/{f+=$2} /^LH:/{h+=$2} END{printf "%d/%d = %.1f%%\n", h, f, 100*h/f}' coverage/lcov.info

# per file, worst first
awk -F: '/^SF:/{f=$2} /^LF:/{lf=$2} /^LH:/{lh=$2} /^end_of_record/{printf "%6.1f%%  %s\n", (lf?100*lh/lf:0), f}' \
  coverage/lcov.info | sort -n
```

### How the suite is organized

`test/` mirrors `lib/`. Three pieces of the harness are worth knowing before you write a new test.

**`test/flutter_test_config.dart`** — Flutter discovers it automatically and runs it once per test file. It disables `google_fonts` runtime fetching (otherwise every widget test tries the asset bundle, then `path_provider`, then HTTP, and spews a wall of `debugPrint` — because **every** screen uses `TextWidget` → `GoogleFonts.acme`), configures `ScreenUtil` (without it any `.w`/`.h` throws `LateInitializationError`), and enables `EquatableConfig.stringify` so a failing `blocTest` shows which field differs.

**Two zone gotchas, both the same shape, both encapsulated in helpers:**

- **`PumpApp.buildBloc` — build the bloc inside the `testWidgets` body, never in a `setUp`.** `setUp` runs outside `testWidgets`' `FakeAsync` zone, so the bloc's internal microtasks stay bound to the real zone, `pump`/`pumpAndSettle` never drain them, the state stays stuck on `FormSubmitting`, and `pumpAndSettle` ends in *timed out*.
- **`ignoreOverflowErrors()` — same rule**, because `testWidgets` installs its own `FlutterError.onError` after the `setUp` callbacks run.

On that overflow helper — measured, not assumed: under `flutter test` there is no Acme font, so Flutter uses its test font, where **every glyph is a full em square**. `Text('Intelligence:', fontSize: 20)` measures exactly **260 px** in tests (13 chars × 20) against roughly 130 px with real Acme, which overflows the `SizedBox(width: 190.w)` that `CardCatWidget` gives the nested `BreedCharacteristicWidget`. **This is a font-metrics artifact, not a layout bug — the app does not overflow.** Phase 7 bundles the font and Phase 8 audits layout for real; the helper should disappear there.

**Fixtures.** `test/fixtures/breeds_full.json` is the real TheCatAPI payload captured on **2026-08-10**: 67 breeds, of which exactly 2 (`European Burmese`, `Malayan`) carry no `reference_image_id`. The trimmed variants are derived mechanically from that file; only four are hand-written, because the live API never produces them (`weight: null`, null `imperial`/`metric`, an empty array, and an image response with no `url` key).

---

## Modernization changelog

### Phase 0 — Hygiene and baseline

Cleanup ahead of the upgrade, so no dead code had to be migrated.

**Removed (0 usages, verified by grep):**
- `core/config/helpers/responsive/responsive_box.dart` and `context_responsive_extension.dart` — the "responsive system" the previous README advertised, with **zero** call sites anywhere in `lib/`.
- The `isMobile` / `isAppleDevice` / `isDesktop` getters in `responsive.dart`. Besides being unused, `isAppleDevice` and `isDesktop` called `Platform.isMacOS` **without a `kIsWeb` guard**, so they would have thrown on web (`isMobile` did have the guard — the inconsistency was the bug). Removing them also drops `dart:io` from the file.
- `AppCatsResponsiveApp.designSizeLarge` — declared and never referenced.
- `AppCatsColor.lightBlue` — unused, and it also removed a `Colors.blue.value` that is deprecated in modern Flutter (→ `toARGB32()`).
- `url_launcher` (the dependency, the import, and `DetailCatPage.openUrl()`, which was never invoked) plus an unused `google_fonts` import in the same file.

**Fixed:**
- App identity. The `MaterialApp` `title` read `'enMedallo'` — copy-paste from another project. And the `applicationId` / `PRODUCT_BUNDLE_IDENTIFIER` was `com.example.*`, which **Google Play rejects**. Now `com.jhonzuluaga.catbreeds`, with the Kotlin package moved accordingly. The display name is unified to "Catbreeds" in `AndroidManifest.xml` and `Info.plist`.
- Added `.gitignore`, which **did not exist** (the repo tracked 104 unfiltered files). It covers `coverage/`, `env/*.json` (secrets via `--dart-define-from-file`, Phase 4), `.fvm/versions/` and `**/failures/` (failed goldens, Phase 8).

**Deliberately left alone:** the `"LigthGreen"`/`"LigthGrey"` typos in `AppCatsColor` and kiwi's `_configureAuthsModule` naming. Those files are deleted in Phases 5 and 7 — fixing them now would be pure churn.

### Phase 1 — Toolchain 3.44.9

A **pure** upgrade: zero architectural changes, so a native toolchain failure could not be confused with a refactor of our own. It goes first because the other way around is impossible — `freezed 3.x`, `injectable 3.x` and `flutter_lints 6` require Dart ≥3.8 and `hydrated_bloc 11` requires `bloc ^9`, while 3.16.7 shipped Dart 3.2.

**SDK and dependencies.** `.fvm/fvm_config.json` from `3.16.7` → `3.44.9`; `environment` to `sdk: ^3.12.0` / `flutter: '>=3.44.0'`. Versions were resolved with `pub upgrade --major-versions` rather than pinned by hand: `flutter_bloc` 8→**9.1.1**, `go_router` 13→**17.4.0**, `google_fonts` 5→**8.2.1**, `kiwi` 4→**5.0.1**, `flutter_lints` 2→**6.0.0**.

One relevant side effect: resolution **dropped `win32 5.2.0`** from the tree. That transitive dependency (via `google_fonts` → `path_provider`) used `UnmodifiableUint8ListView`, removed in Dart 3.4, and on its own made the project impossible to compile on any modern Flutter.

`kiwi_generator` still held `analyzer` at 6.4.1 against the 14.1.0 available; codegen worked. (That debt was settled earlier than planned: Phase 2 had to remove the generator because it blocked `bloc_test` entirely.)

**Dart APIs.** `flutter analyze` reported only 6 `info` and **zero errors** — the code held up well across a 28-minor-version jump. Five were resolved by `dart fix --apply` (`MaterialStatePropertyAll` → `WidgetStatePropertyAll`, super parameters in `CatBreedModel`, type annotations in the splash). The sixth was fixed by hand, and it is the most important behavior change of the phase:

> **The accessibility override was removed.** `app_cats_responsive.dart` wrapped the app in `MediaQuery(...copyWith(textScaleFactor: 1.0, boldText: false))`. It was **not** migrated to `TextScaler`: the purpose of that code was to cancel the system's text scaling and bold-text settings, i.e. to disable two of the user's accessibility preferences. Migrating it would have preserved the bug with newer syntax. It was deleted. For the same reason an `alwaysUse24HourFormat: false` in `main.dart` was dropped — it ignored the locale to format times the app never displays.
>
> **Expected consequence:** the app now respects the OS font size, which **will expose real layout overflows**. Fixing those is Phase 8's job, where it is tested at 1.0 / 1.5 / 2.0.

`useInheritedMediaQuery` was also removed from `ScreenUtilInit` (a workaround for Flutter <3.10, a no-op today), and `dart format` was applied — `dart_style` 3.x reformatted 24 files.

**Android toolchain.** From AGP 7.3.0 / Gradle 7.5 / Kotlin 1.7.10 / Java 8 to **AGP 8.11.1 / Gradle 8.14 / Kotlin 2.2.20 / Java 17**. Also: `compileSdkVersion` → `compileSdk`, the `buildscript {}` block with the manual Kotlin classpath was deleted, `rootProject.buildDir` → `layout.buildDirectory` (the mutable property is gone in Gradle 9), and `android.enableJetifier` was removed (dropped in AGP 8, and only useful for pre-AndroidX dependencies this project does not have). The `localProperties` boilerplate for reading `versionCode`/`versionName` was also deleted — the Flutter Gradle Plugin already exposes both.

> **Why AGP 8.11.1 and not 9.0.1.** The Flutter 3.44.9 template ships AGP 9.0.1 / Gradle 9.1.0 / Kotlin 2.3.20 in Kotlin DSL. But Flutter's own `DependencyVersionChecker` errors below AGP 8.6 / Gradle 8.7 / KGP 2.0 and warns below AGP 8.11.1 / Gradle 8.14 / KGP 2.2.20. Picking the warning thresholds leaves the build **warning-free** without dragging in an AGP major or a `.kts` conversion — which would contradict this phase's mandate of being a pure upgrade with a reviewable diff. AGP 9 + Kotlin DSL is a deliberate follow-up.

Two things the modern template ships that this project was missing: `android:taskAffinity=""` on `MainActivity`, and the `<queries>` block for `PROCESS_TEXT` that the engine's `ProcessTextPlugin` needs.

**iOS.** Deployment target 12.0 → **13.0** (`project.pbxproj`, `AppFrameworkInfo.plist`) and `platform :ios, '13.0'` enabled in the `Podfile`. Flutter also applied its automatic migrations: `@UIApplicationMain` → `@main` and the scheme's `customLLDBInitFile`.

**New platforms: macOS and Web.** The project only had `android/` and `ios/`, so Phase 8's *expanded* breakpoint and `NavigationRail` were impossible to demonstrate. With macOS you can resize the window from 390 to 1440 px and watch the breakpoints live. Identity was aligned with Phase 0 (`Catbreeds`, `com.jhonzuluaga.catbreeds`).

**Verified:** `analyze` with no issues, `dart format` with no diff, and **all four** platforms build — `build apk --debug`, `build ios --no-codesign`, `build macos --debug`, `build web`.

**An honest note on the baseline.** Phase 0 planned screenshots of the app running on 3.16.7 as a visual reference. That turned out to be impossible: Flutter 3.16.7 (Jan 2024) does not build against Xcode 26.6, and the original `pubspec.lock` pinned `win32 5.2.0`, which does not even compile on modern Dart — the project **as committed was not buildable** in a current environment. The visual reference was therefore taken at the end of this phase (post-upgrade, pre-redesign), which actually isolates the Phase 7 and 8 changes better, since it does not mix in SDK differences.

### Phase 2 — Testability seams, regression suite and bug fixes

The project had no tests, but the underlying problem was different: **it was untestable by construction.** `LandingCatsBloc()` took no arguments and resolved its own dependency with `Injector.resolve` inside the constructor, so any bloc test would have booted the real container and hit the real network. The datasource called the top-level `http.get`, so there was nowhere to inject a fake client. And nothing had value equality — not the state, not the events, not the entities — so `bloc_test`'s `expect:` lists could never have matched.

This phase opens those seams, fixes the bugs that surfaced while writing the tests, and lands the regression net that protects Phases 3 through 9. It deliberately keeps kiwi, hand-written JSON and `flutter_screenutil`: the diff has to stay small and attributable.

**Result: 118 tests across 19 files, `analyze` clean, 96.6% of reached lines covered.**

#### Removing `kiwi_generator` was mandatory, not optional

Adding `bloc_test` **fails dependency resolution** while the generator is in the tree:

| Fact | Consequence |
|---|---|
| `flutter_test` (3.44.9) pins `test_api: 0.7.11` **exactly**, not a range | — |
| The only `test` version depending on `test_api 0.7.11` is `test 1.31.0` | — |
| `test 1.31.0` requires `analyzer >=8.0.0 <13.0.0` | — |
| `kiwi_generator 4.2.1` requires `analyzer ^6.0.0` | intersection is **empty** |

So `kiwi_generator` and `build_runner` were removed and the registrations were hand-written: `injector.g.dart` was 26 trivial lines, and the `@Register` annotation lives in `kiwi` (not in the generator), so nothing broke at the import level. **`kiwi` stays.** `build_runner` returns in Phase 3/4 for `freezed`, with `source_gen ^2` and a modern analyzer — a bill that was going to be paid there anyway.

Along the way the `Injector` gained three things the tests needed: `setup()` now clears before registering (kiwi **throws** `KiwiError` on duplicate registration, so a second `setup()` in the same isolate crashed — which is exactly what happens with more than one test file), a `reset()` for isolation, and `http.Client` registered as a **singleton** instead of every datasource resolve building its own connection pool. That singleton is also the seam that makes `test/app_test.dart` possible.

`static final resolve = container.resolve;` is gone too: it was a tear-off captured at class-initialization time, so reassigning `Injector.container` in a test would have been silently ignored.

#### The seams

| Before | After |
|---|---|
| `LandingCatsBloc()` + `Injector.resolve` in the constructor body | `LandingCatsBloc({required GetAllCatsUseCase getAllCatsUseCase})`, resolved in the composition root. The bloc no longer imports the injector. |
| top-level `http.get` | `LandingCatsDataSource({http.Client? client, Duration timeout, int imageConcurrency})` |
| No value equality anywhere | `equatable` on state, events, `FormSubmissionStatus`, `InvalidData` and entities |
| `late String urlImage` mutated by the datasource | `final String urlImage`, resolved **before** the model is built |
| `AppRoute.globalGoRouter` static mutable singleton, 3 calls inside `build` | `AppRoute.router({initialLocation})` + a single `routerConfig` |
| Nullable state lists with four `state.listAllCats![index]` force-unwraps | Non-nullable lists defaulting to `const []` |

Two non-obvious consequences that value equality dragged in:

- **`SubmissionFailed.props` uses `exception.toString()`, not `exception`.** `Exception('boom')` builds a `_Exception` that defines no `==`, so two identical `SubmissionFailed` instances would never compare equal and the whole failure path would have to be asserted with matchers instead of concrete states.
- **`Equatable` is annotated `@immutable`**, so `must_be_immutable` turns the `late String urlImage` and `InvalidData`'s mutable fields into warnings: making them `final` is a *requirement* of Equatable, not a separate decision. And `prefer_const_constructors_in_immutables` from `flutter_lints 6` forces `const` on the ~10 new classes — which is exactly what makes `blocTest.expect` readable.

#### The search history: a bug Equatable would have made invisible

`search_delegate_all_catbreeds.dart` did `filterNamesSearched.add(query)`, and that list **was the same instance** living in `state.namesAlreadySearched`. It then dispatched an event carrying that same instance, and the handler emitted `copyWith(namesAlreadySearched: sameInstance)`.

It worked by accident: `emit` compared state object identity and notified. **The moment `LandingCatsState` extends `Equatable`, the props compare deep-equal and `emit` silently drops the state** — the feature dies with zero errors and zero failing tests. That is why these changes land together:

- `AddNameAlreadySearchedEvent` carries a `String name`, not the whole list.
- Trim and dedupe moved out of the widget and into the bloc, which emits a **new** `List.unmodifiable`. Any future attempt to mutate state from a widget now fails on the exact offending line.
- The event is dispatched from `showResults`, not from `buildResults` — which *is* a build method and only survived because `bloc.add` is asynchronous.
- With the side effect gone, `buildResults` and `buildSuggestions` became identical and collapsed into one.
- The history is now read from the bloc via a `BlocBuilder`. It previously arrived immutable through the constructor, so it **did not update live**: searching and then clearing the query did not show the term just searched.

#### Network consumption: 68 requests → 66, sequential → concurrent

`/breeds` returns 67 breeds and none carries an image, so each one has to be resolved separately. The old code made **68 strictly sequential requests** before first paint, and 2 of them were `GET /v1/images/` **with no id** — because `European Burmese` and `Malayan` have no `reference_image_id` — which the API answers with **400** and the `else` branch swallowed.

Now: empty ids are skipped (**66** requests, a number asserted against the real payload) and images resolve through a new `mapWithConcurrency` helper with 6 in flight. From ~67 serial round-trips to ~11 batches. `Future.wait` over all 67 was rejected: it would fix latency by creating a rate-limit problem. Input order is preserved by writing into an indexed buffer, not by appending in completion order.

> Phase 4 removes the N+1 at the root: `getAllCats` will make **1** request and each card will resolve its own image on demand.

**Intentional behavior change:** `_imageUrlFor` no longer throws. Previously a network failure on *any* of the N image requests aborted all 67 breeds; now that breed gets `urlImage: ''` and the list still renders. With concurrency there is a second reason: a `Future.wait` with two errors leaves one unhandled.

#### Correctness fixes

Each one with its test, and **each test verified by reverting the fix**:

| File | Bug |
|---|---|
| `landing_cats_data_source.dart` | The `try` started **after** the first `http.get`, so a `SocketException` on `/breeds` escaped raw: the repository's `on InvalidData` did not catch it and the bloc's `fold` never ran. |
| `landing_cats_data_source.dart` | The general `catch` also caught the `throw InvalidData` from the status check and **re-wrapped it**: the message ended up as `"Service error: Instance of 'InvalidData'"`. Fixed with `on InvalidData { rethrow; }`. |
| `landing_cats_data_source.dart` | No timeout. Now `.timeout(10s)`, injectable. |
| `landing_cats_data_source.dart` | `catBreedModel.urlImage = mapInfo["url"]` — an unchecked dynamic cast into a non-nullable `String`, while mutating the domain entity. |
| `catbreed_model.dart` | `weight` was the **only** mapped field with no null guard: a payload missing that key threw `TypeError`. Same for `imperial` and `metric`. |
| `splash_catbreeds.dart` | `Timer? timer` was declared and **never assigned** — `startTimer()` was pointlessly `async` and returned the `Timer` inside a `Future` nobody read. A live timer with no reference, impossible to cancel. Plus no `dispose()` and no `mounted` guard. |
| `text_widget.dart` | `textAlign` declared and never forwarded to the `Text`: both call sites that passed it were no-ops. |
| `landing_page.dart`, `detail_cat_page.dart` | Leaked `ScrollController`. **`grep -rn "dispose" lib/` returned zero** across the entire project. |
| `search_delegate_all_catbreeds.dart` | **One** `ScrollController` shared by both list views, which coexist during the 300 ms `AnimatedSwitcher` cross-fade in `_SearchPageState`, and never released: one leak per tap on the search icon. |
| `app_route.dart` | `(state.extra!) as CatBreedEntity` crashed with a red-screen `TypeError` on any deep link to `/home/detail` (Android app link, web URL) or on process restoration. |
| `list_characteristecs_catbreeds_widget.dart` | Two parallel lists indexed together, with the loop bound taken only from the labels list: a label without its value was a `RangeError`, and extra values were silently dropped. |
| `landing_page.dart` | `state.listAllCats![index]` in four places. |
| `landing_page.dart` | `BlocProvider.of` before `super.initState()`. |

An honest note on the shared `ScrollController`: **it is not a crash today.** `ScrollController` tolerates multiple attached positions; the assertion lives only in the `position` getter, reached via `.offset` / `.jumpTo` / `Scrollbar`, and the delegate has no `Scrollbar`. It is a latent hazard plus the leak. It becomes a crash the moment Phase 7 or 8 wraps that list in a `Scrollbar`.

And the fix was not "two controllers". The rule is **dispose where a dispose hook exists, don't own where none does.** The pages are `StatefulWidget`s → `dispose()`. `SearchDelegate` has no hook → the field was deleted and each `ListView` gets `primary: false` with no controller. That `primary: false` is not cosmetic: `ScrollView` computes `primary ?? controller == null && shouldInherit(...)`, every `ModalRoute` provides a `PrimaryScrollController`, and under `flutter test` `defaultTargetPlatform` is android — so without it both lists would go right back to sharing the route's controller, the same bug with a different owner.

#### Extracting the only real business logic

`SearchCatBreedsUseCase` replaces a filter that was duplicated **literally** (same code, different lambda name: `listEvent` in one method, `customAlbum` in the other — a copy-paste leftover from an album app) across `buildResults` and `buildSuggestions`. It also adds the missing `trim()`. It is not registered in the container: it has no dependencies, and registering it would force every search-delegate widget test to call `Injector.setup()`.

#### Assertion style

`bloc_test` with **concrete states**, not matchers: `const LandingCatsState().copyWith(...)`. This works because Equatable routes `Iterable` props to deep comparison.

One trap worth documenting: **`either_dart` delegates `==` to the payload, and a `List` payload compares by identity.** `expect(result, Right(expectedList))` passes or fails for the wrong reason. Use `expect(result.isRight, isTrue)` + `expect(result.right, equals(expected))`. With `Left` the direct comparison is fine, because the payload is a single Equatable object.

And one asymmetry the suite pins on purpose: `Equatable.operator ==` compares `runtimeType`, so **`CatBreedModel != CatBreedEntity`** even with all 40 fields identical. Since the repository upcasts without converting, the runtime elements of the state are always `CatBreedModel`; that is why every builder returns models. A dedicated test fixes that asymmetry, and it is the canary for Phase 4, when `Model extends Entity` goes away.

`MockClient` at the HTTP boundary (URL routing, different bodies per endpoint, and request **counting** are all needed, and it exercises the real `BaseClient.get → send` path); `mocktail` at every architectural boundary above it. In `landing_page_test` the **real bloc** is used with a mocked use case: a `MockBloc` there would let a broken bloc pass.

#### Verification

- `fvm flutter analyze` → no issues. `fvm dart format` → no diff.
- `fvm flutter test` → **118 tests passing**.
- **14 of 14 fixes verified by reverting**: each one was reverted and its test confirmed failing. That is what separates a suite that is evidence from one that is decoration.
- Coverage: **535/554 = 96.6%** of reached lines. Honest caveat: `--coverage` only instruments libraries the run actually loaded, so this is "of reached lines", not "of the project" — the 6 files absent from `lcov.info` are declaration-only (constants, an `abstract class`, barrels). No gate is added: Phase 9 owns that.
- `test/app_test.dart` boots the real app with an injected `MockClient` and walks splash → landing → detail → back. It is the only test proving DI + router + bloc + datasource are wired together, and the first one Phases 3-9 will break.

#### Deliberately not done

| Item | Phase |
|---|---|
| The **infinite spinner** when the API fails — there is no error branch anywhere. Left in place, with a **characterization** test pinning current behavior so Phase 3's diff makes it visible. | 3 |
| `freezed`, killing `Model extends Entity`, the root N+1 fix (1 request), moving the API key out of the code, retry with backoff | 4 |
| `get_it` + `injectable`, singleton repository | 5 |
| `hydrated_bloc`, TTL cache, killing the `initState` refetch, route-by-id instead of `extra` | 6 |
| Design system, Material 3 `ThemeData`, l10n (extracting the hardcoded strings to ARB), bundling the Acme font | 7 |
| Dropping `flutter_screenutil`, real adaptive layout, goldens | 8 |
| Hardening `analysis_options.yaml` (currently a bare `include:`), CI, coverage gate | 9 |

#### Language normalization

The repository is now **English-only**: every doc comment, inline comment, test
name, fixture literal and configuration comment across `lib/`, `test/`,
`pubspec.yaml`, `.gitignore`, the Android Gradle files and this README. Two
data-layer strings changed with it — `"Error al llamar el servicio"` became
`"Service request failed"`, and `"Este es el error del servicio: $error"` became
`"Service error: $error"` — and their assertions moved too. Phase 7 still owns
extracting these strings into ARB files; it just no longer has two languages to
reconcile first.

The `api-key` header name is still the wrong one — TheCatAPI expects `x-api-key`, so these requests **were never authenticated** — but it was hoisted into `Endpoints.authHeader` so Phase 4's `--dart-define-from-file` migration is a one-line change.
