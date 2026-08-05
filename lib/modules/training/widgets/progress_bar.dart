import 'package:flutter/material.dart';


class ProgressBar extends StatelessWidget {

  final double value;


  const ProgressBar({
    super.key,
    required this.value,
  });


  @override
  Widget build(BuildContext context) {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        LinearProgressIndicator(
          value:value,
          minHeight:8,
          borderRadius: BorderRadius.circular(10),
          backgroundColor: Colors.grey.shade200,
          color: const Color(0xff80CFFF),
        ),


        const SizedBox(height:5),


        Text(
          "${(value*100).round()}%",
          style: const TextStyle(
            fontSize:12,
            color: Colors.grey,
          ),
        )

      ],
    );
  }
}