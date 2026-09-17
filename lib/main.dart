import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const SharedPlannerApp());
}

// ============================================================
// APP
// ============================================================

class SharedPlannerApp extends StatelessWidget {
  const SharedPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sharred Planner',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),

      home: const HomeScreen(),
    );
  }
}

// ============================================================
// ENUMS
// ============================================================

enum ItemType {
  event,
  task,
}

enum ViewFilter {
  everyone,
  onlyMe,
}

// ============================================================
// EVENT MODEL
// ============================================================

class PlannerEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String ownerId;
  final String ownerName;
  final int colorValue;

  PlannerEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.ownerId,
    required this.ownerName,
    required this.colorValue,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'ownerId': ownerId,
      'ownerName': ownerName,
      'colorValue': colorValue,
    };
  }

  factory PlannerEvent.fromJson(
    Map<String, dynamic> json,
  ) {
    return PlannerEvent(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: DateTime.parse(
        json['date'],
      ),
      ownerId: json['ownerId'] ?? 'me',
      ownerName: json['ownerName'] ?? 'Me',
      colorValue:
          json['colorValue'] ?? Colors.indigo.value,
    );
  }
}

// ============================================================
// TASK MODEL
// ============================================================

class PlannerTask {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String ownerId;
  final String ownerName;
  final bool completed;
  final int colorValue;

  PlannerTask({
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
    bool? completed,
  }) {
    return PlannerTask(
      id: id,
      title: title,
      description: description,
      dueDate: dueDate,
      ownerId: ownerId,
      ownerName: ownerName,
      completed:
          completed ?? this.completed,
      colorValue: colorValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate':
          dueDate.toIso8601String(),
      'ownerId': ownerId,
      'ownerName': ownerName,
      'completed': completed,
      'colorValue': colorValue,
    };
  }

  factory PlannerTask.fromJson(
    Map<String, dynamic> json,
  ) {
    return PlannerTask(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dueDate: DateTime.parse(
        json['dueDate'],
      ),
      ownerId: json['ownerId'] ?? 'me',
      ownerName:
          json['ownerName'] ?? 'Me',
      completed:
          json['completed'] ?? false,
      colorValue:
          json['colorValue'] ??
              Colors.orange.value,
    );
  }
}

// ============================================================
// LOCAL STORAGE
// ============================================================

class StorageService {
  static const String eventsKey =
      'planner_events';

  static const String tasksKey =
      'planner_tasks';

  Future<List<PlannerEvent>>
      loadEvents() async {
    final prefs =
        await SharedPreferences
            .getInstance();

    final data =
        prefs.getString(eventsKey);

    if (data == null) {
      return [];
    }

    final decoded =
        jsonDecode(data) as List;

    return decoded
        .map(
          (item) =>
              PlannerEvent.fromJson(
            Map<String, dynamic>.from(
              item,
            ),
          ),
        )
        .toList();
  }

  Future<List<PlannerTask>>
      loadTasks() async {
    final prefs =
        await SharedPreferences
            .getInstance();

    final data =
        prefs.getString(tasksKey);

    if (data == null) {
      return [];
    }

    final decoded =
        jsonDecode(data) as List;

    return decoded
        .map(
          (item) =>
              PlannerTask.fromJson(
            Map<String, dynamic>.from(
              item,
            ),
          ),
        )
        .toList();
  }

  Future<void> saveEvents(
    List<PlannerEvent> events,
  ) async {
    final prefs =
        await SharedPreferences
            .getInstance();

    await prefs.setString(
      eventsKey,
      jsonEncode(
        events
            .map(
              (event) =>
                  event.toJson(),
            )
            .toList(),
      ),
    );
  }

  Future<void> saveTasks(
    List<PlannerTask> tasks,
  ) async {
    final prefs =
        await SharedPreferences
            .getInstance();

    await prefs.setString(
      tasksKey,
      jsonEncode(
        tasks
            .map(
              (task) =>
                  task.toJson(),
            )
            .toList(),
      ),
    );
  }
}

// ============================================================
// HOME SCREEN
// ============================================================

