import 'package:flutter/material.dart';

import '../../cats_icons.dart';

class NetworkImageWidget extends StatelessWidget {
  const NetworkImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.boxFit,
  });
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? boxFit;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      width: width,
      height: height ?? 250,
      fit: boxFit ?? BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        if (stackTrace != null) {
          return Image.asset(CatsIcons.notImage, height: 250);
        } else {
          return Image.network(imageUrl, height: 250);
        }
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        } else {
          return Center(
            // Phase 7: the colour was a hardcoded near-black. Left to the theme,
            // a progress indicator takes `colorScheme.primary`, which is the
            // role for it and which follows the active brightness.
            child: CircularProgressIndicator(
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
