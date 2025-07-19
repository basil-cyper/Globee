import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:globee/Core/PushNotificationsServiceChats.dart';
import 'package:globee/Core/Utils.dart';
import 'package:globee/Widgets/Input_Widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatScreen extends StatefulWidget {
  final String? chatId;
  const ChatScreen({super.key, this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController msgController = TextEditingController();
  List sellerDet = [];
  List messages = [];
  String uid = "";
  String fcmToken = "";
  Timer? _statusTimer;
  Timer? _messagesTimer;
  bool isTyping = false;

  Future getChatDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String myUid = prefs.getString("UID")!;
    String chatId = widget.chatId!;

    var result = await AppUtils.makeRequests("fetch", """
      SELECT 
        chats.user_id,
        chats.seller_id,
        IF(chats.user_id = '$myUid', seller.fullname, buyer.fullname) AS other_name,
        IF(chats.user_id = '$myUid', seller.urlAvatar, buyer.urlAvatar) AS other_avatar,
        IF(chats.user_id = '$myUid', seller.last_activity, buyer.last_activity) AS other_last_activity,
        IF(chats.user_id = '$myUid', seller.fcm_token, buyer.fcm_token) AS other_fcm_token
      FROM chats
      JOIN Users AS buyer ON buyer.uid = chats.user_id
      JOIN Users AS seller ON seller.uid = chats.seller_id
      WHERE chats.id = '$chatId'
    """);

    final other = result[0];
    DateTime lastSeen = DateTime.parse(other['other_last_activity']).toUtc();
    bool onlineStatus =
        DateTime.now().toUtc().difference(lastSeen).inSeconds < 120;

    setState(() {
      sellerDet = [
        {
          'name': other['other_name'],
          'avatar': other['other_avatar'],
          'lastSeen': lastSeen,
          'isOnline': onlineStatus,
        },
      ];
      fcmToken = other['other_fcm_token'];
    });
  }

  Future getMessages() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    var result = await AppUtils.makeRequests(
      "fetch",
      "SELECT * FROM messages WHERE chat_id = '${widget.chatId}' ",
    );

    setState(() {
      messages = result;
      uid = prefx.getString("UID")!;
    });
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

  void startTypingStatus() {
    AppUtils.makeRequests(
      "query",
      "UPDATE Users SET is_typing = '1' WHERE uid = '$uid'",
    );
    Future.delayed(Duration(seconds: 3), () {
      AppUtils.makeRequests(
        "query",
        "UPDATE Users SET is_typing = '0' WHERE uid = '$uid'",
      );
    });
  }

  void setupStatusTimer() {
    _statusTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      getChatDetails();
    });

    _messagesTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      getMessages();
    });
  }

  @override
  void initState() {
    getChatDetails();
    getLang();
    getMessages();
    setupStatusTimer();
    super.initState();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _messagesTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          forceMaterialTransparency: true,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () {
              context.go('/paymentSuccess');
            },
            icon: Icon(Iconsax.arrow_right),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(
                      "https://www.pos7d.site/Globee/sys/${sellerDet[0]['avatar']}",
                    ),
                  ),
                  SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sellerDet[0]['name'],
                        style: TextStyle(color: Colors.black),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 10,
                            color: sellerDet[0]['isOnline']
                                ? Colors.green
                                : Colors.grey,
                          ),
                          SizedBox(width: 5),
                          Text(
                            sellerDet[0]['isOnline']
                                ? 'متصل الآن'
                                : 'آخر ظهور: ${timeago.format(sellerDet[0]['lastSeen'].toLocal())}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                reverse: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(messages.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        children: [
                          Align(
                            alignment: messages[i]['sender_id'] == uid
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(messages[i]['message']),
                            ),
                          ),
                          SizedBox(height: 5),
                          Align(
                            alignment: messages[i]['sender_id'] == uid
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Text(
                              messages[i]['sent_at']
                                  .toString()
                                  .split(" ")[1]
                                  .split('.')[0],
                            ),
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),

            Container(
              padding: EdgeInsets.all(8),
              width: double.infinity,
              child: InputWidget(
                icontroller: msgController,
                iHint: languages.isNotEmpty
                    ? languages[160][lang]
                    : "اكتب رسالة...",
                ichanged: (_) => startTypingStatus(),
                isuffixIcon: Transform.flip(
                  flipX: true,
                  child: IconButton(
                    onPressed: () async {
                      SharedPreferences prefx =
                          await SharedPreferences.getInstance();
                      await AppUtils.makeRequests(
                        "query",
                        "INSERT INTO messages VALUES(NULL, '${widget.chatId}', '${prefx.getString("UID")}', 'text', '${msgController.text}', '${DateTime.now()}', 'false')",
                      );
                      await AppUtils.makeRequests(
                        "query",
                        "UPDATE chats SET last_message_at = '${DateTime.now()}' WHERE id = '${widget.chatId}' ",
                      );

                      var userx = await AppUtils.makeRequests(
                        "fetch",
                        "SELECT Fullname FROM Users WHERE uid = '${prefx.getString("UID")}' ",
                      );

                      PushNotificationServiceChats.sendNotificationToUser(
                        fcmToken,
                        "New Message From ${userx[0]['Fullname']}",
                        msgController.text.trim(),
                        widget.chatId ?? "",
                      );
                      setState(() {
                        msgController.clear();
                      });
                      getMessages();
                    },
                    icon: Icon(Iconsax.send_1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
