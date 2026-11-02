import 'package:flutter/material.dart';
import '../layout/m3_layout.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileBody;
  final Widget? tabletBody;
  final Widget desktopBody;

  const ResponsiveLayout({
    super.key,
    required this.mobileBody,
    this.tabletBody,
    required this.desktopBody,
  });

  static bool isMobile(BuildContext context) => M3Layout.isMobile(context);

  static bool isTablet(BuildContext context) => M3Layout.isTablet(context);

  static bool isDesktop(BuildContext context) => M3Layout.isDesktop(context);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= M3Layout.expandedMinWidth) {
      return desktopBody;
    } else if (width >= M3Layout.mediumMinWidth) {
      return tabletBody ?? mobileBody;
    } else {
      return mobileBody;
    }
  }
}
