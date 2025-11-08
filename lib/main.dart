import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:v1checkmate/pages/instructor/home.dart';
import 'package:v1checkmate/pages/student/home.dart';


void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

/*   Future<void> _login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if(username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both fields.')),
      );
      return;
    }

    setState( () => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.2:8000/auth/jwt/create/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if( response.statusCode == 200 ) {

        final data = jsonDecode(response.body);

        // decode jwt token
        final accessToken = data['access'];
        final refreshToken = data['refresh'];
        final payload = Jwt.parseJwt(accessToken);

        final role = payload['role'];
        
        final decodedUsername = payload['username'];

        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('accessToken', accessToken);
        await prefs.setString('refreshToken', refreshToken);
        await prefs.setString('role', role);
        await prefs.setString('username', decodedUsername);

        if(role == 'INSTRUCTOR') {
          Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => InstructorHome())
          );
        }
        else if(role == 'STUDENT') {
          Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => StudentHome())
          );
        }
        else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid credentials.')),
          );
        }
        
      } 
    } catch(e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred.')),
      );
    } finally {
      setState(() => isLoading = false);
    }


  }

 */
  
  Future<void> _login() async {
  final username = usernameController.text.trim();
  final password = passwordController.text.trim();

  if (username.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter both fields.')),
    );
    return;
  }

  setState(() => isLoading = true);

  await Future.delayed(const Duration(seconds: 1)); // simulate delay

  try {
    // Static test users
    const testUsers = {
      'ivan': {'password': '12345', 'role': 'INSTRUCTOR'},
      'edward': {'password': '12345', 'role': 'STUDENT'},
    };

    if (testUsers.containsKey(username) &&
        testUsers[username]!['password'] == password) {
      final role = testUsers[username]!['role']!;

      // Save data locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      await prefs.setString('role', role);

      // Navigate based on role
      if (role == 'INSTRUCTOR') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => InstructorHome()),
        );
      } else if (role == 'STUDENT') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => StudentHome()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid test credentials.')),
      );
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    setState(() => isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: Center(
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo AREA
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.check_box_outlined,
                    color: Colors.white,
                    size: 50,
                  ),
                ),

                const SizedBox(height: 20),
                const Text(
                  'CheckMate',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00B4DB),
                  )
                ),
                const Text(
                  'Smart Exam Evaluation System',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Colors.black,
                  )
                ),

                const SizedBox(height: 40),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),

                  child: Column(children: [
                    const Text(
                      "Welcome Back",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: 'Instructor or Student ID',
                        prefixIcon: const Icon(Icons.person_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        // change into _login
                    
                        onPressed: isLoading ? null : _login, 

                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: const Color(0xFF00B4DB),
                          elevation: 0,
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                'Login',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,

                                )
                              )
                          )
                        )
                      ),
                    ),

                    const SizedBox(height: 16),


                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Forgot your password?",
                        style: TextStyle(color: Colors.teal),
                      ),
                    ),

                  ],

                  ),

                ),

            ],

          ),
          ),
          
        ),
      ),
    );
    
  }
}

