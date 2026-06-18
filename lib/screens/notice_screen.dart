import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:bb/provider/auth_provider.dart'; // Ensure this matches your project path

// --- Data Model ---
class NoticeItem {
  final int id;
  final String noticeName;
  final String noticeDetail;
  final String status;
  bool isRead; 

  NoticeItem({
    required this.id,
    required this.noticeName,
    required this.noticeDetail,
    required this.status,
    required this.isRead,
  });

  factory NoticeItem.fromJson(Map<String, dynamic> json) {
    return NoticeItem(
      id: json['id'] ?? 0,
      noticeName: json['notice_name'] ?? 'No Title',
      noticeDetail: json['notice_detail'] ?? 'No details provided.',
      status: json['status'] ?? 'Inactive',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<NoticeItem> _allNotices = [];
  List<NoticeItem> _filteredNotices = [];
  final TextEditingController _searchController = TextEditingController();

  // Theme Colors matching the image exactly
  static const Color _bgColor = Color(0xFFF8F9FB);
  static const Color _primaryBlue = Color(0xFF5A81FA); // Exact blue from the image
  static const Color _btnBgBlue = Color(0xFFF4F8FF); // Very light blue for button
  static const Color _textDark = Color(0xFF2C2C2C); // Dark grey/black for read text

  @override
  void initState() {
    super.initState();
    _fetchNotices();
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
        _filteredNotices = _allNotices;
      } else {
        _filteredNotices = _allNotices.where((notice) {
          return notice.noticeName.toLowerCase().contains(query) ||
                 notice.noticeDetail.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _fetchNotices() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final String token = authProvider.token ?? '';

      final url = Uri.parse('https://agstest.in/api2/public/api/app-notice-list');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> dataList = responseData['data'] ?? [];

        List<NoticeItem> parsedNotices = dataList
            .map((item) => NoticeItem.fromJson(item))
            .where((notice) => notice.status.toLowerCase() == 'active')
            .toList();

        setState(() {
          _allNotices = parsedNotices;
          _filteredNotices = parsedNotices;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load Notifications');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- Acknowledge Logic ---
  Future<void> _acknowledgeNotice(NoticeItem notice) async {
    // Optimistic UI Update
    setState(() {
      notice.isRead = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification acknowledged.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // API Call logic goes here
    /*
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final url = Uri.parse('https://agstest.in/api2/public/api/app-notice-acknowledge/${notice.id}');
      await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${authProvider.token}',
          'Accept': 'application/json',
        },
      );
    } catch (e) {
      // Handle error
    }
    */
  }

  @override
  Widget build(BuildContext context) {
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
                  icon: const Icon(Icons.menu, color: Colors.black87), // Hamburger menu
                  onPressed: () {
                    // Scaffold.of(context).openDrawer();
                  },
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search Notifications...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          
          // --- Notifications List ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _primaryBlue))
                : _filteredNotices.isEmpty
                    ? Center(
                        child: Text(
                          "No notifications found.",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        itemCount: _filteredNotices.length,
                        itemBuilder: (context, index) {
                          return _buildNotificationCard(_filteredNotices[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NoticeItem notice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: Colors.grey.shade600,
          collapsedIconColor: Colors.grey.shade600,
          tilePadding: const EdgeInsets.only(left: 16.0, right: 12.0, top: 4.0, bottom: 4.0),
          // Using a Row in title to position the button perfectly before the expansion arrow
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notice.noticeName,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w400,
                        color: notice.isRead ? _textDark : _primaryBlue, 
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Posted on: 09-03-26', // Placeholder matching UI design
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // --- Acknowledge Button ---
              if (!notice.isRead)
                InkWell(
                  onTap: () => _acknowledgeNotice(notice),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _btnBgBlue,
                      borderRadius: BorderRadius.circular(4), // Slightly squarer match
                    ),
                    child: const Text(
                      'Acknowledge',
                      style: TextStyle(
                        color: _primaryBlue,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400, // Matches delicate font in image
                      ),
                    ),
                  ),
                ),
            ],
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade100, width: 1.0),
                ),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  notice.noticeDetail,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}