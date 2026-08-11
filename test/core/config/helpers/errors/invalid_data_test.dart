import 'package:flutter_test/flutter_test.dart';
import 'package:tecnical_test_pragma/core/config/helpers/errors/invalid_data.dart';

void main() {
  group('InvalidData', () {
    test('is equal by value', () {
      expect(
        const InvalidData(message: 'boom', statusCode: 500),
        const InvalidData(message: 'boom', statusCode: 500),
      );
    });

    test('differs by statusCode', () {
      expect(
        const InvalidData(message: 'boom', statusCode: 500),
        isNot(const InvalidData(message: 'boom', statusCode: 404)),
      );
    });

    test('differs by message', () {
      expect(
        const InvalidData(message: 'boom', statusCode: 500),
        isNot(const InvalidData(message: 'other', statusCode: 500)),
      );
    });

    test('hashCode is consistent with ==', () {
      expect(
        const InvalidData(message: 'boom', statusCode: 500).hashCode,
        const InvalidData(message: 'boom', statusCode: 500).hashCode,
      );
    });

    test('is an Exception', () {
      // It was thrown without being an Exception. Now it declares it.
      expect(
        const InvalidData(message: 'boom', statusCode: 500),
        isA<Exception>(),
      );
    });

    test('toString exposes the status and the message', () {
      // It had no `toString`, which is why the datasource's double-wrapping
      // produced "Service error: Instance of 'InvalidData'".
      expect(
        const InvalidData(message: 'boom', statusCode: 500).toString(),
        contains('500'),
      );
    });
  });
}
