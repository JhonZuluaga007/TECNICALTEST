import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:tecnical_test_pragma/core/storage/key_value_store.dart';

/// Adapts `hydrated_bloc`'s [Storage] to this project's [KeyValueStore].
///
/// The whole adapter is three forwarding methods, and that is the point: the app
/// already has a `Storage` instance — `main.dart` builds one so the bloc can
/// persist its search history — and it is a general-purpose key-value store with
/// a Hive box behind it. Adding `shared_preferences` (or anything else) for the
/// breeds cache would mean a second persistence technology, a second thing to
/// initialise and a second thing to close, for a job this one already does.
///
/// This file is the **only** place in `lib/` outside the composition root and the
/// bloc that names `package:hydrated_bloc`. See [KeyValueStore] for why that
/// matters.
class HydratedKeyValueStore implements KeyValueStore {
  const HydratedKeyValueStore(this._storage);

  final Storage _storage;

  @override
  Object? read(String key) => _storage.read(key);

  @override
  Future<void> write(String key, Object? value) => _storage.write(key, value);
}
