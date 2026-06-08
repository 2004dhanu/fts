import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:bb/provider/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS & THEME
// ─────────────────────────────────────────────────────────────────────────────
const String _baseUrl = 'https://agstest.in/api2/public/api';

const Color _blue = Color(0xFF3B7DD8);
const Color _bgGray = Color(0xFFF8F9FC);
const Color _borderColor = Color(0xFFE5E7EB);
const Color _textPrimary = Color(0xFF111827);
const Color _textSecondary = Color(0xFF6B7280);
const Color _textLight = Color(0xFF9CA3AF);
const Color _successGreen = Color(0xFF10B981);
const Color _warningOrange = Color(0xFFF59E0B);
const Color _dangerRed = Color(0xFFEF4444);

// ─────────────────────────────────────────────────────────────────────────────
// API SERVICE
// ─────────────────────────────────────────────────────────────────────────────
class DonorViewApiService {
  static Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  /// Fetch donor view by ID
  static Future<Map<String, dynamic>?> fetchDonorView(String token, String id) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/app-donor-view/$id'),
        headers: _headers(token),
      );
      
      debugPrint('Donor View Response Status: ${res.statusCode}');
      debugPrint('Donor View Response Body: ${res.body}');
      
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return body;
      }
    } catch (e) {
      debugPrint('fetchDonorView error: $e');
    }
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DONOR VIEW SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class DonorViewScreen extends StatefulWidget {
  final String donorId;
  
  const DonorViewScreen({Key? key, required this.donorId}) : super(key: key);

  @override
  State<DonorViewScreen> createState() => _DonorViewScreenState();
}

class _DonorViewScreenState extends State<DonorViewScreen> {
  Map<String, dynamic>? _donorData;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedTab = 0; // 0: Overview, 1: Personal, 2: Family, 3: Companies, 4: Donations

  final List<String> _tabs = ['Overview', 'Personal', 'Family', 'Companies', 'Donations'];

  @override
  void initState() {
    super.initState();
    _fetchDonorData();
  }

  Future<void> _fetchDonorData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    final result = await DonorViewApiService.fetchDonorView(token, widget.donorId);

