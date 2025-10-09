import 'package:flutter/material.dart';
import 'package:manong_application/api/auth_service.dart';

class AuthenticatedScreen extends StatefulWidget {
  final Widget child;
  const AuthenticatedScreen({Key? key, required this.child}) : super(key: key);

  @override
  State<AuthenticatedScreen> createState() => _AuthenticatedScreenState();
}

class _AuthenticatedScreenState extends State<AuthenticatedScreen> {
  final AuthService _authService = AuthService();
  late Future<bool> _isLoggedInFuture;

  @override
  void initState() {
    super.initState();
    _isLoggedInFuture = _authService.isLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedInFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading spinner while checking
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          // Error handling
          return Scaffold(
            body: Center(child: Text('Error checking login status')),
          );
        } else {
          final isLoggedIn = snapshot.data ?? false;
          if (!isLoggedIn) {
            // Not logged in, redirect to login screen
            // Use `addPostFrameCallback` to avoid calling Navigator during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed('/register');
            });
            return const SizedBox.shrink();
          }
          // User logged in, show the protected content
          return widget.child;
        }
      },
    );
  }
}
