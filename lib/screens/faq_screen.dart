import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:bb/provider/auth_provider.dart'; // Ensure this matches your project path

// --- Data Model ---
class FaqItem {
  final int id;
  final String question;
  final String answer;
  final String status;

  FaqItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.status,
  });

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      id: json['id'] ?? 0,
      question: json['header'] ?? 'No Question',
      answer: json['text'] ?? 'No Answer provided.',
      status: json['status'] ?? 'Inactive',
    );
  }
}

class FaqScreen extends StatefulWidget {
  const FaqScreen({Key? key}) : super(key: key);

  @override
  _FaqScreenState createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  bool _isLoading = true;
  List<FaqItem> _allFaqs = [];
  List<FaqItem> _filteredFaqs = [];
  final TextEditingController _searchController = TextEditingController();

  // Theme Colors matching the UI image
  static const Color _bgColor = Color(0xFFF8F9FB);
  static const Color _primaryBlue = Color(0xFF4169E1);
  static const Color _textDark = Color(0xFF1A1A2E);

  @override
  void initState() {
    super.initState();
    _fetchFaqs();
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
        _filteredFaqs = _allFaqs;
      } else {
        _filteredFaqs = _allFaqs.where((faq) {
          return faq.question.toLowerCase().contains(query) ||
                 faq.answer.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _fetchFaqs() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final String token = authProvider.token ?? '';

      final url = Uri.parse('https://agstest.in/api2/public/api/app-faq-list');
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

        // Parse and only keep "Active" FAQs
        List<FaqItem> parsedFaqs = dataList
            .map((item) => FaqItem.fromJson(item))
            .where((faq) => faq.status.toLowerCase() == 'active')
            .toList();

        setState(() {
          _allFaqs = parsedFaqs;
          _filteredFaqs = parsedFaqs;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load FAQs');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching FAQs: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
                    // Open drawer or pop navigation
                    // Scaffold.of(context).openDrawer(); 
                  },
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'FAQ List',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: _textDark,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    color: _primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.file_download_outlined, color: Colors.white),
                    onPressed: () {
                      // Implement download functionality if needed
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
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search FAQs...',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          
          // FAQ List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _primaryBlue))
                : _filteredFaqs.isEmpty
                    ? Center(
                        child: Text(
                          "No FAQs found.",
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                        itemCount: _filteredFaqs.length,
                        itemBuilder: (context, index) {
                          return _buildFaqCard(_filteredFaqs[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqCard(FaqItem faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // Theme wrapper removes the default divider lines from ExpansionTile
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: Colors.grey.shade600,
          collapsedIconColor: Colors.grey.shade600,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
          title: Text(
            faq.question,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: _primaryBlue, // Primary blue text exactly like the image
            ),
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade100, width: 1.0), // Faint top line
                ),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  faq.answer,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey.shade800,
                    height: 1.4, // Line height for readability
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