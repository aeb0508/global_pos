import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProductImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final double borderRadius;
  final int? cacheSize;

  const ProductImageWidget({
    super.key,
    this.imageUrl,
    this.size = 56,
    this.borderRadius = 12,
    this.cacheSize,
  });

  Widget get _placeholder => SizedBox(
        height: size,
        width: size,
        child: Icon(Icons.inventory_2_outlined,
            color: Colors.grey.shade400, size: size * 0.4),
      );

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) return _placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        height: size,
        width: size,
        fit: BoxFit.cover,
        memCacheWidth: cacheSize,
        memCacheHeight: cacheSize,
        placeholder: (_, __) => _placeholder,
        errorWidget: (_, __, ___) => _placeholder,
      ),
    );
  }
}
