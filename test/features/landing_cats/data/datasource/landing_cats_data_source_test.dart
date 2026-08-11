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

  group('LandingCatsDataSource.getAllCats', () {
    test('requests /breeds with the auth header', () async {
      final r = routedClient(breedsFixture: 'breeds_empty.json');

      await LandingCatsDataSource(client: r.client).getAllCats();

      expect(r.urls, [Endpoints.urlAllCats]);
      expect(r.headers.first, containsPair('api-key', isNotEmpty));
    });

    test('maps the happy path and resolves each breed image', () async {
      final r = routedClient(breedsFixture: 'breeds_3.json');

      final result = await LandingCatsDataSource(client: r.client).getAllCats();

      expect(result, hasLength(3));
      expect(result.first.name, 'Abyssinian');
      expect(
        result.map((b) => b.urlImage),
        everyElement('https://cdn2.thecatapi.com/images/0XYvRd7oD.jpg'),
      );
      // 1 breeds request + 3 image requests.
      expect(r.urls, hasLength(4));
    });

    test(
      'requests the image at /images/{referenceImageId} with the header',
      () async {
        final r = routedClient(breedsFixture: 'breeds_3.json');

        await LandingCatsDataSource(client: r.client).getAllCats();

        expect(
          r.urls.skip(1),
          everyElement(startsWith(Endpoints.urlForGetImageCat)),
        );
        expect(r.urls, contains('${Endpoints.urlForGetImageCat}0XYvRd7oD'));
        expect(r.headers.last, containsPair('api-key', isNotEmpty));
      },
    );

    test('makes 66 requests for the 67 real breeds, not 68', () async {
      // The headline test for this fix. Before: 1 + 67 = 68 requests, 2 of them
      // `GET /v1/images/` with NO id, which the API answers with 400 and the code
      // silently swallowed. Guaranteed garbage on every launch.
      final r = routedClient(breedsFixture: 'breeds_full.json');

      final result = await LandingCatsDataSource(client: r.client).getAllCats();

      expect(result, hasLength(67));
      expect(
        r.urls,
        hasLength(66),
        reason: '1 breeds request + 65 image requests',
      );
      expect(
        r.urls,
        isNot(contains(Endpoints.urlForGetImageCat)),
        reason: '/images/ is never requested without an id',
      );
      // And the 2 breeds with no image end up with an empty urlImage, not broken.
      final withoutImage = result.where((b) => b.urlImage.isEmpty);
      expect(withoutImage, hasLength(2));
      expect(
        withoutImage.map((b) => b.name),
        containsAll(['European Burmese', 'Malayan']),
      );
    });

    test('does not exceed the in-flight image request limit', () async {
      var inFlight = 0;
      var maxInFlight = 0;
      final client = MockClient((request) async {
        if (request.url.toString() == Endpoints.urlAllCats) {
          return jsonResponse(fixture('breeds_full.json'));
        }
        inFlight++;
        maxInFlight = inFlight > maxInFlight ? inFlight : maxInFlight;
        await Future<void>.delayed(Duration.zero);
        inFlight--;
        return jsonResponse(fixture('image_ok.json'));
      });

      await LandingCatsDataSource(
        client: client,
        imageConcurrency: 4,
      ).getAllCats();

      expect(maxInFlight, 4);
    });

    test('preserves the breed order from the payload', () async {
      final r = routedClient(breedsFixture: 'breeds_3.json');

      final result = await LandingCatsDataSource(client: r.client).getAllCats();

      expect(result.map((b) => b.id), ['abys', 'aege', 'abob']);
    });

    test(
      'returns an empty list for an empty array, without requesting images',
      () async {
        final r = routedClient(breedsFixture: 'breeds_empty.json');

        final result = await LandingCatsDataSource(
          client: r.client,
        ).getAllCats();

        expect(result, isEmpty);
        expect(r.urls, hasLength(1));
      },
    );

    test('returns an empty list for an empty body', () async {
      final r = routedClient(breedsFixture: 'breeds_3.json', breedsBody: '');

      final result = await LandingCatsDataSource(client: r.client).getAllCats();

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
        LandingCatsDataSource(client: r.client).getAllCats(),
        throwsA(const ServerFailure(statusCode: 500)),
      );
    });

    test('a 401 throws ServerFailure(401), not a generic failure', () async {
      // Not hypothetical: the API key hardcoded in `Endpoints` returns 401 today,
      // so this is the failure the running app actually produces.
      final r = routedClient(breedsFixture: 'breeds_3.json', breedsStatus: 401);

      await expectLater(
        LandingCatsDataSource(client: r.client).getAllCats(),
        throwsA(const ServerFailure(statusCode: 401)),
      );
    });

    test('a body that is not JSON throws UnexpectedResponseFailure', () async {
      final r = routedClient(
        breedsFixture: 'breeds_3.json',
        breedsBody: 'not json at all',
      );

      await expectLater(
        LandingCatsDataSource(client: r.client).getAllCats(),
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
        LandingCatsDataSource(client: r.client).getAllCats(),
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
        LandingCatsDataSource(client: client).getAllCats(),
        throwsA(const NetworkFailure()),
      );
    });

    test('a timeout on /breeds throws TimeoutFailure', () async {
      final client = MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return jsonResponse(fixture('breeds_3.json'));
      });

      await expectLater(
        LandingCatsDataSource(
          client: client,
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
        LandingCatsDataSource(client: client).getAllCats(),
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

  group('fault-tolerant image resolution', () {
    test(
      'an image returning 404 leaves urlImage empty without breaking the list',
      () async {
        final r = routedClient(
          breedsFixture: 'breeds_3.json',
          imageStatus: 404,
        );

        final result = await LandingCatsDataSource(
          client: r.client,
        ).getAllCats();

        expect(result, hasLength(3));
        expect(result.map((b) => b.urlImage), everyElement(''));
      },
    );

    test('an image response with no url key leaves urlImage empty', () async {
      // Previously: `catBreedModel.urlImage = mapInfo["url"]`, i.e. assigning
      // `null` into a non-nullable `String`.
      final r = routedClient(
        breedsFixture: 'breeds_3.json',
        imageFixture: 'image_no_url.json',
      );

      final result = await LandingCatsDataSource(client: r.client).getAllCats();

      expect(result.map((b) => b.urlImage), everyElement(''));
    });

    test('an image response that is not an object leaves urlImage empty', () async {
      // Phase 3 replaced `(json.decode(body) as Map)["url"] as String?` with the
      // map pattern `{'url': final String url}`. The cast threw a `TypeError` when
      // the body was not a map; the pattern simply does not match.
      final client = MockClient((request) async {
        if (request.url.toString() == Endpoints.urlAllCats) {
          return jsonResponse(fixture('breeds_3.json'));
        }
        return jsonResponse('["not", "an", "object"]');
      });

      final result = await LandingCatsDataSource(client: client).getAllCats();

      expect(result, hasLength(3));
      expect(result.map((b) => b.urlImage), everyElement(''));
    });

    test('a network failure fetching an image does not break the list', () async {
      // Intentional behavior change: any failure in one of the N image requests
      // used to abort all 67 breeds.
      final client = MockClient((request) async {
        if (request.url.toString() == Endpoints.urlAllCats) {
          return jsonResponse(fixture('breeds_3.json'));
        }
        throw http.ClientException('no network');
      });

      final result = await LandingCatsDataSource(client: client).getAllCats();

      expect(result, hasLength(3));
      expect(result.map((b) => b.urlImage), everyElement(''));
    });
  });
}
