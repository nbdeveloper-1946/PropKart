import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/tokens/app_shadows.dart';
import '../../../core/design_system/tokens/app_motion.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/data_table.dart';
import '../../../core/design_system/widgets/drawers.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/models/user_model.dart';
import '../bloc/properties_bloc.dart';
import '../models/property_model.dart';
import '../repository/properties_repository.dart';
import 'add_edit_property_screen.dart';
import '../../../core/utils/currency.dart';

class PropertiesScreen extends StatefulWidget {
  final String? openPropertyId;
  const PropertiesScreen({super.key, this.openPropertyId});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _highlightedPropertyId;
  String _activeTab = 'All';
  String _activeListingTab = 'Rent'; // 'Rent' or 'Only Re-Sale'
  bool _hasAutoOpenedAdd = false;
  bool _hasAutoOpenedProp = false;
  String? _selectedCategory;
  String? _selectedArea;
  String? _selectedListingType;
  bool? _selectedVerification;
  int _currentPage = 0;
  int _pageSize = 10;

  static const _pageSizeOptions = [10, 25, 50];

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadProperties() {
    context.read<PropertiesBloc>().add(
          LoadPropertiesEvent(
            search: _searchController.text.trim(),
            categoryId: _selectedCategory,
            areaId: _selectedArea,
            listingTypeId: _selectedListingType,
            isVerified: _selectedVerification,
            activeTab: _activeTab,
          ),
        );
  }

