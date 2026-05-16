import 'package:krakflow/services/task_local_database.dart';
import 'package:krakflow/services/taks_api_service.dart';

class TaskSyncService {

  static Future<void> loadInitialDataIfNeeded() async {
    if (!TaskLocalDatabase.isEmpty()) {
      return;
    }

    final tasks = await TaskApiService.fetchTasks();
    await TaskLocalDatabase.saveTasks(tasks);
  }
}