import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bb/provider/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS & THEME
// ─────────────────────────────────────────────────────────────────────────────
const String _baseUrl = 'https://agstest.in/api2/public/api';

const Color _blue = Color(0xFF3B7DD8);
const Color _bgGray = Color(0xFFF0F2F7);
const Color _borderColor = Color(0xFFD0D5DD);
const Color _labelColor = Color(0xFF374151);
const Color _inputText = Color(0xFF111827);

// ─────────────────────────────────────────────────────────────────────────────
// API SERVICE FOR COMPANY DONOR
// ─────────────────────────────────────────────────────────────────────────────
class CompanyDonorApiService {
  static Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  /// Fetch donor title dropdown
  static Future<List<Map<String, dynamic>>> fetchDonorTitle(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/app-fetch-donor-title'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['data'] ?? [];
        
        return data.map<Map<String, dynamic>>((item) {
          return {
            'id': item['honorific']?.toString() ?? '',
            'title': item['honorific']?.toString() ?? '',
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('fetchDonorTitle error: $e');
    }
    return [];
  }

  /// Fetch states dropdown
  static Future<List<Map<String, dynamic>>> fetchStates(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/panel-fetch-state'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['data'] ?? [];
        
        return data.map<Map<String, dynamic>>((item) {
          return {
            'id': item['id']?.toString() ?? '',
            'state_name': item['state_name']?.toString() ?? '',
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('fetchStates error: $e');
    }
    return [];
  }

  /// Fetch promoter active list
  static Future<List<Map<String, dynamic>>> fetchPromoterActive(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/promoter-active'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['data'] ?? [];
        
        return data.map<Map<String, dynamic>>((item) {
          return {
            'id': item['indicomp_fts_id']?.toString() ?? '',
            'name': item['indicomp_full_name']?.toString() ?? '',
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('fetchPromoterActive error: $e');
    }
    return [];
  }

  /// Fetch data source dropdown
  static Future<List<Map<String, dynamic>>> fetchDataSource(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/data-source'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['data'] ?? [];
        
        return data.map<Map<String, dynamic>>((item) {
          return {
            'id': item['id']?.toString() ?? '',
            'source_name': item['source_name']?.toString() ?? '',
          };
        }).toList();
      }
    } catch (e) {
      debugPrint('fetchDataSource error: $e');
    }
    return [];
  }

  /// Check donor duplicate
  static Future<Map<String, dynamic>?> checkDonorDuplicate(
    String token,
    String fullName,
    String mobilePhone, {
    String? id,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/app-check-donor-duplicate'),
      );
      request.headers.addAll(_headers(token));
      request.fields['indicomp_full_name'] = fullName;
      request.fields['indicomp_mobile_phone'] = mobilePhone;
      if (id != null && id.isNotEmpty) {
        request.fields['id'] = id;
      }

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      debugPrint('checkDonorDuplicate error: $e');
    }
    return null;
  }

  /// Create new company donor
  static Future<Map<String, dynamic>?> createCompanyDonor(
    String token,
    Map<String, dynamic> data,
    File? imageFile,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/app-create-donor'),
      );
      request.headers.addAll(_headers(token));

      // Add all fields
      data.forEach((key, value) {
        if (value != null && value.toString().trim().isNotEmpty) {
          request.fields[key] = value.toString();
        }
      });

      // Add image if present
      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'indicomp_image_logo',
            imageFile.path,
          ),
        );
      }

