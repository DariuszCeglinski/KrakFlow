import 'package:flutter/material.dart';

void main() {
  runApp( MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  List<Task> tasks = [
    Task(title: "Projekt graficzny", deadline: "jutro", priority: "niski", done: true),
    Task(title: "Ćwiczenia na kolosa", deadline: "dzisiaj", priority: "średni", done: false),
    Task(title: "Zjeść obiad", deadline: "w tym tygodniu", priority: "wysoki", done: true),
    Task(title: "Kupić ziemniaki", deadline: "w tym tygodniu", priority: "wysoki", done: false),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
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
                      "Masz dziś ${tasks.length} zadania",
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
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      return TaskCard(
                          title: tasks[index].title,
                          subtitle: tasks[index].deadline,
                          icon: tasks[index].done ? Icons.check_circle : Icons.radio_button_unchecked,
                          priority: tasks[index].priority,
                      );
                    },
                  ))
                ],
              ),
            )
      ),
    );
  }
}

class Task {
  final String title;
  final String deadline;
  final String priority;
  final bool done;

  Task({required this.title, required this.deadline, required this.priority, required this.done});
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