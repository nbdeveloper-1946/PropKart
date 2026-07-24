import 'package:flutter/material.dart';
import '../../properties/models/property_model.dart';
import '../../properties/repository/properties_repository.dart';
import '../../properties/services/properties_service.dart';
import '../../../core/storage/repository_coordinator.dart';
import '../../../core/storage/isar_collections.dart';
import '../../../core/storage/model_mappers.dart';
import '../../../core/design_system/crm_design_system.dart';
import '../../../core/design_system/widgets/drawers.dart';

class PropertyDetailScreen extends StatefulWidget {
  final String propertyId;
  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  PropertyModel? _property;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProperty();
  }

  Future<void> _loadProperty() async {
    try {
      final repository = PropertiesRepository();
      
      // 1. Instantly check if we have the property locally
      final local = await repository.getPropertyById(widget.propertyId);
      if (local != null) {
        setState(() {
          _property = local;
          _isLoading = false;
        });
      }

      // 2. Fetch fresh list from server in the background to update/hydrate
      final response = await PropertiesService().getProperties();
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final list = data['properties'] as List? ?? [];
      final freshList = list.map((item) => PropertyModel.fromJson(item)).toList();
      
      // Sync fresh list to local storage
      final localEntities = freshList.map((p) => p.toLocal()).toList();
      await RepositoryCoordinator().propertyLocal.saveProperties(localEntities);

      // Find the matched property
      final matched = freshList.firstWhere(
        (p) => p.id == widget.propertyId,
        orElse: () => null as dynamic,
      );

      if (matched != null) {
        setState(() {
          _property = matched;
          _isLoading = false;
        });
      } else if (_property == null) {
        setState(() {
          _error = 'Property not found.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (_property == null) {
        setState(() {
          _error = 'Failed to load details: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _property == null) {
      return Scaffold(
        backgroundColor: CRMColors.backgroundOf(context),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null && _property == null) {
      return Scaffold(
        backgroundColor: CRMColors.backgroundOf(context),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, color: CRMColors.danger, size: 48),
              const SizedBox(height: CRMSpacing.m),
              Text(_error!, style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondaryOf(context))),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: CRMColors.backgroundOf(context),
      body: BuildPropertyDetailWidget(property: _property!, showHeaderClose: false),
    );
  }
}
