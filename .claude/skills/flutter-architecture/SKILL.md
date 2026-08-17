---
name: flutter-architecture
description: Clean-architecture rules for this repo — where every kind of code goes, the one-way dependency direction, how to add a feature / use case / failure variant / state variant, and how to register it in get_it + injectable. Load BEFORE creating a file, moving code between layers, adding a dependency to a constructor, or touching core/injector/.
---

# Architecture rules

Three layers per feature, one direction: **`presentation → domain ← data`**.

```
lib/features/<feature>/
├── data/          datasource/ (remote + local) · models/ · repository/ (impl)
├── domain/        entities/ · repository/ (contract) · use_cases/
└── presentation/  bloc/ · pages/ · widgets/
```

## What may import what

| Layer | May import | Must never import |
|---|---|---|
| `domain/` | `injectable`, `freezed_annotation`, `core/utils`, `core/errors` | anything from `data/` or `presentation/`, `http`, `hydrated_bloc`, `flutter/material.dart` |
| `data/` | `domain/`, `core/`, `http`, `json_annotation` | `package:hydrated_bloc` (it re-exports `package:bloc`), anything from `presentation/`, `dart:io` |
| `presentation/` | `domain/`, `core/`, `flutter_bloc` | anything from `data/` — no repository, no datasource, no model |
| `core/injector/` | everything | — |

Two boundaries are enforced by types, not by discipline — keep them that way:

- **`core/storage/KeyValueStore`** exists so `data/` never sees `Bloc`/`Cubit`/`Emitter`.
  Two methods (`read`, `write`). Do not widen it "just in case"; `delete`/`clear` were added
  once and removed again because nothing called them.
- **`Injector`** is a facade. `package:get_it` is imported in **exactly one file of `lib/`**
  (`core/injector/injector.dart`). Blocs, widgets and use cases receive dependencies through
  their constructor. `Injector.resolve` is called only from `main.dart`.

## The success/failure channel

```dart
sealed class CatsResult<T> { }   // Ok<T>(value) | Err<T>(failure)
```

- One type parameter. The failure channel is always `CatsFailure`.
- **No `Either`, no `dartz`, no `fpdart`.** `either_dart` was removed in Phase 3 because
  `fold` cannot be checked for exhaustiveness and because it delegates `==` to its payload,
  so an `Either` holding a `List` compares by identity.
- `CatsResult` defines **no `==`**. Consume it with a `switch`, assert on it in two steps:
  ```dart
  expect(result, isA<Ok<List<CatBreedEntity>>>());
  expect((result as Ok<List<CatBreedEntity>>).value, equals(breeds));
  ```
- **The repository is a total function.** It catches `on CatsFailure` and then everything
  else into `Err(UnknownFailure(detail: '$error'))`. No raw exception may escape `data/`.

## Consuming a sealed type

Always an exhaustive `switch`. **Never** a `default:` or a `_` catch-all, and never an `is`
check with an implicit `else` — that is exactly what produced the infinite-spinner bug the
sealed hierarchy was introduced to kill.

```dart
emit(switch (result) {
  Ok(value: FreshBreeds(:final breeds)) => CatsLoaded(breeds: breeds, searchHistory: state.searchHistory),
  Ok(value: StaleBreeds(:final breeds, :final failure)) => CatsStale(...),
  Err(:final failure) => CatsError(failure: failure, searchHistory: state.searchHistory),
});
```

Adding a variant to `CatsFailure` or `LandingCatsState` **is supposed to break every
consumer**. Fix each site; do not silence the analyzer.

Narrow exception: a switch that merely **extracts a value** may use `_ =>` with an obvious
fallback (`landing_page.dart` does this to read `breeds` out of whichever state carries one).
A switch that decides which branch of behavior or UI runs must stay exhaustive — that is the
whole mechanism that stops an error branch from being deleted silently.

## Adding a new feature — the order that works

1. `domain/entities/` — `@freezed sealed class`, immutable, no data-layer artifacts (no
   URLs, no JSON keys, no `late`).
2. `domain/repository/` — an `abstract interface class` returning `Future<CatsResult<T>>`.
3. `domain/use_cases/` — one thin `@injectable` class per operation, constructor-injected
   repository, a single public method.
4. `data/models/` — `@freezed` + `fromJson`. It **does not extend the entity**; it exposes
   an explicit `toEntity()` mapper.
5. `data/datasource/` — throws `CatsFailure` variants, never returns them.
6. `data/repository/` — `@LazySingleton(as: <Contract>)`, converts throws into `CatsResult`.
7. `presentation/bloc/` — sealed state via freezed, dependencies through the constructor.
8. `presentation/pages|widgets/` — exhaustive `switch` over the state.
9. Register (below), regenerate, then wire in `main.dart` / `routers/`.

Run `/flutter-codegen` for steps 1, 4, 7 and `/flutter-testing` for the suite.

## DI: the registration decision table

`throwOnMissingDependencies: true` is set, so a binding that cannot be resolved is a **build
failure**, not a runtime error. That is the point of injectable here.

| Situation | How to register |
|---|---|
| Stateless wrapper (use case) | `@injectable` on the class — a factory |
| Holds state that must be shared (repository with its URL cache and in-flight map) | `@LazySingleton(as: TheContract)` — **singleton is a correctness requirement here, not an optimization** |
| Third-party type (`http.Client`) | `@LazySingleton(dispose: closeHttpClient)` in `AppModule` |
| Constructor mixes real dependencies with **test seams** (`Duration timeout`, `List<Duration> retryDelays`, `DateTime Function() clock`) | A factory method in `AppModule` naming **only** the real dependencies — otherwise injectable tries to resolve a `Duration` from the container and fails the build |
| Registered outside the generated graph (`KeyValueStore`) | Add it to `ignoreUnregisteredTypes` in `@InjectableInit` and register it in `Injector.setup` |
| Owns an OS resource (client, storage box) | Must pass a `dispose:` callback, and that callback must be a **public top-level function** — the generated config is a separate library and cannot see a private one |

Invariant with a test behind it: **every generated registration is lazy.** `init()` must
construct nothing, which is what lets `Injector.setup(httpClient:)` override the client after
`init()` in integration tests. A single `@Singleton` **consumer** anywhere in the graph breaks
that silently — `injector_test.dart` guards it.

## When you are about to break a rule

Some of these rules have already been debated and decided; the reasoning is in `README.md`
per phase. Before arguing for `Either`, for `equatable`, for `Model extends Entity`, for a
global `HydratedBloc.storage`, or for resolving from the container inside a widget, grep the
changelog for that decision. If the reasoning no longer holds, say so explicitly in the PR
doc's "Honest notes" — do not revert it silently.
