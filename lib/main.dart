import 'package:flutter/material.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<StatefulWidget> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("KrakFlow"),
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
            SizedBox(height: 16,),
            Text(
                "Dzisiejsze zadania",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                )
            ),
            Expanded(child: ListView.builder(
              itemCount: TaskRepository.tasks.length,
              itemBuilder: (context, index) {
                return TaskCard(
                  title: TaskRepository.tasks[index].title,
                  subtitle: TaskRepository.tasks[index].deadline,
                  icon: TaskRepository.tasks[index].done
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  priority: TaskRepository.tasks[index].priority,
                );
              },
            ))
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

class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String priority;
  final IconData icon;

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: EdgeInsets.symmetric(
        vertical: 6,
        horizontal: 0,
      ),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold),),
        subtitle: Text("Termin: $subtitle | Priorytet: $priority"),
      ),)
    );
  }
}