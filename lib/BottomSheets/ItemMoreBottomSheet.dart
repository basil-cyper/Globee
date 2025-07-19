import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:globee/BottomSheets/ItemDetailsBottomSheet.dart';
import 'package:globee/BottomSheets/ReportsBottomSheet.dart';
import 'package:globee/Core/Theme.dart';
import 'package:globee/Core/Utils.dart';
import 'package:globee/provider/App_Provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class moreBottomSheet extends StatefulWidget {
  const moreBottomSheet({super.key});

  @override
  State<moreBottomSheet> createState() => moreBottomSheetState();
}

class moreBottomSheetState extends State<moreBottomSheet> {
  late Future<Map<String, dynamic>> futureData;
  String userStx = '';

  @override
  void initState() {
    super.initState();
    getLang();
    futureData = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString("UID");
    final oid = prefs.getString("OID");

    final results = await AppUtils.makeRequests(
      "fetch",
      "SELECT uid FROM Items WHERE uid = '$uid' AND status = '1'",
    );

    final ordersResult = await AppUtils.makeRequests(
      "fetch",
      "SELECT cust_id FROM Orders WHERE cust_id = '$uid'",
    );
    final usersStatus = await AppUtils.makeRequests(
      "fetch",
      "SELECT status FROM Users WHERE uid = '${prefs.getString("UID")}'",
    );
    setState(() {
      userStx = usersStatus[0]['status'];
    });
    return {
      'UID': uid,
      'OID': oid,
      'hasItems': results[0],
      'hasOrders': ordersResult[0],
    };
  }

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

  List<dynamic> blockedList = [];

  Future<List<Map<String, dynamic>>> getBlockedUsers(
    String myUid,
    String itemUser,
  ) async {
    var results = await AppUtils.makeRequests(
      "fetch",
      "SELECT blocked_user_id FROM blocks WHERE user_id = '$myUid' AND blocked_user_id = '$itemUser'",
    );
    return List<Map<String, dynamic>>.from(results);
  }

  Future<void> fetchBlockedUsers(itemUser) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? myUid = prefs.getString("UID");

