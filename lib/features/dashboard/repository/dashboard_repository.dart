import 'package:propkart/features/dashboard/models/dashboard_summary.dart';
import 'package:propkart/features/dashboard/services/dashboard_service.dart';
import 'package:propkart/core/storage/repository_coordinator.dart';
import 'package:propkart/core/storage/isar_collections.dart';
import 'package:propkart/core/storage/model_mappers.dart';
import 'package:propkart/core/storage/performance_logger.dart';

class DashboardRepository {
  final DashboardService _dashboardService = DashboardService();
  final RepositoryCoordinator _coordinator = RepositoryCoordinator();

  Future<DashboardData> getDashboardData() async {
    final start = DateTime.now();
    
    // Read from local Isar
    final localDashboard = await _coordinator.dashboardLocal.getDashboard();
    final isarReadMs = DateTime.now().difference(start).inMilliseconds;
    
    DashboardData? cachedData;
    int jsonParseMs = 0;
    if (localDashboard != null) {
      final parseStart = DateTime.now();
      cachedData = localDashboard.toModel();
      jsonParseMs = DateTime.now().difference(parseStart).inMilliseconds;
    }

    final totalMs = DateTime.now().difference(start).inMilliseconds;
    PerformanceLogger().logMetric(
      operation: 'DashboardRepository.getDashboardData (local)',
      isarReadMs: isarReadMs,
      jsonParseMs: jsonParseMs,
      totalMs: totalMs,
    );

    // Trigger async background refresh
    _triggerBackgroundDashboardRefresh();

    // Get the dynamic counts of requirements to ensure they are always correct and in sync
    final localReqs = await _coordinator.requirementLocal.getRequirements();
    int rentalReqs = 0;
    int resaleReqs = 0;
    for (final item in localReqs) {
      if (item.status == 'Bin') continue;

      final name = item.listingTypeName ?? '';
      final id = item.listingTypeId ?? '';
      final combined = '$name $id'.toLowerCase();
      if (combined.contains('rent')) {
        rentalReqs++;
      } else if (combined.contains('sale') || combined.contains('resale')) {
        resaleReqs++;
      }
    }

    if (cachedData != null) {
      final updatedSummary = DashboardSummary(
        totalProperties: cachedData.summary.totalProperties,
        available: cachedData.summary.available,
        sold: cachedData.summary.sold,
        rented: cachedData.summary.rented,
        requirements: rentalReqs + resaleReqs,
        users: cachedData.summary.users,
        rentalAvailable: cachedData.summary.rentalAvailable,
        resaleAvailable: cachedData.summary.resaleAvailable,
        rentalRented: cachedData.summary.rentalRented,
        resaleSold: cachedData.summary.resaleSold,
        rentalRequirements: rentalReqs,
        resaleRequirements: resaleReqs,
        totalPropertiesTrend: cachedData.summary.totalPropertiesTrend,
        availableTrend: cachedData.summary.availableTrend,
        soldTrend: cachedData.summary.soldTrend,
        rentedTrend: cachedData.summary.rentedTrend,
        requirementsTrend: cachedData.summary.requirementsTrend,
        topBroker: cachedData.summary.topBroker,
        topArea: cachedData.summary.topArea,
        topProperty: cachedData.summary.topProperty,
        monthlyGrowth: cachedData.summary.monthlyGrowth,
      );

      return DashboardData(
        summary: updatedSummary,
        activity: cachedData.activity,
        recentProperties: cachedData.recentProperties,
        checklist: cachedData.checklist,
        followups: cachedData.followups,
        siteVisits: cachedData.siteVisits,
      );
    }

    // Fallback if cache is completely empty on first launch
    final data = await _dashboardService.getDashboardData();
    final model = DashboardData.fromJson(data);
    await _coordinator.dashboardLocal.saveDashboard(model.toLocal());

    final updatedSummary = DashboardSummary(
      totalProperties: model.summary.totalProperties,
      available: model.summary.available,
      sold: model.summary.sold,
      rented: model.summary.rented,
      requirements: rentalReqs + resaleReqs,
      users: model.summary.users,
      rentalAvailable: model.summary.rentalAvailable,
      resaleAvailable: model.summary.resaleAvailable,
      rentalRented: model.summary.rentalRented,
      resaleSold: model.summary.resaleSold,
      rentalRequirements: rentalReqs,
      resaleRequirements: resaleReqs,
      totalPropertiesTrend: model.summary.totalPropertiesTrend,
      availableTrend: model.summary.availableTrend,
      soldTrend: model.summary.soldTrend,
      rentedTrend: model.summary.rentedTrend,
      requirementsTrend: model.summary.requirementsTrend,
      topBroker: model.summary.topBroker,
      topArea: model.summary.topArea,
      topProperty: model.summary.topProperty,
      monthlyGrowth: model.summary.monthlyGrowth,
    );

    return DashboardData(
      summary: updatedSummary,
      activity: model.activity,
      recentProperties: model.recentProperties,
      checklist: model.checklist,
      followups: model.followups,
      siteVisits: model.siteVisits,
    );
  }

  void _triggerBackgroundDashboardRefresh() {
    final start = DateTime.now();
    _dashboardService.getDashboardData().then((response) async {
      final networkMs = DateTime.now().difference(start).inMilliseconds;

      final parseStart = DateTime.now();
      final freshData = DashboardData.fromJson(response);
      final jsonParseMs = DateTime.now().difference(parseStart).inMilliseconds;

      final writeStart = DateTime.now();
      // Save locally to dashboard local table
      await _coordinator.dashboardLocal.saveDashboard(freshData.toLocal());
      
      // Also synchronize structured followups table inside Isar
      final listData = response['followups'] as List? ?? [];
      final freshFollowups = listData.map((item) => DashboardFollowup.fromJson(item)).toList();
      final localEntities = freshFollowups.map((f) => f.toLocal('System')).toList();
      await _coordinator.followupLocal.saveFollowups(localEntities);
      final isarWriteMs = DateTime.now().difference(writeStart).inMilliseconds;

      final totalMs = DateTime.now().difference(start).inMilliseconds;
      PerformanceLogger().logMetric(
        operation: 'DashboardRepository.getDashboardData (background refresh)',
        networkMs: networkMs,
        jsonParseMs: jsonParseMs,
        isarWriteMs: isarWriteMs,
        totalMs: totalMs,
      );

      _coordinator.refreshDashboard();
    }).catchError((_) {});
  }
}
