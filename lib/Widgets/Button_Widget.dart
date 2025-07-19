import 'package:flutter/material.dart';

class ButtonWidget extends StatefulWidget {
  final String? btnText;
  final IconData? bIcon;
  final bool? isDisabled;
  const ButtonWidget({super.key, this.btnText, this.isDisabled, this.bIcon});

  @override
  State<ButtonWidget> createState() => _ButtonWidgetState();
}

class _ButtonWidgetState extends State<ButtonWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
          alignment: Alignment.center,
          width: double.maxFinite,
          padding: EdgeInsets.symmetric(vertical: 12,),
          decoration: BoxDecoration(color: widget.isDisabled == false ? Color(0xFF8F91A0) : Color(0xFF4F66FE),borderRadius: BorderRadius.circular(10)),
          child: widget.bIcon != null ? Icon(widget.bIcon, color: Colors.white,size: 27,) : Text(widget.btnText!, style: TextStyle(color: Colors.white, fontSize: 17,fontWeight: FontWeight.bold),),
        );
  }
}