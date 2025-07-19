import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

class PushNotificationServiceChats {
  static Future<String> getAccessToken() async {
    final jsonStr = dotenv.env['GCP_SERVICE_ACCOUNT'];
    final serviceAccountJson = jsonDecode(jsonStr!);

    List<String> scopes = [
      "https://www.googleapis.com/auth/firebase.messaging",
    ];

    final httpClient = await auth.clientViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
    );

    final credentials = await auth.obtainAccessCredentialsViaServiceAccount(
      auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes,
      httpClient,
    );

    httpClient.close();
    return credentials.accessToken.data;
  }

  static Future<void> sendNotificationToUser(
    String deviceToken,
    String title,
    String body,
    String chatId,
  ) async {
    final String accessToken = await getAccessToken();

    final String endPoint =
        'https://fcm.googleapis.com/v1/projects/mazo-4ea7b/messages:send';

    final Map<String, dynamic> message = {
      'message': {
        'token': deviceToken,
        'notification': {'title': title, 'body': body},
        'data': {"action": "open_chat", "chatId": chatId},
        'webpush': {
          'notification': {
            'title': title,
            'body': body,
            'icon': 'https://mazo.com/icon.png', // اختياري
          },
        },
      },
    };

    final dio = Dio();

    try {
      final response = await dio.post(
        endPoint,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
        data: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        print('✅ FCM message sent successfully!');
      } else {
        print('❌ Failed to send FCM message: ${response.statusCode}');
        print(response.data);
      }
    } catch (e) {
      print('❌ Error sending FCM message with Dio: $e');
    }
  }
}
