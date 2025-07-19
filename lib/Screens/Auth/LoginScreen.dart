import 'dart:math';
import 'package:globee/Core/Utils.dart';
import 'package:globee/Routes/App_Router.dart';
import 'package:globee/Widgets/Back_Button.dart';
import 'package:globee/Widgets/Button_Widget.dart';
import 'package:globee/Widgets/Input_Widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController mobileController = TextEditingController();
  bool isValid = false;
  int otp = 0;
  String lang = "eng";
  List languages = [];
  int isActive = 0;
  bool agreement = false;

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
    return Directionality(
      textDirection: lang == 'arb' ? TextDirection.rtl : TextDirection.ltr,
      child: languages.isEmpty
          ? Scaffold()
          : GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: Scaffold(
                backgroundColor: Colors.white,
                body: SingleChildScrollView(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 50,
                        horizontal: 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              context.go('/home');
                            },
                            child: RectButtonWidget(
                              bicon: lang == 'arb'
                                  ? Iconsax.arrow_circle_right
                                  : Iconsax.arrow_circle_left,
                            ),
                          ),
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
                            languages[1][lang] ?? "",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 20),
                          InputWidget(
                            iMaxLength: 8,
                            ikeyboardType: TextInputType.number,
                            icontroller: mobileController,
                            iHint: languages[2][lang] ?? "",
                            ichanged: (val) {
                              setState(() {
                                isValid = val.length == 8;
                              });
                            },
                            isuffixIcon: Icon(
                              isValid
                                  ? Iconsax.tick_circle
                                  : Iconsax.close_circle,
                              color: isValid ? Colors.green : Colors.red,
                            ),
                          ),
                          Container(
                            alignment: lang == 'arb'
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: agreement,
                                  onChanged: (value) {
                                    setState(() {
                                      agreement = value!;
                                      print(agreement);
                                      isActive = 0;
                                    });
                                  },
                                ),
                                Expanded(
                                  child: Wrap(
                                    children: [
                                      Text(languages[161][lang]),
                                      GestureDetector(
                                        onTap: () {
                                          AppUtils.sNavigateToReplace(
                                            navigatorKey.currentState!.context,
                                            '/privacyterms',
                                            {'termsPage': 'Terms'},
                                          );
                                        },
                                        child: Text(
                                          languages[162][lang],
                                          style: TextStyle(color: Colors.blue),
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      Text("${languages[163][lang]} "),
                                      GestureDetector(
                                        onTap: () {
                                          AppUtils.sNavigateToReplace(
                                            navigatorKey.currentState!.context,
                                            '/privacyterms',
                                            {'termsPage': 'PrivacyPolicy'},
                                          );
                                        },
                                        child: Text(
                                          languages[164][lang],
                                          style: TextStyle(color: Colors.blue),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          SizedBox(
                            height: 50,
                            child: GestureDetector(
                              onTap: () async {
                                if (agreement == true) {
                                  if (isValid) {
                                    int otp = 100000 + Random().nextInt(900000);
                                    AppUtils.sNavigateToReplace(
                                      context,
                                      '/otp',
                                      {
                                        'mobile': mobileController.text,
                                        'otp': otp.toString(),
                                      },
                                    );
                                  } else {
                                    AppUtils.snackBarShowing(
                                      context,
                                      languages[107][lang] ?? "",
                                    );
                                  }
                                } else {
                                  AppUtils.snackBarShowing(
                                    context,
                                    languages[165][lang],
                                  );
                                }
                              },
                              child: ButtonWidget(
                                isDisabled: isValid,
                                btnText: languages[3][lang] ?? "",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
