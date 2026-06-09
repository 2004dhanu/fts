import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:bb/provider/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const String _baseUrl = 'https://agstest.in/api2/public/api';

const Color _blue        = Color(0xFF3B7DD8);
const Color _bgGray      = Color(0xFFF8F9FC);
const Color _borderColor = Color(0xFFE8ECF0);
const Color _textPrimary = Color(0xFF111827);
const Color _textSecondary = Color(0xFF6B7280);
const Color _textLight   = Color(0xFF9CA3AF);
const Color _successGreen = Color(0xFF10B981);
const Color _warningOrange = Color(0xFFF59E0B);
const Color _dangerRed   = Color(0xFFEF4444);

// ─────────────────────────────────────────────────────────────────────────────
// API SERVICE  (unchanged)
// ─────────────────────────────────────────────────────────────────────────────
class DonorViewApiService {
  static Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  static Future<Map<String, dynamic>?> fetchDonorView(String token, String id) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/app-donor-view/$id'), headers: _headers(token));
      debugPrint('✅ Donor View: ${res.statusCode}');
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body.containsKey('code') && body['code'] == 404) return null;
        return body;
      }
    } catch (e) { debugPrint('❌ fetchDonorView: $e'); }
    return null;
  }

  static Future<Map<String, dynamic>?> fetchDonorReceipts(String token, String id) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/app-donor-all-receipts/$id'), headers: _headers(token));
      debugPrint('✅ Donor Receipts: ${res.statusCode}');
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) { debugPrint('❌ fetchDonorReceipts: $e'); }
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class DonorViewScreen extends StatefulWidget {
  final String donorId;
  const DonorViewScreen({Key? key, required this.donorId}) : super(key: key);

  @override
  State<DonorViewScreen> createState() => _DonorViewScreenState();
}

