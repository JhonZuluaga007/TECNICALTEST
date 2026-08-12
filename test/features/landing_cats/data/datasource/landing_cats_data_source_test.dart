import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tecnical_test_pragma/core/config/helpers/endpoints.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/features/landing_cats/data/datasource/landing_cats_data_source.dart';

import '../../../../helpers/fixture_reader.dart';

/// Fixtures captured from TheCatAPI on 2026-08-10: 67 breeds, of which exactly 2
/// (`European Burmese` and `Malayan`) carry no `reference_image_id`.
///
/// This uses `MockClient` from `package:http/testing.dart` rather than a mocktail
/// mock: the tests need URL routing, different bodies per endpoint, and request
/// **counting**, and `MockClient` runs the real `BaseClient.get -> send` path, so
/// it genuinely exercises `Uri` construction, headers and charset decoding. A
/// `Mock implements http.Client` would stub `BaseClient` out entirely: we would
/// be testing the stub.
void main() {
  /// Records every requested URL and answers based on the endpoint.
  ({MockClient client, List<String> urls, List<Map<String, String>> headers})
  routedClient({
    required String breedsFixture,
    int breedsStatus = 200,
    String? breedsBody,
    String imageFixture = 'image_ok.json',
    int imageStatus = 200,
  }) {
    final urls = <String>[];
    final headers = <Map<String, String>>[];

    final client = MockClient((request) async {
      urls.add(request.url.toString());
      headers.add(request.headers);

      if (request.url.toString() == Endpoints.urlAllCats) {
        return jsonResponse(breedsBody ?? fixture(breedsFixture), breedsStatus);
      }
      return jsonResponse(fixture(imageFixture), imageStatus);
    });

    return (client: client, urls: urls, headers: headers);
  }

  /// Builds the datasource with retrying **off**.
  ///
  /// Phase 4 wired `withRetry` into `/breeds`, so a failing case would otherwise
  /// make 3 attempts and sleep 1.4 s of real time. Every case below is about
  /// classifying a single response; the retry policy has its own group at the end.
  LandingCatsDataSource dataSource(http.Client client, {Duration? timeout}) =>
      LandingCatsDataSource(
        client: client,
        timeout: timeout ?? const Duration(seconds: 10),
        retryDelays: const [],
      );

  group('LandingCatsDataSource.getAllCats', () {
    test('requests /breeds forwarding the configured auth headers', () async {
      final r = routedClient(breedsFixture: 'breeds_empty.json');

      await dataSource(r.client).getAllCats();

      expect(r.urls, [Endpoints.urlAllCats]);
      // Phase 4: the assertion used to be `containsPair('api-key', isNotEmpty)`,
      // which passed while being wrong twice over — the header name was one
      // TheCatAPI does not read, and the key was a literal in the source. What
      // matters here is that the datasource forwards whatever the build was
      // configured with; `endpoints_test.dart` owns what that is.
      expect(r.headers.first, isNot(contains('api-key')));
      for (final entry in Endpoints.authHeader.entries) {
        expect(r.headers.first, containsPair(entry.key, entry.value));
      }
    });

    test('maps the happy path in ONE request', () async {
      final r = routedClient(breedsFixture: 'breeds_3.json');

      final result = await dataSource(r.client).getAllCats();

      expect(result, hasLength(3));
      expect(result.first.name, 'Abyssinian');
      expect(r.urls, [Endpoints.urlAllCats]);
    });

    test('makes exactly 1 request for all 67 real breeds, not 66', () async {
      // THE test of Phase 4, and the one that makes the phase worth doing.
      //
      // The history of this number is the history of the bug. Originally 68: one
      // for `/breeds` plus one per breed, including 2 `GET /v1/images/` with no id
      // at all, which the API answers 400 and the code silently swallowed. Phase 2
      // brought it to 66 by skipping those two, and softened the rest with bounded
      // concurrency. Both were mitigations of the wrong problem: the user was still
      // waiting on 65 image lookups to see the 3 cards that fit on screen.
      //
      // It is now 1. Images are resolved by `getBreedImageUrl`, one call per card
      // the list actually builds. This test fails the moment anyone puts image
      // resolution back into `getAllCats`.
      final r = routedClient(breedsFixture: 'breeds_full.json');

      final result = await dataSource(r.client).getAllCats();

      expect(result, hasLength(67));
      expect(
        r.urls,
        hasLength(1),
        reason: 'one request before first paint, whatever the breed count',
      );
      expect(r.urls.single, Endpoints.urlAllCats);
    });

    test('preserves the breed order from the payload', () async {
      final r = routedClient(breedsFixture: 'breeds_3.json');

      final result = await dataSource(r.client).getAllCats();

      expect(result.map((b) => b.id), ['abys', 'aege', 'abob']);
    });

    test(
      'returns an empty list for an empty array, without requesting images',
      () async {
        final r = routedClient(breedsFixture: 'breeds_empty.json');

        final result = await dataSource(r.client).getAllCats();

        expect(result, isEmpty);
        expect(r.urls, hasLength(1));
      },
    );

    test('returns an empty list for an empty body', () async {
      final r = routedClient(breedsFixture: 'breeds_3.json', breedsBody: '');

      final result = await dataSource(r.client).getAllCats();

      expect(result, isEmpty);
      expect(r.urls, hasLength(1));
    });

    test('a status != 200 throws ServerFailure carrying that status', () async {
      // Phase 3: the status is a typed field now, not a substring of an
      // interpolated message. It is what lets the UI tell 401 apart from 500.
      //
      // The `rethrow` this pins is still load-bearing: the general `catch` used to
      // re-wrap the failure thrown by the status check, and the message became
      // "Service error: Instance of 'InvalidData'".
      final r = routedClient(breedsFixture: 'breeds_3.json', breedsStatus: 500);

      await expectLater(
        dataSource(r.client).getAllCats(),
        throwsA(const ServerFailure(statusCode: 500)),
      );
    });

    test('a 401 throws ServerFailure(401), not a generic failure', () async {
      // 401 gets its own case because the UI treats it differently: the error view
      // has a guard clause separating "could not authenticate" from "the service is
      // broken".
      //
      // Phase 4 correction: earlier phases claimed in comments and in the README
      // that the hardcoded key returned 401, making this the failure the running
      // app actually produced. Measured against the live API, that was false —
      // `/v1/breeds` answers 200 anonymously, with the misnamed `api-key` header,
      // and with `x-api-key`. The app was working; it was simply never
      // authenticated.
      final r = routedClient(breedsFixture: 'breeds_3.json', breedsStatus: 401);

      await expectLater(
        dataSource(r.client).getAllCats(),
        throwsA(const ServerFailure(statusCode: 401)),
      );
    });

    test('a body that is not JSON throws UnexpectedResponseFailure', () async {
      final r = routedClient(
        breedsFixture: 'breeds_3.json',
        breedsBody: 'not json at all',
      );

      await expectLater(
        dataSource(r.client).getAllCats(),
        throwsA(isA<UnexpectedResponseFailure>()),
      );
    });

    test('valid JSON that is not an array throws UnexpectedResponseFailure', () {
      // Used to be `json.decode(body) as List`, i.e. a `TypeError` stringified
      // into a message. Now the shape is checked explicitly.
      final r = routedClient(
        breedsFixture: 'breeds_3.json',
        breedsBody: '{"message":"not an array"}',
      );

      return expectLater(
        dataSource(r.client).getAllCats(),
        throwsA(
          const UnexpectedResponseFailure(
            detail: 'Expected a JSON array of breeds',
          ),
        ),
      );
    });

    test('a transport failure on /breeds throws NetworkFailure', () async {
      // `http.ClientException`, NOT `SocketException`: that is what the real
      // client throws. Verified in http 1.6.0 — `IOClient.send` catches
      // `SocketException` and rethrows `_ClientSocketException extends
      // ClientException` (io_client.dart:226), and on web everything is
      // normalized to `ClientException`. Classifying on `SocketException` would
      // also force a `dart:io` import into `lib/` and break the web build.
      //
      // `MockClient` does not wrap what its handler throws, so the exception has
      // to be built here exactly as the real client would.
      final client = MockClient(
        (_) async => throw http.ClientException('no network'),
      );

      await expectLater(
        dataSource(client).getAllCats(),
        throwsA(const NetworkFailure()),
      );
    });

    test('a timeout on /breeds throws TimeoutFailure', () async {
      final client = MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return jsonResponse(fixture('breeds_3.json'));
      });

      await expectLater(
        dataSource(
          client,
          timeout: const Duration(milliseconds: 20),
        ).getAllCats(),
        throwsA(const TimeoutFailure()),
      );
    });

    test('an unanticipated error throws UnknownFailure', () async {
      // The catch-all branch. Its existence is what lets the repository be a
      // total function.
      final client = MockClient(
        (_) async => throw StateError('very unexpected'),
      );

      await expectLater(
        dataSource(client).getAllCats(),
        throwsA(
          isA<UnknownFailure>().having(
            (f) => f.detail,
            'detail',
            contains('very unexpected'),
          ),
        ),
      );
    });
  });

  group('LandingCatsDataSource retry', () {
    /// Counts attempts and answers the first [failures] of them with [status].
    ({MockClient client, int Function() attempts}) flakyClient({
      required int failures,
      int status = 503,
    }) {
      var attempts = 0;
      final client = MockClient((request) async {
        attempts++;
        if (attempts <= failures) {
          return jsonResponse('{"error":"nope"}', status);
        }
        return jsonResponse(fixture('breeds_3.json'));
      });
      return (client: client, attempts: () => attempts);
    }

    test('a transient 503 is retried and the list still arrives', () async {
      // The user-visible payoff: before Phase 4 a single blip put the error screen
      // on the display and left the user to find the Retry button themselves.
      final r = flakyClient(failures: 2);

      final result = await LandingCatsDataSource(
        client: r.client,
        retryDelays: const [Duration.zero, Duration.zero],
      ).getAllCats();

      expect(result, hasLength(3));
      expect(r.attempts(), 3);
    });

    test('a 401 is not retried — retrying cannot fix the request', () async {
      final r = flakyClient(failures: 5, status: 401);

      await expectLater(
        LandingCatsDataSource(
          client: r.client,
          retryDelays: const [Duration.zero, Duration.zero],
        ).getAllCats(),
        throwsA(const ServerFailure(statusCode: 401)),
      );

      expect(r.attempts(), 1);
    });

    test('a malformed body is not retried either', () async {
      var attempts = 0;
      final client = MockClient((_) async {
        attempts++;
        return jsonResponse('{"message":"not an array"}');
      });

      await expectLater(
        LandingCatsDataSource(
          client: client,
          retryDelays: const [Duration.zero, Duration.zero],
        ).getAllCats(),
        throwsA(isA<UnexpectedResponseFailure>()),
      );

      expect(attempts, 1);
    });

    test('a persistent failure still surfaces its typed cause', () async {
      // Retrying must not flatten what the UI depends on to choose a message.
      final r = flakyClient(failures: 99);

      await expectLater(
        LandingCatsDataSource(
          client: r.client,
          retryDelays: const [Duration.zero],
        ).getAllCats(),
        throwsA(const ServerFailure(statusCode: 503)),
      );

      expect(r.attempts(), 2);
    });

    test('a failing image is attempted once and degrades quietly', () async {
      var attempts = 0;
      final client = MockClient((_) async {
        attempts++;
        return jsonResponse('{"error":"nope"}', 503);
      });

      final url = await LandingCatsDataSource(
        client: client,
        retryDelays: const [Duration.zero, Duration.zero],
      ).getBreedImageUrl('0XYvRd7oD');

      expect(url, '');
      expect(attempts, 1);

      // An honest note on what this does and does not prove, because the naive
      // version of this test was misleading.
      //
      // It was originally called "images are NOT retried" and read as if it pinned
      // a policy decision. It does not. Verified by mutation: wrapping
      // `getBreedImageUrl` in `withRetry` leaves this green, because
      // `getBreedImageUrl` never throws — it catches everything and returns `''`,
      // so a retry policy has no failure to act on and the wrapper is a no-op.
      //
      // So the single attempt is a consequence of the tolerance, not of a choice
      // about retrying. The real decision — that only `/breeds` is retried — is
      // visible in `getAllCats` and pinned by the cases above.
    });
  });

  group('LandingCatsDataSource.getBreedImageUrl', () {
    /// A client that only ever answers the image endpoint.
    ({MockClient client, List<String> urls}) imageClient({
      String fixtureName = 'image_ok.json',
      int status = 200,
      String? body,
    }) {
      final urls = <String>[];
      final client = MockClient((request) async {
        urls.add(request.url.toString());
        return jsonResponse(body ?? fixture(fixtureName), status);
      });
      return (client: client, urls: urls);
    }

    test('resolves the url from the payload', () async {
      final r = imageClient();

      final url = await dataSource(r.client).getBreedImageUrl('0XYvRd7oD');

      expect(url, 'https://cdn2.thecatapi.com/images/0XYvRd7oD.jpg');
      expect(r.urls, ['${Endpoints.urlForGetImageCat}0XYvRd7oD']);
    });

    test('an empty id resolves to "" without touching the network', () async {
      // 2 of the 67 breeds have no `reference_image_id`. The original code
      // requested them anyway — `GET /v1/images/` with no id — which returns 400
      // and was silently swallowed: two guaranteed wasted requests per launch.
      final r = imageClient();

      final url = await dataSource(r.client).getBreedImageUrl('');

      expect(url, '');
      expect(r.urls, isEmpty);
    });

    test('never throws, whatever goes wrong', () async {
      // Deliberately total. A broken image has to degrade to a placeholder, not
      // take down the screen — and before Phase 4 a single failing image request
      // aborted all 67 breeds.
      final cases = <String, MockClient>{
        '404': imageClient(status: 404).client,
        'no url key': imageClient(fixtureName: 'image_no_url.json').client,
        // Phase 3 replaced `(json.decode(body) as Map)["url"] as String?` with the
        // map pattern `{'url': final String url}`. The cast threw a `TypeError`
        // when the body was not a map; the pattern simply does not match.
        'not an object': imageClient(body: '["not", "an", "object"]').client,
        'not json': imageClient(body: 'nonsense').client,
        'transport failure': MockClient(
          (_) async => throw http.ClientException('no network'),
        ),
        'arbitrary error': MockClient((_) async => throw StateError('boom')),
      };

      for (final entry in cases.entries) {
        expect(
          await dataSource(entry.value).getBreedImageUrl('0XYvRd7oD'),
          '',
          reason: entry.key,
        );
      }
    });

    test('a timeout resolves to "" rather than propagating', () async {
      final client = MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return jsonResponse(fixture('image_ok.json'));
      });

      expect(
        await dataSource(
          client,
          timeout: const Duration(milliseconds: 20),
        ).getBreedImageUrl('0XYvRd7oD'),
        '',
      );
    });
  });
}
