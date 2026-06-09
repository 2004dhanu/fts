import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:bb/provider/auth_provider.dart';
import 'package:bb/models/donor.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const String _baseUrl = 'https://agstest.in/api2/public/api';

const Color _primaryBlue   = Color(0xFF4169E1);
const Color _successGreen  = Color(0xFF10B981);
const Color _warningOrange = Color(0xFFF59E0B);
const Color _dangerRed     = Color(0xFFEF4444);
const Color _bgGray        = Color(0xFFF7F8FA);
const Color _cardWhite     = Color(0xFFFFFFFF);
const Color _textPrimary   = Color(0xFF1A1A2E);
const Color _textSecondary = Color(0xFF6B7280);
const Color _textLight     = Color(0xFF9CA3AF);
const Color _borderColor   = Color(0xFFE5E7EB);

// ─────────────────────────────────────────────────────────────────────────────
// DATA SOURCE MODEL
// ─────────────────────────────────────────────────────────────────────────────
class DataSource {
  final int id;
  final String name;
  DataSource({required this.id, required this.name});
  factory DataSource.fromJson(Map<String, dynamic> json) => DataSource(
    id: json['id'] ?? 0,
    name: json['data_source_type']?.toString() ?? json['name']?.toString() ?? '',
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// API SERVICE
// ─────────────────────────────────────────────────────────────────────────────
class ReceiptApiService {
  static Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  static Future<Map<String, dynamic>?> fetchReceiptControl(String token) async {
    try {
      final r = await http.get(Uri.parse('$_baseUrl/fetch-receipt-control'), headers: _headers(token));
      debugPrint('✅ Receipt Control: ${r.statusCode}');
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (e) { debugPrint('❌ fetchReceiptControl: $e'); }
    return null;
  }

  static Future<List<String>> fetchMembershipYears(String token) async {
    try {
      final r = await http.get(Uri.parse('$_baseUrl/fetch-membership-year'), headers: _headers(token));
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body);
        final data = body['data'] ?? body;
        if (data is List) return data.map((e) => e.toString()).toList();
      }
    } catch (e) { debugPrint('❌ fetchMembershipYears: $e'); }
    return ['2024-25', '2025-26', '2026-27'];
  }

  static Future<List<String>> fetchSchoolAllotmentYears(String token) async {
    try {
      final r = await http.get(Uri.parse('$_baseUrl/fetch-school-allotment-year'), headers: _headers(token));
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body);
        final data = body['data'] ?? body;
        if (data is List) return data.map((e) {
          if (e is Map) return e['school_allot_year']?.toString() ?? e.toString();
          return e.toString();
        }).toList();
      }
    } catch (e) { debugPrint('❌ fetchSchoolAllotmentYears: $e'); }
    return ['2024-25', '2025-26', '2026-27'];
  }

  static Future<List<DataSource>> fetchDataSources(String token) async {
    try {
      final r = await http.get(Uri.parse('$_baseUrl/data-source'), headers: _headers(token));
      if (r.statusCode == 200) {
        final body = jsonDecode(r.body);
        final data = body['data'] ?? body;
        if (data is List) return data.map((e) => DataSource.fromJson(e)).toList();
      }
    } catch (e) { debugPrint('❌ fetchDataSources: $e'); }
    return [];
  }

  static Future<Map<String, dynamic>> createReceipt(String token, Map<String, String> data) async {
    try {
      debugPrint('📝 Creating receipt: $data');
      final r = await http.post(Uri.parse('$_baseUrl/app-create-receipt'), headers: _headers(token), body: data);
      debugPrint('✅ Create Receipt: ${r.statusCode}');
      debugPrint('📦 Body: ${r.body}');
      if (r.statusCode == 200 || r.statusCode == 201) {
        final decoded = jsonDecode(r.body);
        if (decoded['code'] == 200 || decoded['success'] == true) {
          return {'success': true, 'data': decoded};
        }
        return {'success': false, 'message': decoded['message'] ?? 'Failed to create receipt'};
      }
      return {'success': false, 'message': 'Server error: ${r.statusCode}'};
    } catch (e, st) {
      debugPrint('❌ createReceipt: $e\n$st');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateDonorPan(String token, String donorId, String pan) async {
    try {
      final r = await http.put(Uri.parse('$_baseUrl/update-donor-panno/$donorId'),
          headers: _headers(token), body: {'indicomp_pan_no': pan});
      debugPrint('✅ Update PAN: ${r.statusCode}');
      return {'success': r.statusCode == 200};
    } catch (e) { debugPrint('❌ updateDonorPan: $e'); return {'success': false}; }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class CreateReceiptScreen extends StatefulWidget {
  final Donor donor;
  const CreateReceiptScreen({Key? key, required this.donor}) : super(key: key);

  @override
  State<CreateReceiptScreen> createState() => _CreateReceiptScreenState();
}

class _CreateReceiptScreenState extends State<CreateReceiptScreen> with WidgetsBindingObserver {
  // ── Page tracking ──────────────────────────────────────────────────────────
  int _page = 0; // 0 = page 1,  1 = page 2

  bool _isLoading = false;
  bool _showNoPanDialog = false;

  // ── Form fields ────────────────────────────────────────────────────────────
  bool   _isCsrDonation   = false;
  String? _selectedExemptionType;   // 80G / Non 80G / FCRA
  String? _selectedDonationType;    // OTS / General / Membership
  String? _selectedFinancialYear;
  String? _selectedSchoolAllotmentYear;
  String? _selectedMembershipValidity;
  String? _selectedTransactionMode;
  DataSource? _selectedSource;

  // Realization Date — 3 separate dropdowns
  String? _selDay;
  String? _selMonth;
  String? _selYear;

  final _receiptDateController        = TextEditingController();
  final _totalAmountController        = TextEditingController();
  final _transactionDetailsController = TextEditingController();
  final _remarksController            = TextEditingController();
  final _otsCountController           = TextEditingController();

  // ── Dropdown options ───────────────────────────────────────────────────────
  final List<String> _exemptionTypes  = ['80G', 'Non 80G', 'FCRA'];
  final List<String> _donationTypes   = ['OTS', 'General', 'Membership'];
  final List<String> _transactionModes = ['Cash', 'Cheque', 'Transfer', 'Other'];

  List<String>     _financialYears       = [];
  List<String>     _membershipYears      = [];
  List<String>     _schoolAllotmentYears = [];
  List<DataSource> _dataSources          = [];
  bool             _isLoadingDropdowns   = true;

  // Day / Month / Year lists
  final List<String> _days   = List.generate(31, (i) => (i + 1).toString().padLeft(2, '0'));
  final List<String> _months = ['01','02','03','04','05','06','07','08','09','10','11','12'];
  final List<String> _years  = List.generate(10, (i) => (DateTime.now().year - 5 + i).toString());

  // Helper to get display date (dd-MM-yyyy) for UI
  String get _displayDate {
    try {
      final date = DateTime.parse(_receiptDateController.text);
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (e) {
      return _receiptDateController.text;
    }
  }

  // Update current date to today
  void _updateCurrentDate() {
    final now = DateTime.now();
    final currentDate = DateFormat('yyyy-MM-dd').format(now);
    if (_receiptDateController.text != currentDate) {
      _receiptDateController.text = currentDate;
      if (mounted) setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateCurrentDate();
    _loadDropdownData();
    _checkPanAndShowDialog();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _updateCurrentDate();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _receiptDateController.dispose();
    _totalAmountController.dispose();
    _transactionDetailsController.dispose();
    _remarksController.dispose();
    _otsCountController.dispose();
    super.dispose();
  }

  Future<void> _loadDropdownData() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    try {
      final membershipYears = await ReceiptApiService.fetchMembershipYears(token);
      final schoolYears     = await ReceiptApiService.fetchSchoolAllotmentYears(token);
      final dataSources     = await ReceiptApiService.fetchDataSources(token);
      final cur = DateTime.now().year;
      final fy = [
        '${cur-1}-${cur.toString().substring(2)}',
        '$cur-${(cur+1).toString().substring(2)}',
        '${cur+1}-${(cur+2).toString().substring(2)}',
      ];
      if (mounted) setState(() {
        _membershipYears      = membershipYears;
        _schoolAllotmentYears = schoolYears;
        _dataSources          = dataSources;
        _financialYears       = fy;
        _selectedFinancialYear = fy[1];
        _isLoadingDropdowns   = false;
      });
    } catch (e) {
      debugPrint('Error loading dropdowns: $e');
      if (mounted) setState(() => _isLoadingDropdowns = false);
    }
  }

  void _checkPanAndShowDialog() {
    if (!_hasValidPan()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showNoPanWarningDialog());
    }
  }

  void _showNoPanWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('No PAN Card Available'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('The donor\'s PAN is missing. To issue an 80G receipt, a valid PAN is required.'),
          const SizedBox(height: 8),
          Text('Donor: ${widget.donor.displayName}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Please choose an option below:'),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: _dangerRed))),
          TextButton(onPressed: () { Navigator.pop(context); _showUpdatePanDialog(); },
              child: const Text('Update PAN', style: TextStyle(color: _primaryBlue))),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _continueWithoutPan(); },
            style: ElevatedButton.styleFrom(backgroundColor: _warningOrange),
            child: const Text('Continue without PAN'),
          ),
        ],
      ),
    );
  }

  void _showUpdatePanDialog() {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Update PAN Card'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Please enter the donor\'s PAN number:'),
        const SizedBox(height: 12),
        TextField(controller: ctrl,
            decoration: const InputDecoration(hintText: 'Enter PAN number', border: OutlineInputBorder()),
            textCapitalization: TextCapitalization.characters),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          if (ctrl.text.isNotEmpty) { Navigator.pop(context); await _updatePanNumber(ctrl.text); }
        }, child: const Text('Save')),
      ],
    ));
  }

  Future<void> _updatePanNumber(String pan) async {
    setState(() => _isLoading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    final result = await ReceiptApiService.updateDonorPan(token, widget.donor.id.toString(), pan);
    setState(() => _isLoading = false);
    if (result['success'] == true) _showSuccess('PAN updated successfully!');
    else _showError('Failed to update PAN');
  }

  void _continueWithoutPan() {
    _showNoPanDialog = true;
    _showSuccess('Continuing without PAN. Note: 80G receipts cannot be issued.');
  }

  bool _is80G()        => _selectedExemptionType == '80G';
  bool _hasValidPan()  => widget.donor.panNumber.isNotEmpty && widget.donor.panNumber != 'null';
  bool _isMembership() => _selectedDonationType == 'Membership';

  // Membership locks amount to 1000; Other transaction mode keeps field editable
  void _onDonationTypeSelected(String type) {
    setState(() {
      _selectedDonationType = type;
      if (type == 'Membership') {
        _totalAmountController.text = '1000';
      } else {
        // Only clear if it was previously set by membership auto-fill
        if (_totalAmountController.text == '1000') {
          _totalAmountController.clear();
        }
      }
    });
  }

 
  // ── Validation & submit ────────────────────────────────────────────────────
  bool _validatePage1() {
    if (_selectedExemptionType == null) { _showError('Please select a category'); return false; }
    if (_selectedDonationType  == null) { _showError('Please select a purpose');  return false; }
    if (_totalAmountController.text.isEmpty) { _showError('Please enter total amount'); return false; }
    if (_is80G() && !_hasValidPan() && !_showNoPanDialog) { _showNoPanWarningDialog(); return false; }
    return true;
  }

  bool _validatePage2() {
    if (_selectedTransactionMode == null) { _showError('Please select transaction type'); return false; }
    if (_selectedDonationType == 'OTS') {
      if (_otsCountController.text.isEmpty) { _showError('Please enter number of schools'); return false; }
      if (_selectedSchoolAllotmentYear == null) { _showError('Please select school allotment year'); return false; }
    }
    if (_selectedDonationType == 'General' && _is80G() && _selectedSchoolAllotmentYear == null) {
      _showError('Please select school allotment year'); return false;
    }
    if (_isMembership() && _selectedMembershipValidity == null) {
      _showError('Please select membership validity'); return false;
    }
    return true;
  }

  Future<void> _createReceipt() async {
    if (!_validatePage2()) return;

    // Build realization date string
    String realizationDate = '';
    if (_selDay != null && _selMonth != null && _selYear != null) {
      realizationDate = '$_selYear-$_selMonth-$_selDay';
    }

    setState(() => _isLoading = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    final Map<String, String> data = {
      'indicomp_fts_id'       : widget.donor.indicompFtsId,
      'receipt_date'          : _receiptDateController.text,
      'receipt_exemption_type': _selectedExemptionType!,
      'receipt_financial_year': _selectedFinancialYear!,
      'receipt_donation_type' : _selectedDonationType!,
      'receipt_total_amount'  : _totalAmountController.text,
      'receipt_tran_pay_mode' : _selectedTransactionMode!,
      'receipt_csr'           : _isCsrDonation ? 'Yes' : 'No',
      'with_out_panno'        : (!_hasValidPan() && _showNoPanDialog) ? 'Yes' : 'No',
    };
    if (_selectedSchoolAllotmentYear != null) data['schoolalot_year'] = _selectedSchoolAllotmentYear!;
    if (realizationDate.isNotEmpty)           data['receipt_realization_date'] = realizationDate;
    if (_selectedMembershipValidity != null)  data['m_ship_vailidity'] = _selectedMembershipValidity!;
    if (_otsCountController.text.isNotEmpty)  data['receipt_no_of_ots'] = _otsCountController.text;
    if (_transactionDetailsController.text.isNotEmpty) data['receipt_tran_pay_details'] = _transactionDetailsController.text;
    if (_remarksController.text.isNotEmpty)   data['receipt_remarks'] = _remarksController.text;
    if (_selectedSource != null)              data['donor_source'] = _selectedSource!.name;

    debugPrint('🚀 Submitting: $data');
    final result = await ReceiptApiService.createReceipt(token, data);
    setState(() => _isLoading = false);
    if (result['success'] == true) {
      _showSuccess('Receipt created successfully!');
      if (mounted) Navigator.pop(context, true);
    } else {
      _showError(result['message'] ?? 'Failed to create receipt');
    }
  }

  void _showError(String msg)   => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: _dangerRed));
  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: _successGreen));

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoadingDropdowns) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: _primaryBlue)));
    }
    return Scaffold(
      backgroundColor: _bgGray,
      appBar: AppBar(
        backgroundColor: _cardWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textPrimary),
          onPressed: () {
            if (_page == 1) setState(() => _page = 0);
            else Navigator.pop(context);
          },
        ),
        title: const Text('Create Receipt',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textPrimary)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _borderColor, height: 1),
        ),
      ),
      body: _page == 0 ? _buildPage1() : _buildPage2(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAGE 1
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPage1() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Donor card
      _donorCard(),
      const SizedBox(height: 16),

      // Date + Year row
      _dateYearRow(),
      const SizedBox(height: 14),

      // CSR checkbox
      _csrRow(),
      const SizedBox(height: 18),

      // Category
      _blueSectionLabel('Category'),
      const SizedBox(height: 10),
      _chipRow(_exemptionTypes, _selectedExemptionType, (v) => setState(() => _selectedExemptionType = v)),
      if (_is80G() && !_hasValidPan() && !_showNoPanDialog) ...[
        const SizedBox(height: 6),
        const Text('⚠️ PAN required for 80G receipts',
            style: TextStyle(fontSize: 11, color: _dangerRed)),
      ],
      const SizedBox(height: 18),

      // Purpose
      _blueSectionLabel('Purpose'),
      const SizedBox(height: 10),
      _chipRow(_donationTypes, _selectedDonationType, (v) => _onDonationTypeSelected(v!)),
      const SizedBox(height: 18),

      // Total Amount
      _blueSectionLabel('Total Amount'),
      const SizedBox(height: 10),
      _amountField(),
      const SizedBox(height: 32),

      // Next / Cancel
      _twoButtons(
        primary: 'Next',
        onPrimary: () { if (_validatePage1()) setState(() => _page = 1); },
        onCancel: () => Navigator.pop(context),
      ),
      const SizedBox(height: 16),
    ]),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // PAGE 2
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPage2() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // Dynamic fields (OTS count / school year / membership validity / source)
      ..._dynamicFields(),

      // Transaction Type
      _blueSectionLabel('Transaction Type'),
      const SizedBox(height: 10),
      _chipRow(_transactionModes, _selectedTransactionMode,
          (v) => setState(() => _selectedTransactionMode = v)),
      const SizedBox(height: 18),

      // Realization Date — 3 dropdowns
      _blueSectionLabel('Realization Date'),
      const SizedBox(height: 10),
      _realizationDateRow(),
      const SizedBox(height: 18),

      // Transaction Details
      _blueSectionLabel('Transaction Details'),
      const SizedBox(height: 10),
      _textArea(_transactionDetailsController,
          'Cheque No/ Bank Transfer/ UTR/ Any Other Details', 3),
      const SizedBox(height: 18),

      // Remarks
      _blueSectionLabel('Remarks'),
      const SizedBox(height: 10),
      _textArea(_remarksController, 'Additional remarks', 3),
      const SizedBox(height: 32),

      // Create Receipt / Cancel
      _twoButtons(
        primary: 'Create Receipt',
        onPrimary: _isLoading ? null : _createReceipt,
        onCancel: () => Navigator.pop(context),
        loading: _isLoading,
      ),
      const SizedBox(height: 16),
    ]),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // UI COMPONENTS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _donorCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _cardWhite,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _borderColor),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        '${widget.donor.displayName}(${widget.donor.indicompFtsId})',
        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: _textPrimary),
      ),
      const SizedBox(height: 10),
      Row(children: [
        const Icon(Icons.mail_outline, size: 15, color: _textLight),
        const SizedBox(width: 8),
        Expanded(child: Text(
          widget.donor.email.isNotEmpty ? widget.donor.email : 'No email',
          style: const TextStyle(fontSize: 13, color: _textSecondary),
        )),
      ]),
      const SizedBox(height: 6),
      Row(children: [
        const Icon(Icons.security_outlined, size: 15, color: _textLight),
        const SizedBox(width: 8),
        Text(
          _hasValidPan() ? 'PAN: ${widget.donor.panNumber}' : 'No PAN',
          style: TextStyle(fontSize: 13, color: _hasValidPan() ? _textSecondary : _dangerRed),
        ),
      ]),
    ]),
  );

  Widget _dateYearRow() => Row(children: [
    // Date (tappable) - displays in dd-MM-yyyy format for user
    Expanded(
      flex: 3,
      child: Container(
  padding: const EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 13,
  ),
  decoration: BoxDecoration(
    color: _cardWhite,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: _borderColor),
  ),
  child: Row(
    children: [
      const Icon(Icons.calendar_today,
          size: 16, color: _primaryBlue),
      const SizedBox(width: 8),
      Text(
        DateFormat('dd-MM-yyyy').format(DateTime.now()),
        style: const TextStyle(
          fontSize: 13,
          color: _textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  ),
),
    ),
    const SizedBox(width: 10),
    // Year pill
    GestureDetector(
      onTap: () => _showYearPicker(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _primaryBlue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _primaryBlue.withOpacity(0.3)),
        ),
        child: Text(
          _selectedFinancialYear ?? '----',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primaryBlue),
        ),
      ),
    ),
  ]);

  void _showYearPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardWhite,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SizedBox(
        height: 280,
        child: Column(children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: _borderColor, borderRadius: BorderRadius.circular(2))),
          const Text('Select Financial Year',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _financialYears.length,
              itemBuilder: (_, i) {
                final y = _financialYears[i];
                final sel = y == _selectedFinancialYear;
                return ListTile(
                  title: Text(y, style: TextStyle(
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                      color: sel ? _primaryBlue : _textPrimary)),
                  trailing: sel ? const Icon(Icons.check, color: _primaryBlue) : null,
                  onTap: () { setState(() => _selectedFinancialYear = y); Navigator.pop(context); },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _csrRow() => Row(children: [
    SizedBox(
      width: 20, height: 20,
      child: Checkbox(
        value: _isCsrDonation,
        onChanged: (v) => setState(() => _isCsrDonation = v ?? false),
        activeColor: _primaryBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: _borderColor, width: 1.5),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    const SizedBox(width: 10),
    const Text('This is a CSR Donation',
        style: TextStyle(fontSize: 13.5, color: _textPrimary, fontWeight: FontWeight.w500)),
  ]);

  Widget _blueSectionLabel(String label) => Text(
    label,
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _primaryBlue),
  );

  // Chip row — selected = blue fill, unselected = white with border
  Widget _chipRow(List<String> options, String? selected, ValueChanged<String?> onTap) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: options.map((opt) {
      final isSelected = opt == selected;
      return GestureDetector(
        onTap: () => onTap(opt),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? _primaryBlue : _cardWhite,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? _primaryBlue : _borderColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(opt, style: TextStyle(
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : _textPrimary,
          )),
        ),
      );
    }).toList(),
  );

  // Amount field — locked when Membership
  Widget _amountField() {
    final locked = _isMembership();
    return Container(
      decoration: BoxDecoration(
        color: locked ? const Color(0xFFF0F4FF) : _cardWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: locked ? _primaryBlue.withOpacity(0.3) : _borderColor),
      ),
      child: TextFormField(
        controller: _totalAmountController,
        readOnly: locked,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          fontSize: 14,
          color: locked ? _primaryBlue : _textPrimary,
          fontWeight: locked ? FontWeight.w600 : FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: 'Enter Amount',
          hintStyle: const TextStyle(fontSize: 13.5, color: _textLight),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          suffixIcon: locked
              ? const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.lock_outline, size: 16, color: _primaryBlue),
                )
              : null,
        ),
      ),
    );
  }

  // Realization Date — 3 dropdowns: Day | Month | Year
  Widget _realizationDateRow() => Row(children: [
    Expanded(child: _inlineDropdown('Day',   _days,   _selDay,   (v) => setState(() => _selDay   = v))),
    const SizedBox(width: 10),
    Expanded(child: _inlineDropdown('Month', _months, _selMonth, (v) => setState(() => _selMonth = v))),
    const SizedBox(width: 10),
    Expanded(child: _inlineDropdown('Year',  _years,  _selYear,  (v) => setState(() => _selYear  = v))),
  ]);

  Widget _inlineDropdown(String hint, List<String> items, String? value, ValueChanged<String?> onChange) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 46,
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 13, color: _textLight)),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, size: 18, color: _textLight),
          style: const TextStyle(fontSize: 13, color: _textPrimary),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChange,
        ),
      ),
    );

  Widget _textArea(TextEditingController ctrl, String hint, int lines) => Container(
    decoration: BoxDecoration(
      color: _cardWhite,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _borderColor),
    ),
    child: TextFormField(
      controller: ctrl,
      maxLines: lines,
      style: const TextStyle(fontSize: 13.5, color: _textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: _textLight),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(14),
      ),
    ),
  );

  // Primary blue button + outlined cancel
  Widget _twoButtons({
    required String primary,
    required VoidCallback? onPrimary,
    required VoidCallback onCancel,
    bool loading = false,
  }) => Row(children: [
    Expanded(
      child: ElevatedButton(
        onPressed: onPrimary,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          minimumSize: const Size(0, 48),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: loading
          ? const SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(primary, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: OutlinedButton(
        onPressed: onCancel,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _borderColor),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          minimumSize: const Size(0, 48),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('Cancel',
            style: TextStyle(fontSize: 15, color: _textSecondary, fontWeight: FontWeight.w500)),
      ),
    ),
  ]);

  // Dynamic fields for page 2 based on donation type
  List<Widget> _dynamicFields() {
    final widgets = <Widget>[];

    if (_selectedDonationType == 'OTS') {
      widgets.addAll([
        _blueSectionLabel('Number of Schools *'),
        const SizedBox(height: 10),
        _textInput('Enter number of schools', _otsCountController, TextInputType.number),
        const SizedBox(height: 18),
        _blueSectionLabel('School Allotment Year *'),
        const SizedBox(height: 10),
        _plainDropdown(_selectedSchoolAllotmentYear, _schoolAllotmentYears,
            (v) => setState(() => _selectedSchoolAllotmentYear = v), 'Select Year'),
        const SizedBox(height: 18),
      ]);
    }

    if (_selectedDonationType == 'General') {
      final label = _is80G() ? 'School Allotment Year *' : 'School Allotment Year (Optional)';
      widgets.addAll([
        _blueSectionLabel(label),
        const SizedBox(height: 10),
        _plainDropdown(_selectedSchoolAllotmentYear, _schoolAllotmentYears,
            (v) => setState(() => _selectedSchoolAllotmentYear = v), 'Select Year'),
        const SizedBox(height: 18),
      ]);
    }

    if (_selectedDonationType == 'Membership') {
      widgets.addAll([
        _blueSectionLabel('Membership Validity *'),
        const SizedBox(height: 10),
        _plainDropdown(_selectedMembershipValidity, _membershipYears,
            (v) => setState(() => _selectedMembershipValidity = v), 'Select Validity'),
        const SizedBox(height: 18),
      ]);
    }

    if (_selectedDonationType != null && _dataSources.isNotEmpty) {
      widgets.addAll([
        _blueSectionLabel('Source'),
        const SizedBox(height: 10),
        _dataSourceDropdown(),
        const SizedBox(height: 18),
      ]);
    }

    return widgets;
  }

  Widget _textInput(String hint, TextEditingController ctrl, TextInputType type) => Container(
    decoration: BoxDecoration(
      color: _cardWhite, borderRadius: BorderRadius.circular(10), border: Border.all(color: _borderColor),
    ),
    child: TextFormField(
      controller: ctrl, keyboardType: type,
      style: const TextStyle(fontSize: 13.5, color: _textPrimary),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(fontSize: 13, color: _textLight),
        border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
    ),
  );

  Widget _plainDropdown(String? value, List<String> items, ValueChanged<String?> onChange, String hint) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      height: 48,
      decoration: BoxDecoration(
        color: _cardWhite, borderRadius: BorderRadius.circular(10), border: Border.all(color: _borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 13, color: _textLight)),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: _textLight),
          style: const TextStyle(fontSize: 13, color: _textPrimary),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChange,
        ),
      ),
    );

  Widget _dataSourceDropdown() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    height: 48,
    decoration: BoxDecoration(
      color: _cardWhite, borderRadius: BorderRadius.circular(10), border: Border.all(color: _borderColor),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<DataSource>(
        value: _selectedSource,
        hint: const Text('Select Source', style: TextStyle(fontSize: 13, color: _textLight)),
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down, color: _textLight),
        style: const TextStyle(fontSize: 13, color: _textPrimary),
        items: _dataSources.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
        onChanged: (v) => setState(() => _selectedSource = v),
      ),
    ),
  );

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}