import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_shadows.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'skeletons.dart';
import 'empty_state.dart';

class CRMDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final bool isLoading;
  final String emptyTitle;
  final String emptyDescription;
  final IconData emptyIcon;
  final bool showCheckboxColumn;
  final double? dataRowMinHeight;
  final double? dataRowMaxHeight;

  const CRMDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.isLoading = false,
    this.emptyTitle = 'No entries found',
    this.emptyDescription = 'Try adjusting your search filters or add a new record.',
    this.emptyIcon = Icons.folder_open_rounded,
    this.showCheckboxColumn = true,
    this.dataRowMinHeight,
    this.dataRowMaxHeight,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.all(CRMSpacing.m),
        child: Column(
          children: List.generate(5, (index) => const Padding(
            padding: EdgeInsets.only(bottom: CRMSpacing.s),
            child: CRMSkeleton(height: 48),
          )),
        ),
      );
    }

    if (rows.isEmpty) {
      return CRMEmptyState(
        title: emptyTitle,
        description: emptyDescription,
        icon: emptyIcon,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
        border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.55), width: 0.5),
        boxShadow: CRMShadows.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double availableWidth = constraints.maxWidth;
          final int colCount = columns.length;
          final double baseContentWidth = colCount * 130.0 + CRMSpacing.m * 2;
          
          double spacing = CRMSpacing.m;
          if (colCount > 1 && availableWidth > baseContentWidth) {
            spacing = (availableWidth - baseContentWidth) / (colCount - 1);
            if (spacing < CRMSpacing.s) spacing = CRMSpacing.s;
            if (spacing > 40.0) spacing = 40.0;
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: availableWidth),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(CRMColors.sidebarBgOf(context)),
                headingTextStyle: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context)),
                dataTextStyle: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
                dataRowMinHeight: dataRowMinHeight ?? 52.0,
                dataRowMaxHeight: dataRowMaxHeight ?? 64.0,
                dividerThickness: 0.5,
                horizontalMargin: CRMSpacing.m,
                columnSpacing: spacing,
                columns: columns,
                rows: rows,
                showCheckboxColumn: showCheckboxColumn,
              ),
            ),
          );
        },
      ),
    );
  }
}
