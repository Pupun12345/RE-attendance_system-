// lib/screens/admin/admin_overtime_view_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:smartcare_app/models/overtime_model.dart';
import 'package:smartcare_app/utils/constants.dart';

class AdminOvertimeViewScreen extends StatefulWidget {
  const AdminOvertimeViewScreen({super.key});

  @override
  State<AdminOvertimeViewScreen> createState() =>
      _AdminOvertimeViewScreenState();
}

// 1. ADD TabController
class _AdminOvertimeViewScreenState extends State<AdminOvertimeViewScreen>
    with SingleTickerProviderStateMixin {
  final Color primaryBlue = const Color(0xFF0D47A1);
  final Color lightBlue = const Color(0xFFE3F2FD);

  late TabController _tabController;
  bool _isLoading = true;
  String? _token;

  // 2. CREATE LISTS FOR EACH STATUS
  List<OvertimeRecord> _pendingRequests = [];
  List<OvertimeRecord> _approvedRequests = [];
  List<OvertimeRecord> _rejectedRequests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAllOvertime();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  // 3. FETCH ALL RECORDS (NOT JUST 'approved')
  Future<void> _fetchAllOvertime() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      if (_token == null) {
        _showError("Not authorized.");
        return;
      }

      // Fetch ALL records (no status filter)
      final url = Uri.parse('$apiBaseUrl/api/v1/overtime');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final allRecords = (data['data'] as List)
            .map((r) => OvertimeRecord.fromJson(r))
            .toList();

        // Filter records into the 3 lists
        setState(() {
          _pendingRequests =
              allRecords.where((r) => r.status == 'pending').toList();
          _approvedRequests =
              allRecords.where((r) => r.status == 'approved').toList();
          _rejectedRequests =
              allRecords.where((r) => r.status == 'rejected').toList();
        });
      } else {
        _showError("Failed to load overtime records.");
      }
    } catch (e) {
      _showError("An error occurred: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 4. ADD THE ACTION HANDLER
  Future<void> _handleOvertimeAction(
      OvertimeRecord request, bool isApproved) async {
    if (_token == null) {
      _showError("Not authorized.");
      return;
    }

    final action = isApproved ? 'approve' : 'reject';
    final url = Uri.parse('$apiBaseUrl/api/v1/overtime/${request.id}/$action');

    try {
      final response = await http.put(
        url,
        headers: {'Authorization': 'Bearer $_token'},
      );

      if (response.statusCode == 200) {
        // Success: Move item from 'pending' list to the correct new list
        setState(() {
          _pendingRequests.remove(request);
          if (isApproved) {
            request.status = 'approved';
            _approvedRequests.add(request);
          } else {
            request.status = 'rejected';
            _rejectedRequests.add(request);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isApproved
                  ? "✅ Overtime for ${request.user.name} approved!"
                  : "❌ Overtime for ${request.user.name} rejected!",
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

  // 5. Main UI
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
          "Overtime View",
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        // 6. ADD THE TAB BAR
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryBlue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: primaryBlue,
          tabs: [
            Tab(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  const Icon(LucideIcons.clock3),
                  const SizedBox(width: 8),
                  Text("Pending (${_pendingRequests.length})")
                ])),
            Tab(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  const Icon(LucideIcons.checkCircle),
                  const SizedBox(width: 8),
                  Text("Approved (${_approvedRequests.length})")
                ])),
            Tab(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  const Icon(LucideIcons.xCircle),
                  const SizedBox(width: 8),
                  Text("Rejected (${_rejectedRequests.length})")
                ])),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryBlue))
          : TabBarView(
              controller: _tabController,
              children: [
                // PENDING Tab
                _buildListView(
                  requests: _pendingRequests,
                  emptyMessage: "No pending overtime requests.",
                  isPendingTab: true,
                ),
                // APPROVED Tab
                _buildListView(
                  requests: _approvedRequests,
                  emptyMessage: "No approved overtime records.",
                ),
                // REJECTED Tab
                _buildListView(
                  requests: _rejectedRequests,
                  emptyMessage: "No rejected overtime records.",
                ),
              ],
            ),
    );
  }

  // 7. HELPER: Builds a list for a tab
  Widget _buildListView({
    required List<OvertimeRecord> requests,
    required String emptyMessage,
    bool isPendingTab = false,
  }) {
    if (requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchAllOvertime,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height / 3),
            Center(
              child: Text(
                emptyMessage,
                style: const TextStyle(color: Colors.black54, fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAllOvertime,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          // Use the correct card based on the tab
          return isPendingTab
              ? _buildPendingRequestCard(request)
              : _buildHistoryRequestCard(request);
        },
      ),
    );
  }

  // 8. HELPER: Card for PENDING items (with buttons)
  Widget _buildPendingRequestCard(OvertimeRecord request) {
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
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: lightBlue,
                  child: Icon(LucideIcons.user, color: primaryBlue),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.user.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "Role: ${request.user.role}",
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 16),
            Text(
              "Date: ${DateFormat("MMM dd, yyyy").format(request.date)}",
              style: const TextStyle(color: Colors.black87, fontSize: 14),
            ),
            Text(
              "Hours: ${request.hours.toStringAsFixed(1)} hrs",
              style: const TextStyle(color: Colors.black87, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              "Reason: ${request.reason}",
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 10),
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
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _handleOvertimeAction(request, true),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text("Reject"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _handleOvertimeAction(request, false),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 9. HELPER: Card for APPROVED/REJECTED items (no buttons)
  Widget _buildHistoryRequestCard(OvertimeRecord request) {
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: lightBlue,
          child: Icon(
            request.status == 'approved'
                ? LucideIcons.check
                : LucideIcons.x,
            color: request.status == 'approved' ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          request.user.name,
          style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Date: ${DateFormat("MMM dd, yyyy").format(request.date)}\nReason: ${request.reason}",
          style: const TextStyle(color: Colors.black54),
        ),
        trailing: Text(
          "${request.hours} hrs",
          style: TextStyle(
            color: request.status == 'approved' ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}