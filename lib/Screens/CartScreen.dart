import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:globee/Core/Theme.dart';
import 'package:globee/Core/Utils.dart';
import 'package:globee/Widgets/Button_Widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_compress/video_compress.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List cartOrders = [];
  double totalPrices = 0.00;
  Map<String, Future<String?>> thumbnailFutures = {};

  Future getCartOrders() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    var orders = await AppUtils.makeRequests(
      "fetch",
      "SELECT Cart.id AS id, Items.`name`, Items.id AS itmid,Items.price,Items.qtt AS item_qtt, Items.media,Items.uid, Cart.qtt FROM Cart LEFT JOIN Items ON Cart.item_id = Items.id WHERE Cart.order_id = '${prefx.getString("OID")}'",
    );

    setState(() {
      cartOrders = orders;
      totalPrices = 0.0; // لازم تصفره قبل التكرار
      for (var cartOrder in cartOrders) {
        totalPrices +=
            double.parse(cartOrder['price'].toString()) *
            double.parse(cartOrder['qtt'].toString());
      }
    });
  }

  void calculateTotalPrices() {
    double newTotal = 0.0;
    for (var cartOrder in cartOrders) {
      newTotal +=
          double.parse(cartOrder['price'].toString()) *
          double.parse(cartOrder['qtt'].toString());
    }
    setState(() {
      totalPrices = newTotal;
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
    getCartOrders();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return languages.isEmpty
        ? Scaffold(backgroundColor: Colors.white)
        : Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              leading: IconButton(
                onPressed: () {
                  context.go('/home');
                },
                icon: Icon(Iconsax.arrow_circle_left),
              ),
              forceMaterialTransparency: true,
              centerTitle: true,
              title: Text(
                languages[43][lang],
                style: TextStyle(color: Colors.black),
              ),
              backgroundColor: Colors.white,
            ),
            body: cartOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.shopping_bag, size: 130),
                        SizedBox(height: 20),
                        Text(
                          languages[44][lang],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        ...List.generate(cartOrders.length, (i) {
                          // خالص الوسائط مفصولة
                          List<String> mediaList = cartOrders[i]['media']
                              .toString()
                              .split(',');

                          // ابحث عن أول صورة (مش فيديو)
                          String? firstImage;
                          for (var media in mediaList) {
                            media = media.trim();
                            if (!media.endsWith('.mp4') &&
                                !media.endsWith('.mov') &&
                                !media.endsWith('.avi')) {
                              firstImage = media;

                              break;
                            } else {
                              firstImage = media;
                              print(media);
                              thumbnailFutures[cartOrders[i]['itmid']] ??=
                                  generateSmartThumbnail(
                                    "https://pos7d.site/Globee/sys/uploads/Items/${cartOrders[i]['itmid']}/$firstImage",
                                    cartOrders[i]['itmid'],
                                  );
                            }
                          }

                          return ListTile(
                            onTap: () {
                              AppUtils.sNavigateToReplace(
                                context,
                                '/UserProfileHome',
                                {
                                  'userProfileId': cartOrders[i]['uid'],
                                  'item_id': cartOrders[i]['itmid'],
                                },
                              );
                            },
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 10,
                            ),
                            leading: CircleAvatar(
                              radius: 29,
                              backgroundImage:
                                  firstImage?.split('.')[1] != 'mp4'
                                  ? NetworkImage(
                                      "https://pos7d.site/Globee/sys/uploads/Items/${cartOrders[i]['itmid']}/$firstImage",
                                    )
                                  : null,
                              backgroundColor: Colors.grey[300],
                              child: FutureBuilder<String?>(
                                future:
                                    thumbnailFutures[cartOrders[i]['itmid']],
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                      child: SpinKitDoubleBounce(
                                        color: AppTheme.primaryColor,
                                        size: 30.0,
                                      ),
                                    );
                                  }
                                  if (snapshot.hasError ||
                                      snapshot.data == null) {
                                    return Container();
                                  }
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: Image.file(
                                      File(snapshot.data!),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  );
                                },
                              ),
                            ),
                            title: Text(cartOrders[i]['name'], maxLines: 1),
                            subtitle: Text(cartOrders[i]['price']),
                            trailing: Container(
                              alignment: Alignment.center,
                              width: 100,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () async {
                                        int currentQtt = int.parse(
                                          cartOrders[i]['qtt'].toString(),
                                        );

                                        if (currentQtt > 1) {
                                          currentQtt = currentQtt - 1;

                                          setState(() {
                                            cartOrders[i]['qtt'] = currentQtt
                                                .toString();
                                          });

                                          await AppUtils.makeRequestsViews(
                                            "query",
                                            "UPDATE Cart SET qtt = $currentQtt WHERE id = '${cartOrders[i]['id']}' ",
                                          );
                                          calculateTotalPrices();
                                        } else {
                                          // حذف العنصر لو الكمية وصلت للصفر
                                          await AppUtils.makeRequestsViews(
                                            "query",
                                            "DELETE FROM Cart WHERE id = '${cartOrders[i]['id']}' ",
                                          );

                                          setState(() {
                                            cartOrders.removeAt(i);
                                          });
                                        }
                                      },

                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: AppTheme
                                              .lightTheme
                                              .colorScheme
                                              .primaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                        child: Icon(Iconsax.minus),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.center,
                                    width: 30,
                                    height: 30,
                                    padding: EdgeInsets.only(top: 5),
                                    child: Text(
                                      "${cartOrders[i]['qtt']}",
                                      style: TextStyle(fontSize: 17),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        int currentQtt = int.parse(
                                          cartOrders[i]['qtt'].toString(),
                                        );
                                        int maxQtt = int.parse(
                                          cartOrders[i]['item_qtt'].toString(),
                                        );

                                        if (currentQtt < maxQtt) {
                                          currentQtt = currentQtt + 1;

                                          setState(() {
                                            cartOrders[i]['qtt'] = currentQtt
                                                .toString();
                                          });

                                          AppUtils.makeRequestsViews(
                                            "query",
                                            "UPDATE Cart SET qtt = $currentQtt WHERE id = '${cartOrders[i]['id']}'",
                                          );
                                          calculateTotalPrices();
                                        }
                                      },

                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: AppTheme
                                              .lightTheme
                                              .colorScheme
                                              .primaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                        child: Icon(Iconsax.add),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        SizedBox(height: 80),
                      ],
                    ),
                  ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            floatingActionButton: Visibility(
              visible: cartOrders.isEmpty ? false : true,
              child: GestureDetector(
                onTap: () {
                  context.go('/CheckoutSummary');
                },
                child: SizedBox(
                  height: 60,
                  child: ButtonWidget(
                    btnText: "${languages[52][lang]} $totalPrices QAR",
                  ),
                ),
              ),
            ),
          );
  }
}
