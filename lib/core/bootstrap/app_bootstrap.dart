import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:replicaz/core/config/app_config.dart';
import 'package:replicaz/core/network/api_client.dart';
import 'package:replicaz/core/storage/local_store.dart';
import 'package:replicaz/features/auth/data/auth_service.dart';
import 'package:replicaz/features/contacts/data/contact_service.dart';
import 'package:replicaz/features/follow_ups/data/follow_up_service.dart';
import 'package:replicaz/features/identities/data/identity_service.dart';
import 'package:replicaz/features/messaging/data/messaging_service.dart';
import 'package:replicaz/features/messaging/data/remote_messaging_api.dart';
import 'package:replicaz/features/notes/data/note_service.dart';
import 'package:replicaz/features/receipts/data/receipt_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manual bootstrap (Depozio/Triftly style — no get_it).
class AppBootstrap {
  AppBootstrap._();

  static late final LocalStore store;
  static late final FlutterSecureStorage secureStorage;
  static late final ApiClient apiClient;
  static late final AuthService authService;
  static late final IdentityService identityService;
  static late final ContactService contactService;
  static late final NoteService noteService;
  static late final FollowUpService followUpService;
  static late final ReceiptService receiptService;
  static late final MessagingService messagingService;
  static late final RemoteMessagingApi? remoteMessagingApi;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    store = LocalStore(prefs);
    secureStorage = const FlutterSecureStorage();
    apiClient = ApiClient(secureStorage: secureStorage);
    remoteMessagingApi =
        AppConfig.useRemoteBackend ? RemoteMessagingApi(apiClient) : null;
    authService = AuthService(
      store: store,
      secureStorage: secureStorage,
      apiClient: AppConfig.useRemoteBackend ? apiClient : null,
    );
    identityService = IdentityService(store: store);
    contactService = ContactService(store: store);
    noteService = NoteService(store: store);
    followUpService = FollowUpService(store: store);
    receiptService = ReceiptService(store: store);
    messagingService = MessagingService(
      store: store,
      remote: remoteMessagingApi,
    );
  }
}
