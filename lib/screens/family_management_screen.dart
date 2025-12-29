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
    _loadCurrentUser();
    _loadData();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading family data: $e')),
        );
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
    // For Self profile, user is always the owner
    // For other profiles, check if creator_id matches or if not shared
    final isOwner = isSelf || (!profile.isShared) || (profile.creatorId == _currentUserId);
    final canEdit = isOwner && !isSelf;
    final canDelete = isOwner && !isSelf;
    final canShare = isOwner && !isSelf;
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Shared',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
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
    final firstNameController = TextEditingController(text: profile?.firstName);
    final lastNameController = TextEditingController(text: profile?.lastName);
    final relationController = TextEditingController(text: profile?.relationship);
    final dobController = TextEditingController(text: profile?.dateOfBirth);
    String gender = profile?.gender ?? 'Male';

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
                    color: _isDarkMode ? Colors.white : const Color(0xFF1E293B)
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fill in the details for your family member.',
                  style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 24),
                _buildModernTextField(
                  controller: firstNameController,
                  label: 'First Name',
                  icon: LucideIcons.user,
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: lastNameController,
                  label: 'Last Name',
                  icon: LucideIcons.user,
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: relationController,
                  label: 'Relationship',
                  hint: 'e.g., Son, Father, Spouse',
                  icon: LucideIcons.users,
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: dobController,
                  label: 'Date of Birth',
                  hint: 'YYYY-MM-DD',
                  icon: LucideIcons.calendar,
                  readOnly: true,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: Colors.blue,
                            onPrimary: Colors.white,
                            onSurface: _isDarkMode ? Colors.white : Colors.black,
                            surface: _isDarkMode ? const Color(0xFF132F4C) : Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setModalState(() {
                        dobController.text = picked.toString().split(' ')[0];
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
                 Text(
                  'Gender',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16, 
                    color: _isDarkMode ? Colors.white : const Color(0xFF1E293B)
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildGenderRadio('Male', gender, (v) => setModalState(() => gender = v)),
                    const SizedBox(width: 24),
                    _buildGenderRadio('Female', gender, (v) => setModalState(() => gender = v)),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (firstNameController.text.isEmpty || relationController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill in required fields')),
                        );
                        return;
                      }

                      final newProfile = UserProfile(
                        id: profile?.id ?? 0,
                        firstName: firstNameController.text,
                        lastName: lastNameController.text,
                        relationship: relationController.text,
                        dateOfBirth: dobController.text,
                        gender: gender,
                      );

                      try {
                        if (isEdit) {
                          await ProfileService.updateProfile(profile!.id, newProfile);
                        } else {
                          await ProfileService.createProfile(newProfile);
                        }
                        Navigator.pop(context);
                        _loadData();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF39A4E6),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isEdit ? LucideIcons.save : LucideIcons.plus,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isEdit ? 'Update Profile' : 'Create Profile',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14, 
            fontWeight: FontWeight.w600, 
            color: _isDarkMode ? Colors.grey[400] : const Color(0xFF64748B)
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: _isDarkMode ? Colors.grey[600] : Colors.grey[400]),
            prefixIcon: Icon(icon, color: const Color(0xFF39A4E6), size: 20),
            filled: true,
            fillColor: _isDarkMode ? const Color(0xFF0A1929) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _isDarkMode ? const Color(0xFF1E4976) : const Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderRadio(String value, String groupValue, Function(String) onChanged) {
    bool isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : (_isDarkMode ? const Color(0xFF1E4976) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? Colors.blue : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : (_isDarkMode ? Colors.grey[300] : const Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddConnectionDialog() {
    final emailController = TextEditingController();
    final relationController = TextEditingController();
    String accessLevel = 'view';

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Share Health Access', 
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold, 
                    color: _isDarkMode ? Colors.white : const Color(0xFF1E293B)
                  )
                ),
                const SizedBox(height: 8),
                Text(
                  'Send a request to link with another user account.',
                  style: TextStyle(color: _isDarkMode ? Colors.grey[400] : const Color(0xFF64748B), fontSize: 14),
                ),
                const SizedBox(height: 24),
                _buildModernTextField(
                  controller: emailController,
                  label: 'User Email',
                  hint: 'example@email.com',
                  icon: LucideIcons.mail,
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: relationController,
                  label: 'Relationship',
                  hint: 'e.g., Doctor, Daughter, Caretaker',
                  icon: LucideIcons.users,
                ),
                const SizedBox(height: 24),
                Text(
                  'Access Level',
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16, 
                    color: _isDarkMode ? Colors.white : const Color(0xFF1E293B)
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? const Color(0xFF0A1929) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _isDarkMode ? const Color(0xFF1E4976) : const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: accessLevel,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.blue),
                      items: const [
                        DropdownMenuItem(value: 'view', child: Text('View Only')),
                        DropdownMenuItem(value: 'manage', child: Text('View & Upload')),
                      ],
                      dropdownColor: _isDarkMode ? const Color(0xFF132F4C) : Colors.white,
                      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                      onChanged: (v) => setModalState(() => accessLevel = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (emailController.text.isEmpty || relationController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill in all fields')),
                        );
                        return;
                      }
                      try {
                        await ConnectionService.sendRequest(
                          receiverEmail: emailController.text,
                          relationship: relationController.text,
                          accessLevel: accessLevel,
                        );
                        Navigator.pop(context);
                        _loadData();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent successfully!')));
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Send Connection Request',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _respondToConnection(int id, String action) async {
    try {
      await ConnectionService.respondToRequest(id, action);
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showShareProfileDialog(UserProfile profile) {
    final emailController = TextEditingController();
    String accessLevel = 'upload';

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Share Profile Access',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Share ${profile.fullName}\'s profile with another user.',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.grey[400] : const Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                _buildModernTextField(
                  controller: emailController,
                  label: 'User Email',
                  hint: 'example@email.com',
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 24),
                Text(
                  'Access Level',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: _isDarkMode ? const Color(0xFF0A1929) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isDarkMode ? const Color(0xFF1E4976) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: accessLevel,
                      isExpanded: true,
                      icon: const Icon(LucideIcons.chevronDown, color: Color(0xFF39A4E6)),
                      items: const [
                        DropdownMenuItem(value: 'view', child: Text('View Only')),
                        DropdownMenuItem(value: 'upload', child: Text('View & Upload')),
                        DropdownMenuItem(value: 'manage', child: Text('View, Upload & Manage')),
                      ],
                      dropdownColor: _isDarkMode ? const Color(0xFF132F4C) : Colors.white,
                      style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
                      onChanged: (v) => setModalState(() => accessLevel = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (emailController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter an email address')),
                        );
                        return;
                      }
                      try {
                        await ProfileService.shareProfile(
                          profileId: profile.id,
                          email: emailController.text.trim(),
                          accessLevel: accessLevel,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile shared successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Share Profile',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTransferOwnershipDialog(UserProfile profile) {
    final emailController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Transfer Ownership',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Transfer ownership of ${profile.fullName}\'s profile to another user. You will retain manage access.',
                style: TextStyle(
                  color: _isDarkMode ? Colors.grey[400] : const Color(0xFF64748B),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              _buildModernTextField(
                controller: emailController,
                label: 'New Owner Email',
                hint: 'example@email.com',
                icon: LucideIcons.mail,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (emailController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter an email address')),
                      );
                      return;
                    }
                    try {
                      await ProfileService.transferOwnership(
                        profileId: profile.id,
                        email: emailController.text.trim(),
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ownership transferred successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadData(); // Reload to refresh the list
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Transfer Ownership',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteProfile(UserProfile profile) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF132F4C) : Colors.white,
        title: Text('Delete Profile?', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
        content: Text(
          'Are you sure you want to delete ${profile.fullName}? All linked reports will remain but will lose the profile link.',
          style: TextStyle(color: _isDarkMode ? Colors.grey[300] : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ProfileService.deleteProfile(profile.id);
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
