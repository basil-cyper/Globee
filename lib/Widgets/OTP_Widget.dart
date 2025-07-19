import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

class OtpWidget extends StatelessWidget {
  final TextEditingController? otpController;
  final Function(String)? otpChanged;
  const OtpWidget({super.key, this.otpController, this.otpChanged});

  @override
  Widget build(BuildContext context) {
    return Pinput(
      
      controller: otpController,
      length: 6,
      showCursor: true,
      isCursorAnimationEnabled: true,
      pinAnimationType: PinAnimationType.scale,
      onChanged: otpChanged,
      defaultPinTheme: PinTheme(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Color(0xFFF7F7F7),
          border: Border.all(width: 0, color: Color(0xFFF7F7F7)),
          borderRadius: BorderRadius.circular(9),
        ),
        textStyle: const TextStyle(
          fontSize: 20,
          color: Colors.black,
        ),
      ),
    );
  }
}