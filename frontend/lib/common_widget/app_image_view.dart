import 'package:flutter/material.dart';

import '../common/globs.dart';

class AppImageView extends StatelessWidget {
  final String? path;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String placeholderAsset;

  const AppImageView({
    super.key,
    required this.path,
    this.width = double.infinity,
    this.height = double.infinity,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderAsset = 'assets/img/app_logo.png',
  });

  @override
  Widget build(BuildContext context) {
    final value = (path ?? '').trim();
    final Widget image;

    if (value.isEmpty) {
      image = Image.asset(
        placeholderAsset,
        width: width,
        height: height,
        fit: fit,
      );
    } else if (value.startsWith('http')) {
      image = Image.network(
        value,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          placeholderAsset,
          width: width,
          height: height,
          fit: fit,
        ),
      );
    } else {
      final resolvedPath = value.startsWith('/') ? '${SVKey.mainUrl}$value' : value;
      image = Image.network(
        resolvedPath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          placeholderAsset,
          width: width,
          height: height,
          fit: fit,
        ),
      );
    }

    if (borderRadius == null) {
      return image;
    }

    return ClipRRect(
      borderRadius: borderRadius!,
      child: image,
    );
  }
}
