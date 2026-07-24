import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_motion.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';

class CRMCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? headerAction;
  final Widget child;
  final Widget? footer;
  final EdgeInsetsGeometry padding;
  final bool elevated;

  const CRMCard({
    super.key,
    this.title,
    this.subtitle,
    this.headerAction,
    required this.child,
    this.footer,
    this.padding = const EdgeInsets.all(CRMSpacing.m),
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: CRMMotion.medium,
      curve: CRMMotion.easeOut,
      decoration: BoxDecoration(
        color: elevated
            ? CRMColors.surfaceElevatedOf(context)
            : CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
        border: Border.all(
          color: CRMColors.borderOf(context).withOpacity(0.55),
          width: 0.5,
        ),
        boxShadow: elevated ? CRMShadows.medium : CRMShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || subtitle != null || headerAction != null) ...[
            Padding(
              padding: const EdgeInsets.only(
                left: CRMSpacing.m,
                right: CRMSpacing.m,
                top: CRMSpacing.m,
                bottom: CRMSpacing.s,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            style: CRMTypography.cardTitle
                                .copyWith(color: CRMColors.textOf(context)),
                          ),
                        if (subtitle != null) ...[
                          const SizedBox(height: CRMSpacing.xxs),
                          Text(
                            subtitle!,
                            style: CRMTypography.caption.copyWith(
                              color: CRMColors.textSecondaryOf(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (headerAction != null) headerAction!,
                ],
              ),
            ),
            Divider(
              color: CRMColors.divider,
              height: 1,
              thickness: 0.5,
            ),
          ],
          Padding(
            padding: padding,
            child: child,
          ),
          if (footer != null) ...[
            Divider(
              color: CRMColors.divider,
              height: 1,
              thickness: 0.5,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: CRMSpacing.m,
                vertical: CRMSpacing.s,
              ),
              child: footer!,
            ),
          ],
        ],
      ),
    );
  }
}

class CRMKPICard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final double? growthPercent;
  final String? lastUpdated;

  const CRMKPICard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.growthPercent,
    this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final showGrowth = growthPercent != null;
    final isPositive = (growthPercent ?? 0.0) >= 0;
    final activeIconColor = iconColor ?? CRMColors.primaryOf(context);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    return CRMCard(
      elevated: true,
      padding: EdgeInsets.all(isMobile ? CRMSpacing.s : CRMSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (isMobile
                          ? CRMTypography.captionBold.copyWith(fontSize: 11)
                          : CRMTypography.captionBold)
                      .copyWith(color: CRMColors.textSecondaryOf(context)),
                ),
              ),
              const SizedBox(width: CRMSpacing.xxs),
              Container(
                padding: EdgeInsets.all(isMobile ? CRMSpacing.xxs : CRMSpacing.xs),
                decoration: BoxDecoration(
                  color: activeIconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                ),
                child: Icon(icon, color: activeIconColor, size: isMobile ? 15 : 18),
              ),
            ],
          ),
          SizedBox(height: isMobile ? CRMSpacing.xxs : CRMSpacing.s),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: (isMobile
                      ? CRMTypography.statistics.copyWith(fontSize: 22)
                      : CRMTypography.statistics)
                  .copyWith(color: CRMColors.textOf(context)),
            ),
          ),
          if (showGrowth || lastUpdated != null) ...[
            SizedBox(height: isMobile ? CRMSpacing.xxs : CRMSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (showGrowth)
                  Row(
                    children: [
                      Icon(
                        isPositive
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: isPositive ? CRMColors.success : CRMColors.danger,
                        size: isMobile ? 12 : 14,
                      ),
                      const SizedBox(width: CRMSpacing.xxs),
                      Text(
                        '${isPositive ? "+" : ""}${growthPercent!.toStringAsFixed(1)}%',
                        style: (isMobile
                                ? CRMTypography.captionBold.copyWith(fontSize: 10)
                                : CRMTypography.captionBold)
                            .copyWith(
                          color: isPositive ? CRMColors.success : CRMColors.danger,
                        ),
                      ),
                    ],
                  ),
                if (lastUpdated != null)
                  Text(
                    lastUpdated!,
                    style: (isMobile
                            ? CRMTypography.caption.copyWith(fontSize: 10)
                            : CRMTypography.caption)
                        .copyWith(color: CRMColors.textMutedOf(context)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
