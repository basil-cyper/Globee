import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:globee/Core/SMServices.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  void sendFreeSMS() async {
    final response = await Dio().post(
      'https://textbelt.com/text',
      data: {
        'phone': '+97471402613',
        'message': 'رسالة تجريبية من باسل 🧪',
        'key': 'textbelt',
      },
    );

    print(response.data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            sendFreeSMS();
          },
          child: Text("Test Share on iOS"),
        ),
      ),
    );
  }
}
