import 'package:flutter/material.dart';

import '../models/course_model.dart';
import '../models/lesson_model.dart';
import '../repositories/firebase_training_repository.dart';
import '../widgets/progress_bar.dart';
import '../widgets/lesson_tile.dart';
import 'lesson_screen.dart';

class CourseDetails extends StatelessWidget {
  final CourseModel course;

  const CourseDetails({
    super.key,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    final repository = FirebaseTrainingRepository();

    return Scaffold(
      backgroundColor: const Color(0xffF5F8FC),

      appBar: AppBar(
        title: Text(course.title),
        elevation: 0,
      ),

      body: FutureBuilder<List<LessonModel>>(
        future: repository.getLessons(course.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
              ),
            );
          }

          final lessons = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                /// Course Header
                Text(
                  course.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  course.description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 24),

                /// Progress
                const Text(
                  "Course Progress",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const ProgressBar(
                  value: 0,
                ),

                const SizedBox(height: 30),

                /// Info Cards
                Row(
                  children: [
                    _InfoCard(
                      icon: Icons.menu_book,
                      title: "Lessons",
                      value: lessons.length.toString(),
                    ),

                    const SizedBox(width: 12),

                    _InfoCard(
                      icon: Icons.timer,
                      title: "Duration",
                      value:
                      "${course.duration} min",
                    ),
                  ],
                ),

                const SizedBox(height: 35),

                const Text(
                  "Lessons",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                if (lessons.isEmpty)
                  const Center(
                    child: Padding(
                      padding:
                      EdgeInsets.symmetric(
                        vertical: 40,
                      ),
                      child: Text(
                        "No lessons available",
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics:
                    const NeverScrollableScrollPhysics(),
                    itemCount: lessons.length,
                    itemBuilder:
                        (context, index) {
                      final lesson =
                      lessons[index];

                      return LessonTile(
                        lesson: lesson,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LessonScreen(
                                    lesson: lesson,
                                  ),
                            ),
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
        const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon),

            const SizedBox(height: 8),

            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              value,
              style: const TextStyle(
                fontWeight:
                FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}