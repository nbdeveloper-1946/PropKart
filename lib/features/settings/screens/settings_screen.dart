import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../modules/config/services/config_service.dart';
import '../../../modules/version/presentation/update_dialogs.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/dialogs.dart';
import '../../../core/theme/theme_manager.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../properties/models/property_model.dart';
import '../../properties/services/properties_service.dart';
import 'sync_debug_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PropertiesService _propertiesService = PropertiesService();
  final ConfigService _configService = ConfigService();
  bool _isLoading = true;
  bool _isFetchingPincode = false;
  List<LookupItem> _cities = [];
  List<AreaLookup> _areas = [];
  String? _selectedCityForArea;

  final _cityController = TextEditingController();
  final _areaNameController = TextEditingController();
  final _pincodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    ThemeManager().addListener(_onThemeChanged);
    _loadLocationMetadata();
    _pincodeController.addListener(_onPincodeChanged);
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadLocationMetadata() async {
    setState(() => _isLoading = true);
    try {
      final response = await _propertiesService.getPropertyMetadata();
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final meta = PropertyMetadataModel.fromJson(data['metadata'] ?? {});
      setState(() {
        _cities = meta.cities;
        _areas = meta.areas;
        if (_cities.isNotEmpty) {
          _selectedCityForArea = _cities.first.id;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load location configs: $e'), backgroundColor: CRMColors.danger),
        );
      }
    }
  }

  Future<void> _addCity() async {
    final name = _cityController.text.trim();
    if (name.isEmpty) return;

    // Check for duplicates
    final cityExists = _cities.any((c) => c.name.toLowerCase() == name.toLowerCase());
    if (cityExists) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.card)),
          backgroundColor: CRMColors.surfaceElevatedOf(context),
          title: Text('Duplicate City', style: CRMTypography.sectionTitle),
          content: Text('A city named "$name" already exists in the configuration.', style: CRMTypography.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Dismiss'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _propertiesService.createCity(name);
      final newCity = LookupItem(
        id: result['data']['city']['id'],
        name: result['data']['city']['city_name'],
      );
      setState(() {
        _cities.add(newCity);
        _selectedCityForArea = newCity.id;
        _cityController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('City created successfully'), backgroundColor: CRMColors.success),
      );
      _loadLocationMetadata();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add city: $e'), backgroundColor: CRMColors.danger),
      );
    }
  }

  Future<void> _addArea() async {
    final name = _areaNameController.text.trim();
    final pincode = _pincodeController.text.trim();
    if (name.isEmpty || pincode.isEmpty || _selectedCityForArea == null) return;

    // Check for duplicates
    final areaExists = _areas.any((a) =>
      a.cityId == _selectedCityForArea &&
      a.name.toLowerCase() == name.toLowerCase() &&
      a.pincode == pincode
    );
    if (areaExists) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.card)),
          backgroundColor: CRMColors.surfaceElevatedOf(context),
          title: Text('Duplicate Area', style: CRMTypography.sectionTitle),
          content: Text('An area named "$name" with Pincode "$pincode" already exists for the selected city.', style: CRMTypography.body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Dismiss'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _propertiesService.createArea(_selectedCityForArea!, name, pincode);
      setState(() {
        _areaNameController.clear();
        _pincodeController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Area created successfully'), backgroundColor: CRMColors.success),
      );
      _loadLocationMetadata();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add area: $e'), backgroundColor: CRMColors.danger),
      );
    }
  }

  void _onPincodeChanged() {
    final pincode = _pincodeController.text.trim();
    if (pincode.length == 6 && !_isFetchingPincode) {
      _lookupPincode(pincode);
    }
  }

  Future<void> _lookupPincode(String pincode) async {
    setState(() => _isFetchingPincode = true);
    try {
      final dio = Dio();
      final response = await dio.get('https://api.postalpincode.in/pincode/$pincode');
      
      if (response.statusCode == 200 && response.data is List && response.data.isNotEmpty) {
        final data = response.data[0] as Map<String, dynamic>;
        final status = data['Status']?.toString();
        final postOffices = data['PostOffice'] as List?;
        
        if (status == 'Success' && postOffices != null && postOffices.isNotEmpty) {
          final firstOffice = postOffices[0] as Map<String, dynamic>;
          final districtName = firstOffice['District']?.toString() ?? '';
          
          LookupItem? matchedCity;
          for (final city in _cities) {
            if (city.name.toLowerCase() == districtName.toLowerCase()) {
              matchedCity = city;
              break;
            }
          }
          
          void showAreaSelection(String cityId, String cityName) {
            final List<String> areaNames = postOffices
                .map((po) => po['Name']?.toString() ?? '')
                .where((name) => name.isNotEmpty)
                .toSet() // Remove duplicates from response
                .toList();
            
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.card)),
                backgroundColor: CRMColors.surfaceElevatedOf(context),
                title: Text('Select Area for $pincode ($cityName)', style: CRMTypography.sectionTitle),
                content: SizedBox(
                  width: 300,
                  height: 250,
                  child: ListView.builder(
                    itemCount: areaNames.length,
                    itemBuilder: (context, index) {
                      final areaName = areaNames[index];
                      return ListTile(
                        title: Text(areaName, style: TextStyle(color: CRMColors.textOf(context))),
                        onTap: () {
                          _areaNameController.text = areaName;
                          setState(() {
                            _selectedCityForArea = cityId;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            );
          }
          
          if (matchedCity != null) {
            showAreaSelection(matchedCity.id, matchedCity.name);
          } else if (districtName.isNotEmpty) {
            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.card)),
                  backgroundColor: CRMColors.surfaceElevatedOf(context),
                  title: Text('City Mapping Not Found', style: CRMTypography.sectionTitle),
                  content: Text('Pincode $pincode is located in "$districtName", but this city is not configured in your settings. Would you like to add "$districtName" as a new city first?', style: CRMTypography.body),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('No'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        setState(() => _isLoading = true);
                        try {
                          final result = await _propertiesService.createCity(districtName);
                          final newCity = LookupItem(
                            id: result['data']['city']['id'],
                            name: result['data']['city']['city_name'],
                          );
                          setState(() {
                            _cities.add(newCity);
                            _selectedCityForArea = newCity.id;
                            _isLoading = false;
                          });
                          showAreaSelection(newCity.id, newCity.name);
                          _loadLocationMetadata();
                        } catch (e) {
                          setState(() => _isLoading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to auto-add city: $e'), backgroundColor: CRMColors.danger),
                          );
                        }
                      },
                      child: const Text('Yes, Add City'),
                    ),
                  ],
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      print("⚠️ [POSTAL API ERROR] Failed to fetch postal details: $e");
    } finally {
      if (mounted) {
        setState(() => _isFetchingPincode = false);
      }
    }
  }

  Future<void> _deleteCity(String id) async {
    final confirm = await CRMDialogs.showDeleteConfirmation(
      context,
      title: 'Delete City',
      content: 'Are you sure you want to delete this city configuration?',
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _propertiesService.deleteCity(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('City deleted successfully'), backgroundColor: CRMColors.success),
      );
      _loadLocationMetadata();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete city: $e'), backgroundColor: CRMColors.danger),
      );
    }
  }

  Future<void> _deleteArea(String id) async {
    final confirm = await CRMDialogs.showDeleteConfirmation(
      context,
      title: 'Delete Area',
      content: 'Are you sure you want to delete this area mapping configuration?',
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _propertiesService.deleteArea(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Area deleted successfully'), backgroundColor: CRMColors.success),
      );
      _loadLocationMetadata();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete area: $e'), backgroundColor: CRMColors.danger),
      );
    }
  }

  Widget _buildProfileCard(String name, String email) {
    return CRMCard(
      elevated: true,
      title: 'User Profile',
      subtitle: 'Manage your personal account details',
      child: Padding(
        padding: const EdgeInsets.only(top: CRMSpacing.m),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: CRMColors.primary.withOpacity(0.12),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: CRMTypography.sectionTitle.copyWith(
                      color: CRMColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: CRMSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: CRMTypography.bodyMedium.copyWith(
                          color: CRMColors.text,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: CRMSpacing.l),
            InkWell(
              onTap: () => context.go('/profile'),
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              child: Container(
                padding: const EdgeInsets.all(CRMSpacing.m),
                decoration: BoxDecoration(
                  color: CRMColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                  border: Border.all(color: CRMColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, color: CRMColors.primary, size: 20),
                    const SizedBox(width: CRMSpacing.s),
                    Expanded(
                      child: Text(
                        'Edit & View Profile Details',
                        style: CRMTypography.captionBold.copyWith(color: CRMColors.primary),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: CRMColors.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceCard(bool isAdminOrSuperAdmin) {
    final isDark = ThemeManager().isDarkMode;
    return CRMCard(
      title: 'System & Appearance',
      subtitle: isAdminOrSuperAdmin
          ? 'Customize visual themes and view diagnostic logs'
          : 'Customize visual themes',
      child: Padding(
        padding: const EdgeInsets.only(top: CRMSpacing.xs),
        child: Column(
          children: [
            SwitchListTile(
              title: Text(
                'Dark Mode',
                style: CRMTypography.bodyMedium.copyWith(
                  color: CRMColors.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Toggle between light and dark visual themes',
                style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
              ),
              secondary: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                color: isDark ? CRMColors.primary : CRMColors.textSecondary,
              ),
              value: isDark,
              activeColor: CRMColors.primary,
              onChanged: (val) {
                ThemeManager().toggleTheme();
              },
              contentPadding: EdgeInsets.zero,
            ),
            if (isAdminOrSuperAdmin) ...[
              const Divider(height: CRMSpacing.l),
              ListTile(
                title: Text(
                  'Sync Diagnostics',
                  style: CRMTypography.bodyMedium.copyWith(
                    color: CRMColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'View network logs, outbox status, and realtime diagnostics',
                  style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                ),
                leading: Icon(Icons.sync_rounded, color: CRMColors.primary),
                trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: CRMColors.textSecondary),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SyncDebugScreen()),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard() {
    return CRMCard(
      title: 'About PropKart',
      subtitle: 'View software version details and check for updates',
      child: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final version = snapshot.data?.version ?? '1.0.0';
          final buildNumber = snapshot.data?.buildNumber ?? '1';
          
          return FutureBuilder<String>(
            future: _configService.getLastCheckedTime(),
            builder: (context, lastCheckedSnapshot) {
              final lastChecked = lastCheckedSnapshot.data ?? 'Never Checked';
              
              return Padding(
                padding: const EdgeInsets.only(top: CRMSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAboutRow('App Version', version),
                    const Divider(height: CRMSpacing.m),
                    _buildAboutRow('Build Number', buildNumber),
                    const Divider(height: CRMSpacing.m),
                    _buildAboutRow('Last Checked', lastChecked),
                    const SizedBox(height: CRMSpacing.l),
                    CRMButton(
                      label: 'Check for Updates',
                      onPressed: () => _checkForUpdates(context),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAboutRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: CRMTypography.bodyMedium.copyWith(
            color: CRMColors.textOf(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: CRMTypography.body.copyWith(
            color: CRMColors.textSecondaryOf(context),
          ),
        ),
      ],
    );
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    try {
      final config = await _configService.fetchAppConfig();
      if (mounted) {
        setState(() {}); // refresh "Last Checked"
        
        if (config.versionStatus == "forceUpdate" || config.versionStatus == "softUpdate") {
          showDialog(
            context: context,
            builder: (dialogContext) => UpdateDialog(
              isForceUpdate: config.versionStatus == "forceUpdate",
              androidLink: config.androidLink,
              iosLink: config.iosLink,
              onDismiss: () => Navigator.pop(dialogContext),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your application is up to date.'),
              backgroundColor: CRMColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check for updates: $e'),
            backgroundColor: CRMColors.danger,
          ),
        );
      }
    }
  }

  Widget _buildAuditLogsCard() {
    return CRMCard(
      title: 'Audit Logs',
      subtitle: 'View system audit activity logs and database change records',
      child: Padding(
        padding: const EdgeInsets.only(top: CRMSpacing.xs),
        child: ListTile(
          title: Text(
            'System Activity Audit Logs',
            style: CRMTypography.bodyMedium.copyWith(
              color: CRMColors.textOf(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            'Trace user operations, entity mutations, and operational histories',
            style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
          ),
          leading: CircleAvatar(
            backgroundColor: CRMColors.primary.withOpacity(0.1),
            radius: 18,
            child: Icon(Icons.history_rounded, color: CRMColors.primary, size: 20),
          ),
          trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: CRMColors.textSecondaryOf(context)),
          contentPadding: EdgeInsets.zero,
          onTap: () {
            context.go('/settings/audit-logs');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    final authState = context.watch<AuthBloc>().state;
    String currentUserName = 'Guest';
    String currentUserEmail = '';
    bool isAdminOrSuperAdmin = false;

    if (authState is Authenticated) {
      currentUserEmail = authState.user.email;
      final roleLower = authState.user.role.toLowerCase();
      isAdminOrSuperAdmin = roleLower.contains('admin');
      currentUserName = authState.user.fullName;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(CRMSpacing.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('System Configuration', style: CRMTypography.body.copyWith(color: CRMColors.textSecondary)),
                  Text(
                    'Settings & Profile',
                    style: CRMTypography.pageTitle.copyWith(
                      color: CRMColors.text,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: CRMSpacing.l),
                  if (isMobile) ...[
                    _buildProfileCard(currentUserName, currentUserEmail),
                    const SizedBox(height: CRMSpacing.l),
                    _buildAppearanceCard(isAdminOrSuperAdmin),
                    const SizedBox(height: CRMSpacing.l),
                    if (isAdminOrSuperAdmin) ...[
                      _buildAuditLogsCard(),
                      const SizedBox(height: CRMSpacing.l),
                    ],
                    _buildAboutCard(),
                    const SizedBox(height: CRMSpacing.l),
                    _buildCityCard(),
                    const SizedBox(height: CRMSpacing.l),
                    _buildAreaCard(),
                  ] else ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildProfileCard(currentUserName, currentUserEmail),
                              const SizedBox(height: CRMSpacing.l),
                              _buildAppearanceCard(isAdminOrSuperAdmin),
                              const SizedBox(height: CRMSpacing.l),
                              if (isAdminOrSuperAdmin) ...[
                                _buildAuditLogsCard(),
                                const SizedBox(height: CRMSpacing.l),
                              ],
                              _buildAboutCard(),
                            ],
                          ),
                        ),
                        const SizedBox(width: CRMSpacing.l),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildCityCard(),
                              const SizedBox(height: CRMSpacing.l),
                              _buildAreaCard(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildCityCard() {
    return CRMCard(
      title: 'City Configs',
      subtitle: 'Manage system-wide active cities',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cityController,
                  style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
                  decoration: InputDecoration(
                    labelText: 'New City Name',
                    filled: true,
                    fillColor: CRMColors.backgroundOf(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                      borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.6)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                      borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.6)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                      borderSide: BorderSide(color: CRMColors.primaryOf(context), width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
              CRMButton(
                label: 'Add',
                onPressed: _addCity,
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          SizedBox(
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                color: CRMColors.backgroundOf(context),
                border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.6)),
                borderRadius: BorderRadius.circular(CRMBorderRadius.m),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                itemCount: _cities.length,
                separatorBuilder: (_, __) => Divider(color: CRMColors.borderOf(context).withOpacity(0.5), height: 1),
                itemBuilder: (context, index) {
                  final city = _cities[index];
                  return ListTile(
                    title: Text(city.name, style: TextStyle(color: CRMColors.textOf(context))),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline_rounded, color: CRMColors.danger, size: 18),
                      tooltip: 'Delete City',
                      onPressed: () => _deleteCity(city.id),
                    ),
                    dense: true,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaCard() {
    final filtered = _areas.where((a) => a.cityId == _selectedCityForArea).toList();

    return CRMCard(
      title: 'Area Mapping Configs',
      subtitle: 'Map micro-markets and local communities to cities',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedCityForArea,
            dropdownColor: CRMColors.cardBgOf(context),
            style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
            decoration: InputDecoration(
              labelText: 'Select City',
              filled: true,
              fillColor: CRMColors.backgroundOf(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.6)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                borderSide: BorderSide(color: CRMColors.primaryOf(context), width: 1.5),
              ),
            ),
            items: _cities.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
            onChanged: (v) => setState(() => _selectedCityForArea = v),
          ),
          const SizedBox(height: CRMSpacing.s),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _areaNameController,
                  style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
                  decoration: InputDecoration(
                    labelText: 'New Area Name',
                    filled: true,
                    fillColor: CRMColors.backgroundOf(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                      borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.6)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                      borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.6)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                      borderSide: BorderSide(color: CRMColors.primaryOf(context), width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
              Expanded(
                child: TextField(
                  controller: _pincodeController,
                  style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
                  decoration: InputDecoration(
                    labelText: 'Pincode',
                    filled: true,
                    fillColor: CRMColors.backgroundOf(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                      borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.6)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                      borderSide: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.6)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                      borderSide: BorderSide(color: CRMColors.primaryOf(context), width: 1.5),
                    ),
                    suffixIcon: _isFetchingPincode
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
              CRMButton(
                label: 'Add',
                onPressed: _addArea,
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          SizedBox(
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                color: CRMColors.backgroundOf(context),
                border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.6)),
                borderRadius: BorderRadius.circular(CRMBorderRadius.m),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Divider(color: CRMColors.borderOf(context).withOpacity(0.5), height: 1),
                itemBuilder: (context, index) {
                  final area = filtered[index];
                  return ListTile(
                    title: Text(area.name, style: TextStyle(color: CRMColors.textOf(context))),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(area.pincode, style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded, color: CRMColors.danger, size: 18),
                          tooltip: 'Delete Area',
                          onPressed: () => _deleteArea(area.id),
                        ),
                      ],
                    ),
                    dense: true,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    ThemeManager().removeListener(_onThemeChanged);
    _cityController.dispose();
    _areaNameController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }
}
