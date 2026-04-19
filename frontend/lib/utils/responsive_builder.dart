import 'package:flutter/material.dart';

/// Responsive breakpoints
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Responsive helper widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: builder);
  }

  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < Breakpoints.mobile;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= Breakpoints.mobile && width < Breakpoints.tablet;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= Breakpoints.tablet;
  }

  static int getGridColumns(BuildContext context, {int mobile = 2, int tablet = 3, int desktop = 4}) {
    final width = MediaQuery.of(context).size.width;
    if (width < Breakpoints.mobile) return mobile;
    if (width < Breakpoints.tablet) return tablet;
    return desktop;
  }
}

/// Responsive row that stacks on mobile
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.spacing = 12,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < Breakpoints.mobile) {
          // Stack vertically on mobile
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children
                .expand((child) => [child, SizedBox(height: spacing)])
                .toList()
              ..removeLast(),
          );
        }
        // Row on desktop
        return Row(
          crossAxisAlignment: crossAxisAlignment,
          children: children
              .expand((child) => [
                    if (child is Expanded) child else Expanded(child: child),
                    SizedBox(width: spacing)
                  ])
              .toList()
            ..removeLast(),
        );
      },
    );
  }
}

/// Responsive padding
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobile;
  final EdgeInsets? tablet;
  final EdgeInsets? desktop;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    EdgeInsets padding;
    
    if (width < Breakpoints.mobile) {
      padding = mobile ?? const EdgeInsets.all(12);
    } else if (width < Breakpoints.tablet) {
      padding = tablet ?? const EdgeInsets.all(16);
    } else {
      padding = desktop ?? const EdgeInsets.all(20);
    }

    return Padding(padding: padding, child: child);
  }
}
