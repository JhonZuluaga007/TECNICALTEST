import 'package:flutter_test/flutter_test.dart';
import 'package:tecnical_test_pragma/core/config/helpers/form_submission_status.dart';

void main() {
  group('FormSubmissionStatus', () {
    test('two instances of the same variant are equal', () {
      expect(const InitialFormStatus(), const InitialFormStatus());
      expect(const FormSubmitting(), const FormSubmitting());
      expect(const SubmissionSuccess(), const SubmissionSuccess());
    });

    test('different variants are not equal', () {
      expect(const FormSubmitting(), isNot(const SubmissionSuccess()));
      expect(const InitialFormStatus(), isNot(const FormSubmitting()));
      expect(
        const SubmissionSuccess(),
        isNot(SubmissionFailed(exception: Exception('boom'))),
      );
    });

    test('SubmissionFailed is equal by its exception message', () {
      // This is the case that makes asserting concrete states in
      // `blocTest.expect` possible instead of falling back to matchers:
      // `Exception` defines no `==`, so `props` uses `exception.toString()`.
      expect(
        SubmissionFailed(exception: Exception('boom')),
        SubmissionFailed(exception: Exception('boom')),
      );
      expect(
        SubmissionFailed(exception: Exception('boom')),
        isNot(SubmissionFailed(exception: Exception('other'))),
      );
    });

    test('hashCode is consistent with ==', () {
      expect(
        const SubmissionSuccess().hashCode,
        const SubmissionSuccess().hashCode,
      );
      expect(
        SubmissionFailed(exception: Exception('boom')).hashCode,
        SubmissionFailed(exception: Exception('boom')).hashCode,
      );
    });
  });
}
