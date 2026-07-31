import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/core/widgets/ambient_background.dart';
import 'package:replicaz/features/auth/bloc/auth_bloc.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AmbientBackground(
        intense: true,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                child: Form(
                  key: _formKey,
                  child: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, auth) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Replicaz',
                            maxLines: 1,
                            style: GoogleFonts.syne(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                              color: AppColors.inkMuted,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Create your space',
                            maxLines: 2,
                            style: GoogleFonts.syne(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You’ll switch identities later — start with you.',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.inkMuted,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 28),
                          TextFormField(
                            controller: _name,
                            decoration: const InputDecoration(
                              hintText: 'Display name',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            decoration:
                                const InputDecoration(hintText: 'Email'),
                            validator: (v) => v == null || !v.contains('@')
                                ? 'Enter a valid email'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _password,
                            obscureText: true,
                            decoration:
                                const InputDecoration(hintText: 'Password'),
                            validator: (v) => v == null || v.length < 6
                                ? 'At least 6 characters'
                                : null,
                          ),
                          const SizedBox(height: 22),
                          FilledButton(
                            onPressed: auth.isLoading
                                ? null
                                : () {
                                    if (!_formKey.currentState!.validate()) {
                                      return;
                                    }
                                    context.read<AuthBloc>().add(
                                          AuthRegisterRequested(
                                            email: _email.text.trim(),
                                            password: _password.text,
                                            displayName: _name.text.trim(),
                                          ),
                                        );
                                  },
                            child: Text(
                              auth.isLoading ? 'Creating…' : 'Create account',
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text(
                              'Already have an account? Sign in',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
