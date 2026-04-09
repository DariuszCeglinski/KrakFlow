
class Task {
  final String title;
  final String deadline;
  final String priority;
  final bool done;

  Task({required this.title, required this.deadline, required this.priority, required this.done});
}

class TaskRepository {
  static List<Task> tasks = [
    Task(title: "Projekt graficzny",
        deadline: "jutro",
        priority: "niski",
        done: true),
    Task(title: "Ćwiczenia na kolosa",
        deadline: "dzisiaj",
        priority: "średni",
        done: false),
    Task(title: "Zjeść obiad",
        deadline: "w tym tygodniu",
        priority: "wysoki",
        done: true),
    Task(title: "Kupić ziemniaki",
        deadline: "w tym tygodniu",
        priority: "wysoki",
        done: false),
  ];
}
