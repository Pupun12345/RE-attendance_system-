// lib/screens/edit_user_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/models/user_model.dart';
import 'package:smartcare_app/utils/constants.dart';

class EditUserScreen extends StatefulWidget {
  final User user;
  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final Color primaryBlue = const Color(0xFF0D47A1);
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _userIdController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late String _selectedRole;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill the form fields with the user's data
    _nameController = TextEditingController(text: widget.user.name);
    _userIdController = TextEditingController(text: widget.user.userId);
    _phoneController = TextEditingController(text: widget.user.phone);
    _emailController = TextEditingController(text: widget.user.email ?? '');
    _selectedRole = widget.user.role;
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        _showError("Not authorized.");
        return;
      }

      final url = Uri.parse('$apiBaseUrl/api/v1/users/${widget.user.id}');
      
      final Map<String, dynamic> body = {
        'name': _nameController.text,
        'userId': _userIdController.text,
        'phone': _phoneController.text,
        'role': _selectedRole,
      };

      // Only include email if it's not empty
      if (_emailController.text.isNotEmpty) {
        body['email'] = _emailController.text;
      }

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("User updated successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Go back and indicate success
        }
      } else {
        _showError(data['message'] ?? 'Failed to update user.');
      }
    } catch (e) {
      _showError("An error occurred. Please check your connection.");
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          "Edit User",
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // (Note: Image updating is complex, so we'll skip it for this form)
              _buildTextField(_nameController, "Name *"),
              const SizedBox(height: 16),
              _buildTextField(_userIdController, "User ID *"),
              const SizedBox(height: 16),
              _buildTextField(_phoneController, "Phone Number *",
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField(_emailController, "Email",
                  keyboardType: TextInputType.emailAddress, isRequired: false),
              const SizedBox(height: 20),
              _buildRoleDropdown(),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _updateUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Save Changes",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: InputDecoration(
        labelText: 'Role *',
        labelStyle: TextStyle(color: primaryBlue),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryBlue, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      items: ['worker', 'supervisor', 'management', 'admin']
          .map((role) => DropdownMenuItem(
                value: role,
                child: Text(role[0].toUpperCase() + role.substring(1)),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedRole = value;
          });
        }
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text, bool isRequired = true}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return "This field is required";
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: primaryBlue),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryBlue, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}