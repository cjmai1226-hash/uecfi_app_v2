import 'package:flutter/material.dart';

Widget getContributorBadge(int count, ThemeData theme, {double size = 16}) {
  if (count >= 100) {
    return Tooltip(
      message: 'Pillar of the Community (100+ contributions)',
      child: Icon(
        Icons.military_tech_rounded,
        color: Colors.amber[700],
        size: size,
      ),
    );
  } else if (count >= 50) {
    return Tooltip(
      message: 'Top Contributor (50+ contributions)',
      child: Icon(
        Icons.stars_rounded,
        color: Colors.orange[600],
        size: size,
      ),
    );
  } else if (count >= 10) {
    return Tooltip(
      message: 'Active Contributor (10+ contributions)',
      child: Icon(
        Icons.workspace_premium_rounded,
        color: Colors.blueGrey[400],
        size: size,
      ),
    );
  }
  return const SizedBox.shrink();
}
