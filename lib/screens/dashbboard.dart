import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:bb/screens/create_donor_company.dart';
import 'package:bb/screens/create_individual_Donor.dart';
import 'package:bb/screens/donor_list_screen.dart';
import 'package:bb/screens/login_screen.dart';
import 'package:bb/screens/reciept.dart';
import 'package:bb/screens/school_list.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:bb/provider/auth_provider.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const String _baseUrl = 'https://agstest.in/api2/public/api';

const Color _primaryBlue   = Color(0xFF4169E1);
const Color _successGreen  = Color(0xFF10B981);
const Color _warningOrange = Color(0xFFF59E0B);
const Color _dangerRed     = Color(0xFFEF4444);
const Color _purple        = Color(0xFF8B5CF6);
const Color _teal          = Color(0xFF14B8A6);
const Color _bgGray        = Color(0xFFF7F8FA);
const Color _cardWhite     = Color(0xFFFFFFFF);
const Color _textPrimary   = Color(0xFF1A1A2E);
const Color _textSecondary = Color(0xFF6B7280);
const Color _textLight     = Color(0xFF9CA3AF);
const Color _borderColor   = Color(0xFFE5E7EB);

// ─────────────────────────────────────────────────────────────────────────────
// API SERVICE
// ─────────────────────────────────────────────────────────────────────────────
class DashboardApiService {
  static Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  static Future<Map<String, dynamic>?> fetchDashboard(String token) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/dashboard'), headers: _headers(token));
      debugPrint('✅ Dashboard: ${res.statusCode}');
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) { debugPrint('❌ fetchDashboard: $e'); }
    return null;
  }

  static Future<List<dynamic>?> fetchNotices(String token) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/app-notice'), headers: _headers(token));
      debugPrint('✅ Notices: ${res.statusCode}');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body['data'] ?? body;
      }
    } catch (e) { debugPrint('❌ fetchNotices: $e'); }
    return null;
  }

  static Future<bool> markNoticeAsRead(String token, String noticeId) async {
    try {
      final res = await http.post(Uri.parse('$_baseUrl/app-notices/$noticeId/read'), headers: _headers(token));
      return res.statusCode == 200;
    } catch (e) { debugPrint('❌ markNoticeAsRead: $e'); return false; }
  }

  static Future<List<dynamic>?> fetchPendingReceipts(String token) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/app-receipt-control'), headers: _headers(token));
      debugPrint('✅ Pending Receipts: ${res.statusCode}');
      debugPrint('📦 Body: ${res.body}');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is List) return body;
        if (body is Map<String, dynamic>) {
          if (body['data'] is List) return body['data'];
          if (body['receipts'] is List) return body['receipts'];
          if (body['pending'] is List) return body['pending'];
          return [];
        }
      }
    } catch (e) { debugPrint('❌ fetchPendingReceipts: $e'); }
    return [];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE MODEL
// ─────────────────────────────────────────────────────────────────────────────
class UserProfile {
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final String? imageUrl;
  final String? birthday;
  final String? address;

  UserProfile({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    this.imageUrl,
    this.birthday,
    this.address,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      imageUrl: json['image']?.toString(),
      birthday: json['user_birthday']?.toString(),
      address: json['user_add']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'user_birthday': birthday ?? '',
      'user_add': address ?? '',
    };
  }

