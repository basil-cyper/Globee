import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:globee/Core/Utils.dart';
import 'package:globee/Routes/App_Router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class chatSellersBottomSheet extends StatefulWidget {
  final List seller_ids;
  const chatSellersBottomSheet({super.key, required this.seller_ids});

  @override
  State<chatSellersBottomSheet> createState() => chatSellersBottomSheetState();
}

class chatSellersBottomSheetState extends State<chatSellersBottomSheet> {
  String lang = "eng";
  List sellers = [];
  Future getLang() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();

    List tempSellers = [];

    for (var i = 0; i < widget.seller_ids.length; i++) {
      var result = await AppUtils.makeRequests(
        "fetch",
        "SELECT Fullname, urlAvatar FROM Users WHERE uid = '${widget.seller_ids[i]['uid']}' GROUP BY uid ",
      );
      if (result.isNotEmpty) {
        tempSellers.add(result[0]); // نضيف أول نتيجة فقط
      }
    }

    setState(() {
      lang = prefx.getString("Lang")!;
      sellers = tempSellers;
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
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Choose Your Seller"),
            ...List.generate(sellers.length, (i) {
              return ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 0),
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                    "https://www.pos7d.site/Globee/sys/${sellers[i]['urlAvatar']}",
                  ),
                ),
                title: Text(sellers[i]['Fullname']),
                onTap: () async {
                  SharedPreferences prefx =
                      await SharedPreferences.getInstance();
                  final oid = prefx.getString("OID");
                  final uid = prefx.getString("UID");
                  // 1. إدخال الشات
                  await AppUtils.makeRequests(
                    "query",
                    "INSERT INTO chats VALUES(NULL, '$oid', '$uid', '${widget.seller_ids[i]['uid']}', '${DateTime.now()}', NULL)",
                  );

                  // 2. الحصول على chat_id
                  final result = await AppUtils.makeRequests(
                    "fetch",
                    "SELECT id FROM chats WHERE user_id = '$uid' AND order_id = '$oid' ORDER BY id DESC LIMIT 1",
                  );

                  final chatId = result[0]['id'];
                  print(chatId);

                  // 3. التوجيه إلى صفحة الدردشة
                  AppUtils.sNavigateToReplace(
                    navigatorKey.currentState!.context,
                    '/chatSeller',
                    {'chatId': chatId},
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
