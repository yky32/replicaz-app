import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:replicaz/app/theme/app_colors.dart';
import 'package:replicaz/core/config/app_config.dart';
import 'package:replicaz/core/widgets/ambient_background.dart';
import 'package:replicaz/features/auth/bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _motion.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _motion, curve: Curves.easeOutCubic);
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(fade);

    return Scaffold(
      body: AmbientBackground(
        intense: true,
        child: SafeArea(
          child: FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: slide,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
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
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.2,
                                  height: 0.95,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'One phone. Many lives.\nChat as the self that belongs.',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.inkSoft,
                                  fontSize: 17,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (AppConfig.useRemoteBackend) ...[
                                const SizedBox(height: 12),
                                Text(
                                  'Backend not up? Use offline demo below.\n'
                                  'Local docker (when ready):\n'
                                  'alice@replicaz.local / password',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.inkMuted,
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 40),
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
                                decoration: const InputDecoration(
                                  hintText: 'Password',
                                ),
                                validator: (v) => v == null || v.length < 4
                                    ? 'At least 4 characters'
                                    : null,
                              ),
                              if (auth.errorMessage != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  auth.errorMessage!,
                                  style:
                                      const TextStyle(color: AppColors.danger),
                                ),
                              ],
                              const SizedBox(height: 22),
                              FilledButton(
                                onPressed: auth.isLoading
                                    ? null
                                    : () {
                                        if (!_formKey.currentState!
                                            .validate()) {
                                          return;
                                        }
                                        context.read<AuthBloc>().add(
                                              AuthLoginRequested(
                                                email: _email.text.trim(),
                                                password: _password.text,
                                              ),
                                            );
                                      },
                                child: Text(
                                  auth.isLoading ? 'Signing in…' : 'Continue',
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: auth.isLoading
                                    ? null
                                    : () {
                                        context.read<AuthBloc>().add(
                                              const AuthDemoLoginRequested(),
                                            );
                                      },
                                child: Text(
                                  auth.isLoading
                                      ? 'Loading demo…'
                                      : 'Browse offline demo',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No server · sample chats & identities for UI flow',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.inkMuted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextButton(
                                onPressed: () => context.go('/register'),
                                child: const Text('Create an account'),
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
        ),
      ),
    );
  }
}
