# Daymark — Study Tasks

## Flutter Application Documentation Report

**Prepared for:** Flutter Application Examination  
**Student:** ______________________________  
**Roll number:** __________________________  
**Date:** _________________________________

---

## 1. Application Name and Introduction

**Daymark — Study Tasks** is a responsive task-management web application built with Flutter. It helps a student keep a simple list of study tasks, add notes, mark work as complete, and review progress. The application runs in a web browser and saves its task list locally on that browser.

The interface uses a clean study-dashboard layout. A student can use the same application on a phone, tablet, or desktop browser.

## 2. Purpose and Objectives

The purpose of Daymark is to provide a small, easy-to-use place to organize study work. Its objectives are to:

- Let students record study tasks and optional notes.
- Make it easy to distinguish active tasks from completed tasks.
- Show a simple completion summary to encourage steady progress.
- Demonstrate Flutter widgets, responsive layouts, navigation, animation, state management, themes, reusable components, and validated forms in one working application.
- Keep the application usable without creating a server account; task data stays in the local browser.

## 3. Tools and Technologies Used

| Tool or technology | Use in the application |
|---|---|
| Flutter 3.47.2 | UI framework and web build |
| Dart 3.13.2 | Application programming language |
| Material 3 | Consistent theme, controls, colors, and typography |
| Provider 6.1.5+1 | Shares task state across screens using `ChangeNotifier` |
| shared_preferences 2.5.6 | Saves task data in browser-local storage |
| Flutter Web | Runs the application in a modern browser |

## 4. Features and Functionalities

- **Create tasks:** Add a required title and optional notes.
- **Validate forms:** Prevent saving a task when its title is blank.
- **Edit tasks:** Update a task title or notes without losing completion state.
- **Complete tasks:** Toggle a task between active and completed.
- **Filter tasks:** View all tasks, tasks to do, or completed tasks.
- **Delete tasks:** Confirm before removing a task.
- **Track progress:** View total, active, completed, and completion percentage summaries.
- **Save locally:** Restore the task list after a browser refresh on the same browser and device.
- **Adapt to screen size:** Use a single-column layout on phones and tablets, and add a progress panel on wider desktop screens. Shorter browser windows can scroll vertically.
- **Animate interactions:** Use an animated task completion state, animated filter-list changes, and a fade transition to the task editor.
- **Show an empty state:** Provide a clear prompt when there are no tasks in the selected filter.

### Flutter Concepts Demonstrated

The app uses `Scaffold`, `SafeArea`, `Container`, `Row`, `Column`, `Stack`, `ListView`, `LayoutBuilder`, `Card`-style surfaces, buttons, text fields, checkboxes, and choice chips. Reusable widgets include task cards, progress banners, count badges, and statistics rows. `StatefulWidget` manages the editor form while Provider manages the shared task list.

## 5. Important Code Snippets

### App-wide Provider State

```dart
runApp(
  ChangeNotifierProvider(
    create: (_) => TaskStore()..load(),
    child: const StudyTasksApp(),
  ),
);
```

This creates the task controller once and makes it available to the dashboard and editor screens.

### Responsive Dashboard Layout

```dart
final wide = constraints.maxWidth >= 900;
final scrollPage = constraints.maxHeight < 760;

child: scrollPage
    ? SingleChildScrollView(
        child: _taskColumn(context, store, scrollPage: true),
      )
    : wide
        ? Row(
            children: [
              Expanded(child: _taskColumn(context, store)),
              SizedBox(width: 270, child: _sidePanel(store)),
            ],
          )
        : _taskColumn(context, store),
```

The layout adapts to available width and height so shorter screens remain usable.

### Form Validation

```dart
TextFormField(
  controller: _titleController,
  maxLength: 80,
  decoration: const InputDecoration(
    hintText: 'e.g. Review chapter three',
  ),
  validator: (value) => value == null || value.trim().isEmpty
      ? 'Please enter a task title.'
      : null,
)
```

### Saving Tasks Locally

```dart
Future<void> _persist() async {
  await _persistence.writeTasks(
    _storageKey,
    jsonEncode(_tasks.map((task) => task.toJson()).toList()),
  );
}
```

The task list is serialized as JSON and stored under an application-specific browser preference key.

### Animated Task Completion

```dart
AnimatedContainer(
  duration: const Duration(milliseconds: 220),
  decoration: BoxDecoration(
    color: task.isDone ? const Color(0xFFF0F4EF) : Colors.white,
    borderRadius: BorderRadius.circular(18),
  ),
  child: Row(
    children: [
      Checkbox(
        value: task.isDone,
        onChanged: (_) => context.read<TaskStore>().toggleTask(task),
        activeColor: _green,
      ),
      // The card also displays the title, notes, and action menu.
    ],
  ),
)
```

The task card contains its checkbox, title, optional notes, and edit/delete menu within the animated container.

## 6. Deployment Details

### Run During Development

```sh
flutter pub get
flutter run -d chrome
```

### Build the Web Application for Hosting

```sh
flutter build web --release
```

The release build is generated in `build/web/`. This directory contains the static web application files and can be uploaded to a static web host. No cloud host or public URL has been configured for this project. Task data remains in the local browser and is not synced to other devices.

## 7. Screenshots of Application UI

> **Add screenshots before printing:** capture the running application at the sizes below, then replace each placeholder with the corresponding screenshot in Word. Use grayscale or black-and-white images for the printed copy.

### Desktop Dashboard — 1440 × 900

**Screenshot placeholder:** Insert the dashboard showing the progress panel and task list.

### Tablet Dashboard — 800 × 1024

**Screenshot placeholder:** Insert the responsive dashboard at tablet width.

### Mobile Dashboard — 390 × 844

**Screenshot placeholder:** Insert the mobile dashboard and task filters.

### Add / Edit Task Form — Mobile or Desktop

**Screenshot placeholder:** Insert the task editor showing title validation and the optional notes field.

## Verification Summary

- `flutter analyze` completed with no issues.
- `flutter test` passed the task workflow and viewport checks at 390 × 844, 800 × 1024, and 1440 × 900.
- `flutter build web --release` completed successfully and generated `build/web/`.

## Short Answer-Booklet Summary

**Application:** Daymark — Study Tasks. It is a responsive Flutter web application for recording and organizing study tasks. It supports adding, editing, completing, filtering, and deleting tasks, and displays a task progress summary. It was built with Dart and Flutter, uses Material 3 for its UI, Provider for state management, and `shared_preferences` for browser-local storage. It demonstrates responsive widgets, navigation, animations, reusable custom widgets, and validated forms. The release web build is produced with `flutter build web --release` in the `build/web/` directory.
