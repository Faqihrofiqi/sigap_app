import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class ModernStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final String? trend;
  final bool isPositiveTrend;

  const ModernStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.trend,
    this.isPositiveTrend = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final cardHeight = constraints.maxHeight;
        
        // Use card dimensions for responsive sizing
        final padding = cardWidth * 0.06; // 6% of card width
        final iconSize = cardWidth * 0.12; // 12% of card width, clamped
        final iconPadding = padding * 0.5;
        final valueFontSize = cardWidth * 0.12; // 12% of card width
        final titleFontSize = cardWidth * 0.055; // 5.5% of card width
        
        return Container(
          padding: EdgeInsets.all(padding.clamp(8.0, 16.0)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(cardWidth * 0.05),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon and Trend Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(iconPadding.clamp(4.0, 8.0)),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(cardWidth * 0.03),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: iconSize.clamp(16.0, 24.0),
                    ),
                  ),
                  if (trend != null)
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: padding * 0.3,
                          vertical: padding * 0.15,
                        ),
                        decoration: BoxDecoration(
                          color: (isPositiveTrend ? Colors.green : Colors.red)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(cardWidth * 0.02),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPositiveTrend ? Icons.arrow_upward : Icons.arrow_downward,
                              size: (iconSize * 0.5).clamp(10.0, 14.0),
                              color: isPositiveTrend ? Colors.green : Colors.red,
                            ),
                            SizedBox(width: padding * 0.15),
                            Flexible(
                              child: Text(
                                trend!,
                                style: TextStyle(
                                  fontSize: (titleFontSize * 0.8).clamp(9.0, 12.0),
                                  fontWeight: FontWeight.w600,
                                  color: isPositiveTrend ? Colors.green : Colors.red,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: padding * 0.6),
              // Value
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: valueFontSize.clamp(16.0, 28.0),
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(height: padding * 0.2),
              // Title
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: titleFontSize.clamp(10.0, 14.0),
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Subtitle (only if space allows)
              if (subtitle != null) ...[
                SizedBox(height: padding * 0.1),
                Flexible(
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: (titleFontSize * 0.85).clamp(9.0, 12.0),
                      color: Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
