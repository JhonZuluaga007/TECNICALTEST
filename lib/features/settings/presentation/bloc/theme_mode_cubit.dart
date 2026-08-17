import 'package:flutter/material.dart' show ThemeMode;
import 'package:hydrated_bloc/hydrated_bloc.dart';

/// The user's theme preference, persisted.
///
/// Phase 7. It starts at [ThemeMode.system] — following the OS is the right
/// default, and it is also the only value that is correct before the user has
/// expressed a preference.
///
/// [Storage] is **required and passed in**, never the process-wide
/// `HydratedBloc.storage` static. Same reasoning as `LandingCatsBloc`:
/// `flutter_test_config.dart` runs once per test *file* and hydrated_bloc keys
/// state by runtime type, so one global store would leak a preference from one
/// test into the next and make assertions depend on execution order.
class ThemeModeCubit extends HydratedCubit<ThemeMode> {
  ThemeModeCubit({required Storage storage})
    : super(ThemeMode.system, storage: storage);

  static const _key = 'themeMode';

  /// Advances system -> light -> dark -> system.
  ///
  /// A cycle rather than a boolean toggle because there are three states, and
  /// "follow the system" has to remain reachable: a toggle that only swaps light
  /// and dark takes the user out of `system` on the first tap with no way back.
  void cycle() => emit(switch (state) {
    ThemeMode.system => ThemeMode.light,
    ThemeMode.light => ThemeMode.dark,
    ThemeMode.dark => ThemeMode.system,
  });

  @override
  Map<String, dynamic>? toJson(ThemeMode state) => {_key: state.name};

  /// Returns `null` — i.e. "no stored preference", so the cubit keeps its initial
  /// [ThemeMode.system] — for anything unreadable: a missing key, a value of the
  /// wrong type, or a name written by a future version of this enum.
  ///
  /// Deliberately total. A theme preference that can throw on read is a theme
  /// preference that can make the app unlaunchable, and the only fix a user has
  /// for that is reinstalling. Same rule as the breeds cache in Phase 6.
  @override
  ThemeMode? fromJson(Map<String, dynamic> json) {
    final stored = json[_key];
    if (stored is! String) return null;
    return ThemeMode.values.asNameMap()[stored];
  }
}
