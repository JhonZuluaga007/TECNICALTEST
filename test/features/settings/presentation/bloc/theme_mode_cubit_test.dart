import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:tecnical_test_pragma/features/settings/presentation/bloc/theme_mode_cubit.dart';

import '../../../../helpers/in_memory_key_value_store.dart';

void main() {
  /// A cubit on its own store, closed when the test ends.
  ///
  /// The store is a parameter rather than a fresh one per call precisely so the
  /// persistence test can hand the same box to two cubits — which is the only
  /// way to observe a relaunch.
  ThemeModeCubit buildCubit([InMemoryStorage? storage]) {
    final cubit = ThemeModeCubit(storage: storage ?? InMemoryStorage());
    addTearDown(cubit.close);
    return cubit;
  }

  group('ThemeModeCubit', () {
    test('starts on system', () {
      // Not "light". Before the user has said anything, the OS setting is the
      // only preference that exists.
      expect(buildCubit().state, ThemeMode.system);
    });

    blocTest<ThemeModeCubit, ThemeMode>(
      'cycle() walks system -> light -> dark -> system',
      // The order is the assertion, and it is the whole reason this is a cycle
      // rather than a boolean toggle: `system` has to stay reachable. A switch
      // that goes system -> dark -> light -> system is just as "correct" looking
      // and puts the user somewhere they did not ask for on the first tap.
      build: buildCubit,
      act: (cubit) => cubit
        ..cycle()
        ..cycle()
        ..cycle(),
      expect: () => const [ThemeMode.light, ThemeMode.dark, ThemeMode.system],
    );

    blocTest<ThemeModeCubit, ThemeMode>(
      'cycling four times returns to light, not to a fourth state',
      build: buildCubit,
      act: (cubit) => cubit
        ..cycle()
        ..cycle()
        ..cycle()
        ..cycle(),
      expect: () => const [
        ThemeMode.light,
        ThemeMode.dark,
        ThemeMode.system,
        ThemeMode.light,
      ],
    );
  });

  group('ThemeModeCubit persistence', () {
    test('the preference survives a rebuild on the same storage', () {
      // The two cubits share one box, which is what a relaunch looks like from
      // hydrated_bloc's side: it keys state by runtime type, so the second
      // instance reads what the first wrote. Anything that stops the write —
      // a `toJson` returning null being the obvious one — leaves this on
      // `system` while the app still "works".
      final storage = InMemoryStorage();

      buildCubit(storage).cycle();
      expect(storage.values, isNotEmpty, reason: 'something was persisted');

      expect(buildCubit(storage).state, ThemeMode.light);
    });

    test('a stored dark preference is restored, not just any non-default', () {
      // `light` alone would pass against a hydration that always returns the
      // first enum value. Two values, restored distinctly, is what pins it.
      final storage = InMemoryStorage();

      buildCubit(storage)
        ..cycle()
        ..cycle();

      expect(buildCubit(storage).state, ThemeMode.dark);
    });

    test('an unrelated store does not leak a preference', () {
      // The reason `Storage` is a constructor argument and never the
      // process-wide `HydratedBloc.storage`: with a global box this test would
      // read the previous one's `dark` and pass for the wrong reason.
      final storage = InMemoryStorage();
      buildCubit(storage).cycle();

      expect(buildCubit(InMemoryStorage()).state, ThemeMode.system);
    });
  });

  group('ThemeModeCubit.fromJson', () {
    // A theme preference that can throw on read is an app that cannot be
    // launched, and the only fix a user has for that is reinstalling. Each of
    // these is a shape a real box can hold: a value written by a future version
    // of the enum, a value of the wrong type, and a box written by something
    // else entirely.
    const garbageValues = <Map<String, dynamic>>[
      {'themeMode': 'sepia'},
      {'themeMode': 42},
      {'themeMode': null},
      {'somethingElse': 'light'},
      <String, dynamic>{},
    ];

    for (final garbage in garbageValues) {
      test('returns null rather than throwing for $garbage', () {
        // Called **directly**, not through a constructor.
        //
        // The version of this test that built a cubit on a corrupt box and
        // asserted `ThemeMode.system` was mutation-tested and stayed green
        // against a `fromJson` written as `ThemeMode.values.byName(json[_key]
        // as String)`, i.e. one that throws on every value here. The reason is
        // `HydratedMixin.hydrate` (hydrated_bloc 11.0.0, `hydrated_bloc.dart:184-195`):
        // it wraps the `fromJson` call in a `try` and falls back to
        // `super.state` on anything thrown. So the cubit lands on `system`
        // whether or not this method is total, and that test proved the
        // package's catch-all rather than this code.
        //
        // Calling the method is the only assertion that can tell them apart.
        expect(buildCubit().fromJson(garbage), isNull);
      });
    }

    test('a corrupt store still leaves the cubit on system', () {
      // Kept, renamed, and scoped down to what it actually proves: launching on
      // a box full of nonsense yields the default rather than a crash. Per the
      // note above, hydrated_bloc guarantees most of that on its own — this is
      // an integration check on the pair, not on `fromJson`.
      for (final garbage in garbageValues) {
        final storage = InMemoryStorage()..values['ThemeModeCubit'] = garbage;

        expect(buildCubit(storage).state, ThemeMode.system, reason: '$garbage');
      }
    });

    test('reads back exactly what toJson wrote', () {
      // The round trip, so the two halves cannot drift: a `toJson` writing
      // `state.index` and a `fromJson` reading a name would both look fine on
      // their own and persist nothing.
      final cubit = buildCubit();

      expect(cubit.fromJson(cubit.toJson(ThemeMode.dark)!), ThemeMode.dark);
      expect(cubit.fromJson(cubit.toJson(ThemeMode.light)!), ThemeMode.light);
      expect(cubit.fromJson(cubit.toJson(ThemeMode.system)!), ThemeMode.system);
    });
  });
}
