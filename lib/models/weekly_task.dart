class WeeklyTask {
  int? id;
  String dayOfWeek; // Örneğin: "Pazartesi", "Salı" vb.
  String taskDescription;
  bool isCompleted; // Görevin tamamlanıp tamamlanmadığı

  WeeklyTask({
    this.id,
    required this.dayOfWeek,
    required this.taskDescription,
    required this.isCompleted,
  });

  // WeeklyTask objesini Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dayOfWeek': dayOfWeek,
      'taskDescription': taskDescription,
      'isCompleted': isCompleted
          ? 1
          : 0, // bool değerini INTEGER olarak saklama
    };
  }

  // Map'ten WeeklyTask objesi oluşturma
  factory WeeklyTask.fromMap(Map<String, dynamic> map) {
    return WeeklyTask(
      id: map['id'],
      dayOfWeek: map['dayOfWeek'],
      taskDescription: map['taskDescription'],
      isCompleted: map['isCompleted'] == 1, // INTEGER değerini bool'a çevirme
    );
  }
}
