// lib/screens/shared/login_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


// ✅ --- FIXED IMPORTS ---
import 'package:smartcare_app/screens/admin/admin_dashboard_screen.dart';
import 'package:smartcare_app/screens/supervisor/supervisor_dashboard_screen.dart';
import 'package:smartcare_app/screens/management/management_dashboard_screen.dart'; // ✅ ADDED THIS
import 'package:smartcare_app/utils/constants.dart';
// ✅ --- END OF FIX ---

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoggingIn = false;
  final Color primaryBlue = const Color(0xFF0D47A1);

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError("Please enter email and password.");
      return;
    }
    setState(() => _isLoggingIn = true);

    try {
      final url = Uri.parse('$apiBaseUrl/api/v1/auth/login');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        
        // --- ROLE-BASED NAVIGATION ---
        final user = data['user'];
        final String role = user['role'];

        // Save token, user object, and name (for supervisor dashboard)
        await prefs.setString('token', data['token']);
        await prefs.setString('user', jsonEncode(user));
        await prefs.setString('userName', user['name']); // Supervisor app needs this

        if (!mounted) return;

        // ✅ --- THIS IS THE FULL, CORRECT NAVIGATION LOGIC ---
        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
          );
        } else if (role == 'supervisor') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SupervisorDashboardScreen()),
          );
        } else if (role == 'management') {
          Navigator.pushReplacement( 
            context,
            MaterialPageRoute(
              builder: (context) => const ManagementDashboardScreen(),
             ),
           );
        } else {
          _showError("Your role is not authorized to log in.");
           setState(() => _isLoggingIn = false);
        }
        // --- END ROLE-BASED NAVIGATION ---

      } else {
        _showError(data['message'] ?? 'Invalid credentials.');
        setState(() => _isLoggingIn = false);
      }
    } catch (e) {
      _showError("Could not connect to server. Check your API URL.");
      setState(() => _isLoggingIn = false);
    }
  }

  void _handleForgotPassword(String email) async {
    // (This code is from your admin_login_screen.dart, it's correct)
    if (email.isEmpty) return;
    final url = Uri.parse('$apiBaseUrl/api/v1/auth/forgotpassword');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      final data = jsonDecode(response.body);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']),
            backgroundColor: data['success'] == true ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showError("Server error. Could not send reset link.");
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    // (This code is from your admin_login_screen.dart, it's correct)
    final TextEditingController emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Forgot Password"),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: "Enter your registered email",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () =>
                _handleForgotPassword(emailController.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          "Login",
          style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 180,
                child: Lottie.asset(
                  "assets/lottie/admin_login.json",
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Accurate attendance. Anytime. Anywhere.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email or User ID",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: primaryBlue,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoggingIn ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoggingIn
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Login",
                          style: TextStyle(
                              fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => _showForgotPasswordDialog(context),
                child: Text(
                  "Forgot Password?",
                  style: TextStyle(color: primaryBlue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}