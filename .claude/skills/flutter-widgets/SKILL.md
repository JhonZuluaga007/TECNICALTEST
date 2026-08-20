---
name: flutter-widgets
description: Presentation-layer rules for this repo — disposal ownership, no side effects in build, rebuild scope with BlocBuilder/buildWhen, exhaustive state rendering, failure-to-copy mapping, image resolution per card, and the flutter_screenutil situation. Load BEFORE writing or editing anything under presentation/ or core/common_widgets/.
---

# Widgets and presentation

## Disposal: own it only where a dispose hook exists

The rule, learned the hard way (`grep -rn "dispose" lib/` once returned **zero** across the
whole project):

- `StatefulWidget` → it has `dispose()`; it may own a `ScrollController`, `TextEditingController`,
  `Timer`, `AnimationController`. Cancel/dispose every one of them, and guard `setState` with
  `mounted` after any `await`.
- `SearchDelegate` → **no dispose hook**. It must not own a controller at all. Each `ListView`
  gets `primary: false` and no controller.
- `GoRouter` built in a `State` → `_router.dispose()`.

`primary: false` there is not cosmetic. `ScrollView` computes
`primary ?? controller == null && shouldInherit(...)`, every `ModalRoute` provides a
`PrimaryScrollController`, and under `flutter test` `defaultTargetPlatform` is android — so
without it two lists silently share the route's controller, which is the same bug with a
different owner.

## No side effects in `build`

- Never `bloc.add(...)`, never mutate state, never start a request from a `build` method.
  It only ever "worked" because `bloc.add` is asynchronous.
- Dispatch from an event handler (`showResults`, `onPressed`), from `initState`, or — for a
  fetch that must survive page rebuilds — from where the bloc is **created**, in the
  composition root. `go_router` re-creates a page on every back navigation; an `initState`
  fetch means a network round trip per press of back.
- `BlocProvider(lazy: false)` is required when the bloc must start working before any widget
  reads it (e.g. fetching during the splash). The default builds on first read.

## State never mutates from a widget

The search history bug: the widget did `list.add(query)` on the **same instance** held by the
state, then dispatched it back. With value equality, `emit` compares deep-equal and silently
drops the state — the feature dies with zero errors and zero failing tests.

- Events carry the **minimum**: `AddNameAlreadySearchedEvent(String name)`, not the whole list.
- Trimming, deduping and ordering live in the bloc.
- The bloc emits a **new** `List.unmodifiable(...)`, so any future attempt to mutate state
  from a widget throws on the offending line.

## Rendering a sealed state

Exhaustive `switch`, no `default`, no `is` check with an implicit `else`:

```dart
switch (state) {
  CatsInitial() || CatsLoading() => const CatsLoadingView(),
  CatsLoaded(breeds: []) => const CatsEmptyView(),      // list pattern, before the general case
  CatsLoaded(:final breeds) => _list(breeds),
  CatsStale(:final breeds, :final failure) => _list(breeds, banner: failure),
  CatsError(:final failure) => CatsErrorView(failure: failure, onRetry: ...),
}
```

`CatsEmptyView` exists because a successful request with zero breeds used to render an empty
`ListView` — a blank screen indistinguishable from a broken app. Keep the empty case.

The one place a `_ =>` is acceptable is a switch that **extracts a value** with an obvious
fallback, not one that chooses what to render:

```dart
final breeds = switch (state) {
  CatsLoaded(:final breeds) || CatsStale(:final breeds) => breeds,
  _ => const <CatBreedEntity>[],          // fine: "no breeds yet" is the only other answer
};
```

In a switch that picks a branch of the UI, a `_` is how the error branch gets deleted by
accident. Keep those exhaustive.

Status views (`CatsLoadingView`, `CatsEmptyView`, `CatsErrorView`) are **public and
bloc-free** (`CatsErrorView` takes an `onRetry` callback), so widget tests can pump them in
isolation and match `find.byType(CatsErrorView)` instead of copy that Phase 7 will move.

## Failure-to-copy mapping lives in presentation

`CatsFailure.detail` is a **technical** description for tests and logging — never user-facing
copy. The mapping is `messageFor` in `landing_status_views.dart`, and it uses guard clauses
where the status code changes the meaning:

```dart
ServerFailure(:final statusCode) when statusCode == 401 || statusCode == 403 =>
  'Could not authenticate with the cat service.',
```

`NotFoundFailure` must read as "this breed does not exist", not "the request failed" — there
is nothing to retry, so do not offer a retry button for it.

## Per-card work goes in its own cubit

Each card resolves its own image through `BreedImageCubit` (`loading` / `ready(url)` /
`unavailable`). Two things that keep it correct:

- `if (isClosed) return;` after every `await` before an `emit`.
- Deduplication and caching live in the **repository** (`_urlCache` + `_inFlight`), which is
  why it is a `@LazySingleton`. Do not move that into the cubit — one cubit per card means
  one cache per card, i.e. no cache.
- An empty `referenceImageId` short-circuits to `unavailable`; it must never become a request
  (`GET /v1/images/` with no id answers 400).

The use cases a card needs come from the widget tree (`RepositoryProvider`), not from
`Injector.resolve` — that is what keeps widget tests from having to boot the real DI graph.

## Rebuild scope

- `const` constructors everywhere they are possible; `flutter_lints 6`'s
  `prefer_const_constructors_in_immutables` enforces it on immutable classes and it is also
  what makes `blocTest.expect` readable.
- Prefer `BlocBuilder` scoped to the smallest subtree over one at the top of the page. Use
  `buildWhen` when a state field is orthogonal to what the widget renders (e.g. `searchHistory`
  changing must not rebuild the breed list).
- `BlocSelector` when the widget needs one field of a large state.
- Extract widgets into classes rather than `Widget _buildX()` methods — a class gets its own
  element and can be `const`; a method cannot.

## Accessibility — do not re-add the overrides

`MediaQuery(...copyWith(textScaleFactor: 1.0, boldText: false))` was **deleted**, not migrated
to `TextScaler`: its purpose was to cancel two of the user's accessibility settings. Same for
`alwaysUse24HourFormat: false`. If a layout breaks at large text, fix the layout.

## Sizing and breakpoints

`flutter_screenutil` is **gone** (Phase 8). Do not reintroduce `.w`/`.h`/`.sp`, and do not add
a `MaterialApp.builder` that configures a global from inside `build`.

- **Spacing** comes from `AppSpacing` (`core/design_system/spacing.dart`): `xs` 4, `sm` 8,
  `md` 12, `lg` 16, `xl` 24. Constant at every window size — what adapts is the layout, not
  the size of a gap. `flutter_screenutil` multiplied every gap by `width / 390`, so a 12 px
  gutter became 33 px on a desktop window.
- **Layout** reads `WindowSize.of(context)` (`core/design_system/breakpoints.dart`):
  compact / medium / expanded / large at 600 / 840 / 1200, with `columns` 1/2/3/4. The landing
  screen renders a `ListView` at one column and a `GridView` above it — deliberately not a
  one-column grid, which would force every card to the same height.
- **A cap on line length is not a breakpoint.** The detail screen constrains its description
  to 720 px with a `ConstrainedBox`, because the reason is typographic and applies at whatever
  width it happens to be reached.
- **Text scale is the user's setting, and layouts must survive it.** Measured in Phase 8:
  `CardCatWidget` overflowed by 37 px at scale 2.0 on a phone. The fix was a `Wrap`, not a
  breakpoint — it reacts to the size the text actually took. New layouts get a test at
  1.0 / 1.5 / 2.0.
