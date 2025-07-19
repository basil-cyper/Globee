import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:globee/Core/Utils.dart';
import 'package:globee/provider/local_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangeLangScreen extends StatefulWidget {
  const ChangeLangScreen({super.key});

  @override
  State<ChangeLangScreen> createState() => _ChangeLangScreenState();
}

class _ChangeLangScreenState extends State<ChangeLangScreen> {
  String lang = "eng";
  List languages = [];
  String deviceLang = "eng"; // Default fallback

  Future<void> getLang() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    deviceLang = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    String? savedLang = prefs.getString("Lang");

    if (savedLang != null) {
      lang = savedLang;
    } else {
      lang = (deviceLang == "ar") ? "arb" : "eng";
    }

    await getLangDB();
    setState(() {});
  }

  Future<void> getLangDB() async {
    var results = await AppUtils.makeRequests(
      "fetch",
      "SELECT $lang FROM Languages ",
    );
    setState(() {
      languages = results;
    });
  }

  @override
  void initState() {
    getLang();
    super.initState();
  }

  void _setLanguage(String langCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("Lang", langCode);

    Provider.of<LocaleProvider>(context, listen: false).setLocale(langCode);
    context.go('/splash');
  }

  @override
  Widget build(BuildContext context) {
    return languages.isEmpty
        ? const Scaffold()
        : Directionality(
            textDirection: lang == 'arb'
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: Scaffold(
              appBar: AppBar(
                forceMaterialTransparency: true,
                backgroundColor: Colors.transparent,
                title: Text(
                  languages[114][lang],
                  style: const TextStyle(color: Colors.black),
                ),
                centerTitle: true,
                elevation: 0,
              ),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: Image.asset("assets/img/arb.png", width: 30),
                      title: Text(languages[115][lang]),
                      onTap: () => _setLanguage("arb"),
                    ),
                    ListTile(
                      leading: Image.asset("assets/img/eng.png", width: 30),
                      title: Text(languages[116][lang]),
                      onTap: () => _setLanguage("eng"),
                    ),
                  ],
                ),
              ),
            ),
          );
  }
}
