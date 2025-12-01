// lib/screens/management/management_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // For location
import 'dart:async'; // For timer
import 'dart:convert'; // For jsonDecode
import 'package:shared_preferences/shared_preferences.dart';

// ✅ --- FIXED IMPORTS ---
import 'package:smartcare_app/screens/shared/login_screen.dart';
import 'package:smartcare_app/screens/shared/selfie_checkin_screen.dart';
import 'package:smartcare_app/screens/shared/selfie_checkout_screen.dart';
import 'package:smartcare_app/screens/shared/submit_complaint_screen.dart';
import 'package:smartcare_app/screens/shared/overtime_submission_screen.dart';
import 'package:smartcare_app/screens/shared/holiday_calendar_screen.dart';
import 'package:smartcare_app/screens/management/attendance_overview_screen.dart';
// ✅ --- END OF FIX ---

class ManagementDashboardScreen extends StatefulWidget {
  const ManagementDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ManagementDashboardScreen> createState() =>
      _ManagementDashboardScreenState();
}

class _ManagementDashboardScreenState extends State<ManagementDashboardScreen> {
  int _selectedIndex = 0;
  final Color themeBlue = const Color(0xFF0A3C7B);

  // --- State variables for user data ---
  String _userName = "User Name";
  String _userRole = "Role";
  String _userId = "ID-000";
  String _userEmail = "email@example.com";
  String _userPhone = "1234567890";
  String? _profileImageUrl;
  bool _isLoadingProfile = true;
  String _location = "Fetching location...";
  String _currentStatus = "Checked In (09:00 AM)";
  // ---

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _startStatusTimer();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');

    if (userString != null) {
      final userData = jsonDecode(userString) as Map<String, dynamic>;
      setState(() {
        _userName = userData['name'] ?? 'User Name';
        _userRole = userData['role'] ?? 'Role';
        _userId = userData['userId'] ?? 'ID-000';
        _userEmail = userData['email'] ?? 'email@example.com';
        _userPhone = userData['phone'] ?? '1234567890';
        _profileImageUrl = userData['profileImageUrl'];
      });
    }

    // Initialize screens after data is loaded
    _screens = [
      _buildHomeScreen(), // Index 0
      const AttendanceOverviewScreen(), // Index 1
      const SubmitComplaintScreen(), // Index 2
      _buildProfileScreen(), // Index 3 (Profile)
    ];

    setState(() {
      _isLoadingProfile = false;
    });
  }

  // --- (Copy/Paste _fetchLocation and _startStatusTimer from Supervisor Dashboard) ---
  void _startStatusTimer() {
    Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _currentStatus = DateTime.now().minute % 2 == 0
            ? "Checked In (${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')})"
            : "Checked Out (${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')})";
      });
    });
  }

  Future<void> _fetchLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _location = "GPS not enabled";
      });
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _location = "Location permission denied";
        });
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _location = "Location permission permanently denied";
      });
      return;
    }
    final Position position = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    setState(() {
      _location =
          "Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}";
    });
  }
  // ---

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Titles for the AppBar
    final List<String> _titles = [
      "Management Dashboard",
      "Attendance Overview",
      "Submit Complaint",
      "My Profile" // Changed from "Settings"
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeBlue,
        title: Text(
          _titles[_selectedIndex], // Use dynamic title
          style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        backgroundColor: Colors.white,
        selectedItemColor: themeBlue,
        unselectedItemColor: Colors.black54,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.fingerprint), label: "Attendance"),
          BottomNavigationBarItem(
              icon: Icon(Icons.report_problem_rounded), label: "Complaint"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "Profile"), // Changed from Settings
        ],
      ),
    );
  }

  // --- Home Screen Widget ---
  Widget _buildHomeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Self-Attendance Card ---
          buildCard(
            title: "Self-Attendance",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "Current Status: $_currentStatus",
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _location,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to SHARED screen
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const SelfieCheckInScreen()));
                        },
                        icon: const Icon(Icons.login, color: Colors.white),
                        label: const Text("Check-In",
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeBlue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                           // Navigate to SHARED screen
                           Navigator.push(context, MaterialPageRoute(builder: (context) => const SelfieCheckOutScreen()));
                        },
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text("Check-Out",
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeBlue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // --- Overtime Card ---
          buildCard(
            title: "Overtime Submission",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Submit your overtime requests for approval."),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                       // Navigate to SHARED screen
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const OvertimeSubmissionScreen()));
                    },
                    icon: const Icon(Icons.send, color: Colors.white),
                    label: const Text("Submit Overtime", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- Holiday Card ---
          buildCard(
            title: "Holiday Calendar",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Check upcoming company holidays."),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                       // Navigate to SHARED screen
                       Navigator.push(context, MaterialPageRoute(builder: (context) => HolidayCalendarScreen()));
                    },
                    icon: const Icon(Icons.calendar_month_outlined, color: Colors.white),
                    label: const Text("View Calendar", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }

  // --- Profile Screen Widget ---
  Widget _buildProfileScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 70,
            backgroundColor: themeBlue.withOpacity(0.1),
            backgroundImage: _profileImageUrl != null
                ? NetworkImage(_profileImageUrl!)
                : null,
            child: (_profileImageUrl == null)
                ? Icon(Icons.person, size: 80, color: themeBlue)
                : null,
          ),
          const SizedBox(height: 20),
          Text(
            _userName,
            style: TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold, color: themeBlue),
          ),
          const SizedBox(height: 8),
          Text(
            _userId,
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 20),
          _buildProfileDetailCard(
            icon: Icons.email_outlined,
            label: "Email",
            value: _userEmail,
          ),
          _buildProfileDetailCard(
            icon: Icons.phone_outlined,
            label: "Phone",
            value: _userPhone,
          ),
          _buildProfileDetailCard(
            icon: Icons.badge_outlined,
            label: "Role",
            value: _userRole.substring(0, 1).toUpperCase() + _userRole.substring(1),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                "Log Out",
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper for Profile Cards ---
  Widget _buildProfileDetailCard(
      {required IconData icon, required String label, required String value}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Icon(icon, color: themeBlue, size: 24),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper for Home Cards ---
  Widget buildCard({
    required String title,
    required Widget child,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}