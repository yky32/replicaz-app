import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:replicaz/core/router/go_router_refresh_stream.dart';
import 'package:replicaz/features/auth/bloc/auth_bloc.dart';
import 'package:replicaz/features/auth/presentation/login_screen.dart';
import 'package:replicaz/features/auth/presentation/register_screen.dart';
import 'package:replicaz/features/contacts/presentation/contact_form_screen.dart';
import 'package:replicaz/features/contacts/presentation/contacts_screen.dart';
import 'package:replicaz/features/desk/presentation/desk_screen.dart';
import 'package:replicaz/features/identities/presentation/identities_screen.dart';
import 'package:replicaz/features/identities/presentation/identity_form_screen.dart';
import 'package:replicaz/features/messaging/presentation/inbox_screen.dart';
import 'package:replicaz/features/messaging/presentation/thread_screen.dart';
import 'package:replicaz/features/notes/presentation/note_form_screen.dart';
import 'package:replicaz/features/receipts/presentation/receipt_capture_screen.dart';
import 'package:replicaz/features/settings/presentation/settings_screen.dart';
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
        final loc = state.matchedLocation;
        final onAuth = loc == '/login' || loc == '/register';

        if (status == AuthStatus.unknown || status == AuthStatus.loading) {
          return null;
        }
        if (!loggedIn && !onAuth) return '/login';
        if (loggedIn && onAuth) return '/messages';

        // Legacy paths → slasher IA
        if (loc == '/home' || loc == '/notes') return '/desk';
        if (loc == '/follow-ups') return '/desk';
        if (loc.startsWith('/notes/')) {
          return loc.replaceFirst('/notes', '/desk/notes');
        }
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
            // 0 — Chats
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/messages',
                  builder: (context, state) => const InboxScreen(),
                  routes: [
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
            // 1 — Circle (people)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/contacts',
                  builder: (context, state) => const ContactsScreen(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      builder: (context, state) => ContactFormScreen(
                        initialName: state.uri.queryParameters['name'],
                      ),
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
            // 2 — Desk (notes + follow-ups)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/desk',
                  builder: (context, state) => const DeskScreen(),
                  routes: [
                    GoRoute(
                      path: 'notes/new',
                      builder: (context, state) => const NoteFormScreen(),
                    ),
                    GoRoute(
                      path: 'notes/:id/edit',
                      builder: (context, state) => NoteFormScreen(
                        noteId: state.pathParameters['id'],
                      ),
                    ),
                    GoRoute(
                      path: 'slips/scan',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) => const ReceiptCaptureScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/identities',
          parentNavigatorKey: _rootNavigatorKey,
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
        GoRoute(
          path: '/settings',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    );
  }

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  final GoRouterRefreshStream _refresh;
  late final GoRouter router;

  void dispose() => _refresh.dispose();
}
