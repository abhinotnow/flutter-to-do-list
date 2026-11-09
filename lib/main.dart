import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _ink = Color(0xFF222B26);
const _muted = Color(0xFF7A857E);
const _green = Color(0xFF46745C);
const _canvas = Color(0xFFF5F6F2);

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => TaskStore()..load(),
      child: const StudyTasksApp(),
    ),
  );
}

class StudyTasksApp extends StatelessWidget {
  const StudyTasksApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Daymark | Study Tasks',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: _canvas,
      colorScheme: ColorScheme.fromSeed(seedColor: _green),
      fontFamily: 'Arial',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: _ink, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(color: _ink, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: _ink, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: _ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE3E8E2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE3E8E2)),
        ),
      ),
    ),
    home: const DashboardScreen(),
  );
}

class StudyTask {
  const StudyTask({
    required this.id,
    required this.title,
    required this.notes,
    required this.isDone,
  });

  final String id;
  final String title;
  final String notes;
  final bool isDone;

  StudyTask copyWith({String? title, String? notes, bool? isDone}) => StudyTask(
    id: id,
    title: title ?? this.title,
    notes: notes ?? this.notes,
    isDone: isDone ?? this.isDone,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'notes': notes,
    'isDone': isDone,
  };

  factory StudyTask.fromJson(Map<String, dynamic> json) => StudyTask(
    id: json['id'] as String,
    title: json['title'] as String,
    notes: json['notes'] as String? ?? '',
    isDone: json['isDone'] as bool? ?? false,
  );
}

enum TaskFilter { all, active, completed }

class TaskStore extends ChangeNotifier {
  static const _storageKey = 'daymark.tasks.v1';
  TaskStore({TaskPersistence? persistence})
    : _persistence = persistence ?? PreferencesTaskPersistence();

  final TaskPersistence _persistence;
  final List<StudyTask> _tasks = [];
  TaskFilter filter = TaskFilter.all;
  bool isLoaded = false;

  List<StudyTask> get tasks => List.unmodifiable(_tasks);
  int get completedCount => _tasks.where((task) => task.isDone).length;
  int get activeCount => _tasks.length - completedCount;
  double get progress => _tasks.isEmpty ? 0 : completedCount / _tasks.length;
  List<StudyTask> get visibleTasks => switch (filter) {
    TaskFilter.all => List.unmodifiable(_tasks),
    TaskFilter.active => _tasks.where((task) => !task.isDone).toList(),
    TaskFilter.completed => _tasks.where((task) => task.isDone).toList(),
  };

  Future<void> load() async {
    try {
      final raw = await _persistence.readTasks(_storageKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _tasks
          ..clear()
          ..addAll(
            decoded.map(
              (item) =>
                  StudyTask.fromJson(Map<String, dynamic>.from(item as Map)),
            ),
          );
      }
    } catch (_) {
      // A malformed local value should not prevent using the task list.
      _tasks.clear();
    }
    isLoaded = true;
    notifyListeners();
  }

  void setFilter(TaskFilter value) {
    filter = value;
    notifyListeners();
  }

  Future<void> saveTask({
    StudyTask? existing,
    required String title,
    required String notes,
  }) async {
    final trimmedTitle = title.trim();
    final trimmedNotes = notes.trim();
    if (existing == null) {
      _tasks.insert(
        0,
        StudyTask(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: trimmedTitle,
          notes: trimmedNotes,
          isDone: false,
        ),
      );
    } else {
      final index = _tasks.indexWhere((task) => task.id == existing.id);
      if (index != -1) {
        _tasks[index] = existing.copyWith(
          title: trimmedTitle,
          notes: trimmedNotes,
        );
      }
    }
    notifyListeners();
    await _persist();
  }

  Future<void> toggleTask(StudyTask task) async {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) return;
    _tasks[index] = task.copyWith(isDone: !task.isDone);
    notifyListeners();
    await _persist();
  }

  Future<void> deleteTask(StudyTask task) async {
    _tasks.removeWhere((item) => item.id == task.id);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    await _persistence.writeTasks(
      _storageKey,
      jsonEncode(_tasks.map((task) => task.toJson()).toList()),
    );
  }
}

abstract interface class TaskPersistence {
  Future<String?> readTasks(String key);
  Future<void> writeTasks(String key, String value);
}

class PreferencesTaskPersistence implements TaskPersistence {
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  @override
  Future<String?> readTasks(String key) => _preferences.getString(key);

