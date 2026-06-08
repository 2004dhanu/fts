import 'package:bb/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (_formKey.currentState!.validate()) {
      if (_newPasswordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('New passwords do not match'), backgroundColor: Colors.red),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final result = await authProvider.changePassword(
        _usernameController.text.trim(),
        _oldPasswordController.text,
        _newPasswordController.text,
      );

      if (mounted) {
        if (result['success'] == true) {
          // Show success dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 60),
                    SizedBox(height: 16),
                    Text(
                      'Password Changed!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                content: Text(
                  result['message'] ?? 'Your password has been changed successfully.',
                  textAlign: TextAlign.center,
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Go back to login
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6C63FF),
                    ),
                    child: Text('Back to Login'),
                  ),
                ],
              );
            },
          );
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to change password'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Change Password', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Color(0xFF6C63FF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.password, size: 30, color: Color(0xFF6C63FF)),
              ),
              SizedBox(height: 24),
              Text(
                'Change Password',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Update your password to keep your account secure',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        hintText: 'User Name',
                        prefixIcon: Icon(Icons.person_outline, color: Colors.grey),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Username is required' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _oldPasswordController,
                      obscureText: _obscureOld,
                      decoration: InputDecoration(
                        hintText: 'Old Password',
                        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureOld ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureOld = !_obscureOld),
                        ),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Old password is required' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      decoration: InputDecoration(
                        hintText: 'New Password',
                        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'New password is required';
                        if (value!.length < 4) return 'Password must be at least 4 characters';
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        hintText: 'Confirm New Password',
                        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Please confirm your new password' : null,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _handleChangePassword,
                      child: authProvider.isLoading
                          ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('Update Password'),
                    ),
                    SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Back to Login', style: TextStyle(color: Color(0xFF6C63FF))),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}