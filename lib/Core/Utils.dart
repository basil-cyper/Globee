import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:globee/Core/PushNotificationsService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppUtils {
  static sNavigateTo(context, routeName) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => routeName));
  }

  static sNavigateToReplace(
    BuildContext context,
    String routeName,
    Map<String, String> queryParams,
  ) {
    GoRouter.of(context).go(routeName, extra: queryParams);
  }

  static snackBarShowing(context, snackTitle) {
    return ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(snackTitle)));
  }

  // Core/Utils.dart
  static Future<List<String>> parseMedia(String jsonString) async {
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  static makeRequests(type, query) async {
    final response = await Dio().get(
      "https://pos7d.site/Globee/Requests.php?$type=$query&k=${DateTime.now().millisecondsSinceEpoch}",
    );
    return json.decode(response.data);
  }

  static makeRequestsViews(type, query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final response = await Dio().get(
      "https://pos7d.site/Globee/Requests.php?$type=$encodedQuery&k=${DateTime.now().millisecondsSinceEpoch}",
    );
    return json.decode(response.data);
  }

  Future uploadUsers(pathFile, uid) async {
    final formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(
        pathFile,
        filename: pathFile.split('/').last,
      ),
      "uid": uid,
      "k": DateTime.now().millisecondsSinceEpoch,
    });
    final response = await Dio().post(
      'https://pos7d.site/Globee/UploadUsers.php',
      data: formData,
      onSendProgress: (int sent, int total) {},
    );
    if (response.statusCode == 200) {
      print('Image uploaded successfully: ${response.data}');
    }
  }

  Future uploadItems(pathFile, itemId, itemTxt, isPush) async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    var merchantUser = await AppUtils.makeRequests(
      "fetch",
      "SELECT Fullname FROM Users WHERE uid = '${prefx.getString("UID")}' ",
    );
    final formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(
        pathFile,
        filename: pathFile.split('/').last,
      ),
      "itemId": itemId,
      "k": DateTime.now().millisecondsSinceEpoch,
    });
    final response = await Dio().post(
      'https://pos7d.site/Globee/Upload.php',
      data: formData,
      onSendProgress: (int sent, int total) {},
    );
    if (response.statusCode == 200) {
      print('Image uploaded successfully: ${response.data}');
      if (isPush == true) {
        var request = await AppUtils.makeRequests(
          "fetch",
          "SELECT * FROM Followers WHERE buyer_id = '${prefx.getString("UID")}' ",
        );

        for (var req in request) {
          print(req['user_token']);
          PushNotificationService.sendNotificationToUser(
            req['user_token'].toString(),
            "${merchantUser[0]['Fullname']} has added a new item – take a look!",
            "Explore the $itemTxt – only on Globee.",
          );
        }
      }
    } else {
      print("Image Not Uploaded");
    }
  }
}
