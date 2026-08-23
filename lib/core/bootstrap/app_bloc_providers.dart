import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:replicaz/features/auth/bloc/auth_bloc.dart';
import 'package:replicaz/features/contacts/bloc/contacts_bloc.dart';
import 'package:replicaz/features/follow_ups/bloc/follow_ups_bloc.dart';
import 'package:replicaz/features/identities/bloc/identities_bloc.dart';
import 'package:replicaz/features/messaging/bloc/conversations_bloc.dart';
import 'package:replicaz/features/notes/bloc/notes_bloc.dart';
import 'package:replicaz/features/receipts/bloc/receipts_bloc.dart';

class AppBlocProviders extends StatelessWidget {
  const AppBlocProviders({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc()..add(const AuthBootstrapRequested()),
        ),
        BlocProvider(
          create: (_) => IdentitiesBloc()..add(const IdentitiesLoadRequested()),
        ),
        BlocProvider(
          create: (context) => ContactsBloc(
            identitiesBloc: context.read<IdentitiesBloc>(),
          ),
        ),
        BlocProvider(
          create: (context) => NotesBloc(
            identitiesBloc: context.read<IdentitiesBloc>(),
          ),
        ),
        BlocProvider(
          create: (context) => FollowUpsBloc(
            identitiesBloc: context.read<IdentitiesBloc>(),
          ),
        ),
        BlocProvider(
          create: (context) => ReceiptsBloc(
            identitiesBloc: context.read<IdentitiesBloc>(),
          ),
        ),
        BlocProvider(
          create: (context) => ConversationsBloc(
            identitiesBloc: context.read<IdentitiesBloc>(),
          ),
        ),
      ],
      // After demo fixtures seed (or real login), reload identity-scoped data.
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (p, c) =>
            p.status != c.status && c.status == AuthStatus.authenticated,
        listener: (context, state) {
          context.read<IdentitiesBloc>().add(const IdentitiesLoadRequested());
        },
        child: child,
      ),
    );
  }
}
