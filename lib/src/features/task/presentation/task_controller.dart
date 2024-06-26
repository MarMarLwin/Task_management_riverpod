// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_management/src/features/task/application/task_service.dart';
import 'package:task_management/src/features/task/domain/task.dart';

class TaskController extends StateNotifier<AsyncValue<List<AppTask>>> {
  TaskController(this.taskService) : super(const AsyncData([])) {
    getTasks();
  }
  final TaskService taskService;

  Future<void> getTasks() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final taskList = await taskService.readTasks();
      return taskList;
    });
  }

  Future<void> addOrUpdateTask(AppTask task) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      var appTask = TaskModel(
          title: task.title,
          description: task.description,
          dueDate: task.dueDate,
          isDone: task.isDone);
      taskService.handleSavingReminder(
          isDone: task.isDone, key: task.id, task: appTask);
      await taskService.writeTask(task);
      final taskList = await taskService.readTasks();

      return taskList;
    });
  }

  Future<void> removeTask(AppTask task) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await taskService.removeTask(task);
      final taskList = await taskService.readTasks();
      return taskList;
    });
  }
}

final taskControllerProvider = StateNotifierProvider.autoDispose<TaskController,
    AsyncValue<List<AppTask>>>((ref) {
  return TaskController(ref.watch(taskServiceProvider));
});
