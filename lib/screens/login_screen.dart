import 'package:bb/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _acceptTerms = false;

  static const Color _primaryBlue = Color(0xFF4169E1);
  static const Color _labelBlue = Color(0xFF4169E1);
  static const Color _bgColor = Color(0xFFF0F2F8);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_acceptTerms) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Please accept Terms & Conditions and Privacy Policy',
      ),
    ),
  );
  return;
}
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (result['success'] == true && mounted) {
        Navigator.pushReplacementNamed(context, '/donor-list');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Invalid Username or password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // Top-right decorative circle blob
          Positioned(
            top: -60,
            right: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFD6DCF0).withOpacity(0.6),
              ),
            ),
          ),
          // Bottom-left decorative circle blob
          Positioned(
            bottom: 60,
            left: -70,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFD6DCF0).withOpacity(0.5),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  // Heading
                  Center(
                    child: Column(
                      children: const [
                        Text(
                          'Welcome!',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Log in Account',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF8A8FA8),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Email label
                        Text(
                          'Username',
                          style: TextStyle(
                            color: _labelBlue,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Email field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF1A1A2E),
                          ),
                          decoration: InputDecoration(
                            hintText: 'username',
                            hintStyle: TextStyle(
                              color: Color(0xFFB0B5C8),
                              fontSize: 14.5,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Color(0xFFE2E5EF),
                                width: 1.2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Color(0xFFE2E5EF),
                                width: 1.2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _primaryBlue,
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 1.2,
                              ),
                            ),
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'username is required' : null,
                        ),

                        const SizedBox(height: 20),

                        // Password label
                        Text(
                          'Password',
                          style: TextStyle(
                            color: _labelBlue,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF1A1A2E),
                          ),
                          decoration: InputDecoration(
                            hintText: '••••••',
                            hintStyle: TextStyle(
                              color: Color(0xFFB0B5C8),
                              fontSize: 14.5,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Color(0xFFB0B5C8),
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Color(0xFFE2E5EF),
                                width: 1.2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: Color(0xFFE2E5EF),
                                width: 1.2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _primaryBlue,
                                width: 1.5,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.red,
                                width: 1.2,
                              ),
                            ),
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Password is required' : null,
                        ),

                        const SizedBox(height: 12),

                        // Remember me + Forgot Password row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: _primaryBlue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    side: BorderSide(
                                      color: Color(0xFFB0B5C8),
                                      width: 1.4,
                                    ),
                                    onChanged: (value) =>
                                        setState(() => _rememberMe = value ?? false),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Remember me',
                                  style: TextStyle(
                                    color: Color(0xFF6B7080),
                                    fontSize: 13.5,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/forgot-password'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Forgot Password',
                                style: TextStyle(
                                  color: _primaryBlue,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),

                        
const SizedBox(height: 16),

Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Checkbox(
      value: _acceptTerms,
      activeColor: _primaryBlue,
      onChanged: (value) {
        setState(() {
          _acceptTerms = value ?? false;
        });
      },
    ),
    Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Color(0xFF6B7080),
              fontSize: 13,
            ),
            children: [
              const TextSpan(
                text: 'I agree to the ',
              ),
              WidgetSpan(
                child: GestureDetector(
                  onTap: () {
                     launchUrl(
  Uri.parse('https://ftschamp.com/privacy-policy.html'),
);
                  },
                  child: const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      color: Color(0xFF4169E1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
                const TextSpan(
                text: ' and ',
              ),
              WidgetSpan(
                child: GestureDetector(
                  onTap: () {
                     launchUrl(
  Uri.parse(' https://ftschamp.com/terms-condition.html'),
);// Open Terms URL
                  },
                  child: const Text(
                    'Terms & Conditions',
                    style: TextStyle(
                      color: Color(0xFF4169E1),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
             
            ],
          ),
        ),
      ),
    ),
  ],
),
                     const SizedBox(height: 28),   // Login button
                      SizedBox(
  width: double.infinity,
  height: 52,
  child: Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      gradient: const LinearGradient(
        colors: [
          Color(0xFF4074DA), // primary
          Color(0xFF153C89), // primaryDark
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: ElevatedButton(
      onPressed: authProvider.isLoading ? null : _handleLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        disabledBackgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: authProvider.isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              'Login',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: Colors.white,
              ),
            ),
    ),
  ),
),
                        const SizedBox(height: 22),

                        // OR divider
                       
                        const SizedBox(height: 20),

                        // Sign up with Google button
                        
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