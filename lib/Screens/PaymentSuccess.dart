import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:globee/BottomSheets/ChatSellersBottomSheet.dart';
import 'package:globee/Core/Utils.dart';
import 'package:globee/Routes/App_Router.dart';
import 'package:globee/Screens/ChatScreen.dart';
import 'package:globee/Widgets/Button_Widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentSuccess extends StatefulWidget {
  const PaymentSuccess({super.key});

  @override
  State<PaymentSuccess> createState() => _PaymentSuccessState();
}

class _PaymentSuccessState extends State<PaymentSuccess> {
  String lang = "eng";
  List languages = [];

  Future getLang() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();

    setState(() {
      lang = prefx.getString("Lang") ?? "eng";
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

  Future renewOID() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    int oid = 1000 + Random().nextInt(9999);
    setState(() {
      prefx.setString("OID", oid.toString());
    });
    await AppUtils.makeRequests(
      "query",
      "UPDATE Users SET oid = '${prefx.getString("OID")}' WHERE uid = '${prefx.getString("UID")}' ",
    );
  }

  @override
  void initState() {
    getLang();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (languages.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: Text("${languages[77][lang]}"),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.tick_circle, color: Colors.green, size: 100),
            const SizedBox(height: 20),
            Text("${languages[77][lang]}", style: TextStyle(fontSize: 24)),
            const SizedBox(height: 10),
            Text("${languages[78][lang]}"),
            const SizedBox(height: 10),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            renewOID();
                            context.go('/home');
                          },
                          child: ButtonWidget(
                            btnText: "${languages[79][lang]}",
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            SharedPreferences prefx =
                                await SharedPreferences.getInstance();
                            AppUtils.sNavigateToReplace(
                              navigatorKey.currentState!.context,
                              '/invoice',
                              {
                                'orderId': prefx.getString("OID").toString(),
                                'payment': 'Customer',
                              },
                            );
                          },
                          child: ButtonWidget(
                            btnText: "${languages[80][lang]}",
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      SharedPreferences prefx =
                          await SharedPreferences.getInstance();

                      final oid = prefx.getString("OID");

                      final seller_id = await AppUtils.makeRequests(
                        "fetch",
                        "SELECT uid FROM Orders WHERE oid = '$oid'",
                      );

                      showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return chatSellersBottomSheet(seller_ids: seller_id);
                        },
                      );
                    },

                    child: ButtonWidget(btnText: "${languages[159][lang]}"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
