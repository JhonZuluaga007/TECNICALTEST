import 'package:flutter/material.dart';
import 'package:tecnical_test_pragma/core/config/theme/app_cats_colors.dart';

import '../../cats_icons.dart';

class NetworkImageWidget extends StatelessWidget {
  const NetworkImageWidget(
      {super.key,
      required this.imageUrl,
      this.width,
      this.height,
      this.boxFit});
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? boxFit;

  @override
  Widget build(BuildContext context) {
    final wColor = AppCatsColor();

    return Image.network(
      imageUrl,
      width: width,
      height: height ?? 250,
      fit: boxFit ?? BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        if (stackTrace != null) {
          return Image.asset(
            CatsIcons.notImage,
            height: 250,
          );
        } else {
          return Image.network(
            imageUrl,
            height: 250,
          );
        }
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        } else {
          return Center(
            child: CircularProgressIndicator(
              color: wColor.black,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        }
      },
    );
  }
}
