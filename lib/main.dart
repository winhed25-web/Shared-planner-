import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const SharredPlannerApp());
}

class SharredPlannerApp extends StatelessWidget {
  const SharredPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sharred Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      home: const HomeScreen(),
    );
  }
}

// -----------------------------------------------------------------------------
// MODELS
// -----------------------------------------------------------------------------

class PlannerEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final int startMinutes;
  final int endMinutes;
  final String ownerId;
  final String ownerName;
  final int colorValue;

  const PlannerEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.startMinutes,
    required this.endMinutes,
    required this.ownerId,
    required this.ownerName,
    required this.colorValue,
  });

  PlannerEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    int? startMinutes,
    int? endMinutes,
    String? ownerId,
    String? ownerName,
    int? colorValue,
  }) {
    return PlannerEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'startMinutes': startMinutes,
      'endMinutes': endMinutes,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'colorValue': colorValue,
    };
  }

  factory PlannerEvent.fromJson(Map<String, dynamic> json) {
    return PlannerEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      // Old events that don't have times will default to 09:00–10:00.
      startMinutes: json['startMinutes'] as int? ?? 9 * 60,
      endMinutes: json['endMinutes'] as int? ?? 10 * 60,
      ownerId: json['ownerId'] as String? ?? 'me',
      ownerName: json['ownerName'] as String? ?? 'Me',
      colorValue: json['colorValue'] as int? ?? 0xFF3F51B5,
    );
  }
}

class PlannerTask {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String ownerId;
  final String ownerName;
  final bool completed;
  final int colorValue;

  const PlannerTask({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.ownerId,
    required this.ownerName,
    required this.completed,
    required this.colorValue,
  });

  PlannerTask copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? ownerId,
    String? ownerName,
    bool? completed,
    int? colorValue,
  }) {
    return PlannerTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      completed: completed ?? this.completed,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'ownerId': ownerId,
      'ownerName': ownerName,
      'completed': completed,
      'colorValue': colorValue,
    };
  }

  factory PlannerTask.fromJson(Map<String, dynamic> json) {
    return PlannerTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      dueDate: DateTime.parse(json['dueDate'] as String),
      ownerId: json['ownerId'] as String? ?? 'me',
      ownerName: json['ownerName'] as String? ?? 'Me',
      completed: json['completed'] as bool? ?? false,
      colorValue: json['colorValue'] as int? ?? 0xFF00897B,
    );
  }
}

// -----------------------------------------------------------------------------
// STORAGE
// -----------------------------------------------------------------------------

class StorageService {
  static const String eventsKey = 'planner_events';
  static const String tasksKey = 'planner_tasks';

  Future<List<PlannerEvent>> loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(eventsKey);

    if (data == null || data.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded
          .map(
            (item) => PlannerEvent.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<PlannerTask>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(tasksKey);

    if (data == null || data.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded
          .map(
            (item) => PlannerTask.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveEvents(List<PlannerEvent> events) async {
    final prefs = await SharedPreferences.getInstance();

    final data = jsonEncode(
      events.map((event) => event.toJson()).toList(),
    );

    await prefs.setString(eventsKey, data);
  }

  Future<void> saveTasks(List<PlannerTask> tasks) async {
    final prefs = await SharedPreferences.getInstance();

    final data = jsonEncode(
      tasks.map((task) => task.toJson()).toList(),
    );

    await prefs.setString(tasksKey, data);
  }
}

// -----------------------------------------------------------------------------
// HOME SCREEN
// -----------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService storage = StorageService();

  List<PlannerEvent> events = [];
  List<PlannerTask> tasks = [];

  DateTime selectedDate = DateTime.now();

  // true = everyone, false = only me
  bool showEveryone = true;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final loadedEvents = await storage.loadEvents();
    final loadedTasks = await storage.loadTasks();

    if (!mounted) return;

    setState(() {
      events = loadedEvents;
      tasks = loadedTasks;
      loading = false;
    });
  }

  bool sameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  String formatTime(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;

    final time = TimeOfDay(
      hour: hour,
      minute: minute,
    );

    return time.format(context);
  }

  List<PlannerEvent> get visibleEvents {
    final result = events.where((event) {
      if (!sameDay(event.date, selectedDate)) {
        return false;
      }

      if (!showEveryone && event.ownerId != 'me') {
        return false;
      }

      return true;
    }).toList();

    result.sort(
      (a, b) => a.startMinutes.compareTo(b.startMinutes),
    );

    return result;
  }

  List<PlannerTask> get visibleTasks {
    final result = tasks.where((task) {
      if (!sameDay(task.dueDate, selectedDate)) {
        return false;
      }

      if (!showEveryone && task.ownerId != 'me') {
        return false;
      }

      return true;
    }).toList();

    return result;
  }

  Future<void> openAddItem() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddItemScreen(
          initialDate: selectedDate,
        ),
      ),
    );

    if (result is PlannerEvent) {
      setState(() {
        events.add(result);
      });

      await storage.saveEvents(events);
    }

