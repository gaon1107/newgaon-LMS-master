import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primarySwatch: MaterialColor(
        AppConstants.primaryColorValue,
        _getMaterialColorMap(AppConstants.primaryColorValue),
      ),
      primaryColor: const Color(AppConstants.primaryColorValue),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(AppConstants.primaryColorValue),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(AppConstants.backgroundColor),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(AppConstants.primaryColorValue),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: 'NotoSans',
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32.sp,
          fontWeight: FontWeight.bold,
          color: const Color(AppConstants.textPrimaryColor),
          fontFamily: 'NotoSans',
        ),
        headlineMedium: TextStyle(
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
          color: const Color(AppConstants.textPrimaryColor),
          fontFamily: 'NotoSans',
        ),
        headlineSmall: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: const Color(AppConstants.textPrimaryColor),
          fontFamily: 'NotoSans',
        ),
        bodyLarge: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.normal,
          color: const Color(AppConstants.textPrimaryColor),
          fontFamily: 'NotoSans',
        ),
        bodyMedium: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.normal,
          color: const Color(AppConstants.textSecondaryColor),
          fontFamily: 'NotoSans',
        ),
        bodySmall: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.normal,
          color: const Color(AppConstants.textSecondaryColor),
          fontFamily: 'NotoSans',
        ),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(AppConstants.primaryColorValue),
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, AppConstants.buttonHeight.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          textStyle: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            fontFamily: 'NotoSans',
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(
            color: Color(AppConstants.primaryColorValue),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          borderSide: const BorderSide(
            color: Color(AppConstants.errorColor),
            width: 2,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 12.h,
        ),
        labelStyle: TextStyle(
          fontSize: 14.sp,
          color: const Color(AppConstants.textSecondaryColor),
          fontFamily: 'NotoSans',
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        color: Colors.white,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        titleTextStyle: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: const Color(AppConstants.textPrimaryColor),
          fontFamily: 'NotoSans',
        ),
        contentTextStyle: TextStyle(
          fontSize: 14.sp,
          color: const Color(AppConstants.textSecondaryColor),
          fontFamily: 'NotoSans',
        ),
      ),
    );
  }

  static Map<int, Color> _getMaterialColorMap(int colorValue) {
    return {
      50: Color(colorValue).withOpacity(0.1),
      100: Color(colorValue).withOpacity(0.2),
      200: Color(colorValue).withOpacity(0.3),
      300: Color(colorValue).withOpacity(0.4),
      400: Color(colorValue).withOpacity(0.5),
      500: Color(colorValue).withOpacity(0.6),
      600: Color(colorValue).withOpacity(0.7),
      700: Color(colorValue).withOpacity(0.8),
      800: Color(colorValue).withOpacity(0.9),
      900: Color(colorValue),
    };
  }
}