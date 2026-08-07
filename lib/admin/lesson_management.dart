import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../modules/training/models/course_model.dart';
import '../modules/training/repositories/firebase_training_repository.dart';

import 'lesson_management_screen.dart';
import 'services/training_admin_service.dart';
import 'widgets/course_admin_card.dart';
import 'widgets/course_form_dialog.dart';

class TrainingManagement extends StatefulWidget {

  const TrainingManagement({
    super.key,
    required FirebaseFunctions functions,
  });


  @override
  State<TrainingManagement> createState() =>
      _TrainingManagementState();

}



class _TrainingManagementState
    extends State<TrainingManagement> {


  final FirebaseTrainingRepository repository =
  FirebaseTrainingRepository();


  final TrainingAdminService adminService =
  TrainingAdminService();


  List<CourseModel> courses = [];


  bool loading = true;





  @override
  void initState() {

    super.initState();

    _loadCourses();

  }








  Future<void> _loadCourses() async {

    if(mounted){

      setState(() {

        loading = true;

      });

    }


    try {


      final result =
      await repository.getCourses();



      if(!mounted) return;


      setState(() {

        courses = result;

        loading = false;

      });


    }

    catch(e){

      debugPrint(
        "LOAD COURSES ERROR: $e",
      );


      if(!mounted) return;


      setState(() {

        loading = false;

      });


      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(

          content:
          Text(
            "Failed to load courses: $e",
          ),

          backgroundColor:
          Colors.red,

        ),

      );

    }

  }









  Future<void> _showAddCourseDialog() async {


    await showDialog(

      context: context,

      builder:(context){


        return CourseFormDialog(

          onSave:(data) async {


            try {


              await adminService.addCourse(

                title:
                data["title"] ?? "",


                description:
                data["description"] ?? "",


                driveFolderId:
                data["driveFolderId"] ?? "",


                driveFolderUrl:
                data["driveFolderUrl"] ?? "",

              );



              if(context.mounted){

                Navigator.pop(context);

              }


              await _loadCourses();



            }

            catch(e){


              debugPrint(
                "ADD COURSE ERROR: $e",
              );


            }


          },

        );


      },

    );


  }









  Future<void> _showEditCourseDialog(
      CourseModel course,
      ) async {


    await showDialog(

      context: context,

      builder:(context){


        return CourseFormDialog(


          initialData:{


            "title":
            course.title,


            "description":
            course.description,


            "driveFolderId":
            course.driveFolderId,


            "driveFolderUrl":
            course.driveFolderUrl,

          },



          onSave:(data) async {


            try {


              await adminService.updateCourse(

                course.id,

                {


                  "title":
                  data["title"] ?? "",


                  "description":
                  data["description"] ?? "",


                  "driveFolderId":
                  data["driveFolderId"] ?? "",


                  "driveFolderUrl":
                  data["driveFolderUrl"] ?? "",


                },

              );



              if(context.mounted){

                Navigator.pop(context);

              }


              await _loadCourses();


            }


            catch(e){

              debugPrint(
                "UPDATE COURSE ERROR: $e",
              );

            }


          },

        );


      },

    );


  }









  Future<void> _deleteCourse(
      CourseModel course,
      ) async {



    final confirm =
    await showDialog<bool>(


      context: context,


      builder:(context){


        return AlertDialog(


          title:
          const Text(
            "Delete Course",
          ),


          content:
          Text(
            "Delete ${course.title}?",
          ),



          actions:[


            TextButton(

              onPressed:(){

                Navigator.pop(
                  context,
                  false,
                );

              },

              child:
              const Text(
                "Cancel",
              ),

            ),



            ElevatedButton(

              style:
              ElevatedButton.styleFrom(

                backgroundColor:
                Colors.red,

              ),


              onPressed:(){

                Navigator.pop(
                  context,
                  true,
                );

              },


              child:
              const Text(
                "Delete",
              ),

            ),


          ],


        );


      },


    );



    if(confirm != true){

      return;

    }





    try {


      await adminService.deleteCourse(
        course.id,
      );


      await _loadCourses();


    }


    catch(e){

      debugPrint(
        "DELETE COURSE ERROR: $e",
      );

    }


  }









  Future<void> _manageLessons(
      CourseModel course,
      ) async {


    await Navigator.push(

      context,

      MaterialPageRoute(

        builder:(_)=>

            LessonManagementScreen(

              course:course,

            ),

      ),

    );



    await _loadCourses();


  }









  @override
  Widget build(BuildContext context) {


    return Scaffold(


      backgroundColor:
      const Color(
        0xffF5F8FC,
      ),



      appBar:

      AppBar(

        title:
        const Text(
          "Training Management",
        ),


        actions:[


          IconButton(

            icon:
            const Icon(
              Icons.refresh,
            ),

            onPressed:
            loading
                ? null
                : _loadCourses,

          ),

        ],


      ),







      floatingActionButton:

      FloatingActionButton.extended(

        onPressed:
        _showAddCourseDialog,


        icon:
        const Icon(
          Icons.add,
        ),


        label:
        const Text(
          "Add Course",
        ),

      ),







      body:


      loading

          ?

      const Center(

        child:
        CircularProgressIndicator(),

      )


          :


      courses.isEmpty


          ?

      const Center(

        child:
        Text(
          "No Courses Yet",
        ),

      )


          :


      RefreshIndicator(


        onRefresh:
        _loadCourses,


        child:

        ListView.builder(


          padding:
          const EdgeInsets.all(24),



          itemCount:
          courses.length,



          itemBuilder:(context,index){


            final course =
            courses[index];



            return CourseAdminCard(

              course:
              course,



              onEdit:(){

                _showEditCourseDialog(
                  course,
                );

              },



              onDelete:(){

                _deleteCourse(
                  course,
                );

              },



              onManageLessons:(){

                _manageLessons(
                  course,
                );

              },


            );


          },

        ),

      ),


    );


  }


}