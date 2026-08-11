import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:tecnical_test_pragma/core/config/helpers/endpoints.dart';
import 'package:tecnical_test_pragma/core/config/helpers/errors/invalid_data.dart';
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
        throw InvalidData(
          message: "Service request failed",
          statusCode: response.statusCode,
        );
      }
      if (response.body.isEmpty) return const [];

      final raw = (json.decode(response.body) as List)
          .cast<Map<String, dynamic>>();

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
    } on InvalidData {
      // Without this `rethrow` the `catch` below re-wrapped the `InvalidData`
      // thrown above, and the message ended up as
      // "Service error: Instance of 'InvalidData'".
      rethrow;
    } catch (error) {
      // `response` is no longer in scope here: a transport failure has no HTTP
      // status to report.
      throw InvalidData(message: "Service error: $error", statusCode: null);
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
      final map = json.decode(response.body) as Map<String, dynamic>;
      // Previously: `catBreedModel.urlImage = mapInfo["url"]`, an unchecked
      // dynamic cast into a non-nullable `String`, while mutating the entity.
      return (map["url"] as String?) ?? "";
    } catch (_) {
      return "";
    }
  }
}
