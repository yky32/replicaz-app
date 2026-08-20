import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _showPasswordLogin = false;

  static const _lifePreviews = [
    (label: 'Personal', color: AppColors.identityPersonal),
    (label: 'Job', color: AppColors.identityJob),
    (label: 'Freelance', color: AppColors.identityFreelance),
  ];

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
                                'One phone. Many lives. Keep them separate.',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.ink,
                                  fontSize: 20,
                                  height: 1.25,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'For slashers — switch Job / Side / Private so you reply as the self that belongs.',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.inkSoft,
                                  fontSize: 15.5,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final life in _lifePreviews)
                                    _LifeChip(
                                      label: life.label,
                                      color: life.color,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'After you enter: tap the life pill (top) → Switch life.',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.inkMuted,
                                  fontSize: 12.5,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 32),
                              // Primary path while backend is separate / optional
                              FilledButton(
                                onPressed: auth.isLoading
                                    ? null
                                    : () {
                                        HapticFeedback.lightImpact();
                                        context.read<AuthBloc>().add(
                                              const AuthDemoLoginRequested(),
                                            );
                                      },
                                child: Text(
                                  auth.isLoading
                                      ? 'Opening…'
                                      : 'Enter multi-life demo',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'No server needed · sample lives, chats & people',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.inkMuted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 22),
                              Row(
                                children: [
                                  const Expanded(child: Divider()),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      'or',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.inkMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Expanded(child: Divider()),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (!_showPasswordLogin)
                                OutlinedButton(
                                  onPressed: auth.isLoading
                                      ? null
                                      : () => setState(
                                            () => _showPasswordLogin = true,
                                          ),
                                  child: Text(
                                    'Sign in with email',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              else ...[
                                TextFormField(
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    hintText: 'Email',
                                  ),
                                  validator: (v) =>
                                      v == null || !v.contains('@')
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
                                  validator: (v) =>
                                      v == null || v.length < 4
                                          ? 'At least 4 characters'
                                          : null,
                                ),
                                if (auth.errorMessage != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    auth.errorMessage!,
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ],
                                if (AppConfig.useRemoteBackend) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    'Needs your backend when ready. Until then use the demo.',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppColors.inkMuted,
                                      fontSize: 12,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
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
                                    auth.isLoading
                                        ? 'Signing in…'
                                        : 'Continue with email',
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => setState(
                                    () => _showPasswordLogin = false,
                                  ),
                                  child: const Text('Hide email sign-in'),
                                ),
                              ],
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => context.go('/register'),
                                child: const Text('Create an account'),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'TestFlight preview · offline demo needs no backend',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: AppColors.inkMuted,
                                  height: 1.35,
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
        ),
      ),
    );
  }
}

class _LifeChip extends StatelessWidget {
  const _LifeChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
