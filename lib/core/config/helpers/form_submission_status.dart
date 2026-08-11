import 'package:equatable/equatable.dart';

/// Status of the service request.
///
/// Phase 2: became `Equatable` so `LandingCatsState` can be compared by value.
/// Without it, `SubmissionSuccess() == SubmissionSuccess()` is `false` and every
/// `bloc_test` `expect:` would have to fall back to `isA<>()` matchers.
///
/// Phase 3 replaces this hierarchy with a `sealed class CatsStatus`, whose
/// exhaustive `switch` forces writing the error branch that does not exist today.
abstract class FormSubmissionStatus extends Equatable {
  const FormSubmissionStatus();

  @override
  List<Object?> get props => const [];
}

class InitialFormStatus extends FormSubmissionStatus {
  const InitialFormStatus();
}

class FormSubmitting extends FormSubmissionStatus {
  const FormSubmitting();
}

class SubmissionSuccess extends FormSubmissionStatus {
  const SubmissionSuccess();
}

class SubmissionFailed extends FormSubmissionStatus {
  const SubmissionFailed({required this.exception});

  final Exception exception;

  /// `exception.toString()` rather than `exception`: `Exception('boom')` builds
  /// a `_Exception` that defines no `==`, so two identical `SubmissionFailed`
  /// instances would never compare equal and the failure path could not be
  /// asserted by value. The `toString()` ("Exception: boom") is stable.
  @override
  List<Object?> get props => [exception.toString()];
}
