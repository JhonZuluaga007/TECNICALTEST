/// A minimal key-value store, owned by this project.
///
/// Introduced in Phase 6, and it exists for one reason worth stating: the
/// implementation behind it is `hydrated_bloc`'s `Storage`, and
/// `package:hydrated_bloc` **re-exports `package:bloc`**. Depending on it
/// directly from `data/` would make `Bloc`, `Cubit` and `Emitter` visible to the
/// data layer, which has no business knowing the app uses bloc at all. Three
/// method signatures are a cheap price for keeping that boundary.
///
/// Deliberately **not** async on [read]. `hydrated_bloc`'s `Storage.read` is
/// synchronous because Hive keeps the box in memory, and that is what lets a cold
/// start serve the cached breeds without awaiting — i.e. without a frame of
/// spinner. Widening it to a `Future` here would throw that away for nothing.
///
/// The only implementation in `lib/` is `HydratedKeyValueStore`. The in-memory one
/// lives in `test/helpers/`, because a test double has no reason to ship.
///
/// Two methods, not the five `Storage` has. `delete` and `clear` were here at first
/// and came straight back out: nothing calls them — the cache expires by TTL and
/// overwrites on refresh — so they were interface surface that existed only to be
/// left untested. Manual invalidation is a Phase 7 concern if a pull-to-refresh
/// gesture ever needs it.
abstract interface class KeyValueStore {
  /// The value stored under [key], or `null` if there is none.
  Object? read(String key);

  Future<void> write(String key, Object? value);
}
