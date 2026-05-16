import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:krakflow/services/task_local_database.dart';
import 'package:krakflow/services/task_sync_service.dart';
import 'models/task.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox("tasks");

  await TaskSyncService.loadInitialDataIfNeeded();

  runApp( MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}


class TaskListScreen extends StatefulWidget {
  final String selectedFilter;
  final ValueChanged<List<Task>> onTasksLoaded;

  const TaskListScreen({
    super.key,
    required this.selectedFilter,
    required this.onTasksLoaded,
  });

  @override
  State<StatefulWidget> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late Future<List<Task>> tasksFuture;

  @override
  void initState() {
    super.initState();
    tasksFuture = loadTasks();
  }

  Future<List<Task>> loadTasks() async {
    return TaskLocalDatabase.getTasks();
  }

  Future<void> addTask(Task task) async {
    await TaskLocalDatabase.addTask(task);
    tasksFuture = loadTasks();
  }

  Future<void> editTask(Task task) async {
    await TaskLocalDatabase.updateTask(task);
    tasksFuture = loadTasks();
  }

  Future<void> removeTask(Task task) async {
    await TaskLocalDatabase.deleteTask(task.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Task>>(
        future: tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError){
            return Center(
              child: Text("Błąd: ${snapshot.error}"),
            );
          }

          if(snapshot.hasData){
            final tasks = snapshot.data ?? [];

            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onTasksLoaded(tasks);
            });

            List<Task> filteredTasks = tasks;

            if (widget.selectedFilter == "wykonane") {
              filteredTasks = filteredTasks
                  .where((task) => task.done).toList();
            } else if (widget.selectedFilter == "do zrobienia"){
              filteredTasks = filteredTasks
                  .where((task) => !task.done).toList();
            }

            return ListView.builder(
              itemCount: filteredTasks.length,
              itemBuilder: (context, index) {
                final task = filteredTasks[index];

                return Dismissible(
                  key: ValueKey(task.id),
                  direction: DismissDirection.startToEnd,
                  onDismissed: (direction) async {
                    final String removedTitle = task.title;
                    filteredTasks.remove(task);
                    await removeTask(task);

                    setState(() {
                      tasksFuture = loadTasks();
                    });
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Usunięto zadanie: $removedTitle")
                      ),
                    );
                  },
                  child: TaskCard(
                    title: task.title,
                    subtitle: task.deadline,
                    done: task.done,
                    priority: task.priority,
                    onChanged: (value) async {
                      final updatedTask = Task(
                        id: task.id,
                        title: task.title,
                        deadline: task.deadline,
                        priority: task.priority,
                        done: value ?? false,
                      );

                      await editTask(updatedTask);
                      setState(() {});
                    },
                    onTap: () async {
                      final Task? updatedTask = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditTaskScreen(task: task),
                        ),
                      );

                      if (updatedTask != null) {
                        await editTask(updatedTask);
                        setState(() {});
                      }
                    },
                  )
                );
              },
            );
          }
          return const SizedBox();
        },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String filter = "wszystkie";
  String selectedFilter = "wszystkie";

  int allTasksCount = 0;
  int doneTasksCount = 0;
  int todoTasksCount = 0;

  void updateCounters(List<Task> tasks) {
    setState(() {
      allTasksCount = tasks.length;
      doneTasksCount = tasks.where((task) => task.done).length;
      todoTasksCount = tasks.where((task) => !task.done).length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("KrakFlow"),
        actions: [
          IconButton(
              onPressed: () {
                if (TaskLocalDatabase.isEmpty()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Brak zadań do usunięcia!"))
                  );

                  return;
                }
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text("Potwierdzenie"),
                      content: Text("Czy na pewno chcesz usunąć wszyskie zadania?"),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("Anuluj"),
                        ),
                        TextButton(
                            onPressed: () async {
                              await TaskLocalDatabase.deleteAllTasks();

                              setState(() {
                                allTasksCount = 0;
                              });

                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Usunięto wszystkie zadania!"))
                              );
                              Navigator.pop(context);
                            },
                            child: Text("Usuń"),
                        ),
                      ],
                    );
                  }
                );
              },
              icon: Icon(
                Icons.delete,
                color: TaskLocalDatabase.isEmpty() ? Colors.black.withValues(alpha: 0.3) : Colors.black,
              )
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
                "Wszystkie: $allTasksCount",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                )
            ),
            Text(
                "Zrobione: $doneTasksCount",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                )
            ),
            Text(
                "Do zrobienia: $todoTasksCount",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                )
            ),
            FilterBar(
              selectedFilter: selectedFilter,
              onPressed: (value) {
                setState(() {
                  selectedFilter = value;
                });
              },
            ),
            SizedBox(height: 16,),
            Text(
                "Dzisiejsze zadania",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                )
            ),
            Expanded(
              child: TaskListScreen(
                key: ValueKey(allTasksCount),
                selectedFilter: selectedFilter,
                onTasksLoaded: updateCounters,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final Task? newTask = await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => AddTaskScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              }
            ),
          );

          if (newTask != null) {
            await TaskLocalDatabase.addTask(newTask);
            setState(() {
              allTasksCount++;
            });
          }
        },
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        child: Icon(Icons.add),
      ),
    );
  }
}