class _DonorViewScreenState extends State<DonorViewScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _donorData;
  Map<String, dynamic>? _receiptsData;
  bool _isLoading = true;
  String? _errorMessage;
  late TabController _tabController;

  final List<String> _tabs = ['Overview', 'Personal', 'Family', 'Companies', 'Donations'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _fetchAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllData() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    final results = await Future.wait([
      DonorViewApiService.fetchDonorView(token, widget.donorId),
      DonorViewApiService.fetchDonorReceipts(token, widget.donorId),
    ]);
    if (mounted) {
      setState(() {
        if (results[0] != null && !results[0]!.containsKey('code')) {
          _donorData = results[0];
        } else {
          _errorMessage = results[0]?['message'] ?? 'Failed to load donor data';
        }
        if (results[1] != null) _receiptsData = results[1];
        _isLoading = false;
      });
    }
  }

  // ── Data helpers (all logic unchanged) ────────────────────────────────────
  Map<String, dynamic>? get _ic => _donorData?['individualCompany'];
  List<dynamic> get _familyDetails  => _donorData?['family_details']  ?? [];
  List<dynamic> get _companyDetails => _donorData?['company_details'] ?? [];
  List<dynamic> get _relatedGroup   => _donorData?['related_group']   ?? [];
  List<dynamic> get _imageUrls      => _donorData?['image_url']       ?? [];
  List<dynamic> get _donorReceipts  => _receiptsData?['donor_receipts']    ?? [];
  List<dynamic> get _membershipDetails => _receiptsData?['membership_details'] ?? [];

  double get _totalDonated {
    double t = 0;
    for (var r in _donorReceipts)    t += double.tryParse(r['receipt_total_amount']?.toString() ?? '0') ?? 0;
    for (var m in _membershipDetails) t += double.tryParse(m['receipt_total_amount']?.toString() ?? '0') ?? 0;
    return t;
  }
  int    get _totalReceipts => _donorReceipts.length + _membershipDetails.length;
  double get _largestDonation {
    double l = 0;
    for (var r in [..._donorReceipts, ..._membershipDetails]) {
      double a = double.tryParse(r['receipt_total_amount']?.toString() ?? '0') ?? 0;
      if (a > l) l = a;
    }
    return l;
  }
  double get _membershipValue {
    double t = 0;
    for (var m in _membershipDetails) t += double.tryParse(m['receipt_total_amount']?.toString() ?? '0') ?? 0;
    return t;
  }

  String get _profileImageUrl {
    for (var img in _imageUrls) {
      if (img['image_for'] == 'Donor' && img['image_url'] != null) {
        final path = _ic?['indicomp_image_logo'] ?? '';
        if (path.isNotEmpty && path != 'null') return '${img['image_url']}$path';
      }
    }
    return 'https://agstest.in/api2/public/assets/images/no_image.jpg';
  }

  String get _donorType      => _ic?['indicomp_type']         ?? 'Individual';
  String get _donorStatus    => _ic?['indicomp_status']       ?? 'Active';
  String get _donorName      => _ic?['indicomp_full_name']    ?? 'N/A';
  String get _donorFtsId     => _ic?['indicomp_fts_id']?.toString() ?? 'N/A';
  String get _donorTitle     => _ic?['title']                 ?? '';
  String get _donorGender    => _ic?['indicomp_gender']       ?? '';
  String get _fatherName     => _ic?['indicomp_father_name']  ?? 'N/A';
  String get _motherName     => _ic?['indicomp_mother_name']  ?? 'N/A';
  String get _spouseName     => _ic?['indicomp_spouse_name']  ?? 'N/A';
  String get _mobilePhone    => _ic?['indicomp_mobile_phone'] ?? '';
  String get _whatsapp       => _ic?['indicomp_mobile_whatsapp'] ?? '';
  String get _email          => _ic?['indicomp_email']        ?? '';
  String get _website        => _ic?['indicomp_website']      ?? '';
  String get _panNumber      => _ic?['indicomp_pan_no']       ?? '';
  String get _remarks        => _ic?['indicomp_remarks']      ?? '';
  String get _donorTypeValue => _ic?['indicomp_donor_type']   ?? 'None';
  String get _source         => _ic?['indicomp_source']       ?? '';
  String get _belongsTo      => _ic?['indicomp_belongs_to']   ?? '';
  String get _csr            => _ic?['indicomp_csr']          ?? 'No';
  String get _isPromoter     => _ic?['indicomp_is_promoter']  ?? 'No';
  String get _promoter       => _ic?['indicomp_promoter']     ?? 'N/A';
  String get _correspondencePref => _ic?['indicomp_corr_preffer'] ?? 'Residence';
  String get _createdBy      => _ic?['created_by']            ?? 'N/A';
  String get _updatedBy      => _ic?['updated_by']            ?? 'N/A';

  String _buildAddress(List<List<String>> keys) {
    final parts = <String>[];
    for (var pair in keys) {
      final v = _ic?[pair[0]]?.toString() ?? '';
      if (v.isNotEmpty && v != 'null') parts.add(v);
    }
    return parts.isNotEmpty ? parts.join(', ') : 'N/A';
  }

  String get _resAddress => _buildAddress([
    ['indicomp_res_reg_address'], ['indicomp_res_reg_area'],
    ['indicomp_res_reg_ladmark'], ['indicomp_res_reg_city'],
    ['indicomp_res_reg_state'],   ['indicomp_res_reg_pin_code'],
  ]);
  String get _offAddress => _buildAddress([
    ['indicomp_off_branch_address'], ['indicomp_off_branch_area'],
    ['indicomp_off_branch_ladmark'], ['indicomp_off_branch_city'],
    ['indicomp_off_branch_state'],   ['indicomp_off_branch_pin_code'],
  ]);

  String _fd(String? d) {
    if (d == null || d.isEmpty) return 'N/A';
    try { return DateFormat('dd MMM yyyy').format(DateTime.parse(d)); } catch (e) { return d; }
  }
  String get _dob         => _fd(_ic?['indicomp_dob_annualday']);
  String get _doa         => _fd(_ic?['indicomp_doa']);
  String get _joiningDate => _fd(_ic?['indicomp_joining_date']);

  String _getInitials(String name) {
    if (name.isEmpty || name == 'N/A') return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'active': return _successGreen;
      case 'inactive': return _dangerRed;
      default: return _warningOrange;
    }
  }
  Color _typeColor(String t) {
    switch (t.toLowerCase()) {
      case 'individual': return _blue;
      case 'private': case 'public': case 'psu': return _successGreen;
      case 'trust': case 'society': return _warningOrange;
      default: return _textSecondary;
    }
  }
  Color _donorTypeColor(String t) {
    switch (t.toLowerCase()) {
      case 'member': return _blue;
      case 'donor': return _successGreen;
      case 'member+donor': return _warningOrange;
      default: return _textSecondary;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _textPrimary,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Donor Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textPrimary)),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () {}),
          IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _fetchAllData),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _borderColor, height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : _errorMessage != null
              ? _buildError()
              : RefreshIndicator(
                  color: _blue,
                  onRefresh: _fetchAllData,
                  child: NestedScrollView(
                    headerSliverBuilder: (context, _) => [
                      SliverToBoxAdapter(child: _buildHeader()),
                    ],
                    body: Column(children: [
                      _buildTabBar(),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOverviewTab(),
                            _buildPersonalTab(),
                            _buildFamilyTab(),
                            _buildCompaniesTab(),
                            _buildDonationsTab(),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
    );
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: _dangerRed.withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.error_outline, size: 36, color: _dangerRed),
        ),
        const SizedBox(height: 16),
        Text(_errorMessage!, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: _textSecondary)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _fetchAllData,
          style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          child: const Text('Retry'),
        ),
      ]),
    ),
  );

  // ── Header: profile + chips + stats ───────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(children: [
            // Profile row
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              _buildAvatar(),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_donorName,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textPrimary)),
                const SizedBox(height: 3),
                Text('Donor ID: $_donorFtsId',
                    style: const TextStyle(fontSize: 12, color: _textSecondary)),
              ])),
            ]),

            const SizedBox(height: 14),

            // Status chips row
            Row(children: [
              _chip(_donorTypeValue != 'None' && _donorTypeValue.isNotEmpty ? _donorTypeValue : 'Donor',
                  outlined: true, color: _blue),
              const SizedBox(width: 8),
              _chip(_donorStatus, filled: true, color: _statusColor(_donorStatus)),
              const SizedBox(width: 8),
              _chip(_donorType, outlined: true, color: _typeColor(_donorType)),
            ]),

            const SizedBox(height: 20),

            // Total Donated hero card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: _bgGray,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _borderColor),
              ),
              child: Column(children: [
                const Text('Total Donated',
                    style: TextStyle(fontSize: 12, color: _textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Text(
                  '₹ ${_fmt(_totalDonated)}',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _blue,
                      letterSpacing: -0.5),
                ),
              ]),
            ),

            const SizedBox(height: 16),

            // 3-col quick stats
            Row(children: [
              Expanded(child: _quickStat('Receipts', _totalReceipts.toString(), _dangerRed, Icons.receipt_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _quickStat('Family', _familyDetails.length.toString(), _blue, Icons.people_outline)),
              const SizedBox(width: 10),
              Expanded(child: _quickStat('Membership', _membershipDetails.length.toString(), _warningOrange, Icons.card_membership_outlined)),
            ]),

            const SizedBox(height: 12),

            // 2×2 stat cards
            Row(children: [
              Expanded(child: _statCard2('Current Year Donations', '₹ 0', '0% Growth', Icons.trending_up, _blue)),
              const SizedBox(width: 10),
              Expanded(child: _statCard2('Last Year Donations', '₹ 0', 'Prev transaction', Icons.history, _textSecondary)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _statCard2('Largest Donations', '₹ ${_fmt(_largestDonation)}', 'Single transaction', Icons.emoji_events_outlined, _blue)),
              const SizedBox(width: 10),
              Expanded(child: _statCard2('Membership Value', '₹ ${_fmt(_membershipValue)}', 'Total membership', Icons.card_membership_outlined, _warningOrange)),
            ]),
            const SizedBox(height: 20),
          ]),
        ),
      ]),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 56, height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _borderColor, width: 2),
      ),
      child: ClipOval(
        child: Image.network(
          _profileImageUrl,
          width: 56, height: 56, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: _blue.withOpacity(0.1),
            child: Center(
              child: Text(_getInitials(_donorName),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _blue)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, {bool outlined = false, bool filled = false, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.08),
        border: Border.all(color: outlined ? color.withOpacity(0.4) : Colors.transparent),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: filled ? Colors.white : color)),
    );
  }

  Widget _quickStat(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(children: [
        Text(label, style: const TextStyle(fontSize: 11, color: _textSecondary)),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        ]),
      ]),
    );
  }

  Widget _statCard2(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 11, color: _textSecondary, height: 1.3)),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(child: Text(subtitle, style: const TextStyle(fontSize: 10, color: _textLight))),
          Icon(icon, size: 14, color: color.withOpacity(0.5)),
        ]),
      ]),
    );
  }

  // ── Tab Bar ────────────────────────────────────────────────────────────────
  Widget _buildTabBar() => Container(
    color: Colors.white,
    child: TabBar(
      controller: _tabController,
      isScrollable: true,
      labelColor: _blue,
      unselectedLabelColor: _textSecondary,
      indicatorColor: _blue,
      indicatorWeight: 2.5,
      labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
      tabs: _tabs.map((t) => Tab(text: t)).toList(),
    ),
  );

  // ── Shared UI helpers ──────────────────────────────────────────────────────
  Widget _card(Widget child) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _borderColor),
    ),
    child: child,
  );

  Widget _cardTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Text(title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textPrimary)),
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 140,
        child: Text(label, style: const TextStyle(fontSize: 12.5, color: _textSecondary)),
      ),
      Expanded(
        child: Text(
          (value.isNotEmpty && value != 'null') ? value : 'N/A',
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _textPrimary),
        ),
      ),
    ]),
  );

  Widget _sectionLabel(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(width: 3, height: 15, decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textPrimary)),
    ]),
  );

  String _fmt(double v) {
    if (v == 0) return '0';
    final n = NumberFormat('#,##,###').format(v.toInt());
    return n;
  }

  // ── Tabs ───────────────────────────────────────────────────────────────────
  Widget _buildOverviewTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardTitle('Personal Information'),
        _infoRow('Full Name', _donorName),
        _infoRow('Title', _donorTitle),
        _infoRow('Gender', _donorGender),
        _infoRow('Date of Birth', _dob),
        _infoRow('Date of Anniversary', _doa),
        _infoRow('PAN Number', _panNumber),
        _infoRow('Mobile Phone', _mobilePhone),
        _infoRow('Email', _email),
        _infoRow('Website', _website),
        _infoRow('Status', _donorStatus),
      ])),
      _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardTitle('Addresses'),
        _sectionLabel('Residence Address'),
        Text(_resAddress, style: const TextStyle(fontSize: 12.5, color: _textSecondary, height: 1.5)),
        const SizedBox(height: 14),
        _sectionLabel('Office Address'),
        Text(_offAddress, style: const TextStyle(fontSize: 12.5, color: _textSecondary, height: 1.5)),
      ])),
      _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardTitle('Other Details'),
        _infoRow('Donor Type', _donorTypeValue),
        _infoRow('Correspondence Pref', _correspondencePref),
        _infoRow('Is Promoter', _isPromoter),
        _infoRow('Promoter', _promoter),
        _infoRow('Source', _source),
        _infoRow('Belongs To', _belongsTo),
        _infoRow('CSR', _csr),
        _infoRow('Remarks', _remarks),
        _infoRow('Created By', _createdBy),
        _infoRow('Updated By', _updatedBy),
        _infoRow('Joining Date', _joiningDate),
      ])),
      if (_membershipDetails.isNotEmpty) _buildMembershipsCard(),
    ]),
  );

  Widget _buildPersonalTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(children: [
      _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardTitle('Personal Details'),
        _infoRow('Full Name', _donorName),
        _infoRow('Title', _donorTitle),
        _infoRow('Father Name', _fatherName),
        _infoRow('Mother Name', _motherName),
        _infoRow('Spouse Name', _spouseName),
        _infoRow('Gender', _donorGender),
        _infoRow('Date of Birth', _dob),
        _infoRow('Date of Anniversary', _doa),
        _infoRow('PAN Number', _panNumber),
        _infoRow('Remarks', _remarks),
      ])),
      _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardTitle('Communication Details'),
        _infoRow('Mobile Phone', _mobilePhone),
        _infoRow('WhatsApp', _whatsapp),
        _infoRow('Email', _email),
        _infoRow('Website', _website),
      ])),
    ]),
  );

  Widget _buildFamilyTab() {
    final all = [..._relatedGroup, ..._familyDetails];
    if (all.isEmpty) return _emptyState(Icons.family_restroom, 'No family members found');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: all.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final isRel = i < _relatedGroup.length;
        final m = all[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
          ),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: (isRel ? _warningOrange : _blue).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(isRel ? Icons.group : Icons.person_outline,
                  color: isRel ? _warningOrange : _blue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m['indicomp_full_name'] ?? 'N/A',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              if (isRel)
                const Text('Related Group Member',
                    style: TextStyle(fontSize: 11, color: _warningOrange))
              else if (m['indicomp_mobile_phone'] != null)
                Text(m['indicomp_mobile_phone'].toString(),
                    style: const TextStyle(fontSize: 12, color: _textSecondary)),
            ])),
          ]),
        );
      },
    );
  }

  Widget _buildCompaniesTab() {
    if (_companyDetails.isEmpty) return _emptyState(Icons.business_outlined, 'No companies found');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _companyDetails.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final c = _companyDetails[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
          ),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(color: _successGreen.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.business, color: _successGreen, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c['indicomp_full_name'] ?? 'N/A',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 3),
              Text(c['indicomp_type'] ?? 'Company',
                  style: const TextStyle(fontSize: 12, color: _textSecondary)),
            ])),
          ]),
        );
      },
    );
  }

  Widget _buildDonationsTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardTitle('Recent Donations'),
        _buildRecentDonations(),
      ])),
      _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardTitle('Upcoming Renewals'),
        _buildUpcomingRenewals(),
      ])),
      _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _cardTitle('Family Overview'),
        _buildFamilyOverview(),
      ])),
    ]),
  );

  // ── Donations helpers ──────────────────────────────────────────────────────
  Widget _buildRecentDonations() {
    if (_donorReceipts.isEmpty && _membershipDetails.isEmpty) {
      return _emptyInCard('No donations found');
    }
    List<Map<String, dynamic>> all = [
      ..._donorReceipts.map((r) => {
        'no': r['receipt_no']?.toString() ?? 'N/A',
        'date': r['receipt_date']?.toString() ?? '',
        'amount': double.tryParse(r['receipt_total_amount']?.toString() ?? '0') ?? 0.0,
        'type': 'Donation',
      }),
      ..._membershipDetails.map((m) => {
        'no': m['receipt_no']?.toString() ?? 'N/A',
        'date': m['receipt_date']?.toString() ?? '',
        'amount': double.tryParse(m['receipt_total_amount']?.toString() ?? '0') ?? 0.0,
        'type': 'Membership',
      }),
    ];
    all.sort((a, b) {
      try { return DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])); } catch (_) { return 0; }
    });
    return Column(children: all.map((t) => _donationRow(t)).toList());
  }

  Widget _donationRow(Map<String, dynamic> t) {
    final isMembership = t['type'] == 'Membership';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderColor.withOpacity(0.6))),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Row(children: [
            Text('Ref: ${t['no']}',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _blue)),
            const SizedBox(width: 10),
            const Icon(Icons.calendar_today_outlined, size: 11, color: _textLight),
            const SizedBox(width: 4),
            Text(_fd(t['date']), style: const TextStyle(fontSize: 11.5, color: _textSecondary)),
          ])),
          Text('₹${_fmt(t['amount'])}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _successGreen)),
        ]),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: (isMembership ? _warningOrange : _blue).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('Type: ${t['type']}',
              style: TextStyle(fontSize: 11, color: isMembership ? _warningOrange : _blue)),
        ),
      ]),
    );
  }

  Widget _buildUpcomingRenewals() {
    final cur = DateTime.now().year;
    final upcoming = _membershipDetails.where((m) {
      final v = m['m_ship_vailidity']?.toString() ?? '';
      final y = int.tryParse(v.contains('-') ? v.split('-')[0] : v);
      return y != null && y >= cur;
    }).toList();
    if (upcoming.isEmpty) return _emptyInCard('No upcoming renewals');
    return Column(children: upcoming.map((m) => _renewalRow(
      'Membership #${m['receipt_no']}',
      'Valid until: ${m['m_ship_vailidity'] ?? 'N/A'}',
      '₹${_fmt(double.tryParse(m['receipt_total_amount']?.toString() ?? '0') ?? 0)}',
    )).toList());
  }

  Widget _renewalRow(String title, String validity, String amount) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textPrimary)),
        const SizedBox(height: 3),
        Text(validity, style: const TextStyle(fontSize: 11.5, color: _textSecondary)),
      ])),
      Text(amount, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _warningOrange)),
    ]),
  );

  Widget _buildFamilyOverview() {
    final all = [..._relatedGroup, ..._familyDetails];
    if (all.isEmpty) return _emptyInCard('No family members found');
    return Column(children: all.map((m) {
      final name    = m['indicomp_full_name'] ?? 'N/A';
      final phone   = m['indicomp_mobile_phone']?.toString() ?? '';
      final email   = m['indicomp_email'] ?? '';
      final city    = m['indicomp_res_reg_city'] ?? '';
      final area    = m['indicomp_res_reg_area'] ?? '';
      final address = [area, city].where((s) => s.isNotEmpty).join(', ');
      final status  = m['indicomp_status'] ?? '';
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _bgGray, borderRadius: BorderRadius.circular(10),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _textPrimary)),
          const SizedBox(height: 8),
          if (phone.isNotEmpty) _iconRow(Icons.phone_outlined, phone),
          if (email.isNotEmpty) _iconRow(Icons.mail_outline, email),
          if (address.isNotEmpty) _iconRow(Icons.location_on_outlined, address),
          if (status.isNotEmpty) ...[
            const SizedBox(height: 6),
            RichText(text: TextSpan(children: [
              const TextSpan(text: 'Status: ',
                  style: TextStyle(fontSize: 12, color: _textSecondary, fontWeight: FontWeight.w500)),
              TextSpan(text: status,
                  style: TextStyle(fontSize: 12, color: _statusColor(status), fontWeight: FontWeight.w700)),
            ])),
          ],
        ]),
      );
    }).toList());
  }

  Widget _iconRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 13, color: _textSecondary),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: _textSecondary))),
    ]),
  );

  Widget _buildMembershipsCard() => _card(Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _cardTitle('Memberships'),
      ..._membershipDetails.map((m) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Membership #${m['receipt_no']}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text('Valid until: ${m['m_ship_vailidity'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 11.5, color: _textSecondary)),
          ])),
          Text('₹${_fmt(double.tryParse(m['receipt_total_amount']?.toString() ?? '0') ?? 0)}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _blue)),
        ]),
      )).toList(),
    ],
  ));

  Widget _emptyState(IconData icon, String msg) => Center(
    child: Padding(
      padding: const EdgeInsets.all(48),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 56, color: _textLight),
        const SizedBox(height: 14),
        Text(msg, style: const TextStyle(fontSize: 14, color: _textSecondary)),
      ]),
    ),
  );

  Widget _emptyInCard(String msg) => Container(
    padding: const EdgeInsets.symmetric(vertical: 28),
    alignment: Alignment.center,
    child: Text(msg, style: const TextStyle(fontSize: 13, color: _textSecondary)),
  );
}