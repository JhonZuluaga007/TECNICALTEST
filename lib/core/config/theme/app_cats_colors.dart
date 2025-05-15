import 'package:flutter/material.dart';

class AppCatsColor {
  Map<String, Color> mapColors = {
    "W": Colors.white,
    'BG': const Color.fromARGB(255, 240, 240, 240),
    "LigthGreen": const Color.fromARGB(255, 177, 224, 179),
    "LigthGrey": const Color.fromARGB(255, 225, 223, 223)
  };

  MaterialColor black = const MaterialColor(0xFF141414, {
    30: Color(0xFFCFCFCF),
    40: Color(0XFFAAAAAA),
    50: Color(0xFF5c5c5c),
    60: Color(0xFF707070),
    100: Color(0xFF464646),
    200: Color(0xFF303030),
    300: Color(0xFF1a1a1a),
    400: Color(0xFF040404),
    500: Color(0xFF141414),
    600: Color(0xFF000000),
    700: Color(0xFF000000),
    800: Color(0xFF000000),
    900: Color(0xFF000000),
  });

  MaterialColor lightBlue = MaterialColor(Colors.blue.value, {
    100: Colors.blue[100]!,
  });
}
