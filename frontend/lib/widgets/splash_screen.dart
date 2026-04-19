import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/mobile_home_screen.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    if (!mounted) return;
    
    // Wait for AuthProvider to initialize
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.initialized) {
      await authProvider.initialize();
    }
    
    // Skip login for mobile and tablet (Android)
    final bool isMobileOrTablet = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    
    if (isMobileOrTablet) {
      // Directly navigate to MobileHomeScreen without authentication
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const MobileHomeScreen(),
        ),
      );
      return;
    }
    
    // For web and desktop, check authentication
    final token = await ApiService.getToken();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            token != null && authProvider.isAuthenticated ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.primary,
              cs.primary.withValues(alpha: 0.8),
              cs.secondary,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.point_of_sale_rounded,
                  size: 60,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Global POS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Professional Point of Sale System',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
