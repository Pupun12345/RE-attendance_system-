import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:smartcare_app/utils/constants.dart';

// Model for the employee list
class EmployeeStatus {
  final String id;
  final String name;
  final String status;
  final String? profileImageUrl;

  EmployeeStatus({
    required this.id,
    required this.name,
    required this.status,
    this.profileImageUrl,
  });

  factory EmployeeStatus.fromJson(Map<String, dynamic> json) {
    return EmployeeStatus(
      id: json['_id'],
      name: json['name'],
      status: json['status'],
      profileImageUrl: json['profileImageUrl'],
    );
  }
}

class AttendanceDetailScreen extends StatefulWidget {
  const AttendanceDetailScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceDetailScreen> createState() => _AttendanceDetailScreenState();
}

class _AttendanceDetailScreenState extends State<AttendanceDetailScreen> {
  final Color themeBlue = const Color(0xFF0B3B8C);

  // --- IMPORTANT ---
  // Make sure this is the same IP address you used in the login screen
  //final String _apiUrl = "http://10.5.114.51:5000"; // <-- REPLACE WITH YOUR IP
  final String _apiUrl = apiBaseUrl;

  Map<String, dynamic> _summaryData = {};
  List<EmployeeStatus> _employeeList = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      // Fetch both sets of data in parallel
      final responses = await Future.wait([
        http.get(
          Uri.parse("$_apiUrl/api/v1/attendance/summary/today"),
          headers: {'Authorization': 'Bearer $token'},
        ),
        http.get(
          Uri.parse("$_apiUrl/api/v1/attendance/status/today"),
          headers: {'Authorization': 'Bearer $token'},
        ),
      ]);

      if (!mounted) return;

      // Process Summary Response
      if (responses[0].statusCode == 200) {
        _summaryData = json.decode(responses[0].body)['data'];
      } else {
        throw Exception('Failed to load summary');
      }

      // Process Employee List Response
      if (responses[1].statusCode == 200) {
        final List<dynamic> employeeJson = json.decode(responses[1].body)['data'];
        _employeeList = employeeJson
            .map((json) => EmployeeStatus.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load employee list');
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = "Could not connect to server. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: themeBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Attendance Detail",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    // Get data from summary, provide defaults
    final String presentCount = _summaryData['present']?.toString() ?? '0';
    final String absentCount = _summaryData['absent']?.toString() ?? '0';
    final String leaveCount = _summaryData['leave']?.toString() ?? '0';
    
    // NOTE: Backend logic for "Late" is not implemented.
    const String lateCount = "0"; 

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today Workforce Overview",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              buildStatCard("Present", presentCount, Colors.green),
              const SizedBox(width: 10),
              buildStatCard("Absent", absentCount, Colors.red),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              buildStatCard("Late", lateCount, Colors.orange),
              const SizedBox(width: 10),
              buildStatCard("On Leave", leaveCount, Colors.blueGrey),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "Employee List",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _employeeList.length,
              itemBuilder: (context, index) {
                final employee = _employeeList[index];
                final statusInfo = _getStatusInfo(employee.status);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: employee.profileImageUrl != null
                            ? NetworkImage(employee.profileImageUrl!)
                            : null,
                        child: employee.profileImageUrl == null
                            ? const Icon(Icons.person, size: 20)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          employee.name,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 12),
                        decoration: BoxDecoration(
                          color: statusInfo.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusInfo.text,
                          style: TextStyle(
                              color: statusInfo.color,
                              fontWeight: FontWeight.w600),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget buildStatCard(String title, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            )
          ],
        ),
      ),
    );
  }

  // Helper to get color and text for status
  ({Color color, String text}) _getStatusInfo(String status) {
    switch (status) {
      case 'present':
        return (color: Colors.green, text: 'Present');
      case 'absent':
        return (color: Colors.red, text: 'Absent');
      case 'leave':
        return (color: Colors.blueGrey, text: 'On Leave');
      case 'pending':
        return (color: Colors.orange, text: 'Pending');
      case 'rejected':
        return (color: Colors.deepOrange, text: 'Rejected');
      default:
        return (color: Colors.grey, text: 'Unknown');
    }
  }
}