  @override
  Future<void> writeTasks(String key, String value) =>
      _preferences.setString(key, value);
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Consumer<TaskStore>(
        builder: (context, store, _) {
          if (!store.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 900;
              final scrollPage = constraints.maxHeight < 760;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: constraints.maxWidth < 600 ? 20 : 36,
                      vertical: 24,
                    ),
                    child: scrollPage
                        ? SingleChildScrollView(
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight - 48,
                              ),
                              child: _taskColumn(
                                context,
                                store,
                                scrollPage: true,
                              ),
                            ),
                          )
                        : wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 7,
                                child: _taskColumn(context, store),
                              ),
                              const SizedBox(width: 34),
                              SizedBox(width: 270, child: _sidePanel(store)),
                            ],
                          )
                        : _taskColumn(context, store),
                  ),
                ),
              );
            },
          );
        },
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _openEditor(context),
      backgroundColor: _green,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_rounded),
      label: const Text('New task'),
    ),
  );

  Widget _taskColumn(
    BuildContext context,
    TaskStore store, {
    bool scrollPage = false,
  }) {
    final now = DateTime.now();
    final weekday = const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][now.weekday - 1];
    final month = const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][now.month - 1];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE4EEE6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.spa_rounded, color: _green),
            ),
            const SizedBox(width: 12),
            const Text(
              'daymark',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const Spacer(),
            if (MediaQuery.sizeOf(context).width < 600)
              CircleAvatar(
                radius: 19,
                backgroundColor: const Color(0xFFE4EEE6),
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: _green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 38),
        Text(
          '$weekday, $month ${now.day}',
          style: const TextStyle(color: _muted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Make room for\nwhat matters.',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontSize: 34, height: 1.15),
        ),
        const SizedBox(height: 10),
        const Text(
          'A little progress, every day.',
          style: TextStyle(color: _muted, fontSize: 15),
        ),
        const SizedBox(height: 28),
        _ProgressBanner(store: store),
        const SizedBox(height: 28),
        Row(
          children: [
            const Text(
              'Your tasks',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(width: 9),
            _CountBadge(count: store.visibleTasks.length),
          ],
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: TaskFilter.values.map((filter) {
              final selected = store.filter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_filterLabel(filter)),
                  selected: selected,
                  onSelected: (_) => store.setFilter(filter),
                  showCheckmark: false,
                  selectedColor: _green,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : _muted,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: selected ? _green : const Color(0xFFE3E8E2),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        if (scrollPage)
          SizedBox(height: 320, child: _taskList(store))
        else
          Expanded(child: _taskList(store)),
      ],
    );
  }

  Widget _taskList(TaskStore store) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 220),
    child: store.visibleTasks.isEmpty
        ? _EmptyTasks(key: ValueKey(store.filter))
        : ListView.separated(
            key: ValueKey(store.filter),
            padding: const EdgeInsets.only(bottom: 92),
            itemCount: store.visibleTasks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                TaskCard(task: store.visibleTasks[index]),
          ),
  );

  Widget _sidePanel(TaskStore store) => Column(
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: CircleAvatar(
          radius: 21,
          backgroundColor: const Color(0xFFE4EEE6),
          child: Text(
            _initials,
            style: const TextStyle(color: _green, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      const SizedBox(height: 50),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE9ECE7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'YOUR MOMENTUM',
              style: TextStyle(
                color: _muted,
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: 142,
                height: 142,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: store.progress,
                        strokeWidth: 11,
                        backgroundColor: const Color(0xFFEAF0EA),
                        color: _green,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(store.progress * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                        const Text(
                          'complete',
                          style: TextStyle(fontSize: 12, color: _muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Keep your pace',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${store.completedCount} of ${store.tasks.length} tasks done. You are building a good rhythm.',
              style: const TextStyle(color: _muted, height: 1.45),
            ),
            const SizedBox(height: 22),
            const Divider(color: Color(0xFFE9ECE7)),
            const SizedBox(height: 13),
            _StatLine(
              icon: Icons.radio_button_unchecked_rounded,
              label: 'Still to do',
              value: '${store.activeCount}',
            ),
            const SizedBox(height: 14),
            _StatLine(
              icon: Icons.check_circle_outline_rounded,
              label: 'Completed',
              value: '${store.completedCount}',
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFE7EEE6),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.wb_sunny_outlined, color: _green),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Small steps still move you forward.',
                style: TextStyle(
                  color: _green,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Future<void> _openEditor(BuildContext context, {StudyTask? task}) async {
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, animation, _) => FadeTransition(
          opacity: animation,
          child: TaskEditorScreen(task: task),
        ),
      ),
    );
  }
}

const _initials = 'AM';

class _ProgressBanner extends StatelessWidget {
  const _ProgressBanner({required this.store});
  final TaskStore store;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(19),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF416C55), Color(0xFF63866B)],
      ),
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TODAY\'S PROGRESS',
                style: TextStyle(
                  color: Color(0xFFD8E7D9),
                  fontSize: 10,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                store.activeCount == 0
                    ? 'You are all caught up!'
                    : '${store.activeCount} ${store.activeCount == 1 ? 'task' : 'tasks'} to go',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: store.progress,
                  minHeight: 7,
                  backgroundColor: Colors.white24,
                  color: const Color(0xFFE4C88A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Container(
          width: 49,
          height: 49,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .14),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFFE9D29C),
          ),
        ),
      ],
    ),
  );
}

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task});
  final StudyTask task;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 220),
    padding: const EdgeInsets.fromLTRB(15, 13, 8, 13),
    decoration: BoxDecoration(
      color: task.isDone ? const Color(0xFFF0F4EF) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE8EBE6)),
    ),
    child: Row(
      children: [
        Checkbox(
          value: task.isDone,
          onChanged: (_) => context.read<TaskStore>().toggleTask(task),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          activeColor: _green,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _openEditor(context, task),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: task.isDone ? _muted : _ink,
                      decoration: task.isDone
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (task.notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.notes,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Task actions',
          onSelected: (value) {
            if (value == 'edit') _openEditor(context, task);
            if (value == 'delete') _confirmDelete(context);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit task')),
            PopupMenuItem(value: 'delete', child: Text('Delete task')),
          ],
        ),
      ],
    ),
  );

  Future<void> _openEditor(BuildContext context, StudyTask task) async {
    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, animation, _) => FadeTransition(
          opacity: animation,
          child: TaskEditorScreen(task: task),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this task?'),
        content: Text('“${task.title}” will be removed from your list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete == true && context.mounted) {
      await context.read<TaskStore>().deleteTask(task);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Task deleted')));
      }
    }
  }
}

