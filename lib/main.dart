import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:globee/Core/ApiKeys.dart';
import 'package:globee/Core/Utils.dart';
import 'package:globee/Screens/ForceUpdateScreen.dart';
import 'package:globee/firebase_options.dart';
import 'package:globee/provider/App_Provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:globee/Core/Theme.dart';
import 'package:globee/Routes/App_Router.dart';
import 'package:flutter/services.dart';
import 'package:globee/provider/local_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]);

  await dotenv.load(fileName: ".env");
  print('✅ .env loaded');

  // iOS settings
  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

  // Android settings
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // Combined settings
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Stripe.publishableKey = ApiKeys.publishableKey;
  // await Stripe.instance.applySettings();
  try {
    Firebase.app();
  } catch (e) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
      name: "GlobeeTrading",
    );
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? fcmToken = '';

  Future<void> showNotification(title, body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'your_channel_id',
          'your_channel_name',
          channelDescription: 'your_channel_description',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> initFCM() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    print("UIIIIIID ----> ${prefx.getString("UID")}");
    print("OIIIIIID ----> ${prefx.getString("OID")}");
    NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      fcmToken = await FirebaseMessaging.instance.getToken();
      print("🔥 FCM Token: $fcmToken");
      await AppUtils.makeRequests(
        "query",
        "UPDATE Users SET fcm_token = '$fcmToken' WHERE uid = '${prefx.getString("UID")}' ",
      );
      await AppUtils.makeRequests(
        "query",
        "UPDATE Followers SET user_token = '$fcmToken' WHERE user_id = '${prefx.getString("UID")}' ",
      );
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📩 رسالة أثناء التشغيل: ${message.notification?.title}');
        print(message.notification?.body);
        if (message.notification?.title != '' &&
            message.notification?.body != '') {
          showNotification(
            message.notification?.title,
            message.notification?.body,
          );
          final data = message.data;

          // if (data['action'] == 'open_invoice') {
          //   print(data['orderId']);
          //   AppUtils.sNavigateToReplace(
          //     navigatorKey.currentState!.context,
          //     '/invoice',
          //     {'orderId': data['orderId'], 'shipId': data['shipId']},
          //   );
          // }
        }
      });
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (message.notification?.title != '' &&
            message.notification?.body != '') {
          showNotification(
            message.notification?.title,
            message.notification?.body,
          );
          final data = message.data;
          if (data['action'] == 'open_chat') {
            AppUtils.sNavigateToReplace(
              navigatorKey.currentState!.context,
              '/chatSeller',
              {'chatId': data['chatId']},
            );
          }
          // if (data['action'] == 'open_invoice') {
          //   print(data['orderId']);
          //   AppUtils.sNavigateToReplace(
          //     navigatorKey.currentState!.context,
          //     '/invoice',
          //     {'orderId': data['orderId'], 'shipId': data['shipId']},
          //   );
          // }
        }
      });
      RemoteMessage? initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        if (initialMessage.notification?.title != '' &&
            initialMessage.notification?.body != '') {
          showNotification(
            initialMessage.notification?.title,
            initialMessage.notification?.body,
          );
          final data = initialMessage.data;
          if (data['action'] == 'open_chat') {
            AppUtils.sNavigateToReplace(
              navigatorKey.currentState!.context,
              '/chatSeller',
              {'chatId': data['chatId']},
            );
          }
          // if (data['action'] == 'open_invoice') {
          //   print(data['orderId']);
          //   AppUtils.sNavigateToReplace(
          //     navigatorKey.currentState!.context,
          //     '/invoice',
          //     {'orderId': data['orderId'], 'shipId': data['shipId']},
          //   );
          // }
        }
      }
    } else {
      print('❌ المستخدم رفض الإشعارات');
    }
  }

  Locale? _locale;

  Locale _mapCustomLocale(String langCode) {
    switch (langCode) {
      case 'eng':
        return const Locale('en');
      case 'arb':
        return const Locale('ar');
      default:
        return const Locale('en');
    }
  }

  Future<void> loadSavedLocale() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? langCode = prefs.getString('Lang');
    if (langCode != null) {
      setState(() {
        _locale = _mapCustomLocale(langCode);
      });
    }
  }

  void changeLanguage(String langCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('Lang', langCode);
    setState(() {
      _locale = _mapCustomLocale(langCode);
    });
  }

  @override
  void initState() {
    initFCM();
    loadSavedLocale();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LocaleProvider>(context);
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Globee',
        locale: provider.locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        localeResolutionCallback: (locale, supportedLocales) {
          // لو مفيش لغة محفوظة، يستخدم لغة الجهاز
          if (_locale != null) return _locale;
          for (var supported in supportedLocales) {
            if (supported.languageCode == locale?.languageCode) {
              return supported;
            }
          }
          return supportedLocales.first;
        },
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: router,
      ),
    );
  }
}
