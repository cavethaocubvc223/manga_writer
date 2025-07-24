import 'package:flutter/material.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/main/main_screen.dart';
import 'services/user_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;
  bool _userInfoCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkUserInfo();
  }

  Future<void> _checkUserInfo() async {
    try {
      final isCompleted = await UserService.isUserInfoCompleted();
      setState(() {
        _userInfoCompleted = isCompleted;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _userInfoCompleted = false;
        _isLoading = false;
      });
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manga Creator Daily',
      theme: ThemeData(
        // Modern colorful theme for the manga creator app
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B6B),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: _isLoading
          ? const LoadingScreen()
          : (_userInfoCompleted ? const MainScreen() : const OnboardingScreen()),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF6B6B),
              Color(0xFFFFE66D),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_stories,
                size: 64,
                color: Colors.white,
              ),
              SizedBox(height: 20),
              Text(
                'Manga Creator',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}