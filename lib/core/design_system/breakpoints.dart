import 'package:flutter/widgets.dart';

/// The Material 3 window size classes.
///
/// Hand-rolled on purpose. Verified against the pinned SDK: Flutter 3.44.9 ships
/// **no** breakpoint or `WindowSizeClass` API in `package:flutter/material` —
/// `flutter_adaptive_scaffold` is a separate package, and pulling one in to hold
/// three numbers and an enum would be a dependency for a `switch`.
///
/// This replaces `core/config/helpers/responsive/responsive.dart`, which had a
/// single 640 px threshold that matched none of the Material breakpoints and was
/// consumed by exactly one caller — the `ScreenUtil.init` this phase deleted.
///
/// The thresholds are the published ones:
/// <https://m3.material.io/foundations/layout/applying-layout/window-size-classes>
enum WindowSize {
  /// Phones in portrait. `< 600`.
  compact,

  /// Phones in landscape, small tablets. `600 - 839`.
  medium,

  /// Tablets, small desktop windows. `840 - 1199`.
  expanded,

  /// Desktop. `>= 1200`.
  large;

  /// Classifies a width in logical pixels.
  ///
  /// Separate from [of] so it can be unit-tested without a `BuildContext` — the
  /// boundary values are the whole content of this type.
  static WindowSize fromWidth(double width) {
    if (width < 600) return WindowSize.compact;
    if (width < 840) return WindowSize.medium;
    if (width < 1200) return WindowSize.expanded;
    return WindowSize.large;
  }

  /// Classifies the window the [context] is being laid out in.
  ///
  /// `MediaQuery.sizeOf`, not `MediaQuery.of`: the latter subscribes the caller
  /// to **every** `MediaQueryData` field, so a keyboard opening or a text-scale
  /// change would rebuild the whole grid for nothing.
  static WindowSize of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  /// How many breed cards fit across.
  ///
  /// One column at [compact] is not a grid with one column — `LandingPage`
  /// renders a `ListView` there, because a one-column `GridView` forces every
  /// card to the same height whatever its content is.
  int get columns => switch (this) {
    WindowSize.compact => 1,
    WindowSize.medium => 2,
    WindowSize.expanded => 3,
    WindowSize.large => 4,
  };
}
