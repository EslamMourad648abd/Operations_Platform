import 'package:flutter/material.dart';

import '../modules/Training/models/course_model.dart';
import '../modules/Training/models/lesson_model.dart';
import 'services/training_admin_service.dart';
import 'widgets/lesson_form_dialog.dart';

class LessonManagementScreen extends StatefulWidget {
  final CourseModel course;

  const LessonManagementScreen({
    super.key,
    required this.course,
  });

  @override
  State<LessonManagementScreen> createState() =>
      _LessonManagementScreenState();
}

class _LessonManagementScreenState
    extends State<LessonManagementScreen> {
  final TrainingAdminService adminService =
  TrainingAdminService();

  List<LessonModel> lessons = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    setState(() {
      loading = true;
    });

    try {
      lessons = await adminService.getLessons(
        widget.course.id,
      );
    } catch (e) {
      debugPrint(e.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ),
        );
      }
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  Future<void> _deleteLesson(
      LessonModel lesson,
      ) async {
    await adminService.deleteLesson(
      widget.course.id,
      lesson.id,
    );

    await _loadLessons();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => LessonFormDialog(
        onSave: (data) async {
          await adminService.addLesson(
            courseId: widget.course.id,
            title: data["title"],
            description: data["description"],
            videoUrl: data["videoUrl"],
            duration: data["duration"],
            order: data["order"],
            quizEnabled: data["quizEnabled"],
          );

          if (mounted) {
            Navigator.pop(context);
          }

          await _loadLessons();
        },
      ),
    );
  }

  void _showEditDialog(
      LessonModel lesson,
      ) {
    showDialog(
      context: context,
      builder: (_) => LessonFormDialog(
        initialData: lesson.toMap(),
        onSave: (data) async {
          await adminService.updateLesson(
            widget.course.id,
            lesson.id,
            data,
          );

          if (mounted) {
            Navigator.pop(context);
          }

          await _loadLessons();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xffF5F8FC),

      appBar: AppBar(
        title: Text(
          widget.course.title,
        ),
      ),

      floatingActionButton:
      FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text(
          "Add Lesson",
        ),
      ),

      body: loading
          ? const Center(
        child:
        CircularProgressIndicator(),
      )
          : lessons.isEmpty
          ? const Center(
        child: Text(
          "No lessons added yet.",
          style: TextStyle(
            fontSize: 18,
          ),
        ),
      )
          : ListView.builder(
        padding:
        const EdgeInsets.all(20),
        itemCount: lessons.length,
        itemBuilder:
            (context, index) {
          final lesson =
          lessons[index];

          return Card(
            margin:
            const EdgeInsets.only(
              bottom: 16,
            ),
            elevation: 2,
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(
                14,
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  lesson.order
                      .toString(),
                ),
              ),

              title: Text(
                lesson.title,
              ),

              subtitle: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    lesson.description,
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
                    "Duration: ${lesson.duration} min",
                  ),
                  Text(
                    lesson.quizEnabled
                        ? "Quiz Enabled"
                        : "Quiz Disabled",
                  ),
                ],
              ),

              trailing: Row(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: Colors.blue,
                    ),
                    onPressed: () =>
                        _showEditDialog(
                          lesson,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    onPressed: () =>
                        _deleteLesson(
                          lesson,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}