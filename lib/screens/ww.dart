import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:bb/provider/auth_provider.dart'; // Ensure this matches your project path

class ReceiptViewScreen extends StatefulWidget {
  final String receiptRefNo; // Changed from receiptId to receiptRefNo

  const ReceiptViewScreen({Key? key, required this.receiptRefNo}) : super(key: key);

  @override
  _ReceiptViewScreenState createState() => _ReceiptViewScreenState();
}

class _ReceiptViewScreenState extends State<ReceiptViewScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _receiptData;
  Map<String, dynamic>? _donorData;
  Map<String, dynamic>? _chapterData;
  String? _authSignName;
  String? _80gCode;

  // Controller to handle zooming programmatically
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    _fetchReceiptData();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _fetchReceiptData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final String token = authProvider.token ?? '';

      // Use POST as per API documentation
      final url = Uri.parse('https://agstest.in/api2/public/api/app-fetch-receipt-view');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: {
          'receipt_ref_no': widget.receiptRefNo, // Use receipt_ref_no from widget
        },
      );

      print('API RESPONSE STATUS: ${response.statusCode}');
      print('API RESPONSE BODY: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // Check if data exists before accessing nested properties
        if (responseData['data'] != null) {
          setState(() {
            _receiptData = responseData['data'];
            
            // Safely access donor data
            if (responseData['data']['donor'] != null) {
              _donorData = responseData['data']['donor'];
            } else {
              _donorData = {};
              print('Warning: Donor data is null');
            }
            
            // Safely access chapter data
            if (responseData['data']['chapter'] != null) {
              _chapterData = responseData['data']['chapter'];
            } else {
              _chapterData = {};
              print('Warning: Chapter data is null');
            }
            
            if (responseData['auth_sign'] != null && responseData['auth_sign'].isNotEmpty) {
              _authSignName = responseData['auth_sign'][0]['indicomp_full_name'];
            }
            if (responseData['receipt80GCode'] != null) {
              _80gCode = responseData['receipt80GCode']['receipt_80g_code'];
            }
            
            _isLoading = false;
          });
        } else {
          throw Exception('No data received from API');
        }
      } else {
        throw Exception('Failed to load receipt: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in _fetchReceiptData: $e');
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

  // Zoom Button Logic
  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale < 4.0) { // Max scale limit
      _transformationController.value = Matrix4.identity()..scale(currentScale * 1.5);
    }
  }

  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale > 1.0) { // Min scale limit
      _transformationController.value = Matrix4.identity()..scale(currentScale / 1.5);
    }
  }

  // Helper to convert number to words (e.g., 20000 -> Twenty Thousand)
  String _numberToWords(int number) {
    if (number == 0) return "Zero";
    const units = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"];
    const tens = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"];
    
    String convertLessThanOneThousand(int n) {
      if (n == 0) return "";
      if (n < 20) return units[n];
      if (n < 100) return tens[n ~/ 10] + (n % 10 != 0 ? " " + units[n % 10] : "");
      return units[n ~/ 100] + " Hundred" + (n % 100 != 0 ? " " + convertLessThanOneThousand(n % 100) : "");
    }

    if (number < 1000) return convertLessThanOneThousand(number);
    if (number < 100000) return convertLessThanOneThousand(number ~/ 1000) + " Thousand " + convertLessThanOneThousand(number % 1000);
    if (number < 10000000) return convertLessThanOneThousand(number ~/ 100000) + " Lakh " + convertLessThanOneThousand(number % 100000);
    return convertLessThanOneThousand(number ~/ 10000000) + " Crore " + convertLessThanOneThousand(number % 10000000);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Receipt View', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      // Floating Bottom Action Bar matching the image
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.share_outlined, color: Colors.blue), onPressed: () {}),
            IconButton(icon: const Icon(Icons.mail_outline, color: Colors.blue), onPressed: () {}),
            IconButton(icon: const Icon(Icons.print_outlined, color: Colors.blue), onPressed: () {}),
            IconButton(icon: const Icon(Icons.description_outlined, color: Colors.blue), onPressed: () {}),
            IconButton(icon: const Icon(Icons.message_outlined, color: Colors.green), onPressed: () {}), // WhatsApp
            IconButton(icon: const Icon(Icons.history, color: Colors.redAccent), onPressed: () {}),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _receiptData == null
              ? const Center(child: Text("Failed to load receipt details."))
              : Stack(
                  children: [
                    // Main Receipt Interactive Viewer
                    InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 120), // Bottom padding for FAB
                          // FittedBox scales the 800px fixed-width container down to fit the phone screen like a card
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: 800, // Forces the horizontal layout internally
                              child: Column(
                                children: [
                                  _buildMainReceiptBox(),
                                  const SizedBox(height: 24),
                                  _buildLetterBox(), // Now displayed right below the receipt
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Zoom Buttons Overlay (+ / -)
                    Positioned(
                      right: 16,
                      bottom: 100, // Just above the bottom action bar
                      child: Column(
                        children: [
                          FloatingActionButton.small(
                            heroTag: 'btnZoomIn',
                            backgroundColor: Colors.white,
                            onPressed: _zoomIn,
                            child: const Icon(Icons.add, color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton.small(
                            heroTag: 'btnZoomOut',
                            backgroundColor: Colors.white,
                            onPressed: _zoomOut,
                            child: const Icon(Icons.remove, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildMainReceiptBox() {
    String amountInWords = "Zero Only";
    if (_receiptData != null && _receiptData!['receipt_total_amount'] != null) {
      int amount = int.tryParse(_receiptData!['receipt_total_amount'].toString()) ?? 0;
      amountInWords = _numberToWords(amount) + " Only";
    }

    // Safely access data with null checks
    String chapterName = _chapterData?['chapter_name'] ?? 'Chapter Name';
    String chapterAddress = _chapterData?['chapter_address'] ?? '';
    String chapterEmail = _chapterData?['chapter_email'] ?? '';
    String chapterPhone = _chapterData?['chapter_phone'] ?? '';
    String chapterWhatsapp = _chapterData?['chapter_whatsapp'] ?? '';
    
    String donorName = _donorData?['indicomp_full_name'] ?? '';
    String donorAddress = _donorData?['indicomp_res_reg_address'] ?? '';
    String donorCity = _donorData?['indicomp_res_reg_city'] ?? '';
    String donorPin = _donorData?['indicomp_res_reg_pin_code'] ?? '';
    String donorState = _donorData?['indicomp_res_reg_state'] ?? '';
    String donorPan = _donorData?['indicomp_pan_no'] ?? '';
    
    String receiptRefNo = _receiptData?['receipt_ref_no'] ?? '';
    String receiptDate = _receiptData?['receipt_date'] ?? '';
    String receiptType = _receiptData?['receipt_donation_type'] ?? 'General';
    String receiptPayMode = _receiptData?['receipt_tran_pay_mode'] ?? '';
    String receiptAmount = _receiptData?['receipt_total_amount']?.toString() ?? '0';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ]
      ),
      child: Stack(
        children: [
          // Background Watermark
         Positioned.fill(
  child: Center(
    child: Opacity(
      opacity: 0.05, // Keeps your subtle watermark effect
      child: Image.asset(
        'assets/images/lguh.png', // Replace with your image path
        fit: BoxFit.contain, // Ensures the image scales nicely inside the center
        width: 300, // Optional: Set a specific width if needed
      ),
    ),
  ),
),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row with Asset Images
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Left Logo - Replace with your asset image
                    Image.asset(
                      'assets/images/fts_app_logo.png', // Replace with your left logo path
                      height: 50,
                      width: 50,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.account_balance, size: 50, color: Color(0xFF153C89));
                      },
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'वनबंधु परिषद',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF153C89)),
                          ),
                          const Text(
                            'FRIENDS OF TRIBALS SOCIETY',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF153C89)),
                          ),
                          Text(
                            chapterName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF153C89)),
                          ),
                        ],
                      ),
                    ),
                    // Right Logo - Replace with your asset image
                    Image.asset(
                      'assets/images/ouihkr.png', // Replace with your right logo path
                      height: 50,
                      width: 50,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.group, size: 50, color: Colors.orange);
                      },
                    ),
                  ],
                ),
              ),
              
              // Chapter Address text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  chapterAddress,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF153C89)),
                ),
              ),
              const SizedBox(height: 4),
              
              // Email and Phone
              Text(
                'Email: $chapterEmail | Ph: $chapterPhone | Mob: $chapterWhatsapp',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF153C89)),
              ),
              const SizedBox(height: 8),

              // Head Office Bordered Text
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  border: Border.symmetric(horizontal: BorderSide(color: Colors.grey.shade400, width: 1.5)),
                ),
                child: const Text(
                  'Head Office: Ekal Bhawan, 123/A, Harish Mukherjee Road, Kolkata-26. Web: www.ftsindia.com Ph: 033-2454 4510/11/12/13 PAN: AAAAF0290L',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.black87),
                ),
              ),

              // Main Content Area (Donor Details & Table)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column (Donor details)
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Received with thanks from :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(donorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text(donorAddress, style: const TextStyle(fontSize: 12)),
                                Text(donorCity, style: const TextStyle(fontSize: 12)),
                                Text('$donorCity - $donorPin, $donorState', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(color: Colors.black87, fontSize: 12),
                              children: [
                                const TextSpan(text: 'PAN No : ', style: TextStyle(fontWeight: FontWeight.w600)),
                                TextSpan(text: donorPan, style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Right Column (Details Table)
                    Expanded(
                      flex: 4,
                      child: Table(
                        border: TableBorder.all(color: Colors.grey.shade400, width: 1.0),
                        columnWidths: const {
                          0: FlexColumnWidth(1.2),
                          1: FlexColumnWidth(2),
                        },
                        children: [
                          _buildTableRow('Receipt No.', ':   $receiptRefNo'),
                          _buildTableRow('Date', ':   $receiptDate'),
                          _buildTableRow('On account of', ':   $receiptType'),
                          _buildTableRow('Pay Mode', ':   $receiptPayMode'),
                          _buildTableRow('Amount', ':   Rs. $receiptAmount /-'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Amount in words border
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.symmetric(horizontal: BorderSide(color: Colors.grey.shade400, width: 1.0)),
                ),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87, fontSize: 12),
                    children: [
                      const TextSpan(text: 'Amount in words : '),
                      TextSpan(text: amountInWords, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

              // Reference box
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade400, width: 1.0)),
                ),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87, fontSize: 12),
                    children: [
                      const TextSpan(text: 'Reference : '),
                      TextSpan(text: receiptRefNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

              // Footer (80G info & Sign)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        'Donation is exempt U/Sec.80G of the\nIncome Tax Act 1961 vide Order No.${_80gCode ?? ""}',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF153C89)),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('For Friends of Tribals Society', style: TextStyle(fontSize: 10)),
                        const SizedBox(height: 30), // Space for physical signature
                        Text(_authSignName ?? 'Secretary', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        const Text('Secretary', style: TextStyle(fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper for right-side receipt table rows
  TableRow _buildTableRow(String title, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(6.0),
          child: Text(title, style: const TextStyle(fontSize: 11)),
        ),
        Padding(
          padding: const EdgeInsets.all(6.0),
          child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  // Letter Box (Now placed directly below the receipt)
  Widget _buildLetterBox() {
    String donorName = _donorData?['indicomp_full_name'] ?? '';
    String donorAddress = _donorData?['indicomp_res_reg_address'] ?? '';
    String donorCity = _donorData?['indicomp_res_reg_city'] ?? '';
    String donorPin = _donorData?['indicomp_res_reg_pin_code'] ?? '';
    String donorState = _donorData?['indicomp_res_reg_state'] ?? '';
    String receiptDate = _receiptData?['receipt_date'] ?? '';
    String receiptAmount = _receiptData?['receipt_total_amount']?.toString() ?? '0';
    String receiptRefNo = _receiptData?['receipt_ref_no'] ?? '';
    String receiptType = _receiptData?['receipt_donation_type'] ?? 'Education';

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Date: $receiptDate', style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 16),
          Text(donorName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          Text(donorAddress, style: const TextStyle(fontSize: 14)),
          Text(donorCity, style: const TextStyle(fontSize: 14)),
          Text('$donorCity - $donorPin, $donorState', style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 24),
          const Text('Respected Sir/Madam,', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Text(
            'We thankfully acknowledge the receipt of Rs.$receiptAmount/- via your $receiptRefNo being Donation for $receiptType.',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 12),
          Text(
            'We are pleased to enclose herewith our money receipt no. $receiptRefNo dated $receiptDate.',
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 12),
          const Text('Thanking you once again', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 24),
          const Text('Yours faithfully,', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 6),
          const Text('For Friends of Tribals Society', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 40), // Signature gap
          Text(_authSignName ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const Text('Secretary', style: TextStyle(fontSize: 14)),
          const SizedBox(height: 16),
          const Text('Encl: As stated above', style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}