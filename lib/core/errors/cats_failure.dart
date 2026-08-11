import 'package:equatable/equatable.dart';

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
/// `implements Exception` because the data source throws these.
///
/// Phase 4 regenerates this hierarchy with `freezed`; the modelling stays.
sealed class CatsFailure extends Equatable implements Exception {
  const CatsFailure();

  @override
  List<Object?> get props => const [];
}

/// The request never reached the server (no connection, DNS, refused socket).
///
/// Classified from `http.ClientException`, deliberately not from
/// `SocketException`: see the note on `LandingCatsDataSource.getAllCats`.
final class NetworkFailure extends CatsFailure {
  const NetworkFailure();
}

/// The request was sent but did not answer within `LandingCatsDataSource.timeout`.
final class TimeoutFailure extends CatsFailure {
  const TimeoutFailure();
}

/// The server answered with a status other than 200.
final class ServerFailure extends CatsFailure {
  const ServerFailure({required this.statusCode});

  final int statusCode;

  @override
  List<Object?> get props => [statusCode];
}

/// The server answered 200 with a body we cannot read.
final class UnexpectedResponseFailure extends CatsFailure {
  const UnexpectedResponseFailure({required this.detail});

  /// Technical description, for tests and future logging. **Not** the copy shown
  /// to the user: that mapping lives in the presentation layer
  /// (`landing_status_views.dart`).
  final String detail;

  @override
  List<Object?> get props => [detail];
}

/// Anything we did not anticipate.
///
/// Its existence is what lets the repository be a total function: nothing above
/// the data layer should ever see a raw exception.
final class UnknownFailure extends CatsFailure {
  const UnknownFailure({required this.detail});

  final String detail;

  @override
  List<Object?> get props => [detail];
}
