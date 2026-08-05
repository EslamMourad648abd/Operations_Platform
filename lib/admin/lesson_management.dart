import 'package:bbc_api_tool/admin/services/training_admin_service.dart';
import 'package:flutter/material.dart';

import '../../modules/Training/models/lesson_model.dart';



class LessonManagement extends StatefulWidget {


  final String courseId;


  const LessonManagement({

    super.key,

    required this.courseId,

  });



  @override
  State<LessonManagement> createState() =>
      _LessonManagementState();

}







class _LessonManagementState
    extends State<LessonManagement> {



  final TrainingAdminService service =
  TrainingAdminService();



  List<LessonModel> lessons = [];


  bool loading = true;








  @override
  void initState(){

    super.initState();

    _loadLessons();

  }









  Future<void> _loadLessons() async {


    try{


      final result =
      await service.getLessons(
        widget.courseId,
      );



      if(!mounted) return;



      setState((){


        lessons = result;

        loading = false;


      });



    }
    catch(e){


      debugPrint(
          "LOAD LESSONS ERROR: $e"
      );



      setState((){

        loading = false;

      });


    }


  }









  Future<void> _deleteLesson(

      LessonModel lesson,

      ) async {



    await service.deleteLesson(

      widget.courseId,

      lesson.id,

    );



    await _loadLessons();


  }









  void _openLessonDialog({

    LessonModel? lesson,

  }){



    final title =
    TextEditingController(

      text: lesson?.title ?? "",

    );



    final description =
    TextEditingController(

      text: lesson?.description ?? "",

    );



    final videoUrl =
    TextEditingController(

      text: lesson?.videoUrl ?? "",

    );



    final duration =
    TextEditingController(

      text:

      lesson == null

          ? ""

          :

      lesson.duration.toString(),

    );



    final order =
    TextEditingController(

      text:

      lesson == null

          ? ""

          :

      lesson.order.toString(),

    );



    bool quizEnabled =
        lesson?.quizEnabled ?? false;








    showDialog(

      context: context,

      builder:(context){


        return StatefulBuilder(

          builder:(context,setDialogState){


            return AlertDialog(


              title: Text(

                lesson == null

                    ? "Add Lesson"

                    :

                "Edit Lesson",

              ),



              content: SingleChildScrollView(

                child: Column(

                  children:[


                    TextField(

                      controller:title,

                      decoration:

                      const InputDecoration(

                        labelText:"Title",

                      ),

                    ),



                    TextField(

                      controller:description,

                      decoration:

                      const InputDecoration(

                        labelText:"Description",

                      ),

                    ),



                    TextField(

                      controller:videoUrl,

                      decoration:

                      const InputDecoration(

                        labelText:"Video URL",

                      ),

                    ),



                    TextField(

                      controller:duration,

                      keyboardType:

                      TextInputType.number,

                      decoration:

                      const InputDecoration(

                        labelText:"Duration (minutes)",

                      ),

                    ),



                    TextField(

                      controller:order,

                      keyboardType:

                      TextInputType.number,

                      decoration:

                      const InputDecoration(

                        labelText:"Order",

                      ),

                    ),





                    SwitchListTile(

                      title:

                      const Text(

                        "Enable Quiz",

                      ),


                      value:quizEnabled,


                      onChanged:(value){


                        setDialogState((){


                          quizEnabled = value;


                        });


                      },


                    ),



                  ],

                ),

              ),





              actions:[



                TextButton(

                  onPressed:(){

                    Navigator.pop(context);

                  },

                  child:

                  const Text(

                    "Cancel",

                  ),

                ),





                ElevatedButton(


                  onPressed:() async{


                    final data = {


                      "title":

                      title.text.trim(),


                      "description":

                      description.text.trim(),


                      "videoUrl":

                      videoUrl.text.trim(),


                      "duration":

                      int.tryParse(

                        duration.text,

                      ) ?? 0,


                      "order":

                      int.tryParse(

                        order.text,

                      ) ?? 0,


                      "quizEnabled":

                      quizEnabled,


                    };



                    if(lesson == null){


                      await service.addLesson(

                        courseId:

                        widget.courseId,


                        title:

                        data["title"] as String,


                        description:

                        data["description"] as String,


                        videoUrl:

                        data["videoUrl"] as String,


                        duration:

                        data["duration"] as int,


                        order:

                        data["order"] as int,


                        quizEnabled:

                        data["quizEnabled"] as bool,


                      );



                    }
                    else{


                      await service.updateLesson(

                        widget.courseId,

                        lesson.id,

                        data,

                      );


                    }




                    if(context.mounted){


                      Navigator.pop(context);


                    }



                    await _loadLessons();


                  },


                  child:

                  const Text(

                    "Save",

                  ),


                ),



              ],



            );


          },


        );


      },

    );



  }









  @override
  Widget build(BuildContext context){



    return Scaffold(



      appBar:

      AppBar(

        title:

        const Text(

          "Lesson Management",

        ),

      ),





      floatingActionButton:

      FloatingActionButton.extended(


        onPressed:(){

          _openLessonDialog();

        },


        label:

        const Text(

          "Add Lesson",

        ),


        icon:

        const Icon(

          Icons.add,

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


      ListView.builder(


        padding:

        const EdgeInsets.all(20),



        itemCount:

        lessons.length,



        itemBuilder:(context,index){



          final lesson =
          lessons[index];



          return Card(


            margin:

            const EdgeInsets.only(

              bottom:15,

            ),



            child:

            ListTile(



              title:

              Text(

                "${lesson.order}. ${lesson.title}",

              ),



              subtitle:

              Text(

                lesson.description,

              ),



              trailing:

              Row(


                mainAxisSize:

                MainAxisSize.min,



                children:[



                  IconButton(

                    icon:

                    const Icon(

                      Icons.edit,

                    ),

                    onPressed:(){

                      _openLessonDialog(

                        lesson:lesson,

                      );

                    },

                  ),




                  IconButton(

                    icon:

                    const Icon(

                      Icons.delete,

                      color:Colors.red,

                    ),


                    onPressed:(){

                      _deleteLesson(

                        lesson,

                      );

                    },


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