class FilterBar extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onPressed;

  const FilterBar({
    super.key,
    required this.selectedFilter,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
            onPressed: () => onPressed("wszystkie"),
            style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all( selectedFilter == "wszystkie" ? Colors.lightGreen : Colors.black12),
            ),
            child: Text("Wszystkie", style: TextStyle(fontSize: 12)),
        ),
        TextButton(
            onPressed: () => onPressed("wykonane"),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all( selectedFilter == "wykonane" ? Colors.lightGreen : Colors.black12),
            ),
            child: Text("Wykonane", style: TextStyle(fontSize: 12)),
        ),
        TextButton(
            onPressed: () => onPressed("do zrobienia"),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all( selectedFilter == "do zrobienia" ? Colors.lightGreen : Colors.black12),
            ),
            child: Text("Do zrobienia", style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

}

class AddTaskScreen extends StatelessWidget {
  AddTaskScreen({super.key});

  final TextEditingController titleController = TextEditingController();
  final TextEditingController deadlineController = TextEditingController();
  final TextEditingController priorityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nowe zadanie"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Tytuł zadania",
                border: OutlineInputBorder(),
              ),
            ),
            TextField(
              controller: deadlineController,
              decoration: InputDecoration(
                labelText: "Deadline zadania",
                border: OutlineInputBorder(),
              ),
            ),
            TextField(
              controller: priorityController,
              decoration: InputDecoration(
                labelText: "Priorytet zadania",
                border: OutlineInputBorder(),
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  final newTask = Task(
                    id: Random().nextInt(1000000),
                    title: titleController.text,
                    deadline: deadlineController.text,
                    priority: priorityController.text,
                    done: false,
                  );
                  Navigator.pop(context, newTask);
                },
                child: Text("Zapisz"),
              ),
            )
          ],
        ),
      )
    );
  }
}

class EditTaskScreen extends StatefulWidget {
  final Task task;

  const EditTaskScreen({super.key, required this.task});

  @override
  State<StatefulWidget> createState() => _EditTaskScreen();
}

class _EditTaskScreen extends State<EditTaskScreen> {
  late TextEditingController titleController = TextEditingController();
  late TextEditingController deadlineController = TextEditingController();
  late TextEditingController priorityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.task.title);
    deadlineController = TextEditingController(text: widget.task.deadline);
    priorityController = TextEditingController(text: widget.task.priority);
  }

  @override
  void dispose() {
    titleController.dispose();
    deadlineController.dispose();
    priorityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Edytuj zadanie"),
        ),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: "Tytuł zadania",
                  border: OutlineInputBorder(),
                ),
              ),
              TextField(
                controller: deadlineController,
                decoration: InputDecoration(
                  labelText: "Deadline zadania",
                  border: OutlineInputBorder(),

                ),
              ),
              TextField(
                controller: priorityController,
                decoration: InputDecoration(
                  labelText: "Priorytet zadania",
                  border: OutlineInputBorder(),
                ),

              ),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    final editedTask = Task(
                      id: widget.task.id,
                      title: titleController.text,
                      deadline: deadlineController.text,
                      priority: priorityController.text,
                      done: widget.task.done,
                    );
                    Navigator.pop(context, editedTask);
                  },
                  child: Text("Zapisz"),
                ),
              )
            ],
          ),
        )
    );
  }
}

class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String priority;
  final bool done;
  final Function(bool?)? onChanged;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.priority,
    this.onTap,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: EdgeInsets.symmetric(
        vertical: 6,
        horizontal: 0,
      ),
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(
            value: done,
            onChanged: onChanged,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: done ? TextDecoration.lineThrough : null,
            color: done ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Termin: $subtitle",
              style: TextStyle(
                color: done ? Colors.grey : Colors.black,
              ),
            ),
            Text(
              "Priorytet: $priority",
              style: TextStyle(
                  color: done ? (priority.toLowerCase() == "wysoki" ? Colors.redAccent :
                          priority.toLowerCase() == "średni" ? Colors.orangeAccent : Colors.lightGreen) :
                        (priority.toLowerCase() == "wysoki" ? Colors.red :
                          priority.toLowerCase() == "średni" ? Colors.orange : Colors.green),
              ),
            ),
          ],
        )
      ),)
    );
  }
}