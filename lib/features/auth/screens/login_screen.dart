// frontend/lib/features/auth/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:frontend/features/auth/screens/forgot_password_screen.dart';
import 'package:frontend/features/auth/screens/signup_screen.dart';
import 'package:frontend/features/auth/services/auth_service.dart';
import '../../../common/widgets/custom_button.dart';
import '../../../common/widgets/custom_textfield.dart';

class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService authService = AuthService();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      await authService.logIn(
        context: context,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
    });
    await authService.signInWithGoogle(context: context);
    if (mounted) {
      setState(() {
        _isGoogleLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Logo và tên ứng dụng
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/logo_projexy.png',
                            width: 120,
                            height: 120,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Projexy',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 21),
                    // Tiêu đề
                    Text(
                      tr('login'),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      tr('auth_welcome_back'),
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Form đăng nhập
                    CustomTextField(
                      controller: _emailController,
                      hintText: tr('auth_enter_your_email'),
                      labelText: tr('email'),
                      isBorder: false,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr('validation_enter_email_required');
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return tr('validation_invalid_email_format');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _passwordController,
                      hintText: tr('auth_enter_your_password'),
                      labelText: tr('password'),
                      isBorder: false,
                      obscureText: _obscurePassword,
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        onPressed: _togglePasswordVisibility,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return tr('validation_enter_password_required');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 9),
                    // Quên mật khẩu
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            ForgotPasswordScreen.routeName,
                          );
                        },
                        child: Text(
                          tr('auth_forgot_password_question'),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    // Nút đăng nhập
                    CustomButton(
                      text: tr('login'),
                      onTap: _signIn,
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 24),
                    // Divider OR
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.2),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            tr('auth_or'),
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.2),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Nút đăng nhập bằng Google
                    _GoogleSignInButton(
                      onTap: _signInWithGoogle,
                      isLoading: _isGoogleLoading,
                    ),
                    const SizedBox(height: 12),
                    // Đăng ký
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tr('auth_no_account_question'),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              SignUpScreen.routeName,
                            );
                          },
                          child: Text(
                            tr('auth_sign_up_now'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;

  const _GoogleSignInButton({required this.onTap, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.2),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: isDark
              ? Theme.of(context).colorScheme.surface
              : Colors.white,
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Theme.of(context).colorScheme.primary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/google-icon.svg',
                    width: 22,
                    height: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    tr('auth_sign_in_with_google'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