  Future<void> _launchWhatsApp(PropertyModel property) async {
    final authState = context.read<AuthBloc>().state;
    String userName = 'User';
    if (authState is Authenticated) {
      userName = authState.user.fullName;
    }

    final text = 'Hello,\n'
        'I am $userName from NB Prop Tech.\n'
        'Is your property still available?\n'
        'Thank you.';
    final url =
        'https://wa.me/${property.ownerMobile}?text=${Uri.encodeComponent(text)}';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    }
  }

  bool _hasEditAccess(PropertyModel p, UserModel? currentUser) {
    if (currentUser == null) return false;
    if (currentUser.role == 'Super Admin') return true;
    if (p.createdBy == currentUser.id) return true;
    if (p.adminId != null && p.adminId == currentUser.adminId) return true;
    if (currentUser.role == 'Admin' && p.adminId == currentUser.id) return true;
    return false;
  }

  Widget _buildMobilePropertyCard(PropertyModel p, UserModel? currentUser,
      Set<String> bookmarkedIds, PropertyMetadataModel? metadata) {
    final isMine = _hasEditAccess(p, currentUser);
    final isBookmarked = bookmarkedIds.contains(p.id);
    final isHighlighted = p.id == _highlightedPropertyId;

    return AnimatedContainer(
        duration: CRMMotion.medium,
        curve: CRMMotion.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(CRMBorderRadius.card + 2),
          border: Border.all(
            color: isHighlighted ? CRMColors.primaryOf(context) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: isHighlighted ? CRMShadows.primaryGlow : null,
        ),
        padding: const EdgeInsets.all(2),
        child: CRMCard(
          padding: const EdgeInsets.all(CRMSpacing.m),
          child: InkWell(
            borderRadius: BorderRadius.circular(CRMBorderRadius.card),
            onTap: () => _openPropertyDetails(context, p),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      p.propertyCode,
                      style: CRMTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: CRMColors.primaryOf(context),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: CRMColors.primaryOf(context).withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(CRMBorderRadius.xs),
                          ),
                          child: Text(
                            p.listingTypeName,
                            style: TextStyle(
                              color: CRMColors.primaryOf(context),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: p.isStatusAvailable
                                ? CRMColors.success.withOpacity(0.1)
                                : CRMColors.warning.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(CRMBorderRadius.xs),
                          ),
                          child: Text(
                            p.statusDisplayName,
                            style: TextStyle(
                              color: p.isStatusAvailable
                                  ? CRMColors.success
                                  : CRMColors.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: CRMSpacing.s),
                Text(
                  p.title,
                  style: CRMTypography.cardTitle.copyWith(
                    color: CRMColors.textOf(context),
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: CRMSpacing.xs),
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded,
                        size: 14, color: CRMColors.textSecondaryOf(context)),
                    const SizedBox(width: 4),
                    Text(
                      'Owner: ',
                      style: CRMTypography.caption
                          .copyWith(color: CRMColors.textSecondaryOf(context)),
                    ),
                    Expanded(
                      child: Text(
                        '${p.ownerName} (${p.ownerMobile})',
                        style: CRMTypography.captionBold.copyWith(
                          color: CRMColors.textOf(context),
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: CRMSpacing.xs),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 14, color: CRMColors.textSecondaryOf(context)),
                    const SizedBox(width: 4),
                    Text(
                      '${p.areaName}, ${p.cityName}',
                      style: CRMTypography.caption
                          .copyWith(color: CRMColors.textSecondaryOf(context)),
                    ),
                  ],
                ),
                const SizedBox(height: CRMSpacing.xs),
                Row(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getPropertyBhkOrAreaIcon(p),
                            size: 14,
                            color: CRMColors.textSecondaryOf(context)),
                        const SizedBox(width: 4),
                        Text(
                          _getPropertyBhkOrAreaValue(p),
                          style: CRMTypography.captionBold.copyWith(
                            color: CRMColors.textOf(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: CRMSpacing.m),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sell_outlined,
                            size: 14,
                            color: CRMColors.textSecondaryOf(context)),
                        const SizedBox(width: 4),
                        Text(
                          CRMCurrencyFormatter.formatShort(p.price),
                          style: CRMTypography.captionBold.copyWith(
                            color: CRMColors.textOf(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: CRMSpacing.xs),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 14, color: CRMColors.textSecondaryOf(context)),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd-MM-yyyy').format(p.createdAt),
                      style: CRMTypography.caption
                          .copyWith(color: CRMColors.textSecondaryOf(context)),
                    ),
                  ],
                ),
                const Divider(height: CRMSpacing.l),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: CRMSpacing.m,
                  runSpacing: CRMSpacing.s,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Verified: ',
                          style: CRMTypography.caption.copyWith(
                              color: CRMColors.textSecondaryOf(context)),
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: p.isVerified,
                            activeColor: CRMColors.success,
                            onChanged: (val) {
                              context.read<PropertiesBloc>().add(
                                    ToggleVerificationEvent(p.id, val,
                                        activeTab: _activeTab),
                                  );
                            },
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: CRMSpacing.s,
                      runSpacing: CRMSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            isBookmarked
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: isBookmarked
                                ? CRMColors.warning
                                : CRMColors.textMutedOf(context),
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            context.read<PropertiesBloc>().add(
                                  ToggleBookmarkEvent(p.id,
                                      activeTab: _activeTab),
                                );
                          },
                        ),
                        if (isMine && _activeTab != 'My Deleted') ...[
                          IconButton(
                            icon: Icon(Icons.edit_outlined,
                                color: CRMColors.primaryOf(context), size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              if (metadata != null) {
                                _showAddEditPropertyDialog(
                                    context, metadata, p);
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline_rounded,
                                color: CRMColors.danger, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              context.read<PropertiesBloc>().add(
                                    DeletePropertyEvent(p.id,
                                        activeTab: _activeTab),
                                  );
                            },
                          ),
                        ] else if (isMine && _activeTab == 'My Deleted') ...[
                          IconButton(
                            icon: Icon(Icons.restore_rounded,
                                color: CRMColors.success, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              context.read<PropertiesBloc>().add(
                                    RestorePropertyEvent(p.id,
                                        activeTab: _activeTab),
                                  );
                            },
                          ),
                        ],
                        IconButton(
                          icon: Icon(Icons.chat_bubble_outline_rounded,
                              color: CRMColors.success, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _launchWhatsApp(p),
                          tooltip: 'Contact on WhatsApp',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String? currentUserId;
    UserModel? currentUser;
    if (authState is Authenticated) {
      currentUserId = authState.user.id;
      currentUser = authState.user;
    }
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocConsumer<PropertiesBloc, PropertiesState>(
        listener: (context, state) {
          if (state is PropertiesError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: CRMColors.danger),
            );
          } else if (state is PropertyCreatedState) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _openPropertyDetails(context, state.property);
              if (_scrollController.hasClients) {
                _scrollController.animateTo(0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOut);
              }
              setState(() {
                _highlightedPropertyId = state.property.id;
              });
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  setState(() {
                    _highlightedPropertyId = null;
                  });
                }
              });
            });
          }
        },
        builder: (context, state) {
          final isLoading =
              state is PropertiesLoading || state is PropertiesInitial;
          List<PropertyModel> properties = [];
          PropertyMetadataModel? metadata;
          Set<String> bookmarkedIds = {};

          if (state is PropertiesLoaded) {
            properties = state.properties.where((p) {
              final ltName = p.listingTypeName.toLowerCase();
              if (_activeListingTab == 'Rent') {
                return ltName.contains('rent');
              } else {
                return ltName.contains('sale') ||
                    ltName.contains('resale') ||
                    !ltName.contains('rent');
              }
            }).toList();
            metadata = state.metadata;
            bookmarkedIds = state.bookmarkedIds;

            final action =
                GoRouterState.of(context).uri.queryParameters['action'];
            if (action == 'add' &&
                !_hasAutoOpenedAdd &&
                state.metadata != null) {
              _hasAutoOpenedAdd = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showAddEditPropertyDialog(context, state.metadata!);
              });
            }

            final openId = widget.openPropertyId ??
                GoRouterState.of(context).uri.queryParameters['openId'];
            if (openId != null && !_hasAutoOpenedProp) {
              _hasAutoOpenedProp = true;
              PropertyModel? matched;
              for (final item in properties) {
                if (item.id == openId) {
                  matched = item;
                  break;
                }
              }
              if (matched != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _openPropertyDetails(context, matched!);
                });
              } else {
                PropertiesRepository().getPropertyById(openId).then((p) {
                  if (p != null && mounted) {
                    _openPropertyDetails(context, p);
                  }
                });
              }
            }
          }

          final totalPages =
              properties.isEmpty ? 1 : (properties.length / _pageSize).ceil();
          final safePage = _currentPage.clamp(0, totalPages - 1);
          final pageStart = safePage * _pageSize;
          final pageEnd = (pageStart + _pageSize).clamp(0, properties.length);
          final pagedProperties = properties.isEmpty
              ? properties
              : properties.sublist(pageStart, pageEnd);

          return SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: CRMSpacing.m,
              vertical: CRMSpacing.l,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Responsive Page Header
                _buildPageHeader(metadata),
                const SizedBox(height: CRMSpacing.l),

                // 2. Statistics Row (Overflow Fixed Layout)
                _buildStatisticsRow(properties),
                const SizedBox(height: CRMSpacing.l),

                // 3. Search & 4. Advanced Filters
                _buildSearchAndFilters(metadata),
                const SizedBox(height: CRMSpacing.l),

                // 5. Action Toolbar (Responsive choice chips)
                _buildActionToolbar(),
                const SizedBox(height: CRMSpacing.m),

                // 6. Property Table (Desktop) / Property Cards (Mobile) & 7. Pagination
                if (screenWidth < 768) ...[
                  if (isLoading)
                    const Center(
                        child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator()))
                  else if (pagedProperties.isEmpty)
                    CRMCard(
                      child: Padding(
                        padding: const EdgeInsets.all(CRMSpacing.xl),
                        child: Column(
                          children: [
                            Text('No Properties Found',
                                style: CRMTypography.sectionTitle
                                    .copyWith(color: CRMColors.textOf(context))),
                            const SizedBox(height: CRMSpacing.s),
                            Text('No records match your active search terms.',
                                style: CRMTypography.body
                                    .copyWith(color: CRMColors.textSecondaryOf(context))),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: pagedProperties.map((p) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: CRMSpacing.m),
                          child: _buildMobilePropertyCard(
                              p, currentUser, bookmarkedIds, metadata),
                        );
                      }).toList(),
                    ),
                ] else ...[
                  CRMDataTable(
                    isLoading: isLoading,
                    emptyTitle: 'No Properties Found',
                    emptyDescription:
                        'No records match your active search terms.',
                    showCheckboxColumn: false,
                    dataRowMinHeight: 72.0,
                    dataRowMaxHeight: 80.0,
                    columns: [
                      const DataColumn(label: Text('Code')),
                      const DataColumn(label: Text('Property Name')),
                      const DataColumn(label: Text('Owner')),
                      const DataColumn(label: Text('Area')),
                      DataColumn(label: Text(_getBhkColumnHeader(metadata))),
                      const DataColumn(label: Text('Price')),
                      const DataColumn(label: Text('Date')),
                      const DataColumn(label: Text('Status')),
                      const DataColumn(label: Text('Photos')),
                      const DataColumn(label: Text('Shortlist')),
                      const DataColumn(label: Text('Actions')),
                    ],
                    rows: pagedProperties.map((p) {
                      final isMine = _hasEditAccess(p, currentUser);
                      final isBookmarked = bookmarkedIds.contains(p.id);
                      return DataRow(
                        color:
                            WidgetStateProperty.resolveWith<Color?>((states) {
                          if (p.id == _highlightedPropertyId) {
                            return CRMColors.primaryOf(context).withOpacity(0.08);
                          }
                          return null;
                        }),
                        onSelectChanged: (_) =>
                            _openPropertyDetails(context, p),
                        cells: [
                          DataCell(Text(p.propertyCode,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold))),
                          DataCell(Text(p.title)),
                          DataCell(
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(p.ownerName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  Text(p.ownerMobile,
                                      style: TextStyle(
                                          color: CRMColors.textMutedOf(context),
                                          fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                          DataCell(Text(p.areaName)),
                          DataCell(Text(_getPropertyBhkOrAreaValue(p))),
                          DataCell(Text(CRMCurrencyFormatter.formatShort(p.price),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600))),
                          DataCell(Text(
                              DateFormat('dd-MM-yyyy').format(p.createdAt))),
                          DataCell(
                            PopupMenuButton<String>(
                              tooltip: 'Change Status',
                              onSelected: (String statusName) async {
                                if (statusName == 'To Be Available') {
                                  final DateTime? pickedDate =
                                      await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now()
                                        .add(const Duration(days: 1)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now()
                                        .add(const Duration(days: 365 * 5)),
                                    helpText: 'Select Available Date',
                                  );
                                  if (pickedDate == null) return;

                                  LookupItem? targetLookup;
                                  if (metadata != null) {
                                    for (final s in metadata.statuses) {
                                      if (s.name
                                          .toLowerCase()
                                          .contains('to be available')) {
                                        targetLookup = s;
                                        break;
                                      }
                                    }
                                  }
                                  final statusId = targetLookup?.id ??
                                      '05a73434-e99b-425b-99b2-1825d529ac35';
                                  if (context.mounted) {
                                    context.read<PropertiesBloc>().add(
                                          UpdatePropertyEvent(
                                            p.id,
                                            {
                                              'property_status_id': statusId,
                                              'possession_date': pickedDate
                                                  .toIso8601String()
                                                  .substring(0, 10),
                                            },
                                            activeTab: _activeTab,
                                          ),
                                        );
                                  }
                                  return;
                                }

                                LookupItem? targetLookup;
                                if (metadata != null) {
                                  for (final s in metadata.statuses) {
                                    if (s.name
                                            .toLowerCase()
                                            .replaceAll(' ', '') ==
                                        statusName
                                            .toLowerCase()
                                            .replaceAll(' ', '')) {
                                      targetLookup = s;
                                      break;
                                    }
                                  }
                                }
                                final statusId = targetLookup?.id ?? statusName;
                                context.read<PropertiesBloc>().add(
                                      UpdatePropertyEvent(
                                        p.id,
                                        {'property_status_id': statusId},
                                        activeTab: _activeTab,
                                      ),
                                    );
                              },
                              itemBuilder: (BuildContext context) {
                                final isRent = p.listingTypeName
                                    .toLowerCase()
                                    .contains('rent');
                                return <PopupMenuEntry<String>>[
                                  const PopupMenuItem<String>(
                                    value: 'Available',
                                    child: Text('Available'),
                                  ),
                                  if (isRent) ...[
                                    const PopupMenuItem<String>(
                                      value: 'Rented Out',
                                      child: Text('Rented Out'),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'To Be Available',
                                      child: Text('To Be Available'),
                                    ),
                                  ] else ...[
                                    const PopupMenuItem<String>(
                                      value: 'Sold Out',
                                      child: Text('Sold Out'),
                                    ),
                                  ],
                                ];
                              },
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: p.isStatusAvailable
                                        ? CRMColors.success
                                            .withValues(alpha: 0.12)
                                        : CRMColors.warning
                                            .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                        CRMBorderRadius.xs),
                                    border: Border.all(
                                      color: (p.isStatusAvailable
                                              ? CRMColors.success
                                              : CRMColors.warning)
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          p.statusDisplayName,
                                          style: TextStyle(
                                            color: p.isStatusAvailable
                                                ? CRMColors.success
                                                : CRMColors.warning,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Icon(
                                          Icons.arrow_drop_down_rounded,
                                          size: 16,
                                          color: p.isStatusAvailable
                                              ? CRMColors.success
                                              : CRMColors.warning,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Builder(
                              builder: (context) {
                                final hasImages = p.images.isNotEmpty;
                                return InkWell(
                                  onTap: hasImages
                                      ? () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => CRMImageZoomViewer(
                                              images: p.images,
                                              initialIndex: 0,
                                            ),
                                          );
                                        }
                                      : null,
                                  borderRadius:
                                      BorderRadius.circular(CRMBorderRadius.xs),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: CRMColors.backgroundOf(context),
                                      borderRadius: BorderRadius.circular(
                                          CRMBorderRadius.xs),
                                      border: Border.all(
                                        color: hasImages
                                            ? CRMColors.primaryOf(context).withOpacity(0.3)
                                            : CRMColors.borderOf(context).withOpacity(0.6),
                                        width: 0.5,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: hasImages
                                        ? Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              _buildPropertyThumbnail(
                                                  p.images.first),
                                              if (p.images.length > 1)
                                                Positioned(
                                                  right: 0,
                                                  bottom: 0,
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 3,
                                                        vertical: 1),
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Color(0xB3000000),
                                                      borderRadius:
                                                          BorderRadius.only(
                                                              topLeft: Radius
                                                                  .circular(4)),
                                                    ),
                                                    child: Text(
                                                      '+${p.images.length - 1}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          )
                                        : Icon(
                                            Icons.image_not_supported_outlined,
                                            size: 18,
                                            color:
                                                CRMColors.textMutedOf(context),
                                          ),
                                  ),
                                );
                              },
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: Icon(
                                isBookmarked
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: isBookmarked
                                    ? CRMColors.warning
                                    : CRMColors.textMutedOf(context),
                              ),
                              onPressed: () {
                                context.read<PropertiesBloc>().add(
                                      ToggleBookmarkEvent(p.id,
                                          activeTab: _activeTab),
                                    );
                              },
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isMine) ...[
                                  IconButton(
                                    icon: Icon(Icons.edit_outlined,
                                        color: CRMColors.primaryOf(context), size: 18),
                                    onPressed: () {
                                      if (metadata != null) {
                                        _showAddEditPropertyDialog(
                                            context, metadata!, p);
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline_rounded,
                                        color: CRMColors.danger, size: 18),
                                    onPressed: () {
                                      context.read<PropertiesBloc>().add(
                                            DeletePropertyEvent(p.id,
                                                activeTab: _activeTab),
                                          );
                                    },
                                  ),
                                ],
                                IconButton(
                                  icon: Icon(Icons.chat_bubble_outline_rounded,
                                      color: CRMColors.success, size: 18),
                                  onPressed: () => _launchWhatsApp(p),
                                  tooltip: 'Contact on WhatsApp',
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
                if (properties.isNotEmpty) ...[
                  const SizedBox(height: CRMSpacing.m),
                  _buildPagination(properties.length, totalPages, safePage),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageHeader(PropertyMetadataModel? metadata) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    Widget leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Workspace',
            style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context))),
        Text(
          'Properties Operating System',
          style: CRMTypography.pageTitle.copyWith(
            color: CRMColors.textOf(context),
            fontSize: isMobile ? 20 : 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    Widget rightColumn = CRMButton(
      label: 'Add Property',
      prefixIcon: Icons.add_circle_outline_rounded,
      onPressed: () {
        if (metadata == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Metadata lookups loading, please try again.')),
          );
          return;
        }
        _showAddEditPropertyDialog(context, metadata!);
      },
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          leftColumn,
          const SizedBox(height: CRMSpacing.m),
          rightColumn,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: leftColumn),
        const SizedBox(width: CRMSpacing.m),
        rightColumn,
      ],
    );
  }

  Widget _buildStatisticsRow(List<PropertyModel> properties) {
    final bookmarkedIds =
        (context.read<PropertiesBloc>().state is PropertiesLoaded)
            ? (context.read<PropertiesBloc>().state as PropertiesLoaded)
                .bookmarkedIds
            : <String>{};

    final verified = properties.where((p) => p.isVerified).length;
    final active =
        properties.where((p) => p.propertyStatusName == 'Available').length;
    final shortlisted =
        properties.where((p) => bookmarkedIds.contains(p.id)).length;

    final double screenWidth = MediaQuery.of(context).size.width;

    final cards = [
      CRMKPICard(
          title: 'Active listings',
          value: '$active',
          icon: Icons.bolt_rounded,
          iconColor: CRMColors.primaryOf(context)),
      CRMKPICard(
          title: 'Verified listings',
          value: '$verified',
          icon: Icons.verified_user_outlined,
          iconColor: CRMColors.success),
      CRMKPICard(
          title: 'Shortlisted listings',
          value: '$shortlisted',
          icon: Icons.star_outline_rounded,
          iconColor: CRMColors.warning),
    ];

    final int crossAxisCount = screenWidth >= 1000 ? cards.length : 2;
    final double childAspectRatio =
        screenWidth >= 1000 ? (cards.length == 4 ? 2.2 : 2.5) : 1.5;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: CRMSpacing.m,
        mainAxisSpacing: CRMSpacing.m,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) => cards[index],
    );
  }

  Widget _buildSearchAndFilters(PropertyMetadataModel? metadata) {
    final categories = metadata != null ? metadata.categories : <LookupItem>[];
    final areas = metadata != null ? metadata.areas : <AreaLookup>[];
    final listingTypes =
        metadata != null ? metadata.listingTypes : <LookupItem>[];

    return CRMCard(
      title: 'Advanced Search Filter Drawer',
      subtitle: 'Perform refined lookup filters across listing records',
      child: Padding(
        padding: const EdgeInsets.only(top: CRMSpacing.s),
        child: Column(
          children: [
            // Search Input Row
            LayoutBuilder(
              builder: (context, searchConstraints) {
                final isCompactSearch = searchConstraints.maxWidth < 500;

                final searchField = TextField(
                  controller: _searchController,
                  style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
                  decoration: InputDecoration(
                    hintText: 'Search property code, title, owner mobile...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: CRMColors.backgroundOf(context),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                        borderSide: BorderSide.none),
                  ),
                  onChanged: (_) => _loadProperties(),
                );

                final searchButton = CRMButton(
                  label: 'Search',
                  onPressed: _loadProperties,
                );

                if (isCompactSearch) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      searchField,
                      const SizedBox(height: CRMSpacing.s),
                      searchButton,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: searchField),
                    const SizedBox(width: CRMSpacing.s),
                    searchButton,
                  ],
                );
              },
            ),
            const SizedBox(height: CRMSpacing.m),

            // Filters Dropdowns Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                double targetWidth;

                if (width >= 900) {
                  targetWidth = (width - (CRMSpacing.m * 4)) / 5;
                } else if (width >= 600) {
                  targetWidth = (width - CRMSpacing.m) / 2;
                } else {
                  targetWidth = width;
                }

                return Wrap(
                  spacing: CRMSpacing.m,
                  runSpacing: CRMSpacing.m,
                  children: [
                    // Rent vs Sale/Re-Sale Toggle Tabs
                    Container(
                      height: 48,
                      width: targetWidth,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: CRMColors.backgroundOf(context),
                        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                        border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.6), width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                              child: _buildPropertyListingTabButton('Rent')),
                          const SizedBox(width: 4),
                          Expanded(
                              child: _buildPropertyListingTabButton('Re-Sale')),
                        ],
                      ),
                    ),
                    _buildDropdown(
                      label: 'Category',
                      value: _selectedCategory,
                      items: categories
                          .map((c) => DropdownMenuItem<String>(
                              value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategory = val;
                          _currentPage = 0;
                        });
                        _loadProperties();
                      },
                      width: targetWidth,
                    ),
                    _buildDropdown(
                      label: 'Area',
                      value: _selectedArea,
                      items: areas
                          .map((a) => DropdownMenuItem<String>(
                              value: a.id, child: Text(a.name)))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedArea = val;
                          _currentPage = 0;
                        });
                        _loadProperties();
                      },
                      width: targetWidth,
                    ),
                    _buildVerificationDropdown(targetWidth),
                    SizedBox(
                      width: targetWidth,
                      height: 48,
                      child: CRMButton(
                        label: 'Clear Filters',
                        variant: CRMButtonVariant.outline,
                        onPressed: _clearFilters,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyListingTabButton(String label) {
    final isSelected = _activeListingTab == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeListingTab = label;
          _currentPage = 0;
        });
      },
      child: AnimatedContainer(
        duration: CRMMotion.fast,
        curve: CRMMotion.easeOut,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? CRMColors.primaryOf(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(CRMBorderRadius.xs),
        ),
        child: Text(
          label,
          style: CRMTypography.captionBold.copyWith(
            color: isSelected ? Colors.white : CRMColors.textSecondaryOf(context),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = null;
      _selectedArea = null;
      _selectedListingType = null;
      _selectedVerification = null;
      _activeListingTab = 'Rent';
      _currentPage = 0;
    });
    _loadProperties();
  }

  Widget _buildVerificationDropdown(double width) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<bool?>(
        value: _selectedVerification,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Verification',
          filled: true,
          fillColor: CRMColors.backgroundOf(context),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: CRMSpacing.m, vertical: CRMSpacing.s),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              borderSide: BorderSide.none),
        ),
        items: const [
          DropdownMenuItem<bool?>(
              value: null,
              child: Text('All Verification', overflow: TextOverflow.ellipsis)),
          DropdownMenuItem<bool?>(
              value: true,
              child: Text('Verified', overflow: TextOverflow.ellipsis)),
          DropdownMenuItem<bool?>(
              value: false,
              child: Text('Unverified', overflow: TextOverflow.ellipsis)),
        ],
        onChanged: (val) {
          setState(() {
            _selectedVerification = val;
            _currentPage = 0;
          });
          _loadProperties();
        },
      ),
    );
  }

  Widget _buildPagination(int totalItems, int totalPages, int currentPage) {
    final from = currentPage * _pageSize + 1;
    final to = ((currentPage + 1) * _pageSize).clamp(0, totalItems);
    final double screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 500;

    final infoText = Text(
      'Showing $from–$to of $totalItems',
      style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
    );

    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Rows:',
            style:
                CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context))),
        const SizedBox(width: CRMSpacing.xs),
        DropdownButton<int>(
          value: _pageSize,
          underline: const SizedBox.shrink(),
          items: _pageSizeOptions
              .map(
                  (size) => DropdownMenuItem(value: size, child: Text('$size')))
              .toList(),
          onChanged: (val) {
            if (val == null) return;
            setState(() {
              _pageSize = val;
              _currentPage = 0;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed:
              currentPage > 0 ? () => setState(() => _currentPage--) : null,
        ),
        Text(
          '${currentPage + 1} / $totalPages',
          style: CRMTypography.captionBold.copyWith(color: CRMColors.textOf(context)),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: currentPage < totalPages - 1
              ? () => setState(() => _currentPage++)
              : null,
        ),
      ],
    );

    if (isMobile) {
      return Column(
        children: [
          infoText,
          const SizedBox(height: CRMSpacing.s),
          controls,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        infoText,
        controls,
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    required double width,
  }) {
    final bool hasValue =
        value == null || items.any((item) => item.value == value);
    final String? safeValue = hasValue ? value : null;

    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        value: safeValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: CRMColors.backgroundOf(context),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: CRMSpacing.m, vertical: CRMSpacing.s),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              borderSide: BorderSide.none),
        ),
        items: [
          DropdownMenuItem<String>(
              value: null,
              child: Text('All $label', overflow: TextOverflow.ellipsis)),
          ...items,
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionToolbar() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final chipsList = Wrap(
      spacing: CRMSpacing.s,
      runSpacing: CRMSpacing.xs,
      children: ['All', 'Shortlisted'].map((tab) {
        final isSelected = _activeTab == tab;
        return ChoiceChip(
          label: Text(tab),
          selected: isSelected,
          selectedColor: CRMColors.primaryOf(context).withOpacity(0.12),
          labelStyle: TextStyle(
            color: isSelected ? CRMColors.primaryOf(context) : CRMColors.textOf(context),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
          onSelected: (val) {
            if (val) {
              setState(() {
                _activeTab = tab;
                _currentPage = 0;
              });
              _loadProperties();
            }
          },
        );
      }).toList(),
    );

    final refreshButton = IconButton(
      icon: Icon(Icons.refresh_rounded, color: CRMColors.textSecondaryOf(context)),
      onPressed: _loadProperties,
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filter Views',
                  style: CRMTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.bold)),
              refreshButton,
            ],
          ),
          const SizedBox(height: CRMSpacing.xs),
          chipsList,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: chipsList),
        refreshButton,
      ],
    );
  }

  void _showAddEditPropertyDialog(
      BuildContext context, PropertyMetadataModel metadata,
      [PropertyModel? property]) {
    final propertiesBloc = context.read<PropertiesBloc>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12.0 : 40.0,
          vertical: isMobile ? 16.0 : 24.0,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: CRMColors.cardBgOf(dialogContext),
            borderRadius: BorderRadius.circular(CRMBorderRadius.dialog),
            boxShadow: CRMShadows.modal,
          ),
          width: isMobile ? screenWidth - 24 : screenWidth * 0.95,
          height: MediaQuery.of(context).size.height * 0.95,
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 750),
          clipBehavior: Clip.antiAlias,
          child: BlocProvider.value(
            value: propertiesBloc,
            child: AddEditPropertyScreen(
              metadata: metadata,
              property: property,
              activeTab: _activeTab,
            ),
          ),
        ),
      ),
    );
  }

  void _openPropertyDetails(BuildContext context, PropertyModel p) {
    final String url = '${Uri.base.origin}/properties/${p.id}';
    launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
  }

  String _getBhkColumnHeader(PropertyMetadataModel? metadata) {
    if (_selectedCategory == null || metadata == null) {
      return 'BHK';
    }
    final selectedCat = metadata.categories.firstWhere(
      (c) => c.id == _selectedCategory,
      orElse: () => LookupItem(id: '', name: ''),
    );
    final name = selectedCat.name.toLowerCase();
    if (name.contains('commercial') || name.contains('industrial')) {
      return 'Super Built-up Area';
    } else if (name.contains('land') || name.contains('plot')) {
      return 'Plot Area';
    }
    return 'BHK';
  }

  String _getPropertyBhkOrAreaValue(PropertyModel p) {
    final catName = p.categoryName.toLowerCase();
    if (catName.contains('commercial') || catName.contains('industrial')) {
      return p.superBuiltupArea != null && p.superBuiltupArea! > 0
          ? '${p.superBuiltupArea!.toStringAsFixed(0)} Sq.Ft'
          : 'N/A';
    } else if (catName.contains('land') || catName.contains('plot')) {
      return p.plotArea != null && p.plotArea! > 0
          ? '${p.plotArea!.toStringAsFixed(0)} Sq.Ft'
          : 'N/A';
    }
    return '${p.bedrooms} BHK';
  }

  IconData _getPropertyBhkOrAreaIcon(PropertyModel p) {
    final catName = p.categoryName.toLowerCase();
    if (catName.contains('commercial') || catName.contains('industrial')) {
      return Icons.business_center_outlined;
    } else if (catName.contains('land') || catName.contains('plot')) {
      return Icons.landscape_outlined;
    }
    return Icons.king_bed_outlined;
  }

  Widget _buildPropertyThumbnail(String url) {
    if (url.startsWith('data:image') || url.contains('base64')) {
      try {
        final base64Str = url.split(',').last;
        return Image.memory(base64Decode(base64Str), fit: BoxFit.cover);
      } catch (_) {}
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(
        child: SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      ),
      errorWidget: (context, url, error) =>
          const Icon(Icons.broken_image_outlined, size: 16),
    );
  }
}
