import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:bb/provider/auth_provider.dart';

class SchoolDetailsScreen extends StatefulWidget {
  final int schoolId;
  const SchoolDetailsScreen({Key? key, required this.schoolId}) : super(key: key);

  @override
  _SchoolDetailsScreenState createState() => _SchoolDetailsScreenState();
}

class _SchoolDetailsScreenState extends State<SchoolDetailsScreen> {
  Map<String, dynamic>? _schoolData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSchoolDetails();
  }

  Future<void> _fetchSchoolDetails() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final url = Uri.parse('https://agstest.in/api2/public/api/app-school-by-id/${widget.schoolId}');
    
    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer ${authProvider.token}'});
      if (response.statusCode == 200) {
        setState(() {
          _schoolData = json.decode(response.body)['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: const Text("School Details", style: TextStyle(color: Colors.black, fontSize: 18)),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSection("School Information", [
              _buildRow("School", "${_schoolData!['village'] ?? 'N/A'} ()"),
              _buildRow("Opening Date", _schoolData!['date_of_opening'] ?? '-'),
              _buildRow("Region", "${_schoolData!['region']} (${_schoolData!['region_code']})"),
              _buildRow("Acchal", "${_schoolData!['achal']} (${_schoolData!['achal_code']})"),
              _buildRow("Cluster", "${_schoolData!['cluster']} (${_schoolData!['cluster_code']})"),
              _buildRow("Sub Cluster", "${_schoolData!['sub_cluster']} (${_schoolData!['sub_cluster_code']})"),
              _buildRow("Teacher Name", "${_schoolData!['teacher']} (${_schoolData!['teacher_gender']})"),
              _buildRow("Total Students (Boys/Girls)", "${_schoolData!['total']} (${_schoolData!['boys']} / ${_schoolData!['girls']})"),
            ]),
            const SizedBox(height: 16),
            _buildSection("Contact Information", [
              _buildRow("Samiti Pramukh", _schoolData!['vidyalaya_samity_pramukh'] ?? 'N/A'),
              _buildRow("VCF", "${_schoolData!['vcf_name']} (${_schoolData!['vcf_phone']})"),
              _buildRow("SCF", "${_schoolData!['scf_name'] ?? 'N/A'} (${_schoolData!['scf_phone'] ?? 'N/A'})"),
            ]),
            const SizedBox(height: 16),
            _buildSection("Village Statistics", [
              _buildRow("Total Population", _schoolData!['population'].toString()),
              _buildRow("Male Literacy", _schoolData!['literacy_rate_male'].toString()),
              _buildRow("Female Literacy", _schoolData!['literacy_rate_female'].toString()),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if(title.isNotEmpty) Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          if(title.isNotEmpty) const Divider(),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}