import 'package:flutter/material.dart';

/// The seed the whole palette is derived from.
///
/// It is the app's existing accent — the green of the rating meter in
/// `BreedCharacteristicWidget`, previously `AppCatsColor.mapColors["LigthGreen"]`
/// — rather than a new colour chosen here. Keeping it means the redesign changes
/// how the palette is *built* without changing what the app looks like it is.
///
/// Its own lightness does not matter: [ColorScheme.fromSeed] reads the hue and
/// generates the tonal palette, so a pale seed and a saturated one of the same hue
/// produce the same scheme.
const Color kSeedColor = Color(0xFFB1E0B3);

/// The light scheme.
///
/// Everything the old `AppCatsColor` provided by hand — white surfaces, a
/// near-black text colour and its ten opacity steps — is a generated role here.
/// The mapping used at the call sites is in the Phase 7 PR doc.
final ColorScheme lightScheme = ColorScheme.fromSeed(seedColor: kSeedColor);

/// The dark scheme.
///
/// New behaviour, not a port: before this phase a device in dark mode got the
/// light app, because there was no `ThemeData` at all.
final ColorScheme darkScheme = ColorScheme.fromSeed(
  seedColor: kSeedColor,
  brightness: Brightness.dark,
);
