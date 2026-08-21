import 'package:freezed_annotation/freezed_annotation.dart';

part 'cats_failure.freezed.dart';

/// Everything that can go wrong while fetching cat breeds.
///
/// Phase 3 replaced `InvalidData`, which collapsed every cause — no connection,
/// timeout, HTTP 500, malformed JSON — into one interpolated `String`
/// (`"Service error: $error"`). The UI could not make a single decision from
/// that, which is one of the reasons there was no error branch at all.
///
/// `sealed` is the point: a `switch` over a `CatsFailure` is checked for
/// exhaustiveness by the compiler, so adding a variant here forces every
/// consumer to handle it.
///
/// Phase 4 moved the hand-written `Equatable` subclasses to `freezed`. The
/// modelling is unchanged and so are the variant names, which is why every
/// `switch` over this type compiled without a single edit. What changed is that
/// `==`/`hashCode` are generated instead of maintained by hand.
///
/// `implements Exception` because the data source throws these. It sits on the
/// base rather than on each variant so `on CatsFailure` catches all of them.
@freezed
sealed class CatsFailure with _$CatsFailure implements Exception {
  /// The request never reached the server (no connection, DNS, refused socket).
  ///
  /// Classified from `http.ClientException`, deliberately not from
  /// `SocketException`: see the note on `LandingCatsDataSource.getAllCats`.
  const factory CatsFailure.network() = NetworkFailure;

  /// The request was sent but did not answer within
  /// `LandingCatsDataSource.timeout`.
  const factory CatsFailure.timeout() = TimeoutFailure;

  /// The server answered with a status other than 200.
  const factory CatsFailure.server({required int statusCode}) = ServerFailure;

  /// The server answered 200 with a body we cannot read.
  ///
  /// [detail] is a technical description, for tests and future logging. **Not**
  /// the copy shown to the user: that mapping lives in the presentation layer
  /// (`status_views.dart`).
  const factory CatsFailure.unexpectedResponse({required String detail}) =
      UnexpectedResponseFailure;

  /// The breed asked for does not exist.
  ///
  /// Added in Phase 6, when the detail screen stopped receiving a whole
  /// `CatBreedEntity` through `go_router`'s `extra` and started receiving an id
  /// from the URL. An id can now be wrong — a stale deep link, a typed URL, a
  /// breed the API dropped — and that is a distinct outcome from "the request
  /// failed": there is nothing to retry, and the copy should say so.
  const factory CatsFailure.notFound({required String id}) = NotFoundFailure;

  /// Anything we did not anticipate.
  ///
  /// Its existence is what lets the repository be a total function: nothing above
  /// the data layer should ever see a raw exception.
  const factory CatsFailure.unknown({required String detail}) = UnknownFailure;
}
