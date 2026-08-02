import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:habbit/core/colors.dart';
import 'package:habbit/pages/app_shell.dart';
import 'package:habbit/pages/login.dart';

/// Decides which screen to show based on Firebase auth state.
///
/// Listening to [FirebaseAuth.authStateChanges] means sign-in (email or Google)
/// and sign-out automatically swap between [Login] and [AppShell] — no manual
/// navigation is required from those flows.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const AppShell();
        }

        return const Login();
      },
    );
  }
}
