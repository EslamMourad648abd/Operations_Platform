import 'package:flutter/material.dart';

class PlatformCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;

  const PlatformCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
  });

  // @override
  // Widget build(BuildContext context) {
  //   const primary = Color(0xFF003366);
  //   const secondary = Color(0xFF80CFFF);
  //
  //   return Container(
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(18),
  //       gradient: const LinearGradient(
  //         colors: [primary, secondary],
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //       ),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(.08),
  //           blurRadius: 15,
  //           offset: const Offset(0, 8),
  //         ),
  //       ],
  //     ),
  //     child: Material(
  //       color: Colors.transparent,
  //       child: InkWell(
  //         borderRadius: BorderRadius.circular(18),
  //         onTap: enabled ? onPressed : null,
  //         child: Padding(
  //           padding: const EdgeInsets.all(22),
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //
  //               CircleAvatar(
  //                 radius: 26,
  //                 backgroundColor: Colors.white.withOpacity(.15),
  //                 child: Icon(
  //                   icon,
  //                   color: Colors.white,
  //                   size: 28,
  //                 ),
  //               ),
  //
  //               const Spacer(),
  //
  //               Text(
  //                 title,
  //                 style: const TextStyle(
  //                   color: Colors.white,
  //                   fontSize: 22,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //
  //               const SizedBox(height: 8),
  //
  //               Text(
  //                 subtitle,
  //                 style: TextStyle(
  //                   color: Colors.white.withOpacity(.9),
  //                   height: 1.4,
  //                 ),
  //               ),
  //
  //               const SizedBox(height: 20),
  //
  //               Row(
  //                 children: [
  //
  //                   Container(
  //                     padding: const EdgeInsets.symmetric(
  //                       horizontal: 12,
  //                       vertical: 6,
  //                     ),
  //                     decoration: BoxDecoration(
  //                       color: enabled
  //                           ? Colors.green
  //                           : Colors.orange,
  //                       borderRadius: BorderRadius.circular(20),
  //                     ),
  //                     child: Text(
  //                       enabled
  //                           ? "Available"
  //                           : "Coming Soon",
  //                       style: const TextStyle(
  //                         color: Colors.white,
  //                         fontWeight: FontWeight.w600,
  //                       ),
  //                     ),
  //                   ),
  //
  //                   const Spacer(),
  //
  //                    Icon(
  //                     enabled
  //                     ? Icons.arrow_forward_rounded
  //                     : Icons.desktop_access_disabled_rounded,
  //                     color: Colors.white,
  //
  //                   )
  //                 ],
  //               )
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF003366);
    const secondary = Color(0xFF80CFFF);

    final disabled = !enabled;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),

        gradient: LinearGradient(
          colors: disabled
              ? [
            Colors.grey.shade400,
            Colors.grey.shade600,
          ]
              : [
            primary,
            secondary,
          ],

          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: enabled ? onPressed : null,

          child: Padding(
            padding: const EdgeInsets.all(22),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                CircleAvatar(
                  radius: 26,

                  backgroundColor:
                  Colors.white.withOpacity(.15),

                  child: Icon(
                    icon,

                    color: disabled
                        ? Colors.white70
                        : Colors.white,

                    size: 28,
                  ),
                ),


                const Spacer(),


                Text(
                  title,

                  style: TextStyle(
                    color: disabled
                        ? Colors.white70
                        : Colors.white,

                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),


                const SizedBox(height: 8),


                Text(
                  subtitle,

                  style: TextStyle(
                    color: disabled
                        ? Colors.white60
                        : Colors.white.withOpacity(.9),

                    height: 1.4,
                  ),
                ),


                const SizedBox(height: 20),


                Row(
                  children: [

                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),

                      decoration: BoxDecoration(
                        color: enabled
                            ? Colors.green
                            : Colors.black26,

                        borderRadius:
                        BorderRadius.circular(20),
                      ),

                      child: Text(
                        enabled
                            ? "Available"
                            : "Coming Soon",

                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ),


                    const Spacer(),


                    Icon(
                      enabled
                          ? Icons.arrow_forward_rounded
                          : Icons.lock_outline_rounded,

                      color: disabled
                          ? Colors.white70
                          : Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}