    if (result is PlannerTask) {
      setState(() {
        tasks.add(result);
      });

      await storage.saveTasks(tasks);
    }
  }

  Future<void> editEvent(PlannerEvent event) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddItemScreen(
          initialDate: event.date,
          existingEvent: event,
        ),
      ),
    );

    if (result is PlannerEvent) {
      final index = events.indexWhere(
        (item) => item.id == event.id,
      );

      if (index != -1) {
        setState(() {
          events[index] = result;
        });

        await storage.saveEvents(events);
      }
    }
  }

  Future<void> deleteEvent(PlannerEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete event?'),
          content: Text(
            'Are you sure you want to delete "${event.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      events.removeWhere(
        (item) => item.id == event.id,
      );
    });

    await storage.saveEvents(events);
  }

  Future<void> toggleTask(PlannerTask task) async {
    final index = tasks.indexWhere(
      (item) => item.id == task.id,
    );

    if (index == -1) return;

    setState(() {
      tasks[index] = task.copyWith(
        completed: !task.completed,
      );
    });

    await storage.saveTasks(tasks);
  }

  void previousDay() {
    setState(() {
      selectedDate = selectedDate.subtract(
        const Duration(days: 1),
      );
    });
  }

  void nextDay() {
    setState(() {
      selectedDate = selectedDate.add(
        const Duration(days: 1),
      );
    });
  }

  void today() {
    setState(() {
      selectedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat(
      'EEEE, d MMMM yyyy',
    ).format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sharred Planner'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddItem,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                const SizedBox(height: 8),

                // -------------------------------------------------------------
                // DATE NAVIGATION
                // -------------------------------------------------------------

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: previousDay,
                        icon: const Icon(
                          Icons.chevron_left,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              dateText,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            TextButton(
                              onPressed: today,
                              child: const Text('Today'),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: nextDay,
                        icon: const Icon(
                          Icons.chevron_right,
                        ),
                      ),
                    ],
                  ),
                ),

                // -------------------------------------------------------------
                // VISIBILITY FILTER
                // -------------------------------------------------------------

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: true,
                        icon: Icon(Icons.people_outline),
                        label: Text('Everyone'),
                      ),
                      ButtonSegment<bool>(
                        value: false,
                        icon: Icon(Icons.person_outline),
                        label: Text('Only Me'),
                      ),
                    ],
                    selected: {showEveryone},
                    onSelectionChanged: (selection) {
                      setState(() {
                        showEveryone = selection.first;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // -------------------------------------------------------------
                // CONTENT
                // -------------------------------------------------------------

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: loadData,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        100,
                      ),
                      children: [
                        Text(
                          'Events',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),

                        if (visibleEvents.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: Text(
                                  'No events for this day.',
                                ),
                              ),
                            ),
                          ),

                        for (final event in visibleEvents)
                          EventCard(
                            event: event,
                            timeText:
                                '${formatTime(event.startMinutes)} – ${formatTime(event.endMinutes)}',
                            onEdit: () => editEvent(event),
                            onDelete: () => deleteEvent(event),
                          ),

                        const SizedBox(height: 24),

                        Text(
                          'Tasks',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),

                        if (visibleTasks.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: Text(
                                  'No tasks for this day.',
                                ),
                              ),
                            ),
                          ),

                        for (final task in visibleTasks)
                          TaskCard(
                            task: task,
                            onToggle: () => toggleTask(task),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// -----------------------------------------------------------------------------
// EVENT CARD
// -----------------------------------------------------------------------------

class EventCard extends StatelessWidget {
  final PlannerEvent event;
  final String timeText;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const EventCard({
    super.key,
    required this.event,
    required this.timeText,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final eventColor = Color(event.colorValue);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 6,
              color: eventColor,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 82,
                      child: Text(
                        timeText,
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (event.description
                              .trim()
                              .isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(event.description),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            event.ownerName,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit();
                        } else if (value == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Edit'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete_outline),
                            title: Text('Delete'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TASK CARD
// -----------------------------------------------------------------------------

class TaskCard extends StatelessWidget {
  final PlannerTask task;
  final VoidCallback onToggle;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Checkbox(
          value: task.completed,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.completed
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: task.description.isEmpty
            ? Text(task.ownerName)
            : Text(
                '${task.description}\n${task.ownerName}',
              ),
        isThreeLine: task.description.isNotEmpty,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ADD / EDIT SCREEN
// -----------------------------------------------------------------------------

class AddItemScreen extends StatefulWidget {
  final DateTime initialDate;
  final PlannerEvent? existingEvent;

  const AddItemScreen({
    super.key,
    required this.initialDate,
    this.existingEvent,
  });

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  late DateTime selectedDate;
  late TimeOfDay startTime;
  late TimeOfDay endTime;

  bool isEvent = true;

  final uuid = const Uuid();

  bool get isEditing => widget.existingEvent != null;

  @override
  void initState() {
    super.initState();

    final event = widget.existingEvent;

    if (event != null) {
      titleController.text = event.title;
      descriptionController.text = event.description;

      selectedDate = event.date;

      startTime = TimeOfDay(
        hour: event.startMinutes ~/ 60,
        minute: event.startMinutes % 60,
      );

      endTime = TimeOfDay(
        hour: event.endMinutes ~/ 60,
        minute: event.endMinutes % 60,
      );
    } else {
      selectedDate = widget.initialDate;
      startTime = const TimeOfDay(
        hour: 9,
        minute: 0,
      );
      endTime = const TimeOfDay(
        hour: 10,
        minute: 0,
      );
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  int timeToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      selectedDate = picked;
    });
  }

  Future<void> pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: startTime,
    );

    if (picked == null) return;

    setState(() {
      startTime = picked;

      if (timeToMinutes(endTime) <=
          timeToMinutes(startTime)) {
        endTime = TimeOfDay(
          hour: (picked.hour + 1) % 24,
          minute: picked.minute,
        );
      }
    });
  }

  Future<void> pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: endTime,
    );

    if (picked == null) return;

    setState(() {
      endTime = picked;
    });
  }

  void save() {
    final title = titleController.text.trim();
    final description =
        descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title.'),
        ),
      );
      return;
    }

    final startMinutes = timeToMinutes(startTime);
    final endMinutes = timeToMinutes(endTime);

    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'End time must be after start time.',
          ),
        ),
      );
      return;
    }

    if (isEvent) {
      final oldEvent = widget.existingEvent;

      final event = PlannerEvent(
        id: oldEvent?.id ?? uuid.v4(),
        title: title,
        description: description,
        date: selectedDate,
        startMinutes: startMinutes,
        endMinutes: endMinutes,
        ownerId: oldEvent?.ownerId ?? 'me',
        ownerName: oldEvent?.ownerName ?? 'Me',
        colorValue:
            oldEvent?.colorValue ?? 0xFF3F51B5,
      );

      Navigator.pop(context, event);
      return;
    }

    final task = PlannerTask(
      id: uuid.v4(),
      title: title,
      description: description,
      dueDate: selectedDate,
      ownerId: 'me',
      ownerName: 'Me',
      completed: false,
      colorValue: 0xFF00897B,
    );

    Navigator.pop(context, task);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Event' : 'Add Item',
        ),
        actions: [
          TextButton(
            onPressed: save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: true,
                icon: Icon(Icons.event_outlined),
                label: Text('Event'),
              ),
              ButtonSegment<bool>(
                value: false,
                icon: Icon(Icons.task_alt),
                label: Text('Task'),
              ),
            ],
            selected: {isEvent},
            onSelectionChanged: isEditing
                ? null
                : (selection) {
                    setState(() {
                      isEvent = selection.first;
                    });
                  },
          ),

          const SizedBox(height: 20),

          TextField(
            controller: titleController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'Work',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 14),

          TextField(
            controller: descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Optional',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 20),

          // DATE
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.calendar_today_outlined,
              ),
              title: const Text('Date'),
              subtitle: Text(
                DateFormat(
                  'EEEE, d MMMM yyyy',
                ).format(selectedDate),
              ),
              trailing: const Icon(
                Icons.chevron_right,
              ),
              onTap: pickDate,
            ),
          ),

          // EVENT TIMES
          if (isEvent) ...[
            const SizedBox(height: 10),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.play_arrow_outlined,
                    ),
                    title: const Text('Start time'),
                    subtitle: Text(
                      startTime.format(context),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: pickStartTime,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.stop_outlined,
                    ),
                    title: const Text('End time'),
                    subtitle: Text(
                      endTime.format(context),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: pickEndTime,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${startTime.format(context)} – ${endTime.format(context)}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (!isEvent) ...[
            const SizedBox(height: 16),
            const Text(
              'Tasks currently use the selected date as their due date.',
            ),
          ],

          const SizedBox(height: 30),

          FilledButton.icon(
            onPressed: save,
            icon: Icon(
              isEditing
                  ? Icons.save_outlined
                  : Icons.add,
            ),
            label: Text(
              isEditing
                  ? 'Save Changes'
                  : 'Create ${isEvent ? 'Event' : 'Task'}',
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SETTINGS
// -----------------------------------------------------------------------------

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('People'),
            subtitle: const Text(
              'Manage people in your planner',
            ),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(
              Icons.calendar_month_outlined,
            ),
            title: const Text('Shared Calendars'),
            subtitle: const Text(
              'Manage calendars shared with others',
            ),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(
              Icons.notifications_outlined,
            ),
            title: const Text('Notifications'),
            subtitle: const Text(
              'Manage reminders and notifications',
            ),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text(
              'Sharred Planner',
            ),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Sharred Planner',
                applicationVersion: '1.0.0',
                applicationLegalese:
                    'Shared calendar and task planner',
              );
            },
          ),
        ],
      ),
    );
  }
}
