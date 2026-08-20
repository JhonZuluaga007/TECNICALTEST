/// The spacing scale, in logical pixels.
///
/// Phase 8 introduced it while removing `flutter_screenutil`. Before, spacing was
/// written as `15.w` / `5.h` / `12.w` — density-scaled magic numbers spread over
/// nine files, on a 4 pt grid only by accident (5 and 15 are not on it).
///
/// The values are **not** scaled by anything at runtime. `flutter_screenutil`
/// multiplied every one of them by `screenWidth / 390`, which meant padding grew
/// on a tablet: a 12 px gutter became 33 px at 1080 px wide. Material spacing is
/// constant across window sizes; what changes with the window is the *layout*
/// (see `WindowSize`), not the size of a gap.
abstract final class AppSpacing {
  /// 4 — between items in a tight row, e.g. the rating dots.
  static const double xs = 4;

  /// 8 — inside a control.
  static const double sm = 8;

  /// 12 — between siblings; the list gutter.
  static const double md = 12;

  /// 16 — card padding, screen margin at `WindowSize.compact`.
  static const double lg = 16;

  /// 24 — around a full-screen status view.
  static const double xl = 24;
}
