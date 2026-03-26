import 'package:dejtingapp/flavors/flavor_config.dart';
import 'package:dejtingapp/flavors/oldies_config.dart';
import 'main.dart' as app;

Future<void> main() async {
  FlavorConfig.current = OldiesFlavorConfig();
  await app.main();
}
