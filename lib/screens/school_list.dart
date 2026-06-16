import 'dart:convert';
import 'package:bb/screens/school_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:bb/provider/auth_provider.dart'; // Ensure this matches your project path

class School {
  final int id;
  final String achal, cluster, subCluster, village, district, state, schoolCode, status;

  School({
    required this.id,
    required this.achal,
    required this.cluster,
    required this.subCluster,
    required this.village,
    required this.district,
    required this.state,
    required this.schoolCode,
    required this.status,
  });

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      id: json['id'] ?? 0,
      achal: json['achal'] ?? 'N/A',
      cluster: json['cluster'] ?? 'N/A',
      subCluster: json['sub_cluster'] ?? 'N/A',
      village: json['village'] ?? 'N/A',
      district: json['district'] ?? 'N/A',
      state: json['school_state'] ?? 'N/A',
      schoolCode: json['school_code'] ?? 'N/A',
      status: json['status_label'] ?? 'N/A',
    );
  }
}
class SchoolListScreen extends StatefulWidget {
  @override
  _SchoolListScreenState createState() => _SchoolListScreenState();
}

class _SchoolListScreenState extends State<SchoolListScreen> {
  List<School> _allSchools = [];
  List<School> _filteredSchools = [];
  String _chapterName = "Loading...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final url = Uri.parse('https://agstest.in/api2/public/api/app-school-list/2025-26');
    
    try {
      final response = await http.get(url, headers: {'Authorization': 'Bearer ${authProvider.token}'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _chapterName = data['data'][0]['chapter_name'];
          _allSchools = (data['schools'] as List).map((s) => School.fromJson(s)).toList();
          _filteredSchools = _allSchools;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterSchools(String query) {
    setState(() {
      _filteredSchools = _allSchools.where((s) => 
        s.village.toLowerCase().contains(query.toLowerCase()) || 
        s.schoolCode.toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("$_chapterName (${_allSchools.length} Schools)", 
          style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600)),
        leading: const Icon(Icons.menu, color: Colors.black87),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filterSchools,
              decoration: InputDecoration(
                hintText: 'Search School',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator()) : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredSchools.length,
              itemBuilder: (context, index) => _buildSchoolCard(_filteredSchools[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchoolCard(School school) {
    return InkWell(
      onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SchoolDetailsScreen(
            schoolId: school.id,
          ),
        ),
      );
    },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Ackal: ${school.achal}", style: const TextStyle(color: Colors.blue, fontSize: 15)),
                const Icon(Icons.visibility_outlined, color: Colors.grey, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text("Cluster: ${school.cluster} | Sub Cluster: ${school.subCluster}", style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 4),
            Text("Village: ${school.village} | District: ${school.district}", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text("State: ${school.state}", style: const TextStyle(color: Colors.blue)),
            const SizedBox(height: 4),
            Text("School Code: ${school.schoolCode} | Status: ${school.status.isEmpty ? 'N/A' : school.status}", 
              style: const TextStyle(color: Colors.blue)),
          ],
        ),
      ),
    );
  }
}