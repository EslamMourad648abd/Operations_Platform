import 'package:flutter/material.dart';
import '../models/course_model.dart';


class CourseCard extends StatefulWidget {

  final CourseModel course;
  final VoidCallback onPressed;


  const CourseCard({
    super.key,
    required this.course,
    required this.onPressed,
  });


  @override
  State<CourseCard> createState() =>
      _CourseCardState();

}



class _CourseCardState extends State<CourseCard> {

  bool _hovering = false;


  @override
  Widget build(BuildContext context) {


    final progress = (0 * 100).round();


    String buttonText;


    if (progress == 0) {

      buttonText = "Start Course";

    } else if (progress == 100) {

      buttonText = "Review Course";

    } else {

      buttonText = "Continue Learning";

    }



    return MouseRegion(

      cursor: SystemMouseCursors.click,


      onEnter: (_) =>
          setState(() => _hovering = true),


      onExit: (_) =>
          setState(() => _hovering = false),



      child: AnimatedScale(

        duration:
        const Duration(milliseconds:180),


        scale:
        _hovering ? 1.02 : 1,



        child: AnimatedContainer(

          duration:
          const Duration(milliseconds:180),



          decoration: BoxDecoration(

            color:
            Colors.white,


            borderRadius:
            BorderRadius.circular(20),



            boxShadow: [

              BoxShadow(

                color:
                Colors.black.withOpacity(
                  _hovering ? .15 : .08,
                ),


                blurRadius:
                _hovering ? 18 : 10,


                offset:
                const Offset(0,6),

              ),

            ],

          ),




          child: Stack(

            children: [



              Padding(

                padding:
                const EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  90,
                ),



                child:SingleChildScrollView(
                  physics:  const NeverScrollableScrollPhysics(),
                  child: Column(

                  crossAxisAlignment:
                  CrossAxisAlignment.start,



                  children: [



                    Center(

                      child: CircleAvatar(

                        radius:34,


                        backgroundColor:
                        const Color(0xff003366)
                            .withOpacity(.08),


                        child: const Icon(

                          Icons.school,

                          size:34,


                          color:
                          Color(0xff003366),

                        ),

                      ),

                    ),




                    const SizedBox(height:20),




                    Text(

                      widget.course.title,


                      maxLines:2,


                      overflow:
                      TextOverflow.ellipsis,



                      style: const TextStyle(

                        fontSize:20,


                        fontWeight:
                        FontWeight.bold,


                        color:
                        Color(0xff003366),

                      ),

                    ),




                    const SizedBox(height:8),




                    Text(

                      widget.course.description,


                      maxLines:3,


                      overflow:
                      TextOverflow.ellipsis,



                      style: const TextStyle(

                        color:
                        Colors.grey,


                        height:1.4,

                      ),

                    ),




                    const SizedBox(height:20),




                    Row(

                      children: [



                        const Icon(

                          Icons.menu_book,

                          size:18,


                          color:
                          Color(0xff003366),

                        ),



                        const SizedBox(width:6),




                        const Flexible(

                          child: Text(

                            "Lessons Available",

                            overflow:
                            TextOverflow.ellipsis,

                          ),

                        ),




                        const Spacer(),




                        const Icon(

                          Icons.schedule,

                          size:18,


                          color:
                          Color(0xff003366),

                        ),




                        const SizedBox(width:6),




                        Text(

                          "${widget.course.duration} min",

                          overflow:
                          TextOverflow.ellipsis,

                        ),


                      ],

                    ),




                    const SizedBox(height:24),




                    const Text(

                      "Progress",

                      style:TextStyle(

                        fontWeight:
                        FontWeight.w600,

                      ),

                    ),




                    const SizedBox(height:8),




                    ClipRRect(

                      borderRadius:
                      BorderRadius.circular(20),



                      child:
                      LinearProgressIndicator(

                        value:0,


                        minHeight:8,



                        backgroundColor:
                        Colors.grey.shade200,



                        valueColor:
                        const AlwaysStoppedAnimation(

                          Color(0xff003366),

                        ),

                      ),

                    ),




                    const SizedBox(height:8),




                    Align(

                      alignment:
                      Alignment.centerRight,



                      child:Text(

                        "$progress%",



                        style:const TextStyle(

                          color:
                          Color(0xff003366),


                          fontWeight:
                          FontWeight.bold,

                        ),

                      ),

                    ),


                  ],

                ),
                ),

              ),




              Positioned(

                left:24,

                right:24,

                bottom:24,



                child:SizedBox(

                  width:
                  double.infinity,



                  child:ElevatedButton(

                    onPressed:
                    widget.onPressed,



                    style:
                    ElevatedButton.styleFrom(

                      backgroundColor:
                      const Color(0xff003366),


                      foregroundColor:
                      Colors.white,



                      padding:
                      const EdgeInsets.symmetric(

                        vertical:15,

                      ),



                      shape:
                      RoundedRectangleBorder(

                        borderRadius:
                        BorderRadius.circular(12),

                      ),

                    ),



                    child:
                    Text(buttonText),

                  ),

                ),

              ),


            ],

          ),

        ),

      ),

    );

  }

}