import 'package:flutter_test/flutter_test.dart';
import 'package:replicaz/app/app.dart';
import 'package:replicaz/core/bootstrap/app_bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Replicaz loads login screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppBootstrap.init();

    await tester.pumpWidget(const ReplicazApp());
    await tester.pumpAndSettle();

    expect(find.text('Replicaz'), findsWidgets);
    expect(find.text('Continue'), findsOneWidget);
  });
}