  String get fullName => '$firstName $lastName'.trim();
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE API SERVICE
// ─────────────────────────────────────────────────────────────────────────────
class ProfileApiService {
  static Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  static Future<UserProfile?> fetchProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/app-profile'),
        headers: _headers(token),
      );
      debugPrint('✅ Profile Response Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] ?? body;
        return UserProfile.fromJson(data);
      } else if (response.statusCode == 401) {
        debugPrint('❌ Unauthorized - Please login again');
        return null;
      }
    } catch (e) {
      debugPrint('❌ fetchProfile error: $e');
    }
    return null;
  }

  static Future<bool> updateProfile(String token, UserProfile profile, {File? imageFile}) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/app-update-profile'));
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
      request.fields['first_name'] = profile.firstName;
      request.fields['last_name'] = profile.lastName;
      request.fields['phone'] = profile.phone;
      if (profile.birthday != null && profile.birthday!.isNotEmpty) {
        request.fields['user_birthday'] = profile.birthday!;
      }
      if (profile.address != null && profile.address!.isNotEmpty) {
        request.fields['user_add'] = profile.address!;
      }
      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      }
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ updateProfile error: $e');
      return false;
    }
  }

  static Future<bool> deleteAccount(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/app-delete-account'),
        headers: _headers(token),
      );
      debugPrint('✅ Delete Account Response Status: ${response.statusCode}');
      debugPrint('📦 Delete Account Response Body: ${response.body}');
      return response.statusCode == 200;
    } catch (e) { 
      debugPrint('❌ deleteAccount error: $e'); 
      return false; 
    }
  }

  static Future<bool> logout(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/app-logout'),
        headers: _headers(token),
      );
      debugPrint('✅ Logout Response Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) { 
      debugPrint('❌ logout error: $e'); 
      return false; 
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD SCREEN WITH DRAWER
// ─────────────────────────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);
  
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  Map<String, dynamic>? _dashboardData;
  List<dynamic>? _notices;
  List<dynamic>? _pendingReceipts;
  bool _isLoading = true;
  String? _errorMessage;
  
  // User profile data
  UserProfile? _userProfile;
  bool _isLoadingProfile = true;
   bool _isSaving = false;
  
  // Navigation
  int _selectedIndex = 0;
 

final List<IconData> _menuIcons = [
  Icons.dashboard_outlined,
  Icons.people_outline,
  Icons.receipt_outlined,
];
 Widget _getCurrentScreen() {
  switch (_selectedIndex) {
    case 0:
      return _buildDashboardContent();

    case 1:
      return DonorListScreen();

    case 2:
      return ReceiptListScreen();

    case 3:
      return CreateDonorScreen();

    case 4:
      return CreateCompanyDonorScreen();

    default:
      return const Center(
        child: Text('Coming Soon'),
      );
  }
}
  
  final List<String> _screenTitles = [
  'Dashboard',
  'Donor List',
  'Receipt',
  'Add Donor',
  'Add Company',
];

  @override
  void initState() {
    super.initState();
    _fetchAllData();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token ?? '';
    
    if (token.isNotEmpty) {
      final profile = await ProfileApiService.fetchProfile(token);
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoadingProfile = false;
        });
      }
    } else {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _fetchAllData() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    final results = await Future.wait([
      DashboardApiService.fetchDashboard(token),
      DashboardApiService.fetchNotices(token),
      DashboardApiService.fetchPendingReceipts(token),
    ]);
    if (mounted) {
      setState(() {
        if (results[0] != null) _dashboardData = results[0] as Map<String, dynamic>;
        else _errorMessage = 'Failed to load dashboard data';
        if (results[1] != null) _notices = results[1] as List<dynamic>;
        if (results[2] != null) _pendingReceipts = results[2] as List<dynamic>;
        _isLoading = false;
      });
    }
  }

  Future<void> _markNoticeAsRead(String noticeId) async {
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    final ok = await DashboardApiService.markNoticeAsRead(token, noticeId);
    if (ok && mounted) {
      _fetchAllData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notice marked as read'), backgroundColor: _successGreen));
    }
  }

  // Data helpers
  int get _totalDonors => _i(_dashboardData?['data']?['total_companies_count']);
  int get _individuals => _i(_dashboardData?['data']?['individual_company_count']);
  int get _companiesTrust => _i(_dashboardData?['data']?['other_companies_count']);
  String get _totalDonation => _dashboardData?['data']?['total_donation']?.toString() ?? '0';
  int get _otsCount => _i(_dashboardData?['data']?['ots_receipts_count']);
  int get _membershipCount => _i(_dashboardData?['data']?['mem_receipts_count']);
  int get _generalCount => _i(_dashboardData?['data']?['gen_receipts_count']);
  String get _otsDonation => _dashboardData?['data']?['total_ots_donation']?.toString() ?? '0';
  String get _membershipDonation => _dashboardData?['data']?['total_membership_donation']?.toString() ?? '0';
  String get _generalDonation => _dashboardData?['data']?['total_general_donation']?.toString() ?? '0';

  int _i(dynamic v) => v != null ? int.tryParse(v.toString()) ?? 0 : 0;

  String _fmtDate(String? d) {
    if (d == null || d.isEmpty) return 'N/A';
    try { return DateFormat('dd-MM-yyyy').format(DateTime.parse(d)); } catch (_) { return d; }
  }

  String _fmtNoticeDate(String? d) {
    if (d == null || d.isEmpty) return '';
    try {
      final dt = DateTime.parse(d);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 30) return DateFormat('MMM dd').format(dt);
      if (diff.inDays > 0) return '${diff.inDays} days ago';
      if (diff.inHours > 0) return '${diff.inHours} hours ago';
      return 'Today';
    } catch (_) { return d; }
  }

  String _fmtNum(int v) {
    if (v == 0) return '0';
    return NumberFormat('#,##,###').format(v);
  }

  void _navigateToScreen(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close drawer
  }

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token ?? '';
    
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    final success = await ProfileApiService.logout(token);
    if (!mounted) return;
    Navigator.pop(context);
    if (success) {
      authProvider.logout();
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) =>  LoginScreen()));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed'), backgroundColor: _dangerRed),
      );
    }
  }

  void _openProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Colors.transparent,
      builder: (_) => ProfileBottomSheet(
        userProfile: _userProfile,
        onProfileUpdated: _loadUserProfile,
      ),
    );
  }

  String _getDisplayName() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (_userProfile != null && _userProfile!.fullName.isNotEmpty) {
      return _userProfile!.fullName;
    }
    if (authProvider.userData != null) {
      final name = authProvider.userData!['name'] ?? 
                   authProvider.userData!['full_name'] ?? 
                   authProvider.userData!['first_name'];
      if (name != null && name.toString().isNotEmpty) return name.toString();
    }
    return authProvider.currentUserName;
  }

  String _getEmail() {
    if (_userProfile != null && _userProfile!.email.isNotEmpty) return _userProfile!.email;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.userData != null && authProvider.userData!['email'] != null) {
      return authProvider.userData!['email'].toString();
    }
    return 'user@example.com';
  }
  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: _dangerRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() => _isSaving = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    final success = await ProfileApiService.deleteAccount(token);
    setState(() => _isSaving = false);
    
    if (success && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.logout();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully'), backgroundColor: _successGreen),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete account. Please try again.'), backgroundColor: _dangerRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bgGray,
      appBar: AppBar(
        title: Text(_screenTitles[_selectedIndex], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: _textPrimary),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: _primaryBlue), onPressed: _fetchAllData),
        ],
      ),
      drawer: _buildDrawer(),
    body: _getCurrentScreen(),
    bottomNavigationBar: Container(
  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
  decoration: BoxDecoration(
    color: _primaryBlue,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: _primaryBlue.withOpacity(0.25),
        blurRadius: 15,
        offset: const Offset(0, 6),
      ),
    ],
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      backgroundColor: _primaryBlue,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      iconSize: 20,
      selectedFontSize: 11,
      unselectedFontSize: 10,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_alt_outlined),
          label: 'Donors',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          label: 'Receipt',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_add_alt_1_rounded),
          label: 'Add',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.business_outlined),
          label: 'Company',
        ),
      ],
    ),
  ),
),
    );
  }

  Widget _buildDrawer() {
    final displayName = _getDisplayName();
    final email = _getEmail();
    
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Profile Header
            GestureDetector(
              onTap: _openProfile,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _primaryBlue.withOpacity(0.05),
                  border: Border(bottom: BorderSide(color: _borderColor)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(color: _primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
                      child: _userProfile?.imageUrl != null && _userProfile!.imageUrl!.isNotEmpty
                          ? ClipOval(child: Image.network(_userProfile!.imageUrl!, width: 50, height: 50, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildAvatarText(displayName)))
                          : _buildAvatarText(displayName),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(email, style: const TextStyle(fontSize: 12, color: _textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                   
                    const Icon(Icons.chevron_right, size: 18, color: _textLight),
                  ],
                ),
              ),
            ),
            // Menu Items
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _menuIcons.length,
                itemBuilder: (context, index) {
  final isSelected = _selectedIndex == index;

 if (index == 1) {
  return Column(
    children: [
      ListTile(
        leading: Icon(
          _menuIcons[index],
          color: isSelected ? _primaryBlue : _textSecondary,
        ),
        title: Text(
          _screenTitles[index],
        ),
        onTap: () => _navigateToScreen(index),
      ),

      ListTile(
        dense: true,
        contentPadding: const EdgeInsets.only(left: 16),
        leading: const Icon(Icons.person_add_alt_1, size: 24),
        title: const Text(
  'Add Donor',
  style: TextStyle(
    fontSize: 16,
    
  ),
),
        onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>  SchoolListScreen(),
          ),
        );

        if (result == true) {
          setState(() {});
        }
      },
      ),

      ListTile(
        dense: true,
        contentPadding: const EdgeInsets.only(left: 16),
        leading: const Icon(Icons.business, size: 24),
        title: const Text(
  'Add Company',
  style: TextStyle(
    fontSize: 16,
    
  ),
),
       onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const CreateCompanyDonorScreen(),
          ),
        );

        if (result == true) {
          setState(() {});
        }
      },
      ),
    ],
  );
}
  return ListTile(
    leading: Icon(
      _menuIcons[index],
      color: isSelected ? _primaryBlue : _textSecondary,
    ),
    title: Text(
      _screenTitles[index],
      style: TextStyle(
        color: isSelected ? _primaryBlue : _textPrimary,
      ),
    ),
    onTap: () => _navigateToScreen(index),
  );
},
              ),
            ),
             
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: _borderColor))),
              child: Column(
                children: [
                  
                  ListTile(
                    leading: const Icon(Icons.logout, size: 20, color: _dangerRed),
                    title: const Text('Logout', style: TextStyle(fontSize: 13, color: _dangerRed)),
                    dense: true,
                    onTap: _logout,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _deleteAccount,
                    style: TextButton.styleFrom(foregroundColor: _dangerRed),
                    child: const Text('Delete Account'),
                  ),
                  Text('FTS CHAMP\nVersion 1.0', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: _textLight)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarText(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Center(child: Text(initial, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _primaryBlue)));
  }

  void _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildDashboardContent() {
    return Column(
      children: [
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: _primaryBlue))
              : _errorMessage != null
                  ? _buildError()
                  : RefreshIndicator(
                      color: _primaryBlue,
                      onRefresh: _fetchAllData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatGrid(),
                            const SizedBox(height: 14),
                             _buildDonationSummary(),
                              const SizedBox(height: 14),
                            _buildNeedApproval(),
                            const SizedBox(height: 14),
                             _buildDistribution(),
                              const SizedBox(height: 14),
                            _buildRecentNotices(),
                          ],
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: _textLight),
          const SizedBox(height: 16),
          Text('${_screenTitles[_selectedIndex]} screen coming soon...', style: const TextStyle(color: _textSecondary)),
        ],
      ),
    );
  }

  Widget _buildError() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, size: 48, color: _dangerRed),
      const SizedBox(height: 12),
      Text(_errorMessage!, style: const TextStyle(color: _textSecondary)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: _fetchAllData, style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue), child: const Text('Retry')),
    ]),
  );

  // ── UI Components ──────────────────────────────────────────────────────────
  Widget _buildStatGrid() => Column(children: [
    Row(children: [
      Expanded(child: _statCard('Total Donors', _fmtNum(_totalDonors), const Color(0xFF4FC3F7), const Color(0xFFE3F8FF), Icons.people_outline)),
      const SizedBox(width: 10),
      Expanded(child: _statCard('Individuals', _fmtNum(_individuals), const Color(0xFFFF6B6B), const Color(0xFFFFEEEE), Icons.person_outline)),
    ]),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: _statCard('Comp./ Trust', _fmtNum(_companiesTrust), const Color(0xFFAB47BC), const Color(0xFFF3E5F5), Icons.business_outlined)),
      const SizedBox(width: 10),
      Expanded(child: _statCard('Total Donation', '₹$_totalDonation', const Color(0xFF26C6DA), const Color(0xFFE0F7FA), Icons.currency_rupee)),
    ]),
  ]);

  Widget _statCard(String label, String value, Color iconColor, Color iconBg, IconData icon) =>
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _cardWhite, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0,2))]),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: iconColor, size: 20)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: _textSecondary)),
        ])),
      ]),
    );

  Widget _buildNeedApproval() {
    final pending = _pendingReceipts ?? [];
    return _sectionCard(
      header: Row(children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.notifications_outlined, size: 16, color: _warningOrange)),
        const SizedBox(width: 10),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Need Approval', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textPrimary)),
          Text('Receipts Pending for Approval', style: TextStyle(fontSize: 11, color: _textSecondary)),
        ])),
        _pill('${pending.length} New', _primaryBlue),
      ]),
      body: pending.isEmpty
        ? Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Center(child: Text('No pending approvals', style: TextStyle(color: _textLight, fontSize: 13))))
        : Column(children: pending.map((r) => _approvalRow(r)).toList()),
    );
  }

  Widget _approvalRow(Map<String, dynamic> receipt) {
    final name = receipt['indicomp_full_name'] ?? 'Unknown';
    final refNo = receipt['receipt_no']?.toString() ?? 'N/A';
    final date = _fmtDate(receipt['receipt_date']?.toString());
    final amount = receipt['receipt_total_amount']?.toString() ?? '0';
    final chips = _parseTypeChips(receipt);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _bgGray, borderRadius: BorderRadius.circular(12), border: Border.all(color: _borderColor)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _textPrimary))),
          Container(width: 28, height: 28, decoration: BoxDecoration(color: _primaryBlue.withOpacity(0.08), shape: BoxShape.circle), child: const Icon(Icons.visibility_outlined, size: 14, color: _primaryBlue)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.receipt_outlined, size: 13, color: _textLight), const SizedBox(width: 4),
          Text('Ref: $refNo', style: const TextStyle(fontSize: 12, color: _textSecondary)), const SizedBox(width: 12),
          const Icon(Icons.calendar_today_outlined, size: 12, color: _textLight), const SizedBox(width: 4),
          Text(date, style: const TextStyle(fontSize: 12, color: _textSecondary)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          ...chips.map((c) => Padding(padding: const EdgeInsets.only(right: 6), child: _typeChip(c['label']!, c['color']!))),
          const Spacer(),
          Text('₹$amount', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _textPrimary)),
        ]),
      ]),
    );
  }

  List<Map<String, dynamic>> _parseTypeChips(Map<String, dynamic> r) {
    final chips = <Map<String, dynamic>>[];
    final exemption = r['receipt_exemption_type']?.toString() ?? '';
    final receiptType = r['receipt_type']?.toString() ?? '';
    const colorMap = {'M': Color(0xFF4169E1), 'P': Color(0xFFAB47BC), 'G': Color(0xFF10B981), 'F': Color(0xFFF59E0B), 'OTS': Color(0xFF8B5CF6)};
    if (receiptType.isNotEmpty) {
      final initial = receiptType.substring(0, math.min(1, receiptType.length)).toUpperCase();
      chips.add({'label': initial, 'color': colorMap[initial] ?? _primaryBlue});
    }
    if (exemption.isNotEmpty) chips.add({'label': exemption, 'color': _textSecondary});
    if (chips.isEmpty) chips.add({'label': 'N/A', 'color': _textLight});
    return chips;
  }

  Widget _typeChip(String label, dynamic color) {
    final c = color is Color ? color : _textSecondary;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(6)), child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c)));
  }

  Widget _buildRecentNotices() {
    final unread = _notices?.where((n) => n['is_read'] == 0).length ?? 0;
    final list = _notices ?? [];
    return _sectionCard(
      header: Row(children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: _primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.notifications_outlined, size: 16, color: _primaryBlue)),
        const SizedBox(width: 10),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Recent Notices', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textPrimary)),
          Text('Updates and announcements', style: TextStyle(fontSize: 11, color: _textSecondary)),
        ])),
        _pill('$unread New', _primaryBlue),
      ]),
      body: list.isEmpty
        ? Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Center(child: Text('No notices available', style: TextStyle(color: _textLight, fontSize: 13))))
        : Column(children: list.map((n) => _noticeRow(n)).toList()),
    );
  }

  Widget _noticeRow(Map<String, dynamic> notice) {
    final isRead = notice['is_read'] == 1;
    final title = notice['notice_name'] ?? 'Notice';
    final detail = notice['notice_detail'] ?? '';
    final date = _fmtNoticeDate(notice['created_at']?.toString());

    return GestureDetector(
      onTap: () => _showNoticeDetail(notice),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: isRead ? _bgGray : _primaryBlue.withOpacity(0.04), borderRadius: BorderRadius.circular(10), border: Border.all(color: isRead ? _borderColor : _primaryBlue.withOpacity(0.2))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 13.5, fontWeight: isRead ? FontWeight.w600 : FontWeight.w700, color: _textPrimary)),
            const SizedBox(height: 4),
            Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: _textSecondary, height: 1.4)),
            if (date.isNotEmpty) ...[const SizedBox(height: 4), Text(date, style: const TextStyle(fontSize: 11, color: _textLight))],
          ])),
          const SizedBox(width: 8),
          const Icon(Icons.more_vert, size: 18, color: _textLight),
        ]),
      ),
    );
  }

  void _showNoticeDetail(Map<String, dynamic> notice) {
    final isRead = notice['is_read'] == 1;
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardWhite,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7, minChildSize: 0.5, maxChildSize: 0.9, expand: false,
        builder: (_, ctrl) => Column(children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: _borderColor, borderRadius: BorderRadius.circular(2))),
          Expanded(child: SingleChildScrollView(
            controller: ctrl, padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(notice['notice_name'] ?? 'Notice', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: _textPrimary)),
              const SizedBox(height: 6),
              Text(_fmtNoticeDate(notice['created_at']?.toString()), style: const TextStyle(fontSize: 12, color: _textLight)),
              const SizedBox(height: 18),
              Text(notice['notice_detail'] ?? '', style: const TextStyle(fontSize: 14, height: 1.6, color: _textSecondary)),
              const SizedBox(height: 28),
              if (!isRead)
                SizedBox(width: double.infinity, child: ElevatedButton(
                  onPressed: () async { await _markNoticeAsRead(notice['id'].toString()); if (mounted) Navigator.pop(context); },
                  style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Mark as Read', style: TextStyle(fontWeight: FontWeight.w600)),
                )),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _buildDonationSummary() => _sectionCard(
    header: Row(children: [
      Container(width: 32, height: 32, decoration: BoxDecoration(color: _warningOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.bar_chart_outlined, size: 16, color: _warningOrange)),
      const SizedBox(width: 10),
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Donation Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textPrimary)),
        Text('Breakdown by type', style: TextStyle(fontSize: 11, color: _textSecondary)),
      ]),
    ]),
    body: Column(children: [
      const SizedBox(height: 4),
      _donationSummaryRow('OTS', _otsDonation, _otsCount, _purple, Icons.currency_rupee),
      const Divider(color: _borderColor, height: 1),
      _donationSummaryRow('Membership', _membershipDonation, _membershipCount, _warningOrange, Icons.currency_rupee),
      const Divider(color: _borderColor, height: 1),
      _donationSummaryRow('General', _generalDonation, _generalCount, _successGreen, Icons.currency_rupee),
    ]),
  );

  Widget _donationSummaryRow(String label, String amount, int count, Color color, IconData icon) =>
    Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(children: [
      Container(width: 30, height: 30, decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle), child: Icon(icon, size: 14, color: color)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textPrimary)),
        Text('₹ $amount', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ])),
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color))),
    ]));

  Widget _buildDistribution() {
    final total = _otsCount + _membershipCount + _generalCount;
    final data = <_ChartSlice>[
      if (_generalCount > 0) _ChartSlice('General', _generalCount, _successGreen),
      if (_membershipCount > 0) _ChartSlice('Membership', _membershipCount, _warningOrange),
      if (_otsCount > 0) _ChartSlice('One Teacher School', _otsCount, _purple),
    ];

    return _sectionCard(
      header: Row(children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.pie_chart_outline, size: 16, color: _successGreen)),
        const SizedBox(width: 10),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Distribution', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textPrimary)),
          Text('Receipt type distribution', style: TextStyle(fontSize: 11, color: _textSecondary)),
        ]),
      ]),
      body: Column(children: [
        const SizedBox(height: 8),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(width: 110, height: 110, child: CustomPaint(painter: _DonutPainter(data, total))),
          const SizedBox(width: 24),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: data.map((d) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: d.color, shape: BoxShape.circle)), const SizedBox(width: 8), Expanded(child: Text(d.label, style: const TextStyle(fontSize: 12, color: _textSecondary)))]))).toList())),
        ]),
        if (data.isNotEmpty) ...[
          const SizedBox(height: 16), const Divider(color: _borderColor, height: 1), const SizedBox(height: 12),
          ...data.map((d) => _progressRow(d, total)),
        ],
      ]),
    );
  }

  Widget _progressRow(_ChartSlice d, int total) {
    final pct = total > 0 ? (d.value / total * 100) : 0.0;
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(d.label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: _textPrimary)), Text('${d.value} receipts', style: const TextStyle(fontSize: 11.5, color: _textSecondary))]),
      const SizedBox(height: 6),
      ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: total > 0 ? d.value / total : 0, backgroundColor: _borderColor, valueColor: AlwaysStoppedAnimation(d.color), minHeight: 7)),
      const SizedBox(height: 3),
      Text('${pct.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, color: _textLight)),
    ]));
  }

  Widget _sectionCard({required Widget header, required Widget body}) => Container(
    margin: const EdgeInsets.only(bottom: 2),
    decoration: BoxDecoration(color: _cardWhite, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0,2))]),
    child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [header, const SizedBox(height: 2), body])),
  );

  Widget _pill(String label, Color color) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)));
}

