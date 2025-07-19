import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:globee/Widgets/Button_Widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:globee/BottomSheets/UserMoreBottomSheet.dart';
import 'package:globee/Core/Theme.dart';
import 'package:globee/Core/Utils.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:globee/provider/App_Provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_compress/video_compress.dart';

class UserProfile extends StatefulWidget {
  final String userId;
  const UserProfile({super.key, required this.userId});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  List allMerchantItems = [];
  List merchantItems = [];
  List merchantUsers = [];
  List languages = [];
  int currentIndex = 0;
  String lang = "eng";
  Map<String, Future<String?>> thumbnailFutures = {};

  String totalItems = "";
  String ordered = "";
  String uid = '';

  Future getLang() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();

    setState(() {
      lang = prefx.getString("Lang")!;
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

  Future getMerchantItems() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    var merchantItemsAll = await AppUtils.makeRequests(
      "fetch",
      "SELECT Users.Fullname, Users.urlAvatar, Items.`id`,Items.`name`,Items.`price`, Items.media, Items.created_at, Items.Views, Items.uid, Items.status FROM Users LEFT JOIN Items ON Users.uid = Items.uid WHERE Items.uid = '${widget.userId}' ORDER BY Items.created_at DESC ",
    );
    setState(() {
      allMerchantItems = merchantItemsAll;
      merchantItems = List.from(allMerchantItems);
      uid = prefx.getString("UID")!;
    });
  }

  Future getMerchant() async {
    var merchantUser = await AppUtils.makeRequests(
      "fetch",
      "SELECT Fullname, urlAvatar, uid FROM Users WHERE uid = '${widget.userId}' ",
    );
    setState(() {
      merchantUsers = merchantUser;
    });
  }

  Future getCountItenswithUser() async {
    var countItems = await AppUtils.makeRequests(
      "fetch",
      "SELECT COUNT(Items.id) as count_items FROM Users LEFT JOIN Items ON Users.uid = Items.uid WHERE Items.uid = '${widget.userId}' AND Items.status = '1'",
    );
    setState(() {
      totalItems = countItems[0]['count_items'];
    });
  }

  void orderData(String orderx) {
    setState(() {
      switch (orderx) {
        case "Latest":
          merchantItems.sort(
            (a, b) => DateTime.parse(
              b['created_at'],
            ).compareTo(DateTime.parse(a['created_at'])),
          );
          break;
        case "Popular":
          merchantItems.sort(
            (a, b) => int.parse(
              b['Views'].toString(),
            ).compareTo(int.parse(a['Views'].toString())),
          );
          break;
        case "Oldest":
          merchantItems.sort(
            (a, b) => DateTime.parse(
              a['created_at'],
            ).compareTo(DateTime.parse(b['created_at'])),
          );
          break;
      }
    });
  }

  Future<String?> generateSmartThumbnail(String videoUrl, String id) async {
    try {
      // الحصول على مسار مؤقت للتخزين
      final tempDir = await getTemporaryDirectory();
      final thumbnailPath = '${tempDir.path}/thumb_$id.jpg';
      final videoPath = '${tempDir.path}/temp_video_$id.mp4';

      // لو الصورة موجودة بالفعل، ارجع المسار فورًا
      if (await File(thumbnailPath).exists()) {
        print('🟢 thumbnail already exists: $thumbnailPath');
        return thumbnailPath;
      }

      // تحميل الفيديو مؤقتًا
      final dio = Dio();
      final response = await dio.download(
        videoUrl,
        videoPath,
        options: Options(
          responseType: ResponseType.bytes,
          // timeout: Duration(seconds: 15), // ممكن تضيف تايم اوت لو عايز
        ),
      );

      if (response.statusCode != 200) {
        print("❌ فشل تحميل الفيديو");
        return null;
      }

      // توليد صورة مصغرة من الفيديو المحمل
      final thumbnailFile = await VideoCompress.getFileThumbnail(
        videoPath,
        quality: 75,
        position: -1,
      );

      if (thumbnailFile == null || thumbnailFile.path.isEmpty) {
        print("❌ لم يتم توليد الصورة المصغرة");
        return null;
      }

      // نسخ الصورة إلى المسار الثابت
      final savedThumb = await File(thumbnailFile.path).copy(thumbnailPath);
      print("✅ thumbnail saved: ${savedThumb.path}");

      // حذف الفيديو المؤقت بعد التوليد (اختياري)
      final tempVideoFile = File(videoPath);
      if (await tempVideoFile.exists()) {
        await tempVideoFile.delete();
      }

      return savedThumb.path;
    } catch (e) {
      print("❌ خطأ أثناء توليد الصورة: $e");
      return null;
    }
  }

  Future deleteAccount() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    await AppUtils.makeRequests(
      "query",
      "DELETE FROM Users WHERE uid = '${prefx.getString("UID")}' ",
    );
    await AppUtils.makeRequests(
      "query",
      "DELETE FROM Items WHERE uid = '${prefx.getString("UID")}' ",
    );
    prefx.remove("UID");
    context.go('/splash');
  }

