import 'package:flutter/material.dart';

/// SpeedCode Labs color tokens.
abstract final class AppColors {
  static const primary = Color(0xFF9F2350);
  static const primaryDark = Color(0xFF7F1D42);
  static const primaryLight = Color(0xFFFCE7F0);
  static const softPink = Color(0xFFFDF6F9);
  static const white = Color(0xFFFFFFFF);

  static const background = Color(0xFFF8FAFC);
  static const navy = Color(0xFF0F172A);
  static const mainText = Color(0xFF0F172A);
  static const secondaryText = Color(0xFF64748B);
  static const border = Color(0xFFE5E7EB);
  static const divider = Color(0xFFE5E7EB);
  static const navInactive = Color(0xFF64748B);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate800 = Color(0xFF1E293B);
  static const slate900 = Color(0xFF0F172A);

  static const success = Color(0xFF059669);
  static const successLight = Color(0xFFD1FAE5);
  static const successBorder = Color(0xFFA7F3D0);
  static const mintSurface = Color(0xFFECFDF5);

  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);
  static const warningBorder = Color(0xFFFDE68A);
  static const warningSurface = Color(0xFFFFFBEB);
  static const warningText = Color(0xFF92400E);

  static const info = Color(0xFF3B82F6);
  static const infoLight = Color(0xFFEFF6FF);
  static const infoBorder = Color(0xFFBFDBFE);

  static const attendanceTimeIn = success;
  static const attendanceTimeOut = warning;
  static const review = Color(0xFF8B5CF6);
  static const error = Color(0xFFE5484D);
  static const notificationBadge = Color(0xFFDC2626);

  static const backlog = Color(0xFF94A3B8);
  static const todo = info;
  static const inProgress = warning;
  static const done = Color(0xFF10B981);
  static const blocked = error;

  static const statusBacklog = backlog;
  static const statusTodo = todo;
  static const statusInProgress = inProgress;
  static const statusReview = review;
  static const statusDone = done;
  static const statusBlocked = blocked;

  static const calendarWorking = Color(0xFF059669);
  static const calendarLeave = Color(0xFFD97706);
  static const calendarMeeting = Color(0xFF7C3AED);
  static const calendarCompany = Color(0xFF2563EB);
  static const calendarBrand = Color(0xFF9F2350);
  static const calendarProject = Color(0xFF0F766E);

  // Dark-mode surfaces.
  static const darkBackground = Color(0xFF0F172A);
  static const darkSurface = Color(0xFF1E293B);
  static const darkSurfaceAlt = Color(0xFF273449);
  static const darkBorder = Color(0xFF334155);
  static const darkText = Color(0xFFF8FAFC);
  static const darkSecondaryText = Color(0xFF94A3B8);
  static const darkNavInactive = Color(0xFF94A3B8);
  static const darkMintSurface = Color(0xFF132B28);
  static const darkNoticeSurface = Color(0xFF2A2416);

  static const cardShadow = Color(0x0A101828);
  static const elevatedShadow = Color(0x14101828);

  static const softImageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC94A7B), primary],
  );

  static const attendanceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [mintSurface, white],
  );

  static const attendanceGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkMintSurface, darkSurface],
  );

  static const noticeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [warningSurface, white],
  );

  static const noticeGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkNoticeSurface, darkSurface],
  );
}

extension AppColorContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get surface => isDark ? AppColors.darkSurface : AppColors.white;
  Color get canvas => isDark ? AppColors.darkBackground : AppColors.background;
  Color get textPrimary => isDark ? AppColors.darkText : AppColors.mainText;
  Color get textSecondary =>
      isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;
  Color get line => isDark ? AppColors.darkBorder : AppColors.border;
  Color get navInactive =>
      isDark ? AppColors.darkNavInactive : AppColors.navInactive;
}