// ─────────────────────────────────────────────────────────────────────────────
// Donut Chart
// ─────────────────────────────────────────────────────────────────────────────
class _ChartSlice {
  final String label;
  final int value;
  final Color color;
  _ChartSlice(this.label, this.value, this.color);
}

class _DonutPainter extends CustomPainter {
  final List<_ChartSlice> data;
  final int total;
  _DonutPainter(this.data, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0 || data.isEmpty) {
      final paint = Paint()..color = _borderColor..style = PaintingStyle.stroke..strokeWidth = 18;
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2 - 9, paint);
      return;
    }
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeW = 18.0;
    const gap = 0.03;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = strokeW..strokeCap = StrokeCap.butt;
    double startAngle = -math.pi / 2;
    final total2pi = 2 * math.pi;
    for (final slice in data) {
      final sweep = (slice.value / total) * total2pi - gap;
      paint.color = slice.color;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep.clamp(0.01, total2pi), false, paint);
      startAngle += sweep + gap;
    }
  }
  @override bool shouldRepaint(covariant CustomPainter old) => true;
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class ProfileBottomSheet extends StatefulWidget {
  final UserProfile? userProfile;
  final VoidCallback onProfileUpdated;
  const ProfileBottomSheet({Key? key, this.userProfile, required this.onProfileUpdated}) : super(key: key);
  @override
  State<ProfileBottomSheet> createState() => _ProfileBottomSheetState();
}

