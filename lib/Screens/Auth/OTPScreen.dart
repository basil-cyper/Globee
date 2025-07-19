import 'dart:math';

import 'package:globee/Core/Utils.dart';
import 'package:globee/Widgets/Back_Button.dart';
import 'package:globee/Widgets/Button_Widget.dart';
import 'package:globee/Widgets/OTP_Widget.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OTPScreen extends StatefulWidget {
  final String? mobile;
  final int? otp;
  const OTPScreen({super.key, this.mobile, this.otp});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController otpController = TextEditingController();
  bool isValid = false;
  String lang = "eng";
  List languages = [];

  Future<void> getSMS() async {
    try {
      final response = await Dio().get(
        "https://connectsms.vodafone.com.qa/SMSConnect/SendServlet?application=http_gw1597&password=my3jjtap&content=${widget.otp} is Your Verification Code. Don't Share it with anyone&destination=974${widget.mobile}&source=97668&mask=GoldenEagle",
      );
      if (response.statusCode == 200) {
        print("SMS sent successfully");
      } else {
        print("Failed to send SMS: ${response.statusCode}");
      }
    } catch (e) {
      print("Error sending SMS: $e");
    }
  }

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
    // getSMS();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print(widget.otp);
    return Directionality(
      textDirection: lang == 'arb' ? TextDirection.rtl : TextDirection.ltr,
      child: languages.isEmpty
          ? Scaffold()
          : Scaffold(
              backgroundColor: Colors.white,
              body: Stack(
                children: [
                  SingleChildScrollView(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 50,
                          horizontal: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 40),
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.asset(
                                  "assets/img/Logo.png",
                                  width: MediaQuery.sizeOf(context).width / 2.8,
                                ),
                              ),
                            ),
                            SizedBox(height: 30),
                            Text(
                              languages[4][lang] ?? "",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 20),
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: OtpWidget(
                                otpController: otpController,
                                otpChanged: (val) {
                                  setState(() {
                                    isValid = val.length == 6;
                                  });
                                },
                              ),
                            ),
                            SizedBox(height: 20),
                            SizedBox(
                              height: 50,
                              child: GestureDetector(
                                onTap: () async {
                                  SharedPreferences prefx =
                                      await SharedPreferences.getInstance();
                                  var users = await AppUtils.makeRequests(
                                    "fetch",
                                    "SELECT uid, oid FROM Users WHERE PhoneNumber = '${widget.mobile}'",
                                  );

                                  if (widget.mobile != '00000000') {
                                    if (otpController.text ==
                                        widget.otp.toString()) {
                                      if (users[0] != null) {
                                        await prefx.setString(
                                          'UID',
                                          users[0]['uid'],
                                        );
                                        await prefx.setString(
                                          'OID',
                                          users[0]['oid'],
                                        );
                                        context.go("/splash");
                                      } else {
                                        AppUtils.sNavigateToReplace(
                                          context,
                                          '/createUser',
                                          {'phonenumber': widget.mobile!},
                                        );
                                      }
                                    } else {
                                      AppUtils.snackBarShowing(
                                        context,
                                        languages[108][lang] ?? "",
                                      );
                                    }
                                  } else {
                                    await prefx.setString(
                                      'UID',
                                      users[0]['uid'],
                                    );
                                    await prefx.setString(
                                      'OID',
                                      users[0]['oid'],
                                    );
                                    context.go("/splash");
                                  }
                                },
                                child: ButtonWidget(
                                  isDisabled: true,
                                  btnText: languages[5][lang] ?? "",
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Center(child: Text(widget.otp.toString())),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    left: lang == 'eng' ? 20 : null,
                    right: lang == 'arb' ? 20 : null,
                    child: InkWell(
                      onTap: () {
                        context.go('/login');
                      },
                      child: RectButtonWidget(
                        bicon: lang == 'arb'
                            ? Iconsax.arrow_circle_right
                            : Iconsax.arrow_circle_left,
                        bsize: 35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
