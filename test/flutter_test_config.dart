import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecnical_test_pragma/app_cats_responsive.dart';

/// Global test configuration. `flutter test` discovers this file automatically
/// and runs it once per test file.
///
/// Two things every widget test in this project needs:
///
/// - **A real Acme font.** Phase 7 bundled it as an asset and dropped
///   `google_fonts`; this loads it. `flutter_test` has **no font-loading code of
///   its own**, so without this every glyph is drawn from the test font, in which
///   each character is a full em square — text measures roughly twice its real
///   width and layouts overflow for reasons that do not exist in the app. That is
///   what `ignoreOverflowErrors()` was working around.
/// - **`ScreenUtil`**, which holds `late Size _uiSize` and `late MediaQueryData
///   _data`, so any uninitialized `.w`/`.h` throws `LateInitializationError`.
///   `ScreenUtil.configure` needs no `BuildContext`, so there is no need to wrap
///   every test in `ScreenUtilInit`.
///
/// What used to be here and is gone: `GoogleFonts.config.allowRuntimeFetching =
/// false` (Phase 7 — the package it configured no longer exists) and
/// `EquatableConfig.stringify = true` (Phase 4 — freezed generates a
/// field-listing `toString()` unconditionally).
///
/// Phase 8 drops flutter_screenutil. When that happens only the font loader is
/// left.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // Required before `rootBundle`: it reads through the binding's asset bundle,
  // and the binding does not exist yet when this file runs.
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadAcme();

  // designSize == screen size => `.w`/`.h` are the identity in tests.
  //
  // `splitScreenMode` and `minTextAdapt` must be passed EXPLICITLY: left null,
  // `configure` does `x ?? _instance._x` over uninitialized `late` fields and
  // throws `LateInitializationError` while loading the file.
  ScreenUtil.configure(
    data: const MediaQueryData(size: AppCatsResponsiveApp.designSizeSmall),
    designSize: AppCatsResponsiveApp.designSizeSmall,
    splitScreenMode: false,
    minTextAdapt: true,
  );

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
