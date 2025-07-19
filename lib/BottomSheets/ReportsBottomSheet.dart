import 'package:flutter/material.dart';
import 'package:globee/Core/PushNotificationsService.dart';
import 'package:globee/Core/Utils.dart';
import 'package:globee/provider/App_Provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class reportsBottomSheet extends StatefulWidget {
  const reportsBottomSheet({super.key});

  @override
  State<reportsBottomSheet> createState() => _reportsBottomSheetState();
}

class _reportsBottomSheetState extends State<reportsBottomSheet> {
  String lang = "eng";
  List languages = [];
  String? selectedValue;

  @override
  void initState() {
    super.initState();
    getLang();
  }

  Future getLang() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    lang = prefx.getString("Lang") ?? "eng";
    await getLangDB();
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
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: lang == 'arb' ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(16),
        child: languages.length >= 149
            ? SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(21, (i) {
                    String value = languages[i + 128][lang];
                    return RadioListTile<String>(
                      value: value,
                      groupValue: selectedValue,
                      title: Text(value),
                      onChanged: (val) async {
                        setState(() {
                          selectedValue = val!;
                          print("Selected Report: $selectedValue");
                        });
                        SharedPreferences prefx =
                            await SharedPreferences.getInstance();
                        await AppUtils.makeRequests(
                          "query",
                          "INSERT INTO Flags VALUES(NULL, '${Provider.of<AppProvider>(context, listen: false).itemId}', '${prefx.getString("UID")}', '$selectedValue', '${DateTime.now()}', '0')",
                        );

                        var requestEmp = await AppUtils.makeRequests(
                          "fetch",
                          "SELECT * FROM employees",
                        );
                        if (requestEmp[0] != null) {
                          for (var reqx in requestEmp) {
                            PushNotificationService.sendNotificationToUser(
                              reqx['fcm_token'].toString(),
                              "${languages[155][lang]}",
                              "${languages[156][lang]} $selectedValue",
                            );
                          }
                        }

                        Navigator.pop(context);
                      },
                    );
                  }),
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