    if (mounted) {
      setState(() {
        if (result != null) {
          _donorData = result;
          _isLoading = false;
        } else {
          _errorMessage = 'Failed to load donor data';
          _isLoading = false;
        }
      });
    }
  }

  // Helper methods to extract data
  Map<String, dynamic>? get _individualCompany => _donorData?['individualCompany'];
  List<dynamic> get _familyDetails => _donorData?['family_details'] ?? [];
  List<dynamic> get _companyDetails => _donorData?['company_details'] ?? [];
  List<dynamic> get _relatedGroup => _donorData?['related_group'] ?? [];
  List<dynamic> get _imageUrls => _donorData?['image_url'] ?? [];

  String get _donorType => _individualCompany?['indicomp_type'] ?? 'Individual';
  String get _donorStatus => _individualCompany?['indicomp_status'] ?? 'Active';
  String get _donorName => _individualCompany?['indicomp_full_name'] ?? 'N/A';
  String get _donorId => _individualCompany?['indicomp_fts_id']?.toString() ?? 'N/A';
  String get _donorTitle => _individualCompany?['title'] ?? '';
  String get _donorGender => _individualCompany?['indicomp_gender'] ?? '';
  String get _mobilePhone => _individualCompany?['indicomp_mobile_phone'] ?? '';
  String get _email => _individualCompany?['indicomp_email'] ?? '';
  String get _panNumber => _individualCompany?['indicomp_pan_no'] ?? '';
  String get _remarks => _individualCompany?['indicomp_remarks'] ?? '';
  String get _donorTypeValue => _individualCompany?['indicomp_donor_type'] ?? 'None';
  String get _source => _individualCompany?['indicomp_source'] ?? '';
  String get _belongsTo => _individualCompany?['indicomp_belongs_to'] ?? '';
  String get _csr => _individualCompany?['indicomp_csr'] ?? 'No';
  String get _correspondencePref => _individualCompany?['indicomp_corr_preffer'] ?? 'Residence';
  
  // Addresses
  String get _resAddress => '${_individualCompany?['indicomp_res_reg_address'] ?? ''}\n'
      '${_individualCompany?['indicomp_res_reg_area'] ?? ''}\n'
      '${_individualCompany?['indicomp_res_reg_ladmark'] ?? ''}\n'
      '${_individualCompany?['indicomp_res_reg_city'] ?? ''}, ${_individualCompany?['indicomp_res_reg_state'] ?? ''} - ${_individualCompany?['indicomp_res_reg_pin_code'] ?? ''}';
  
  String get _offAddress => '${_individualCompany?['indicomp_off_branch_address'] ?? ''}\n'
      '${_individualCompany?['indicomp_off_branch_area'] ?? ''}\n'
      '${_individualCompany?['indicomp_off_branch_ladmark'] ?? ''}\n'
      '${_individualCompany?['indicomp_off_branch_city'] ?? ''}, ${_individualCompany?['indicomp_off_branch_state'] ?? ''} - ${_individualCompany?['indicomp_off_branch_pin_code'] ?? ''}';

  // Dates
  String get _dob => _formatDate(_individualCompany?['indicomp_dob_annualday']);
  String get _doa => _formatDate(_individualCompany?['indicomp_doa']);
  String get _joiningDate => _formatDate(_individualCompany?['indicomp_joining_date']);

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'N/A';
    try {
      final parsed = DateTime.parse(date);
      return DateFormat('dd MMM yyyy').format(parsed);
    } catch (e) {
      return date;
    }
  }

  // Family Members Count
  int get _familyCount => _familyDetails.length;
  int get _companyCount => _companyDetails.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGray,
      appBar: AppBar(
        title: Text(
          _donorName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _textPrimary,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // Navigate to edit screen
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: _dangerRed),
                      const SizedBox(height: 16),
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchDonorData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchDonorData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile Header
                        _buildProfileHeader(),
                        
                        // Stats Cards
                        _buildStatsCards(),
                        
                        // Tabs
                        _buildTabs(),
                        
                        // Tab Content
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildTabContent(),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: _blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getInitials(_donorName),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: _blue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Donor Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _donorName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(_donorStatus).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _donorStatus,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _getStatusColor(_donorStatus),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Donor ID: ${_donorId}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getTypeColor(_donorType).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _donorType,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _getTypeColor(_donorType),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getDonorTypeColor(_donorTypeValue).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _donorTypeValue,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _getDonorTypeColor(_donorTypeValue),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    // Demo stats - replace with actual API data when available
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _statCard('Total Donated', '₱93,670', _blue)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Total Receipts', '1', _successGreen)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Family Members', _familyCount.toString(), _warningOrange)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Memberships', '2', _dangerRed)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statCard('Current Year', '₱0', _textSecondary)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Last Year', '₱0', _textSecondary)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Largest Donation', '₱88,000', _successGreen)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Membership Value', '₱5,670', _warningOrange)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final isSelected = _selectedTab == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? _blue : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  _tabs[index],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? _blue : _textSecondary,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildPersonalTab();
      case 2:
        return _buildFamilyTab();
      case 3:
        return _buildCompaniesTab();
      case 4:
        return _buildDonationsTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildOverviewTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Personal Info Card
        _sectionCard('Personal Information', [
          _infoRow('Full Name', _donorName),
          _infoRow('Title', _donorTitle),
          _infoRow('Gender', _donorGender),
          _infoRow('Date of Birth', _dob),
          _infoRow('Date of Anniversary', _doa),
          _infoRow('PAN Number', _panNumber),
          _infoRow('Mobile Phone', _mobilePhone),
          _infoRow('Email', _email),
          _infoRow('Website', _individualCompany?['indicomp_website'] ?? 'N/A'),
          _infoRow('Status', _donorStatus),
        ]),
        
        const SizedBox(height: 16),
        
        // Address Card
        _sectionCard('Addresses', [
          _addressSection('Residence Address', _resAddress),
          const SizedBox(height: 16),
          _addressSection('Office Address', _offAddress),
        ]),
        
        const SizedBox(height: 16),
        
        // Other Details Card
        _sectionCard('Other Details', [
          _infoRow('Donor Type', _donorTypeValue),
          _infoRow('Correspondence Preference', _correspondencePref),
          _infoRow('Is Promoter', _individualCompany?['indicomp_is_promoter'] ?? 'No'),
          _infoRow('Promoter', _individualCompany?['indicomp_promoter'] ?? 'N/A'),
          _infoRow('Source', _source),
          _infoRow('Belongs To', _belongsTo),
          _infoRow('CSR', _csr),
          _infoRow('Remarks', _remarks),
          _infoRow('Created By', _individualCompany?['created_by'] ?? 'N/A'),
          _infoRow('Updated By', _individualCompany?['updated_by'] ?? 'N/A'),
          _infoRow('Joining Date', _joiningDate),
        ]),
        
        const SizedBox(height: 16),
        
        // Memberships Card (if any)
        _buildMembershipsSection(),
      ],
    );
  }

  Widget _buildPersonalTab() {
    return Column(
      children: [
        _sectionCard('Personal Details', [
          _infoRow('Full Name', _donorName),
          _infoRow('Title', _donorTitle),
          _infoRow('Father Name', _individualCompany?['indicomp_father_name'] ?? 'N/A'),
          _infoRow('Mother Name', _individualCompany?['indicomp_mother_name'] ?? 'N/A'),
          _infoRow('Spouse Name', _individualCompany?['indicomp_spouse_name'] ?? 'N/A'),
          _infoRow('Gender', _donorGender),
          _infoRow('Date of Birth', _dob),
          _infoRow('Date of Anniversary', _doa),
          _infoRow('PAN Number', _panNumber),
          _infoRow('Remarks', _remarks),
        ]),
        const SizedBox(height: 16),
        _sectionCard('Communication Details', [
          _infoRow('Mobile Phone', _mobilePhone),
          _infoRow('WhatsApp', _individualCompany?['indicomp_mobile_whatsapp'] ?? 'N/A'),
          _infoRow('Email', _email),
          _infoRow('Website', _individualCompany?['indicomp_website'] ?? 'N/A'),
        ]),
      ],
    );
  }

  Widget _buildFamilyTab() {
    if (_familyDetails.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          children: [
            Icon(Icons.family_restroom, size: 64, color: _textLight),
            SizedBox(height: 16),
            Text(
              'No family members found',
              style: TextStyle(fontSize: 14, color: _textSecondary),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _familyDetails.length,
      itemBuilder: (context, index) {
        final member = _familyDetails[index];
        return _familyMemberCard(member);
      },
    );
  }

  Widget _buildCompaniesTab() {
    if (_companyDetails.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          children: [
            Icon(Icons.business_outlined, size: 64, color: _textLight),
            SizedBox(height: 16),
            Text(
              'No companies found',
              style: TextStyle(fontSize: 14, color: _textSecondary),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _companyDetails.length,
      itemBuilder: (context, index) {
        final company = _companyDetails[index];
        return _companyCard(company);
      },
    );
  }

  Widget _buildDonationsTab() {
    // Sample donations - replace with actual API data
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _sectionHeader('Recent Donations'),
          const SizedBox(height: 12),
          const _DonationTable(),
          const SizedBox(height: 24),
          _sectionHeader('Upcoming Renewals'),
          const SizedBox(height: 12),
          _buildRenewalItem('Membership #5364', 'Valid until: 2025', '₱1,242'),
          const SizedBox(height: 12),
          _buildRenewalItem('Membership #64', 'Valid until: 2023-24', '₱4,428'),
        ],
      ),
    );
  }

  Widget _buildMembershipsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Memberships',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildMembershipItem('Membership #5364', 'Valid until: 2025', '₱1,242'),
          const SizedBox(height: 12),
          _buildMembershipItem('Membership #64', 'Valid until: 2023-24', '₱4,428'),
        ],
      ),
    );
  }

  Widget _buildMembershipItem(String title, String validity, String amount) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bgGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                validity,
                style: const TextStyle(
                  fontSize: 11,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRenewalItem(String title, String validity, String amount) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bgGray,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                validity,
                style: const TextStyle(
                  fontSize: 11,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _warningOrange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: _blue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: _textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressSection(String title, String address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          address.isNotEmpty ? address : 'N/A',
          style: const TextStyle(
            fontSize: 12,
            color: _textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _familyMemberCard(Map<String, dynamic> member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline, color: _blue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member['indicomp_full_name'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member['indicomp_mobile_phone'] ?? 'No contact',
                      style: const TextStyle(fontSize: 12, color: _textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _companyCard(Map<String, dynamic> company) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _successGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.business, color: _successGreen, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company['indicomp_full_name'] ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  company['indicomp_type'] ?? 'Company',
                  style: const TextStyle(fontSize: 12, color: _textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return _successGreen;
      case 'inactive':
        return _dangerRed;
      default:
        return _warningOrange;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'individual':
        return _blue;
      case 'private':
      case 'public':
      case 'psu':
        return _successGreen;
      case 'trust':
      case 'society':
        return _warningOrange;
      default:
        return _textSecondary;
    }
  }

  Color _getDonorTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'member':
        return _blue;
      case 'donor':
        return _successGreen;
      case 'member+donor':
        return _warningOrange;
      default:
        return _textSecondary;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DONATION TABLE WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _DonationTable extends StatelessWidget {
  const _DonationTable();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _tableHeader(),
          _tableRow('Receipt No', '#2079'),
          _tableRow('Date', '9 Oct 1981'),
          _tableRow('Amount', '₱88,000'),
          _tableRow('Type', 'Donation'),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FC),
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Receipt No', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          Text('Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          Text('Amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          Text('Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _tableRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
     
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}