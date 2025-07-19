import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:globee/Core/Theme.dart';
import 'package:globee/Core/Utils.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String lang = "";
  List languages = [];

  Future<void> checkForForceUpdate() async {
    try {
      final dio = Dio();
      String platform = "";
      if (Platform.isIOS) {
        setState(() {
          platform = "IOS";
        });
      } else {
        setState(() {
          platform = "Android";
        });
      }

      final response = await dio.get(
        'https://pos7d.site/Globee/get_update_info.php?platform=$platform&k=${DateTime.now().millisecondsSinceEpoch}',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final latestVersion = data['latest_version'];
        final forceUpdate = data['force_update'].toString() == "1";
        final message = data['message'];
        final storeUrl = data['store_link'];

        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        print(
          "📱 Current: $currentVersion | 🔄 Latest: $latestVersion | 🔐 Force: $forceUpdate",
        );

        if (forceUpdate && currentVersion != latestVersion) {
          print("🚨 Force Update Triggered!");
          context.go(
            '/force-update',
            extra: {'message': message, 'storeUrl': storeUrl},
          );
        }
      }
    } catch (e) {
      print("Error while checking for update: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    checkForForceUpdate();
    _checkLang();
  }

  Future<void> _checkLang() async {
    final prefs = await SharedPreferences.getInstance();
    final storedLang = prefs.getString("Lang");
    if (storedLang != null) {
      lang = storedLang;
      await getLangDB();
      _navigateToHome();
      setState(() {});
    }
  }

  Future getLangDB() async {
    var results = await AppUtils.makeRequests(
      "fetch",
      "SELECT $lang FROM Languages ",
    );
    setState(() {
      languages = results;
    });
  }

  void _navigateToHome() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var userStatus = await AppUtils.makeRequests(
      "fetch",
      "SELECT status FROM Users WHERE uid = '${prefs.getString("UID")}' ",
    );
    if (userStatus[0] != null) {
      if (userStatus[0]['status'] == '2') {
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          context.go('/block');
        });
      } else {
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          context.go('/home');
        });
      }
    } else {
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        context.go('/home');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return languages.isEmpty
        ? const Scaffold(
            body: Center(
              child: SpinKitDoubleBounce(
                color: AppTheme.primaryColor,
                size: 30.0,
              ),
            ),
          )
        : Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      "assets/img/Logo.png",
                      width: MediaQuery.sizeOf(context).width / 2.8,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    languages[0][lang] ?? "",
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const SizedBox(height: 20),
                  SpinKitDoubleBounce(color: AppTheme.primaryColor, size: 30.0),
                ],
              ),
            ),
          );
  }
}
