import 'package:flutter/material.dart';
import 'package:globee/Core/PushNotificationsService.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            PushNotificationService.sendNotificationToUser(
              "ddVBwWQUACgXWPggriMLZb:APA91bHTXKas6QCHcboDxlqNu0i3RSZTXDgKBahSGcQFUFcgFaMqNAiNkIIhrMmgSp6JLevV3hwyAmYbfK9v4NL1LoFHyoMQxgJen9YepEyVZoggouXx0u8",
              "Welcome Employee",
              "I am User",
            );
          },
          child: Text("Test Share on iOS"),
        ),
      ),
    );
  }
}
