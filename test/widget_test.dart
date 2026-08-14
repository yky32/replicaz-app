import 'package:flutter_test/flutter_test.dart';
import 'package:replicaz/app/app.dart';
import 'package:replicaz/core/bootstrap/app_bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Replicaz boots without crash', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppBootstrap.init();

    await tester.pumpWidget(const ReplicazApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // App shell mounts (login or splash). Full settle avoided — ambient loop.
    expect(find.byType(ReplicazApp), findsOneWidget);
  });
}
