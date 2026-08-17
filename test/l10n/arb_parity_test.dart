import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The structural half of Phase 7's countermeasure against a half-translated app.
///
/// The risk, stated in the plan: a key present in `app_en.arb` and missing from
/// `app_es.arb` **falls back to English at runtime with nothing failing**.
/// `gen-l10n` only warns, `flutter test` never regenerates (the generated l10n is
/// committed, like the other tracked generated files), and every widget test in
/// the suite pins `Locale('en')`. The app ships in Spanish with English strings
/// in it, green the whole way.
///
/// So this reads the ARB files as data. It does not go through
/// `AppLocalizations`, on purpose: the generated class is the thing that would
/// have silently absorbed the divergence, and asserting on it would inherit the
/// fallback.
void main() {
  /// Everything a message can be, keyed by resource id.
  ///
  /// `@@locale` and the `@key` metadata blocks are dropped: only `app_en.arb`
  /// carries the latter (`required-resource-attributes: true` makes them
  /// mandatory in the template and pointless in a translation), so comparing
  /// them would compare the file format rather than the translation.
  Map<String, String> messagesOf(String path) {
    final decoded = jsonDecode(File(path).readAsStringSync()) as Map;
    return {
      for (final entry in decoded.entries)
        if (!(entry.key as String).startsWith('@'))
          entry.key as String: entry.value as String,
    };
  }

  /// The placeholder names a message actually interpolates, read from the value.
  ///
  /// Read from the **value**, not from the `@key.placeholders` block, because
  /// only the template has that block. `{origin}` in one locale and `{country}`
  /// in the other is a runtime crash in gen-l10n's output, and it is exactly the
  /// kind of thing a translator does.
  Set<String> placeholdersIn(String message) => RegExp(
    r'\{(\w+)\}',
  ).allMatches(message).map((match) => match.group(1)!).toSet();

  late Map<String, String> en;
  late Map<String, String> es;

  setUpAll(() {
    // `flutter test` runs with the package root as the working directory, the
    // same assumption `fixture_reader.dart` already makes.
    en = messagesOf('lib/l10n/app_en.arb');
    es = messagesOf('lib/l10n/app_es.arb');
  });

  group('ARB parity', () {
    test('both files declare their locale', () {
      // Cheap, but it is what makes the two maps below comparable at all: a
      // missing `@@locale` means gen-l10n infers the locale from the file name,
      // and the file name is not what the app looks up.
      final enRaw = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync());
      final esRaw = jsonDecode(File('lib/l10n/app_es.arb').readAsStringSync());

      expect((enRaw as Map)['@@locale'], 'en');
      expect((esRaw as Map)['@@locale'], 'es');
    });

    test('the two files define exactly the same keys', () {
      // Set difference in both directions rather than one `equals`, so the
      // failure message names the offending keys instead of printing two
      // nineteen-element sets side by side.
      expect(
        en.keys.toSet().difference(es.keys.toSet()),
        isEmpty,
        reason: 'translated in English but missing from Spanish',
      );
      expect(
        es.keys.toSet().difference(en.keys.toSet()),
        isEmpty,
        reason: 'present in Spanish but not in the template',
      );
      expect(en, isNotEmpty);
    });

    test('every key interpolates the same placeholder names in both files', () {
      final mismatched = <String, String>{};
      for (final key in en.keys.where(es.containsKey)) {
        final fromEn = placeholdersIn(en[key]!);
        final fromEs = placeholdersIn(es[key]!);
        if (!setEquals(fromEn, fromEs)) {
          mismatched[key] = 'en $fromEn vs es $fromEs';
        }
      }

      expect(mismatched, isEmpty);
    });

    test('the template declares every placeholder its messages use', () {
      // The other direction of the same problem, inside the template alone: a
      // `{statusCode}` in the value with no `placeholders` entry makes gen-l10n
      // emit a getter instead of a method, and the call site stops compiling —
      // loudly, but only after a regeneration nobody runs during `flutter test`.
      final raw =
          jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map;

      final undeclared = <String, Set<String>>{};
      for (final entry in en.entries) {
        final used = placeholdersIn(entry.value);
        if (used.isEmpty) continue;
        final meta = raw['@${entry.key}'] as Map?;
        final declared =
            ((meta?['placeholders'] as Map?)?.keys ?? const <String>[])
                .cast<String>()
                .toSet();
        final missing = used.difference(declared);
        if (missing.isNotEmpty) undeclared[entry.key] = missing;
      }

      expect(undeclared, isEmpty);
    });

    test('no Spanish message was left as its English source', () {
      // A weaker check than it looks, and deliberately scoped: `appTitle` is a
      // proper noun and is meant to be identical. Anything else being
      // byte-identical to the English is a key someone copied across and never
      // came back to — which the key-set test above cannot see, because the key
      // is there.
      final untranslated = en.keys
          .where((key) => key != 'appTitle')
          .where((key) => es[key] == en[key])
          .toList();

      expect(untranslated, isEmpty);
    });
  });
}

/// `flutter_test` re-exports `setEquals` from `package:flutter/foundation.dart`
/// only through `matchers`; spelling it out keeps this file's imports to
/// `dart:` plus the test package.
bool setEquals(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);