class TaskEditorScreen extends StatefulWidget {
  const TaskEditorScreen({super.key, this.task});
  final StudyTask? task;

  @override
  State<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends State<TaskEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _notesController = TextEditingController(text: widget.task?.notes ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: _canvas,
      title: Text(widget.task == null ? 'New task' : 'Edit task'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4EEE6),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    size: 30,
                    color: _green,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.task == null
                      ? 'What would you like to do?'
                      : 'Update your task',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontSize: 27),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Keep it clear and manageable. You can always edit it later.',
                  style: TextStyle(color: _muted, height: 1.5),
                ),
                const SizedBox(height: 30),
                const Text(
                  'TASK TITLE',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 9),
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Review chapter three',
                    prefixIcon: Icon(Icons.check_circle_outline_rounded),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter a task title.'
                      : null,
                ),
                const SizedBox(height: 22),
                const Text(
                  'NOTES (OPTIONAL)',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 9),
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  maxLength: 240,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Add a little context to help you get started…',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    _saving
                        ? 'Saving…'
                        : widget.task == null
                        ? 'Add task'
                        : 'Save changes',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await context.read<TaskStore>().saveTask(
      existing: widget.task,
      title: _titleController.text,
      notes: _notesController.text,
    );
    if (!mounted) return;
    Navigator.pop(context);
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFE9EFE8),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.checklist_rounded, size: 30, color: _green),
          ),
          const SizedBox(height: 14),
          const Text(
            'A fresh start',
            style: TextStyle(
              color: _ink,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Add a task and take the first small step.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted),
          ),
        ],
      ),
    ),
  );
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFE8EDE7),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      '$count',
      style: const TextStyle(
        color: _green,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _StatLine extends StatelessWidget {
  const _StatLine({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: _green),
      const SizedBox(width: 9),
      Expanded(
        child: Text(label, style: const TextStyle(color: _muted, fontSize: 13)),
      ),
      Text(
        value,
        style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
      ),
    ],
  );
}

String _filterLabel(TaskFilter filter) => switch (filter) {
  TaskFilter.all => 'All tasks',
  TaskFilter.active => 'To do',
  TaskFilter.completed => 'Completed',
};