class HomeScreen
    extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen>
      createState() =>
          _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {
  final StorageService storage =
      StorageService();

  List<PlannerEvent> events = [];

  List<PlannerTask> tasks = [];

  DateTime selectedDate =
      DateTime.now();

  ViewFilter filter =
      ViewFilter.everyone;

  @override
  void initState() {
    super.initState();

    loadData();
  }

  Future<void> loadData() async {
    final loadedEvents =
        await storage.loadEvents();

    final loadedTasks =
        await storage.loadTasks();

    if (!mounted) return;

    setState(() {
      events = loadedEvents;
      tasks = loadedTasks;
    });
  }

  bool isSameDay(
    DateTime first,
    DateTime second,
  ) {
    return first.year ==
            second.year &&
        first.month ==
            second.month &&
        first.day ==
            second.day;
  }

  List<PlannerEvent>
      get visibleEvents {
    return events.where((event) {
      if (!isSameDay(
        event.date,
        selectedDate,
      )) {
        return false;
      }

      if (filter ==
              ViewFilter.onlyMe &&
          event.ownerId != 'me') {
        return false;
      }

      return true;
    }).toList();
  }

  List<PlannerTask>
      get visibleTasks {
    return tasks.where((task) {
      if (!isSameDay(
        task.dueDate,
        selectedDate,
      )) {
        return false;
      }

      if (filter ==
              ViewFilter.onlyMe &&
          task.ownerId != 'me') {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void>
      openAddItem() async {
    final result =
        await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddItemScreen(
          selectedDate:
              selectedDate,
        ),
      ),
    );

    if (result
        is PlannerEvent) {
      events.add(result);

      await storage.saveEvents(
        events,
      );

      setState(() {});
    }

    if (result
        is PlannerTask) {
      tasks.add(result);

      await storage.saveTasks(
        tasks,
      );

      setState(() {});
    }
  }

  Future<void>
      toggleTask(
    PlannerTask task,
  ) async {
    final index =
        tasks.indexWhere(
      (item) =>
          item.id == task.id,
    );

    if (index == -1) return;

    tasks[index] =
        task.copyWith(
      completed:
          !task.completed,
    );

    await storage.saveTasks(
      tasks,
    );

    setState(() {});
  }

  void previousDay() {
    setState(() {
      selectedDate =
          selectedDate.subtract(
        const Duration(
          days: 1,
        ),
      );
    });
  }

  void nextDay() {
    setState(() {
      selectedDate =
          selectedDate.add(
        const Duration(
          days: 1,
        ),
      );
    });
  }

  void today() {
    setState(() {
      selectedDate =
          DateTime.now();
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final dateText =
        DateFormat(
      'EEEE, d MMMM yyyy',
    ).format(
      selectedDate,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sharred Planner',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),

        actions: [
          PopupMenuButton<
              ViewFilter>(
            icon: const Icon(
              Icons.visibility,
            ),

            onSelected:
                (value) {
              setState(() {
                filter = value;
              });
            },

            itemBuilder:
                (context) =>
                    const [
              PopupMenuItem(
                value:
                    ViewFilter
                        .everyone,
                child: Row(
                  children: [
                    Icon(
                      Icons.groups,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      'Everyone',
                    ),
                  ],
                ),
              ),

              PopupMenuItem(
                value:
                    ViewFilter
                        .onlyMe,
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Text(
                      'Only Me',
                    ),
                  ],
                ),
              ),
            ],
          ),

          IconButton(
            icon: const Icon(
              Icons.settings,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            openAddItem,
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Add',
        ),
      ),

      body: Column(
        children: [
          const SizedBox(
            height: 12,
          ),

          Text(
            dateText,
            style: Theme.of(
              context,
            )
                .textTheme
                .headlineSmall
                ?.copyWith(
                  fontWeight:
                      FontWeight.bold,
                ),
          ),

          const SizedBox(
            height: 8,
          ),

          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .center,
            children: [
              IconButton(
                onPressed:
                    previousDay,
                icon: const Icon(
                  Icons
                      .chevron_left,
                ),
              ),

              FilledButton
                  .tonal(
                onPressed: today,
                child: const Text(
                  'Today',
                ),
              ),

              IconButton(
                onPressed:
                    nextDay,
                icon: const Icon(
                  Icons
                      .chevron_right,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 6,
          ),

          Container(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration:
                BoxDecoration(
              color: Theme.of(
                context,
              )
                  .colorScheme
                  .secondaryContainer,
              borderRadius:
                  BorderRadius
                      .circular(
                20,
              ),
            ),
            child: Text(
              filter ==
                      ViewFilter
                          .onlyMe
                  ? 'Only my events and tasks'
                  : 'Everyone’s events and tasks',
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight
                        .w600,
              ),
            ),
          ),

          const Divider(
            height: 24,
          ),

          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets
                      .fromLTRB(
                16,
                0,
                16,
                100,
              ),
              children: [
                sectionHeader(
                  context,
                  'Events',
                  Icons.event,
                ),

                const SizedBox(
                  height: 8,
                ),

                if (visibleEvents
                    .isEmpty)
                  emptyCard(
                    'No events for this day.',
                  ),

                ...visibleEvents
                    .map(
                  eventCard,
                ),

                const SizedBox(
                  height: 24,
                ),

                sectionHeader(
                  context,
                  'Tasks',
                  Icons
                      .check_circle_outline,
                ),

                const SizedBox(
                  height: 8,
                ),

                if (visibleTasks
                    .isEmpty)
                  emptyCard(
                    'No tasks for this day.',
                  ),

                ...visibleTasks
                    .map(
                  taskCard,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(
            context,
          )
              .colorScheme
              .primary,
        ),

        const SizedBox(
          width: 8,
        ),

        Text(
          title,
          style: Theme.of(
            context,
          )
              .textTheme
              .titleLarge
              ?.copyWith(
                fontWeight:
                    FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget emptyCard(
    String message,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(
          18,
        ),
        child: Text(
          message,
          style:
              const TextStyle(
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget eventCard(
    PlannerEvent event,
  ) {
    return Card(
      child: ListTile(
        leading:
            CircleAvatar(
          backgroundColor:
              Color(
            event.colorValue,
          ),
          child:
              const Icon(
            Icons.event,
            color:
                Colors.white,
          ),
        ),

        title: Text(
          event.title,
          style:
              const TextStyle(
            fontWeight:
                FontWeight.w600,
          ),
        ),

        subtitle:
            Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            if (event
                .description
                .isNotEmpty)
              Text(
                event
                    .description,
              ),

            Text(
              '👤 ${event.ownerName}',
            ),
          ],
        ),
      ),
    );
  }

  Widget taskCard(
    PlannerTask task,
  ) {
    return Card(
      child: ListTile(
        leading:
            Checkbox(
          value:
              task.completed,
          onChanged: (_) {
            toggleTask(
              task,
            );
          },
        ),

        title: Text(
          task.title,
          style:
              TextStyle(
            fontWeight:
                FontWeight.w600,
            decoration:
                task.completed
                    ? TextDecoration
                        .lineThrough
                    : null,
          ),
        ),

        subtitle: Text(
          '👤 ${task.ownerName}',
        ),
      ),
    );
  }
}

// ============================================================
// ADD ITEM SCREEN
// ============================================================

class AddItemScreen
    extends StatefulWidget {
  final DateTime selectedDate;

  const AddItemScreen({
    super.key,
    required this.selectedDate,
  });

  @override
  State<AddItemScreen>
      createState() =>
          _AddItemScreenState();
}

class _AddItemScreenState
    extends State<AddItemScreen> {
  final titleController =
      TextEditingController();

  final descriptionController =
      TextEditingController();

  ItemType itemType =
      ItemType.event;

  DateTime selectedDate =
      DateTime.now();

  @override
  void initState() {
    super.initState();

    selectedDate =
        widget.selectedDate;
  }

  @override
  void dispose() {
    titleController
        .dispose();

    descriptionController
        .dispose();

    super.dispose();
  }

  Future<void>
      chooseDate() async {
    final result =
        await showDatePicker(
      context: context,
      initialDate:
          selectedDate,
      firstDate:
          DateTime(2020),
      lastDate:
          DateTime(2100),
    );

    if (result != null) {
      setState(() {
        selectedDate =
            result;
      });
    }
  }

  void saveItem() {
    final title =
        titleController
            .text
            .trim();

    if (title.isEmpty) {
      ScaffoldMessenger
          .of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a title.',
          ),
        ),
      );

      return;
    }

    const uuid = Uuid();

    if (itemType ==
        ItemType.event) {
      final event =
          PlannerEvent(
        id: uuid.v4(),
        title: title,
        description:
            descriptionController
                .text
                .trim(),
        date: selectedDate,
        ownerId: 'me',
        ownerName: 'Me',
        colorValue:
            Colors.indigo.value,
      );

      Navigator.pop(
        context,
        event,
      );
    } else {
      final task =
          PlannerTask(
        id: uuid.v4(),
        title: title,
        description:
            descriptionController
                .text
                .trim(),
        dueDate:
            selectedDate,
        ownerId: 'me',
        ownerName: 'Me',
        completed: false,
        colorValue:
            Colors.orange.value,
      );

      Navigator.pop(
        context,
        task,
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          itemType ==
                  ItemType.event
              ? 'New Event'
              : 'New Task',
        ),
      ),

      body: ListView(
        padding:
            const EdgeInsets.all(
          20,
        ),
        children: [
          SegmentedButton<
              ItemType>(
            segments: const [
              ButtonSegment(
                value:
                    ItemType.event,
                label:
                    Text('Event'),
                icon:
                    Icon(
                  Icons.event,
                ),
              ),

              ButtonSegment(
                value:
                    ItemType.task,
                label:
                    Text('Task'),
                icon:
                    Icon(
                  Icons
                      .check_circle,
                ),
              ),
            ],

            selected: {
              itemType,
            },

            onSelectionChanged:
                (selection) {
              setState(() {
                itemType =
                    selection
                        .first;
              });
            },
          ),

          const SizedBox(
            height: 24,
          ),

          TextField(
            controller:
                titleController,
            decoration:
                const InputDecoration(
              labelText:
                  'Title',
              hintText:
                  'Enter a title',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          TextField(
            controller:
                descriptionController,
            maxLines: 4,
            decoration:
                const InputDecoration(
              labelText:
                  'Description',
              hintText:
                  'Optional details',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          Card(
            child:
                ListTile(
              leading:
                  const Icon(
                Icons
                    .calendar_month,
              ),

              title:
                  const Text(
                'Date',
              ),

              subtitle:
                  Text(
                DateFormat(
                  'EEEE, d MMMM yyyy',
                ).format(
                  selectedDate,
                ),
              ),

              onTap:
                  chooseDate,
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          FilledButton.icon(
            onPressed:
                saveItem,

            icon:
                const Icon(
              Icons.check,
            ),

            label: Text(
              itemType ==
                      ItemType.event
                  ? 'Create Event'
                  : 'Create Task',
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SETTINGS
// ============================================================

class SettingsScreen
    extends StatelessWidget {
  const SettingsScreen({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Settings',
        ),
      ),

      body: ListView(
        children: [
          const ListTile(
            leading:
                CircleAvatar(
              child:
                  Icon(
                Icons.person,
              ),
            ),

            title:
                Text(
              'My Account',
            ),

            subtitle:
                Text(
              'Me',
            ),
          ),

          const Divider(),

          ListTile(
            leading:
                const Icon(
              Icons.group,
            ),

            title:
                const Text(
              'People',
            ),

            subtitle:
                const Text(
              'Manage people',
            ),

            onTap: () {
              showInfo(
                context,
                'Online accounts and invitations '
                'will be connected in the next stage.',
              );
            },
          ),

          ListTile(
            leading:
                const Icon(
              Icons.calendar_month,
            ),

            title:
                const Text(
              'Shared Calendars',
            ),

            subtitle:
                const Text(
              'Create and manage calendars',
            ),

            onTap: () {
              showInfo(
                context,
                'Shared calendars will be connected '
                'to the cloud in the next stage.',
              );
            },
          ),

          ListTile(
            leading:
                const Icon(
              Icons.notifications,
            ),

            title:
                const Text(
              'Notifications',
            ),

            subtitle:
                const Text(
              'Event and task reminders',
            ),

            onTap: () {
              showInfo(
                context,
                'Notifications will be added later.',
              );
            },
          ),

          const ListTile(
            leading:
                Icon(
              Icons.info_outline,
            ),

            title:
                Text(
              'About',
            ),

            subtitle:
                Text(
              'Sharred Planner 1.0',
            ),
          ),
        ],
      ),
    );
  }

  void showInfo(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger
        .of(context)
        .showSnackBar(
      SnackBar(
        content:
            Text(message),
      ),
    );
  }
}
