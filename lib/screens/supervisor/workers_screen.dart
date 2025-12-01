import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:smartcare_app/utils/constants.dart';

// Model to hold worker data
class Worker {
  final String id; // This is the User._id
  final String name;
  final String userId; // This is the User.userId (e.g., WRK001)
  final String? profileImageUrl;

  Worker({
    required this.id,
    required this.name,
    required this.userId,
    this.profileImageUrl,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['_id'],
      name: json['name'],
      userId: json['userId'],
      profileImageUrl: json['profileImageUrl'],
    );
  }
}

class WorkersScreen extends StatefulWidget {
  // --- ADDED ---
  final String? initialSearchQuery;

  // --- UPDATED ---
  const WorkersScreen({super.key, this.initialSearchQuery});

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  final Color themeBlue = const Color(0xFF0B3B8C);
  final TextEditingController searchController = TextEditingController();

  // --- IMPORTANT ---
  // Make sure this is the same IP address you used in the login screen
  //final String _apiUrl = "http://10.5.114.51:5000"; // <-- REPLACE WITH YOUR IP
  final String _apiUrl = apiBaseUrl;

  List<Worker> _allWorkers = [];
  List<Worker> _filteredWorkers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchWorkers();
    
    // --- UPDATED ---
    if (widget.initialSearchQuery != null) {
      searchController.text = widget.initialSearchQuery!;
    }
    searchController.addListener(_filterWorkers);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchWorkers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse("$_apiUrl/api/v1/users?role=worker"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        List<dynamic> usersJson = responseData['users'];
        setState(() {
          _allWorkers = usersJson.map((json) => Worker.fromJson(json)).toList();
          _filteredWorkers = _allWorkers;
          _isLoading = false;
          _filterWorkers(); // --- ADDED to apply initial filter
        });
      } else {
        setState(() {
          _error = "Failed to load workers.";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Could not connect to server. Check your network.";
        _isLoading = false;
      });
    }
  }

  void _filterWorkers() {
    String query = searchController.text.toLowerCase();
    setState(() {
      _filteredWorkers = _allWorkers.where((worker) {
        return worker.name.toLowerCase().contains(query) ||
            worker.userId.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _markAttendance(Worker worker) async {
    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Attendance"),
          content: Text("Are you sure you want to mark ${worker.name} as PRESENT?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text("Mark Present", style: TextStyle(color: themeBlue)),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return; // User cancelled
    }

    // User confirmed, proceed with API call
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse("$_apiUrl/api/v1/attendance/mark"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'workerId': worker.id, // Send the User._id
        }),
      );

      final responseData = json.decode(response.body);
      if (!mounted) return;

      if (response.statusCode == 201) {
        _showSnackbar("Attendance marked for ${worker.name}", Colors.green);
      } else {
        _showSnackbar(responseData['message'] ?? 'Failed to mark attendance', Colors.red);
      }
    } catch (e) {
      _showSnackbar("Error: Could not connect to server.", Colors.red);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }
    if (_filteredWorkers.isEmpty) {
      return Center(
          child: Text(searchController.text.isEmpty
              ? "No workers found."
              : "No workers match your search."));
    }

    return ListView.builder(
      itemCount: _filteredWorkers.length,
      itemBuilder: (context, index) {
        final worker = _filteredWorkers[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: worker.profileImageUrl != null
                    ? NetworkImage(worker.profileImageUrl!)
                    : null,
                child: worker.profileImageUrl == null
                    ? const Icon(Icons.person, size: 26)
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(worker.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(worker.userId,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.grey)),
                ],
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => _markAttendance(worker),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeBlue,
                  foregroundColor: Colors.white, // Text color
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Take Attendance",
                    style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: AppBar(
        backgroundColor: themeBlue,
        title: const Text(
          "Workers",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search worker by name or ID...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }
}