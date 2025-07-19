import 'package:flutter/material.dart';

class RectButtonWidget extends StatelessWidget {
  final IconData? bicon;
  final double? bsize;
  final double? bwidth;
  final double? bheight;
  const RectButtonWidget({super.key, this.bicon, this.bsize, this.bwidth, this.bheight});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Container(
        width: bwidth ?? 50,
        height: bwidth ?? 50,
        decoration: BoxDecoration(
          color: Color(0xFF4F67FF),
          borderRadius: BorderRadius.circular(10)
        ),
        child: Icon(bicon,color:Colors.white,size: bsize),
      ),
    );
  }
}