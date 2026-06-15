import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:bb/provider/auth_provider.dart'; // Ensure this matches your project path

// --- Data Model ---
class InactiveMember {
  final int id;
  final String fullName;
  final String donorType;
  final String phone;
  final String email;
  final String type;
  final String chapter;
  final String lastPayDate;
  final String payCount;

  InactiveMember({
    required this.id,
    required this.fullName,
    required this.donorType,
    required this.phone,
    required this.email,
    required this.type,
    required this.chapter,
    required this.lastPayDate,
    required this.payCount,
  });

  factory InactiveMember.fromJson(Map<String, dynamic> json) {
    return InactiveMember(
      id: json['id'] ?? 0,
      fullName: json['indicomp_full_name'] ?? 'Unknown',
      // Provide a fallback if donor type is null, as seen in your provided JSON
      donorType: json['indicomp_donor_type'] ?? 'Donor',
      phone: json['indicomp_mobile_phone']?.toString() ?? 'N/A',
      email: json['indicomp_email'] ?? 'N/A',
      type: json['indicomp_type'] ?? 'N/A',
      chapter: json['chapter_name'] ?? 'N/A',
      lastPayDate: json['last_payment_date'] ?? 'N/A',
      payCount: json['payment_count']?.toString() ?? '0',
    );
  }
}

class InactiveMembershipScreen extends StatefulWidget {
  // Pass an ID if needed, defaults to "2" based on your API URL requirement
  final String categoryId; 

  const InactiveMembershipScreen({Key? key, this.categoryId = "2"}) : super(key: key);

  @override
  _InactiveMembershipScreenState createState() => _InactiveMembershipScreenState();
}

class _InactiveMembershipScreenState extends State<InactiveMembershipScreen> {
  bool _isLoading = true;
  List<InactiveMember> _allMembers = [];
  List<InactiveMember> _filteredMembers = [];
  final TextEditingController _searchController = TextEditingController();

  // Color Palette matching the UI
  static const Color _bgColor = Color(0xFFF8F9FB);
  static const Color _primaryBlue = Color(0xFF4169E1);
  static const Color _labelBlue = Color(0xFF5A81FA);
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

      // Calling the inactive members endpoint (e.g., app-member/2)
      final url = Uri.parse('https://agstest.in/api2/public/api/app-member/${widget.categoryId}');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> memberList = responseData['data'] ?? [];

        List<InactiveMember> parsedMembers = memberList.map((m) => InactiveMember.fromJson(m)).toList();

        setState(() {
          _allMembers = parsedMembers;
          _filteredMembers = parsedMembers;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load data. Status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching inactive members: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Helper to mask phone numbers strictly matching "7984******"
  String _maskPhone(String phone) {
    if (phone == 'N/A' || phone.length < 5) return phone;
    return '${phone.substring(0, 4)}******';
  }

  // Helper to format dates from YYYY-MM-DD to DD-MM-YYYY
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
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Inactive Membership',
          style: TextStyle(
            color: _textDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          // Local Search Bar
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
          
          // Data ListView
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _primaryBlue))
                : _filteredMembers.isEmpty
                    ? const Center(child: Text("No inactive members found.", style: TextStyle(color: _textGrey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        itemCount: _filteredMembers.length,
                        itemBuilder: (context, index) {
                          return _buildInactiveMemberCard(_filteredMembers[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildInactiveMemberCard(InactiveMember member) {
    // Reusable text styles
    const labelStyle = TextStyle(color: _labelBlue, fontSize: 13.5, fontWeight: FontWeight.w400);
    const valueStyle = TextStyle(color: _textDark, fontSize: 13.5, fontWeight: FontWeight.w400);

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
          // Row 1: Name and "Send Mail" Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  member.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () {
                  // Execute send mail action
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _primaryBlue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Send Mail',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Donor Type
          RichText(
            text: TextSpan(
              text: 'Donor Type: ',
              style: labelStyle,
              children: [
                TextSpan(text: member.donorType, style: valueStyle),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Row 3: Phone & Email
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 16, color: _labelBlue),
              const SizedBox(width: 6),
              Text(_maskPhone(member.phone), style: valueStyle),
              
              const SizedBox(width: 16),
              
              const Icon(Icons.mail_outline, size: 16, color: _labelBlue),
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

          // Row 4: Type & Chapter
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

          // Row 5: Last Pay Date & Pay Count
          Row(
            children: [
              RichText(
                text: TextSpan(
                  text: 'Last Pay Date: ',
                  style: labelStyle,
                  children: [
                    TextSpan(text: _formatDate(member.lastPayDate), style: valueStyle),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    text: 'Pay Count: ',
                    style: labelStyle,
                    children: [
                      TextSpan(text: member.payCount, style: valueStyle),
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
