import 'package:flutter/foundation.dart';

class Endpoints {
  static const urlAllCats = "https://api.thecatapi.com/v1/breeds";

  static const urlForGetImageCat = "https://api.thecatapi.com/v1/images/";

  /// TheCatAPI's key header name.
  ///
  /// It used to be `api-key`, which the API ignores — it expects `x-api-key`, so
  /// every request the app has ever made went out unauthenticated.
  static const apiKeyHeader = "x-api-key";

  /// Reads the key from the build environment. Phase 4 moved it out of the
  /// source; before that it was a literal in this file (and in the datasource
  /// before Phase 2 hoisted it here).
  ///
  /// Supply it with `--dart-define-from-file=env/dev.json`. See `env/example.json`
  /// for the shape; `env/*.json` is gitignored except that example.
  static const apiKey = String.fromEnvironment("CAT_API_KEY");

  /// The auth headers for this build, or an empty map when no key was supplied.
  static Map<String, String> get authHeader => headersForKey(apiKey);

  /// Builds the auth headers for [key], or **an empty map** when it is blank.
  ///
  /// Empty rather than `{"x-api-key": ""}` on purpose. Both `/v1/breeds` and
  /// `/v1/images/{id}` answer 200 anonymously — verified against the live API —
  /// so a keyless build is a working build on the anonymous tier, which is what
  /// the app has effectively been running on all along. Sending a blank or stale
  /// key instead of no key would trade working requests for a risk with no
  /// upside.
  ///
  /// Split out from [authHeader] so both branches are unit-testable: [apiKey]
  /// comes from `String.fromEnvironment`, which is resolved at compile time, so a
  /// test cannot vary it in-process.
  @visibleForTesting
  static Map<String, String> headersForKey(String key) =>
      key.isEmpty ? const {} : {apiKeyHeader: key};
}
