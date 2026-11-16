/// Kontrak abstraksi antarmuka sumber data tugas
abstract interface class TaskRepository {
  Future<List<String>> getTasks();
}

/// Service atau Use Case yang bergantung pada abstraksi TaskRepository
class TaskService {
  final TaskRepository _repository;

  TaskService(this._repository);

  /// Memuat daftar tugas secara asinkron dari repository
  Future<List<String>> loadTasks() {
    return _repository.getTasks();
  }

  /// Memuat tugas dengan filter (kasus bisnis lanjutan)
  Future<List<String>> loadTasksFiltered(String keyword) async {
    final tasks = await _repository.getTasks();
    if (keyword.trim().isEmpty) return tasks;
    return tasks
        .where((t) => t.toLowerCase().contains(keyword.toLowerCase()))
        .toList();
  }
}
