import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'task_repository.dart';

void main() {
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

class TaskApiService {
  static const String baseUrl = "https://dummyjson.com";
  
  static Future<List<Task>> fetchTasks() async {
    final response = await http.get(
      Uri.parse("$baseUrl/todos"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List todos = data["todos"];

      return todos.map((todo) {
        final random = Random();
        final deadlines = ["jutro", "pojutrze", "poniedziałek"];
        final priorities = ["niski", "średni", "wysoki"];
        final priority = priorities[random.nextInt(priorities.length)];
        final deadline = deadlines[random.nextInt(deadlines.length)];
        return Task(
          title: todo["todo"],
          deadline: deadline,
          done: todo["completed"],
          priority: priority,
        );
      }).toList();
    } else {
      throw Exception("Błąd pobierania danych");
    }
  }
}

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<StatefulWidget> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late Future<List<Task>> tasksFuture;

  @override
  void initState() {
    super.initState();
    tasksFuture = TaskApiService.fetchTasks();
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
            final tasks = snapshot.data!;

            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return TaskCard(
                  title: tasks[index].title,
                  subtitle: tasks[index].deadline,
                  done: tasks[index].done,
                  priority: tasks[index].priority,
                  onChanged: (value){
                    setState(() {
                      TaskRepository.tasks[index] = Task(
                        title: tasks[index].title,
                        deadline: tasks[index].deadline,
                        priority: tasks[index].priority,
                        done: value!,
                      );
                    });
                  },
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

  @override
  Widget build(BuildContext context) {
    List<Task> filteredTasks = TaskRepository.tasks;

    if (selectedFilter == "wykonane") {
      filteredTasks = TaskRepository.tasks
          .where((task) => task.done).toList();
    } else if (selectedFilter == "do zrobienia"){
      filteredTasks = TaskRepository.tasks
          .where((task) => !task.done).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("KrakFlow"),
        actions: [
          IconButton(
              onPressed: () {
                if (TaskRepository.tasks.isEmpty) {
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
                            onPressed: () {
                              setState(() {
                                TaskRepository.tasks.clear();
                              });
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
                color: TaskRepository.tasks.isEmpty ? Colors.black.withValues(alpha: 0.3) : Colors.black,
              )
          ),
        ],
      ),
      body:
      Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
                "Masz dziś ${TaskRepository.tasks.length} zadania",
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
              child: TaskListScreen(),
            //     child: ListView.builder(
            //   itemCount: filteredTasks.length,
            //   itemBuilder: (context, index) {
            //     final task = filteredTasks[index];
            //     return Dismissible(
            //         key: ValueKey(task.title),
            //         direction: DismissDirection.startToEnd,
            //         onDismissed: (direction){
            //             setState(() {
            //               TaskRepository.tasks.remove(task);
            //             });
            //
            //             ScaffoldMessenger.of(context).showSnackBar(
            //             SnackBar(
            //               content: Text("Usunięto zadanie: ${task.title}")
            //             ),
            //           );
            //         },
            //         child: TaskCard(
            //           title: task.title,
            //           subtitle: task.deadline,
            //           done: task.done,
            //           priority: task.priority,
            //           onChanged: (value){
            //             setState(() {
            //               TaskRepository.tasks[index] = Task(
            //                 title: task.title,
            //                 deadline: task.deadline,
            //                 priority: task.priority,
            //                 done: value!,
            //               );
            //             });
            //           },
            //           onTap: () async {
            //             final Task? updatedTask = await Navigator.push(
            //                 context,
            //                 MaterialPageRoute(
            //                   builder: (context) => EditTaskScreen(task: task),
            //                 ),
            //             );
            //
            //             if (updatedTask != null) {
            //               setState(() {
            //                 TaskRepository.tasks[index] = updatedTask;
            //               });
            //             }
            //           },
            //         )
            //     );
            //   },
            // )
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
            setState(() {
              TaskRepository.tasks.add(newTask);
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