import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:tecnical_test_pragma/core/config/helpers/endpoints.dart';
import 'package:tecnical_test_pragma/core/errors/cats_failure.dart';
import 'package:tecnical_test_pragma/core/utils/retry.dart';
import 'package:tecnical_test_pragma/features/landing_cats/data/models/catbreed_model.dart';

class LandingCatsDataSource {
  /// [client] is injected so tests can pass a `MockClient`. The code previously
  /// called the top-level `http.get`, so there was no seam at all.
  ///
  /// [timeout] and [retryDelays] are parameters so tests can force a 20 ms timeout
  /// and retry without spending real wall-clock time.
  LandingCatsDataSource({
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
    this.retryDelays = const [
      Duration(milliseconds: 400),
      Duration(seconds: 1),
    ],
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  /// One entry per retry of `/breeds`; empty disables retrying.
  final List<Duration> retryDelays;

  /// Fetches every breed in **one** request.
  ///
  /// This is Phase 4's headline change. It used to make 66: one for `/breeds`
  /// plus one `GET /v1/images/{id}` for each of the 65 breeds carrying a
  /// `reference_image_id`, all of them before the first frame could be painted.
  /// Phase 2 had softened that with bounded concurrency (67 serial round-trips
  /// down to ~11 batches of 6), but the user was still waiting on 65 images to
  /// see the 3 cards that fit on screen.
  ///
  /// Resolving image URLs is now [getBreedImageUrl], called per card as the list
  /// builds them. Measured against the live API, this is not an optimisation that
  /// could have been skipped: `/v1/breeds` carries no image data at all (`0/67`
  /// breeds have an `image` key), and while every URL does follow
  /// `cdn2.thecatapi.com/images/{id}.{ext}`, the extension is not always `.jpg` —
  /// 3 of the 65 are `.png`, and requesting those as `.jpg` returns 403. So the
  /// URL genuinely has to be asked for; the fix is asking lazily, not asking less.
  ///
  /// Retried on transient failures. Only this call is: image resolution already
  /// degrades to a placeholder, and retrying 65 of those would multiply the wait
  /// for something the user barely notices. This one is the difference between a
  /// list and an error screen.
  Future<List<CatBreedModel>> getAllCats() =>
      withRetry(_fetchBreeds, delays: retryDelays);

  Future<List<CatBreedModel>> _fetchBreeds() async {
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

      return [
        for (final raw in decoded.cast<Map<String, dynamic>>())
          CatBreedModel.fromJson(raw),
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

  /// Resolves one breed's image URL, or `""` if it could not be obtained.
  ///
  /// Was `_imageUrlFor`, private and called 65 times in a burst from
  /// [getAllCats]. Now public and called once per visible card.
  ///
  /// Deliberately never throws. Letting one broken image take down the whole
  /// screen was worse UX than a placeholder, and "this breed has no photo" is not
  /// an error state — 2 of the 67 breeds genuinely have no
  /// `reference_image_id`.
  Future<String> getBreedImageUrl(String referenceImageId) async {
    // The old code requested these anyway, i.e. `GET /v1/images/` with no id,
    // which returns 400 and was silently swallowed: two guaranteed wasted
    // requests on every launch.
    if (referenceImageId.isEmpty) return "";

    try {
      final response = await _client
          .get(
            Uri.parse("${Endpoints.urlForGetImageCat}$referenceImageId"),
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
