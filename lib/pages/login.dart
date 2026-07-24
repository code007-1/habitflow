import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habbit/core/colors.dart';

/// Web OAuth client id from google-services.json (`client_type: 3`).
/// Required as `serverClientId` so Android returns an `idToken` usable by
/// Firebase Auth.
const String _serverClientId =
    '538906972899-7193kkojb2tvhiqimsdfjr7fru71r0e2.apps.googleusercontent.com';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _googleSignInInitialized = false;

  // ── UI state ───────────────────────────────────────────────────────────────
  bool _isRegisterMode = false;
  bool _obscurePassword = true;
  bool _submitting = false; // email/password flow
  bool _googleBusy = false; // Google flow

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<UserCredential> signInWithGoogle() async {
    // On web, google_sign_in v7's `authenticate()` is unsupported. Let Firebase
    // Auth drive the OAuth popup instead — it uses the `authDomain` configured
    // in firebase_options.dart.
    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider();
      return FirebaseAuth.instance.signInWithPopup(googleProvider);
    }

    // Mobile/desktop: google_sign_in v7 uses a singleton that must be
    // initialized once before any authentication call.
    final GoogleSignIn signIn = GoogleSignIn.instance;
    if (!_googleSignInInitialized) {
      await signIn.initialize(serverClientId: _serverClientId);
      _googleSignInInitialized = true;
    }

    final GoogleSignInAccount googleUser = await signIn.authenticate();

    // In v7 `authentication` is a synchronous getter exposing only `idToken`.
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    // Create a Firebase credential from the Google id token.
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with the Google credential.
    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  // ── Actions ──────────────────────────────────────────────────────────────
  Future<void> _submitEmailPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Please enter your email and password', isError: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      if (_isRegisterMode) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      // AuthGate listens to authStateChanges and swaps to the app on success.
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? 'Authentication failed', isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _googleBusy = true);
    try {
      await signInWithGoogle();
      // AuthGate handles navigation once signed in.
    } on GoogleSignInException catch (e) {
      _showSnack('Google sign-in failed: ${e.code.name}', isError: true);
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? 'Google sign-in failed', isError: true);
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final busy = _submitting || _googleBusy;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBrand(),
                  const SizedBox(height: 32),
                  _buildCard(busy),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Logo badge + app name + tagline.
  Widget _buildBrand() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowBrand,
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_fire_department_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'HabitFlow',
          style: GoogleFonts.ubuntu(
            color: AppColors.grey7,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Build better habits, one day at a time',
          textAlign: TextAlign.center,
          style: GoogleFonts.ubuntu(
            color: AppColors.grey5,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(bool busy) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.grey3),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isRegisterMode ? 'Create your account' : 'Welcome back',
            style: GoogleFonts.ubuntu(
              color: AppColors.grey7,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isRegisterMode
                ? 'Start tracking your habits today.'
                : 'Sign in to continue your streaks.',
            style: GoogleFonts.ubuntu(
              color: AppColors.grey5,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'you@example.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePassword,
            onSubmitted: (_) => busy ? null : _submitEmailPassword(),
            suffix: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppColors.grey5,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 24),
          _buildPrimaryButton(busy),
          const SizedBox(height: 20),
          _buildDivider(),
          const SizedBox(height: 20),
          _buildGoogleButton(busy),
          const SizedBox(height: 20),
          _buildModeToggle(busy),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.ubuntu(
            color: AppColors.grey6,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          onSubmitted: onSubmitted,
          style: GoogleFonts.ubuntu(color: AppColors.grey7, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.ubuntu(color: AppColors.grey4, fontSize: 14),
            prefixIcon: Icon(icon, color: AppColors.grey5, size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: AppColors.grey2,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(bool busy) {
    return GestureDetector(
      onTap: busy ? null : _submitEmailPassword,
      child: Opacity(
        opacity: busy ? 0.7 : 1,
        child: Container(
          width: double.infinity,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowBrand,
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: _submitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  _isRegisterMode ? 'Create Account' : 'Sign In',
                  style: GoogleFonts.ubuntu(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.grey3)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: GoogleFonts.ubuntu(color: AppColors.grey4, fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: AppColors.grey3)),
      ],
    );
  }

  Widget _buildGoogleButton(bool busy) {
    return GestureDetector(
      onTap: busy ? null : _handleGoogleSignIn,
      child: Container(
        width: double.infinity,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.grey3, width: 1.5),
        ),
        child: _googleBusy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google "G" wordmark in its signature blue.
                  Text(
                    'G',
                    style: GoogleFonts.ubuntu(
                      color: const Color(0xFF4285F4),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: GoogleFonts.ubuntu(
                      color: AppColors.grey7,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildModeToggle(bool busy) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            _isRegisterMode
                ? 'Already have an account? '
                : "Don't have an account? ",
            style: GoogleFonts.ubuntu(color: AppColors.grey5, fontSize: 14),
          ),
          GestureDetector(
            onTap: busy
                ? null
                : () => setState(() => _isRegisterMode = !_isRegisterMode),
            child: Text(
              _isRegisterMode ? 'Sign in' : 'Register',
              style: GoogleFonts.ubuntu(
                color: AppColors.primaryDeep,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
