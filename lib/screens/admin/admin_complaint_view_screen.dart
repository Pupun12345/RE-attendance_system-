// lib/screens/admin_complaint_view_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:smartcare_app/models/complaint_model.dart';
import 'package:smartcare_app/utils/constants.dart';

class AdminComplaintViewScreen extends StatefulWidget {
  const AdminComplaintViewScreen({super.key});

  @override
  State<AdminComplaintViewScreen> createState() =>
      _AdminComplaintViewScreenState();
}

class _AdminComplaintViewScreenState extends State<AdminComplaintViewScreen> {
  final Color primaryBlue = const Color(0xFF0D47A1);
  final Color lightBlue = const Color(0xFFE3F2FD);

  List<Complaint> _complaints = [];
  bool _isLoading = true;
  String? _token;

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  // ✅ --- Fetch Complaints from API ---
  Future<void> _fetchComplaints() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      if (_token == null) {
        _showError("Not authorized.");
        return;
      }

      final url = Uri.parse('$apiBaseUrl/api/v1/complaints');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _complaints = (data['complaints'] as List)
              .map((c) => Complaint.fromJson(c))
              .toList();
        });
      } else {
        _showError("Failed to load complaints.");
      }
    } catch (e) {
      _showError("An error occurred: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ --- Update Complaint Status via API ---
  Future<void> _updateStatus(Complaint complaint, String newStatus) async {
    if (_token == null) {
      _showError("Not authorized.");
      return;
    }

    try {
      final url = Uri.parse('$apiBaseUrl/api/v1/complaints/${complaint.id}');
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        setState(() {
          complaint.status = newStatus; // Update the UI locally
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Complaint status updated!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showError("Failed to update status.");
      }
    } catch (e) {
      _showError("An error occurred: ${e.toString()}");
    }
  }

  // ✅ --- Get Color for Status ---
  Color _getStatusColor(String status) {
    if (status == 'resolved') return Colors.green;
    if (status == 'in_progress') return Colors.orange;
    return Colors.redAccent;
  }

  // ✅ --- Show Status Options ---
  void _showStatusMenu(BuildContext context, Complaint complaint) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(LucideIcons.checkCircle, color: Colors.green),
            title: const Text("Resolved"),
            onTap: () {
              Navigator.pop(context);
              _updateStatus(complaint, 'resolved');
            },
          ),
          ListTile(
            leading: const Icon(LucideIcons.clock, color: Colors.orange),
            title: const Text("In Progress"),
            onTap: () {
              Navigator.pop(context);
              _updateStatus(complaint, 'in_progress');
            },
          ),
          ListTile(
            leading:
                const Icon(LucideIcons.alertCircle, color: Colors.redAccent),
            title: const Text("Pending"),
            onTap: () {
              Navigator.pop(context);
              _updateStatus(complaint, 'pending');
            },
          ),
        ],
      ),
    );
  }

  // ✅ --- Main Build Method (Updated) ---
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
          "View Complaints",
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryBlue))
          : _complaints.isEmpty
              ? RefreshIndicator(
                  onRefresh: _fetchComplaints,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height / 3),
                      const Center(child: Text("No complaints found.")),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchComplaints,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _complaints.length,
                    itemBuilder: (context, index) {
                      final complaint = _complaints[index];
                      return _buildComplaintCard(complaint);
                    },
                  ),
                ),
    );
  }

  // ✅ --- New Complaint Card Widget ---
  Widget _buildComplaintCard(Complaint complaint) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    complaint.title,
                    style: TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showStatusMenu(context, complaint),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(complaint.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      complaint.status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(complaint.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              complaint.description,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
            ),
            const Divider(height: 20),
            Row(
              children: [
                Icon(LucideIcons.user, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  "${complaint.user.name} (${complaint.user.userId})",
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                const Spacer(),
                Icon(LucideIcons.calendar, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  DateFormat("MMM dd, yyyy").format(complaint.createdAt),
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}