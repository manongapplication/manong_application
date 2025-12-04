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
  bool _isCheckingPassword = false;
  String? _error;
  AppUser? _user;
  bool _hasReadInstructions = false;
  bool _hasPassword = false; // Track if user already has password
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
    _getProfileAndCheckPassword();
  }

  Future<void> _checkIfUserHasPassword() async {
    if (_user == null || _user!.phone.isEmpty) return;

    setState(() {
      _isCheckingPassword = true;
    });

    try {
      final hasPassword = await AuthService().checkIfHasPassword(_user!.phone);

      if (mounted) {
        setState(() {
          _hasPassword = hasPassword ?? false;
          _isCheckingPassword = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingPassword = false;
        });
      }
      logger.severe('Error checking password status: $e');
    }
  }

  Future<void> _getProfileAndCheckPassword() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthService().getMyProfile();

      if (!mounted) return;

      setState(() {
        _user = response;

        // Pre-fill form with existing user data
        if (response.firstName != null) {
          _firstNameController.text = response.firstName!;
        }
        if (response.lastName != null) {
          _lastNameController.text = response.lastName!;
        }
        if (response.nickname != null) {
          _nicknameController.text = response.nickname!;
        }
        if (response.email != null) {
          _emailController.text = response.email!;
        }
        if (response.addressLine != null) {
          _addressLineController.text = response.addressLine!;
        }
      });

      // After getting profile, check if user has password
      await _checkIfUserHasPassword();
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

  void submitCompletedProfile({
    required String firstName,
    required String lastName,
    String? nickname,
    required String email,
    required AddressCategory addressCategory,
    required String addressLine,
    required ValidIdType validIdType,
    required File validId,
    String? password, // Make password optional
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
        password: password, // Pass password (could be null)
      );

      if (response != null) {
        SnackBarUtils.showSuccess(
          navigatorKey.currentContext!,
          response['message'] ?? 'Profile completed successfully!',
        );

        Navigator.pop(navigatorKey.currentContext!, {'update': true});
      } else {
        SnackBarUtils.showWarning(
          navigatorKey.currentContext!,
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
        'Error completing profile: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isButtonLoading = false;
      });
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
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
      SnackBarUtils.showWarning(
        navigatorKey.currentContext!,
        'Please fill all required fields',
      );
      return;
    }

    // Validate password only if user doesn't have one
    if (!_hasPassword) {
      if (_passwordController.text.isEmpty) {
        SnackBarUtils.showWarning(
          navigatorKey.currentContext!,
          'Please enter a password',
        );
        return;
      }

      if (_passwordController.text.length < 8) {
        SnackBarUtils.showWarning(
          navigatorKey.currentContext!,
          'Password must be at least 8 characters',
        );
        return;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        SnackBarUtils.showWarning(
          navigatorKey.currentContext!,
          'Passwords do not match',
        );
        return;
      }
    }

    submitCompletedProfile(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      nickname: _nicknameController.text.isNotEmpty
          ? _nicknameController.text
          : null,
      addressCategory: _selectedCategory!,
      addressLine: _addressLineController.text,
      validIdType: _selectedValidIdType!,
      validId: _validId!,
      password: _hasPassword ? null : _passwordController.text,
    );
  }

  Widget _buildPasswordRequirements() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password Requirements:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          _buildRequirementItem(
            'At least 8 characters long',
            _passwordController.text.length >= 8,
          ),
          _buildRequirementItem(
            'Passwords match',
            _passwordController.text.isNotEmpty &&
                _passwordController.text == _confirmPasswordController.text,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            color: met ? Colors.green : Colors.grey.shade400,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: met ? Colors.green : Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordFields() {
    return Column(
      children: [
        TextFormField(
          controller: _passwordController,
          enabled: !_isButtonLoading,
          obscureText: true,
          validator: _validatePassword,
          maxLength: 128,
          onChanged: (value) {
            // Re-validate confirm password when password changes
            if (_confirmPasswordController.text.isNotEmpty) {
              _formKey.currentState!.validate();
            }
            setState(() {}); // Update UI for password requirements
          },
          decoration: inputDecoration(
            'Enter new password',
            labelStyle: TextStyle(color: AppColorScheme.primaryDark),
            labelText: 'Password',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            prefixIcon: Icon(
              Icons.lock_outline,
              color: AppColorScheme.primaryDark,
            ),
          ),
        ),

        const SizedBox(height: 16),

        TextFormField(
          controller: _confirmPasswordController,
          enabled: !_isButtonLoading,
          obscureText: true,
          validator: _validateConfirmPassword,
          maxLength: 128,
          onChanged: (value) {
            if (_formKey.currentState != null) {
              _formKey.currentState!.validate();
            }
            setState(() {}); // Update UI for password requirements
          },
          decoration: inputDecoration(
            'Confirm your password',
            labelStyle: TextStyle(color: AppColorScheme.primaryDark),
            labelText: 'Confirm Password',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            prefixIcon: Icon(
              Icons.lock_outline,
              color: AppColorScheme.primaryDark,
            ),
          ),
        ),

        const SizedBox(height: 16),

        _buildPasswordRequirements(),

        const SizedBox(height: 16),
      ],
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
            prefixIcon: Icon(
              Icons.person_outline,
              color: AppColorScheme.primaryDark,
            ),
          ),
          textCapitalization: TextCapitalization.words,
        ),

        const SizedBox(height: 16),

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
            prefixIcon: Icon(
              Icons.person_outline,
              color: AppColorScheme.primaryDark,
            ),
          ),
          textCapitalization: TextCapitalization.words,
        ),

        const SizedBox(height: 16),

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
            prefixIcon: Icon(
              Icons.alternate_email,
              color: AppColorScheme.primaryDark,
            ),
          ),
          textCapitalization: TextCapitalization.words,
        ),

        const SizedBox(height: 16),

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
            prefixIcon: Icon(
              Icons.email_outlined,
              color: AppColorScheme.primaryDark,
            ),
          ),
        ),

        const SizedBox(height: 16),

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
            prefixIcon: Icon(
              Icons.category_outlined,
              color: AppColorScheme.primaryDark,
            ),
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

        const SizedBox(height: 16),

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
            prefixIcon: Icon(
              Icons.location_on_outlined,
              color: AppColorScheme.primaryDark,
            ),
          ),
        ),

        const SizedBox(height: 16),

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
            prefixIcon: Icon(
              Icons.badge_outlined,
              color: AppColorScheme.primaryDark,
            ),
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

        const SizedBox(height: 16),

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

        const SizedBox(height: 16),

        // Show loading while checking password status
        if (_isCheckingPassword) ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(
                color: AppColorScheme.primaryColor,
              ),
            ),
          ),
        ] else if (!_hasPassword) ...[
          // Only show password fields if user doesn't have password
          _buildPasswordFields(),
        ] else ...[
          // Show message if user already has password
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You already have a password set. No need to create a new one.',
                    style: TextStyle(color: Colors.blue.shade800, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorScheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: !_isButtonLoading ? _submitInit : null,
            child: _isButtonLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(color: Colors.white),
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
                Text(
                  _hasPassword
                      ? 'Complete your profile details'
                      : 'Complete your profile and set a password',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColorScheme.primaryLight.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
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
                        'I\'ve read and understood the profile completion instructions.',
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: _buildFormInputs(),
                ),
              ),
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
        onPressed: _getProfileAndCheckPassword,
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
