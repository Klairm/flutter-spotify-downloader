import 'package:flutter/material.dart';
import 'package:sample_app/utils/constants.dart';

class AppTheme {
  AppTheme._();

  static ThemeData darkTheme({
    required BuildContext context,
  }) {
    return ThemeData(
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.transparent,
          elevation: 0.0,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        selectionHandleColor: spotifyColor,
        cursorColor: spotifyColor,
        selectionColor: spotifyColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(width: 1.5, color: spotifyColor),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7.0),
        ),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      brightness: Brightness.dark,
      appBarTheme: AppBarTheme(
        color: spotifyColor,
        foregroundColor: Colors.white,
      ),
      canvasColor: spotifyColor,
      cardColor: Colors.grey.shade900,
      cardTheme: CardTheme(
        clipBehavior: Clip.antiAlias,
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7.0),
        ),
      ),
      dialogBackgroundColor: Colors.grey.shade900,
      progressIndicatorTheme:
          const ProgressIndicatorThemeData().copyWith(color: spotifyColor),
      iconTheme: const IconThemeData(
        color: Colors.white,
        opacity: 1.0,
        size: 24.0,
      ),
      indicatorColor: spotifyColor,
      colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: Colors.white,
            secondary: spotifyColor,
            brightness: Brightness.dark,
          ),
    );
  }
}
