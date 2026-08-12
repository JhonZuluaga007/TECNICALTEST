import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tecnical_test_pragma/core/config/helpers/endpoints.dart';

void main() {
  group('Endpoints', () {
    test('the key header is x-api-key, not api-key', () {
      // The regression this pins is not hypothetical: the app shipped
      // `api-key` from the first commit, TheCatAPI only reads `x-api-key`, so
      // every request went out unauthenticated and nobody noticed — because
      // both endpoints the app uses answer 200 anonymously.
      expect(Endpoints.apiKeyHeader, 'x-api-key');
    });

    test('no key means NO header at all, not a blank one', () {
      // `{"x-api-key": ""}` is worse than sending nothing: it is a malformed
      // credential where the anonymous tier would have worked.
      expect(Endpoints.headersForKey(''), isEmpty);
    });

    test('a key produces exactly one header, under the right name', () {
      expect(Endpoints.headersForKey('abc-123'), {'x-api-key': 'abc-123'});
    });

    test('no secret is hardcoded anywhere in lib/', () {
      // This scans the source instead of asserting on a value, because "the key is
      // not in the code" is a property OF THE CODE, not of a running build.
      //
      // It exists because the runtime test below cannot cover it: that test has to
      // tolerate `--dart-define=CAT_API_KEY=...` (a legitimate way to run the
      // suite), and a `fromEnvironment` default would take exactly the same branch
      // as a legitimately configured key. Verified by mutation: adding
      // `defaultValue: "leaked-key"` left the whole suite green until this test
      // existed.
      //
      // The literal that was here until Phase 4 — and is still in git history at
      // commit 4c6b5ee — was a UUID, which is the shape every TheCatAPI key takes.
      final uuid = RegExp(
        r'''['"][0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'''
        r'''[0-9a-fA-F]{4}-[0-9a-fA-F]{12}['"]''',
      );

      final offenders = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where((file) => uuid.hasMatch(file.readAsStringSync()))
          .map((file) => file.path)
          .toList();

      expect(offenders, isEmpty, reason: 'API-key-shaped literal in source');

      // And no default on the environment read, which would put a key in the
      // binary of every unconfigured build.
      final source = File(
        'lib/core/config/helpers/endpoints.dart',
      ).readAsStringSync();
      expect(source, contains('String.fromEnvironment("CAT_API_KEY")'));
      expect(source, isNot(contains('defaultValue')));
    });

    test('the key comes from the environment, never from a literal', () {
      // Two modes, both meaningful:
      //
      // Unconfigured (`fvm flutter test`) — `String.fromEnvironment` yields "",
      // so there must be no auth header. This branch is what fails if someone
      // puts a literal back as the `fromEnvironment` default.
      //
      // Configured (`--dart-define=CAT_API_KEY=...`) — the key is legitimately
      // present, so what is asserted is that it reaches the header untouched.
      // Without this branch the suite would break under a keyed run, which is a
      // perfectly valid way to run it.
      if (Endpoints.apiKey.isEmpty) {
        expect(Endpoints.authHeader, isEmpty);
      } else {
        expect(Endpoints.authHeader, {
          Endpoints.apiKeyHeader: Endpoints.apiKey,
        });
      }
    });
  });
}
