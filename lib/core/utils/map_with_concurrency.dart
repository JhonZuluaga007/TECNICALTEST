/// Applies [operation] to every element of [items] with at most [concurrency]
/// operations in flight at a time, **preserving input order**.
///
/// An alternative to `Future.wait(items.map(op))`, which would fix latency by
/// creating a rate-limit problem: with 67 breeds it would fire 67 simultaneous
/// requests. And an alternative to a `for` loop with `await` inside, which is
/// correct but serializes everything.
///
/// Order is preserved by writing into an indexed buffer rather than by
/// completion order: `results[index]`, not `results.add(...)`.
Future<List<R>> mapWithConcurrency<T, R>(
  List<T> items,
  Future<R> Function(T item) operation, {
  int concurrency = 6,
}) async {
  if (items.isEmpty) return const [];

  final results = List<R?>.filled(items.length, null);
  var next = 0;

  Future<void> worker() async {
    while (true) {
      final index = next++;
      if (index >= items.length) return;
      results[index] = await operation(items[index]);
    }
  }

  await Future.wait(
    List.generate(concurrency.clamp(1, items.length), (_) => worker()),
  );

  return results.cast<R>();
}
