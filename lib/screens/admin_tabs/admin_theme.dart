import 'package:flutter/material.dart';

bool adminIsDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

Color adminCardColor(BuildContext context) =>
    Theme.of(context).colorScheme.surface;

Color adminPrimaryTextColor(BuildContext context) =>
    Theme.of(context).colorScheme.onSurface;

Color adminSecondaryTextColor(BuildContext context) =>
    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);

Color adminSubtleSurfaceColor(BuildContext context) => adminIsDark(context)
    ? const Color(0xFF202B3C)
    : const Color(0xFFF8FAFC);

Color adminBorderColor(BuildContext context) => adminIsDark(context)
    ? Colors.white.withValues(alpha: 0.1)
    : const Color(0xFFE2E8F0);

BoxDecoration adminCardDecoration(BuildContext context) => BoxDecoration(
      color: adminCardColor(context),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: adminBorderColor(context)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: adminIsDark(context) ? 0.12 : 0.04,
          ),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
