import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:manong_application/models/app_user.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/widgets/error_state_widget.dart';
import 'package:manong_application/widgets/input_decorations.dart';
import 'package:manong_application/widgets/my_app_bar.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final Logger logger = Logger('CompleteProfileScreen');
  bool _isLoading = false;
  String? _error;
  AppUser? _user;
  final TextEditingController _firstNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  Future<void> _getProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await AuthService().getMyProfile();

      if (!mounted) return;

      setState(() {
        _user = response;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
      logger.severe('Error getting profile $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildForm() {
    return Column(
      children: [
        // TextFormField(
        //   controller: _firstNameController,
        //   validator: (value) {
        //     if (value!.trim().isEmpty) {
        //       return 'First name cannot be empty.';
        //     } else {
        //       return null;
        //     }
        //   },
        //   maxLength: 50,
        //   decoration: inputDecoration(
        //     labelText: 'First Name',
        //     hintText: '',
        //   ),
        // ),
      ],
    );
  }

  Widget _buildState() {
    if (_error != null) {
      return ErrorStateWidget(
        errorText: _error.toString(),
        onPressed: _getProfile,
      );
    }

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColorScheme.primaryColor),
      );
    }

    return _buildForm();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: myAppBar(title: 'Complete your profile'),
      body: _buildState(),
    );
  }
}
