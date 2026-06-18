import 'dart:convert';
import 'dart:io'; // Added for File operations
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart'; // Added for saving the CSV file
import 'package:bb/provider/auth_provider.dart'; // From your context

// --- Data Model ---
class MemberDetail {
  final int id;
  final String fullName;
  final String spouseName;
  final String phone;
  final String email;
  final String type;
  final String chapter;
  final String joinDate;
  final String validity;

  MemberDetail({
    required this.id,
    required this.fullName,
    required this.spouseName,
    required this.phone,
    required this.email,
    required this.type,
    required this.chapter,
    required this.joinDate,
    required this.validity,
  });

  factory MemberDetail.fromJson(Map<String, dynamic> json) {
    return MemberDetail(
      id: json['id'] ?? 0,
      fullName: json['indicomp_full_name'] ?? 'N/A',
      spouseName: json['indicomp_spouse_name'] ?? 'N/A',
      phone: json['indicomp_mobile_phone']?.toString() ?? 'N/A',
      email: json['indicomp_email'] ?? 'N/A',
      type: json['indicomp_type'] ?? 'N/A',
      chapter: json['chapter_name'] ?? 'N/A',
      joinDate: json['joining_date'] ?? 'N/A',
      validity: json['last_payment_date'] ?? json['joining_vailidity']?.toString() ?? 'N/A',
    );
  }
}

class AllMembersScreen extends StatefulWidget {
  @override
  _AllMembersScreenState createState() => _AllMembersScreenState();
}

class _AllMembersScreenState extends State<AllMembersScreen> {
  bool _isLoading = true;
  List<MemberDetail> _allMembers = [];
  List<MemberDetail> _filteredMembers = [];
  final TextEditingController _searchController = TextEditingController();

  // Colors based on UI design
  static const Color _bgColor = Color(0xFFF8F9FB);
  static const Color _primaryBlue = Color(0xFF4169E1);
  static const Color _labelBlue = Color(0xFF5A81FA); // Lighter blue for labels like "Spouse:"
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textGrey = Color(0xFF8A8FA8);

  @override
  void initState() {
    super.initState();
    _fetchMembersData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Optimize search for large lists
  void _onSearchChanged() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMembers = _allMembers;
      } else {
        _filteredMembers = _allMembers.where((member) {
          return member.fullName.toLowerCase().contains(query) ||
                 member.email.toLowerCase().contains(query) ||
                 member.phone.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _fetchMembersData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final String token = authProvider.token ?? '';

      final url = Uri.parse('https://agstest.in/api2/public/api/app-member-dashboard');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> memberList = data['data'] ?? [];

        List<MemberDetail> parsedMembers = memberList.map((m) => MemberDetail.fromJson(m)).toList();

        setState(() {
          _allMembers = parsedMembers;
          _filteredMembers = parsedMembers;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching members: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // --- NEW EXPORT LOGIC ADDED HERE ---
 Future<void> _exportToCSV() async {
    try {
      if (_allMembers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data available to export.')),
        );
        return;
      }

      // --- 1. REQUEST PERMISSION FIRST ---
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            // If the user denies permission, stop the process
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Storage permission is required to save the file.')),
            );
            return;
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating CSV File...')),
      );

      // --- 2. GENERATE CSV DATA ---
      String csvData = "S. No.,Full Name,Type,Spouse/Contact,Mobile,Email,Joining Date,Validity,Chapter\n";

      for (int i = 0; i < _allMembers.length; i++) {
        final m = _allMembers[i];
        
        String escape(String value) {
          if (value.contains(',')) {
            return '"$value"';
          }
          return value;
        }

        csvData += "${i + 1},"
            "${escape(m.fullName)},"
            "${escape(m.type)},"
            "${escape(m.spouseName)},"
            "${escape(m.phone)},"
            "${escape(m.email)},"
            "${escape(_formatDate(m.joinDate))},"
            "${escape(_formatDate(m.validity))},"
            "${escape(m.chapter)}\n";
      }

      // --- 3. SAVE THE FILE ---
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final String filePath = '${directory!.path}/All_Members_Export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final File file = File(filePath);
      
      await file.writeAsString(csvData);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File downloaded to: $filePath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  // ------------------------------------

  // Utility to mask phone numbers (e.g., 7984******)
  String _maskPhone(String phone) {
    if (phone == 'N/A' || phone.length < 5) return phone;
    return '${phone.substring(0, 4)}******';
  }

  // Utility to format dates from YYYY-MM-DD to DD-MM-YYYY
  String _formatDate(String dateStr) {
    if (dateStr == 'N/A' || !dateStr.contains('-')) return dateStr;
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return '${parts[2]}-${parts[1]}-${parts[0]}';
      }
    } catch (e) {
      return dateStr;
    }
    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'All Member',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_filteredMembers.length} members',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: _primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.file_download_outlined, color: Colors.white),
                    // -- CONNECTED EXPORT CSV FUNCTION HERE --
                    onPressed: () {
                      _exportToCSV(); 
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search Members...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          
          // List View (Optimized for Large Data)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _primaryBlue))
                : _filteredMembers.isEmpty
                    ? const Center(child: Text("No members found.", style: TextStyle(color: _textGrey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        itemCount: _filteredMembers.length,
                        // ListView.builder ensures memory optimization for 1700+ rows
                        itemBuilder: (context, index) {
                          return _buildMemberCard(_filteredMembers[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(MemberDetail member) {
    // Reusable text style for labels like "Spouse:", "Type:", "Chapter:"
    const labelStyle = TextStyle(color: _labelBlue, fontSize: 14, fontWeight: FontWeight.w400);
    const valueStyle = TextStyle(color: _textDark, fontSize: 14, fontWeight: FontWeight.w400);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name and "Email Sent" button row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  member.fullName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _primaryBlue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Email Sent',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Spouse Info
          RichText(
            text: TextSpan(
              text: 'Spouse: ',
              style: labelStyle,
              children: [
                TextSpan(text: member.spouseName, style: valueStyle),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Phone and Email Row
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 18, color: _labelBlue),
              const SizedBox(width: 6),
              Text(_maskPhone(member.phone), style: valueStyle),
              
              const SizedBox(width: 16), // Spacer between phone and email
              
              const Icon(Icons.mail_outline, size: 18, color: _labelBlue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  member.email, 
                  style: valueStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Type and Chapter Row
          Row(
            children: [
              RichText(
                text: TextSpan(
                  text: 'Type: ',
                  style: labelStyle,
                  children: [
                    TextSpan(text: member.type, style: valueStyle),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    text: 'Chapter: ',
                    style: labelStyle,
                    children: [
                      TextSpan(text: member.chapter, style: valueStyle),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Join Date and Validity Row
          Row(
            children: [
              RichText(
                text: TextSpan(
                  text: 'Join Date: ',
                  style: labelStyle,
                  children: [
                    TextSpan(text: _formatDate(member.joinDate), style: valueStyle),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    text: 'Validity: ',
                    style: labelStyle,
                    children: [
                      TextSpan(text: _formatDate(member.validity), style: valueStyle),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}