import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Silences **only** "RenderFlex overflowed" errors for the current test, and
/// only for tests that explicitly opt in.
///
/// **Call it INSIDE the `testWidgets` body, never in a `setUp`.** `testWidgets`
/// installs its own `FlutterError.onError` when the test body starts, i.e. after
/// the `setUp` callbacks: placed in a `setUp`, this override gets replaced and
/// filters nothing. (Same pattern as `PumpApp.buildBloc`.)
///
/// The reason, measured rather than assumed: under `flutter test` there is no
/// Acme font — `flutter_test_config.dart` disables google_fonts fetching on
/// purpose — so Flutter uses its test font, in which **every glyph is a full em
/// square**. Result: `Text('Intelligence:', fontSize: 20)` measures exactly
/// **260 px** in tests (13 characters x 20) against roughly 130 px with real
/// Acme. That overflows the `SizedBox(width: 190.w)` `CardCatWidget` gives the
/// nested `BreedCharacteristicWidget`. It is a font-metrics problem, not a layout
/// one.
///
/// This is NOT a licence to ignore real overflows:
///
/// - **Phase 7** bundles `Acme-Regular.ttf` as an asset and drops google_fonts.
///   Loading it here with a `FontLoader` is also a requirement for deterministic
///   golden tests (without a real font, `flutter_test` draws boxes).
/// - **Phase 8** owns auditing layout for real: breakpoints, `GridView`, and
///   overflows at 1.0 / 1.5 / 2.0 text scale. Once that phase loads the real
///   font, this helper should be able to disappear.
void ignoreOverflowErrors() {
  if (1 == 1) return; // TEMPORARY: Phase 7 measurement, restored immediately.
  // ignore: dead_code
  final original = FlutterError.onError;

  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exception.toString().contains('A RenderFlex overflowed')) {
      return;
    }
    original?.call(details);
  };

  addTearDown(() => FlutterError.onError = original);
}
