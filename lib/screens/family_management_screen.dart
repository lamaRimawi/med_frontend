import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../models/connection_model.dart';
import '../services/profile_service.dart';
import '../services/connection_service.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Family & Shared Access',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'Profiles'),
            Tab(text: 'Connections'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProfilesTab(),
                _buildConnectionsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tabController.index == 0 ? _showAddProfileDialog : _showAddConnectionDialog,
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _tabController.index == 0 ? 'Add Member' : 'Share Access',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildProfilesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _profiles.length,
      itemBuilder: (context, index) {
        final profile = _profiles[index];
        final isSelf = profile.relationship == 'Self';

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.blue.withOpacity(0.1),
              child: Text(
                profile.firstName[0].toUpperCase(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
            title: Text(
              profile.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              profile.relationship,
              style: TextStyle(color: Colors.grey[600]),
            ),
            trailing: isSelf
                ? const Icon(Icons.person, color: Colors.grey)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                        onPressed: () => _showEditProfileDialog(profile),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmDeleteProfile(profile),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildConnectionsTab() {
    if (_sentConnections.isEmpty && _receivedConnections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No active connections',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_receivedConnections.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Received Requests',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          ..._receivedConnections.map((conn) => _buildConnectionCard(conn, isReceived: true)),
          const SizedBox(height: 24),
        ],
        if (_sentConnections.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Sent Requests',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          ..._sentConnections.map((conn) => _buildConnectionCard(conn, isReceived: false)),
        ],
      ],
    );
  }

  Widget _buildConnectionCard(FamilyConnection conn, {required bool isReceived}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.1),
                  child: const Icon(Icons.person_add, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isReceived ? (conn.fromEmail ?? 'Unknown') : (conn.toEmail ?? 'Unknown'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Role: ${conn.relationship} • Level: ${conn.accessLevel ?? 'view'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(conn.status),
              ],
            ),
            if (isReceived && conn.status == 'pending') ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _respondToConnection(conn.id, 'reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _respondToConnection(conn.id, 'accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Accept'),
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

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'accepted':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
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
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isEdit ? 'Edit Profile' : 'Add Family Member',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fill in the details for your family member.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 24),
                _buildModernTextField(
                  controller: firstNameController,
                  label: 'First Name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: lastNameController,
                  label: 'Last Name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: relationController,
                  label: 'Relationship',
                  hint: 'e.g., Son, Father, Spouse',
                  icon: Icons.family_restroom_outlined,
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: dobController,
                  label: 'Date of Birth',
                  hint: 'YYYY-MM-DD',
                  icon: Icons.calendar_today_outlined,
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
                            colorScheme: const ColorScheme.light(
                              primary: Colors.blue,
                              onPrimary: Colors.white,
                              onSurface: Colors.black,
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
                const Text(
                  'Gender',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
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
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      isEdit ? 'Update Profile' : 'Create Profile',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.blue, size: 20),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
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
            color: isSelected ? Colors.blue : const Color(0xFFE2E8F0),
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
                color: isSelected ? Colors.blue : const Color(0xFF1E293B),
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
            color: Colors.white,
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
                const Text('Share Health Access', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 8),
                const Text(
                  'Send a request to link with another user account.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                ),
                const SizedBox(height: 24),
                _buildModernTextField(
                  controller: emailController,
                  label: 'User Email',
                  hint: 'example@email.com',
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  controller: relationController,
                  label: 'Relationship',
                  hint: 'e.g., Doctor, Daughter, Caretaker',
                  icon: Icons.link_outlined,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Access Level',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
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

  Future<void> _confirmDeleteProfile(UserProfile profile) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile?'),
        content: Text('Are you sure you want to delete ${profile.fullName}? All linked reports will remain but will lose the profile link.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
