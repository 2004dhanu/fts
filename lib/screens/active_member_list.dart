import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:bb/provider/auth_provider.dart'; // From your context

// --- Data Model ---
class ActiveMember {
  final int id;
  final String fullName;
  final String donorType;
  final String phone;
  final String email;
  final String type;
  final String chapter;
  final String lastPayDate;
  final String payCount;
  final bool isEmailSent; // Determines which button to show

  ActiveMember({
    required this.id,
    required this.fullName,
    required this.donorType,
    required this.phone,
    required this.email,
    required this.type,
    required this.chapter,
    required this.lastPayDate,
    required this.payCount,
    this.isEmailSent = false,
  });

  factory ActiveMember.fromJson(Map<String, dynamic> json) {
    return ActiveMember(
      id: json['id'] ?? 0,
      fullName: json['indicomp_full_name'] ?? 'Unknown',
      donorType: json['indicomp_donor_type'] ?? 'Donor', // Fallback to Donor if null
      phone: json['indicomp_mobile_phone']?.toString() ?? 'N/A',
      email: json['indicomp_email'] ?? 'N/A',
      type: json['indicomp_type'] ?? 'N/A',
      chapter: json['chapter_name'] ?? 'N/A',
      lastPayDate: json['last_payment_date'] ?? 'N/A',
      payCount: json['payment_count']?.toString() ?? '0',
      // Assuming the API provides a flag for email status; 
      // otherwise, you can implement custom logic here to determine it.
      isEmailSent: json['email_sent'] == 1 || json['email_sent'] == true,
    );
  }
}

class ActiveMembershipScreen extends StatefulWidget {
  // You might want to pass an ID if the endpoint is dynamic like /api/app-member/{id}
  final String? yearId; 

  const ActiveMembershipScreen({Key? key, this.yearId = "1"}) : super(key: key);

  @override
  _ActiveMembershipScreenState createState() => _ActiveMembershipScreenState();
}

class _ActiveMembershipScreenState extends State<ActiveMembershipScreen> {
  bool _isLoading = true;
  List<ActiveMember> _allMembers = [];
  List<ActiveMember> _filteredMembers = [];
  final TextEditingController _searchController = TextEditingController();

  // Colors based on UI design
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

      // The URL includes the ID passed or defaults to '1'
      final url = Uri.parse('https://agstest.in/api2/public/api/app-member/${widget.yearId}');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // The API snippet provided had an empty "data": [] array, but assuming
        // it will be populated with member objects in a real scenario:
        final List<dynamic> memberList = responseData['data'] ?? [];

        List<ActiveMember> parsedMembers = memberList.map((m) => ActiveMember.fromJson(m)).toList();

        // If the API returns empty data for testing, you might want to uncomment below to inject dummy data to see the UI
        /*
        if (parsedMembers.isEmpty) {
          parsedMembers = [
            ActiveMember(id: 1, fullName: 'Aarav Sharma', donorType: 'Donor', phone: '7984123456', email: 'aarav01@gmail.com', type: 'Private', chapter: 'Kolkata Chapter', lastPayDate: '2025-12-09', payCount: '1', isEmailSent: true),
            ActiveMember(id: 2, fullName: 'Mukul Sharma', donorType: 'Donor', phone: '7984654321', email: 'mukul02@gmail.com', type: 'Private', chapter: 'Kolkata Chapter', lastPayDate: '2025-12-09', payCount: '1', isEmailSent: false),
          ];
        }
        */

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
        SnackBar(content: Text('Error fetching active members: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Utility to mask phone numbers to match UI: "7984******"
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
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Active Membership',
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
          
          // List View (Optimized with builder)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _primaryBlue))
                : _filteredMembers.isEmpty
                    ? const Center(child: Text("No active members found.", style: TextStyle(color: _textGrey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        itemCount: _filteredMembers.length,
                        itemBuilder: (context, index) {
                          // Note: The first card in your image has a blue border. 
                          // If that's a "selected" state, you can pass a boolean. 
                          // Here we'll just render it normally, but you can add logic if needed.
                          return _buildActiveMemberCard(_filteredMembers[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveMemberCard(ActiveMember member) {
    const labelStyle = TextStyle(color: _labelBlue, fontSize: 13.5, fontWeight: FontWeight.w400);
    const valueStyle = TextStyle(color: _textDark, fontSize: 13.5, fontWeight: FontWeight.w400);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // If you need the exact blue border as seen on the first item in the image:
        // border: index == 0 ? Border.all(color: Colors.lightBlueAccent, width: 2) : Border.all(color: Colors.grey.shade200),
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
          // Row 1: Name and Action Button
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
                  // Handle Mail Sending Logic Here
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _primaryBlue,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    member.isEmailSent ? 'Email Sent' : 'Send Mail',
                    style: const TextStyle(
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

          // Row 3: Phone and Email
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

          // Row 4: Type and Chapter
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

          // Row 5: Last Pay Date and Pay Count
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
