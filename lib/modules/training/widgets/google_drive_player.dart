import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';


class GoogleDrivePlayer extends StatelessWidget {

  final String videoUrl;


  const GoogleDrivePlayer({
    super.key,
    required this.videoUrl,
  });



  String get previewUrl {

    if (videoUrl.contains("/preview")) {
      return videoUrl;
    }


    final uri = Uri.parse(videoUrl);


    final segments = uri.pathSegments;


    final index = segments.indexOf("d");


    if (index != -1 && index + 1 < segments.length) {

      final fileId = segments[index + 1];


      return "https://drive.google.com/file/d/$fileId/preview";

    }


    return videoUrl;

  }



  @override
  Widget build(BuildContext context) {


    return Center(

      child: ConstrainedBox(

        constraints: const BoxConstraints(

          maxWidth: 1200,

        ),


        child: AspectRatio(

          aspectRatio: 16 / 9,


          child: Card(

            clipBehavior:
            Clip.antiAlias,


            elevation: 4,


            child: HtmlWidget(

              '''
              
              <div style="
                width:100%;
                height:100%;
                overflow:hidden;
              ">

                <iframe

                  src="$previewUrl"

                  style="
                    width:100%;
                    height:100%;
                    border:0;
                    display:block;
                  "

                  allow="autoplay"

                  allowfullscreen>

                </iframe>

              </div>

              ''',

            ),

          ),

        ),

      ),

    );

  }

}