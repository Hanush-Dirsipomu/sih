// lib/screens/enhanced_login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../components/ui_components.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'admin_dashboard.dart';
import 'institution_registration_screen.dart';
import 'student_dashboard.dart';
import 'student_onboarding_screen.dart';
import 'teacher_dashboard.dart';

class EnhancedLoginScreen extends StatefulWidget {
  const EnhancedLoginScreen({super.key});

  @override
  State<EnhancedLoginScreen> createState() => _EnhancedLoginScreenState();
}

class _EnhancedLoginScreenState extends State<EnhancedLoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _collegeIdController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'student';
  bool _isLoading = false;
  bool _obscurePassword = true;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppAnimation.slow,
      vsync: this,
    );
    _slideController = AnimationController(
      duration: AppAnimation.slow,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: AppAnimation.defaultCurve),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: AppAnimation.defaultCurve));
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _collegeIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ApiService.login(
        _collegeIdController.text.trim(),
        _passwordController.text,
        _selectedRole,
      );

      if (!mounted) return;

      if (result['success']) {
        final role = result['data']['role'];
        
        // Show success message with animation
        _showSuccessMessage();
        
        // Navigate after delay for smooth transition
        await Future.delayed(const Duration(milliseconds: 1500));
        
        if (!mounted) return;
        
        if (role == 'admin') {
          Navigator.of(context).pushReplacement(
            _createRoute(const AdminDashboard()),
          );
        } else if (role == 'teacher') {
          Navigator.of(context).pushReplacement(
            _createRoute(const TeacherDashboard()),
          );
        } else if (role == 'student') {
          final bool profileCompleted = result['data']['profile_completed'] ?? false;
          if (profileCompleted) {
            Navigator.of(context).pushReplacement(
              _createRoute(const StudentDashboard()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              _createRoute(const StudentOnboardingScreen()),
            );
          }
        }
      } else {
        _showErrorMessage(result['message'] ?? 'Login Failed!');
      }
    } catch (e) {
      _showErrorMessage('Network error. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text('Welcome! Redirecting...'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, _) => page,
      transitionsBuilder: (context, animation, _, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo and title section
                      _buildHeader(),
                      
                      const SizedBox(height: 48),
                      
                      // Login form
                      _buildLoginForm(),
                      
                      const SizedBox(height: 24),
                      
                      // Register institution link
                      _buildRegisterLink(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo with gradient background
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryRed.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.school_rounded,
            size: 50,
            color: Colors.white,
          ),
        ).animate().scale(delay: 300.ms, duration: 600.ms),
        
        const SizedBox(height: 24),
        
        // Animated title
        AnimatedTextKit(
          animatedTexts: [
            TypewriterAnimatedText(
              'Smart Curriculum',
              textStyle: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              speed: const Duration(milliseconds: 100),
            ),
          ],
          totalRepeatCount: 1,
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Streamlined education management',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildLoginForm() {
    return AnimatedCard(
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // College ID field
            CustomTextField(
              controller: _collegeIdController,
              label: 'College ID',
              hint: 'Enter your college ID',
              prefixIcon: Icons.person_outline_rounded,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your college ID';
                }
                if (value.trim().length < 3) {
                  return 'College ID must be at least 3 characters';
                }
                return null;
              },
            ).animate().slideX(delay: 400.ms, duration: 400.ms),
            
            const SizedBox(height: 20),
            
            // Password field
            CustomTextField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Enter your password',
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              obscureText: _obscurePassword,
              onSuffixIconTap: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ).animate().slideX(delay: 500.ms, duration: 400.ms),
            
            const SizedBox(height: 20),
            
            // Role selector
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Role',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRole,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedRole = newValue;
                          });
                        }
                      },
                      items: [
                        {'value': 'student', 'label': 'Student', 'icon': Icons.school_rounded},
                        {'value': 'teacher', 'label': 'Teacher', 'icon': Icons.person_rounded},
                        {'value': 'admin', 'label': 'Administrator', 'icon': Icons.admin_panel_settings_rounded},
                      ].map((role) {
                        return DropdownMenuItem<String>(
                          value: role['value'] as String,
                          child: Row(
                            children: [
                              Icon(role['icon'] as IconData, size: 20, color: AppColors.textSecondary),
                              const SizedBox(width: 12),
                              Text(role['label'] as String),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ).animate().slideX(delay: 600.ms, duration: 400.ms),
            
            const SizedBox(height: 32),
            
            // Login button
            GradientButton(
              text: 'Sign In',
              loading: _isLoading,
              onPressed: _login,
              height: 56,
            ).animate().scale(delay: 700.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.divider)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'New Institution?',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(child: Divider(color: AppColors.divider)),
          ],
        ),
        
        const SizedBox(height: 16),
        
        OutlinedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              _createRoute(const InstitutionRegistrationScreen()),
            );
          },
          icon: const Icon(Icons.add_business_rounded),
          label: const Text('Register Institution'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            side: BorderSide(color: AppColors.primaryRed.withValues(alpha: 0.5)),
            foregroundColor: AppColors.primaryRed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
          ),
        ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
      ],
    );
  }
}