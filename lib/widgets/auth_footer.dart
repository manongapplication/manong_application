import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/theme/colors.dart';

class AuthFooter extends StatefulWidget {
  const AuthFooter({super.key});

  @override
  State<AuthFooter> createState() => _AuthFooterState();
}

class _AuthFooterState extends State<AuthFooter> {
  bool _helpPressed = false;
  bool _settingsPressed = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main Action Buttons
            Row(
              children: [
                // Sign Up Button (Outlined Style)
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColorScheme.primaryColor,
                      side: BorderSide(
                        color: AppColorScheme.primaryColor,
                        width: 1.5,
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12),

                // Login Button (Filled)
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColorScheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: AppColorScheme.primaryColor.withOpacity(0.3),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/register',
                        arguments: {'isLoginFlow': true},
                      );
                    },
                    child: Text(
                      'Log In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 24),

            // Secondary Actions - Cleaner Layout
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Help Button with feedback
                  _buildInteractiveButton(
                    icon: Icons.help_outline,
                    label: 'Get Help',
                    isPressed: _helpPressed,
                    onTapDown: () => setState(() => _helpPressed = true),
                    onTapUp: () => setState(() => _helpPressed = false),
                    onTapCancel: () => setState(() => _helpPressed = false),
                    onTap: () {
                      Navigator.pushNamed(context, '/help-and-support');
                    },
                  ),

                  // Vertical Divider
                  Container(width: 1, height: 20, color: Colors.grey[300]),

                  // Settings Button with feedback
                  _buildInteractiveButton(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    isPressed: _settingsPressed,
                    onTapDown: () => setState(() => _settingsPressed = true),
                    onTapUp: () => setState(() => _settingsPressed = false),
                    onTapCancel: () => setState(() => _settingsPressed = false),
                    onTap: () {
                      Navigator.pushNamed(context, '/profile');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveButton({
    required IconData icon,
    required String label,
    required bool isPressed,
    required VoidCallback onTapDown,
    required VoidCallback onTapUp,
    required VoidCallback onTapCancel,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: Colors.grey[300],
        highlightColor: Colors.grey[200],
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
