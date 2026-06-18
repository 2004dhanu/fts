import 'dart:convert';
<<<<<<< HEAD
import 'package:bb/screens/ww.dart';
=======
>>>>>>> 340fb4e3687d1acbb774fc373bc216b9d1908053
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:bb/provider/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTS & THEME
// ─────────────────────────────────────────────────────────────────────────────
const String _baseUrl = 'https://agstest.in/api2/public/api';

const Color _primaryBlue = Color(0xFF4169E1);
const Color _primaryDark = Color(0xFF3457B1);
const Color _successGreen = Color(0xFF10B981);
const Color _warningOrange = Color(0xFFF59E0B);
const Color _dangerRed = Color(0xFFEF4444);
const Color _purple = Color(0xFF8B5CF6);
const Color _teal = Color(0xFF14B8A6);
const Color _bgGray = Color(0xFFF7F8FA);
const Color _cardWhite = Color(0xFFFFFFFF);
const Color _textPrimary = Color(0xFF1A1A2E);
const Color _textSecondary = Color(0xFF4A4F68);
const Color _textLight = Color(0xFF9CA3AF);
const Color _borderColor = Color(0xFFE5E7EB);

// ─────────────────────────────────────────────────────────────────────────────
// RECEIPT MODEL
// ─────────────────────────────────────────────────────────────────────────────
class Receipt {
  final int id;
  final String receiptNo;
  final String receiptRefNo;
  final String receiptDate;
  final String exemptionType;
  final String totalAmount;
  final String donationType;
  final String donorName;
  final String chapterName;
  final String financialYear;
  final String? promoter;
  final String? payMode;
  final String? remarks;

  Receipt({
    required this.id,
    required this.receiptNo,
    required this.receiptRefNo,
    required this.receiptDate,
    required this.exemptionType,
    required this.totalAmount,
    required this.donationType,
    required this.donorName,
    required this.chapterName,
    required this.financialYear,
    this.promoter,
    this.payMode,
    this.remarks,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'] ?? 0,
      receiptNo: json['receipt_no']?.toString() ?? 'N/A',
      receiptRefNo: json['receipt_ref_no']?.toString() ?? 'N/A',
      receiptDate: json['receipt_date']?.toString() ?? '',
      exemptionType: json['receipt_exemption_type']?.toString() ?? 'N/A',
      totalAmount: json['receipt_total_amount']?.toString() ?? '0',
      donationType: json['receipt_donation_type']?.toString() ?? 'General',
      donorName: json['indicomp_full_name']?.toString() ?? 'Unknown',
      chapterName: json['chapter_name']?.toString() ?? '',
      financialYear: json['receipt_financial_year']?.toString() ?? '',
      promoter: json['indicomp_promoter']?.toString(),
      payMode: json['receipt_tran_pay_mode']?.toString(),
      remarks: json['receipt_remarks']?.toString(),
    );
  }

