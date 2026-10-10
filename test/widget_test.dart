import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edit_sathi/main.dart';
import 'package:edit_sathi/providers/project_provider.dart';
import 'package:edit_sathi/providers/timeline_provider.dart';

void main() {
  testWidgets('EditSathiApp renders Home screen with Edit Sathi brand title',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    final projectProvider = ProjectProvider();
    await projectProvider.initialize();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: projectProvider),
          ChangeNotifierProvider(create: (_) => TimelineProvider()),
        ],
        child: const EditSathiApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify brand header and hero call-to-action
    expect(find.text('Edit Sathi'), findsOneWidget);
    expect(find.text('Create something amazing'), findsOneWidget);
    expect(find.text('New Project'), findsOneWidget);
    expect(find.text('Auto Edit'), findsOneWidget);
    expect(find.text('AI Tools'), findsOneWidget);
    expect(find.text('Templates'), findsWidgets);
    expect(find.text('More'), findsOneWidget);
  });
}
