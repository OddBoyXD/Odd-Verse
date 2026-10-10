import 'package:flutter/material.dart';

class CustomExpansionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const CustomExpansionTile(
      {super.key,
      required this.children,
      required this.icon,
      required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05),
                width: 1.0,
              ),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.04),
                width: 1.0,
              ),
            ),
            childrenPadding:
                const EdgeInsets.only(left: 8, right: 8, bottom: 12, top: 4),
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            textColor: theme.textTheme.titleMedium?.color,
            iconColor: theme.colorScheme.secondary,
            collapsedIconColor:
                theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            collapsedBackgroundColor: isDark
                ? theme.cardColor.withOpacity(0.4)
                : theme.cardColor.withOpacity(0.8),
            backgroundColor: isDark
                ? theme.cardColor.withOpacity(0.65)
                : theme.cardColor.withOpacity(0.95),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            leading: Icon(icon, color: theme.colorScheme.secondary, size: 22),
            children: children,
          ),
        ),
      ),
    );
  }
}

