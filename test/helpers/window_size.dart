import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecnical_test_pragma/core/design_system/breakpoints.dart';

/// Sizes the test window, and restores it when the test ends.
///
/// New in Phase 8, and it exists because of a measured surprise. `flutter_test`
/// defaults to an **800x600** surface, which `WindowSize.fromWidth` classifies as
/// [WindowSize.medium] — so with an adaptive landing screen the *entire* existing
/// suite would have been exercising the two-column grid, and the one-column list
/// that phones actually show would have had no coverage at all. Two tests failed
/// on that alone when the grid landed, which is how it was noticed.
///
/// The `PumpApp` helpers therefore default to [phone], and any test that wants a
/// wider window says so.
///
/// `devicePixelRatio` is pinned to 1 so `physicalSize` and the logical size the
/// widgets see are the same number — otherwise every size here would have to be
/// divided by whatever ratio the host happens to report.
void setWindowSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

/// 390x844 — an iPhone 14. [WindowSize.compact].
const Size phone = Size(390, 844);

/// 768x1024 — an iPad in portrait. [WindowSize.medium].
const Size tabletPortrait = Size(768, 1024);

/// 1024x768 — an iPad in landscape. [WindowSize.expanded].
const Size tabletLandscape = Size(1024, 768);

/// 1440x900 — a desktop window. [WindowSize.large].
const Size desktop = Size(1440, 900);
