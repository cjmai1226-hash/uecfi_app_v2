import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserAvatar extends StatelessWidget {
  final String authorName;
  final String? localAvatarPath;
  final String? avatarUrl;
  final double radius;
  final Color? backgroundColor;
  final TextStyle? textStyle;

  const UserAvatar({
    super.key,
    required this.authorName,
    this.localAvatarPath,
    this.avatarUrl,
    this.radius = 20.0,
    this.backgroundColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = authorName.trim().isNotEmpty
        ? authorName.trim()[0].toUpperCase()
        : 'M';

    // 1. Local avatar file (for current user instant offline display)
    if (localAvatarPath != null &&
        localAvatarPath!.isNotEmpty &&
        File(localAvatarPath!).existsSync()) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.transparent,
        backgroundImage: FileImage(File(localAvatarPath!)),
      );
    }

    // 2. Network Cached Avatar (from Firebase Cloud Storage)
    if (avatarUrl != null && avatarUrl!.trim().isNotEmpty && avatarUrl!.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: avatarUrl!.trim(),
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor ?? Colors.transparent,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor ?? theme.colorScheme.primary.withValues(alpha: 0.15),
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
        errorWidget: (context, url, error) => CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor ?? theme.colorScheme.primary,
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
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? theme.colorScheme.primary,
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
