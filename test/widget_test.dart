import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:study_tasks/main.dart';

void main() {
  testWidgets('user can add, complete, edit, filter, and delete a task', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final persistence = _MemoryTaskPersistence();
    final store = TaskStore(persistence: persistence)..load();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: store, child: const StudyTasksApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('A fresh start'), findsOneWidget);
    await tester.tap(find.text('New task'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter a task title.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Study Flutter');
    await tester.enterText(
      find.byType(TextFormField).last,
      'Review responsive layouts',
    );
    await tester.tap(find.text('Add task'));
    await tester.pumpAndSettle();
    expect(find.text('Study Flutter'), findsOneWidget);
    expect(persistence.value, contains('Study Flutter'));

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Completed'));
    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    expect(find.text('Study Flutter'), findsOneWidget);

    await tester.tap(find.byTooltip('Task actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit task'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Study Provider');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(find.text('Study Provider'), findsOneWidget);

    await tester.tap(find.byTooltip('Task actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete task'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(find.text('Study Provider'), findsNothing);
    expect(persistence.value, '[]');
  });

  for (final size in const [Size(390, 844), Size(800, 1024), Size(1440, 900)]) {
    testWidgets('dashboard fits ${size.width.toInt()}px viewport', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final store = TaskStore(persistence: _MemoryTaskPersistence())..load();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: store,
          child: const StudyTasksApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Make room for\nwhat matters.'), findsOneWidget);
      expect(find.text('New task'), findsOneWidget);
    });
  }
}

class _MemoryTaskPersistence implements TaskPersistence {
  String value = '';

  @override
  Future<String?> readTasks(String key) async => value.isEmpty ? null : value;

  @override
  Future<void> writeTasks(String key, String value) async {
    this.value = value;
  }
}
