import 'package:bb/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _userAddressController = TextEditingController();

  String? _selectedChapter;
  String? _selectedDay;
  String? _selectedMonth;
  String? _selectedYear;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  static const Color _primaryBlue = Color(0xFF4169E1);
  static const Color _labelBlue = Color(0xFF4169E1);
  static const Color _bgColor = Color(0xFFF0F2F8);

  final List<String> _chapters = [
    'Bangalore', 'North', 'South', 'East', 'West',
    'Central', 'Mumbai', 'Delhi', 'Chennai', 'Kolkata'
  ];

  final List<String> _days =
      List.generate(31, (i) => (i + 1).toString().padLeft(2, '0'));
  final List<String> _months = [
    '01', '02', '03', '04', '05', '06',
    '07', '08', '09', '10', '11', '12'
  ];
  final List<String> _years = List.generate(
    80,
    (i) => (DateTime.now().year - i).toString(),
  );

  String get _userBirthday {
    if (_selectedYear != null && _selectedMonth != null && _selectedDay != null) {
      return '$_selectedYear-$_selectedMonth-$_selectedDay';
    }
    return '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _userAddressController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Passwords do not match'),
              backgroundColor: Colors.red),
        );
        return;
      }

      if (_selectedChapter == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Please select a chapter'),
              backgroundColor: Colors.red),
        );
        return;
      }

      final userData = {
        'name': _nameController.text.trim(),
        'full_name': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'user_birthday': _userBirthday,
        'user_add': _userAddressController.text.trim(),
        'user_chapter': _selectedChapter!,
        'password': _passwordController.text,
      };

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.signUp(userData);

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(result['message']),
                backgroundColor: Colors.green),
          );
          if (result['autoLoggedIn'] == true) {
            Navigator.pushReplacementNamed(context, '/donor-list');
          } else {
            Navigator.pop(context);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(result['message']),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // ── Shared decoration ──────────────────────────────────────────────────────
  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB0B5C8), fontSize: 14.5),
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E5EF), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E5EF), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: _labelBlue,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  // ── Dropdown field (chapter / day / month / year) ─────────────────────────
  Widget _dropdownField({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    double? width,
  }) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E5EF), width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: const TextStyle(color: Color(0xFFB0B5C8), fontSize: 14.5),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFFB0B5C8), size: 20),
          style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 14.5),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // Decorative blobs — same as login screen
          Positioned(
            top: -60,
            right: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD6DCF0).withOpacity(0.6),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: -70,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD6DCF0).withOpacity(0.5),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title block ──────────────────────────────────────────
                  Center(
                    child: Column(
                      children: const [
                        Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Fill in your details to request access',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8A8FA8),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Full Name ─────────────────────────────────────
                        _label('Full Name'),
                        TextFormField(
                          controller: _fullNameController,
                          style: const TextStyle(
                              fontSize: 15, color: Color(0xFF1A1A2E)),
                          decoration: _fieldDecoration('Jhon Avantika'),
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Full Name is required' : null,
                        ),

                        const SizedBox(height: 20),

                        // ── Chapter Name ──────────────────────────────────
                        _label('Chapter Name'),
                        _dropdownField(
                          hint: 'Select',
                          value: _selectedChapter,
                          items: _chapters,
                          onChanged: (v) =>
                              setState(() => _selectedChapter = v),
                        ),
                        if (_selectedChapter == null &&
                            _formKey.currentState != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, left: 4),
                            child: Text(
                              'Please select a chapter',
                              style: TextStyle(
                                  color: Colors.red[600], fontSize: 12),
                            ),
                          ),

                        const SizedBox(height: 20),

                        // ── Email Address ─────────────────────────────────
                        _label('Email Address'),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                              fontSize: 15, color: Color(0xFF1A1A2E)),
                          decoration: _fieldDecoration(
                              'Enter Your Email Address'),
                          validator: (v) {
                            if (v?.isEmpty ?? true) return 'Email is required';
                            if (!v!.contains('@')) return 'Enter valid email';
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // ── Phone Number ──────────────────────────────────
                        _label('Phone Number'),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                              fontSize: 15, color: Color(0xFF1A1A2E)),
                          decoration:
                              _fieldDecoration('Enter Your Mobile Number'),
                          validator: (v) => v?.isEmpty ?? true
                              ? 'Phone Number is required'
                              : null,
                        ),

                        const SizedBox(height: 20),

                        // ── Date of Birth (3 dropdowns) ───────────────────
                        _label('Date of Birth'),
                        Row(
                          children: [
                            // Day
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: _dropdownField(
                                  hint: 'Day',
                                  value: _selectedDay,
                                  items: _days,
                                  onChanged: (v) =>
                                      setState(() => _selectedDay = v),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Month
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: _dropdownField(
                                  hint: 'Month',
                                  value: _selectedMonth,
                                  items: _months,
                                  onChanged: (v) =>
                                      setState(() => _selectedMonth = v),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Year
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: _dropdownField(
                                  hint: 'Year',
                                  value: _selectedYear,
                                  items: _years,
                                  onChanged: (v) =>
                                      setState(() => _selectedYear = v),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ── Hidden fields (username, address, passwords) ───
                        // These are kept in state/logic but not shown per the
                        // image UI. Username defaults to full name if blank.
                        // Password fields hidden from view as per design.
                        //
                        // If you need them visible, uncomment below:
                        //
                        // _label('Username'),
                        // TextFormField(controller: _nameController, decoration: _fieldDecoration('Username')),
                        // const SizedBox(height: 20),
                        // _label('Password'),
                        // TextFormField(
                        //   controller: _passwordController,
                        //   obscureText: _obscurePassword,
                        //   decoration: _fieldDecoration('Password').copyWith(
                        //     suffixIcon: IconButton(
                        //       icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Color(0xFFB0B5C8), size: 20),
                        //       onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        //     ),
                        //   ),
                        // ),
                        // const SizedBox(height: 20),
                        // _label('Confirm Password'),
                        // TextFormField(
                        //   controller: _confirmPasswordController,
                        //   obscureText: _obscureConfirmPassword,
                        //   decoration: _fieldDecoration('Confirm Password').copyWith(
                        //     suffixIcon: IconButton(
                        //       icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Color(0xFFB0B5C8), size: 20),
                        //       onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        //     ),
                        //   ),
                        // ),
                        // const SizedBox(height: 20),

                        const SizedBox(height: 8),

                        // ── Submit button ─────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed:
                                authProvider.isLoading ? null : _handleSignUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              disabledBackgroundColor:
                                  _primaryBlue.withOpacity(0.6),
                            ),
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text(
                                    'Submit',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Back to Sign in ───────────────────────────────
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF4A4F68),
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Back to Sign in',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF4A4F68),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}