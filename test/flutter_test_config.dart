import 'dart:async';

import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';

/// Global test configuration. `flutter test` discovers this file automatically
/// and runs it once per test file.
///
/// It has one job left: **load a real Acme font.** Phase 7 bundled it as an asset
/// and dropped `google_fonts`; this registers it. `flutter_test` has **no
/// font-loading code of its own**, so without this every glyph is drawn from the
/// test font, in which each character is a full em square — text measures roughly
/// twice its real width and layouts overflow for reasons that do not exist in the
/// app. That is what `ignoreOverflowErrors()` was working around, and why Phase 8
/// could delete it.
///
/// What used to be here and is gone:
///
/// - `ScreenUtil.configure` (Phase 8 — the package is gone, so `.w`/`.h` no
///   longer exist to throw `LateInitializationError`).
/// - `GoogleFonts.config.allowRuntimeFetching = false` (Phase 7 — the package it
///   configured no longer exists).
/// - `EquatableConfig.stringify = true` (Phase 4 — freezed generates a
///   field-listing `toString()` unconditionally).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Required before `rootBundle`: it reads through the binding's asset bundle,
  // and the binding does not exist yet when this file runs.
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadAcme();

  await testMain();
}

/// Registers the bundled Acme under the same family name `ThemeData` asks for.
///
/// The family string must match `AppTheme`'s `fontFamily` exactly; a mismatch is
/// silent — Flutter falls back to the test font and the metrics problem above
/// comes straight back.
Future<void> _loadAcme() async {
  final loader = FontLoader('Acme')
    ..addFont(rootBundle.load('assets/fonts/Acme-Regular.ttf'));
  await loader.load();
}
