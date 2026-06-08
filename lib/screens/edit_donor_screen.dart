import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:bb/models/donor.dart';
import 'package:bb/provider/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS & THEME
// ─────────────────────────────────────────────────────────────────────────────
const String _baseUrl = 'https://agstest.in/api2/public/api';

const Color _blue        = Color(0xFF3B7DD8);
const Color _bgGray      = Color(0xFFF0F2F7);
const Color _borderColor = Color(0xFFD0D5DD);
const Color _labelColor  = Color(0xFF374151);
const Color _inputText   = Color(0xFF111827);

// ─────────────────────────────────────────────────────────────────────────────
// DONOR API SERVICE  (token injected at call time — no global constant)
// ─────────────────────────────────────────────────────────────────────────────
class DonorApiService {
  static Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  /// Fetch full donor detail by ID.
  static Future<Map<String, dynamic>?> fetchDonorById(
      String id, String token) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/app-fetch-donor-by-id/$id'),
        headers: _headers(token),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map<String, dynamic>) {
          return body['data'] ?? body['donor'] ?? body;
        }
      }
    } catch (e) {
      debugPrint('fetchDonorById error: $e');
    }
    return null;
  }

  /// Update donor via PUT multipart/form-data.
  static Future<bool> updateDonor(
  String id,
  Map<String, dynamic> data,
  String token,
) async {
  try {
    final uri = Uri.parse(
      '$_baseUrl/app-update-donor/$id',
    );

    final req = http.MultipartRequest(
      'POST',
      uri,
    );

    req.headers.addAll(_headers(token));

    // Laravel override
    req.fields['_method'] = 'PUT';

    _buildFieldMap(data).forEach((key, value) {
      if (value != null &&
          value.toString().trim().isNotEmpty) {
        req.fields[key] = value.toString();
      }
    });

    debugPrint('====================');
    debugPrint('UPDATE URL: $uri');
    debugPrint('DONOR ID: $id');
    debugPrint('TOKEN: $token');
    debugPrint('FIELDS:');
    req.fields.forEach((k, v) {
      debugPrint('$k = $v');
    });
    debugPrint('====================');

    final streamed = await req.send();

    final res =
        await http.Response.fromStream(streamed);

    debugPrint('STATUS CODE: ${res.statusCode}');
    debugPrint('RESPONSE BODY: ${res.body}');

    return res.statusCode == 200 ||
        res.statusCode == 201;
  } catch (e, s) {
    debugPrint('UPDATE ERROR: $e');
    debugPrint('STACK: $s');
    return false;
  }
}
  /// API field name → value map.
  static Map<String, String?> _buildFieldMap(Map<String, dynamic> d) => {
    'title':                        d['title'],
    'indicomp_full_name':           d['full_name'],
    'indicomp_father_name':         d['father_name'],
    'indicomp_mother_name':         d['mother_name'],
    'indicomp_gender':              d['gender'],
    'indicomp_spouse_name':         d['spouse_name'],
    'indicomp_dob_annualday':       d['date_of_birth'],
    'indicomp_doa':                 d['date_of_anniversary'],
    'indicomp_pan_no':              d['pan_number'],
    'indicomp_remarks':             d['remarks'],
    'indicomp_is_promoter':         d['is_promoter'],
    'indicomp_promoter':            d['promoter'],
    'indicomp_belongs_to':          d['belong_to'],
    'indicomp_source':              d['source'],
    'indicomp_donor_type':          d['donor_type'],
    'indicomp_type':                d['type'],
    'indicomp_mobile_phone':        d['mobile_phone'],
    'indicomp_mobile_whatsapp':     d['whatsapp'],
    'indicomp_email':               d['email'],
    'indicomp_website':             d['website'],
    'indicomp_res_reg_address':     d['res_house_street'],
    'indicomp_res_reg_area':        d['res_area'],
    'indicomp_res_reg_ladmark':     d['res_landmark'],
    'indicomp_res_reg_city':        d['res_city'],
    'indicomp_res_reg_state':       d['res_state'],
    'indicomp_res_reg_pin_code':    d['res_pincode'],
    'indicomp_off_branch_address':  d['off_house_street'],
    'indicomp_off_branch_area':     d['off_area'],
    'indicomp_off_branch_ladmark':  d['off_landmark'],
    'indicomp_off_branch_city':     d['off_city'],
    'indicomp_off_branch_state':    d['off_state'],
    'indicomp_off_branch_pin_code': d['off_pincode'],
    'indicomp_corr_preffer':        d['correspondence_pref'],
  };

  /// Convert a [Donor] model → internal form map so the form auto-fills.

