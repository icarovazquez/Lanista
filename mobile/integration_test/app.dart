import 'package:integration_test/integration_test.dart';
import 'package:lanista/main.dart' as app;

/// Entry point for integration tests.
/// Call [appMain] at the top of each integration test file.
void appMain() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  app.main();
}
