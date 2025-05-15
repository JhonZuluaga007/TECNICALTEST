import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ResponsiveBox extends StatelessWidget {
  const ResponsiveBox({
    Key? key,
    this.child,
    this.height,
    this.width,
  }) : super(key: key);
  final Widget? child;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width?.w, height: height?.h, child: child);
  }
}
