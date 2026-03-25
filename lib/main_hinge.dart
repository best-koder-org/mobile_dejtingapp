import 'package:dejtingapp/flavors/flavor_config.dart';
import 'package:dejtingapp/flavors/hinge_config.dart';
import 'main.dart' as app;

Future<void> main() async {
  FlavorConfig.current = HingeFlavorConfig();
  await app.main();
}
