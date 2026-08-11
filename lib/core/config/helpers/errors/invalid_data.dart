import 'package:equatable/equatable.dart';

/// Data-layer error.
///
/// Phase 2: became `Equatable`, with `final` fields and `implements Exception`.
/// It previously had mutable fields (and therefore an unstable `hashCode`) and
/// was not an `Exception`, even though it was thrown.
///
/// Phase 3 replaces it with a `sealed class CatsFailure` carrying variants.
class InvalidData extends Equatable implements Exception {
  const InvalidData({required this.message, required this.statusCode});

  final int? statusCode;
  final String? message;

  @override
  List<Object?> get props => [statusCode, message];

  @override
  String toString() =>
      'InvalidData(statusCode: $statusCode, message: $message)';
}
