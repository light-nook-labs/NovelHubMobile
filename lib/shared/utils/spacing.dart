import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Consistent spacing and padding constants for the app
class AppSpacing {
  // Padding constants
  static const EdgeInsets paddingXS = EdgeInsets.all(4);
  static const EdgeInsets paddingS = EdgeInsets.all(8);
  static const EdgeInsets paddingM = EdgeInsets.all(12);
  static const EdgeInsets paddingL = EdgeInsets.all(16);
  static const EdgeInsets paddingXL = EdgeInsets.all(24);

  // Horizontal padding
  static const EdgeInsets paddingHorizontalS = EdgeInsets.symmetric(
    horizontal: 8,
  );
  static const EdgeInsets paddingHorizontalM = EdgeInsets.symmetric(
    horizontal: 12,
  );
  static const EdgeInsets paddingHorizontalL = EdgeInsets.symmetric(
    horizontal: 16,
  );

  // Vertical padding
  static const EdgeInsets paddingVerticalS = EdgeInsets.symmetric(vertical: 4);
  static const EdgeInsets paddingVerticalM = EdgeInsets.symmetric(vertical: 8);
  static const EdgeInsets paddingVerticalL = EdgeInsets.symmetric(vertical: 12);

  // Gap constants
  static const SizedBox gapXS = SizedBox(width: 4, height: 4);
  static const SizedBox gapS = SizedBox(width: 8, height: 8);
  static const SizedBox gapM = SizedBox(width: 12, height: 12);
  static const SizedBox gapL = SizedBox(width: 16, height: 16);
  static const SizedBox gapXL = SizedBox(width: 24, height: 24);

  // Width gaps
  static const SizedBox gapWidthXS = SizedBox(width: 4);
  static const SizedBox gapWidthS = SizedBox(width: 8);
  static const SizedBox gapWidthM = SizedBox(width: 12);
  static const SizedBox gapWidthL = SizedBox(width: 16);
  static const SizedBox gapWidthXL = SizedBox(width: 24);

  // Height gaps
  static const SizedBox gapHeightXS = SizedBox(height: 4);
  static const SizedBox gapHeightS = SizedBox(height: 8);
  static const SizedBox gapHeightM = SizedBox(height: 12);
  static const SizedBox gapHeightL = SizedBox(height: 16);
  static const SizedBox gapHeightXL = SizedBox(height: 24);

  // Border radius
  static const BorderRadius radiusS = BorderRadius.all(Radius.circular(4));
  static const BorderRadius radiusM = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusL = BorderRadius.all(Radius.circular(12));
  static const BorderRadius radiusXL = BorderRadius.all(Radius.circular(16));
  static const BorderRadius radiusCircular = BorderRadius.all(
    Radius.circular(100),
  );

  // Card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(12);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(16);

  // List item padding
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 10,
  );
  static const EdgeInsets listItemPaddingDense = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );

  // Grid spacing
  static const double gridSpacing = 10;
  static const double gridSpacingSmall = 8;

  // Section spacing
  static const double sectionSpacing = 24;
  static const double sectionSpacingSmall = 16;
}

/// Consistent text styles
class AppTextStyles {
  // Title styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
  );

  // Body styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );

  // Label styles
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );

  // Badge styles
  static const TextStyle badge = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle badgeLarge = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
}

/// Consistent decoration styles
class AppDecorations {
  // Card decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: AppSpacing.radiusL,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Badge decoration
  static BoxDecoration badgeDecoration(Color color) => BoxDecoration(
    color: color.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(4),
    border: Border.all(color: color.withValues(alpha: 0.3)),
  );

  // Chip decoration
  static BoxDecoration chipDecoration(bool isSelected, BuildContext context) =>
      BoxDecoration(
        color: isSelected
            ? AppColors.primary
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      );

  // Input decoration
  static InputDecoration inputDecoration(
    BuildContext context, {
    String? hintText,
  }) => InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  );
}
