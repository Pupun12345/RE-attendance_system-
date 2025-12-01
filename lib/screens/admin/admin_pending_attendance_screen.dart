// lib/screens/admin_pending_attendance_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:smartcare_app/models/pending_attendance_model.dart';
import 'package:smartcare_app/utils/constants.dart';

class AdminPendingAttendanceScreen extends StatefulWidget {
  const AdminPendingAttendanceScreen({super.key});

  @override
  State<AdminPendingAttendanceScreen> createState() =>
      _AdminPendingAttendanceScreenState();
}

class _AdminPendingAttendanceScreenState
    extends State<AdminPendingAttendanceScreen> {
  final Color primaryBlue = const Color(0xFF0D47A1);
  final Color lightBlue = const Color(0xFFE3F2FD);

  List<PendingAttendance> _pendingRequests = [];
  bool _isLoading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _fetchPendingRequests();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  // ✅ --- 1. FETCH PENDING REQUESTS from API ---
  Future<void> _fetchPendingRequests() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      if (_token == null) {
        _showError("Not authorized.");
        return;
      }

      final url = Uri.parse('$apiBaseUrl/api/v1/attendance/pending');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _pendingRequests = (data['data'] as List)
              .map((req) => PendingAttendance.fromJson(req))
              .toList();
        });
      } else {
        _showError("Failed to load pending requests.");
      }
    } catch (e) {
      _showError("An error occurred: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ --- 2. HANDLE APPROVE/REJECT API CALL ---
  Future<void> _handleAttendanceAction(
      PendingAttendance request, bool isApproved) async {
    if (_token == null) {
      _showError("Not authorized.");
      return;
    }

    final action = isApproved ? 'approve' : 'reject';
    final url = Uri.parse('$apiBaseUrl/api/v1/attendance/${request.id}/$action');

    try {
      final response = await http.put(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        // Success: Remove from list locally for instant UI update
        setState(() {
          _pendingRequests.remove(request);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isApproved
                  ? "✅ Attendance of ${request.user.name} approved!"
                  : "❌ Attendance of ${request.user.name} rejected!",
            ),
            backgroundColor: isApproved ? Colors.green : Colors.redAccent,
          ),
        );
      } else {
        final data = jsonDecode(response.body);
        _showError(data['message'] ?? 'Failed to process request.');
      }
    } catch (e) {
      _showError("An error occurred: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Pending Attendance",
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryBlue))
          : RefreshIndicator(
              onRefresh: _fetchPendingRequests,
              child: _pendingRequests.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height / 3),
                        const Center(
                          child: Text(
                            "No pending attendance requests.",
                            style: TextStyle(color: Colors.black54, fontSize: 16),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _pendingRequests.length,
                      itemBuilder: (context, index) {
                        final request = _pendingRequests[index];
                        return _buildRequestCard(request);
                      },
                    ),
            ),
    );
  }

  // ✅ --- 3. BUILD CARD from API DATA ---
  Widget _buildRequestCard(PendingAttendance staff) {
    // --- Profile Image Logic ---
    ImageProvider profileImage =
        const AssetImage("assets/images/profile.png");
    if (staff.user.profileImageUrl != null &&
        staff.user.profileImageUrl!.isNotEmpty) {
      profileImage = NetworkImage(staff.user.profileImageUrl!);
    }
    // --- End Profile Image Logic ---

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Staff Info
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: lightBlue,
                  backgroundImage: profileImage,
                  onBackgroundImageError: (exception, stackTrace) {
                    // Handle broken image links
                  },
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff.user.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Time: ${DateFormat("hh:mm a").format(staff.checkInTime)}",
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "Date: ${DateFormat("MMM dd, yyyy").format(staff.checkInTime)}",
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    // You can add notes here if you have them
                    // Text(
                    //   "Note: ${staff.notes ?? 'N/A'}",
                    //   style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic),
                    // ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 🔹 Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text("Approve"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _handleAttendanceAction(staff, true),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text("Reject"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _handleAttendanceAction(staff, false),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}