class _ProfileBottomSheetState extends State<ProfileBottomSheet> {
  late TextEditingController _firstNameController, _lastNameController, _phoneController, _emailController, _birthdayController, _addressController;
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.userProfile?.firstName ?? '');
    _lastNameController = TextEditingController(text: widget.userProfile?.lastName ?? '');
    _phoneController = TextEditingController(text: widget.userProfile?.phone ?? '');
    _emailController = TextEditingController(text: widget.userProfile?.email ?? '');
    _birthdayController = TextEditingController(text: widget.userProfile?.birthday ?? '');
    _addressController = TextEditingController(text: widget.userProfile?.address ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _birthdayController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      _birthdayController.text = DateFormat('yyyy-MM-dd').format(date);
    }
  }

  Future<void> _saveProfile() async {
    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('First and last name required'), backgroundColor: _warningOrange),
      );
      return;
    }
    setState(() => _isSaving = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    final profile = UserProfile(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      birthday: _birthdayController.text,
      address: _addressController.text,
    );
    final success = await ProfileApiService.updateProfile(token, profile, imageFile: _selectedImage);
    setState(() => _isSaving = false);
    if (success && mounted) {
      widget.onProfileUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated'), backgroundColor: _successGreen),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile'), backgroundColor: _dangerRed),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: _dangerRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    setState(() => _isSaving = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    final success = await ProfileApiService.deleteAccount(token);
    setState(() => _isSaving = false);
    
    if (success && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.logout();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully'), backgroundColor: _successGreen),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete account. Please try again.'), backgroundColor: _dangerRed),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: _cardWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: _borderColor, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Text('Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _textPrimary)),
                  const Spacer(),
                  TextButton(
                    onPressed: _deleteAccount,
                    style: TextButton.styleFrom(foregroundColor: _dangerRed),
                    child: const Text('Delete Account'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(color: _primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
                            child: _selectedImage != null
                                ? ClipOval(child: Image.file(_selectedImage!, width: 80, height: 80, fit: BoxFit.cover))
                                : widget.userProfile?.imageUrl != null && widget.userProfile!.imageUrl!.isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          widget.userProfile!.imageUrl!,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => _buildAvatarInitial(),
                                        ),
                                      )
                                    : _buildAvatarInitial(),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: _primaryBlue, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField('First Name', _firstNameController, required: true),
                    const SizedBox(height: 16),
                    _buildTextField('Last Name', _lastNameController, required: true),
                    const SizedBox(height: 16),
                    _buildTextField('Phone', _phoneController, keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    _buildReadonlyField('Email', _emailController.text),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _selectDate,
                      child: AbsorbPointer(child: _buildTextField('Birthday', _birthdayController)),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField('Address', _addressController, maxLines: 2),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Update Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarInitial() {
    final initial = _firstNameController.text.isNotEmpty ? _firstNameController.text[0].toUpperCase() : 'U';
    return Center(child: Text(initial, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: _primaryBlue)));
  }

  Widget _buildTextField(String label, TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textSecondary)),
            if (required) const Text(' *', style: TextStyle(color: _dangerRed)),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: _bgGray,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildReadonlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textSecondary)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: _bgGray, borderRadius: BorderRadius.circular(10)),
          child: Text(
            value.isNotEmpty ? value : 'Not provided',
            style: const TextStyle(fontSize: 14, color: _textPrimary),
          ),
        ),
      ],
    );
  }
}