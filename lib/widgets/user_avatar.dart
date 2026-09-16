import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserAvatar extends StatelessWidget {
  final String authorName;
  final String? localAvatarPath;
  final String? avatarUrl;
  final double radius;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final TextStyle? textStyle;

  const UserAvatar({
    super.key,
    required this.authorName,
    this.localAvatarPath,
    this.avatarUrl,
    this.radius = 20.0,
    this.borderRadius,
    this.backgroundColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = radius * 2;
    final r = borderRadius ?? BorderRadius.circular(radius * 0.45);
    final initial = authorName.trim().isNotEmpty
        ? authorName.trim()[0].toUpperCase()
        : 'M';

    // 1. Local avatar file (for current user instant offline display)
    if (localAvatarPath != null &&
        localAvatarPath!.isNotEmpty &&
        File(localAvatarPath!).existsSync()) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.transparent,
          borderRadius: r,
          image: DecorationImage(
            image: FileImage(File(localAvatarPath!)),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // 2. Network Cached Avatar (from Firebase Cloud Storage)
    if (avatarUrl != null &&
        avatarUrl!.trim().isNotEmpty &&
        avatarUrl!.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: avatarUrl!.trim(),
        imageBuilder: (context, imageProvider) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.transparent,
            borderRadius: r,
            image: DecorationImage(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor ??
                theme.colorScheme.primary.withValues(alpha: 0.15),
            borderRadius: r,
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: textStyle ??
                TextStyle(
                  fontSize: radius * 0.8,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor ?? theme.colorScheme.primary,
            borderRadius: r,
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: textStyle ??
                TextStyle(
                  fontSize: radius * 0.8,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
        ),
      );
    }

    // 3. Default Initial Letter Avatar
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.primary,
        borderRadius: r,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: textStyle ??
            TextStyle(
              fontSize: radius * 0.8,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
      ),
    );
  }
}
