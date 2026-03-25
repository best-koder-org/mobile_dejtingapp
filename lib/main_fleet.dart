import 'package:dejtingapp/flavors/flavor_config.dart';
import 'package:dejtingapp/flavors/fleet_config.dart';
import 'main.dart' as app;

Future<void> main() async {
  FlavorConfig.current = FleetFlavorConfig();
  await app.main();
}
