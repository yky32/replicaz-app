import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:replicaz/core/router/go_router_refresh_stream.dart';
import 'package:replicaz/features/auth/bloc/auth_bloc.dart';
import 'package:replicaz/features/auth/presentation/login_screen.dart';
import 'package:replicaz/features/auth/presentation/register_screen.dart';
import 'package:replicaz/features/contacts/presentation/contact_form_screen.dart';
import 'package:replicaz/features/contacts/presentation/contacts_screen.dart';
import 'package:replicaz/features/follow_ups/presentation/follow_ups_screen.dart';
import 'package:replicaz/features/home/presentation/home_screen.dart';
import 'package:replicaz/features/identities/presentation/identities_screen.dart';
import 'package:replicaz/features/identities/presentation/identity_form_screen.dart';
import 'package:replicaz/features/messaging/presentation/inbox_screen.dart';
import 'package:replicaz/features/messaging/presentation/thread_screen.dart';
import 'package:replicaz/features/notes/presentation/note_form_screen.dart';
import 'package:replicaz/features/notes/presentation/notes_screen.dart';
import 'package:replicaz/features/shell/presentation/app_shell.dart';

class AppRouter {
  AppRouter({required AuthBloc authBloc})
      : _refresh = GoRouterRefreshStream(authBloc.stream) {
    router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/messages',
      refreshListenable: _refresh,
      redirect: (context, state) {
        final status = authBloc.state.status;
        final loggedIn = authBloc.state.isAuthenticated;
        final onAuth = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        if (status == AuthStatus.unknown || status == AuthStatus.loading) {
          return null;
        }
        if (!loggedIn && !onAuth) return '/login';
        if (loggedIn && onAuth) return '/messages';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return AppShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/messages',
                  builder: (context, state) => const InboxScreen(),
                  routes: [
                    // Full-screen thread — outside shell so liquid nav does not cover composer.
                    GoRoute(
                      path: ':conversationId',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) {
                        final extra = state.extra;
                        String? title;
                        if (extra is String) {
                          title = extra;
                        } else if (extra is Map) {
                          title = extra['title'] as String?;
                        }
                        return ThreadScreen(
                          conversationId:
                              state.pathParameters['conversationId']!,
                          title: title,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/contacts',
                  builder: (context, state) => const ContactsScreen(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      builder: (context, state) => const ContactFormScreen(),
                    ),
                    GoRoute(
                      path: ':id/edit',
                      builder: (context, state) => ContactFormScreen(
                        contactId: state.pathParameters['id'],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/notes',
                  builder: (context, state) => const NotesScreen(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      builder: (context, state) => const NoteFormScreen(),
                    ),
                    GoRoute(
                      path: ':id/edit',
                      builder: (context, state) => NoteFormScreen(
                        noteId: state.pathParameters['id'],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/follow-ups',
          builder: (context, state) => const FollowUpsScreen(),
        ),
        GoRoute(
          path: '/identities',
          builder: (context, state) => const IdentitiesScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => const IdentityFormScreen(),
            ),
            GoRoute(
              path: ':id/edit',
              builder: (context, state) => IdentityFormScreen(
                identityId: state.pathParameters['id'],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  final GoRouterRefreshStream _refresh;
  late final GoRouter router;

  void dispose() => _refresh.dispose();
}
