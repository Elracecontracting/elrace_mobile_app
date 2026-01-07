import 'package:el_race/utils/color_utils.dart';
import 'package:flutter/material.dart';

class BottomWidget extends StatelessWidget {
  final Function() onTapped;
  const BottomWidget({super.key, required this.onTapped});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(-1.0, 1.0), // Flip horizontally
          child: Image.asset('assets/png/bottom.png'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: GestureDetector(
            onTap: () => onTapped(),
            child: Container(
              width: 120,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: white,
                  boxShadow: const [
                    BoxShadow(
                        color: lightGrey,
                        offset: Offset(1, 4),
                        blurRadius: 10)
                  ]),
              child: Center(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset('assets/png/icons/signout.png'),
                      const Text(
                        'SIGN OUT',
                        style:
                            TextStyle(fontWeight: FontWeight.bold, color: blue),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
