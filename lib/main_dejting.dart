import 'package:dejtingapp/flavors/flavor_config.dart';
import 'package:dejtingapp/flavors/dejting_config.dart';
import 'main.dart' as app;

Future<void> main() async {
  FlavorConfig.current = DejtingFlavorConfig();
  await app.main();
}