  String get formattedDate {
    if (receiptDate.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(receiptDate);
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (e) {
      return receiptDate;
    }
  }

  String get formattedAmount => '₹${int.tryParse(totalAmount)?.toString() ?? totalAmount}';
  
  String get exemptionShort {
    switch (exemptionType.toLowerCase()) {
      case '80g':
        return '80G';
      case 'non 80g':
        return 'Non 80G';
      case 'fcra':
        return 'FCRA';
      default:
        return exemptionType;
    }
  }

  Color get exemptionColor {
    switch (exemptionType.toLowerCase()) {
      case '80g':
        return _successGreen;
      case 'non 80g':
        return _warningOrange;
      case 'fcra':
        return _purple;
      default:
        return _textSecondary;
    }
  }

  Color get donationTypeColor {
    switch (donationType.toLowerCase()) {
      case 'general':
        return _successGreen;
      case 'membership':
        return _teal;
      case 'ots':
        return _purple;
      default:
        return _primaryBlue;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// API SERVICE
// ─────────────────────────────────────────────────────────────────────────────
class ReceiptApiService {
  static Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  static Future<List<Receipt>> fetchReceiptList(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/app-fetch-receipt-list'),
        headers: _headers(token),
      );

      debugPrint('✅ Receipt List Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? body;
        
        return data.map((json) => Receipt.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        debugPrint('❌ Unauthorized - Please check your token');
        return [];
      } else {
        debugPrint('❌ Failed to load receipts: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ fetchReceiptList error: $e');
      return [];
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RECEIPT LIST SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class ReceiptListScreen extends StatefulWidget {
  const ReceiptListScreen({Key? key}) : super(key: key);

  @override
  State<ReceiptListScreen> createState() => _ReceiptListScreenState();
}

class _ReceiptListScreenState extends State<ReceiptListScreen> {
  List<Receipt> _receipts = [];
  List<Receipt> _filteredReceipts = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchReceipts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchReceipts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = Provider.of<AuthProvider>(context, listen: false).token ?? '';
    final receipts = await ReceiptApiService.fetchReceiptList(token);

    if (mounted) {
      setState(() {
        if (receipts.isNotEmpty) {
          _receipts = receipts;
          _filteredReceipts = receipts;
          _isLoading = false;
        } else {
          _errorMessage = 'No receipts found';
          _isLoading = false;
        }
      });
    }
  }

  void _filterReceipts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredReceipts = _receipts;
      } else {
        _filteredReceipts = _receipts.where((receipt) {
          return receipt.donorName.toLowerCase().contains(query.toLowerCase()) ||
              receipt.receiptNo.toLowerCase().contains(query.toLowerCase()) ||
              receipt.receiptRefNo.toLowerCase().contains(query.toLowerCase()) ||
              receipt.donationType.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGray,
     
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          
          // Stats Row
         
          
          // List View
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _primaryBlue))
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_outlined, size: 64, color: _textLight),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(fontSize: 14, color: _textSecondary),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchReceipts,
                              style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredReceipts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.search_off, size: 64, color: _textLight),
                                const SizedBox(height: 16),
                                Text(
                                  'No receipts found for "$_searchQuery"',
                                  style: const TextStyle(fontSize: 14, color: _textSecondary),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchReceipts,
                            color: _primaryBlue,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredReceipts.length,
                              itemBuilder: (context, index) {
                                final receipt = _filteredReceipts[index];
                                return _buildReceiptCard(receipt);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: _filterReceipts,
        decoration: InputDecoration(
          hintText: 'Search by name, receipt no, or type...',
          hintStyle: const TextStyle(fontSize: 13, color: _textLight),
          prefixIcon: const Icon(Icons.search, color: _textLight, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: _textLight, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _filterReceipts('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primaryBlue),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  
  Widget _buildReceiptCard(Receipt receipt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Name and Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Avatar Circle
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(receipt.donorName),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _primaryBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            receipt.donorName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.receipt, size: 12, color: _textLight),
                              const SizedBox(width: 4),
                              Text(
                                'Ref: ${receipt.receiptNo}',
                                style: const TextStyle(fontSize: 11, color: _textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    receipt.formattedAmount,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _successGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: receipt.exemptionColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      receipt.exemptionShort,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: receipt.exemptionColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          const Divider(color: _borderColor, height: 1),
          const SizedBox(height: 12),
          
          // Details Row
          Row(
            children: [
              _buildDetailChip(
                Icons.calendar_today_outlined,
                receipt.formattedDate,
                _textSecondary,
              ),
              const SizedBox(width: 8),
              _buildDetailChip(
                Icons.category_outlined,
                receipt.donationType,
                receipt.donationTypeColor,
              ),
              if (receipt.chapterName.isNotEmpty) ...[
                const SizedBox(width: 8),
               
              ],
            ],
          ),
          
          const SizedBox(height: 10),
          
          // Footer Row
<<<<<<< HEAD
    Row(
  children: [
    _buildActionButton(Icons.visibility_outlined, 'View', () {
      // Access property directly from the Receipt object
      String receiptRefNo = receipt.receiptRefNo; // or receipt.receipt_ref_no
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReceiptViewScreen(receiptRefNo: receiptRefNo),
        ),
      );
    }),
  ],
),
=======
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                receipt.receiptRefNo,
                style: const TextStyle(fontSize: 11, color: _textLight),
              ),
              Row(
                children: [
                  _buildActionButton(Icons.visibility_outlined, 'View', () {
                    _showReceiptDetail(receipt);
                  }),
                 
                ],
              ),
            ],
          ),
>>>>>>> 340fb4e3687d1acbb774fc373bc216b9d1908053
        ],
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _bgGray,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: _primaryBlue),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: _primaryBlue, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _showReceiptDetail(Receipt receipt) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      backgroundColor: _cardWhite,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _primaryBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(receipt.donorName),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: _primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      receipt.donorName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: receipt.exemptionColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        receipt.exemptionShort,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: receipt.exemptionColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: _borderColor),
                  const SizedBox(height: 16),
                  _detailRow('Receipt No', receipt.receiptNo),
                  _detailRow('Receipt Ref No', receipt.receiptRefNo),
                  _detailRow('Date', receipt.formattedDate),
                  _detailRow('Financial Year', receipt.financialYear),
                  _detailRow('Donation Type', receipt.donationType),
                  _detailRow('Exemption Type', receipt.exemptionType),
                  _detailRow('Amount', receipt.formattedAmount),
                  _detailRow('Chapter', receipt.chapterName),
                  if (receipt.promoter != null && receipt.promoter!.isNotEmpty)
                    _detailRow('Promoter', receipt.promoter!),
                  if (receipt.payMode != null && receipt.payMode!.isNotEmpty)
                    _detailRow('Payment Mode', receipt.payMode!),
                  if (receipt.remarks != null && receipt.remarks!.isNotEmpty)
                    _detailRow('Remarks', receipt.remarks!),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: _borderColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Download PDF functionality
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Download PDF'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: _textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}