import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shared compact sizing tokens for the mobile UI.
abstract final class AppSpacing {
  static const hairline = 1.0;
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 6.0;
  static const md = 8.0;
  static const lg = 10.0;
  static const xl = 12.0;
  static const xxl = 16.0;
  static const xxxl = 20.0;
  static const huge = 24.0;
  static const screen = 16.0;
  static const cardGap = 12.0;
  static const cardPadding = 16.0;
  static const innerGap = 8.0;
  static const sectionGap = 12.0;
}

abstract final class AppRadii {
  static const xs = 6.0;
  static const sm = 8.0;
  static const md = 10.0;
  static const lg = 12.0;
  static const xl = 14.0;
  static const xxl = 16.0;
  static const card = 18.0;
  static const cardLarge = 20.0;
  static const pill = 999.0;
  static const eventBar = 3.0;
  static const dot = 2.0;
}

abstract final class AppType {
  static const greeting = 13.0;
  static const userName = 20.0;
  static const cardTitle = 16.0;
  static const cardSubtitle = 12.0;
  static const body = 14.0;
  static const bodySmall = 12.0;
  static const meta = 12.0;
  static const chip = 11.0;
  static const button = 14.0;
  static const dropdown = 14.0;
  static const statLabel = 13.0;
  static const statNumber = 24.0;
  static const projectName = 14.0;
  static const projectCount = 12.0;
  static const link = 13.0;
  static const calendarWeekday = 11.0;
  static const calendarDate = 12.0;
  static const calendarMonth = 15.0;
  static const calendarDayTitle = 16.0;
  static const eventTitle = 15.0;
  static const countBadge = 11.0;
  static const bottomNav = 11.0;
  static const timeline = 13.0;
  static const noticeTitle = 15.0;
  static const noticeBody = 13.0;
  static const empty = 13.0;
  static const avatarInitials = 13.0;
  static const notificationBadge = 9.0;
  static const error = 11.0;
  static const monthButton = 13.0;
  static const appBarTitle = 16.0;
  static const sheetTitle = 18.0;

  static const chipLetterSpacing = 0.4;
  static const buttonLetterSpacing = 0.6;
}

abstract final class AppIconSizes {
  static const xs = 10.0;
  static const sm = 12.0;
  static const md = 14.0;
  static const lg = 16.0;
  static const xl = 18.0;
  static const xxl = 20.0;
  static const header = 22.0;
  static const nav = 22.0;
  static const empty = 24.0;
}

abstract final class AppSizes {
  static const appBarHeight = 56.0;
  static const headerAction = 40.0;
  static const headerActionIcon = 22.0;
  static const headerDividerHeight = 24.0;
  static const headerLogo = 28.0;
  static const profileAvatar = 34.0;
  static const profileAvatarCompact = 30.0;
  static const notificationBadge = 16.0;
  static const minTapTarget = 40.0;

  static const bottomNavHeight = 60.0;
  static const bottomNavGap = 2.0;
  static const bottomNavBadge = 16.0;
  static const bottomNavIcon = 22.0;

  static const cardBorder = 1.0;
  static const loadingNotice = 160.0;
  static const loadingDashboard = 240.0;
  static const loadingTeams = 150.0;
  static const attendanceLoading = 170.0;

  static const chipHeight = 28.0;
  static const chipHPadding = 10.0;
  static const chipVPadding = 4.0;
  static const dropdownHeight = 44.0;
  static const dropdownIcon = AppIconSizes.xxl;
  static const actionButton = 46.0;
  static const attendanceButton = 46.0;
  static const actionSpinner = 18.0;
  static const actionShadowBlur = 8.0;
  static const actionShadowOffset = 3.0;
  static const actionShadowOpacity = 0.25;

  static const timelineRow = 30.0;
  static const timelineDot = 12.0;
  static const attendanceTimelineDot = 12.0;
  static const timelineLine = 14.0;
  static const timelineLineWidth = 1.5;
  static const timelineLabelWidth = 24.0;
  static const pulseDot = 6.0;

  static const noticeCount = 24.0;
  static const noticeAddTap = 40.0;
  static const noticeAvatar = 24.0;
  static const noticeDot = 8.0;

  static const calendarControl = 34.0;
  static const calendarWeekday = 32.0;
  static const calendarDayCell = 52.0;
  static const calendarTodayCircle = 30.0;
  static const calendarDot = 7.0;
  static const calendarDotSpacing = 3.0;
  static const calendarEventBarWidth = 36.0;
  static const calendarEventBarHeight = 6.0;

  static const personAvatar = 36.0;
  static const listRow = 56.0;
  static const peopleList = 260.0;
  static const peopleEmpty = 60.0;
  static const listTilePadding = 12.0;

  static const progressHeight = 10.0;
  static const projectProgressHeight = 8.0;
  static const statDot = 10.0;
  static const statPill = 22.0;
  static const statCardPaddingV = 12.0;
  static const statCardPaddingH = 14.0;
  static const statNumberGap = 4.0;
  static const statCardGap = 8.0;

  static const cardHeaderIcon = 24.0;
  static const cardHeaderIconRadius = 8.0;
  static const cardHeaderIconGap = 6.0;

  static const taskProgress = 4.0;
  static const taskDot = 6.0;
}

abstract final class AppShadows {
  static const soft = [
    BoxShadow(
      color: AppColors.cardShadow,
      blurRadius: 8,
      offset: Offset(0, 3),
    ),
  ];

  static const elevated = [
    BoxShadow(
      color: AppColors.elevatedShadow,
      blurRadius: 12,
      offset: Offset(0, 5),
    ),
  ];
}
