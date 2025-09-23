import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/app_constants.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double? height;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double? fontSize;
  final FontWeight? fontWeight;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.fontSize,
    this.fontWeight,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ??
        const Color(AppConstants.primaryColorValue);
    final effectiveTextColor = textColor ?? Colors.white;
    final effectiveHeight = height ?? AppConstants.buttonHeight.h;
    final effectiveFontSize = fontSize ?? 16.sp;
    final effectiveFontWeight = fontWeight ?? FontWeight.w600;
    final effectiveBorderRadius = borderRadius ??
        BorderRadius.circular(AppConstants.borderRadius);

    Widget buttonChild;

    if (isLoading) {
      buttonChild = SizedBox(
        width: 20.w,
        height: 20.w,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
        ),
      );
    } else if (icon != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: (effectiveFontSize + 2).sp,
            color: effectiveTextColor,
          ),
          SizedBox(width: 8.w),
          Text(
            text,
            style: TextStyle(
              fontSize: effectiveFontSize,
              fontWeight: effectiveFontWeight,
              color: effectiveTextColor,
              fontFamily: 'NotoSans',
            ),
          ),
        ],
      );
    } else {
      buttonChild = Text(
        text,
        style: TextStyle(
          fontSize: effectiveFontSize,
          fontWeight: effectiveFontWeight,
          color: effectiveTextColor,
          fontFamily: 'NotoSans',
        ),
      );
    }

    return SizedBox(
      width: width,
      height: effectiveHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBackgroundColor,
          foregroundColor: effectiveTextColor,
          disabledBackgroundColor: Colors.grey.shade300,
          disabledForegroundColor: Colors.grey.shade600,
          elevation: 2,
          shadowColor: effectiveBackgroundColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: effectiveBorderRadius,
          ),
          padding: padding ?? EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
        ),
        child: buttonChild,
      ),
    );
  }
}

class CustomOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double? height;
  final Color? borderColor;
  final Color? textColor;
  final IconData? icon;
  final double? fontSize;
  final FontWeight? fontWeight;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const CustomOutlinedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.borderColor,
    this.textColor,
    this.icon,
    this.fontSize,
    this.fontWeight,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ??
        const Color(AppConstants.primaryColorValue);
    final effectiveTextColor = textColor ??
        const Color(AppConstants.primaryColorValue);
    final effectiveHeight = height ?? AppConstants.buttonHeight.h;
    final effectiveFontSize = fontSize ?? 16.sp;
    final effectiveFontWeight = fontWeight ?? FontWeight.w600;
    final effectiveBorderRadius = borderRadius ??
        BorderRadius.circular(AppConstants.borderRadius);

    Widget buttonChild;

    if (isLoading) {
      buttonChild = SizedBox(
        width: 20.w,
        height: 20.w,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(effectiveTextColor),
        ),
      );
    } else if (icon != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: (effectiveFontSize + 2).sp,
            color: effectiveTextColor,
          ),
          SizedBox(width: 8.w),
          Text(
            text,
            style: TextStyle(
              fontSize: effectiveFontSize,
              fontWeight: effectiveFontWeight,
              color: effectiveTextColor,
              fontFamily: 'NotoSans',
            ),
          ),
        ],
      );
    } else {
      buttonChild = Text(
        text,
        style: TextStyle(
          fontSize: effectiveFontSize,
          fontWeight: effectiveFontWeight,
          color: effectiveTextColor,
          fontFamily: 'NotoSans',
        ),
      );
    }

    return SizedBox(
      width: width,
      height: effectiveHeight,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: effectiveTextColor,
          disabledForegroundColor: Colors.grey.shade600,
          side: BorderSide(
            color: isLoading ? Colors.grey.shade300 : effectiveBorderColor,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: effectiveBorderRadius,
          ),
          padding: padding ?? EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
        ),
        child: buttonChild,
      ),
    );
  }
}

class CustomIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;
  final double? iconSize;
  final String? tooltip;
  final EdgeInsetsGeometry? padding;

  const CustomIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size,
    this.iconSize,
    this.tooltip,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSize = size ?? 48.w;
    final effectiveIconSize = iconSize ?? 24.sp;
    final effectiveBackgroundColor = backgroundColor ??
        const Color(AppConstants.primaryColorValue);
    final effectiveIconColor = iconColor ?? Colors.white;

    return SizedBox(
      width: effectiveSize,
      height: effectiveSize,
      child: Material(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(effectiveSize / 2),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(effectiveSize / 2),
          child: Padding(
            padding: padding ?? EdgeInsets.all(8.w),
            child: Icon(
              icon,
              size: effectiveIconSize,
              color: effectiveIconColor,
            ),
          ),
        ),
      ),
    );
  }
}