      debugPrint('====================');
      debugPrint('CREATE COMPANY DONOR URL: $_baseUrl/app-create-donor');
      debugPrint('FIELDS:');
      request.fields.forEach((k, v) {
        debugPrint('$k = $v');
      });
      debugPrint('====================');

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      debugPrint('STATUS CODE: ${res.statusCode}');
      debugPrint('RESPONSE BODY: ${res.body}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (e, s) {
      debugPrint('CREATE COMPANY DONOR ERROR: $e');
      debugPrint('STACK: $s');
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATE COMPANY DONOR SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class CreateCompanyDonorScreen extends StatefulWidget {
  const CreateCompanyDonorScreen({Key? key}) : super(key: key);

  @override
  State<CreateCompanyDonorScreen> createState() => _CreateCompanyDonorScreenState();
}

class _CreateCompanyDonorScreenState extends State<CreateCompanyDonorScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 4;

  final _page1Key = GlobalKey<FormState>();
  final _page2Key = GlobalKey<FormState>();
  final _page3Key = GlobalKey<FormState>();
  final _page4Key = GlobalKey<FormState>();

  // Text Controllers
  late final TextEditingController _companyName;
  late final TextEditingController _contactName;
  late final TextEditingController _designation;
  late final TextEditingController _panNumber;
  late final TextEditingController _remarks;
  late final TextEditingController _annualDayController;
  late final TextEditingController _mobilePhone;
  late final TextEditingController _whatsApp;
  late final TextEditingController _email;
  late final TextEditingController _website;
  late final TextEditingController _regHouseStreet;
  late final TextEditingController _regArea;
  late final TextEditingController _regLandmark;
  late final TextEditingController _regCity;
  late final TextEditingController _regPincode;
  late final TextEditingController _branchHouseStreet;
  late final TextEditingController _branchArea;
  late final TextEditingController _branchLandmark;
  late final TextEditingController _branchCity;
  late final TextEditingController _branchPincode;

  // Dropdown values
  String? _companyType;
  String? _title;
  String? _gender;
  String? _isPromoter;
  String? _promoterId;
  String? _belongTo;
  String? _sourceId;
  String? _donorType;
  String? _csr;
  String? _regState;
  String? _branchState;
  String? _correspondencePref;

  // Lists from APIs
  List<Map<String, dynamic>> _titles = [];
  List<Map<String, dynamic>> _states = [];
  List<Map<String, dynamic>> _promoters = [];
  List<Map<String, dynamic>> _sources = [];

  File? _imageFile;
  bool _isCreating = false;
  bool _isLoading = true;
  bool _isCheckingDuplicate = false;

  // Dropdown options from API documentation (fixed values)
  final List<String> _companyTypes = ['Private', 'Public', 'PSU', 'Trust', 'Society', 'Others'];
  final List<String> _genders = ['Male', 'Female'];
  final List<String> _yesNo = ['Yes', 'No'];
  final List<String> _donorTypes = ['Member', 'Donor', 'Member+Donor', 'None'];
  final List<String> _csrOptions = ['Yes', 'No'];
  final List<String> _corrPref = ['Registered', 'Office', 'Digital', 'Branch Office'];
  final List<String> _belongToList = ['Executive Committee', 'Mahila Samiti', 'Ekal Yuva', 'Functional Committee'];

  @override
  void initState() {
    super.initState();
    _initControllers();
    _loadDropdownData();
  }

  void _initControllers() {
    _companyName = TextEditingController();
    _contactName = TextEditingController();
    _designation = TextEditingController();
    _panNumber = TextEditingController();
    _remarks = TextEditingController();
    _annualDayController = TextEditingController();
    _mobilePhone = TextEditingController();
    _whatsApp = TextEditingController();
    _email = TextEditingController();
    _website = TextEditingController();
    _regHouseStreet = TextEditingController();
    _regArea = TextEditingController();
    _regLandmark = TextEditingController();
    _regCity = TextEditingController();
    _regPincode = TextEditingController();
    _branchHouseStreet = TextEditingController();
    _branchArea = TextEditingController();
    _branchLandmark = TextEditingController();
    _branchCity = TextEditingController();
    _branchPincode = TextEditingController();
  }

  Future<void> _loadDropdownData() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';

    final results = await Future.wait([
      CompanyDonorApiService.fetchDonorTitle(token),
      CompanyDonorApiService.fetchStates(token),
      CompanyDonorApiService.fetchPromoterActive(token),
      CompanyDonorApiService.fetchDataSource(token),
    ]);

    if (mounted) {
      setState(() {
        _titles = results[0];
        _states = results[1];
        _promoters = results[2];
        _sources = results[3];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    for (final c in [
      _companyName, _contactName, _designation, _panNumber, _remarks, _annualDayController,
      _mobilePhone, _whatsApp, _email, _website,
      _regHouseStreet, _regArea, _regLandmark, _regCity, _regPincode,
      _branchHouseStreet, _branchArea, _branchLandmark, _branchCity, _branchPincode,
    ]) {
      c.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage = page);
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0:
        return _page1Key.currentState?.validate() ?? true;
      case 1:
        return _page2Key.currentState?.validate() ?? true;
      case 2:
        return _page3Key.currentState?.validate() ?? true;
      case 3:
        return _page4Key.currentState?.validate() ?? true;
      default:
        return true;
    }
  }

  void _next() {
    if (_validateCurrentPage() && _currentPage < _totalPages - 1) {
      _goTo(_currentPage + 1);
    }
  }

  void _prev() {
    if (_currentPage > 0) _goTo(_currentPage - 1);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<bool> _checkDuplicate() async {
    if (_companyName.text.isEmpty || _mobilePhone.text.isEmpty) return true;

    setState(() => _isCheckingDuplicate = true);

    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    final result = await CompanyDonorApiService.checkDonorDuplicate(
      token,
      _companyName.text,
      _mobilePhone.text,
    );

    setState(() => _isCheckingDuplicate = false);

    if (result != null && result['status'] == 'duplicate') {
      if (mounted) {
        final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Duplicate Found'),
            content: Text(
              'A company with name "${_companyName.text}" and mobile "${_mobilePhone.text}" already exists.\n\n'
              'Do you want to continue creating?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Continue', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        return shouldContinue ?? false;
      }
      return false;
    }
    return true;
  }

  Map<String, dynamic> _collectData() {
    return {
      // Company Details
      'indicomp_full_name': _companyName.text,
      'indicomp_type': _companyType,
      'title': _title,
      'indicomp_com_contact_name': _contactName.text,
      'indicomp_com_contact_designation': _designation.text,
      'indicomp_gender': _gender,
      'indicomp_doa': _annualDayController.text,
      'indicomp_pan_no': _panNumber.text,
      'indicomp_remarks': _remarks.text,
      'indicomp_is_promoter': _isPromoter ?? 'No',
      'indicomp_promoter': _promoterId,
      'indicomp_belongs_to': _belongTo,
      'indicomp_source': _sourceId,
      'indicomp_donor_type': _donorType,
      'indicomp_csr': _csr ?? 'No',
      
      // Communication Details
      'indicomp_mobile_phone': _mobilePhone.text,
      'indicomp_mobile_whatsapp': _whatsApp.text,
      'indicomp_email': _email.text,
      'indicomp_website': _website.text,
      
      // Registered Address
      'indicomp_res_reg_address': _regHouseStreet.text,
      'indicomp_res_reg_area': _regArea.text,
      'indicomp_res_reg_ladmark': _regLandmark.text,
      'indicomp_res_reg_city': _regCity.text,
      'indicomp_res_reg_state': _regState,
      'indicomp_res_reg_pin_code': _regPincode.text,
      
      // Branch Office Address
      'indicomp_off_branch_address': _branchHouseStreet.text,
      'indicomp_off_branch_area': _branchArea.text,
      'indicomp_off_branch_ladmark': _branchLandmark.text,
      'indicomp_off_branch_city': _branchCity.text,
      'indicomp_off_branch_state': _branchState,
      'indicomp_off_branch_pin_code': _branchPincode.text,
      
      // Correspondence Preference
      'indicomp_corr_preffer': _correspondencePref ?? 'Registered',
    };
  }

  Future<void> _handleCreate() async {
    // Validate all pages
    bool allValid = true;
    for (final key in [_page1Key, _page2Key, _page3Key, _page4Key]) {
      if (!(key.currentState?.validate() ?? true)) allValid = false;
    }

    if (!allValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check for duplicates
    final isUnique = await _checkDuplicate();
    if (!isUnique) return;

    setState(() => _isCreating = true);

    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    final result = await CompanyDonorApiService.createCompanyDonor(
      token,
      _collectData(),
      _imageFile,
    );

    if (mounted) {
      setState(() => _isCreating = false);

      if (result != null && (result['status'] == 'success' || result['success'] == true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company donor created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final errorMsg = result?['message'] ?? 'Failed to create company donor. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // UI Helpers
  Widget _sectionHeader(IconData icon, String title) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: _blue,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(children: [
      Icon(icon, color: Colors.white, size: 18),
      const SizedBox(width: 10),
      Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ]),
  );

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: _blue, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Colors.red, width: 1.5),
    ),
  );

  Widget _label(String text, {bool required = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 12.5, color: _labelColor, fontWeight: FontWeight.w500),
        children: required
            ? [const TextSpan(text: ' *', style: TextStyle(color: Colors.red))]
            : [],
      ),
    ),
  );

  Widget _field(String label, TextEditingController ctrl, {
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    bool required = false,
    int maxLines = 1,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      _label(label, required: required),
      TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        inputFormatters: formatters,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 13.5, color: _inputText),
        decoration: _dec(label),
        validator: required
            ? (v) => (v == null || v.isEmpty) ? '$label is required' : null
            : null,
      ),
    ],
  );

  Widget _dropdownFromList<T>(String label, T? value, List<T> items,
      ValueChanged<T?> onChanged, {bool required = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      _label(label, required: required),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _borderColor),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        height: 48,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            hint: Text(
              'Select $label',
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF9CA3AF)),
            ),
            isExpanded: true,
            icon: const Icon(Icons.unfold_more, size: 16, color: Color(0xFF9CA3AF)),
            style: const TextStyle(fontSize: 13.5, color: _inputText),
            items: items.map((e) => DropdownMenuItem<T>(
              value: e,
              child: Text(e.toString()),
            )).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ],
  );

  Widget _apiDropdown(
    String label,
    String? value,
    List<Map<String, dynamic>> items,
    String valueKey,
    String displayKey,
    ValueChanged<String?> onChanged, {
    bool required = false,
  }) {
    final validItems = items.where((item) {
      final val = item[valueKey]?.toString() ?? '';
      return val.isNotEmpty;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _label(label, required: required),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _borderColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          height: 48,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                'Select $label',
                style: const TextStyle(fontSize: 13.5, color: Color(0xFF9CA3AF)),
              ),
              isExpanded: true,
              icon: const Icon(Icons.unfold_more, size: 16, color: Color(0xFF9CA3AF)),
              style: const TextStyle(fontSize: 13.5, color: _inputText),
              items: validItems.map((item) {
                final display = item[displayKey]?.toString() ?? '';
                final val = item[valueKey]?.toString() ?? '';
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(display),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _datePicker(String label, TextEditingController ctrl,
      {DateTime? initial, DateTime? last}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      _label(label),
      TextFormField(
        controller: ctrl,
        readOnly: true,
        style: const TextStyle(fontSize: 13.5, color: _inputText),
        decoration: _dec(label).copyWith(
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF9CA3AF)),
        ),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: initial ?? DateTime(1997),
            firstDate: DateTime(1900),
            lastDate: last ?? DateTime.now(),
          );
          if (picked != null) {
            ctrl.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
          }
        },
      ),
    ],
  );

  Widget _imagePicker() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      _label('Upload Company Logo'),
      GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _borderColor),
          ),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: const Icon(Icons.business_outlined, size: 20, color: Color(0xFF6B7280)),
            ),
            const SizedBox(width: 10),
            const Text(
              'Choose File',
              style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _imageFile != null ? _imageFile!.path.split('/').last : 'No file chosen',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ]),
        ),
      ),
    ],
  );

  Widget _navButtons({bool showPrev = true, bool showNext = true}) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (showPrev)
          OutlinedButton.icon(
            onPressed: _prev,
            icon: const Icon(Icons.arrow_back, size: 15),
            label: const Text('Previous', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: _labelColor,
              side: const BorderSide(color: _borderColor),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size(0, 36),
            ),
          )
        else
          const SizedBox.shrink(),
       if (showNext)
  Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      gradient: const LinearGradient(
        colors: [
       
          Color(0xFF4074DA),
          Color(0xFF153C89),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(
        color: Colors.white24,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF4074DA).withOpacity(0.25),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: ElevatedButton.icon(
      onPressed: _next,
      icon: const Icon(Icons.arrow_forward, size: 15),
      label: const Text(
        'Next',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        minimumSize: const Size(80, 36),
      ),
    ),
  ),
      ],
    ),
  );

  // Page Builders
  Widget _buildPage1() => Form(
    key: _page1Key,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader(Icons.business_outlined, 'Company Details'),
        const SizedBox(height: 20),
        Column(children: [
          _field('Company Name', _companyName, required: true),
          const SizedBox(height: 16),
          _dropdownFromList('Company Type', _companyType, _companyTypes,
              (v) => setState(() => _companyType = v), required: true),
          const SizedBox(height: 16),
          _apiDropdown('Title', _title, _titles, 'id', 'title',
              (v) => setState(() => _title = v)),
          const SizedBox(height: 16),
          _field('Contact Name', _contactName, required: true),
          const SizedBox(height: 16),
          _field('Designation', _designation),
          const SizedBox(height: 16),
          _dropdownFromList('Gender', _gender, _genders,
              (v) => setState(() => _gender = v), required: true),
          const SizedBox(height: 16),
          _datePicker('Annual Day', _annualDayController),
          const SizedBox(height: 16),
          _field('PAN Number', _panNumber, required: true),
          const SizedBox(height: 16),
          _imagePicker(),
          const SizedBox(height: 16),
          _field('Remarks', _remarks),
          const SizedBox(height: 16),
          _dropdownFromList('Is Promoter?', _isPromoter, _yesNo,
              (v) => setState(() => _isPromoter = v)),
          const SizedBox(height: 16),
          _apiDropdown('Promoter', _promoterId, _promoters, 'id', 'name',
              (v) => setState(() => _promoterId = v)),
          const SizedBox(height: 16),
          _dropdownFromList('Belong To', _belongTo, _belongToList,
              (v) => setState(() => _belongTo = v)),
          const SizedBox(height: 16),
          _apiDropdown('Source', _sourceId, _sources, 'id', 'source_name',
              (v) => setState(() => _sourceId = v)),
          const SizedBox(height: 16),
          _dropdownFromList('Donor Type', _donorType, _donorTypes,
              (v) => setState(() => _donorType = v)),
          const SizedBox(height: 16),
          _dropdownFromList('CSR', _csr, _csrOptions,
              (v) => setState(() => _csr = v)),
        ]),
        const SizedBox(height: 24),
        _navButtons(showPrev: false),
      ]),
    ),
  );

  Widget _buildPage2() => Form(
    key: _page2Key,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader(Icons.phone_outlined, 'Communication Details'),
        const SizedBox(height: 20),
        Column(children: [
          _field('Mobile Phone', _mobilePhone,
              keyboard: TextInputType.phone, required: true),
          const SizedBox(height: 16),
          _field('WhatsApp', _whatsApp, keyboard: TextInputType.phone),
          const SizedBox(height: 16),
          _field('Email', _email, keyboard: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _field('Website', _website, keyboard: TextInputType.url),
        ]),
        const SizedBox(height: 24),
        _navButtons(),
      ]),
    ),
  );

  Widget _buildPage3() => Form(
    key: _page3Key,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader(Icons.location_on_outlined, 'Registered Address'),
        const SizedBox(height: 20),
        Column(children: [
          _field('House & Street Number', _regHouseStreet),
          const SizedBox(height: 16),
          _field('Area', _regArea),
          const SizedBox(height: 16),
          _field('Landmark', _regLandmark),
          const SizedBox(height: 16),
          _field('City', _regCity, required: true),
          const SizedBox(height: 16),
          _apiDropdown('State', _regState, _states, 'id', 'state_name',
              (v) => setState(() => _regState = v), required: true),
          const SizedBox(height: 16),
          _field('Pincode', _regPincode,
              keyboard: TextInputType.number, required: true),
        ]),
        const SizedBox(height: 24),
        _navButtons(),
      ]),
    ),
  );

  Widget _buildPage4() => Form(
    key: _page4Key,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader(Icons.business_center_outlined, 'Branch Office Address'),
        const SizedBox(height: 20),
        Column(children: [
          _field('Office & Street Number', _branchHouseStreet),
          const SizedBox(height: 16),
          _field('Area', _branchArea),
          const SizedBox(height: 16),
          _field('Landmark', _branchLandmark),
          const SizedBox(height: 16),
          _field('City', _branchCity),
          const SizedBox(height: 16),
          _apiDropdown('State', _branchState, _states, 'id', 'state_name',
              (v) => setState(() => _branchState = v)),
          const SizedBox(height: 16),
          _field('Pincode', _branchPincode, keyboard: TextInputType.number),
          const SizedBox(height: 16),
          _dropdownFromList('Correspondence Preference', _correspondencePref, _corrPref,
              (v) => setState(() => _correspondencePref = v), required: true),
        ]),
        const SizedBox(height: 28),
        Wrap(spacing: 10, runSpacing: 10, children: [
          ElevatedButton.icon(
            onPressed: _isCreating ? null : _handleCreate,
            icon: _isCreating
                ? const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.business, size: 16),
            label: const Text('Create Company', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          OutlinedButton(
            onPressed: () => Navigator.maybePop(context),
            child: const Text('Cancel', style: TextStyle(fontSize: 13.5, color: Color(0xFF374151))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _borderColor),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _prev,
          icon: const Icon(Icons.arrow_back, size: 15, color: Color(0xFF6B7280)),
          label: const Text('Previous', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          style: TextButton.styleFrom(minimumSize: const Size(0, 36)),
        ),
        const SizedBox(height: 8),
      ]),
    ),
  );

  // Stepper
  static const _pageLabels = ['Company', 'Communication', 'Registered', 'Branch'];
  static const _pageIcons = [
    Icons.business_outlined,
    Icons.phone_outlined,
    Icons.location_on_outlined,
    Icons.business_center_outlined,
  ];

  Widget _buildStepper() => Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
    child: Row(
      children: List.generate(_totalPages * 2 - 1, (i) {
        if (i.isOdd) {
          final completed = _currentPage > i ~/ 2;
          return Expanded(
            child: Container(height: 2, color: completed ? _blue : const Color(0xFFE5E7EB)),
          );
        }
        final page = i ~/ 2;
        final isActive = page == _currentPage;
        final isDone = page < _currentPage;
        return GestureDetector(
          onTap: () => _goTo(page),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isActive || isDone) ? _blue : const Color(0xFFE5E7EB),
              ),
              child: isDone
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Icon(_pageIcons[page],
                      color: isActive ? Colors.white : const Color(0xFF9CA3AF), size: 16),
            ),
            const SizedBox(height: 4),
            Text(_pageLabels[page],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive
                      ? _blue
                      : isDone
                          ? const Color(0xFF374151)
                          : const Color(0xFF9CA3AF),
                )),
          ]),
        );
      }),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _bgGray,
      body: SafeArea(
        child: Column(children: [
          // Top header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.business, color: _blue, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Add Company Donor',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                  SizedBox(height: 2),
                  Text('Create a new company donor record',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ]),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back, size: 14),
                label: const Text('Back', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _labelColor,
                  side: const BorderSide(color: _borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ]),
          ),

          _buildStepper(),

          Expanded(
            child: Container(
              margin: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: [
                    _buildPage1(),
                    _buildPage2(),
                    _buildPage3(),
                    _buildPage4(),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}