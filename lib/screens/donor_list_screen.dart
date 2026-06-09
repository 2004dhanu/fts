
import 'package:bb/models/donor.dart';
import 'package:bb/provider/auth_provider.dart';
import 'package:bb/screens/create_donor_company.dart';
import 'package:bb/screens/create_individual_Donor.dart';
import 'package:bb/screens/create_receipt_screen.dart';
import 'package:bb/screens/dashbboard.dart';
import 'package:bb/screens/donor_view.dart';
import 'package:bb/screens/edit_donor_screen.dart';
import 'package:bb/screens/reciept.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Simple in-memory image cache helper
// ─────────────────────────────────────────────────────────────────────────────
class _CachedNetworkImage extends StatelessWidget {
  final String url;
  final double size;
  final Color fallbackColor;

  const _CachedNetworkImage({
    required this.url,
    required this.size,
    required this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * 2).toInt(), // cache at 2× for retina
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fallbackColor.withOpacity(0.15),
          ),
          child: Icon(Icons.person, size: size * 0.5, color: fallbackColor),
        ),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
            ),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: const Color(0xFF4169E1),
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────────────────
class DonorListScreen extends StatefulWidget {
  @override
  _DonorListScreenState createState() => _DonorListScreenState();
}

class _DonorListScreenState extends State<DonorListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const Color _primaryBlue = Color(0xFF4169E1);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchDonors());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDonors() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.fetchDonorList();
  }

  void _logout() {
    Provider.of<AuthProvider>(context, listen: false).logout();
    Navigator.pushReplacementNamed(context, '/');
  }

  List<Donor> _getFilteredDonors(List<Donor> donors) {
    if (_searchQuery.isEmpty) return donors;
    final q = _searchQuery.toLowerCase();
    return donors.where((d) {
      return d.displayName.toLowerCase().contains(q) ||
          d.type.toLowerCase().contains(q) ||
          d.spouseName.toLowerCase().contains(q) ||
          d.contactName.toLowerCase().contains(q);
    }).toList();
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'individual':
        return const Color(0xFF4169E1);
      case 'trust':
        return Colors.green;
      case 'private':
        return Colors.purple;
      case 'public':
        return Colors.orange;
      case 'society':
        return Colors.teal;
      case 'corporate':
        return Colors.indigo;
      case 'psu':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  // ── Drawer (hamburger menu) ───────────────────────────────────────────────
  void _openDrawer(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black38,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: Colors.white,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.72,
            height: double.infinity,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BBC',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _drawerItem(Icons.people_outline, 'Donor List', () {
                      Navigator.pop(context);
                    }),
                    _drawerItem(Icons.logout, 'Logout', () {
                      Navigator.pop(context);
                      _logout();
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF4A4F68), size: 20),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1A1A2E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final filteredDonors = _getFilteredDonors(authProvider.donors.cast<Donor>());

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top bar ──────────────────────────────────────────────────
           

            const SizedBox(height: 12),

            // ── Search bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
                  decoration: InputDecoration(
                    hintText: 'Search years or meme...',
                    hintStyle: TextStyle(
                        color: Colors.grey[400], fontSize: 13.5),
                    prefixIcon:
                        Icon(Icons.search, color: Colors.grey[400], size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),
Container(
  padding: const EdgeInsets.all(16),
  child: Row(
    children: [
      Expanded(
        child: ElevatedButton.icon(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateDonorScreen(),
              ),
            );

            if (result == true) {
              setState(() {});
            }
          },
          icon: const Icon(Icons.person_add, size: 18),
          label: const Text(
            'Add Donor',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B7DD8),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),

      const SizedBox(width: 12),

      Expanded(
        child: ElevatedButton.icon(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const CreateCompanyDonorScreen(),
              ),
            );

            if (result == true) {
              setState(() {});
            }
          },
          icon: const Icon(Icons.business, size: 18),
          label: const Text(
            'Add Company',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B7DD8),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    ],
  ),
),
            // ── List ──────────────────────────────────────────────────────
            Expanded(
              child: authProvider.isLoading && authProvider.donors.isEmpty
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF4169E1)))
                  : filteredDonors.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline,
                                  size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'No donors found',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: _primaryBlue,
                          onRefresh: _fetchDonors,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: filteredDonors.length,
                            itemBuilder: (context, index) =>
    _DonorCard(
      donor: filteredDonors[index],
      typeColor: _typeColor(filteredDonors[index].type),
      onView: () => _showDonorDetails(filteredDonors[index]),
    ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom sheet detail ───────────────────────────────────────────────────
  void _showDonorDetails(Donor donor) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _CachedNetworkImage(
                    url: donor.fullImageUrl,
                    size: 70,
                    fallbackColor: _typeColor(donor.type),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          donor.displayName,
                          style: const TextStyle(
                              fontSize: 19, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${donor.type} | ${donor.uniqueId}',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              _detailRow(Icons.badge, 'Title', donor.title),
              _detailRow(Icons.phone, 'Phone', donor.mobilePhone),
              _detailRow(Icons.email, 'Email', donor.email),
              _detailRow(Icons.location_city, 'Chapter', donor.chapterName),
              _detailRow(Icons.people, 'Promoter', donor.promoter),
              if (donor.spouseName.isNotEmpty && donor.spouseName != 'null')
                _detailRow(Icons.favorite, 'Spouse', donor.spouseName),
              if (donor.contactName.isNotEmpty && donor.contactName != 'null')
                _detailRow(
                    Icons.contact_phone, 'Contact Person', donor.contactName),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Close',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    if (value.isEmpty || value == 'null') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Donor Card Widget
// ─────────────────────────────────────────────────────────────────────────────
class _DonorCard extends StatelessWidget {
  final Donor donor;
  final Color typeColor;
  final VoidCallback onView;
 

  const _DonorCard({
    required this.donor,
    required this.typeColor,
    required this.onView,
    
    
  });

  @override
  Widget build(BuildContext context) {
    final bool hasSpouse =
        donor.spouseName.isNotEmpty && donor.spouseName != 'null';
    final bool hasContact =
        donor.contactName.isNotEmpty && donor.contactName != 'null';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [

    // Top Row
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        _CachedNetworkImage(
          url: donor.fullImageUrl,
          size: 48,
          fallbackColor: typeColor,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      donor.displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         _ActionIcon(
                                icon: Icons.receipt_outlined, // Changed to receipt icon
                                onTap: () {
                                  // Navigate to Create Receipt Screen with donor data
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CreateReceiptScreen(
                                        donor: donor,
                                      ),
                                    ),
                                  );
                                },
                              ),
                        const SizedBox(width: 6),
                        _ActionIcon(
                          icon: Icons.edit_outlined,
                          // In your DonorListScreen, when tapping on edit action:
onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EditDonorScreen(donor: donor),
    ),
  );
}
                        ),
                        const SizedBox(width: 6),
                   _ActionIcon(
  icon: Icons.remove_red_eye_outlined,
  onTap: () {
    // IMPORTANT: Pass the DATABASE ID (donor.id) not the FTS ID
    final donorId = donor.id?.toString() ?? '';
    debugPrint('🔍 Viewing donor - DB ID: ${donor.id}, FTS ID: ${donor.indicompFtsId}');
    debugPrint('🚀 Navigating to DonorViewScreen with DATABASE ID: $donorId');
    
    if (donorId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DonorViewScreen(
            donorId: donorId,  // Pass DATABASE ID (e.g., 12399)
          ),
        ),
      );
    } else {
      debugPrint('❌ No valid donor ID found');
    }
  },
),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Text(
                '${donor.type} | ${donor.uniqueId}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ],
    ),

    const SizedBox(height: 10),

    // Phone
    Row(
  children: [
    Icon(
      Icons.phone_outlined,
      size: 14,
      color: Color(0xFF4169E1),
    ),
    const SizedBox(width: 4),

    Text(
      donor.maskedPhone,
      style: const TextStyle(
        fontSize: 12.5,
        color: Color(0xFF4A4F68),
      ),
    ),

    const SizedBox(width: 12),

    Icon(
      Icons.mail_outline,
      size: 14,
      color: Color(0xFF4169E1),
    ),
    const SizedBox(width: 4),

    Expanded(
      child: Text(
        donor.email,
        style: const TextStyle(
          fontSize: 12.5,
          color: Color(0xFF4A4F68),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ],
),
    const SizedBox(height: 6),

    // Contact / Spouse
    if (hasSpouse)
      RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'Spouse: ',
              style: TextStyle(
                color: Color(0xFF4169E1),
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
            TextSpan(
              text: donor.spouseName,
              style: const TextStyle(
                color: Color(0xFF4A4F68),
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      )
    else if (hasContact)
      RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'Contact: ',
              style: TextStyle(
                color: Color(0xFF4169E1),
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
            TextSpan(
              text: donor.contactName,
              style: const TextStyle(
                color: Color(0xFF4A4F68),
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
  ],
),
      
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small tappable icon inside the pill
// ─────────────────────────────────────────────────────────────────────────────
class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        size: 16,
        color: const Color(0xFF6B7280),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search Delegate (unchanged logic)
// ─────────────────────────────────────────────────────────────────────────────
class DonorSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear, color: Color(0xFF6C63FF)),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final results = authProvider.donors.where((d) {
      return d.displayName.toLowerCase().contains(query.toLowerCase()) ||
          d.type.toLowerCase().contains(query.toLowerCase()) ||
          d.spouseName.toLowerCase().contains(query.toLowerCase()) ||
          d.contactName.toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No donors found',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with a different name',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final donor = results[index];
        final bool hasSpouse =
            donor.spouseName.isNotEmpty && donor.spouseName != 'null';
        final bool hasContact =
            donor.contactName.isNotEmpty && donor.contactName != 'null';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  donor.fullImageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  cacheWidth: 96,
                  errorBuilder: (_, __, ___) => Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getTypeColor(donor.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 24,
                      color: _getTypeColor(donor.type),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      donor.displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Type | ID
                    Text(
                      '${donor.type} | ${donor.uniqueId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Phone
                    Row(
                      children: [
                        Icon(Icons.phone_outlined,
                            size: 14,
                            color: const Color(0xFF4169E1).withOpacity(0.8)),
                        const SizedBox(width: 6),
                        Text(
                          donor.maskedPhone,
                          style: const TextStyle(
                              fontSize: 12.5, color: Color(0xFF4A4F68)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Email
                    Row(
                      children: [
                        Icon(Icons.mail_outline,
                            size: 14,
                            color: const Color(0xFF4169E1).withOpacity(0.8)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            donor.email,
                            style: const TextStyle(
                                fontSize: 12.5, color: Color(0xFF4A4F68)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Spouse OR Contact
                    if (hasSpouse)
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Spouse: ',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: const Color(0xFF4169E1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: donor.spouseName,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF4A4F68),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (hasContact)
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Contact: ',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: const Color(0xFF4169E1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: donor.contactName,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF4A4F68),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final suggestions = authProvider.donors.where((d) {
      return d.displayName.toLowerCase().contains(query.toLowerCase()) ||
          d.type.toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Search donors',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter name, type, or spouse name',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    if (suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No matching donors',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final donor = suggestions[index];

        return GestureDetector(
          onTap: () {
            query = donor.displayName;
            showResults(context);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    donor.fullImageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    cacheWidth: 96,
                    errorBuilder: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getTypeColor(donor.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 24,
                        color: _getTypeColor(donor.type),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donor.displayName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${donor.type} | ${donor.uniqueId}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        donor.maskedPhone,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'individual':
        return Colors.blue;
      case 'trust':
        return Colors.green;
      case 'private':
        return Colors.purple;
      case 'public':
        return Colors.orange;
      case 'society':
        return Colors.teal;
      case 'corporate':
        return Colors.indigo;
      case 'psu':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  @override
  ThemeData get theme => ThemeData(
    
        appBarTheme: const AppBarTheme(
          
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        inputDecorationTheme: const InputDecorationTheme(
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
        ),
        
      );
      
}