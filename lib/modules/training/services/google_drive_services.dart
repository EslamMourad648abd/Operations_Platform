import '../models/lesson_model.dart';


class GoogleDriveService {


  Future<List<LessonModel>> getLessonsFromFolder(
      String folderId,
      ) async {


    /*
      Temporary mock data.

      Later this will:

      Flutter
        |
        ↓
      Backend/API
        |
        ↓
      Google Drive API
        |
        ↓
      Files inside folder

    */


    return [

      LessonModel(
        id: "1",
        title: "Introduction to BBC",
        videoUrl:
        "https://drive.google.com/example-video-1", description: '',  order: 2,courseId: '', quizEnabled: true, duration: 1,
      ),


      LessonModel(
        id: "2",
        title: "Platform Navigation",
        videoUrl:
        "https://drive.google.com/example-video-2",description: '',  order: 2,courseId: '', quizEnabled: true, duration: 1,
      ),


      LessonModel(
        id: "3",
        title: "Customer Journey",
        videoUrl:
        "https://drive.google.com/example-video-3",description: '',  order: 2, courseId: '', quizEnabled: true, duration: 1,
      )

    ];

  }


}