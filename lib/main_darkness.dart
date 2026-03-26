import 'package:dejtingapp/flavors/flavor_config.dart';
import 'package:dejtingapp/flavors/darkness_config.dart';
import 'main.dart' as app;

Future<void> main() async {
  FlavorConfig.current = DarknessFlavorConfig();
  await app.main();
}