    if (myUid != null) {
      blockedList = await getBlockedUsers(myUid, itemUser);
      setState(() {});
    }
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
        child: FutureBuilder<Map<String, dynamic>>(
          future: futureData,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: SpinKitDoubleBounce(
                  color: AppTheme.primaryColor,
                  size: 30.0,
                ),
              );
            }

            final data = snapshot.data!;
            final uid = data['UID'];
            final oid = data['OID'];
            final hasItems = data['hasItems'];
            final hasOrders = data['hasOrders'];
            final itemUser = Provider.of<AppProvider>(
              context,
              listen: false,
            ).currentUser;

            fetchBlockedUsers(itemUser);
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (uid != null)
                    Visibility(
                      visible: userStx == '0' ? false : true,
                      child: ListTile(
                        leading: const Icon(Iconsax.user_octagon),
                        title: Text(languages[30][lang]),
                        onTap: () async {
                          SharedPreferences prefx =
                              await SharedPreferences.getInstance();
                          await AppUtils.makeRequests(
                            "query",
                            "UPDATE Users SET last_activity = '${DateTime.now()}' WHERE uid = '${prefx.getString("UID")}' ",
                          );
                          AppUtils.sNavigateToReplace(context, '/UserProfile', {
                            'userId': uid,
                          });
                        },
                      ),
                    ),
                  // طلبات العملاء: لما يكون مسجل وعنده أصناف
                  if (uid != null && hasItems != null)
                    ListTile(
                      leading: const Icon(Iconsax.task_square),
                      title: Text(languages[31][lang]),
                      onTap: () async {
                        SharedPreferences prefx =
                            await SharedPreferences.getInstance();
                        await AppUtils.makeRequests(
                          "query",
                          "UPDATE Users SET last_activity = '${DateTime.now()}' WHERE uid = '${prefx.getString("UID")}' ",
                        );
                        context.go('/customersOrders');
                      },
                    ),

                  // طلباتي: لما يكون مسجل وعنده طلبات
                  if (uid != null && hasOrders != null)
                    ListTile(
                      leading: const Icon(Iconsax.receipt),
                      title: Text(languages[32][lang]),
                      onTap: () async {
                        SharedPreferences prefx =
                            await SharedPreferences.getInstance();
                        await AppUtils.makeRequests(
                          "query",
                          "UPDATE Users SET last_activity = '${DateTime.now()}' WHERE uid = '${prefx.getString("UID")}' ",
                        );
                        AppUtils.sNavigateToReplace(
                          context,
                          '/customersOrders',
                          {'custId': uid},
                        );
                      },
                    ),

                  if (uid != null && oid != null)
                    Visibility(
                      visible: userStx == '0' ? false : true,
                      child: ListTile(
                        leading: const Icon(Iconsax.shopping_cart),
                        title: Text(languages[33][lang]),
                        onTap: () async {
                          SharedPreferences prefx =
                              await SharedPreferences.getInstance();
                          await AppUtils.makeRequests(
                            "query",
                            "UPDATE Users SET last_activity = '${DateTime.now()}' WHERE uid = '${prefx.getString("UID")}' ",
                          );
                          context.go('/cart');
                        },
                      ),
                    ),
                  ListTile(
                    leading: const Icon(Iconsax.note),
                    title: Text(languages[34][lang]),
                    onTap: () async {
                      if (Provider.of<AppProvider>(
                            context,
                            listen: false,
                          ).itemId !=
                          0) {
                        SharedPreferences prefx =
                            await SharedPreferences.getInstance();
                        await AppUtils.makeRequests(
                          "query",
                          "UPDATE Users SET last_activity = '${DateTime.now()}' WHERE uid = '${prefx.getString("UID")}' ",
                        );
                        showItemDetailsBottomSheet(
                          context,
                          itemId: Provider.of<AppProvider>(
                            context,
                            listen: false,
                          ).itemId.toString(),
                        );
                      }
                    },
                  ),
                  Visibility(
                    visible: userStx == '0' ? false : true,
                    child: ListTile(
                      leading: const Icon(Iconsax.flag),
                      title: Text(languages[127][lang]),
                      onTap: () async {
                        SharedPreferences prefx =
                            await SharedPreferences.getInstance();
                        await AppUtils.makeRequests(
                          "query",
                          "UPDATE Users SET last_activity = '${DateTime.now()}' WHERE uid = '${prefx.getString("UID")}' ",
                        );
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => reportsBottomSheet(),
                        );
                      },
                    ),
                  ),
                  Visibility(
                    visible: uid != itemUser ? true : false,
                    child: ListTile(
                      leading: const Icon(Iconsax.forbidden),
                      // title: Text(),
                      title: Text(
                        blockedList.isEmpty
                            ? languages[167][lang]
                            : languages[168][lang],
                      ),
                      onTap: () async {
                        var request = await AppUtils.makeRequests(
                          "fetch",
                          "SELECT * FROM blocks WHERE blocked_user_id = '$itemUser' AND user_id = '$uid' ",
                        );
                        if (request[0] != null) {
                          await AppUtils.makeRequests(
                            "query",
                            "DELETE FROM blocks WHERE blocked_user_id = '$itemUser' AND user_id = '$uid' ",
                          );
                          await AppUtils.makeRequests(
                            "query",
                            "UPDATE Items SET status = '1' WHERE uid = '$itemUser' ",
                          );
                        } else {
                          await AppUtils.makeRequests(
                            "query",
                            "INSERT INTO blocks VALUES (NULL, '$itemUser', '$uid', '${DateTime.now()}')",
                          );
                          await AppUtils.makeRequests(
                            "query",
                            "UPDATE Items SET status = '4' WHERE uid = '$itemUser' ",
                          );
                        }

                        Navigator.pop(context);
                        context.go('/splash');
                      },
                    ),
                  ),
                  if (uid != null)
                    ListTile(
                      leading: const Icon(Iconsax.logout),
                      title: Text(languages[35][lang]),
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await AppUtils.makeRequests(
                          "query",
                          "UPDATE Users SET last_activity = '${DateTime.now()}' WHERE uid = '${prefs.getString("UID")}' ",
                        );
                        prefs.remove("UID");
                        context.go('/splash');
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
