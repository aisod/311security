import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:security_311_user/models/namibian_regions.dart';
import 'package:security_311_user/services/auth_service.dart';
import 'package:security_311_user/screens/legal/terms_of_service_screen.dart';
import 'package:security_311_user/screens/legal/privacy_policy_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _idController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  NamibianRegions? _selectedRegion;
  IdType _selectedIdType = IdType.namibianId;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _idController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateNamibianPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Remove spaces and special characters
    final cleanPhone = value.replaceAll(RegExp(r'[^0-9+]'), '');

    // Check for Namibian phone number formats
    if (cleanPhone.startsWith('+264')) {
      if (cleanPhone.length == 12 &&
          RegExp(r'^\+264[0-9]{9}$').hasMatch(cleanPhone)) {
        return null;
      }
    } else if (cleanPhone.startsWith('264')) {
      if (cleanPhone.length == 12 &&
          RegExp(r'^264[0-9]{9}$').hasMatch(cleanPhone)) {
        return null;
      }
    } else if (RegExp(r'^[0-9]{9}$').hasMatch(cleanPhone)) {
      // Allow 9-digit local format
      return null;
    }

    return 'Enter a valid Namibian phone number';
  }

  String? _validateIdNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'ID/Passport number is required';
    }

    if (_selectedIdType == IdType.namibianId) {
      if (value.length != 11 || !RegExp(r'^[0-9]{11}$').hasMatch(value)) {
        return 'Namibian ID must be 11 digits (YYMMDDXXXXX)';
      }
    } else {
      if (value.length < 6) {
        return 'Enter a valid passport number';
      }
    }

    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }


  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain uppercase, lowercase, and number';
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

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedRegion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your region'),
          backgroundColor: Color(0xFFD32F2F),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fullName =
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
      final result = await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: fullName,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        region: _selectedRegion?.name,
        idNumber: _idController.text.trim(),
        idType: _selectedIdType.name,
      );

      setState(() => _isLoading = false);

      if (result.success && result.user != null) {
        if (mounted) {
          const roleMessage = 'Registration successful! You can now sign in.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(roleMessage),
              backgroundColor: Color(0xFF388E3C),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Registration failed'),
              backgroundColor: Color(0xFFD32F2F),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: Color(0xFFD32F2F),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Join 3:11 Security"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Create Your Security Profile",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Join thousands of Namibians staying safe together",
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32),

              // Phone Number Field
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: "Mobile Number *",
                  hintText: "+264 81 XXX XXXX",
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-()]')),
                ],
                validator: _validateNamibianPhone,
              ),
              const SizedBox(height: 20),

              // ID Type Selection
              Text(
                "ID Type *",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIdType = IdType.namibianId;
                          _idController.clear();
                        });
                      },
                      child: Row(
                        children: [
                          // ignore: deprecated_member_use
                          Radio<IdType>(
                            value: IdType.namibianId,
                            // ignore: deprecated_member_use
                            groupValue: _selectedIdType,
                            // ignore: deprecated_member_use
                            onChanged: (value) {
                              setState(() {
                                _selectedIdType = value!;
                                _idController.clear();
                              });
                            },
                          ),
                          Text(
                            "Namibian ID",
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIdType = IdType.passport;
                          _idController.clear();
                        });
                      },
                      child: Row(
                        children: [
                          // ignore: deprecated_member_use
                          Radio<IdType>(
                            value: IdType.passport,
                            // ignore: deprecated_member_use
                            groupValue: _selectedIdType,
                            // ignore: deprecated_member_use
                            onChanged: (value) {
                              setState(() {
                                _selectedIdType = value!;
                                _idController.clear();
                              });
                            },
                          ),
                          Text(
                            "Passport",
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ID Number Field
              TextFormField(
                controller: _idController,
                decoration: InputDecoration(
                  labelText: "${_selectedIdType.displayName} *",
                  hintText: _selectedIdType == IdType.namibianId
                      ? "11-digit ID number"
                      : "Passport number",
                  prefixIcon: const Icon(Icons.badge),
                ),
                keyboardType: _selectedIdType == IdType.namibianId
                    ? TextInputType.number
                    : TextInputType.text,
                inputFormatters: _selectedIdType == IdType.namibianId
                    ? [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11)
                      ]
                    : [LengthLimitingTextInputFormatter(20)],
                validator: _validateIdNumber,
              ),
              const SizedBox(height: 20),

              // Region Dropdown
              DropdownButtonFormField<NamibianRegions>(
                decoration: const InputDecoration(
                  labelText: "Region *",
                  prefixIcon: Icon(Icons.location_on),
                ),
                initialValue: _selectedRegion,
                items: NamibianRegions.values.map((region) {
                  return DropdownMenuItem(
                    value: region,
                    child: Text(region.displayName),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedRegion = value),
                validator: (value) =>
                    value == null ? 'Please select your region' : null,
              ),
              const SizedBox(height: 20),

              // Names Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: "First Name *",
                        prefixIcon: Icon(Icons.person),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: _validateName,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: "Last Name *",
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: _validateName,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email *",
                  hintText: "your@email.com",
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              const SizedBox(height: 20),

              // Password Field
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: "Password *",
                  hintText: "At least 6 characters",
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: _validatePassword,
              ),
              const SizedBox(height: 20),

              // Confirm Password Field
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: "Confirm Password *",
                  hintText: "Re-enter your password",
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: _validateConfirmPassword,
              ),
              const SizedBox(height: 32),

              // Terms and Conditions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Privacy & Security",
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Your information is encrypted and secure. Email verification is required for account activation.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRegistration,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Legal Links
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                      "By registering, you agree to our ",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TermsOfServiceScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Terms of Service",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Text(
                      " and ",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "Privacy Policy",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
