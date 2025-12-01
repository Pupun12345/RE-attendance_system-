// lib/screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:smartcare_app/screens/shared/manage_users_screen.dart';
import 'package:smartcare_app/screens/admin/admin_reports_screen.dart';
import 'package:smartcare_app/screens/admin/admin_settings_screen.dart';
import 'package:smartcare_app/screens/admin/admin_holiday_setup_screen.dart';
import 'package:smartcare_app/screens/admin/admin_summary_dashboard_screen.dart';
import 'package:smartcare_app/screens/admin/admin_overtime_view_screen.dart';
import 'package:smartcare_app/screens/admin/admin_complaint_view_screen.dart';
import 'package:smartcare_app/screens/admin/admin_pending_attendance_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  final Color primaryBlue = const Color(0xFF0D47A1);
  final Color lightBlue = const Color(0xFFE3F2FD);

  final List<String> _titles = [
    "Home",
    "Dashboard Summary",
    "Manage Users",
    "Reports",
    "Settings",
  ];

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 隼 Main Home Dashboard Cards
  Widget _buildHomeDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDashboardCard(
            icon: LucideIcons.users,
            title: "Manage Management Staff",
            subtitle: "Add, edit, or remove management-level employees.",
            isManagementCard: true,
          ),
          _buildDashboardCard(
            icon: LucideIcons.userCog,
            title: "Manage Supervisors",
            subtitle: "Handle supervisor accounts and assign roles.",
            isSupervisorCard: true,
          ),
          _buildDashboardCard(
            icon: LucideIcons.user,
            title: "Manage Workers",
            subtitle: "Oversee general worker profiles and attendance.",
            isWorkerCard: true,
          ),
          _buildDashboardCard(
            icon: LucideIcons.clock8,
            title: "Overtime View",
            subtitle:
                "Monitor and approve overtime records submitted by staff and workers.",
            isOvertimeCard: true,
          ),
          _buildDashboardCard(
            icon: LucideIcons.messageCircle,
            title: "Complaint View",
            subtitle:
                "Review and address complaints or feedback raised by employees promptly.",
            isComplaintCard: true,
          ),
          _buildDashboardCard(
            icon: LucideIcons.calendarDays,
            title: "Set Holidays",
            subtitle: "Configure company holidays and special events.",
            isHolidayCard: true,
          ),

          // ✅ --- Pending Attendance Card REMOVED from here ---
        ],
      ),
    );
  }

  // 隼 Reusable Dashboard Card Widget
  Widget _buildDashboardCard({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isHolidayCard = false,
    bool isManagementCard = false,
    bool isSupervisorCard = false,
    bool isWorkerCard = false,
    bool isOvertimeCard = false,
    bool isComplaintCard = false,
    // ✅ Parameter 'isPendingAttendanceCard' removed
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: lightBlue,
                  child: Icon(icon, color: primaryBlue, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // 隼 Navigation Logic
                  if (isHolidayCard) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminHolidaySetupScreen(),
                      ),
                    );
                  } else if (isManagementCard) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ManageUsersScreen(roleFilter: 'management'),
                      ),
                    );
                  } else if (isSupervisorCard) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ManageUsersScreen(roleFilter: 'supervisor'),
                      ),
                    );
                  } else if (isWorkerCard) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ManageUsersScreen(roleFilter: 'worker'),
                      ),
                    );
                  } else if (isOvertimeCard) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminOvertimeViewScreen(),
                      ),
                    );
                  } else if (isComplaintCard) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminComplaintViewScreen(),
                      ),
                    );
                  // ✅ 'else if' block for Pending Attendance removed
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("$title section coming soon!")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  "View Details",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 隼 Define pages for navbar navigation
    final List<Widget> _pages = [
      _buildHomeDashboard(),
      const AdminSummaryDashboardScreen(),
      const ManageUsersScreen(),
      const AdminReportsScreen(),
      const AdminSettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
        title: Text(
          _titles[_selectedIndex],
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryBlue,
        unselectedItemColor: Colors.black54,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.layoutDashboard),
            label: "Dashboard",
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.users),
            label: "Users",
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.barChart2),
            label: "Reports",
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}