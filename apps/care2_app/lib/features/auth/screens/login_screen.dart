import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';

/// Premium login/register/forgot-password screen with animated mode transitions.
class LoginScreen extends ConsumerStatefulWidget {
  final String? initialMode;
  const LoginScreen({super.key, this.initialMode});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

enum _AuthMode { login, register, forgotPassword, resetPassword }

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _resetTokenController = TextEditingController();
  final _newPasswordController = TextEditingController();

  _AuthMode _mode = _AuthMode.login;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _obscureNewPassword = true;
  String? _resetToken; // Stored after forgot-password response

  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    if (widget.initialMode == 'register') {
      _mode = _AuthMode.register;
    }
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..forward();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _resetTokenController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _switchMode(_AuthMode newMode) {
    setState(() {
      _mode = newMode;
      _formKey.currentState?.reset();
    });
    ref.read(authProvider.notifier).clearError();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(authProvider.notifier);
    bool success = false;

    switch (_mode) {
      case _AuthMode.login:
        success = await notifier.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
        if (success && mounted) context.go('/home');
        break;

      case _AuthMode.register:
        success = await notifier.register(
          _emailController.text.trim(),
          _passwordController.text,
          _displayNameController.text.trim(),
        );
        if (success && mounted) context.go('/onboarding');
        break;

      case _AuthMode.forgotPassword:
        final token = await notifier.forgotPassword(
          _emailController.text.trim(),
        );
        if (token != null && mounted) {
          setState(() {
            _resetToken = token;
            _resetTokenController.text = token;
            _mode = _AuthMode.resetPassword;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Reset code generated! Enter your new password.'),
              backgroundColor: Care2Theme.primary.withValues(alpha: 0.9),
            ),
          );
        }
        break;

      case _AuthMode.resetPassword:
        success = await notifier.resetPassword(
          _resetTokenController.text.trim(),
          _newPasswordController.text,
        );
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Password reset! You can now log in.'),
              backgroundColor: Care2Theme.primary.withValues(alpha: 0.9),
            ),
          );
          _switchMode(_AuthMode.login);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1117), Color(0xFF1A1A2E), Color(0xFF0F3460)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    _buildLogo(),
                    const SizedBox(height: 28),
                    _buildTitle(),
                    const SizedBox(height: 8),
                    _buildSubtitle(),
                    const SizedBox(height: 36),
                    _buildForm(auth),
                    const SizedBox(height: 16),
                    _buildErrorBanner(auth),
                    const SizedBox(height: 8),
                    _buildSubmitButton(auth),
                    const SizedBox(height: 20),
                    _buildModeSwitch(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Logo ──
  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(scale: _pulseAnim.value, child: child);
      },
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: Care2Theme.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: Care2Theme.primary.withValues(alpha: 0.35),
              blurRadius: 35,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Icon(
          _mode == _AuthMode.forgotPassword || _mode == _AuthMode.resetPassword
              ? Icons.lock_reset_rounded
              : _mode == _AuthMode.register
                  ? Icons.person_add_rounded
                  : Icons.fingerprint,
          size: 44,
          color: const Color(0xFF003300),
        ),
      ),
    );
  }

  // ── Title ──
  Widget _buildTitle() {
    final title = switch (_mode) {
      _AuthMode.login => 'Welcome Back',
      _AuthMode.register => 'Create Account',
      _AuthMode.forgotPassword => 'Forgot Password',
      _AuthMode.resetPassword => 'Reset Password',
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: ShaderMask(
        key: ValueKey(title),
        shaderCallback: (bounds) =>
            Care2Theme.primaryGradient.createShader(bounds),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  // ── Subtitle ──
  Widget _buildSubtitle() {
    final sub = switch (_mode) {
      _AuthMode.login =>
        'Sign in with your credentials to access your health data from any device.',
      _AuthMode.register =>
        'Create your Care 2.0 identity for cross-device health syncing.',
      _AuthMode.forgotPassword =>
        'Enter your email and we\'ll generate a reset code for you.',
      _AuthMode.resetPassword =>
        'Enter the reset code and choose a new password.',
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        sub,
        key: ValueKey(sub),
        textAlign: TextAlign.center,
        style: TextStyle(color: Care2Theme.textSecondary, fontSize: 14, height: 1.5),
      ),
    );
  }

  // ── Form ──
  Widget _buildForm(AuthState auth) {
    return Form(
      key: _formKey,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        child: Column(
          children: [
            // Display Name (Register only)
            if (_mode == _AuthMode.register) ...[
              _glassField(
                controller: _displayNameController,
                hint: 'Display Name',
                icon: Icons.badge_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter a display name.';
                  if (v.trim().length < 2) return 'At least 2 characters.';
                  return null;
                },
              ),
              const SizedBox(height: 14),
            ],

            // Email (all modes except resetPassword)
            if (_mode != _AuthMode.resetPassword)
              _glassField(
                controller: _emailController,
                hint: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter your email.';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                    return 'Enter a valid email.';
                  }
                  return null;
                },
              ),

            // Password (login & register)
            if (_mode == _AuthMode.login || _mode == _AuthMode.register) ...[
              const SizedBox(height: 14),
              _glassField(
                controller: _passwordController,
                hint: 'Password',
                icon: Icons.lock_outline,
                obscure: _obscurePassword,
                onToggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter your password.';
                  if (v.length < 6) return 'At least 6 characters.';
                  return null;
                },
              ),
            ],

            // Confirm Password (register)
            if (_mode == _AuthMode.register) ...[
              const SizedBox(height: 14),
              _glassField(
                controller: _confirmPasswordController,
                hint: 'Confirm Password',
                icon: Icons.lock_outline,
                obscure: _obscureConfirm,
                onToggleObscure: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (v) {
                  if (v != _passwordController.text) {
                    return 'Passwords do not match.';
                  }
                  return null;
                },
              ),
            ],

            // Forgot password link (login only)
            if (_mode == _AuthMode.login) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _switchMode(_AuthMode.forgotPassword),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: Care2Theme.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],

            // Reset token + new password fields
            if (_mode == _AuthMode.resetPassword) ...[
              _glassField(
                controller: _resetTokenController,
                hint: 'Reset Code',
                icon: Icons.vpn_key_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter the reset code.';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _glassField(
                controller: _newPasswordController,
                hint: 'New Password',
                icon: Icons.lock_outline,
                obscure: _obscureNewPassword,
                onToggleObscure: () =>
                    setState(() => _obscureNewPassword = !_obscureNewPassword),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter a new password.';
                  if (v.length < 6) return 'At least 6 characters.';
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Error banner ──
  Widget _buildErrorBanner(AuthState auth) {
    if (auth.error == null || auth.error!.isEmpty) return const SizedBox.shrink();
    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Care2Theme.riskRed.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Care2Theme.riskRed.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Care2Theme.riskRed, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                auth.error!,
                style: TextStyle(color: Care2Theme.riskRed, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Submit button ──
  Widget _buildSubmitButton(AuthState auth) {
    final label = switch (_mode) {
      _AuthMode.login => 'Sign In',
      _AuthMode.register => 'Create Account',
      _AuthMode.forgotPassword => 'Send Reset Code',
      _AuthMode.resetPassword => 'Reset Password',
    };
    final icon = switch (_mode) {
      _AuthMode.login => Icons.login_rounded,
      _AuthMode.register => Icons.person_add_rounded,
      _AuthMode.forgotPassword => Icons.send_rounded,
      _AuthMode.resetPassword => Icons.lock_reset_rounded,
    };

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: auth.isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Care2Theme.primary,
          foregroundColor: const Color(0xFF003300),
          disabledBackgroundColor: Care2Theme.primary.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child: auth.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF003300),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Mode switch links ──
  Widget _buildModeSwitch() {
    return Column(
      children: [
        if (_mode == _AuthMode.login) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Don't have an account?  ",
                  style: TextStyle(color: Care2Theme.textTertiary, fontSize: 14)),
              GestureDetector(
                onTap: () => _switchMode(_AuthMode.register),
                child: Text(
                  'Sign Up',
                  style: TextStyle(
                    color: Care2Theme.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (_mode == _AuthMode.register) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Already have an account?  ',
                  style: TextStyle(color: Care2Theme.textTertiary, fontSize: 14)),
              GestureDetector(
                onTap: () => _switchMode(_AuthMode.login),
                child: Text(
                  'Sign In',
                  style: TextStyle(
                    color: Care2Theme.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (_mode == _AuthMode.forgotPassword ||
            _mode == _AuthMode.resetPassword) ...[
          TextButton.icon(
            onPressed: () => _switchMode(_AuthMode.login),
            icon: Icon(Icons.arrow_back_rounded,
                size: 18, color: Care2Theme.accent),
            label: Text(
              'Back to Sign In',
              style: TextStyle(color: Care2Theme.accent, fontSize: 14),
            ),
          ),
        ],
        const SizedBox(height: 4),
        // Cross-device sync badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.devices_rounded,
                  size: 16, color: Care2Theme.primary.withValues(alpha: 0.7)),
              const SizedBox(width: 8),
              Text(
                'Sync across all your devices',
                style: TextStyle(
                  color: Care2Theme.textTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Glass text field ──
  Widget _glassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: Care2Theme.glassDecoration(opacity: 0.06, borderRadius: 18),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Care2Theme.textTertiary),
          prefixIcon: Icon(icon, color: Care2Theme.primary, size: 22),
          suffixIcon: onToggleObscure != null
              ? IconButton(
                  icon: Icon(
                    obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Care2Theme.textTertiary,
                    size: 20,
                  ),
                  onPressed: onToggleObscure,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          errorStyle: TextStyle(color: Care2Theme.riskRed, fontSize: 12),
        ),
        validator: validator,
      ),
    );
  }
}