/// Convert a [Donor] model → internal form map so the form auto-fills.
static Map<String, dynamic> fromDonorModel(Donor donor) {
  return {
    'id':                  donor.id,
    'title':               donor.title,
    'full_name':           donor.fullName,   // uses Donor.fullName, not displayName
    'father_name':         '',
    'mother_name':         '',
    'gender':              '',
    'spouse_name':         donor.spouseName,
    'date_of_birth':       '',
    'date_of_anniversary': '',
    'pan_number':          '',
    'remarks':             '',
    'is_promoter':         '',
    'promoter':            donor.promoter,
    'belong_to':           '',
    'source':              '',
    'donor_type':          '',
    'type':                donor.type,
    'mobile_phone':        donor.mobilePhone,
    'whatsapp':            '',
    'email':               donor.email,
    'website':             '',
    'res_house_street':    '',
    'res_area':            '',
    'res_landmark':        '',
    'res_city':            '',
    'res_state':           '',
    'res_pincode':         '',
    'off_house_street':    '',
    'off_area':            '',
    'off_landmark':        '',
    'off_city':            '',
    'off_state':           '',
    'off_pincode':         '',
    'correspondence_pref': 'Residence',
  };
}
  /// Fallback: map raw API response keys → internal form keys.
  static Map<String, dynamic> fromApiResponse(Map<String, dynamic> api) {
    return {
      'id':                  api['id']?.toString() ?? '',
      'title':               api['title'],
      'full_name':           api['indicomp_full_name'] ?? api['full_name'] ?? '',
      'father_name':         api['indicomp_father_name'] ?? '',
      'mother_name':         api['indicomp_mother_name'] ?? '',
      'gender':              api['indicomp_gender'],
      'spouse_name':         api['indicomp_spouse_name'] ?? '',
      'date_of_birth':       api['indicomp_dob_annualday'] ?? '',
      'date_of_anniversary': api['indicomp_doa'] ?? '',
      'pan_number':          api['indicomp_pan_no'] ?? '',
      'remarks':             api['indicomp_remarks'] ?? '',
      'is_promoter':         api['indicomp_is_promoter'],
      'promoter':            api['indicomp_promoter'],
      'belong_to':           api['indicomp_belongs_to'],
      'source':              api['indicomp_source'],
      'donor_type':          api['indicomp_donor_type'],
      'type':                api['indicomp_type'] ?? 'Individual',
      'mobile_phone':        api['indicomp_mobile_phone'] ?? '',
      'whatsapp':            api['indicomp_mobile_whatsapp'] ?? '',
      'email':               api['indicomp_email'] ?? '',
      'website':             api['indicomp_website'] ?? '',
      'res_house_street':    api['indicomp_res_reg_address'] ?? '',
      'res_area':            api['indicomp_res_reg_area'] ?? '',
      'res_landmark':        api['indicomp_res_reg_ladmark'] ?? '',
      'res_city':            api['indicomp_res_reg_city'] ?? '',
      'res_state':           api['indicomp_res_reg_state'],
      'res_pincode':         api['indicomp_res_reg_pin_code'] ?? '',
      'off_house_street':    api['indicomp_off_branch_address'] ?? '',
      'off_area':            api['indicomp_off_branch_area'] ?? '',
      'off_landmark':        api['indicomp_off_branch_ladmark'] ?? '',
      'off_city':            api['indicomp_off_branch_city'] ?? '',
      'off_state':           api['indicomp_off_branch_state'],
      'off_pincode':         api['indicomp_off_branch_pin_code'] ?? '',
      'correspondence_pref': api['indicomp_corr_preffer'] ?? 'Residence',
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EDIT DONOR SCREEN
// Takes a [Donor] model directly from the card list — no extra fetch needed.
// Falls back to fetching full detail if [fetchFullDetail] is true.
// ─────────────────────────────────────────────────────────────────────────────
class EditDonorScreen extends StatefulWidget {
  /// Pass the Donor model from the list card.
  final Donor donor;

  /// Set to true if you want to fetch the full detail record before showing the form.
  final bool fetchFullDetail;

  const EditDonorScreen({
    Key? key,
    required this.donor,
    this.fetchFullDetail = false,
  }) : super(key: key);

  @override
  State<EditDonorScreen> createState() => _EditDonorScreenState();
}

class _EditDonorScreenState extends State<EditDonorScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 4;

  final _page1Key = GlobalKey<FormState>();
  final _page2Key = GlobalKey<FormState>();
  final _page3Key = GlobalKey<FormState>();
  final _page4Key = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _fullName;
  late final TextEditingController _fatherName;
  late final TextEditingController _motherName;
  late final TextEditingController _spouseName;
  late final TextEditingController _panNumber;
  late final TextEditingController _remarks;
  late final TextEditingController _dobController;
  late final TextEditingController _anniversaryController;
  late final TextEditingController _mobilePhone;
  late final TextEditingController _whatsApp;
  late final TextEditingController _email;
  late final TextEditingController _website;
  late final TextEditingController _alternateMobile;
  late final TextEditingController _officePhone;
  late final TextEditingController _alternateMail;
  late final TextEditingController _resHouseStreet;
  late final TextEditingController _resArea;
  late final TextEditingController _resLandmark;
  late final TextEditingController _resCity;
  late final TextEditingController _resPincode;
  late final TextEditingController _offHouseStreet;
  late final TextEditingController _offArea;
  late final TextEditingController _offLandmark;
  late final TextEditingController _offCity;
  late final TextEditingController _offPincode;

  // Dropdown state
  String? _title;
  String? _gender;
  String? _isPromoter;
  String? _promoter;
  String? _belongTo;
  String? _source;
  String? _donorType;
  String  _type = 'Individual';
  String? _resState;
  String? _offState;
  String? _correspondencePref;

  bool _isSaving   = false;
  bool _isLoading  = true; // while optionally fetching full detail

  // Dropdown lists
  final List<String> _titles      = ['Mr.', 'Mrs.', 'Ms.', 'Dr.', 'Prof.', 'Kum'];
  final List<String> _genders     = ['Male', 'Female', 'Other'];
  final List<String> _yesNo       = ['Yes', 'No'];
  final List<String> _donorTypes  = ['Member', 'Donor', 'Member+Donor', 'None'];
  final List<String> _corrPref    = ['Residence', 'Office', 'Digital', 'Registered', 'Branch Office'];
  final List<String> _belongToList = ['Executive Committee', 'Mahila Samiti', 'Ekal Yuva', 'Functional Committee'];
  final List<String> _sourceList  = ['Referral', 'Website', 'Event', 'Other'];
  final List<String> _promoterList = ['Promoter A', 'Promoter B', 'Promoter C'];
  final List<String> _stateList   = [
    'Andhra Pradesh','Assam','Bihar','Delhi','Goa','Gujarat','Haryana',
    'Himachal Pradesh','Jharkhand','Karnataka','Kerala','Madhya Pradesh',
    'Maharashtra','Manipur','Meghalaya','Mizoram','Nagaland','Odisha',
    'Punjab','Rajasthan','Sikkim','Tamil Nadu','Telangana','Tripura',
    'Uttar Pradesh','Uttarakhand','West Bengal',
  ];

  String? _safeValue(String? val, List<String> list) =>
      (val != null && list.contains(val)) ? val : null;

  // ── Init ───────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initControllersEmpty();

    if (widget.fetchFullDetail) {
      // Fetch full detail then populate
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadFullDetail());
    } else {
      // Populate directly from the Donor model passed in
      _populateFromMap(DonorApiService.fromDonorModel(widget.donor));
      setState(() => _isLoading = false);
    }
  }

  void _initControllersEmpty() {
    _fullName              = TextEditingController();
    _fatherName            = TextEditingController();
    _motherName            = TextEditingController();
    _spouseName            = TextEditingController();
    _panNumber             = TextEditingController();
    _remarks               = TextEditingController();
    _dobController         = TextEditingController();
    _anniversaryController = TextEditingController();
    _mobilePhone           = TextEditingController();
    _whatsApp              = TextEditingController();
    _email                 = TextEditingController();
    _website               = TextEditingController();
    _alternateMobile       = TextEditingController();
    _officePhone           = TextEditingController();
    _alternateMail         = TextEditingController();
    _resHouseStreet        = TextEditingController();
    _resArea               = TextEditingController();
    _resLandmark           = TextEditingController();
    _resCity               = TextEditingController();
    _resPincode            = TextEditingController();
    _offHouseStreet        = TextEditingController();
    _offArea               = TextEditingController();
    _offLandmark           = TextEditingController();
    _offCity               = TextEditingController();
    _offPincode            = TextEditingController();
  }

  /// Fill all controllers from an internal-key map.
  void _populateFromMap(Map<String, dynamic> d) {
    _fullName.text              = d['full_name'] ?? '';
    _fatherName.text            = d['father_name'] ?? '';
    _motherName.text            = d['mother_name'] ?? '';
    _spouseName.text            = d['spouse_name'] ?? '';
    _panNumber.text             = d['pan_number'] ?? '';
    _remarks.text               = d['remarks'] ?? '';
    _dobController.text         = d['date_of_birth'] ?? '';
    _anniversaryController.text = d['date_of_anniversary'] ?? '';
    _mobilePhone.text           = d['mobile_phone'] ?? '';
    _whatsApp.text              = d['whatsapp'] ?? '';
    _email.text                 = d['email'] ?? '';
    _website.text               = d['website'] ?? '';
    _alternateMobile.text       = d['alternate_mobile'] ?? '';
    _officePhone.text           = d['office_phone'] ?? '';
    _alternateMail.text         = d['alternate_email'] ?? '';
    _resHouseStreet.text        = d['res_house_street'] ?? '';
    _resArea.text               = d['res_area'] ?? '';
    _resLandmark.text           = d['res_landmark'] ?? '';
    _resCity.text               = d['res_city'] ?? '';
    _resPincode.text            = d['res_pincode'] ?? '';
    _offHouseStreet.text        = d['off_house_street'] ?? '';
    _offArea.text               = d['off_area'] ?? '';
    _offLandmark.text           = d['off_landmark'] ?? '';
    _offCity.text               = d['off_city'] ?? '';
    _offPincode.text            = d['off_pincode'] ?? '';

    _title             = _safeValue(d['title']?.toString(), _titles);
    _gender            = _safeValue(d['gender']?.toString(), _genders);
    _isPromoter        = _safeValue(d['is_promoter']?.toString(), _yesNo);
    _promoter          = _safeValue(d['promoter']?.toString(), _promoterList);
    _belongTo          = _safeValue(d['belong_to']?.toString(), _belongToList);
    _source            = _safeValue(d['source']?.toString(), _sourceList);
    _donorType         = _safeValue(d['donor_type']?.toString(), _donorTypes);
    _type              = d['type']?.toString() ?? 'Individual';
    _resState          = _safeValue(d['res_state']?.toString(), _stateList);
    _offState          = _safeValue(d['off_state']?.toString(), _stateList);
    _correspondencePref = _safeValue(d['correspondence_pref']?.toString(), _corrPref) ?? 'Residence';
  }

  Future<void> _loadFullDetail() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    final id    = widget.donor.id?.toString() ?? '';

    final fullData = await DonorApiService.fetchDonorById(id, token);
    if (!mounted) return;

    setState(() {
      if (fullData != null) {
        _populateFromMap(DonorApiService.fromApiResponse(fullData));
      } else {
        // Fall back to what we already have from the list
        _populateFromMap(DonorApiService.fromDonorModel(widget.donor));
      }
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    for (final c in [
      _fullName, _fatherName, _motherName, _spouseName, _panNumber,
      _remarks, _dobController, _anniversaryController,
      _mobilePhone, _whatsApp, _email, _website, _alternateMobile,
      _officePhone, _alternateMail,
      _resHouseStreet, _resArea, _resLandmark, _resCity, _resPincode,
      _offHouseStreet, _offArea, _offLandmark, _offCity, _offPincode,
    ]) { c.dispose(); }
    _pageController.dispose();
    super.dispose();
  }

  // ── Navigation ─────────────────────────────────────────────────────────────
  void _goTo(int page) {
    _pageController.animateToPage(page,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() => _currentPage = page);
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0: return _page1Key.currentState?.validate() ?? true;
      case 1: return _page2Key.currentState?.validate() ?? true;
      case 2: return _page3Key.currentState?.validate() ?? true;
      case 3: return _page4Key.currentState?.validate() ?? true;
      default: return true;
    }
  }

  void _next() {
    if (_validateCurrentPage() && _currentPage < _totalPages - 1) {
      _goTo(_currentPage + 1);
    }
  }

  void _prev() { if (_currentPage > 0) _goTo(_currentPage - 1); }

  Map<String, dynamic> _collectData() => {
    'title':               _title,
    'full_name':           _fullName.text,
    'father_name':         _fatherName.text,
    'mother_name':         _motherName.text,
    'gender':              _gender,
    'spouse_name':         _spouseName.text,
    'date_of_birth':       _dobController.text,
    'date_of_anniversary': _anniversaryController.text,
    'pan_number':          _panNumber.text,
    'remarks':             _remarks.text,
    'is_promoter':         _isPromoter,
    'promoter':            _promoter,
    'belong_to':           _belongTo,
    'source':              _source,
    'donor_type':          _donorType,
    'type':                _type,
    'mobile_phone':        _mobilePhone.text,
    'whatsapp':            _whatsApp.text,
    'email':               _email.text,
    'website':             _website.text,
    'alternate_mobile':    _alternateMobile.text,
    'office_phone':        _officePhone.text,
    'alternate_email':     _alternateMail.text,
    'res_house_street':    _resHouseStreet.text,
    'res_area':            _resArea.text,
    'res_landmark':        _resLandmark.text,
    'res_city':            _resCity.text,
    'res_state':           _resState,
    'res_pincode':         _resPincode.text,
    'off_house_street':    _offHouseStreet.text,
    'off_area':            _offArea.text,
    'off_landmark':        _offLandmark.text,
    'off_city':            _offCity.text,
    'off_state':           _offState,
    'off_pincode':         _offPincode.text,
    'correspondence_pref': _correspondencePref,
  };

  // ── Update handler ─────────────────────────────────────────────────────────
  Future<void> _handleUpdate() async {
    bool allValid = true;
    for (final key in [_page1Key, _page2Key, _page3Key, _page4Key]) {
      if (!(key.currentState?.validate() ?? true)) allValid = false;
    }
    if (!allValid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill all required fields'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _isSaving = true);

    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    final id    = widget.donor.id?.toString() ?? '';
    final ok    = await DonorApiService.updateDonor(id, _collectData(), token);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Donor updated successfully!' : 'Update failed. Please try again.'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ));
      if (ok) Navigator.pop(context, true); // return true = list should refresh
    }
    final data = _collectData();

debugPrint('FORM DATA => $data');

await DonorApiService.updateDonor(
  id,
  data,
  token,
);
  }

  Future<void> _handleAttachToGroup() async {
    // TODO: implement attach-to-group API call
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attach to group coming soon')));
  }

  // ── Shared UI helpers ───────────────────────────────────────────────────────
  Widget _sectionHeader(IconData icon, String title) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(color: _blue, borderRadius: BorderRadius.circular(8)),
    child: Row(children: [
      Icon(icon, color: Colors.white, size: 18),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
    ]),
  );

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
    filled: true, fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    border:             OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _borderColor)),
    enabledBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _borderColor)),
    focusedBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _blue, width: 1.5)),
    errorBorder:        OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
  );

  Widget _label(String text, {bool required = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: RichText(text: TextSpan(
      text: text,
      style: const TextStyle(fontSize: 12.5, color: _labelColor, fontWeight: FontWeight.w500),
      children: required ? [const TextSpan(text: ' *', style: TextStyle(color: Colors.red))] : [],
    )),
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
        validator: required ? (v) => (v == null || v.isEmpty) ? '$label is required' : null : null,
      ),
    ],
  );

  Widget _readonlyField(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      _label(label),
      TextFormField(
        initialValue: value,
        readOnly: true,
        style: const TextStyle(fontSize: 13.5, color: Color(0xFF9CA3AF)),
        decoration: _dec(label),
      ),
    ],
  );

  Widget _dropdown<T>(String label, T? value, List<T> items,
      ValueChanged<T?> onChanged, {bool required = false}) =>
    Column(
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
              hint: Text('Select $label', style: const TextStyle(fontSize: 13.5, color: Color(0xFF9CA3AF))),
              isExpanded: true,
              icon: const Icon(Icons.unfold_more, size: 16, color: Color(0xFF9CA3AF)),
              style: const TextStyle(fontSize: 13.5, color: _inputText),
              items: items.map((e) => DropdownMenuItem<T>(value: e, child: Text(e.toString()))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );

  Widget _datePicker(String label, TextEditingController ctrl,
      {DateTime? initial, DateTime? last}) =>
    Column(
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
              ctrl.text = '${picked.day.toString().padLeft(2, '0')}-'
                          '${picked.month.toString().padLeft(2, '0')}-'
                          '${picked.year}';
            }
          },
        ),
      ],
    );

  Widget _grid4(List<Widget> cells) => Column(
    children: cells.expand((e) => [e, const SizedBox(height: 16)]).toList(),
  );

  Widget _grid2(List<Widget> cells) {
    final rows = <Widget>[];
    for (int i = 0; i < cells.length; i += 2) {
      final end = (i + 2 > cells.length) ? cells.length : i + 2;
      final row = List<Widget>.from(cells.sublist(i, end));
      while (row.length < 2) row.add(const SizedBox.shrink());
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 16));
      rows.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: row[0]),
        const SizedBox(width: 14),
        Expanded(child: row[1]),
      ]));
    }
    return Column(children: rows);
  }

  Widget _grid3(List<Widget> cells) {
    final rows = <Widget>[];
    for (int i = 0; i < cells.length; i += 3) {
      final end = (i + 3 > cells.length) ? cells.length : i + 3;
      final row = List<Widget>.from(cells.sublist(i, end));
      while (row.length < 3) row.add(const SizedBox.shrink());
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 16));
      rows.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: row[0]),
        const SizedBox(width: 14),
        Expanded(child: row[1]),
        const SizedBox(width: 14),
        Expanded(child: row[2]),
      ]));
    }
    return Column(children: rows);
  }

  // ── Stepper ────────────────────────────────────────────────────────────────
  static const _pageLabels = ['Personal', 'Communication', 'Residence', 'Office'];
  static const _pageIcons  = [
    Icons.person_outline, Icons.phone_outlined,
    Icons.home_outlined,  Icons.business_outlined,
  ];

  Widget _buildStepper() => Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
    child: Row(
      children: List.generate(_totalPages * 2 - 1, (i) {
        if (i.isOdd) {
          final completed = _currentPage > i ~/ 2;
          return Expanded(child: Container(height: 2, color: completed ? _blue : const Color(0xFFE5E7EB)));
        }
        final page = i ~/ 2;
        final isActive = page == _currentPage;
        final isDone   = page < _currentPage;
        return GestureDetector(
          onTap: () => _goTo(page),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 36, height: 36,
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
            Text(_pageLabels[page], style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? _blue : isDone ? const Color(0xFF374151) : const Color(0xFF9CA3AF),
            )),
          ]),
        );
      }),
    ),
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
          ElevatedButton.icon(
            onPressed: _next,
            icon: const Icon(Icons.arrow_forward, size: 15),
            label: const Text('Next', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size(80, 36),
            ),
          ),
      ],
    ),
  );

  // ── Pages ──────────────────────────────────────────────────────────────────
  Widget _buildPage1() => Form(
    key: _page1Key,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader(Icons.info_outline, 'Personal Details'),
        const SizedBox(height: 20),
        _grid4([
          _dropdown('Title', _title, _titles, (v) => setState(() => _title = v), required: true),
          _field('Full Name', _fullName, required: true),
          _field('Father Name', _fatherName),
          _field('Mother Name', _motherName),
        ]),
        const SizedBox(height: 16),
        _grid4([
          _dropdown('Gender', _gender, _genders, (v) => setState(() => _gender = v), required: true),
          _field('Spouse Name', _spouseName),
          _datePicker('Date of Birth', _dobController, initial: DateTime(1997, 7, 7)),
          _datePicker('Date of Anniversary', _anniversaryController,
              initial: DateTime(1996, 5, 28),
              last: DateTime.now().add(const Duration(days: 365 * 10))),
        ]),
        const SizedBox(height: 16),
        _grid4([
          _field('PAN Number', _panNumber),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            _label('Upload Image'),
            Container(
              height: 48,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: _borderColor)),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8))),
                  child: const Icon(Icons.image_outlined, size: 20, color: Color(0xFF6B7280)),
                ),
                const SizedBox(width: 10),
                const Text('Choose File', style: TextStyle(fontSize: 13, color: Color(0xFF374151))),
                const SizedBox(width: 8),
                Expanded(child: Text('No file chosen', style: TextStyle(fontSize: 12, color: Colors.grey[400]), overflow: TextOverflow.ellipsis)),
              ]),
            ),
          ]),
          _field('Remarks', _remarks),
          _dropdown('Is Promoter?', _isPromoter, _yesNo, (v) => setState(() => _isPromoter = v)),
        ]),
        const SizedBox(height: 16),
        _grid4([
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              _label('Promoter'),
              const Spacer(),
              const Text('Not in List!', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w500)),
            ]),
            Container(
              height: 48,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: _borderColor)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _promoter,
                  hint: const Text('Select Promoter', style: TextStyle(fontSize: 13.5, color: Color(0xFF9CA3AF))),
                  isExpanded: true,
                  icon: const Icon(Icons.unfold_more, size: 16, color: Color(0xFF9CA3AF)),
                  style: const TextStyle(fontSize: 13.5, color: _inputText),
                  items: _promoterList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _promoter = v),
                ),
              ),
            ),
          ]),
          _dropdown('Belong To', _belongTo, _belongToList, (v) => setState(() => _belongTo = v)),
          _dropdown('Source', _source, _sourceList, (v) => setState(() => _source = v)),
          _dropdown('Donor Type', _donorType, _donorTypes, (v) => setState(() => _donorType = v)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _readonlyField('Type', _type)),
          const Expanded(child: SizedBox()),
          const Expanded(child: SizedBox()),
          const Expanded(child: SizedBox()),
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
        _grid4([
          _field('Mobile Phone', _mobilePhone, keyboard: TextInputType.phone, required: true),
          _field('WhatsApp', _whatsApp, keyboard: TextInputType.phone),
          _field('Email', _email, keyboard: TextInputType.emailAddress),
          _field('Website', _website, keyboard: TextInputType.url),
        ]),
        const SizedBox(height: 16),
        _grid3([
          _field('Alternate Mobile', _alternateMobile, keyboard: TextInputType.phone),
          _field('Office Phone', _officePhone, keyboard: TextInputType.phone),
          _field('Alternate Email', _alternateMail, keyboard: TextInputType.emailAddress),
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
        _sectionHeader(Icons.location_on_outlined, 'Residence Address'),
        const SizedBox(height: 20),
        _grid4([
          _field('House & Street Number', _resHouseStreet),
          _field('Area', _resArea),
          _field('Landmark', _resLandmark),
          _field('City', _resCity, required: true),
        ]),
        const SizedBox(height: 16),
        _grid2([
          _dropdown('State', _resState, _stateList, (v) => setState(() => _resState = v), required: true),
          _field('Pincode', _resPincode, keyboard: TextInputType.number, required: true),
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
        _sectionHeader(Icons.business_center_outlined, 'Office Address'),
        const SizedBox(height: 20),
        _grid4([
          _field('Office & Street Number', _offHouseStreet),
          _field('Area', _offArea),
          _field('Landmark', _offLandmark),
          _field('City', _offCity),
        ]),
        const SizedBox(height: 16),
        _grid3([
          _dropdown('State', _offState, _stateList, (v) => setState(() => _offState = v)),
          _field('Pincode', _offPincode, keyboard: TextInputType.number),
          _dropdown('Correspondence Preference', _correspondencePref, _corrPref,
              (v) => setState(() => _correspondencePref = v), required: true),
        ]),
        const SizedBox(height: 28),
        Wrap(spacing: 10, runSpacing: 10, children: [
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _handleUpdate,
            icon: _isSaving
                ? const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.person_outline, size: 16),
            label: const Text('Update Donor', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue, foregroundColor: Colors.white, elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          ElevatedButton(
            onPressed: _isSaving ? null : _handleAttachToGroup,
            child: const Text('Attach to Group', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white, elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              minimumSize: const Size(0, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            child: const Text('Leave Group', style: TextStyle(fontSize: 13.5, color: Color(0xFF374151))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _borderColor),
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

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _bgGray,
      body: SafeArea(child: Column(children: [
        // Top header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: _blue.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.person_outline, color: _blue, size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Edit Individual Donor',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
              SizedBox(height: 2),
              Text('Update donor information and details',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ])),
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
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
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
      ])),
    );
  }
}