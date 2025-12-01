import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart'; // ✅ Corrected import
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcare_app/utils/constants.dart';

class AddWorkerScreen extends StatefulWidget {
  const AddWorkerScreen({super.key});

  @override
  State<AddWorkerScreen> createState() => _AddWorkerScreenState();
}

class _AddWorkerScreenState extends State<AddWorkerScreen> {
  final Color primaryBlue = const Color(0xFF0D47A1);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isConfirmed = false;
  bool _isSaving = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedImage =
        await _picker.pickImage(source: source, imageQuality: 80);
    if (pickedImage != null) {
      setState(() {
        _profileImage = File(pickedImage.path);
      });
    }
    Navigator.pop(context);
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            alignment: WrapAlignment.center,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text("Take Photo"),
                onTap: () => _pickImage(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo, color: Colors.green),
                title: const Text("Choose from Gallery"),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.redAccent),
                title: const Text("Cancel"),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🔹 Updated Save Worker function
  void _saveWorker() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showError("Passwords do not match!");
      return;
    }

    if (!_isConfirmed) {
      _showError("Please confirm company policy before saving.");
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        _showError("Authentication error. Please log in again.");
        setState(() => _isSaving = false);
        return;
      }

      // 2. Create Multipart Request
      final url = Uri.parse('$apiBaseUrl/api/v1/users');
      var request = http.MultipartRequest('POST', url);

      // 3. Add Headers
      request.headers['Authorization'] = 'Bearer $token';

      // 4. Add Fields
      request.fields['name'] = _nameController.text;
      request.fields['userId'] = _userIdController.text;
      request.fields['phone'] = _phoneController.text;
      request.fields['password'] = _newPasswordController.text;
      request.fields['role'] = 'worker'; // Hardcode role for this screen

      // 5. Add Image (if selected)
      if (_profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profileImage', // This key must match your backend (upload.single('profileImage'))
            _profileImage!.path,
          ),
        );
      }

      // 6. Send Request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (response.statusCode == 201 && data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Worker added successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Pass true to indicate success
        }
      } else {
        _showError(data['message'] ?? 'Failed to add worker.');
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
          "Add Worker",
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
              GestureDetector(
                onTap: _showImagePickerOptions,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue[50],
                      backgroundImage:
                          _profileImage != null ? FileImage(_profileImage!) : null,
                      child: _profileImage == null
                          ? Icon(LucideIcons.camera,
                              size: 34, color: primaryBlue)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Add Profile Photo",
                      style: TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              _buildTextField(_nameController, "Name *"),
              const SizedBox(height: 16),
              _buildTextField(_userIdController, "User ID *"),
              const SizedBox(height: 16),
              _buildTextField(_phoneController, "Phone Number *",
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _newPasswordController,
                label: "New Password *",
                obscureText: _obscureNewPassword,
                onToggle: () {
                  setState(() {
                    _obscureNewPassword = !_obscureNewPassword;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: "Confirm Password *",
                obscureText: _obscureConfirmPassword,
                onToggle: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: _isConfirmed,
                    activeColor: primaryBlue,
                    onChanged: (value) {
                      setState(() {
                        _isConfirmed = value!;
                      });
                    },
                  ),
                  const Expanded(
                    child: Text(
                      "I confirm that the above details are accurate and comply with company policies.",
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveWorker,
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
                          "Save Worker",
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

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "This field is required";
        }
        if (value.length < 6) {
          return "Password must be at least 6 characters";
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: primaryBlue),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: primaryBlue,
          ),
          onPressed: onToggle,
        ),
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