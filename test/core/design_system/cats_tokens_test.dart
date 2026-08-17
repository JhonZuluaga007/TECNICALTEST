import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tecnical_test_pragma/core/design_system/cats_tokens.dart';

void main() {
  group('CatsTokens.copyWith', () {
    test('replaces only what it is given', () {
      final result = CatsTokens.light.copyWith(
        ratingFilled: const Color(0xFF123456),
      );

      expect(result.ratingFilled, const Color(0xFF123456));
      expect(result.ratingEmpty, CatsTokens.light.ratingEmpty);
    });
  });

  group('CatsTokens.lerp', () {
    test('interpolates both colours halfway', () {
      // Both, not one. A `lerp` that forwards `ratingFilled` and returns
      // `this.ratingEmpty` compiles, satisfies `ThemeExtension`, and makes the
      // meter's two colours drift apart mid-animation on every theme switch.
      final result = CatsTokens.light.lerp(CatsTokens.dark, 0.5);

      expect(
        result.ratingFilled,
        Color.lerp(
          CatsTokens.light.ratingFilled,
          CatsTokens.dark.ratingFilled,
          0.5,
        ),
      );
      expect(
        result.ratingEmpty,
        Color.lerp(
          CatsTokens.light.ratingEmpty,
          CatsTokens.dark.ratingEmpty,
          0.5,
        ),
      );
      // And halfway is genuinely between the endpoints, so a `lerp` that ignores
      // `t` and returns either side cannot pass.
      expect(result.ratingFilled, isNot(CatsTokens.light.ratingFilled));
      expect(result.ratingFilled, isNot(CatsTokens.dark.ratingFilled));
    });

    test('t = 0 and t = 1 are the endpoints', () {
      expect(
        CatsTokens.light.lerp(CatsTokens.dark, 0).ratingFilled,
        CatsTokens.light.ratingFilled,
      );
      expect(
        CatsTokens.light.lerp(CatsTokens.dark, 1).ratingFilled,
        CatsTokens.dark.ratingFilled,
      );
    });

    test('a null other returns this unchanged', () {
      // `ThemeExtension.lerp` is declared with a nullable `other`, and Flutter
      // does pass null — a theme that registers the extension animating against
      // one that does not. Returning `this` is the only sane answer; throwing
      // would crash a theme transition.
      final result = CatsTokens.light.lerp(null, 0.5);

      expect(result.ratingFilled, CatsTokens.light.ratingFilled);
      expect(result.ratingEmpty, CatsTokens.light.ratingEmpty);
    });
  });
}
