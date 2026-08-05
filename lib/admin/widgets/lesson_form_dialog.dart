import 'package:flutter/material.dart';

class LessonFormDialog extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const LessonFormDialog({
    super.key,
    this.initialData,
    required this.onSave,
  });

  @override
  State<LessonFormDialog> createState() =>
      _LessonFormDialogState();
}

class _LessonFormDialogState
    extends State<LessonFormDialog> {

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late final TextEditingController videoUrlController;
  late final TextEditingController durationController;
  late final TextEditingController orderController;

  bool quizEnabled = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();

    final data = widget.initialData;

    titleController = TextEditingController(
      text: data?["title"] ?? "",
    );

    descriptionController = TextEditingController(
      text: data?["description"] ?? "",
    );

    videoUrlController = TextEditingController(
      text: data?["videoUrl"] ?? "",
    );

    durationController = TextEditingController(
      text: (data?["duration"] ?? "").toString(),
    );

    orderController = TextEditingController(
      text: (data?["order"] ?? "").toString(),
    );

    quizEnabled =
        data?["quizEnabled"] ?? true;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    videoUrlController.dispose();
    durationController.dispose();
    orderController.dispose();
    super.dispose();
  }

  Future<void> _save() async {

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      saving = true;
    });

    await widget.onSave({
      "title": titleController.text.trim(),
      "description":
      descriptionController.text.trim(),
      "videoUrl":
      videoUrlController.text.trim(),
      "duration":
      int.parse(durationController.text),
      "order":
      int.parse(orderController.text),
      "quizEnabled": quizEnabled,
    });

    if (!mounted) return;

    setState(() {
      saving = false;
    });
  }

  InputDecoration decoration(
      String label,
      ) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return AlertDialog(

      title: Text(
        widget.initialData == null
            ? "Add Lesson"
            : "Edit Lesson",
      ),

      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [

                TextFormField(
                  controller:
                  titleController,
                  decoration:
                  decoration("Title"),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "Required";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller:
                  descriptionController,
                  decoration:
                  decoration("Description"),
                  maxLines: 3,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller:
                  videoUrlController,
                  decoration:
                  decoration("Video URL"),
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return "Required";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller:
                  durationController,
                  decoration:
                  decoration("Duration (minutes)"),
                  keyboardType:
                  TextInputType.number,
                  validator: (value) {
                    if (value == null ||
                        int.tryParse(value) ==
                            null) {
                      return "Invalid number";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller:
                  orderController,
                  decoration:
                  decoration("Lesson Order"),
                  keyboardType:
                  TextInputType.number,
                  validator: (value) {
                    if (value == null ||
                        int.tryParse(value) ==
                            null) {
                      return "Invalid number";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                SwitchListTile(
                  contentPadding:
                  EdgeInsets.zero,
                  title:
                  const Text("Enable Quiz"),
                  value: quizEnabled,
                  onChanged: (value) {
                    setState(() {
                      quizEnabled = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),

      actions: [

        TextButton(
          onPressed: saving
              ? null
              : () {
            Navigator.pop(context);
          },
          child: const Text("Cancel"),
        ),

        ElevatedButton(
          onPressed:
          saving ? null : _save,
          child: saving
              ? const SizedBox(
            width: 18,
            height: 18,
            child:
            CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
              : const Text("Save"),
        ),
      ],
    );
  }
}