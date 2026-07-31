import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:replicaz/app/router.dart';
import 'package:replicaz/app/theme/app_theme.dart';
import 'package:replicaz/core/bootstrap/app_bloc_providers.dart';
import 'package:replicaz/features/auth/bloc/auth_bloc.dart';

class ReplicazApp extends StatelessWidget {
  const ReplicazApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppBlocProviders(child: _AppView());
  }
}

class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  AppRouter? _appRouter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _appRouter ??= AppRouter(authBloc: context.read<AuthBloc>());
  }

  @override
  void dispose() {
    _appRouter?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = _appRouter!.router;
    return MaterialApp.router(
      title: 'Replicaz',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
