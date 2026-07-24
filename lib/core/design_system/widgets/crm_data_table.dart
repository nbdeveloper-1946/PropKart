import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_typography.dart';
import 'skeletons.dart';

class CRMColumn<T> {
  final String label;
  final Widget Function(T item) cellBuilder;
  final bool sortable;
  final double? width;
  final String sortField;

  const CRMColumn({
    required this.label,
    required this.cellBuilder,
    this.sortable = false,
    this.width,
    this.sortField = '',
  });
}

class CRMDataTable<T> extends StatelessWidget {
  final List<CRMColumn<T>> columns;
  final List<T> items;
  final bool isLoading;
  final String? sortField;
  final bool sortAscending;
  final Function(String field, bool ascending)? onSort;
  final Function(T item)? onRowTap;
  final List<T> selectedItems;
  final Function(List<T> selected)? onSelectionChanged;
  final int currentPage;
  final int totalPages;
  final Function(int page)? onPageChanged;

  const CRMDataTable({
    super.key,
    required this.columns,
    required this.items,
    this.isLoading = false,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.onRowTap,
    this.selectedItems = const [],
    this.onSelectionChanged,
    this.currentPage = 1,
    this.totalPages = 1,
    this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(CRMSpacing.m),
        child: CRMListSkeleton(count: 5),
      );
    }

    final hasSelection = onSelectionChanged != null;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: CRMColors.borderOf(context),
                ),
                child: DataTable(
                  showCheckboxColumn: hasSelection,
                  headingRowColor: WidgetStateProperty.all(CRMColors.background),
                  dataRowColor: WidgetStateProperty.all(CRMColors.cardBgOf(context)),
                  dataRowMinHeight: 64.0,
                  dataRowMaxHeight: 128.0,
                  horizontalMargin: CRMSpacing.m,
                  columnSpacing: CRMSpacing.l,
                  sortColumnIndex: sortField != null
                      ? columns.indexWhere((c) => c.sortField == sortField)
                      : null,
                  sortAscending: sortAscending,
                  columns: [
                    ...columns.map((c) {
                      return DataColumn(
                        label: Text(
                          c.label,
                          style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
                        ),
                        onSort: c.sortable && onSort != null
                            ? (index, ascending) {
                                onSort!(c.sortField, ascending);
                              }
                            : null,
                      );
                    }),
                  ],
                  rows: items.map((item) {
                    final isSelected = selectedItems.contains(item);
                    return DataRow(
                      selected: isSelected,
                      onSelectChanged: hasSelection
                          ? (selected) {
                              final updated = List<T>.from(selectedItems);
                              if (selected == true) {
                                updated.add(item);
                              } else {
                                updated.remove(item);
                              }
                              onSelectionChanged!(updated);
                            }
                          : null,
                      cells: columns.map((c) {
                        return DataCell(
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onRowTap != null ? () => onRowTap!(item) : null,
                            child: Container(
                              alignment: Alignment.centerLeft,
                              width: c.width,
                              child: c.cellBuilder(item),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
        if (totalPages > 1 && onPageChanged != null)
          Container(
            padding: const EdgeInsets.symmetric(vertical: CRMSpacing.s, horizontal: CRMSpacing.m),
            decoration: BoxDecoration(
              color: CRMColors.cardBgOf(context),
              border: Border(top: BorderSide(color: CRMColors.borderOf(context))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Page $currentPage of $totalPages',
                  style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: currentPage > 1 ? () => onPageChanged!(currentPage - 1) : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: currentPage < totalPages ? () => onPageChanged!(currentPage + 1) : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
