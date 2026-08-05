import 'package:flutter/material.dart';


class CourseFormDialog extends StatefulWidget {


  final Function(Map<String,dynamic>) onSave;


  final Map<String,dynamic>? initialData;



  const CourseFormDialog({

    super.key,

    required this.onSave,

    this.initialData,

  });



  @override
  State<CourseFormDialog> createState() =>
      _CourseFormDialogState();

}




class _CourseFormDialogState
    extends State<CourseFormDialog>{


  late TextEditingController titleController;

  late TextEditingController descriptionController;

  late TextEditingController durationController;

  late TextEditingController folderIdController;

  late TextEditingController folderUrlController;




  @override
  void initState(){

    super.initState();


    titleController =
        TextEditingController(
          text:
          widget.initialData?["title"] ?? "",
        );


    descriptionController =
        TextEditingController(
          text:
          widget.initialData?["description"] ?? "",
        );


    durationController =
        TextEditingController(
          text:
          widget.initialData?["duration"]
              ?.toString()
              ??
              "",
        );


    folderIdController =
        TextEditingController(
          text:
          widget.initialData?["driveFolderId"]
              ??
              "",
        );


    folderUrlController =
        TextEditingController(
          text:
          widget.initialData?["driveFolderUrl"]
              ??
              "",
        );


  }





  @override
  Widget build(BuildContext context){


    return AlertDialog(


      title:
      Text(

        widget.initialData == null

            ?

        "Add Course"

            :

        "Edit Course",

      ),



      content:

      SingleChildScrollView(

        child:Column(

          mainAxisSize:
          MainAxisSize.min,


          children:[


            TextField(

              controller:titleController,

              decoration:
              const InputDecoration(
                labelText:"Course Title",
              ),

            ),



            TextField(

              controller:
              descriptionController,

              decoration:
              const InputDecoration(
                labelText:"Description",
              ),

            ),



            TextField(

              controller:
              durationController,

              keyboardType:
              TextInputType.number,

              decoration:
              const InputDecoration(
                labelText:"Duration (minutes)",
              ),

            ),



            TextField(

              controller:
              folderIdController,

              decoration:
              const InputDecoration(
                labelText:"Google Drive Folder ID",
              ),

            ),



            TextField(

              controller:
              folderUrlController,

              decoration:
              const InputDecoration(
                labelText:"Google Drive Folder URL",
              ),

            ),


          ],

        ),

      ),



      actions:[


        TextButton(

          onPressed:
              ()=>Navigator.pop(context),

          child:
          const Text(
            "Cancel",
          ),

        ),



        ElevatedButton(


          onPressed:(){


            widget.onSave({


              "title":
              titleController.text.trim(),



              "description":
              descriptionController.text.trim(),



              "duration":
              int.tryParse(
                durationController.text,
              )
                  ??
                  0,



              "driveFolderId":
              folderIdController.text.trim(),



              "driveFolderUrl":
              folderUrlController.text.trim(),



            });



          },


          child:
          const Text(
            "Save",
          ),

        ),



      ],


    );


  }



}