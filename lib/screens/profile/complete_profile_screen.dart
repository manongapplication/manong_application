import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/auth_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/address_category.dart';
import 'package:manong_application/models/app_user.dart';
import 'package:manong_application/models/valid_id_type.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/snackbar_utils.dart';
import 'package:manong_application/widgets/complete_profile_instruction.dart';
import 'package:manong_application/widgets/error_state_widget.dart';
import 'package:manong_application/widgets/input_decorations.dart';
import 'package:manong_application/widgets/manong_icon.dart';
import 'package:manong_application/widgets/my_app_bar.dart';
import 'package:manong_application/widgets/single_image_picker_card.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final Logger logger = Logger('CompleteProfileScreen');
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isButtonLoading = false;
  String? _error;
  AppUser? _user;
  bool _hasReadInstructions = false;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressLineController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  AddressCategory? _selectedCategory;
  ValidIdType? _selectedValidIdType;
  File? _validId;

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  void submitCompletedProfile({
    required String firstName,
    required String lastName,
    String? nickname,
    required String email,
    required AddressCategory addressCategory,
    required String addressLine,
    required ValidIdType validIdType,
    required File validId,
    required String password,
  }) async {
    setState(() {
      _isButtonLoading = true;
    });
    try {
      final response = await AuthService().completeProfile(
        firstName: firstName,
        lastName: lastName,
        email: email,
        addressCategory: addressCategory,
        addressLine: addressLine,
        validIdType: validIdType,
        validId: validId,
        password: password,
      );

      if (response != null) {
        SnackBarUtils.showSuccess(
          navigatorKey.currentContext!,
          response['message'],
        );

        Navigator.pop(navigatorKey.currentContext!, {'update': true});
      } else {
        SnackBarUtils.showWarning(
          navigatorKey.currentContext!,
          response?['message'] ??
              'Failed completing profile. Please try again later.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });

      SnackBarUtils.showError(
        navigatorKey.currentContext!,
        'Error completing profile $_error',
      );
    } finally {
      setState(() {
        _isButtonLoading = false;
      });
    }
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

  void _submitInit() {
    if (!_hasReadInstructions) {
      SnackBarUtils.showWarning(
        navigatorKey.currentContext!,
        'Please read the instructions first',
      );

      return;
    }
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null ||
        _selectedValidIdType == null ||
        _validId == null) {
      return;
    }

    submitCompletedProfile(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      nickname: _nicknameController.text,
      addressCategory: _selectedCategory!,
      addressLine: _addressLineController.text,
      validIdType: _selectedValidIdType!,
      validId: _validId!,
      password: _passwordController.text,
    );
  }

  Widget _buildFormInputs() {
    return Column(
      children: [
        const SizedBox(height: 20),
        TextFormField(
          controller: _firstNameController,
          enabled: !_isButtonLoading,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'First name cannot be empty.';
            }
            if (value.trim().length < 2) {
              return 'First name must be at least 2 characters.';
            }
            return null;
          },
          maxLength: 50,
          decoration: inputDecoration(
            'First Name',
            labelStyle: TextStyle(color: AppColorScheme.primaryDark),
            labelText: 'First Name',
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
        ),

        TextFormField(
          controller: _lastNameController,
          enabled: !_isButtonLoading,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Last name cannot be empty.';
            }
            if (value.trim().length < 2) {
              return 'Last name must be at least 2 characters.';
            }
            return null;
          },
          maxLength: 50,
          decoration: inputDecoration(
            'Last Name',
            labelStyle: TextStyle(color: AppColorScheme.primaryDark),
            labelText: 'Last Name',
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
        ),

        TextFormField(
          controller: _nicknameController,
          enabled: !_isButtonLoading,
          validator: (value) {
            if (value != null &&
                value.trim().isNotEmpty &&
                value.trim().length < 2) {
              return 'Nickname must be at least 2 characters if provided.';
            }
            return null;
          },
          maxLength: 50,
          decoration: inputDecoration(
            'Nickname (Optional)',
            labelStyle: TextStyle(color: AppColorScheme.primaryDark),
            labelText: 'Nickname (Optional)',
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
        ),

        TextFormField(
          controller: _emailController,
          enabled: !_isButtonLoading,
          validator: (value) {
            if (value!.trim().isEmpty) {
              return 'Email cannot be empty.';
            } else {
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                return 'Please enter a valid email address';
              }
              return null;
            }
          },
          maxLength: 50,
          decoration: inputDecoration(
            'Email',
            labelStyle: TextStyle(color: AppColorScheme.primaryDark),
            labelText: 'Email',
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
        ),

        const SizedBox(height: 14),

        DropdownButtonFormField<AddressCategory>(
          dropdownColor: Colors.white,
          value: _selectedCategory,
          validator: (value) =>
              value == null ? 'Please select a category' : null,
          decoration: InputDecoration(
            labelText: 'Address Category',
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColorScheme.primaryColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColorScheme.primaryColor),
            ),
            labelStyle: TextStyle(color: AppColorScheme.primaryColor),
          ),
          items: AddressCategory.values.map((category) {
            return DropdownMenuItem<AddressCategory>(
              value: category,
              child: Text(
                category.value[0].toUpperCase() + category.value.substring(1),
              ),
            );
          }).toList(),
          onChanged: !_isButtonLoading
              ? (AddressCategory? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              : null,
        ),

        const SizedBox(height: 24),

        TextFormField(
          controller: _addressLineController,
          enabled: !_isButtonLoading,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Address cannot be empty';
            } else if (value.trim().length < 10) {
              return 'Address must be at least 10 characters';
            }
            return null;
          },
          maxLength: 255,
          decoration: inputDecoration(
            'Address',
            labelStyle: TextStyle(color: AppColorScheme.primaryDark),
            labelText: 'Address',
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
        ),

        const SizedBox(height: 14),

        DropdownButtonFormField<ValidIdType>(
          dropdownColor: Colors.white,
          value: _selectedValidIdType,
          validator: (value) =>
              value == null ? 'Please select a valid type' : null,
          decoration: InputDecoration(
            labelText: 'Upload Type (Selfie or Valid ID)',
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColorScheme.primaryColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColorScheme.primaryColor),
            ),
            labelStyle: TextStyle(color: AppColorScheme.primaryColor),
          ),
          items: ValidIdType.values.map((type) {
            return DropdownMenuItem<ValidIdType>(
              value: type,
              child: Text(
                type.value[0].toUpperCase() + type.value.substring(1),
              ),
            );
          }).toList(),
          onChanged: !_isButtonLoading
              ? (ValidIdType? newValue) {
                  setState(() {
                    _selectedValidIdType = newValue;
                  });
                }
              : null,
        ),

        const SizedBox(height: 24),

        SingleImagePickerCard(
          image: _validId,
          enabled: !_isButtonLoading,
          padding: const EdgeInsets.all(12),
          onImageSelect: (File? image) {
            setState(() {
              _validId = image;
            });
          },
        ),

        const SizedBox(height: 24),

        TextFormField(
          controller: _passwordController,
          enabled: !_isButtonLoading,
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a password';
            }
            if (value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            return null;
          },
          maxLength: 128,
          decoration: inputDecoration(
            'Password',
            labelStyle: TextStyle(color: AppColorScheme.primaryDark),
            labelText: 'Password',
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
        ),

        const SizedBox(height: 14),

        TextFormField(
          controller: _confirmPasswordController,
          enabled: !_isButtonLoading,
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
          maxLength: 128,
          onChanged: (value) {
            if (_formKey.currentState != null) {
              _formKey.currentState!.validate();
            }
          },
          decoration: inputDecoration(
            'Confirm Password',
            labelStyle: TextStyle(color: AppColorScheme.primaryDark),
            labelText: 'Confirm Password',
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
        ),

        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorScheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: !_isButtonLoading ? _submitInit : null,
            child: _isButtonLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: AppColorScheme.primaryColor,
                    ),
                  )
                : const Text('Submit'),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColorScheme.primaryColor,
                  AppColorScheme.primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Profile Avatar
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    manongIcon(size: 32),
                    Text(
                      'Welcome to Manong',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColorScheme.primaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const CompleteProfileInstruction(),
                Row(
                  children: [
                    Checkbox(
                      value: _hasReadInstructions,
                      onChanged: (value) =>
                          setState(() => _hasReadInstructions = value!),
                      activeColor: AppColorScheme.primaryColor,
                    ),
                    const Expanded(
                      child: Text(
                        'I’ve read and understood the profile completion instructions.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(),

          // -- Form --
          Stack(
            children: [
              _buildFormInputs(),
              if (!_hasReadInstructions) ...[
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColorScheme.primaryColor.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child: Text(
                            'Please Read The Instruction first',
                            style: TextStyle(
                              color: AppColorScheme.primaryLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
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

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Form(key: _formKey, child: _buildForm()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorScheme.backgroundGrey,
      appBar: myAppBar(title: 'Complete your profile'),
      body: SafeArea(child: _buildState()),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _addressLineController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
