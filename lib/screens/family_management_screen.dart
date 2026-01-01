import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/theme_toggle.dart';
import '../models/profile_model.dart';
import '../models/connection_model.dart';
import '../services/profile_service.dart';
import '../services/connection_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../models/profile_model.dart';
import '../widgets/access_verification_modal.dart';
import '../services/profile_state_service.dart';

class FamilyManagementScreen extends StatefulWidget {
  const FamilyManagementScreen({super.key});

  @override
  State<FamilyManagementScreen> createState() => _FamilyManagementScreenState();
}

class _FamilyManagementScreenState extends State<FamilyManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserProfile> _profiles = [];
  List<FamilyConnection> _sentConnections = [];
  List<FamilyConnection> _receivedConnections = [];
  bool _isLoading = true;
  User? _currentUser;
  int? _currentUserId; // Store current user ID for ownership checks
  
  bool get _isDarkMode {
    final themeProvider = ThemeProvider.of(context);
    return themeProvider?.themeMode == ThemeMode.dark;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // specificially to update FAB
      }
    });
    _loadCurrentUser();
    _loadData(); // Ensure connection data is loaded initially
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await UserService().getUserProfile();
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    } catch (e) {
      // Try loading from prefs
      final user = await User.loadFromPrefs();
      if (mounted && user != null) {
        setState(() {
          _currentUser = user;
        });
      }
    }
    
    // Get current user ID from the self profile
    try {
      final profiles = await ProfileService.getProfiles();
      final selfProfile = profiles.firstWhere(
        (p) => p.relationship == 'Self',
        orElse: () => profiles.first,
      );
      if (mounted) {
        setState(() {
          _currentUserId = selfProfile.creatorId ?? selfProfile.id;
        });
      }
    } catch (e) {
      debugPrint('Error getting current user ID: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final profiles = await ProfileService.getProfiles();
      final connections = await ConnectionService.getConnections();
      setState(() {
        _profiles = profiles;
        _sentConnections = connections['sent']!;
        _receivedConnections = connections['received']!;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showToast('Error loading family data: $e', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A1929) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0A1929) : Colors.white,
        leading: IconButton(
          icon: Icon(
            LucideIcons.arrowLeft,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Family & Shared Access',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF132F4C) : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF39A4E6),
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
              tabs: const [
                Tab(text: 'Profiles'),
                Tab(text: 'Connections'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: const Color(0xFF39A4E6),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProfilesTab(),
                _buildConnectionsTab(),
              ],
            ),
      floatingActionButton: _buildFloatingActionButton(isDark),
    );
  }

  Widget _buildFloatingActionButton(bool isDark) {
    return FloatingActionButton.extended(
      onPressed: _tabController.index == 0 ? _showAddProfileDialog : _showAddConnectionDialog,
      backgroundColor: const Color(0xFF39A4E6),
      elevation: 4,
      icon: const Icon(LucideIcons.plus, color: Colors.white, size: 20),
      label: Text(
        _tabController.index == 0 ? 'Add Member' : 'Share Access',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildProfilesTab() {
    final isDark = _isDarkMode;
    
    if (_profiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.users,
              size: 80,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              'No profiles yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add family members to get started',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Separate profiles into owned and shared
    // Self profile is always owned, others check creator_id or isShared flag
    final ownedProfiles = _profiles.where((p) {
      if (p.relationship == 'Self') return true;
      if (!p.isShared) return true;
      return p.creatorId == _currentUserId;
    }).toList();
    final sharedProfiles = _profiles.where((p) {
      if (p.relationship == 'Self') return false;
      return p.isShared && p.creatorId != _currentUserId;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (ownedProfiles.isNotEmpty) ...[
          _buildSectionHeader('My Profiles', isDark),
          const SizedBox(height: 12),
          ...ownedProfiles.map((profile) => _buildProfileCard(profile, isDark, isOwned: true)),
          if (sharedProfiles.isNotEmpty) const SizedBox(height: 24),
        ],
        if (sharedProfiles.isNotEmpty) ...[
          _buildSectionHeader('Shared With Me', isDark),
          const SizedBox(height: 12),
          ...sharedProfiles.map((profile) => _buildProfileCard(profile, isDark, isOwned: false)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.grey[300] : Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildProfileCard(UserProfile profile, bool isDark, {required bool isOwned}) {
    final isSelf = profile.relationship == 'Self';
    
    // Explicit Permission Checks
    final bool isOwner = isSelf || profile.isOwner(_currentUserId); 
    final bool canManage = isSelf || profile.canManage;

    final canEdit = canManage;
    final canShare = canManage;
    final canDelete = isOwner && !isSelf;
    final canTransfer = isOwner && !isSelf;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132F4C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E4976) : Colors.grey.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Switch to this profile
            ProfileStateService().setSelectedProfile(profile);
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF39A4E6).withOpacity(0.2),
                        const Color(0xFF39A4E6).withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      profile.firstName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF39A4E6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Name and relationship
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            profile.fullName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          if (profile.isShared) ...[
                             const SizedBox(width: 8),
                             _buildAccessBadge(profile.accessLevel),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.user,
                            size: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            profile.relationship,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Actions
                if (isSelf)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.checkCircle,
                          size: 14,
                          color: isDark ? Colors.grey[300] : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Current',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[300] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  PopupMenuButton<String>(
                    icon: Icon(
                      LucideIcons.moreVertical,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: isDark ? const Color(0xFF132F4C) : Colors.white,
                    itemBuilder: (context) => [
                      if (canShare)
                        PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(LucideIcons.share2, size: 18, color: isDark ? Colors.white : Colors.black),
                              const SizedBox(width: 12),
                              const Text('Share Access'),
                            ],
                          ),
                        ),
                      if (canEdit)
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(LucideIcons.edit, size: 18, color: isDark ? Colors.white : Colors.black),
                              const SizedBox(width: 12),
                              const Text('Edit'),
                            ],
                          ),
                        ),
                      if (canTransfer)
                        PopupMenuItem(
                          value: 'transfer',
                          child: Row(
                            children: [
                              Icon(LucideIcons.refreshCw, size: 18, color: Colors.orange),
                              const SizedBox(width: 12),
                              const Text('Transfer Ownership'),
                            ],
                          ),
                        ),
                      if (canDelete)
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(LucideIcons.trash2, size: 18, color: Colors.red),
                              const SizedBox(width: 12),
                              const Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                    ],
                    onSelected: (value) {
                      switch (value) {
                        case 'share':
                          _showShareProfileDialog(profile);
                          break;
                        case 'edit':
                          _showEditProfileDialog(profile);
                          break;
                        case 'transfer':
                          _showTransferOwnershipDialog(profile);
                          break;
                        case 'delete':
                          _confirmDeleteProfile(profile);
                          break;
                      }
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildAccessBadge(String? accessLevel) {
    String label = 'Shared';
    Color color = Colors.orange;

    if (accessLevel == 'manage') {
      label = 'Manager';
      color = Colors.blue;
    } else if (accessLevel == 'upload') {
      label = 'Contributor';
      color = Colors.green;
    } else if (accessLevel == 'view') {
      label = 'Viewer';
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildConnectionsTab() {
    final isDark = _isDarkMode;
    
    if (_sentConnections.isEmpty && _receivedConnections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.userPlus,
              size: 80,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              'No connections yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share access with family members or doctors',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_receivedConnections.isNotEmpty) ...[
          _buildSectionHeader('Received Requests', isDark),
          const SizedBox(height: 12),
          ..._receivedConnections.map((conn) => _buildConnectionCard(conn, isReceived: true)),
          if (_sentConnections.isNotEmpty) const SizedBox(height: 24),
        ],
        if (_sentConnections.isNotEmpty) ...[
          _buildSectionHeader('Sent Requests', isDark),
          const SizedBox(height: 12),
          ..._sentConnections.map((conn) => _buildConnectionCard(conn, isReceived: false)),
        ],
      ],
    );
  }

  Widget _buildConnectionCard(FamilyConnection conn, {required bool isReceived}) {
    final isDark = _isDarkMode;
    final email = isReceived ? (conn.fromEmail ?? 'Unknown') : (conn.toEmail ?? 'Unknown');
    final status = conn.status;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132F4C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E4976) : Colors.grey.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.withOpacity(0.2),
                        Colors.orange.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Icon(
                    LucideIcons.userPlus,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        email,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.user,
                            size: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            conn.relationship,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            LucideIcons.shield,
                            size: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            conn.accessLevel ?? 'view',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            if (isReceived && status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _respondToConnection(conn.id, 'reject'),
                      icon: Icon(LucideIcons.x, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _respondToConnection(conn.id, 'accept'),
                      icon: Icon(LucideIcons.check, size: 16),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF39A4E6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1, end: 0);
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;
    switch (status) {
      case 'accepted':
        color = Colors.green;
        icon = LucideIcons.checkCircle;
        break;
      case 'rejected':
        color = Colors.red;
        icon = LucideIcons.xCircle;
        break;
      default:
        color = Colors.orange;
        icon = LucideIcons.clock;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddProfileDialog() {
    _showProfileDialog();
  }

  void _showEditProfileDialog(UserProfile profile) {
    _showProfileDialog(profile: profile);
  }

  void _showProfileDialog({UserProfile? profile}) {
    final isEdit = profile != null;
    final formKey = GlobalKey<FormState>();
    
    final firstNameController = TextEditingController(text: profile?.firstName);
    final lastNameController = TextEditingController(text: profile?.lastName);
    
    // Default values
    String? gender = profile?.gender;
    if (gender == null || gender.isEmpty) gender = 'Male';

    String? relationship = profile?.relationship;
    
    // For DOB, keep it as a controller for the text field, but manage DateTime separately if needed
    final dobController = TextEditingController(text: profile?.dateOfBirth);

    final familyRoles = ['Son', 'Daughter', 'Spouse', 'Father', 'Mother', 'Brother', 'Sister', 'Other'];
    final genderOptions = ['Male', 'Female', 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF132F4C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _isDarkMode ? Colors.grey[700] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isEdit ? 'Edit Profile' : 'Add Family Member',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEdit 
                      ? 'Update family member details'
                      : 'Create a profile for a family member (e.g., child or spouse) that you will manage.',
                    style: TextStyle(
                      fontSize: 14,
                      color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Name Fields
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: firstNameController,
                          label: 'First Name',
                          icon: LucideIcons.user,
                          isDark: _isDarkMode,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Required';
                            if (RegExp(r'[0-9!@#<>?":_`~;[\]\\|=+)(*&^%$\-]').hasMatch(value)) {
                              return 'Invalid characters';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: lastNameController,
                          label: 'Last Name',
                          isDark: _isDarkMode,
                          validator: (value) {
                             if (value == null || value.isEmpty) return 'Required';
                             return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Relationship Dropdown
                  DropdownButtonFormField<String>(
                    value: relationship,
                    decoration: InputDecoration(
                      labelText: 'Relationship',
                      labelStyle: TextStyle(
                        color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      prefixIcon: Icon(
                        LucideIcons.users,
                        color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        size: 20,
                      ),
                      filled: true,
                      fillColor: _isDarkMode ? const Color(0xFF0A1929) : Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                        ),
                      ),
                    ),
                    dropdownColor: _isDarkMode ? const Color(0xFF132F4C) : Colors.white,
                    style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                    items: familyRoles.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role),
                      );
                    }).toList(),
                    onChanged: (val) => setModalState(() => relationship = val),
                    validator: (val) => val == null ? 'Please select a relationship' : null,
                  ),
                  const SizedBox(height: 16),

                  // Gender & DOB Row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: gender,
                          decoration: InputDecoration(
                            labelText: 'Gender',
                            labelStyle: TextStyle(
                              color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                            filled: true,
                            fillColor: _isDarkMode ? const Color(0xFF0A1929) : Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                              ),
                            ),
                          ),
                          dropdownColor: _isDarkMode ? const Color(0xFF132F4C) : Colors.white,
                          style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                          items: genderOptions.map((g) {
                            return DropdownMenuItem(value: g, child: Text(g));
                          }).toList(),
                          onChanged: (val) => setModalState(() => gender = val),
                          validator: (val) => val == null ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: _isDarkMode 
                                      ? ThemeData.dark().copyWith(
                                          colorScheme: const ColorScheme.dark(
                                            primary: Color(0xFF39A4E6), 
                                            onPrimary: Colors.white, 
                                            surface: Color(0xFF132F4C), 
                                            onSurface: Colors.white, 
                                          ),
                                          dialogBackgroundColor: const Color(0xFF132F4C),
                                        )
                                      : ThemeData.light().copyWith(
                                          colorScheme: const ColorScheme.light(
                                            primary: Color(0xFF39A4E6),
                                          ),
                                        ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setModalState(() {
                                dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                              });
                            }
                          },
                          child: AbsorbPointer( 
                            child: _buildTextField(
                              controller: dobController,
                              label: 'Date of Birth',
                              icon: LucideIcons.calendar,
                              isDark: _isDarkMode,
                              validator: (val) => (val == null || val.isEmpty) ? 'Required' : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                         if (formKey.currentState!.validate()) {
                            Navigator.pop(context); // Close dialog
                            _saveProfile(
                              isEdit: isEdit,
                              profileId: profile?.id,
                              firstName: firstNameController.text,
                              lastName: lastNameController.text,
                              relationship: relationship!,
                              gender: gender!,
                              dob: dobController.text,
                            );
                         }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF39A4E6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isEdit ? 'Save Changes' : 'Create & Verify',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool isObscure = false,
    required bool isDark,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      validator: validator,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        prefixIcon: icon != null 
            ? Icon(icon, color: isDark ? Colors.grey[400] : Colors.grey[600], size: 20) 
            : null,
        filled: true,
        fillColor: isDark ? const Color(0xFF0A1929) : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF39A4E6), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
    );
  }

  Future<void> _saveProfile({
    required bool isEdit,
    int? profileId,
    required String firstName,
    required String lastName,
    required String relationship,
    required String gender,
    required String dob,
  }) async {
    setState(() => _isLoading = true);
    
    try {
      final profile = UserProfile(
        id: profileId ?? 0,
        firstName: firstName,
        lastName: lastName,
        relationship: relationship,
        dateOfBirth: dob,
        gender: gender,
        isShared: false,
        accessLevel: 'manage', 
      );

      if (isEdit) {
        await ProfileService.updateProfile(profileId!, profile);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully')),
           );
        }
      } else {
        final newProfileId = await ProfileService.createProfile(profile);
        
        // Success! Now trigger verification immediately for the newly created profile
        if (mounted) {
           setState(() => _isLoading = false); // Stop loading to show modal
           await _confirmAndVerifyProfile(newProfileId);
        }
        return; 
      }

      _loadData(); // Reload list
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    }
  }

  Future<void> _confirmAndVerifyProfile(int profileId) async {
      try {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black87, 
          builder: (context) => AccessVerificationModal(
              resourceType: 'profile',
              resourceId: profileId,
              isFirstTimeSetup: true,
          ),
        );
        
        // After flow completes (whether verified or cancelled)
        if (mounted) {
           _showToast('Family member added successfully. Please verify their account.');
           _loadData();
        }
      } catch (e) {
         _loadData();
      }
  }

  void _showAddConnectionDialog() {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? selectedRelationship;
    // Filter profiles to show ones this user owns (creator) OR has manage access to
    final availableProfiles = _profiles.where((p) {
      return p.relationship == 'Self' || p.isOwner(_currentUserId) || p.canManage;
    }).toList();
    int? selectedProfileId = availableProfiles.isNotEmpty ? availableProfiles.first.id : null;
    
    final relationshipOptions = ['Doctor', 'Spouse', 'Father', 'Mother', 'Son', 'Daughter', 'Brother', 'Sister', 'Caregiver', 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF132F4C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
               mainAxisSize: MainAxisSize.min,
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                  Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _isDarkMode ? Colors.grey[700] : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Share Access',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : Colors.black
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Invite a family member or doctor by email.', 
                    style: TextStyle(color: Colors.grey)
                  ),
                  const SizedBox(height: 24),
                  
                  // Profile Selector
                  if (availableProfiles.isNotEmpty) ...[
                    DropdownButtonFormField<int>(
                      value: selectedProfileId,
                      decoration: InputDecoration(
                        labelText: 'Share Record For',
                        labelStyle: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                        prefixIcon: Icon(LucideIcons.userCircle, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], size: 20),
                        filled: true,
                        fillColor: _isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF39A4E6))),
                      ),
                      dropdownColor: _isDarkMode ? const Color(0xFF132F4C) : Colors.white,
                      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black, fontSize: 16),
                      icon: Icon(LucideIcons.chevronDown, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], size: 20),
                      items: availableProfiles.map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.fullName),
                      )).toList(),
                      onChanged: (val) => setModalState(() => selectedProfileId = val),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email Field
                  _buildTextField(
                    controller: emailController, 
                    label: 'Email Address', 
                    icon: LucideIcons.mail, 
                    isDark: _isDarkMode,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Email is required';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Enter a valid email';
                      return null;
                    }
                  ),
                  const SizedBox(height: 16),
                  
                  // Relationship Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedRelationship,
                    decoration: InputDecoration(
                      labelText: 'Relationship (User to Profile)',
                      labelStyle: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                      prefixIcon: Icon(LucideIcons.users, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], size: 20),
                      filled: true,
                      fillColor: _isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF39A4E6))),
                      errorStyle: const TextStyle(color: Colors.redAccent),
                    ),
                    dropdownColor: _isDarkMode ? const Color(0xFF132F4C) : Colors.white,
                    style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black, fontSize: 16),
                    icon: Icon(LucideIcons.chevronDown, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], size: 20),
                    items: relationshipOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) => setModalState(() => selectedRelationship = newValue),
                    validator: (value) => value == null ? 'Please select a relationship' : null,
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                         if (formKey.currentState!.validate()) {
                           Navigator.pop(context);
                           if (selectedProfileId != null) {
                             // Use profile sharing logic
                             _shareProfile(selectedProfileId!, emailController.text);
                           } else {
                             // Fallback to generic connection
                             _sendConnectionRequest(emailController.text, selectedRelationship!);
                           }
                         }
                      },
                      style: ElevatedButton.styleFrom(
                         backgroundColor: const Color(0xFF39A4E6),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Send Invite', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
               ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendConnectionRequest(String email, String relationship) async {
     setState(() => _isLoading = true);
     try {
       await ConnectionService.sendRequest(
          receiverEmail: email, 
          relationship: relationship,
          accessLevel: 'view', 
       );
       if (mounted) {
         _showToast('Request sent to $email');
       }
       _loadData();
     } catch (e) {
       setState(() => _isLoading = false);
       if (mounted) {
         _showToast('Error: $e', isError: true);
       }
     }
  }

  Future<void> _respondToConnection(int connectionId, String action) async {
    setState(() => _isLoading = true);
    try {
      await ConnectionService.respondToRequest(connectionId, action);
      if (mounted) {
        _showToast('Request ${action}ed');
      }
      _loadData();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showToast('Error: $e', isError: true);
      }
    }
  }

  void _showShareProfileDialog(UserProfile profile) {
     final emailController = TextEditingController();
     
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         backgroundColor: _isDarkMode ? const Color(0xFF132F4C) : Colors.white,
         title: Text('Share ${profile.firstName}\'s Profile', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             Text('Allow another user (e.g. spouse) to view/manage this profile.', style: TextStyle(color: Colors.grey)),
             const SizedBox(height: 16),
             _buildTextField(controller: emailController, label: 'User Email', icon: LucideIcons.mail, isDark: _isDarkMode),
           ],
         ),
         actions: [
           TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
           TextButton(
             child: const Text('Share'),
             onPressed: () {
               Navigator.pop(context);
               _shareProfile(profile.id, emailController.text);
             },
           ),
         ],
       ),
     );
  }

  Future<void> _shareProfile(int profileId, String email) async {
     setState(() => _isLoading = true);
     try {
       await ProfileService.shareProfile(
         profileId: profileId,
         email: email,
         accessLevel: 'manage', 
       );
       if (mounted) {
          _showToast('Shared profile with $email');
       }
       _loadData();
     } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) _showToast('Error: $e', isError: true);
     }
  } 

  void _showTransferOwnershipDialog(UserProfile profile) {
     final emailController = TextEditingController();
     
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         backgroundColor: _isDarkMode ? const Color(0xFF132F4C) : Colors.white,
         title: Text('Transfer Ownership', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
              const Text('Transfer this profile to the child/person themselves. They must have an account.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Container(padding: const EdgeInsets.all(8), color: Colors.orange.withOpacity(0.1), 
                child: Row(children: [Icon(LucideIcons.alertTriangle, color: Colors.orange, size: 16), SizedBox(width:8), Expanded(child: Text('You will lose ownership but may retain shared access.', style: TextStyle(color: Colors.orange, fontSize: 12)))])
              ),
              const SizedBox(height: 16),
              _buildTextField(controller: emailController, label: 'Their Account Email', icon: LucideIcons.mail, isDark: _isDarkMode),
           ],
         ),
         actions: [
           TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
           ElevatedButton(
             style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
             child: const Text('Transfer', style: TextStyle(color: Colors.white)),
             onPressed: () async {
                Navigator.pop(context);
                try {
                   await ProfileService.transferOwnership(profileId: profile.id, email: emailController.text);
                   _loadData();
                   if (mounted) _showToast('Transfer request sent successfully');
                } catch(e) {
                   if (mounted) _showToast('Error: $e', isError: true);
                }
             },
           ),
         ],
       ),
     );
  }

  void _confirmDeleteProfile(UserProfile profile) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _isDarkMode ? const Color(0xFF132F4C) : Colors.white,
          title: Text('Delete Profile?', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
          content: Text('Are you sure you want to delete ${profile.fullName}? This cannot be undone.', style: TextStyle(color: _isDarkMode ? Colors.grey[300] : Colors.black87)),
          actions: [
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(context)),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.pop(context);
                try {
                   await ProfileService.deleteProfile(profile.id);
                   _loadData();
                   if (mounted) _showToast('Profile deleted successfully');
                } catch(e) {
                   if (mounted) _showToast('Error: $e', isError: true);
                }
              },
            ),
          ],
        ),
      );
  }
  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? LucideIcons.alertCircle : LucideIcons.checkCircle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
