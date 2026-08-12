import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tecnical_test_pragma/app_cats_responsive.dart';

/// Global test configuration. `flutter test` discovers this file automatically
/// and runs it once per test file.
///
/// Without it, every widget test in this project is noisy and slow:
///
/// - `TextWidget` calls `GoogleFonts.acme(...)`, and **every** screen uses
///   `TextWidget`. google_fonts tries the asset bundle, then `path_provider`
///   (which throws `MissingPluginException` under `flutter test`), then HTTP
///   (which flutter_test's `_MockHttpOverrides` answers with 400). The error is
///   swallowed via `.ignore()`, so nothing fails: it just spews a wall of
///   `debugPrint` and wastes a round trip per test.
/// - `ScreenUtil` holds `late Size _uiSize` and `late MediaQueryData _data`, so
///   any uninitialized `.w`/`.h` throws `LateInitializationError`.
///   `ScreenUtil.configure` needs no `BuildContext`, so there is no need to wrap
///   every test in `ScreenUtilInit`.
///
/// Phase 4 removed the third entry, `EquatableConfig.stringify = true`. It existed
/// so a failing `blocTest` printed which field differed instead of two
/// `Instance of 'LandingCatsState'` — freezed generates a field-listing
/// `toString()` unconditionally, so with `equatable` gone the setting had nothing
/// left to configure.
///
/// Phase 7 bundles the Acme font and drops google_fonts; Phase 8 drops
/// flutter_screenutil. When that happens, this file disappears entirely.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;

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
