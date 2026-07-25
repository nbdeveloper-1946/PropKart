import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/users_bloc.dart';
import '../models/user_model.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/tokens/app_shadows.dart';
import '../../../core/design_system/tokens/app_motion.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/data_table.dart';
import '../../../core/design_system/widgets/inputs.dart';
import '../../../core/design_system/widgets/dialogs.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/security/role_guard.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http_parser/http_parser.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedRoleId;
  String _selectedStatus = "All";
  
  List<dynamic> _passwordResets = [];
  bool _isLoadingResets = false;
  int _activeTabIndex = 0;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _triggerFetch();
    _fetchPasswordResets();
  }

  Future<void> _fetchPasswordResets() async {
    final authState = context.read<AuthBloc>().state;
    // Only fetch if authenticated and caller is Admin or Super Admin
    if (authState is Authenticated) {
      final roleName = authState.user.role;
      if (roleName != 'Admin' && roleName != 'Super Admin') {
        return;
      }
    } else {
      return;
    }

    setState(() {
      _isLoadingResets = true;
    });
    try {
      final response = await DioClient.dio.get('/users/password-resets');
      final data = response.data['data']['resets'] as List? ?? [];
      setState(() {
        _passwordResets = data;
        _isLoadingResets = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingResets = false;
      });
    }
  }

  void _triggerFetch() {
    context.read<UsersBloc>().add(
          FetchUsers(
            search: _searchController.text.trim(),
            roleId: _selectedRoleId,
            status: _selectedStatus,
          ),
        );
  }

  void _showAddEditUserDialog([UserModel? user]) {
    final isEditing = user != null;
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: user?.fullName);
    final emailController = TextEditingController(text: user?.email);
    final mobileController = TextEditingController(text: user?.mobile);
    final passwordController = TextEditingController();

    String? localSelectedRoleId = user?.roleId;
    bool obscurePassword = true;
    String? uploadedPhotoUrl = user?.profilePhoto;

    showDialog(
      context: context,
      builder: (dialogContext) {
        final authState = context.read<AuthBloc>().state;
        final callerRole = authState is Authenticated ? authState.user.role : '';

        final usersState = context.read<UsersBloc>().state;
        List<RoleModel> roles = [];
        if (usersState is UsersLoaded) {
          roles = usersState.roles;
          if (callerRole == 'Admin') {
            roles = roles.where((r) => r.name.toLowerCase() == 'sales').toList();
          } else if (callerRole == 'Super Admin') {
            roles = roles.where((r) => r.name.toLowerCase() != 'super admin').toList();
          }
        }

        if (localSelectedRoleId == null && roles.isNotEmpty) {
          localSelectedRoleId = roles.any((r) => r.id == user?.roleId)
              ? user?.roleId
              : roles.first.id;
        }

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: CRMColors.surfaceElevatedOf(context),
              elevation: 8,
              shadowColor: CRMColors.shadow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(CRMBorderRadius.dialog),
                side: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.5), width: 0.5),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: const EdgeInsets.all(CRMSpacing.l),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? "Edit User Account" : "Add User Account",
                            style: CRMTypography.sectionTitle.copyWith(color: CRMColors.text),
                          ),
                          const SizedBox(height: CRMSpacing.xs),
                          Text(
                            isEditing ? "Modify the system credentials and role permissions." : "Create new employee logins for the NB Realty system.",
                            style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                          ),
                          const SizedBox(height: CRMSpacing.l),

                          // Profile Photo Picker Avatar
                          Align(
                            alignment: Alignment.center,
                            child: Stack(
                              children: [
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: CRMColors.backgroundOf(context),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.6), width: 2),
                                    boxShadow: CRMShadows.soft,
                                  ),
                                  child: ClipOval(
                                    child: _isUploadingPhoto
                                        ? Center(
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(strokeWidth: 2.5, color: CRMColors.primary),
                                            ),
                                          )
                                        : (uploadedPhotoUrl != null && uploadedPhotoUrl!.isNotEmpty)
                                            ? Image.network(
                                                uploadedPhotoUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => Icon(
                                                  Icons.person_rounded,
                                                  size: 48,
                                                  color: CRMColors.textMuted,
                                                ),
                                              )
                                            : Icon(
                                                Icons.person_rounded,
                                                size: 48,
                                                color: CRMColors.textMuted,
                                              ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: _isUploadingPhoto ? null : () => _pickAndUploadPhoto(setState, (url) {
                                        setState(() {
                                          uploadedPhotoUrl = url;
                                        });
                                      }),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: CRMColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_rounded,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: CRMSpacing.m),
                          
                          // Full Name Input
                          CRMTextField(
                            controller: nameController,
                            labelText: 'Full Name *',
                            hintText: 'Enter complete name',
                            prefixIcon: Icons.person_rounded,
                            validator: (val) => val == null || val.trim().isEmpty ? "Full name required" : null,
                          ),
                          const SizedBox(height: CRMSpacing.m),

                          // Email Input
                          CRMTextField(
                            controller: emailController,
                            labelText: 'Email Address *',
                            hintText: 'user@nbrealty.com',
                            prefixIcon: Icons.email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) => val == null || val.trim().isEmpty ? "Email required" : null,
                          ),
                          const SizedBox(height: CRMSpacing.m),

                          // Mobile Phone
                          CRMTextField(
                            controller: mobileController,
                            labelText: 'Phone Number',
                            hintText: '+91 XXXXX XXXXX',
                            prefixIcon: Icons.phone_rounded,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: CRMSpacing.m),

                          // Password Input with Show/Hide Eye Toggle
                          CRMTextField(
                            controller: passwordController,
                            labelText: isEditing ? "New Password (Optional)" : "Password *",
                            hintText: 'Min 6 characters',
                            prefixIcon: Icons.lock_rounded,
                            obscureText: obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: CRMColors.textMuted,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                            ),
                            validator: (val) {
                              if (!isEditing && (val == null || val.isEmpty)) {
                                return "Password required";
                              }
                              if (val != null && val.isNotEmpty && val.length < 6) {
                                return "Password must be at least 6 characters";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: CRMSpacing.m),

                          // Role Selector
                          if (roles.isNotEmpty) ...[
                            Text(
                              'System Role *',
                              style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondary),
                            ),
                            const SizedBox(height: CRMSpacing.xs),
                            DropdownButtonFormField<String>(
                              value: localSelectedRoleId,
                              dropdownColor: CRMColors.cardBgOf(context),
                              style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.admin_panel_settings_rounded, color: CRMColors.textMutedOf(context)),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: CRMSpacing.m,
                                  vertical: CRMSpacing.s,
                                ),
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
                              items: roles.map((r) {
                                return DropdownMenuItem<String>(
                                  value: r.id,
                                  child: Text(r.name),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  localSelectedRoleId = val;
                                });
                              },
                            ),
                            const SizedBox(height: CRMSpacing.xl),
                          ],
                          
                          // Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              CRMButton(
                                label: 'Cancel',
                                variant: CRMButtonVariant.outline,
                                onPressed: () => Navigator.pop(dialogContext),
                              ),
                              const SizedBox(width: CRMSpacing.s),
                              CRMButton(
                                label: isEditing ? 'Save Changes' : 'Create Account',
                                onPressed: () {
                                  if (formKey.currentState?.validate() ?? false) {
                                    String? targetRole;
                                    for (final r in roles) {
                                      if (r.id == localSelectedRoleId) {
                                        targetRole = r.name;
                                        break;
                                      }
                                    }
                                    final denial = RoleGuard.validateUserMutation(
                                      callerRole: callerRole,
                                      targetRoleName: targetRole ?? user?.roleName,
                                      isDelete: false,
                                    );
                                    if (denial != null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(denial)),
                                      );
                                      return;
                                    }

                                    final userData = {
                                      'full_name': nameController.text.trim(),
                                      'email': emailController.text.trim(),
                                      'mobile': mobileController.text.trim(),
                                      'role_id': localSelectedRoleId,
                                      'profile_photo': uploadedPhotoUrl,
                                    };

                                    if (passwordController.text.isNotEmpty) {
                                      userData['password'] = passwordController.text;
                                    }

                                    if (isEditing) {
                                      context.read<UsersBloc>().add(
                                            UpdateUserRequested(id: user.id, userData: userData),
                                          );
                                    } else {
                                      context.read<UsersBloc>().add(
                                            CreateUserRequested(userData: userData),
                                          );
                                    }

                                    Navigator.pop(dialogContext);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmDialog(UserModel user) async {
    final authState = context.read<AuthBloc>().state;
    final callerRole = authState is Authenticated ? authState.user.role : '';
    final denial = RoleGuard.validateUserMutation(
      callerRole: callerRole,
      targetRoleName: user.roleName,
      isDelete: true,
    );
    if (denial != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(denial)));
      return;
    }

    final confirmed = await CRMDialogs.showDeleteConfirmation(
      context,
      title: "Confirm Deletion",
      content: "Are you sure you want to delete ${user.fullName}? This operation will perform a soft delete.",
    );
    if (confirmed == true && mounted) {
      context.read<UsersBloc>().add(DeleteUserRequested(id: user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;

    final authState = context.watch<AuthBloc>().state;
    bool hasAccess = false;
    if (authState is Authenticated) {
      hasAccess = authState.user.permissions.contains("users.read");
    }

    if (!hasAccess) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(CRMSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gpp_bad_rounded, color: CRMColors.danger, size: 72),
                const SizedBox(height: CRMSpacing.m),
                Text(
                  "403 - Forbidden",
                  style: CRMTypography.pageTitle.copyWith(color: CRMColors.text),
                ),
                const SizedBox(height: CRMSpacing.xs),
                Text(
                  "You do not have permission to view this page.",
                  style: CRMTypography.body.copyWith(color: CRMColors.textSecondary),
                ),
                const SizedBox(height: CRMSpacing.xl),
                CRMButton(
                  label: "Back to Dashboard",
                  onPressed: () => Navigator.maybePop(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocListener<UsersBloc, UsersState>(
        listener: (context, state) {
          if (state is UsersOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: CRMColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _triggerFetch();
          } else if (state is UsersError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error: ${state.message}"),
                backgroundColor: CRMColors.danger,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? CRMSpacing.m : CRMSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Row
              _buildPageHeader(),
              const SizedBox(height: CRMSpacing.l),

              // 2. Statistics Overview Cards
              _buildStatisticsRow(),
              const SizedBox(height: CRMSpacing.l),

              // Reset Requests Section (if any requests exist)
              _buildPasswordResetsSection(),
              if (_passwordResets.isNotEmpty) const SizedBox(height: CRMSpacing.l),

              // 3. Search and Filters Card
              _buildSearchAndFiltersCard(),
              const SizedBox(height: CRMSpacing.l),

              // TabBar for Super Admin
              if (authState is Authenticated && authState.user.role == 'Super Admin') ...[
                _buildTabBar(),
                const SizedBox(height: CRMSpacing.m),
              ],

              // 4. Employees Data Table
              _buildEmployeesTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 600;

    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "User Management",
          style: CRMTypography.pageTitle.copyWith(
            color: CRMColors.text,
            fontSize: isMobile ? 22 : 28,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          "Configure workspace permissions, logins, and enterprise roles",
          style: CRMTypography.body.copyWith(
            color: CRMColors.textSecondary,
            fontSize: isMobile ? 13 : 14,
          ),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          textColumn,
          const SizedBox(height: CRMSpacing.m),
          SizedBox(
            width: double.infinity,
            child: CRMButton(
              label: "Add Employee",
              prefixIcon: Icons.add_rounded,
              onPressed: () => _showAddEditUserDialog(),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: textColumn),
        const SizedBox(width: CRMSpacing.m),
        CRMButton(
          label: "Add Employee",
          prefixIcon: Icons.add_rounded,
          onPressed: () => _showAddEditUserDialog(),
        ),
      ],
    );
  }

  Widget _buildStatisticsRow() {
    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, state) {
        int total = 0;
        int active = 0;
        int admins = 0;

        if (state is UsersLoaded) {
          total = state.users.length;
          active = state.users.where((u) => u.isActive).length;
          admins = state.users.where((u) => u.roleName.toLowerCase() == 'admin').length;
        }

        final double screenWidth = MediaQuery.of(context).size.width;
        final int crossAxisCount = screenWidth >= 1000 ? 3 : 2;
        final double childAspectRatio = screenWidth >= 1000 ? 2.5 : 1.5;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: CRMSpacing.m,
          mainAxisSpacing: CRMSpacing.m,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: childAspectRatio,
          children: [
            CRMKPICard(
              title: "TOTAL EMPLOYEES",
              value: total.toString(),
              icon: Icons.people_rounded,
              iconColor: CRMColors.primary,
            ),
            CRMKPICard(
              title: "ACTIVE SYSTEM USERS",
              value: active.toString(),
              icon: Icons.check_circle_outline_rounded,
              iconColor: CRMColors.success,
            ),
            CRMKPICard(
              title: "ADMINISTRATORS",
              value: admins.toString(),
              icon: Icons.admin_panel_settings_rounded,
              iconColor: CRMColors.info,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchAndFiltersCard() {
    return CRMCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Search input
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
                  decoration: InputDecoration(
                    hintText: 'Search by employee name, email, phone number...',
                    hintStyle: CRMTypography.body.copyWith(color: CRMColors.textMutedOf(context)),
                    prefixIcon: Icon(Icons.search_rounded, color: CRMColors.textMutedOf(context)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: CRMColors.textMutedOf(context)),
                            onPressed: () {
                              _searchController.clear();
                              _triggerFetch();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: CRMColors.backgroundOf(context),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: CRMSpacing.m,
                      vertical: CRMSpacing.s,
                    ),
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
                  onChanged: (val) => _triggerFetch(),
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
              CRMButton(
                label: "Search",
                onPressed: _triggerFetch,
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          
          // Role & Status Dropdown Row
          BlocBuilder<UsersBloc, UsersState>(
            builder: (context, state) {
              List<RoleModel> roles = [];
              if (state is UsersLoaded) {
                roles = state.roles;
              }

              return Wrap(
                spacing: CRMSpacing.m,
                runSpacing: CRMSpacing.s,
                children: [
                  // Role Filter
                  _buildDropdown(
                    label: 'Filter by Role',
                    value: _selectedRoleId,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text("All Roles"),
                      ),
                      ...roles.map((r) => DropdownMenuItem<String?>(
                            value: r.id,
                            child: Text(r.name),
                          )),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedRoleId = val;
                      });
                      _triggerFetch();
                    },
                  ),
                  
                  // Status Filter
                  _buildDropdown(
                    label: 'Filter by Status',
                    value: _selectedStatus,
                    items: ["All", "Active", "Inactive"].map((status) {
                      return DropdownMenuItem<String>(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedStatus = val ?? "All";
                      });
                      _triggerFetch();
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      width: 200,
      height: 44,
      child: DropdownButtonFormField<T>(
        value: value,
        dropdownColor: CRMColors.cardBgOf(context),
        style: CRMTypography.body.copyWith(color: CRMColors.textOf(context)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: CRMSpacing.m,
            vertical: 4,
          ),
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
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildEmployeesTable() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 768;

    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, state) {
        final isLoading = state is UsersLoading || state is UsersInitial;
        List<UserModel> users = [];

        if (state is UsersLoaded) {
          users = state.users;
          final authState = context.read<AuthBloc>().state;
          final isSuperAdmin = authState is Authenticated && authState.user.role == 'Super Admin';
          if (isSuperAdmin) {
            final targetRole = _activeTabIndex == 0 ? 'Admin' : 'Sales';
            users = users.where((u) => u.roleName.toLowerCase() == targetRole.toLowerCase()).toList();
          }
        }

        if (isLoading) {
          return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
        }

        if (users.isEmpty) {
          return CRMCard(
            elevated: true,
            child: Padding(
              padding: const EdgeInsets.all(CRMSpacing.xl),
              child: Column(
                children: [
                  Text('No Employees Found', style: CRMTypography.sectionTitle.copyWith(color: CRMColors.textOf(context))),
                  const SizedBox(height: CRMSpacing.s),
                  Text('Try adjusting your filters or add a new employee profile.', style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context))),
                ],
              ),
            ),
          );
        }

        if (isMobile) {
          return Column(
            children: users.map((user) => _buildMobileUserCard(user)).toList(),
          );
        }

        return CRMDataTable(
          isLoading: isLoading,
          emptyTitle: 'No Employees Found',
          emptyDescription: 'Try adjusting your filters or add a new employee profile.',
          dataRowMinHeight: 52.0,
          dataRowMaxHeight: 60.0,
          columns: const [
            DataColumn(label: Text('Full Name')),
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('Email Address')),
            DataColumn(label: Text('Mobile')),
            DataColumn(label: Text('Active Logins')),
            DataColumn(label: Text('Actions')),
          ],
          rows: users.map((user) {
            final isAdmin = user.roleName.toLowerCase() == 'admin';

            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isAdmin
                            ? CRMColors.info.withOpacity(0.1)
                            : CRMColors.primary.withOpacity(0.1),
                        radius: 16,
                        child: Icon(
                          isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                          color: isAdmin ? CRMColors.info : CRMColors.primary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: CRMSpacing.s),
                      Text(
                        user.fullName,
                        style: CRMTypography.bodyMedium.copyWith(color: CRMColors.text),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.s, vertical: CRMSpacing.xxs),
                    decoration: BoxDecoration(
                      color: isAdmin ? CRMColors.info.withOpacity(0.12) : CRMColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(CRMBorderRadius.round),
                    ),
                    child: Text(
                      user.roleName,
                      style: CRMTypography.captionBold.copyWith(
                        color: isAdmin ? CRMColors.info : CRMColors.primary,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(user.email, style: CRMTypography.body.copyWith(color: CRMColors.textSecondary))),
                DataCell(Text(user.mobile ?? '-', style: CRMTypography.body.copyWith(color: CRMColors.textSecondary))),
                DataCell(
                  Switch(
                    value: user.isActive,
                    activeColor: CRMColors.primary,
                    onChanged: (val) {
                      context.read<UsersBloc>().add(
                            ToggleUserStatusRequested(id: user.id, isActive: val),
                          );
                    },
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isAdmin) ...[
                        IconButton(
                          icon: const Icon(Icons.analytics_outlined, color: CRMColors.warning, size: 18),
                          onPressed: () => _showAdminStatsDialog(user),
                        ),
                      ],
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: CRMColors.primary, size: 18),
                        onPressed: () => _showAddEditUserDialog(user),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline_rounded, color: CRMColors.danger, size: 18),
                        onPressed: () => _showDeleteConfirmDialog(user),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMobileUserCard(UserModel user) {
    final isAdmin = user.roleName.toLowerCase() == 'admin';

    return Container(
      margin: const EdgeInsets.only(bottom: CRMSpacing.s),
      padding: const EdgeInsets.all(CRMSpacing.m),
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
        border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.55), width: 0.5),
        boxShadow: CRMShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isAdmin
                    ? CRMColors.info.withOpacity(0.1)
                    : CRMColors.primary.withOpacity(0.1),
                radius: 18,
                child: Icon(
                  isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                  color: isAdmin ? CRMColors.info : CRMColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: CRMTypography.bodyMedium.copyWith(
                        color: CRMColors.textOf(context),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.s, vertical: CRMSpacing.xxs),
                decoration: BoxDecoration(
                  color: isAdmin ? CRMColors.info.withOpacity(0.12) : CRMColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(CRMBorderRadius.round),
                ),
                child: Text(
                  user.roleName,
                  style: CRMTypography.captionBold.copyWith(
                    color: isAdmin ? CRMColors.info : CRMColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          Divider(color: CRMColors.borderOf(context).withOpacity(0.5), height: 1),
          const SizedBox(height: CRMSpacing.s),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.phone_rounded, size: 16, color: CRMColors.textMutedOf(context)),
                  const SizedBox(width: 6),
                  Text(
                    user.mobile ?? '-',
                    style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context)),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'Active Login',
                    style: CRMTypography.body.copyWith(
                      color: CRMColors.textSecondaryOf(context),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: CRMSpacing.xs),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: user.isActive,
                      activeColor: CRMColors.primary,
                      onChanged: (val) {
                        context.read<UsersBloc>().add(
                              ToggleUserStatusRequested(id: user.id, isActive: val),
                            );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.s),
          Divider(color: CRMColors.borderOf(context).withOpacity(0.5), height: 1),
          const SizedBox(height: CRMSpacing.s),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isAdmin) ...[
                TextButton.icon(
                  onPressed: () => _showAdminStatsDialog(user),
                  icon: const Icon(Icons.analytics_outlined, color: CRMColors.warning, size: 16),
                  label: const Text(
                    'Stats',
                    style: TextStyle(color: CRMColors.warning),
                  ),
                ),
                const SizedBox(width: CRMSpacing.s),
              ],
              TextButton.icon(
                onPressed: () => _showAddEditUserDialog(user),
                icon: Icon(Icons.edit_outlined, color: CRMColors.primary, size: 16),
                label: Text(
                  'Edit',
                  style: TextStyle(color: CRMColors.primary),
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
              TextButton.icon(
                onPressed: () => _showDeleteConfirmDialog(user),
                icon: Icon(Icons.delete_outline_rounded, color: CRMColors.danger, size: 16),
                label: Text(
                  'Delete',
                  style: TextStyle(color: CRMColors.danger),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordResetsSection() {
    if (_passwordResets.isEmpty) return const SizedBox.shrink();

    return CRMCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.vpn_key_rounded, color: CRMColors.warning, size: 20),
              const SizedBox(width: 8),
              Text(
                "Pending Password Reset Requests (${_passwordResets.length})",
                style: CRMTypography.sectionTitle.copyWith(color: CRMColors.text, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _passwordResets.length,
            separatorBuilder: (context, index) => Divider(color: CRMColors.border.withOpacity(0.5)),
            itemBuilder: (context, index) {
              final r = _passwordResets[index];
              final userName = r['userName'] ?? '';
              final userEmail = r['userEmail'] ?? '';
              final roleName = r['roleName'] ?? '';
              final createdAtStr = r['createdAt'] ?? '';
              
              String timeDisplay = 'recently';
              try {
                final dt = DateTime.parse(createdAtStr);
                final diff = DateTime.now().difference(dt);
                if (diff.inMinutes < 60) {
                  timeDisplay = '${diff.inMinutes}m ago';
                } else if (diff.inHours < 24) {
                  timeDisplay = '${diff.inHours}h ago';
                } else {
                  timeDisplay = '${diff.inDays}d ago';
                }
              } catch (_) {}

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                userName,
                                style: CRMTypography.bodyMedium.copyWith(color: CRMColors.text, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: CRMColors.warning.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  roleName,
                                  style: CRMTypography.caption.copyWith(color: CRMColors.warning, fontWeight: FontWeight.bold, fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "$userEmail • Requested $timeDisplay",
                            style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    CRMButton(
                      label: "Reset Password",
                      variant: CRMButtonVariant.primary,
                      onPressed: () => _showResetPasswordDialog(r),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(dynamic request) {
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: CRMColors.surfaceElevatedOf(context),
              elevation: 8,
              shadowColor: CRMColors.shadow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(CRMBorderRadius.dialog),
                side: BorderSide(color: CRMColors.borderOf(context).withOpacity(0.5), width: 0.5),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Padding(
                  padding: const EdgeInsets.all(CRMSpacing.l),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Reset Password for ${request['userName']}",
                          style: CRMTypography.sectionTitle.copyWith(color: CRMColors.text),
                        ),
                        const SizedBox(height: CRMSpacing.xs),
                        Text(
                          "Enter a new password for ${request['userEmail']} (${request['roleName']}).",
                          style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                        ),
                        const SizedBox(height: CRMSpacing.l),
                        
                        CRMTextField(
                          controller: passwordController,
                          labelText: 'New Password *',
                          hintText: 'Min 6 characters',
                          prefixIcon: Icons.lock_rounded,
                          obscureText: obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: CRMColors.textMuted,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return "Password required";
                            }
                            if (val.length < 6) {
                              return "Password must be at least 6 characters";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: CRMSpacing.xl),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            CRMButton(
                              label: 'Cancel',
                              variant: CRMButtonVariant.outline,
                              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                            ),
                            const SizedBox(width: CRMSpacing.s),
                            CRMButton(
                              label: 'Save Password',
                              variant: CRMButtonVariant.primary,
                              isLoading: isSaving,
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      if (formKey.currentState?.validate() ?? false) {
                                        setState(() {
                                          isSaving = true;
                                        });
                                        try {
                                          final newPassword = passwordController.text;
                                          await DioClient.dio.post(
                                            '/users/password-resets/${request['id']}/resolve',
                                            data: {'newPassword': newPassword},
                                          );
                                          
                                          Navigator.pop(dialogContext);
                                          
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text("Password updated successfully."),
                                              backgroundColor: CRMColors.success,
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                          
                                          _fetchPasswordResets();
                                          _triggerFetch();
                                          
                                        } catch (e) {
                                          setState(() {
                                            isSaving = false;
                                          });
                                          String errorMsg = 'Failed to reset password. Please try again.';
                                          if (e is DioException) {
                                            errorMsg = e.response?.data['message'] ?? e.message ?? errorMsg;
                                          }
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text("Error: $errorMsg"),
                                              backgroundColor: CRMColors.danger,
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      }
                                    },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: CRMColors.cardBgOf(context),
          borderRadius: BorderRadius.circular(CRMBorderRadius.m),
          border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.5), width: 0.5),
          boxShadow: CRMShadows.soft,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTabItem(0, "Administrators", Icons.admin_panel_settings_rounded),
            const SizedBox(width: 4),
            _buildTabItem(1, "Sales Representatives", Icons.person_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    final isSelected = _activeTabIndex == index;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTabIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: CRMMotion.fast,
          curve: CRMMotion.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? CRMColors.primaryOf(context).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
            border: Border(
              bottom: BorderSide(
                color: isSelected ? CRMColors.primaryOf(context) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? CRMColors.primaryOf(context) : CRMColors.textSecondaryOf(context),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: CRMTypography.bodyMedium.copyWith(
                  color: isSelected ? CRMColors.primaryOf(context) : CRMColors.textSecondaryOf(context),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdminStatsDialog(UserModel user) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: CRMColors.surfaceElevatedOf(dialogContext),
          elevation: 8,
          shadowColor: CRMColors.shadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CRMBorderRadius.dialog),
            side: BorderSide(color: CRMColors.borderOf(dialogContext).withOpacity(0.5), width: 0.5),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: FutureBuilder<Response>(
              future: DioClient.dio.get('/users/admins/${user.id}/stats'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    height: 250,
                    child: Center(
                      child: CircularProgressIndicator(color: CRMColors.primary),
                    ),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData || snapshot.data?.data['success'] == false) {
                  return Padding(
                    padding: const EdgeInsets.all(CRMSpacing.l),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: CRMColors.danger, size: 48),
                        const SizedBox(height: CRMSpacing.m),
                        Text(
                          "Failed to load statistics.",
                          style: CRMTypography.sectionTitle.copyWith(color: CRMColors.text),
                        ),
                        const SizedBox(height: CRMSpacing.l),
                        CRMButton(
                          label: "Close",
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                  );
                }

                final stats = snapshot.data!.data['data'];
                final adminName = stats['adminName'] ?? user.fullName;
                final salesCreated = stats['salesCreated'] ?? 0;
                final activeSales = stats['activeSales'] ?? 0;
                final inactiveSales = stats['inactiveSales'] ?? 0;
                final propertiesAdded = stats['propertiesAdded'] ?? 0;
                final requirementsAdded = stats['requirementsAdded'] ?? 0;

                Widget buildStatCard(String title, String value, IconData icon, Color color) {
                  return Container(
                    padding: const EdgeInsets.all(CRMSpacing.m),
                    decoration: BoxDecoration(
                      color: CRMColors.backgroundOf(context),
                      borderRadius: BorderRadius.circular(CRMBorderRadius.m),
                      border: Border.all(color: CRMColors.borderOf(context).withOpacity(0.5), width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: CRMSpacing.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                value,
                                style: CRMTypography.sectionTitle.copyWith(color: CRMColors.text, fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(CRMSpacing.l),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: CRMColors.info,
                                radius: 20,
                                child: Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: CRMSpacing.m),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    adminName,
                                    style: CRMTypography.sectionTitle.copyWith(color: CRMColors.text),
                                  ),
                                  Text(
                                    "Administrator Profile & Metrics",
                                    style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, color: CRMColors.textMuted),
                            onPressed: () => Navigator.pop(dialogContext),
                          ),
                        ],
                      ),
                      const SizedBox(height: CRMSpacing.m),
                      Divider(color: CRMColors.borderOf(context).withOpacity(0.5)),
                      const SizedBox(height: CRMSpacing.m),
                      
                      // Contact info
                      Row(
                        children: [
                          Icon(Icons.mail_outline_rounded, size: 16, color: CRMColors.textSecondary),
                          const SizedBox(width: 8),
                          Text(user.email, style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondary)),
                        ],
                      ),
                      if (user.mobile != null && user.mobile!.isNotEmpty) ...[
                        const SizedBox(height: CRMSpacing.xs),
                        Row(
                          children: [
                            Icon(Icons.phone_outlined, size: 16, color: CRMColors.textSecondary),
                            const SizedBox(width: 8),
                            Text(user.mobile!, style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondary)),
                          ],
                        ),
                      ],
                      const SizedBox(height: CRMSpacing.l),

                      Text(
                        "TEAM STATISTICS",
                        style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondary, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: CRMSpacing.s),

                      // Metrics Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: CRMSpacing.s,
                        mainAxisSpacing: CRMSpacing.s,
                        childAspectRatio: 2.8,
                        children: [
                          buildStatCard("Sales Created", salesCreated.toString(), Icons.group_add_rounded, CRMColors.primary),
                          buildStatCard("Active Sales", activeSales.toString(), Icons.check_circle_outline_rounded, CRMColors.success),
                          buildStatCard("Inactive Sales", inactiveSales.toString(), Icons.cancel_outlined, CRMColors.danger),
                          buildStatCard("Properties", propertiesAdded.toString(), Icons.home_work_outlined, CRMColors.info),
                        ],
                      ),
                      const SizedBox(height: CRMSpacing.s),
                      buildStatCard("Requirements Added", requirementsAdded.toString(), Icons.assignment_outlined, CRMColors.warning),
                      
                      const SizedBox(height: CRMSpacing.xl),
                      Align(
                        alignment: Alignment.centerRight,
                        child: CRMButton(
                          label: "Dismiss",
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadPhoto(StateSetter dialogSetState, Function(String) onUploaded) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    dialogSetState(() {
      _isUploadingPhoto = true;
    });

    try {
      MultipartFile multipartFile;

      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        if (bytes.length > 2 * 1024 * 1024) {
          throw Exception("Image size must be less than 2 MB.");
        }
        multipartFile = MultipartFile.fromBytes(
          bytes,
          filename: pickedFile.name,
          contentType: MediaType('image', 'jpeg'),
        );
      } else {
        final File file = File(pickedFile.path);
        final int sizeInBytes = await file.length();
        
        File uploadFile = file;

        // Deterministic compression pipeline
        if (sizeInBytes > 0) {
          final String targetPath = "${Directory.systemTemp.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg";
          
          // Step 1: Compress with 80% quality and resize max 800x800 px
          XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
            file.absolute.path,
            targetPath,
            quality: 80,
            minWidth: 800,
            minHeight: 800,
          );

          if (compressedFile != null) {
            uploadFile = File(compressedFile.path);
            int compressedSize = await uploadFile.length();

            // Step 2: If size exceeds 500 KB limit, re-compress with 70% quality
            if (compressedSize > 500 * 1024) {
              final String secondPath = "${Directory.systemTemp.path}/compressed_70_${DateTime.now().millisecondsSinceEpoch}.jpg";
              final XFile? secondCompressed = await FlutterImageCompress.compressAndGetFile(
                file.absolute.path,
                secondPath,
                quality: 70,
                minWidth: 800,
                minHeight: 800,
              );
              if (secondCompressed != null) {
                uploadFile = File(secondCompressed.path);
                compressedSize = await uploadFile.length();
              }
            }

            // Step 3: Assert ultimate limit of 2 MB
            if (compressedSize > 2 * 1024 * 1024) {
              throw Exception("Compressed image size exceeds the required 2 MB limit.");
            }
          }
        }

        multipartFile = await MultipartFile.fromFile(
          uploadFile.path, 
          filename: 'profile_photo.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
      }

      final formData = FormData.fromMap({
        'file': multipartFile,
      });

      Response? response;
      int retries = 3;
      while (retries > 0) {
        try {
          response = await DioClient.dio.post('/users/upload-profile', data: formData);
          break;
        } catch (e) {
          retries--;
          if (retries == 0) rethrow;
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      if (response != null && response.data != null) {
        final publicUrl = response.data['data']['publicUrl'];
        onUploaded(publicUrl);
      }

    } catch (e) {
      String errorMsg = 'Failed to upload photo.';
      if (e is DioException) {
        errorMsg = e.response?.data['message'] ?? e.message ?? errorMsg;
      } else if (e is Exception) {
        errorMsg = e.toString().replaceAll("Exception: ", "");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: CRMColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      dialogSetState(() {
        _isUploadingPhoto = false;
      });
    }
  }
}
