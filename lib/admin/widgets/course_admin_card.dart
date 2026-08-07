import 'package:flutter/material.dart';

import '../../modules/training/models/course_model.dart';

class CourseAdminCard extends StatelessWidget {
  final CourseModel course;

  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onManageLessons;

  const CourseAdminCard({
    super.key,
    required this.course,
    required this.onEdit,
    required this.onDelete,
    required this.onManageLessons,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Title + Actions
            Row(
              children: [
                Expanded(
                  child: Text(
                    course.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff003366),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: Colors.blue,
                  ),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// Description
            Text(
              course.description,
              style: const TextStyle(
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 18),


            /// Lessons Count
            Row(
              children: [
                const Icon(
                  Icons.play_circle_outline,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  "${course.lessonsCount} Lessons",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// Drive URL (optional)
            if (course.driveFolderUrl.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.link,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      course.driveFolderUrl,
                      style: const TextStyle(
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.menu_book),
                label: const Text("Manage Lessons"),
                onPressed: onManageLessons,
              ),
            ),
          ],
        ),
      ),
    );
  }
}