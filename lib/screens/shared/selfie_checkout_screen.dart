import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:smartcare_app/utils/constants.dart';
import 'package:geocoding/geocoding.dart'; // ✅ ADDED THIS IMPORT

class SelfieCheckOutScreen extends StatefulWidget {
  const SelfieCheckOutScreen({super.key});

  @override
  State<SelfieCheckOutScreen> createState() => _SelfieCheckOutScreenState();
}

class _SelfieCheckOutScreenState extends State<SelfieCheckOutScreen> {
  String dateTime = "";
  String location = "Fetching location...";
  final Color themeBlue = const Color(0xFF0B3B8C);
  File? selfieImage;
  Position? _currentPosition;
  bool _isLoading = false;
  String _userName = "Unknown"; 

  final String _apiUrl = apiBaseUrl;

  @override
  void initState() {
    super.initState();
    updateDateTime();
    fetchLocation(); // ✅ This will now fetch the address
    _loadUserData(); 
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userName = prefs.getString('userName') ?? "Unknown";
    });
  }

  void updateDateTime() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        final now = DateTime.now();
        dateTime = "${now.day.toString().padLeft(2, '0')} "
            "${_month(now.month)} ${now.year} "
            "${_formatTime(now)}";
      });
    });
  }
  
  String _month(int m) {
    const months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
    return months[m-1];
  }

  String _formatTime(DateTime now) {
    int hour = now.hour;
    String ampm = hour >= 12 ? "PM" : "AM";
    hour = hour % 12 == 0 ? 12 : hour % 12;
    String minute = now.minute.toString().padLeft(2, '0');
    String second = now.second.toString().padLeft(2, '0');
    return "$hour:$minute:$second $ampm";
  }

  // ✅ UPDATED: Fetch Location & Convert to Address
  Future<void> fetchLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => location = "GPS disabled");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => location = "Location permission denied");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => location = "Permission blocked");
      return;
    }
    
    try {
      // 1. Get raw coordinates
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      _currentPosition = pos; // Save for backend API

      // 2. Convert to Address (Reverse Geocoding)
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          pos.latitude, 
          pos.longitude
        );

        if (!mounted) return;

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          // Format: "Street, City"
          setState(() {
            String city = place.locality ?? place.subAdministrativeArea ?? "";
            String area = place.thoroughfare ?? place.subLocality ?? "";
            
            if (area.isEmpty && city.isEmpty) {
               location = "Unknown Location";
            } else if (area.isEmpty) {
               location = city;
            } else {
               location = "$area, $city";
            }
          });
        } else {
          setState(() {
            location = "Address not found";
          });
        }
      } catch (e) {
        // Fallback if geocoding fails
        if (mounted) {
          setState(() {
            location = "Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}";
          });
        }
      }

    } catch (e) {
      if (mounted) {
        setState(() => location = "Error fetching location.");
      }
    }
  }

  Future<void> openCamera() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera, 
        preferredCameraDevice: CameraDevice.front, // Use front camera
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          selfieImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showError("Camera not available on this device.");
    }
  }

  Future<void> confirmCheckout() async {
    if (selfieImage == null) {
      _showError("Selfie is required");
      return;
    }
    if (_currentPosition == null) {
      _showError("Location is required. Please wait.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$_apiUrl/api/v1/attendance/checkout"),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['location'] = "${_currentPosition!.latitude},${_currentPosition!.longitude}";
      
      request.files.add(
        await http.MultipartFile.fromPath(
          'attendanceImage',
          selfieImage!.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        _showSuccess("Checked Out Successfully!");
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        _showError(responseData['message'] ?? "Check-out failed");
      }
    } catch (e) {
      _showError("Could not connect to server.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: themeBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Selfie Punch Out",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: Colors.black),
                const SizedBox(width: 8),
                Text(dateTime, style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 20),
                const SizedBox(width: 8),
                Text(_userName, style: const TextStyle(fontSize: 16)), 
              ],
            ),

            const Spacer(),

            if (selfieImage != null)
              Center(
                child: ClipOval(
                  child: Image.file(
                    selfieImage!,
                    height: 160,
                    width: 160,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            if (selfieImage != null) const SizedBox(height: 20),

            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(location, style: const TextStyle(fontSize: 14))),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading 
                    ? null 
                    : (selfieImage == null ? openCamera : confirmCheckout),
                icon: _isLoading
                    ? Container()
                    : Icon(selfieImage == null ? Icons.camera_alt : Icons.check, size: 22),
                label: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        selfieImage == null ? "Take Photo" : "Confirm Clock-Out",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}