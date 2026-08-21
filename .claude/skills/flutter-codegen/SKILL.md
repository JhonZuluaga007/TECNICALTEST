---
name: flutter-codegen
description: freezed 3.x, json_serializable and injectable code generation in this repo — the abstract-vs-sealed rule, build.yaml settings that are load-bearing, the analyzer pin, build_runner commands, and the stale-generated-file trap. Load BEFORE editing any class annotated @freezed, @injectable, @LazySingleton or with a fromJson factory.
---

# Code generation

Generated files are **committed**: `*.freezed.dart`, `*.g.dart`, `injector.config.dart`. A
fresh clone must build without running the generator.

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

Then commit source **and** generated file in the same commit. Verify nothing drifted:

```bash
git diff --exit-code -- '*.freezed.dart' '*.g.dart' '*.config.dart'
```

That check exists because it has already bitten: a mutation run restored a source file but
left `injector.config.dart` stale, and the suite failed on a registration that was plainly
present in the source. **CI detects it now** — `.github/workflows/ci.yml`'s "Generated files are
not stale" step runs the two commands above on every push, so a forgotten regeneration is a red
build rather than a confusing local failure.

## freezed 3.x — `abstract` vs `sealed`

freezed 3 requires the class modifier, and which one you pick is not cosmetic:

```dart
// ONE constructor — a data class
@freezed
abstract class CatBreedEntity with _$CatBreedEntity {
  const factory CatBreedEntity({ @Default('') String id, ... }) = _CatBreedEntity;
}

// SEVERAL constructors — a union you will switch over exhaustively
@freezed
sealed class BreedsSnapshot with _$BreedsSnapshot {
  const factory BreedsSnapshot.fresh({required List<CatBreedEntity> breeds}) = FreshBreeds;
  const factory BreedsSnapshot.stale({
    required List<CatBreedEntity> breeds,
    required CatsFailure failure,
  }) = StaleBreeds;
}
```

Rules that this codebase depends on:

- **Name every variant explicitly** (`= FreshBreeds`, `= CatsLoaded`) — never `= _Fresh`.
  Consumers pattern-match on those names.
- `sealed` is what makes a `switch` exhaustiveness-checked. Adding a variant is *supposed* to
  break every consumer.
- freezed generates `==`, `hashCode`, `toString`, `copyWith` and — when a `fromJson` factory
  is declared — `toJson`. **`equatable` was removed in Phase 4 precisely because it duplicated
  this.** Do not add it back.
- A `@freezed` class implementing `Exception` puts `implements Exception` on the **base**
  (`CatsFailure`), not on each variant, so `on CatsFailure` catches all of them.

## json_serializable — `build.yaml` is load-bearing

```yaml
json_serializable:
  options:
    field_rename: snake        # TheCatAPI is snake_case; saves ~20 @JsonKey annotations
    explicit_to_json: true     # REQUIRED, not a preference
```

`explicit_to_json` is not style. Without it the generator emits `'weight': instance.weight` —
the nested `WeightModel` **object** instead of its map — so `toJson()` produces something
`fromJson` cannot read back. It appeared to work only because `json.encode` calls `toJson` on
unknown objects for you; anything handling the map directly (which is what `hydrated_bloc`
does when caching breeds) throws a `TypeError` on the nested cast. There is a round-trip test
in `catbreed_model_test.dart` — keep it.

Every field in `CatBreedModel` carries a `@Default(...)`. The live payload **omits** keys
rather than sending `null` for the two breeds with no image, and `@Default` covers both shapes
(`json['x'] as String? ?? ''`). Add the default when you add a field, and assert both shapes.

## injectable

See `/flutter-architecture` for the registration decision table. Generation-side notes:

- `@InjectableInit(throwOnMissingDependencies: true)` is set. It **defaults to `false`**,
  which merely prints warnings and lets the build succeed — do not remove it.
- `ignoreUnregisteredTypes: [KeyValueStore]` is the one declared exception, because that type
  is registered by hand in `Injector.setup`. Everything not on that list is an error.
- A `dispose:` callback must be a **public top-level function** (`closeHttpClient`,
  `closeStorage`). The generated config is a separate library and cannot reference a private
  one — a `_closeClient` will not compile.

## The analyzer pin — do not "upgrade" it

`analyzer: ^10.2.0` is pinned in `dev_dependencies`. Left alone, pub maximizes it to 12.x,
which no stable freezed supports, so it silently resolves freezed to the `3.2.6-dev.1`
**prerelease**. Verified working set: freezed 3.2.5, json_serializable 6.14.1,
injectable_generator 2.12.1, build_runner 2.15.1, analyzer 10.2.0. Remove the pin only when a
stable freezed supports analyzer 12, and say so in the PR doc.

## When generation fails

| Symptom | Cause |
|---|---|
| `part '...freezed.dart'` not found | Missing `part` directive, or the file was never generated — run build_runner |
| Conflicting outputs | Use `--delete-conflicting-outputs` |
| A registration is missing though it is in the source | Stale `injector.config.dart` — regenerate |
| injectable cannot resolve a `Duration` / `DateTime Function()` | A **test seam** leaked into an annotated constructor — move the registration to a factory method in `AppModule` naming only the real dependencies |
| Version solving fails after adding a package | Check the analyzer pin note above before touching it |
