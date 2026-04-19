import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class ResponsiveHelper {
  // Check if running on mobile (Android or iOS)
  static bool get isMobile {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (e) {
      return false;
    }
  }

  // Check if running on desktop (Windows, macOS, Linux)
  static bool get isDesktop {
    if (kIsWeb) return true;
    try {
      return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    } catch (e) {
      return false;
    }
  }

  // Check specifically for Android
  static bool get isAndroid {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid;
    } catch (e) {
      return false;
    }
  }

  // Get responsive padding
  static EdgeInsets getScreenPadding(BuildContext context) {
    return isMobile 
        ? const EdgeInsets.all(12) 
        : const EdgeInsets.all(24);
  }

  // Get responsive card margin
  static EdgeInsets getCardMargin() {
    return isMobile 
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
        : const EdgeInsets.all(16);
  }

  // Get responsive font size
  static double getHeadlineSize() {
    return isMobile ? 20 : 28;
  }

  static double getTitleSize() {
    return isMobile ? 16 : 20;
  }

  static double getBodySize() {
    return isMobile ? 14 : 16;
  }

  // Get grid columns based on screen width
  static int getGridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (isMobile) {
      return width > 600 ? 2 : 1;
    }
    return width > 1200 ? 4 : (width > 800 ? 3 : 2);
  }

  // Check if screen is small
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  // Get app bar height
  static double getAppBarHeight() {
    return isMobile ? 56 : 64;
  }

  // Get bottom navigation bar height
  static double getBottomNavHeight() {
    return isMobile ? 60 : 0;
  }
}
