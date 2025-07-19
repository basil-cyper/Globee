import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:globee/Core/Utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessBlock extends StatefulWidget {
  const AccessBlock({super.key});

  @override
  State<AccessBlock> createState() => _AccessBlockState();
}

class _AccessBlockState extends State<AccessBlock> {
  String lang = "eng";
  List languages = [];

  Future getLang() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();

    setState(() {
      lang = prefx.getString("Lang")!;
      getLangDB();
    });
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

  @override
  void initState() {
    getLang();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return languages.isEmpty
        ? Scaffold(backgroundColor: Colors.redAccent)
        : Scaffold(
            backgroundColor: Colors.redAccent,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.user_remove, size: 100, color: Colors.white),
                  SizedBox(height: 20),
                  Text(
                    languages[153][lang],
                    style: TextStyle(
                      fontSize: 40,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    languages[154][lang],
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ],
              ),
            ),
          );
  }
}
