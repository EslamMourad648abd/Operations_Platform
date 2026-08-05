import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/google_drive_player.dart';
import '../models/lesson_model.dart';


class LessonScreen extends StatelessWidget {


  final LessonModel lesson;


  const LessonScreen({
    super.key,
    required this.lesson,
  });



  Future<void> _openVideo() async {


    final uri = Uri.parse(
      lesson.videoUrl,
    );


    if(await canLaunchUrl(uri)){

      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

    }


  }



  @override
  Widget build(BuildContext context){


    return Scaffold(

      backgroundColor:
      const Color(0xffF5F8FC),


      appBar: AppBar(

        title:
        Text(lesson.title),

      ),



      body: SingleChildScrollView(

        child: Padding(

          padding: const EdgeInsets.all(30),

        child: Column(

          crossAxisAlignment:
          CrossAxisAlignment.start,


          children: [


            Text(

              lesson.title,

              style:
              const TextStyle(

                fontSize:28,

                fontWeight:
                FontWeight.bold,

              ),

            ),



            const SizedBox(height:25),



            GoogleDrivePlayer(

              videoUrl: lesson.videoUrl,

            ),



            const SizedBox(height:25),



            Text(

              lesson.title,

              style:
              const TextStyle(

                fontSize:18,

                fontWeight:
                FontWeight.bold,

              ),

            ),


          ],

        ),

      ),
      ),
    );

  }


}