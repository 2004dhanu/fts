
import 'dart:convert';
import 'package:bb/provider/auth_provider.dart';
import 'package:bb/screens/member_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:bb/provider/auth_provider.dart'; // From your original code context

// --- Data Models ---
class Member {
  final int id;
  final String fullName;
  final String email;
  final String year;

  Member({
    required this.id,
    required this.fullName,
    required this.email,
    required this.year,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] ?? 0,
      fullName: json['indicomp_full_name'] ?? 'Unknown',
      email: json['indicomp_email'] ?? 'No Email',
      year: json['joining_vailidity']?.toString() ?? 'N/A',
    );
  }
}

class MembersDashboardScreen extends StatefulWidget {
  @override
  _MembersDashboardScreenState createState() => _MembersDashboardScreenState();
}

class _MembersDashboardScreenState extends State<MembersDashboardScreen> {
  bool _isLoading = true;
  List<Member> _allMembers = [];
  Map<String, List<Member>> _groupedByYear = {};

  // UI Colors extracted from your image
  static const Color _bgColor = Color(0xFFF8F9FB);
  static const Color _primaryBlue = Color(0xFF4169E1);
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textGrey = Color(0xFF8A8FA8);

  // Note: Emails Sent and Pending are not in the provided API response. 
  // We use static fallbacks here to perfectly match the UI requirements.
  int _totalEmailsSent = 2230;
  String _pendingEmails = "54,48712";

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // Assuming your AuthProvider has a getter for the token. 
      // If it's stored differently, adjust this variable.
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

        List<Member> parsedMembers = memberList.map((m) => Member.fromJson(m)).toList();
        
        Map<String, List<Member>> grouped = {};
        for (var member in parsedMembers) {
          if (!grouped.containsKey(member.year)) {
            grouped[member.year] = [];
          }
          grouped[member.year]!.add(member);
        }

        // Sort years descending
        var sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
        Map<String, List<Member>> sortedGrouped = {
          for (var key in sortedKeys) key: grouped[key]!
        };

        setState(() {
          _allMembers = parsedMembers;
          _groupedByYear = sortedGrouped;
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
        SnackBar(content: Text('Error fetching dashboard: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int activeYearsCount = _groupedByYear.keys.length;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Members Dashboard',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage members accross different years',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_red_eye_outlined, color: Colors.grey),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primaryBlue))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 2x2 Grid Summary ---
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.6, // Adjusting box height
                    children: [
                      _buildSummaryCard(
                        icon: Icons.person_outline,
                        iconBgColor: const Color(0xFF6366F1), // Blue
                        title: 'Total Members',
                        value: '${_allMembers.length}',
                      ),
                      _buildSummaryCard(
                        icon: Icons.calendar_today_outlined,
                        iconBgColor: const Color(0xFFF0744B), // Orange
                        title: 'Active Years',
                        value: '$activeYearsCount',
                      ),
                      _buildSummaryCard(
                        icon: Icons.mail_outline,
                        iconBgColor: const Color(0xFF29C293), // Green
                        title: 'Emails Sent',
                        value: '$_totalEmailsSent',
                      ),
                      _buildSummaryCard(
                        icon: Icons.mark_email_unread_outlined,
                        iconBgColor: const Color(0xFFD64D55), // Red
                        title: 'Pending Emails',
                        value: _pendingEmails,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- Search Bar ---
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search years or meme...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- Membership by Year Section ---
                  const Text(
                    'Membership by Year',
                    style: TextStyle(
                      color: _primaryBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _groupedByYear.keys.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      String year = _groupedByYear.keys.elementAt(index);
                      List<Member> membersInYear = _groupedByYear[year]!;
                      return _buildYearCard(year, membersInYear.length);
                    },
                  ),

                  const SizedBox(height: 30),

                  // --- Recent Members Section ---
                  const Text(
                    'Recent Members',
                    style: TextStyle(
                      color: _primaryBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    // Show max 5 recent members to save screen space or all if needed
                    itemCount: _allMembers.take(5).length, 
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildMemberCard(_allMembers[index]);
                    },
                  ),
                  const SizedBox(height: 40), // Bottom padding
                ],
              ),
            ),
    );
  }

  // Widget for Top 4 Grid Cards
  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconBgColor,
    required String title,
    required String value,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _textGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _textDark,
            ),
          ),
        ],
      ),
    );
  }

  // Widget for Membership By Year List Items
  Widget _buildYearCard(String year, int memberCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  text: 'Year $year ',
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: '($memberCount Member${memberCount > 1 ? 's' : ''})',
                      style: const TextStyle(
                        color: _textGrey,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$memberCount',
                  style: const TextStyle(color: _textDark, fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatusDot(Colors.green, '0 Sent'),
              const SizedBox(width: 16),
              _buildStatusDot(Colors.red, '0 Pending'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.mail_outline, color: _primaryBlue, size: 18),
                  label: const Text('Email', style: TextStyle(color: _primaryBlue)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E5EF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('View', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // Small helper for • 0 Sent / • 0 Pending
  Widget _buildStatusDot(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // Widget for Recent Members List Items
  Widget _buildMemberCard(Member member) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                member.fullName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF3FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  // Modifying layout slightly to match the specific '2023-24' design from the picture
                  member.year, 
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.mail_outline, size: 18, color: _primaryBlue),
              const SizedBox(width: 8),
              Text(
                member.email,
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}