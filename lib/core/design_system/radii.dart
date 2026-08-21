/// The corner radius scale, in logical pixels.
///
/// Phase 9. Before it, four surfaces picked their own corner inline: the breed
/// card at 12, and the search field, its container and the stale banner at 8.
/// Two values, written four times, with nothing saying they were a set.
///
/// **Deliberately two entries, not a full scale.** The rule this phase applied
/// is that a number earns a token when it expresses one decision at more than
/// one *independent* site. `AppRadius.card = 12` used once would be worse than
/// the literal — a name that only restates its single caller. Named by size, the
/// pair says something the literals could not: these are the two corners this
/// app uses.
///
/// Elevation, border width and icon size were considered and left as literals
/// for the same reason, in reverse: elevation appears once (inside `cardTheme`,
/// where a number in a theme is the right form), `width: 1` is the SDK's own
/// default for `BorderSide` and `Border.all` and was deleted rather than named,
/// and the icon sizes are one-offs — the `48` on a status icon and the `48` on
/// the app bar's bottom are not the same decision, and a token would fuse them.
abstract final class AppRadius {
  /// 8 — input surfaces and inline strips: the search field and the stale banner.
  static const double sm = 8;

  /// 12 — cards. Applied through `ThemeData.cardTheme`, not per widget.
  static const double md = 12;
}
