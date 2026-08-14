import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:tecnical_test_pragma/core/storage/key_value_store.dart';

/// A [KeyValueStore] backed by a `Map`.
///
/// Every test that touches persistence uses this. It lives here rather than in
/// `lib/` because a test double has no reason to ship, and because
/// `Injector.setup` **requires** a storage instead of defaulting to one — so "the
/// store the tests use" can never silently become "the store the app uses".
class InMemoryKeyValueStore implements KeyValueStore {
  InMemoryKeyValueStore([Map<String, Object?>? initial])
    : _values = {...?initial};

  final Map<String, Object?> _values;

  @override
  Object? read(String key) => _values[key];

  @override
  Future<void> write(String key, Object? value) async => _values[key] = value;
}

/// A `hydrated_bloc` [Storage] backed by a `Map`.
///
/// Separate from [InMemoryKeyValueStore] because `Storage` is a five-method
/// interface (it adds `clear` and `close`) and because the two are used at
/// different seams: this one goes into a bloc's constructor or into
/// `Injector.setup`, the other into the cache's data source.
///
/// [closed] is exposed so the container's disposal can be asserted, the same way
/// `injector_test.dart` records `close()` on the http client.
class InMemoryStorage implements Storage {
  final Map<String, dynamic> values = {};
  bool closed = false;

  @override
  dynamic read(String key) => values[key];

  @override
  Future<void> write(String key, dynamic value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<void> clear() async => values.clear();

  @override
  Future<void> close() async => closed = true;
}
