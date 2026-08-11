import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:tecnical_test_pragma/core/config/helpers/endpoints.dart';
import 'package:tecnical_test_pragma/core/config/helpers/errors/invalid_data.dart';
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
      final sinImagen = result.where((b) => b.urlImage.isEmpty);
      expect(sinImagen, hasLength(2));
      expect(
        sinImagen.map((b) => b.name),
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

    test('a status != 200 throws InvalidData WITHOUT double wrapping', () async {
      // The general `catch` also caught the `throw InvalidData` from the status
      // check and re-wrapped it, so the message ended up as
      // "Service error: Instance of 'InvalidData'" and the original was lost.
      // `on InvalidData { rethrow; }` fixes it.
      final r = routedClient(breedsFixture: 'breeds_3.json', breedsStatus: 500);

      await expectLater(
        LandingCatsDataSource(client: r.client).getAllCats(),
        throwsA(
          const InvalidData(message: 'Service request failed', statusCode: 500),
        ),
      );
    });

    test('a malformed body throws InvalidData with no statusCode', () async {
      final r = routedClient(
        breedsFixture: 'breeds_3.json',
        breedsBody: 'no soy json',
      );

      await expectLater(
        LandingCatsDataSource(client: r.client).getAllCats(),
        throwsA(
          isA<InvalidData>()
              .having((e) => e.statusCode, 'statusCode', isNull)
              .having(
                (e) => e.message,
                'message',
                startsWith('Service error:'),
              ),
        ),
      );
    });

    test('a transport failure on /breeds is wrapped in InvalidData', () async {
      // The first `http.get` used to sit OUTSIDE the `try`, so a
      // `SocketException` escaped raw: the repository's `on InvalidData` did not
      // catch it and the bloc's `fold` never ran.
      final client = MockClient(
        (_) async => throw const SocketException('no network'),
      );

      await expectLater(
        LandingCatsDataSource(client: client).getAllCats(),
        throwsA(
          isA<InvalidData>().having((e) => e.statusCode, 'statusCode', isNull),
        ),
      );
    });

    test('a timeout on /breeds is wrapped in InvalidData', () async {
      final client = MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return jsonResponse(fixture('breeds_3.json'));
      });

      await expectLater(
        LandingCatsDataSource(
          client: client,
          timeout: const Duration(milliseconds: 20),
        ).getAllCats(),
        throwsA(isA<InvalidData>()),
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

    test('a network failure fetching an image does not break the list', () async {
      // Intentional behavior change: any failure in one of the N image requests
      // used to abort all 67 breeds.
      final client = MockClient((request) async {
        if (request.url.toString() == Endpoints.urlAllCats) {
          return jsonResponse(fixture('breeds_3.json'));
        }
        throw const SocketException('no network');
      });

      final result = await LandingCatsDataSource(client: client).getAllCats();

      expect(result, hasLength(3));
      expect(result.map((b) => b.urlImage), everyElement(''));
    });
  });
}
