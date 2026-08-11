import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TextWidget extends StatelessWidget {
  const TextWidget({
    super.key,
    required this.text,
    this.textAlign,
    this.fontWeight,
    required this.fontSize,
    required this.colorText,
    this.fontStyle,
  });
  final String text;
  final TextAlign? textAlign;
  final FontWeight? fontWeight;
  final double fontSize;
  final Color colorText;
  final FontStyle? fontStyle;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      // `textAlign` was declared and never forwarded to the `Text`: the two
      // call sites using it (`detail_cat_page` and the search delegate) were
      // silent no-ops.
      textAlign: textAlign,
      style: GoogleFonts.acme(
        color: colorText,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
      ),
    );
  }
}
