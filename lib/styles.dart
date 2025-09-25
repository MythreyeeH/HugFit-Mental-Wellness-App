import 'package:flutter/material.dart';

/// ------------------------------
/// COLOR PALETTE
/// ------------------------------
class AppColors {
  static const Color yellow = Color(0xFFFBC246);
  static const Color orange = Color(0xFFFE9135);
  static const Color deepOrange = Color(0xFFE05F1D);
  static const Color red = Color(0xFF8F1A00);
  static const Color darkRed = Color(0xFFB43E0E);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color greyLight = Color(0xFFF5F5F5);
  static const Color greyDark = Color(0xFF777777);

  static const Color primary = orange;
  static const Color background = greyLight;

  static Color aiMessage = Colors.grey.shade200;
  static Color userMessage = orange.withOpacity(0.8);

  static Color inputBackground = white;

  static Color get primaryContainer => Color(0xFFD1C4E9); // light purple, or any color you want

}

/// ------------------------------
/// TEXT STYLES
/// ------------------------------
class AppTextStyles {
  // Bold serif for headings
  static const TextStyle heading = TextStyle(
    fontFamily: 'Serif',
    fontWeight: FontWeight.bold,
    fontSize: 28,
    color: AppColors.black,
    height: 1.3,
);

static TextStyle get subtitle => TextStyle(
  fontSize: 14,
  color: Colors.grey[600],
);


  static const TextStyle headingWhite = TextStyle(
    fontFamily: 'Serif',
    fontWeight: FontWeight.bold,
    fontSize: 28,
    color: AppColors.white,
  );

  // Subheading
  static const TextStyle subheading = TextStyle(
    fontFamily: 'Serif',
    fontWeight: FontWeight.w600,
    fontSize: 20,
    color: AppColors.deepOrange,
  );

  // Body text
  static const TextStyle body = TextStyle(
    fontFamily: 'Serif',
    fontSize: 16,
    color: AppColors.black,
  );

  static const TextStyle subText = TextStyle(
    fontFamily: 'Serif',
    fontSize: 14,
    color: AppColors.greyDark,
  );

  // Buttons
  static const TextStyle button = TextStyle(
    fontFamily: 'Serif',
    fontWeight: FontWeight.bold,
    fontSize: 18,
    color: AppColors.white,
  );

  // Links or secondary text
  static const TextStyle link = TextStyle(
    fontFamily: 'Serif',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.deepOrange,
    decoration: TextDecoration.underline,
  );

  // Messages
  static const TextStyle message = TextStyle(
    fontFamily: 'Serif',
    fontSize: 16,
    color: AppColors.black,
  );

  // Input text
  static const TextStyle input = TextStyle(
    fontFamily: 'Serif',
    fontSize: 16,
    color: AppColors.black,
  );
}

/// ------------------------------
/// BUTTON STYLES
/// ------------------------------
class AppButtonStyles {
  static final ButtonStyle elevated = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.white,
    textStyle: AppTextStyles.button,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    elevation: 6,
    shadowColor: AppColors.deepOrange.withOpacity(0.4),
  );

  static final ButtonStyle outlined = OutlinedButton.styleFrom(
    backgroundColor: AppColors.white,
    foregroundColor: AppColors.primary,
    textStyle: AppTextStyles.button,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    side: BorderSide(color: AppColors.primary, width: 2),
  );

  static TextStyle get bodyBold => const TextStyle(
  fontFamily: 'Serif',
  fontWeight: FontWeight.bold,
  fontSize: 16,
  color: Colors.black,
);

}

/// ------------------------------
/// INPUT FIELD DECORATION
/// ------------------------------
class AppInputDecorations {
  static InputDecoration textField({String? label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
          fontFamily: 'Serif', fontWeight: FontWeight.w600, color: AppColors.deepOrange),
      hintStyle: const TextStyle(color: AppColors.greyDark),
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.greyDark.withOpacity(0.2), width: 1.5),
      ),
    );
  }
}

