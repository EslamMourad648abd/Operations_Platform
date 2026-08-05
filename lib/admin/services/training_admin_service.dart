import 'package:cloud_firestore/cloud_firestore.dart';

import '../../modules/Training/models/lesson_model.dart';





class TrainingAdminService {



  final FirebaseFirestore firestore;



  TrainingAdminService({

    FirebaseFirestore? firestore,

  }) :

        firestore =
            firestore ?? FirebaseFirestore.instance;







  // ================================
  // COURSES
  // ================================



  Future<void> addCourse({


    required String title,


    required String description,


    required int duration,


    required String driveFolderId,


    required String driveFolderUrl,


  }) async {



    await firestore

        .collection("training_courses")

        .add({


      "title": title,


      "description": description,


      "duration": duration,


      "driveFolderId": driveFolderId,


      "driveFolderUrl": driveFolderUrl,


      "lessonsCount": 0,


      "createdAt":

      FieldValue.serverTimestamp(),



    });



  }







  Future<void> updateCourse(

      String id,

      Map<String,dynamic> data,

      ) async {



    await firestore

        .collection("training_courses")

        .doc(id)

        .update(data);



  }







  Future<void> deleteCourse(

      String id,

      ) async {



    await firestore

        .collection("training_courses")

        .doc(id)

        .delete();



  }









  // ================================
  // LESSONS
  // ================================





  CollectionReference<Map<String,dynamic>> _lessons(

      String courseId,

      ) {



    return firestore

        .collection("training_courses")

        .doc(courseId)

        .collection("lessons");


  }









  Future<List<LessonModel>> getLessons(

      String courseId,

      ) async {



    final snapshot = await _lessons(courseId)

        .orderBy(

      "order",

      descending: false,

    )

        .get();





    return snapshot.docs.map((doc){



      return LessonModel.fromMap(

        doc.data(),

        doc.id,

      );



    }).toList();



  }









  Future<void> addLesson({


    required String courseId,


    required String title,


    required String description,


    required String videoUrl,


    required int duration,


    required int order,


    required bool quizEnabled,


  }) async {



    await _lessons(courseId)

        .add({


      "courseId": courseId,


      "title": title,


      "description": description,


      "videoUrl": videoUrl,


      "duration": duration,


      "order": order,


      "quizEnabled": quizEnabled,


      "createdAt":

      FieldValue.serverTimestamp(),



    });



    await _updateLessonsCount(courseId);



  }









  Future<void> updateLesson(

      String courseId,

      String lessonId,

      Map<String,dynamic> data,

      ) async {



    await _lessons(courseId)

        .doc(lessonId)

        .update(data);



  }









  Future<void> deleteLesson(

      String courseId,

      String lessonId,

      ) async {



    await _lessons(courseId)

        .doc(lessonId)

        .delete();



    await _updateLessonsCount(courseId);



  }









  Future<void> _updateLessonsCount(

      String courseId,

      ) async {



    final snapshot = await _lessons(courseId)

        .get();



    await firestore

        .collection("training_courses")

        .doc(courseId)

        .update({


      "lessonsCount":

      snapshot.docs.length,


    });



  }




}