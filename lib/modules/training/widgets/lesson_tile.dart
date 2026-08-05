import 'package:flutter/material.dart';
import '../models/lesson_model.dart';


class LessonTile extends StatelessWidget {


  final LessonModel lesson;
  final VoidCallback onPressed;


  const LessonTile({

    super.key,

    required this.lesson,

    required this.onPressed,

  });



  @override
  Widget build(BuildContext context) {


    return Card(

      elevation:2,


      child:ListTile(


        leading:
        const CircleAvatar(

          backgroundColor:
          Color(0xff80CFFF),


          child:
          Icon(

            Icons.play_arrow,

            color:Colors.white,

          ),

        ),



        title:
        Text(

          lesson.title,

          style:
          const TextStyle(

            fontWeight:
            FontWeight.w600,

          ),

        ),



        trailing:
        const Icon(

          Icons.arrow_forward_ios,

          size:16,

        ),



        onTap:onPressed,


      ),

    );

  }


}