import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:smartcare_app/utils/constants.dart';

class SubmitComplaintScreen extends StatefulWidget {
  const SubmitComplaintScreen({super.key});

  @override
  State<SubmitComplaintScreen> createState() => _SubmitComplaintScreenState();
}

class _SubmitComplaintScreenState extends State<SubmitComplaintScreen> {
  final Color themeBlue = const Color(0xFF0B3B8C);
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  bool _isSubmitting = false;

  File? selectedImage;

  final String _apiUrl = apiBaseUrl;

  Future<void> pickImageFromGallery() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  Future<void> captureImage() async {
    // This try...catch block correctly handles the error on Windows
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 80
      );
      if (picked != null) {
        setState(() => selectedImage = File(picked.path));
      }
    } catch (e) {
      _showError("Camera not available on this device.");
    }
  }

  Future<void> submitComplaint() async {
    if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
      _showError("Title and description cannot be empty.");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Get the saved token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        _showError("You are not logged in. Please restart the app.");
        setState(() => _isSubmitting = false);
        return;
      }

      // --- Create a Multipart Request ---
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$_apiUrl/api/v1/complaints"),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add text fields
      request.fields['title'] = titleController.text;
      request.fields['description'] = descriptionController.text;

      // Add image file if selected
      if (selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'complaintImage', // This MUST match the backend upload.single()
            selectedImage!.path,
            contentType: MediaType('image', 'jpeg'), // Adjust as needed
          ),
        );
      }
      
      // --- Send the request ---
      var streamedResponse = await request.send();
      
      // --- Get the response ---
      var response = await http.Response.fromStream(streamedResponse);
      final responseData = json.decode(response.body);

      if (response.statusCode == 201 && responseData['success'] == true) {
        _showSuccess("Complaint submitted successfully!");
        
        // ✅ --- FIX FOR BLACK SCREEN ---
        // We DO NOT pop the screen. We clear the form instead.
        setState(() {
          titleController.clear();
          descriptionController.clear();
          selectedImage = null;
        });
        // ✅ --- END OF FIX ---

      } else {
        _showError(responseData['message'] ?? 'Failed to submit complaint');
      }
    } catch (e) {
      _showError("Could not connect to server. Please try again.");
    } finally {
      if(mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: themeBlue,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Submit Complaint",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Complaint Title",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: "Enter title...",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text("Description",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Describe your issue...",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: captureImage, // Now safe to click
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text("Take Photo",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: pickImageFromGallery,
                    icon: Icon(Icons.file_upload, color: themeBlue),
                    label: Text("Upload Image",
                        style: TextStyle(
                            color: themeBlue, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: themeBlue, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (selectedImage != null) ...[
              const SizedBox(height: 15),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(selectedImage!,
                      height: 140, width: 140, fit: BoxFit.cover),
                ),
              ),
            ],
            
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : submitComplaint, 
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Submit Complaint",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}