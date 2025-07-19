import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:globee/Core/PushNotificationsService.dart';
import 'package:globee/Core/Theme.dart';
import 'package:globee/Core/Utils.dart';
import 'package:globee/Widgets/Input_Widget.dart';
import 'package:globee/provider/App_Provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

String comex = "";
String comIdx = "0";
void showCommentsBottomSheet(BuildContext context) async {
  TextEditingController commentController = TextEditingController();
  String editingCommentId = "";
  String editingCommentText = "";
  String comType = "original";

  Future<Map<String, dynamic>> fetchInitialData(BuildContext context) async {
    final commentsResponse = await AppUtils.makeRequests(
      "fetch",
      "SELECT Users.Fullname, Users.urlAvatar, Comments.`id`, Comments.`comment`,Comments.`type`,Comments.`parent_id`, Users.uid FROM Users RIGHT JOIN Comments ON Users.uid COLLATE utf8_unicode_ci = Comments.user_id COLLATE utf8_unicode_ci WHERE item_id = '${Provider.of<AppProvider>(context, listen: false).itemId.toString()}' ORDER BY type ASC, id DESC",
    );

    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString("UID") ?? "";
    final comments = commentsResponse is List ? commentsResponse : [];

    return {'comments': comments, 'uid': uid};
  }

  Future<Map<String, dynamic>> fetchLangData() async {
    final prefs = await SharedPreferences.getInstance();
    String lang = prefs.getString("Lang") ?? 'arb';

    var results = await AppUtils.makeRequests(
      "fetch",
      "SELECT $lang FROM Languages ",
    );

    return {'lang': lang, 'results': results};
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return FutureBuilder<Map<String, dynamic>>(
        future: fetchLangData(),
        builder: (context, langSnapshot) {
          if (!langSnapshot.hasData) {
            return SizedBox(
              height: 300,
              child: Center(
                child: SpinKitDoubleBounce(
                  color: AppTheme.primaryColor,
                  size: 30.0,
                ),
              ),
            );
          }

          String lang = langSnapshot.data!['lang'];
          var results = langSnapshot.data!['results'];

          return Directionality(
            textDirection: lang == 'arb'
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: FutureBuilder<Map<String, dynamic>>(
                future: fetchInitialData(context),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return SizedBox(
                      height: 300,
                      child: Center(
                        child: SpinKitDoubleBounce(
                          color: AppTheme.primaryColor,
                          size: 30.0,
                        ),
                      ),
                    );
                  }

                  List commentsList = snapshot.data!['comments'] as List;
                  String uid = snapshot.data!['uid'] as String;

                  return StatefulBuilder(
                    builder: (context, setState) {
                      return Padding(
                        padding: MediaQuery.of(context).viewInsets,
                        child: Container(
                          height: 600,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 5,
                                  margin: EdgeInsets.only(bottom: 20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    results[25][lang],
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                    child: Icon(Iconsax.close_circle),
                                  ),
                                ],
                              ),
                              Divider(),
                              SizedBox(height: 15),
                              Expanded(
                                child: commentsList.isEmpty
                                    ? Provider.of<AppProvider>(
                                                context,
                                              ).commentBool ==
                                              "OFF"
                                          ? Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Iconsax.close_circle,
                                                    size: 90,
                                                    color: Colors.red,
                                                  ),
                                                  SizedBox(height: 20),
                                                  Text(
                                                    results[110][lang],
                                                    style: TextStyle(
                                                      fontSize: 30,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Iconsax.close_circle,
                                                    size: 90,
                                                  ),
                                                  SizedBox(height: 20),
                                                  Text(
                                                    results[47][lang],
                                                    style: TextStyle(
                                                      fontSize: 30,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                    : ListView(
                                        children: commentsList
                                            .where(
                                              (c) => c['type'] == 'original',
                                            )
                                            .map<Widget>((comment) {
                                              final replies = commentsList
                                                  .where(
                                                    (r) =>
                                                        r['type'] ==
                                                            'replied' &&
                                                        r['parent_id']
                                                                .toString() ==
                                                            comment['id']
                                                                .toString(),
                                                  )
                                                  .toList();

                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  buildCommentTile(
                                                    comment,
                                                    currentUserId: uid,
                                                    onReply:
                                                        (type, name, comId) {
                                                          setState(() {
                                                            comType = type;
                                                            comex = name;
                                                            comIdx = comId;
                                                          });
                                                        },
                                                  ),
                                                  ...replies.map(
                                                    (reply) => Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            right: 40.0,
                                                          ),
                                                      child: buildCommentTile(
                                                        reply,
                                                        currentUserId: uid,
                                                        isReply: true,
                                                        onReply:
                                                            (
                                                              type,
                                                              name,
                                                              comId,
                                                            ) {
                                                              setState(() {
                                                                comType = type;
                                                                comex = name;
                                                                comIdx = comId;
                                                              });
                                                            },
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            })
                                            .toList(),
                                      ),
                              ),
                              Visibility(
                                visible:
                                    Provider.of<AppProvider>(
                                      context,
                                    ).commentBool !=
                                    "OFF",
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    comType == 'original'
                                        ? Container()
                                        : Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8.0,
                                            ),
                                            child: Container(
                                              alignment: Alignment.centerRight,
                                              child: Text(
                                                "${results[158][lang]} $comex",
                                              ),
                                            ),
                                          ),
                                    InputWidget(
                                      isRead: uid == '',
                                      icontroller: commentController,
                                      iHint: results[48][lang],
                                      isuffixIcon: Transform.flip(
                                        flipX: true,
                                        child: IconButton(
                                          onPressed: () async {
                                            if (uid == '') {
                                              context.go('/login');
                                              return;
                                            }

                                            if (commentController.text
                                                .trim()
                                                .isEmpty) {
                                              Fluttertoast.showToast(
                                                msg: results[111][lang],
                                                toastLength: Toast.LENGTH_SHORT,
                                                gravity: ToastGravity.TOP,
                                                backgroundColor: Colors.black54,
                                                textColor: Colors.white,
                                                fontSize: 16.0,
                                              );
                                              return;
                                            }

                                            if (editingCommentText.isNotEmpty) {
                                              await AppUtils.makeRequests(
                                                "query",
                                                "UPDATE Comments SET comment = '${commentController.text}' WHERE id = '$editingCommentId'",
                                              );
                                            } else {
                                              SharedPreferences prefx =
                                                  await SharedPreferences.getInstance();
                                              await AppUtils.makeRequests(
                                                "query",
                                                "UPDATE Users SET last_activity = '${DateTime.now()}' WHERE uid = '${prefx.getString("UID")}' ",
                                              );
                                              if (comType == 'replied') {
                                                await AppUtils.makeRequests(
                                                  "query",
                                                  "INSERT INTO Comments VALUES(NULL, '${commentController.text}', '$uid', '${Provider.of<AppProvider>(context, listen: false).itemId}', '${DateTime.now()}', 'replied', '$comIdx')",
                                                );
                                              } else {
                                                await AppUtils.makeRequests(
                                                  "query",
                                                  "INSERT INTO Comments(comment, user_id, item_id, created_at, type) VALUES('${commentController.text}', '$uid', '${Provider.of<AppProvider>(context, listen: false).itemId}', '${DateTime.now()}', 'original')",
                                                );
                                              }
                                              final commentsNow =
                                                  await AppUtils.makeRequests(
                                                    "fetch",
                                                    "SELECT * FROM Users WHERE uid = '$uid'",
                                                  );
                                              final commentsResponse =
                                                  await AppUtils.makeRequests(
                                                    "fetch",
                                                    "SELECT * FROM Items WHERE id = '${Provider.of<AppProvider>(context, listen: false).itemId.toString()}'",
                                                  );
                                              final currentPushUser =
                                                  await AppUtils.makeRequests(
                                                    "fetch",
                                                    "SELECT * FROM Users WHERE uid = '${commentsResponse[0]['uid']}'",
                                                  );
                                              PushNotificationService.sendNotificationToUser(
                                                currentPushUser[0]['fcm_token']
                                                    .toString(),
                                                "${results[121][lang]} ${commentsNow[0]['Fullname']}",
                                                commentController.text.trim(),
                                              );

                                              var requestEmp =
                                                  await AppUtils.makeRequests(
                                                    "fetch",
                                                    "SELECT * FROM employees",
                                                  );
                                              for (var reqx in requestEmp) {
                                                print(reqx['fcm_token']);
                                                PushNotificationService.sendNotificationToUser(
                                                  reqx['fcm_token'].toString(),
                                                  "${results[121][lang]} ${commentsNow[0]['Fullname']}",
                                                  commentController.text.trim(),
                                                );
                                              }
                                              await AppUtils.makeRequests(
                                                "query",
                                                "INSERT INTO Notifications VALUES(NULL, '${results[121][lang]} ${commentsNow[0]['Fullname']}', '${commentController.text.trim()}', '${DateTime.now().toString().split(' ')[0]}', 'false')",
                                              );
                                            }

                                            commentController.clear();

                                            var updatedComments =
                                                await AppUtils.makeRequests(
                                                  "fetch",
                                                  "SELECT Users.Fullname, Users.urlAvatar, Comments.`id`, Comments.`comment` "
                                                      "FROM Users RIGHT JOIN Comments ON Users.uid COLLATE utf8_unicode_ci = Comments.user_id COLLATE utf8_unicode_ci "
                                                      "WHERE item_id = '${Provider.of<AppProvider>(context, listen: false).itemId}'",
                                                );

                                            setState(() {
                                              commentsList =
                                                  updatedComments is List
                                                  ? updatedComments
                                                  : [];
                                              editingCommentText = "";
                                              editingCommentId = "";
                                            });
                                          },
                                          icon: Icon(Iconsax.send_1),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      );
    },
  );
}

Widget buildCommentTile(
  Map comment, {
  required String currentUserId,
  required Function(String comType, String comex, String comId) onReply,
  bool isReply = false,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundImage: comment["urlAvatar"] != null
              ? NetworkImage(
                  "https://pos7d.site/Globee/sys/${comment["urlAvatar"]}",
                )
              : null,
          child: comment["urlAvatar"] == null ? Icon(Icons.person) : null,
        ),
        SizedBox(width: 10),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment["Fullname"] ?? "مستخدم غير معروف",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(comment["comment"], style: TextStyle(fontSize: 13)),
                ],
              ),
              if (!isReply && comment['uid'] != currentUserId)
                GestureDetector(
                  onTap: () async {
                    var currentCommentReply = await AppUtils.makeRequests(
                      "fetch",
                      "SELECT Fullname FROM Users WHERE uid = '${comment['uid']}'",
                    );
                    final name = currentCommentReply[0]['Fullname'];
                    onReply("replied", name, comment['id']);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Icon(Iconsax.undo, size: 18),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}


// final comment = commentsList[index];
//                                           return Column(
//                                             children: [
//                                               comment['type'] != 'original'
//                                                   ? Padding(
//                                                     padding:
//                                                         const EdgeInsets.only(
//                                                           top: 12.0,
//                                                           bottom: 12.0,
//                                                           right: 30,
//                                                         ),
//                                                     child: Row(
//                                                       crossAxisAlignment:
//                                                           CrossAxisAlignment
//                                                               .center,
//                                                       children: [
//                                                         Expanded(
//                                                           child: Row(
//                                                             children: [
//                                                               CircleAvatar(
//                                                                 radius: 20,
//                                                                 backgroundColor:
//                                                                     Colors
//                                                                         .grey[300],
//                                                                 backgroundImage:
//                                                                     comment["urlAvatar"] !=
//                                                                             null
//                                                                         ? NetworkImage(
//                                                                           "https://pos7d.site/Globee/sys/${comment["urlAvatar"]}",
//                                                                         )
//                                                                         : null,
//                                                                 child:
//                                                                     comment["urlAvatar"] ==
//                                                                             null
//                                                                         ? Icon(
//                                                                           Icons
//                                                                               .person,
//                                                                           color:
//                                                                               Colors.grey,
//                                                                         )
//                                                                         : null,
//                                                               ),
//                                                               SizedBox(
//                                                                 width: 10,
//                                                               ),
//                                                               Expanded(
//                                                                 child: Column(
//                                                                   crossAxisAlignment:
//                                                                       CrossAxisAlignment
//                                                                           .start,
//                                                                   children: [
//                                                                     Text(
//                                                                       comment["Fullname"] ??
//                                                                           "مستخدم غير معروف",
//                                                                       style: TextStyle(
//                                                                         fontWeight:
//                                                                             FontWeight.bold,
//                                                                         fontSize:
//                                                                             14,
//                                                                       ),
//                                                                     ),
//                                                                     SizedBox(
//                                                                       height: 4,
//                                                                     ),
//                                                                     Text(
//                                                                       comment["comment"],
//                                                                       style: TextStyle(
//                                                                         fontSize:
//                                                                             13,
//                                                                       ),
//                                                                     ),
//                                                                   ],
//                                                                 ),
//                                                               ),
//                                                             ],
//                                                           ),
//                                                         ),
//                                                         Visibility(
//                                                           visible:
//                                                               uid == comment['uid']
//                                                                   ? true
//                                                                   : false,
//                                                           child: IconButton(
//                                                             onPressed: () async {
//                                                               var result =
//                                                                   await SimpleMoreComment.showItemComments(
//                                                                     context,
//                                                                     comment['id'],
//                                                                   );

//                                                               if (result?['replied'] ==
//                                                                   true) {
//                                                                 var currentCommentReply =
//                                                                     await AppUtils.makeRequests(
//                                                                       "fetch",
//                                                                       "SELECT Fullname FROM Users WHERE uid = '${result['cCommentRepl'][0]['user_id']}'",
//                                                                     );
//                                                                 setState(() {
//                                                                   comType =
//                                                                       'replied';
//                                                                   comex =
//                                                                       currentCommentReply[0]['Fullname'];
//                                                                 });
//                                                               } else if (result !=
//                                                                       null &&
//                                                                   result['deleted'] ==
//                                                                       true) {
//                                                                 var comments = await AppUtils.makeRequests(
//                                                                   "fetch",
//                                                                   "SELECT Users.Fullname, Users.urlAvatar, Comments.`id`, Comments.`comment` "
//                                                                       "FROM Users RIGHT JOIN Comments ON Users.uid COLLATE utf8_unicode_ci = Comments.user_id COLLATE utf8_unicode_ci "
//                                                                       "WHERE item_id = '${Provider.of<AppProvider>(context, listen: false).itemId.toString()}'",
//                                                                 );
//                                                                 setState(() {
//                                                                   commentsList =
//                                                                       comments;
//                                                                 });
//                                                               } else {
//                                                                 setState(() {
//                                                                   editingCommentText =
//                                                                       result['cComment'][0]['comment'];
//                                                                   editingCommentId =
//                                                                       result['cComment'][0]['id'];
//                                                                   commentController
//                                                                           .text =
//                                                                       editingCommentText;
//                                                                 });
//                                                               }
//                                                             },
//                                                             icon: Icon(
//                                                               Iconsax
//                                                                   .more_square,
//                                                             ),
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   )
//                                                   : Padding(
//                                                     padding:
//                                                         const EdgeInsets.symmetric(
//                                                           vertical: 12.0,
//                                                         ),
//                                                     child: Row(
//                                                       crossAxisAlignment:
//                                                           CrossAxisAlignment
//                                                               .center,
//                                                       children: [
//                                                         Expanded(
//                                                           child: Row(
//                                                             children: [
//                                                               CircleAvatar(
//                                                                 radius: 20,
//                                                                 backgroundColor:
//                                                                     Colors
//                                                                         .grey[300],
//                                                                 backgroundImage:
//                                                                     comment["urlAvatar"] !=
//                                                                             null
//                                                                         ? NetworkImage(
//                                                                           "https://pos7d.site/Globee/sys/${comment["urlAvatar"]}",
//                                                                         )
//                                                                         : null,
//                                                                 child:
//                                                                     comment["urlAvatar"] ==
//                                                                             null
//                                                                         ? Icon(
//                                                                           Icons
//                                                                               .person,
//                                                                           color:
//                                                                               Colors.grey,
//                                                                         )
//                                                                         : null,
//                                                               ),
//                                                               SizedBox(
//                                                                 width: 10,
//                                                               ),
//                                                               Expanded(
//                                                                 child: Column(
//                                                                   crossAxisAlignment:
//                                                                       CrossAxisAlignment
//                                                                           .start,
//                                                                   children: [
//                                                                     Text(
//                                                                       comment["Fullname"] ??
//                                                                           "مستخدم غير معروف",
//                                                                       style: TextStyle(
//                                                                         fontWeight:
//                                                                             FontWeight.bold,
//                                                                         fontSize:
//                                                                             14,
//                                                                       ),
//                                                                     ),
//                                                                     SizedBox(
//                                                                       height: 4,
//                                                                     ),
//                                                                     Text(
//                                                                       comment["comment"],
//                                                                       style: TextStyle(
//                                                                         fontSize:
//                                                                             13,
//                                                                       ),
//                                                                     ),
//                                                                   ],
//                                                                 ),
//                                                               ),
//                                                             ],
//                                                           ),
//                                                         ),
//                                                         Visibility(
//                                                           visible:
//                                                               uid == comment['uid']
//                                                                   ? true
//                                                                   : false,
//                                                           child: IconButton(
//                                                             onPressed: () async {
//                                                               var result =
//                                                                   await SimpleMoreComment.showItemComments(
//                                                                     context,
//                                                                     comment['id'],
//                                                                   );
//                                                               if (result !=
//                                                                       null &&
//                                                                   result['deleted'] ==
//                                                                       true) {
//                                                                 var comments = await AppUtils.makeRequests(
//                                                                   "fetch",
//                                                                   "SELECT Users.Fullname, Users.urlAvatar, Comments.`id`, Comments.`comment` "
//                                                                       "FROM Users RIGHT JOIN Comments ON Users.uid COLLATE utf8_unicode_ci = Comments.user_id COLLATE utf8_unicode_ci "
//                                                                       "WHERE item_id = '${Provider.of<AppProvider>(context, listen: false).itemId.toString()}'",
//                                                                 );
//                                                                 setState(() {
//                                                                   commentsList =
//                                                                       comments;
//                                                                 });
//                                                               } else {
//                                                                 setState(() {
//                                                                   editingCommentText =
//                                                                       result['cComment'][0]['comment'];
//                                                                   editingCommentId =
//                                                                       result['cComment'][0]['id'];
//                                                                   commentController
//                                                                           .text =
//                                                                       editingCommentText;
//                                                                 });
//                                                               }
//                                                             },
//                                                             icon: Icon(
//                                                               Iconsax
//                                                                   .more_square,
//                                                             ),
//                                                           ),
//                                                         ),
//                                                         Visibility(
//                                                           visible:
//                                                               comment['uid'] !=
//                                                                       uid
//                                                                   ? true
//                                                                   : false,
//                                                           child: GestureDetector(
//                                                             onTap: () async {
//                                                               var currentCommentReply =
//                                                                   await AppUtils.makeRequests(
//                                                                     "fetch",
//                                                                     "SELECT Fullname FROM Users WHERE uid = '${comment['uid']}'",
//                                                                   );
//                                                               setState(() {
//                                                                 comType =
//                                                                     'replied';
//                                                                 comex =
//                                                                     currentCommentReply[0]['Fullname'];
//                                                               });
//                                                             },
//                                                             child: Icon(
//                                                               Iconsax.undo,
//                                                             ),
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   ),
//                                             ],
//                                           );