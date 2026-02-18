import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

import 'theme/app_theme.dart';

// Import your components here
// import 'widgets/discovery/profile_card.dart';
// import 'widgets/common/primary_button.dart';

void main() {
  runApp(const WidgetbookApp());
}

class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      // Component catalog
      directories: [
        WidgetbookComponent(
          name: 'Common Components',
          useCases: [
            WidgetbookUseCase(
              name: 'Primary Button',
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Like'),
                ),
              ),
            ),
          ],
        ),
        WidgetbookCategory(
          name: 'Discovery',
          children: [
            // Your ProfileCard, MatchNotification, etc. will go here
          ],
        ),
        WidgetbookCategory(
          name: 'Design Tokens',
          children: [
            WidgetbookComponent(
              name: 'Colors',
              useCases: [
                WidgetbookUseCase(
                  name: 'Brand Colors',
                  builder: (context) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ColorSwatch('Primary (Coral)', AppTheme.primaryColor),
                        _ColorSwatch('Primary Light', AppTheme.primaryLight),
                        _ColorSwatch('Primary Dark', AppTheme.primaryDark),
                        _ColorSwatch('Secondary (Purple)', AppTheme.secondaryColor),
                        _ColorSwatch('Tertiary (Teal)', AppTheme.tertiaryColor),
                        _ColorSwatch('Success', AppTheme.successColor),
                        _ColorSwatch('Error', AppTheme.errorColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Typography',
              useCases: [
                WidgetbookUseCase(
                  name: 'Text Styles',
                  builder: (context) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Display Large', style: Theme.of(context).textTheme.displayLarge),
                        const SizedBox(height: 8),
                        Text('Headline Large', style: Theme.of(context).textTheme.headlineLarge),
                        const SizedBox(height: 8),
                        Text('Body Large', style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 8),
                        Text('Body Medium', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
      
      // App themes
      appBuilder: (context, child) {
        return MaterialApp(
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          home: child,
        );
      },
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final String name;
  final Color color;
  
  const _ColorSwatch(this.name, this.color);
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