  @override
  void initState() {
    getLang();
    getMerchantItems();
    getCountItenswithUser();
    getMerchant();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    getLangDB();
    print(uid);
    print(merchantUsers[0]['uid']);
    return Directionality(
      textDirection: lang == 'arb' ? TextDirection.rtl : TextDirection.ltr,
      child: languages.isEmpty
          ? Scaffold()
          : Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                leading: IconButton(
                  onPressed: () {
                    context.go('/home');
                  },
                  icon: Icon(
                    lang == 'arb'
                        ? Iconsax.arrow_circle_right
                        : Iconsax.arrow_circle_left,
                  ),
                ),
                forceMaterialTransparency: true,
                backgroundColor: Colors.transparent,
                title: Text(
                  languages[36][lang] ?? "",
                  style: TextStyle(color: Colors.black),
                ),
                centerTitle: true,
                elevation: 0,
                actions: [
                  merchantUsers[0]['uid'] != uid
                      ? Container()
                      : GestureDetector(
                          onTap: () async {
                            SharedPreferences prefx =
                                await SharedPreferences.getInstance();
                            if (prefx.getString("Lang") == 'arb') {
                              prefx.setString("Lang", "eng");
                            } else {
                              prefx.setString("Lang", "arb");
                            }
                            getLang();
                            Provider.of<AppProvider>(
                              context,
                              listen: false,
                            ).setLang(lang);
                            setState(() {});
                          },
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 10),
                            child: Image.asset(
                              "assets/img/$lang.png",
                              width: 30,
                            ),
                          ),
                        ),
                ],
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    Container(
                      height: 170,
                      padding: EdgeInsets.symmetric(horizontal: 30),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(
                              merchantUsers.isNotEmpty
                                  ? "https://pos7d.site/Globee/sys/${merchantUsers[0]['urlAvatar']}"
                                  : "",
                            ),
                          ),
                          SizedBox(width: 20),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 180,
                                child: Text(
                                  "${merchantUsers.isNotEmpty ? merchantUsers[0]['Fullname'] : ""}",
                                  style: TextStyle(fontSize: 27),
                                ),
                              ),
                              Text(
                                "$totalItems ${int.parse(totalItems) > 2 && int.parse(totalItems) < 11 ? languages[112][lang] ?? "" : languages[113][lang] ?? ""}",
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Visibility(
                      visible: merchantItems.isEmpty && allMerchantItems.isEmpty
                          ? false
                          : true,
                      child: Row(
                        children: [
                          SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              orderData("Latest");
                              setState(() {
                                currentIndex = 0;
                              });
                            },
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                chipTheme:
                                    ChipThemeData.fromDefaults(
                                      secondaryColor: Colors.grey.shade100,
                                      brightness: Brightness.light,
                                      labelStyle: TextStyle(),
                                    ).copyWith(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      side: BorderSide.none,
                                    ),
                              ),
                              child: Chip(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 11,
                                ),
                                backgroundColor: currentIndex == 0
                                    ? Colors.black
                                    : Colors.grey.shade100,
                                label: Text(
                                  languages[37][lang] ?? "",
                                  style: TextStyle(
                                    color: currentIndex == 0
                                        ? Colors.white
                                        : Colors.black,
                                    fontFamily:
                                        GoogleFonts.tajawal().fontFamily,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              orderData("Popular");
                              setState(() {
                                currentIndex = 1;
                              });
                            },
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                chipTheme:
                                    ChipThemeData.fromDefaults(
                                      secondaryColor: Colors.grey.shade100,
                                      brightness: Brightness.light,
                                      labelStyle: TextStyle(),
                                    ).copyWith(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      side: BorderSide.none,
                                    ),
                              ),
                              child: Chip(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 11,
                                ),
                                backgroundColor: currentIndex == 1
                                    ? Colors.black
                                    : Colors.grey.shade100,
                                label: Text(
                                  languages[38][lang] ?? "",
                                  style: TextStyle(
                                    color: currentIndex == 1
                                        ? Colors.white
                                        : Colors.black,
                                    fontFamily:
                                        GoogleFonts.tajawal().fontFamily,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              orderData("Oldest");
                              setState(() {
                                currentIndex = 2;
                              });
                            },
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                chipTheme:
                                    ChipThemeData.fromDefaults(
                                      secondaryColor: Colors.grey.shade100,
                                      brightness: Brightness.light,
                                      labelStyle: TextStyle(),
                                    ).copyWith(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      side: BorderSide.none,
                                    ),
                              ),
                              child: Chip(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 11,
                                ),
                                backgroundColor: currentIndex == 2
                                    ? Colors.black
                                    : Colors.grey.shade100,
                                label: Text(
                                  languages[39][lang] ?? "",
                                  style: TextStyle(
                                    color: currentIndex == 2
                                        ? Colors.white
                                        : Colors.black,
                                    fontFamily:
                                        GoogleFonts.tajawal().fontFamily,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: merchantItems.isEmpty && allMerchantItems.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Iconsax.close_circle,
                                    color: Colors.red,
                                    size: 80,
                                  ),
                                  SizedBox(height: 20),
                                  Text(
                                    "No Items Found",
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () => getMerchantItems(),
                              child: MasonryGridView.builder(
                                gridDelegate:
                                    SliverSimpleGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                    ),
                                itemCount: merchantItems.length,
                                itemBuilder: (context, index) {
                                  // جلب أول ميديا
                                  // جلب أول ميديا
                                  String firstMedia =
                                      merchantItems[index]['media']
                                          .toString()
                                          .split(',')[0]
                                          .trim();

                                  // استخراج الامتداد بشكل دقيق
                                  String fileExtension = Uri.parse(
                                    firstMedia,
                                  ).path.split('.').last.toLowerCase();
                                  print(fileExtension);

                                  // رابط الميديا
                                  String mediaUrl =
                                      "https://pos7d.site/Globee/sys/uploads/Items/${merchantItems[index]['id']}/$firstMedia";
                                  thumbnailFutures[merchantItems[index]['id']] ??=
                                      generateSmartThumbnail(
                                        mediaUrl,
                                        merchantItems[index]['id'],
                                      );
                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      AppUtils.sNavigateToReplace(
                                        context,
                                        '/UserProfileHome',
                                        {
                                          'userProfileId':
                                              widget.userId.toString() ?? '',
                                          'item_id': merchantItems[index]['id'],
                                        },
                                      );
                                    },
                                    child: Container(
                                      height: 150,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Stack(
                                        children: [
                                          // الصورة أو الفيديو
                                          fileExtension == 'webp'
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                  child: Image.network(
                                                    mediaUrl,
                                                  ),
                                                )
                                              : FutureBuilder<String?>(
                                                  future:
                                                      thumbnailFutures[merchantItems[index]['id']],
                                                  builder: (context, snapshot) {
                                                    if (snapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      return Center(
                                                        child:
                                                            SpinKitDoubleBounce(
                                                              color: AppTheme
                                                                  .primaryColor,
                                                              size: 30.0,
                                                            ),
                                                      );
                                                    }
                                                    if (snapshot.hasError ||
                                                        snapshot.data == null) {
                                                      return Center(
                                                        child: Icon(
                                                          Icons.broken_image,
                                                        ),
                                                      );
                                                    }
                                                    return ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            3,
                                                          ),
                                                      child: Image.file(
                                                        File(snapshot.data!),
                                                        fit: BoxFit.cover,
                                                        width: double.infinity,
                                                        height: double.infinity,
                                                      ),
                                                    );
                                                  },
                                                ),

                                          // الـ Gradient من الأسفل
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            height: 50,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.bottomCenter,
                                                  end: Alignment.topCenter,
                                                  colors: [
                                                    Colors.black.withOpacity(
                                                      0.7,
                                                    ),
                                                    Colors.transparent,
                                                  ],
                                                ),
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                      bottom: Radius.circular(
                                                        8,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          ),

                                          // مثال على كتابة اسم فوق الجريدينت
                                          Positioned(
                                            bottom: 8,
                                            left: lang == 'eng' ? 5 : null,
                                            right: lang == 'arb' ? 5 : null,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: 140,
                                                  child: Text(
                                                    merchantItems[index]['name'],
                                                    maxLines: 2,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  "${merchantItems[index]['price']} ${languages[53][lang]}",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Positioned(
                                            top: 3,
                                            right: 3,
                                            child: Visibility(
                                              visible:
                                                  uid ==
                                                      merchantItems[index]['uid']
                                                  ? true
                                                  : false,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.4),
                                                      blurRadius: 6,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: IconButton(
                                                  onPressed: () {
                                                    SimpleUserMore.showUserMore(
                                                      context,
                                                      merchantItems[index]['id'],
                                                    ).then((val) {
                                                      if (val != null) {
                                                        setState(() {
                                                          getMerchantItems();
                                                          getCountItenswithUser();
                                                        });
                                                        print("Done");
                                                      }
                                                    });
                                                  },
                                                  icon: Icon(
                                                    Iconsax.more,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerFloat,
              floatingActionButton: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text(
                          lang == 'arb' ? "حذف الحساب" : "Delete Account",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        content: Text(
                          lang == 'arb'
                              ? "هل أنت متأكد أنك تريد حذف الحساب نهائيًا؟ لا يمكن التراجع عن هذا الإجراء."
                              : "Are you sure you want to delete your account permanently? This action cannot be undone.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(lang == 'arb' ? "إلغاء" : "Cancel"),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              deleteAccount();
                            },
                            child: Text(lang == 'arb' ? "حذف" : "Delete"),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  height: 50,
                  child: ButtonWidget(
                    btnText: lang == 'arb'
                        ? "حذف الحساب نهائياً"
                        : "Delete Account",
                  ),
                ),
              ),
            ),
    );
  }
}
