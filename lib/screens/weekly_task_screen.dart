import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/weekly_task.dart';
import '../database/database_helper.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class WeeklyTaskScreen extends StatefulWidget {
  const WeeklyTaskScreen({super.key});

  @override
  _WeeklyTaskScreenState createState() => _WeeklyTaskScreenState();
}

class _WeeklyTaskScreenState extends State<WeeklyTaskScreen>
    with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _daysOfWeek = [
    {'name': 'Pazartesi', 'short': 'PAZ', 'color': const Color(0xFF6C5CE7)},
    {'name': 'Salı', 'short': 'SAL', 'color': const Color(0xFFE17055)},
    {'name': 'Çarşamba', 'short': 'ÇAR', 'color': const Color(0xFF00B894)},
    {'name': 'Perşembe', 'short': 'PER', 'color': const Color(0xFFFFB142)},
    {'name': 'Cuma', 'short': 'CUM', 'color': const Color(0xFFE84393)},
    {'name': 'Cumartesi', 'short': 'CTS', 'color': const Color(0xFF00CEC9)},
    {'name': 'Pazar', 'short': 'PAZ', 'color': const Color(0xFFFF7675)},
  ];

  Map<String, List<WeeklyTask>> _weeklyTasks = {};
  bool _isLoading = true;
  String? _expandedDay;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _loadWeeklyTasks();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeOut),
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  _loadWeeklyTasks() async {
    setState(() {
      _isLoading = true;
    });
    Map<String, List<WeeklyTask>> tasks = {};
    for (var dayInfo in _daysOfWeek) {
      String day = dayInfo['name'];
      tasks[day] = await DatabaseHelper().getWeeklyTasksByDay(day);
    }
    setState(() {
      _weeklyTasks = tasks;
      _isLoading = false;
    });
  }

  _showAddTaskDialog(String dayOfWeek, Color dayColor) {
    TextEditingController taskController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: dayColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_task_rounded,
                        color: dayColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Yeni Görev',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF2D3436),
                            ),
                          ),
                          Text(
                            dayOfWeek,
                            style: TextStyle(
                              fontSize: 14,
                              color: dayColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: taskController,
                  autofocus: true,
                  maxLines: 3,
                  minLines: 1,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : const Color(0xFF2D3436),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Görev açıklamasını yazın...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey[500],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF16213E)
                        : const Color(0xFFF8F9FA),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'İptal',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (taskController.text.isNotEmpty) {
                            WeeklyTask newTask = WeeklyTask(
                              dayOfWeek: dayOfWeek,
                              taskDescription: taskController.text,
                              isCompleted: false,
                            );
                            await DatabaseHelper().insertWeeklyTask(newTask);
                            _loadWeeklyTasks();
                            Navigator.of(context).pop();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: dayColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Ekle',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _toggleTaskCompletion(WeeklyTask task) async {
    task.isCompleted = !task.isCompleted;
    await DatabaseHelper().updateWeeklyTask(task);
    _loadWeeklyTasks();
  }

  _deleteTask(int id) async {
    await DatabaseHelper().deleteWeeklyTask(id);
    _loadWeeklyTasks();
  }

  Widget _buildTaskItem(WeeklyTask task, Color dayColor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _toggleTaskCompletion(task),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: task.isCompleted ? dayColor : Colors.transparent,
                    border: Border.all(
                      color: task.isCompleted ? dayColor : Colors.grey[400]!,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: task.isCompleted
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    task.taskDescription,
                    style: TextStyle(
                      fontSize: 16,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      color: task.isCompleted
                          ? (isDark ? Colors.white54 : Colors.grey[500])
                          : (isDark ? Colors.white : const Color(0xFF2D3436)),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteTask(task.id!),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red[400],
                    size: 20,
                  ),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayCard(Map<String, dynamic> dayInfo, int index) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dayName = dayInfo['name'];
    final dayColor = dayInfo['color'] as Color;
    final tasks = _weeklyTasks[dayName] ?? [];
    final completedTasks = tasks.where((task) => task.isCompleted).length;
    final totalTasks = tasks.length;
    final completionPercentage = totalTasks > 0
        ? completedTasks / totalTasks
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() {
              _expandedDay = _expandedDay == dayName ? null : dayName;
            });
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [dayColor, dayColor.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: dayColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          dayInfo['short'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dayName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF2D3436),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            totalTasks == 0
                                ? 'Henüz görev yok'
                                : '$completedTasks/$totalTasks görev tamamlandı',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                          if (totalTasks > 0) ...[
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: completionPercentage,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                dayColor,
                              ),
                              minHeight: 4,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: dayColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _expandedDay == dayName
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: dayColor,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _expandedDay == dayName
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: [
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      if (tasks.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF16213E)
                                : const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.task_alt_rounded,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Henüz görev eklenmemiş',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...tasks.map((task) => _buildTaskItem(task, dayColor)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showAddTaskDialog(dayName, dayColor),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Görev Ekle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: dayColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F23)
          : const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Haftalık Program',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF2D3436),
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return _buildDayCard(_daysOfWeek[index], index);
                }, childCount: _daysOfWeek.length),
              ),
            ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: () {
            // Tüm günleri genişletme/daraltma toggle
            setState(() {
              if (_expandedDay != null) {
                _expandedDay = null;
              } else {
                _expandedDay = _daysOfWeek[0]['name'];
              }
            });
          },
          icon: Icon(
            _expandedDay != null
                ? Icons.unfold_less_rounded
                : Icons.unfold_more_rounded,
          ),
          label: Text(_expandedDay != null ? 'Daralt' : 'Genişlet'),
          backgroundColor: const Color(0xFF6C5CE7),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
