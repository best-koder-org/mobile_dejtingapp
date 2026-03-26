import 'package:dejtingapp/flavors/flavor_config.dart';
import 'package:dejtingapp/flavors/voice_config.dart';
import 'main.dart' as app;

Future<void> main() async {
  FlavorConfig.current = VoiceFlavorConfig();
  await app.main();
}
