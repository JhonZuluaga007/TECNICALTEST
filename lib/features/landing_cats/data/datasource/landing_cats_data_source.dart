import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:tecnical_test_pragma/core/config/helpers/endpoints.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/core/utils/map_with_concurrency.dart';
import 'package:tecnical_test_pragma/features/landing_cats/data/models/catbreed_model.dart';

class LandingCatsDataSource {
  /// [client] is injected so tests can pass a `MockClient`. The code previously
  /// called the top-level `http.get`, so there was no seam at all.
  ///
  /// [timeout] and [imageConcurrency] are parameters so tests can force a 20 ms
  /// timeout and assert the in-flight request limit without depending on real
  /// wall-clock time.
  LandingCatsDataSource({
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
    this.imageConcurrency = 6,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;
  final int imageConcurrency;

  Future<List<CatBreedModel>> getAllCats() async {
    // The `try` wraps the FIRST await. It used to start after the first
    // `http.get`, so a `SocketException` on `/breeds` escaped raw: the
    // repository's `on InvalidData` did not catch it and the bloc's `fold` never
    // ran.
    try {
      final response = await _client
          .get(Uri.parse(Endpoints.urlAllCats), headers: Endpoints.authHeader)
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw ServerFailure(statusCode: response.statusCode);
      }
      if (response.body.isEmpty) return const [];

      final decoded = json.decode(response.body);
      // Phase 3: the shape is checked instead of blind-cast. `as List` on a
      // valid-but-wrong payload (an object, a number) threw a `TypeError`, which
      // then got stringified into a message nobody could act on.
      if (decoded is! List) {
        throw const UnexpectedResponseFailure(
          detail: 'Expected a JSON array of breeds',
        );
      }
      final raw = decoded.cast<Map<String, dynamic>>();

      // `/breeds` carries no images, so each one has to be resolved separately.
      // Bounded concurrency instead of sequential: 67 breeds go from 67 serial
      // round-trips to roughly 11 batches of 6.
      //
      // Phase 4 removes the N+1 at the root: `getAllCats` will make a single
      // request and each card will resolve its own image on demand.
      final urls = await mapWithConcurrency<Map<String, dynamic>, String>(raw, (
        breed,
      ) async {
        final referenceId = (breed["reference_image_id"] as String?) ?? "";
        // 2 of the 67 breeds (`European Burmese` and `Malayan`) have
        // `reference_image_id: null`. The old code requested them anyway, i.e.
        // `GET /v1/images/` with no id, which returns 400 and was silently
        // swallowed. Two guaranteed wasted requests on every launch.
        if (referenceId.isEmpty) return "";
        return _imageUrlFor(referenceId);
      }, concurrency: imageConcurrency);

      return [
        for (var i = 0; i < raw.length; i++)
          CatBreedModel.fromMap(raw[i], urlImage: urls[i]),
      ];
    } on CatsFailure {
      // Without this `rethrow` the clauses below would re-wrap the failure thrown
      // above. Phase 2 hit exactly that: the message became
      // "Service error: Instance of 'InvalidData'".
      rethrow;
    } on TimeoutException {
      throw const TimeoutFailure();
    } on http.ClientException {
      // NOT `on SocketException`: that lives in `dart:io` and importing it here
      // would break the web build. It is also unnecessary — verified in
      // http 1.6.0: `IOClient.send` catches `SocketException` and rethrows
      // `_ClientSocketException extends ClientException` (io_client.dart:226),
      // and on web `_toClientException` normalizes everything to
      // `ClientException` (browser_client.dart:148). So this one clause covers
      // transport failures on every platform.
      throw const NetworkFailure();
    } on FormatException catch (error) {
      // A 200 with a body that is not JSON at all.
      throw UnexpectedResponseFailure(detail: error.message);
    } on TypeError catch (error) {
      // A 200 with valid JSON whose fields are not the types the model expects.
      throw UnexpectedResponseFailure(detail: '$error');
    } catch (error) {
      throw UnknownFailure(detail: '$error');
    }
  }

  /// Returns the image URL, or `""` if it could not be obtained.
  ///
  /// Deliberately never throws: letting one broken image take down all 67 breeds
  /// was worse UX, and with concurrency a `Future.wait` with two errors would
  /// leave one unhandled.
  Future<String> _imageUrlFor(String referenceId) async {
    try {
      final response = await _client
          .get(
            Uri.parse("${Endpoints.urlForGetImageCat}$referenceId"),
            headers: Endpoints.authHeader,
          )
          .timeout(timeout);

      if (response.statusCode != 200) return "";

      // A map pattern, not a cast. Previously:
      // `(json.decode(body) as Map<String, dynamic>)["url"] as String?`, which
      // threw a `TypeError` when the body was not a map at all. The pattern
      // simply does not match, and both "not a map" and "no usable url" collapse
      // into the same harmless empty string.
      return switch (json.decode(response.body)) {
        {'url': final String url} => url,
        _ => "",
      };
    } catch (_) {
      return "";
    }
  }
}
