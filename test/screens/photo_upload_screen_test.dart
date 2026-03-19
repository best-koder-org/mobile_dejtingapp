import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/photo_upload_screen.dart';
import '../helpers/core_screen_test_helper.dart';

void main() {
  group('PhotoUploadScreen', () {
    setUp(() {
      // Photo grid needs a taller viewport to show all 6 slots
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.window.physicalSizeTestValue = const Size(800, 1400);
      binding.window.devicePixelRatioTestValue = 1.0;
    });

    tearDown(() {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.window.clearPhysicalSizeTestValue();
      binding.window.clearDevicePixelRatioTestValue();
    });

    Widget buildSubject() {
      return buildCoreScreenTestApp(
        home: PhotoUploadScreen(
          onPhotoRequirementMet: (_) {},
        ),
      );
    }

    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('shows AppBar with Add photos title', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Add photos'), findsOneWidget);
    });

    testWidgets('displays photo grid (GridView present)', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('shows at least 4 add-photo tap targets (minimum required slots)',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // Each empty slot shows add_photo_alternate icon; minPhotos = 4
      expect(
        find.byIcon(Icons.add_photo_alternate),
        findsAtLeastNWidgets(4),
      );
    });

    testWidgets('photo count indicator shows 0/6 initially', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // Requirements header always shows uploaded/max count
      expect(find.textContaining('0/6'), findsOneWidget);
    });

    testWidgets('requirements header shows progress indicator', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets(
        'requirements header shows not-met state when fewer than minimum photos',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // With 0 photos the camera icon (not check_circle) is shown
      // and the "add more photos" prompt is displayed
      expect(find.byIcon(Icons.photo_camera), findsOneWidget);
      expect(find.textContaining('photos to continue'), findsOneWidget);
    });

    testWidgets('photo guidelines section is displayed', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Photo Tips'), findsOneWidget);
    });

    testWidgets('primary photo slot is marked with Primary badge', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Primary'), findsOneWidget);
    });

    testWidgets('required label shown for minimum required slots',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump(const Duration(milliseconds: 500));
      // minPhotos = 4, so at least one 'Required' label should appear
      expect(find.text('Required'), findsAtLeastNWidgets(1));
    });
  });
}
