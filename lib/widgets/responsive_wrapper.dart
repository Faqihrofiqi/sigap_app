import 'package:flutter/material.dart';
import '../core/app_theme.dart';

/// Widget wrapper untuk membuat layout responsive
class ResponsiveWrapper extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final EdgeInsets? padding;
  final double? maxWidth;
  
  const ResponsiveWrapper({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.padding,
    this.maxWidth,
  });
  
  @override
  Widget build(BuildContext context) {
    final isDesktop = AppTheme.isDesktop(context);
    final isTablet = AppTheme.isTablet(context);
    
    Widget child;
    if (isDesktop && desktop != null) {
      child = desktop!;
    } else if (isTablet && tablet != null) {
      child = tablet!;
    } else {
      child = mobile;
    }
    
    final contentMaxWidth = maxWidth ?? AppTheme.maxContentWidth(context);
    final contentPadding = padding ?? AppTheme.responsivePadding(context);
    
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: contentMaxWidth,
        ),
        child: Padding(
          padding: contentPadding,
          child: child,
        ),
      ),
    );
  }
}

/// Responsive grid untuk menampilkan items
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.mobileColumns = 1,
    this.tabletColumns,
    this.desktopColumns,
  });
  
  @override
  Widget build(BuildContext context) {
    int columns = mobileColumns;
    
    if (AppTheme.isDesktop(context) && desktopColumns != null) {
      columns = desktopColumns!;
    } else if (AppTheme.isTablet(context) && tabletColumns != null) {
      columns = tabletColumns!;
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: 1.2,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Responsive row yang berubah menjadi column di mobile
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;
  
  const ResponsiveRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.spacing = 16,
  });
  
  @override
  Widget build(BuildContext context) {
    if (AppTheme.isMobile(context)) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children
            .expand((child) => [child, SizedBox(height: spacing)])
            .toList()
          ..removeLast(),
      );
    }
    
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children
          .expand((child) => [child, SizedBox(width: spacing)])
          .toList()
        ..removeLast(),
    );
  }
}

